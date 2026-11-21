#!/usr/bin/env python3
"""Read-only Tang USB-UART snapshot reader, optionally compared with a PDF point."""
import argparse
import json
import re
import sys
import time
from pathlib import Path

FIELDS = set('B Y RD WR A M DI DV DO OE DIR RDY P C S W R WA WD RA RV'.split())

def parse_line(line):
    if not line.startswith('CPU8v1 '):
        return None
    pairs = re.findall(r'([A-Z]+)=([0-9A-F]+)', line)
    result = {key: int(value, 16) for key, value in pairs}
    if set(result) != FIELDS or len(pairs) != len(FIELDS):
        return None
    return result

def compare(snapshot, expected):
    checks = [('BOOT/RUN', snapshot['B'], 0),
              ('/RD', snapshot['RD'], expected['rd']),
              ('/WR', snapshot['WR'], expected['wr'])]
    address = expected['a']
    if address is not None:
        checks += [('indirizzo (bit disponibili)', snapshot['A'] & snapshot['M'], address & snapshot['M']),
                   ('Y0/Y1', snapshot['Y'], 2 if address >= 0x2000 else 0)]
    active_io = address is not None and address >= 0x2000 and (not expected['rd'] or not expected['wr'])
    if active_io:
        checks += [('dato valido', snapshot['DV'], 1), ('/OE NH245', snapshot['OE'], 0),
                   ('DIR NH245', snapshot['DIR'], 1 if not expected['rd'] else 0)]
        if expected['d'] is not None and snapshot['DV']:
            checks.append(('dato lato FPGA', snapshot['DI'], expected['d']))
        if not expected['rd'] and expected['d'] is not None:
            checks.append(('risposta interna', snapshot['DO'], expected['d']))
    else:
        checks.append(('/OE NH245 fuori accesso I/O', snapshot['OE'], 1))
    return [{'signal': name, 'observed': actual, 'expected': target, 'ok': actual == target}
            for name, actual, target in checks]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', default='auto')
    parser.add_argument('--baud', type=int, default=115200)
    parser.add_argument('--seconds', type=float, default=2.0)
    parser.add_argument('--point', type=int, help='Punto 1-372 del PDF Hello World, non il solo numero T')
    parser.add_argument('--json', action='store_true')
    parser.add_argument('--raw', action='store_true')
    args = parser.parse_args()
    if args.seconds <= 0 or (args.point is not None and not 1 <= args.point <= 372):
        parser.error('Usare seconds > 0 e point fra 1 e 372')
    try:
        import serial
        from serial.tools import list_ports
    except ImportError:
        parser.error('Serve pyserial nel Python usato per questo script')
    expected = None
    if args.point:
        entries = json.loads(Path(__file__).with_name('hello_world_expected.json').read_text())
        expected = entries[args.point - 1]
    candidates = [args.port] if args.port != 'auto' else sorted(
        [p.device for p in list_ports.comports()
         if any(word in p.device for word in ('usbserial', 'usbmodem', 'ttyUSB', 'ttyACM'))], reverse=True)
    if not candidates:
        parser.exit(1, 'Tang non rilevata: collegare la USB-C e caricare il bitstream con debug.\n')
    failures = []
    for device in candidates:
        samples = []
        try:
            port = serial.Serial(baudrate=args.baud, timeout=0.2)
            port.dtr = False
            port.rts = False
            port.port = device
            with port:
                deadline = time.monotonic() + args.seconds
                while time.monotonic() < deadline:
                    line = port.readline().decode('ascii', errors='replace').strip()
                    snap = parse_line(line)
                    if snap:
                        samples.append(snap)
                        if args.raw:
                            print(line, flush=True)
        except (OSError, serial.SerialException) as exc:
            failures.append(f'{device}: {exc}')
            continue
        if not samples:
            failures.append(f'{device}: nessun pacchetto CPU8v1 a {args.baud} baud')
            continue
        s = samples[-1]
        report = {'port': device, 'samples': len(samples), 'snapshot': s}
        if expected:
            report['point'] = expected
            report['checks'] = compare(s, expected)
        if args.json:
            print(json.dumps(report, indent=2))
        elif not args.raw:
            print(f"Porta: {device}; campioni: {len(samples)}")
            print(f"Modalita: {'BOOT' if s['B'] else 'RUN'}; Y0={(s['Y'] >> 1)&1}, Y1={s['Y']&1}; /RD={s['RD']}, /WR={s['WR']}")
            print(f"A={s['A']:04X}, maschera={s['M']:04X}, A15..A3={s['A']>>3:04X}")
            print(f"Dato pad={s['DI']:02X} ({'valido' if s['DV'] else 'NON valido: traduttore disabilitato'}); risposta interna={s['DO']:02X}")
            print(f"/OE={s['OE']}, DIR={s['DIR']}, READY={s['RDY']}, STATUS={s['S']:02X}, puntatore={s['P']:04X}, colore={s['C']:02X}")
            print(f"Scritture accettate={s['W']}, ultima={s['WA']:04X}:{s['WD']:02X}; letture={s['R']}, ultima={s['RA']:04X}:{s['RV']:02X}")
            if expected:
                print(f"Confronto punto {args.point}: {expected['label']}, T{expected['step']}")
                for check in report['checks']:
                    print(f"  {'OK' if check['ok'] else 'DIVERSO'} {check['signal']}: letto {check['observed']:X}, atteso {check['expected']:X}")
        return
    parser.exit(1, '\n'.join(failures) + '\n')

if __name__ == '__main__':
    main()
