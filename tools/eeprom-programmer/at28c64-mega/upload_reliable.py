#!/usr/bin/env python3
"""Carica file .hex o .bin con CRC, ACK e ritentativi sul Mega."""

import argparse
import re
import sys
import time


BLOCK_SIZE = 16
LINE = re.compile(r"^\s*([0-9A-Fa-f]{1,4})\s*:\s*([0-9A-Fa-f]{2})\s*$")


def crc16(address, data):
    crc = 0xFFFF
    for value in address.to_bytes(2, "big") + len(data).to_bytes(2, "big") + data:
        crc ^= value << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return crc


def read_hex(path):
    image = {}
    for number, raw in enumerate(path.read_text().splitlines(), 1):
        if not raw.strip():
            continue
        match = LINE.match(raw)
        if not match:
            raise ValueError(f"{path}:{number}: formato atteso '0000: FF'")
        image[int(match.group(1), 16)] = int(match.group(2), 16)
    return image


def read_image(path, image_format, start_address):
    if image_format == "hex" or (image_format == "auto" and path.suffix.lower() == ".hex"):
        return read_hex(path)
    data = path.read_bytes()
    if not data:
        raise ValueError("il file .bin e vuoto")
    if start_address + len(data) > 8192:
        raise ValueError("il file .bin non entra nella AT28C64 (8192 byte)")
    return {start_address + index: value for index, value in enumerate(data)}


def ranges(image):
    addresses = sorted(image)
    if not addresses:
        return
    start = previous = addresses[0]
    for address in addresses[1:]:
        if address != previous + 1:
            yield start, bytes(image[item] for item in range(start, previous + 1))
            start = address
        previous = address
    yield start, bytes(image[item] for item in range(start, previous + 1))


def response(port, command, timeout):
    port.write((command + "\n").encode("ascii"))
    port.flush()
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        line = port.readline().decode("ascii", errors="replace").strip()
        if line.startswith("OK ") or line.startswith("ERR "):
            return line
    raise TimeoutError(f"nessuna risposta a: {command}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", required=True, help="porta seriale, es. /dev/cu.usbmodemXXXX")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--retries", type=int, default=3)
    parser.add_argument("--protected", action="store_true")
    parser.add_argument("--format", choices=("auto", "hex", "bin"), default="auto")
    parser.add_argument("--address", type=lambda value: int(value, 0), default=0,
                        help="indirizzo iniziale per .bin (default: 0x0000)")
    parser.add_argument("image_file", type=__import__("pathlib").Path)
    args = parser.parse_args()
    if not 0 <= args.address < 8192:
        raise SystemExit("--address deve essere fra 0x0000 e 0x1FFF")
    image = read_image(args.image_file, args.format, args.address)
    if not image:
        raise SystemExit("il file di input e vuoto")
    image_ranges = list(ranges(image))
    total_bytes = sum(len(data) for _, data in image_ranges)
    written_bytes = 0
    try:
        import serial
    except ImportError as error:
        raise SystemExit("installa pyserial: python3 -m pip install pyserial") from error
    with serial.Serial(args.port, args.baud, timeout=0.25, write_timeout=2) as port:
        time.sleep(2.2)  # reset automatico del Mega all'apertura della seriale
        port.reset_input_buffer()
        mode = response(port, "M P" if args.protected else "M W", 2)
        if not mode.startswith("OK "):
            raise RuntimeError(mode)
        for start, data in image_ranges:
            for offset in range(0, len(data), BLOCK_SIZE):
                block = data[offset:offset + BLOCK_SIZE]
                address = start + offset
                # Il firmware accetta anche 0b...: il prefisso 0x evita che
                # un indirizzo come 0B00 venga scambiato per binario.
                command = (
                    f"B 0x{address:04X} 0x{len(block):02X} "
                    f"0x{crc16(address, block):04X} {block.hex().upper()}"
                )
                for attempt in range(1, args.retries + 1):
                    result = response(port, command, 2 + len(block) * 0.03)
                    if result.startswith("OK B"):
                        break
                    print(f"ritento {address:04X} ({attempt}/{args.retries}): {result}", file=sys.stderr)
                else:
                    raise RuntimeError(f"blocco {address:04X} non scritto")
                written_bytes += len(block)
                percent = written_bytes * 100 / total_bytes
                print(
                    f"\rUpload: {percent:6.2f}% "
                    f"({written_bytes}/{total_bytes} byte, fino a 0x{address + len(block) - 1:04X})",
                    end="",
                    flush=True,
                )
            expected = crc16(start, data)
            result = response(
                port,
                f"C 0x{start:04X} 0x{len(data):04X} 0x{expected:04X}",
                3 + len(data) * 0.002,
            )
            if result != "OK C":
                raise RuntimeError(f"verifica intervallo {start:04X}: {result}")
    print("\nOK: EEPROM scritta e verificata con CRC-16")


if __name__ == "__main__":
    main()
