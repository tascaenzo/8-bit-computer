#!/usr/bin/env python3
"""Record timestamped Tang snapshots without driving CPU or FPGA signals."""
import argparse
import csv
from datetime import datetime
import json
from pathlib import Path
import time

from debug_read import FIELDS, parse_line


def events_between(previous, current):
    if previous is None:
        return ['inizio acquisizione; i contatori possono includere accessi precedenti']
    events = []
    for field, label in [('B', 'BOOT_RUN'), ('RDY', 'READY')]:
        if current[field] != previous[field]:
            events.append(f'{label}: {previous[field]} -> {current[field]}')
    for counter, address, value, label in [('W', 'WA', 'WD', 'scritture'),
                                          ('R', 'RA', 'RV', 'letture')]:
        difference = current[counter] - previous[counter]
        if difference < 0:
            events.append(f'{label}: contatore diminuito; possibile reset FPGA o wrap')
        elif difference:
            events.append(f'{label}: +{difference}, ultima {current[address]:04X}:{current[value]:02X}')
            if difference > 1:
                events.append(f'{label}: dettagli di {difference-1} accessi intermedi non disponibili')
    # Do not announce changes on undriven data pads as CPU data activity.
    controls = ('Y', 'RD', 'WR', 'A', 'M', 'OE', 'DIR')
    if any(current[k] != previous[k] for k in controls):
        events.append(f'bus A={current["A"]:04X} M={current["M"]:04X} '
                      f'Y={current["Y"]} /RD={current["RD"]} /WR={current["WR"]} '
                      f'/OE={current["OE"]} DIR={current["DIR"]}')
    if current['DV'] and (not previous['DV'] or current['DI'] != previous['DI']):
        events.append(f'dato pad valido: {current["DI"]:02X}')
    return events


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', default='auto')
    parser.add_argument('--seconds', type=float, default=1800)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.seconds <= 0:
        parser.error('--seconds deve essere positivo')
    import serial
    from serial.tools import list_ports
    candidates = [args.port] if args.port != 'auto' else sorted(
        [p.device for p in list_ports.comports()
         if any(s in p.device for s in ('usbserial', 'usbmodem', 'ttyUSB', 'ttyACM'))], reverse=True)
    args.output.mkdir(parents=True, exist_ok=True)
    start = time.monotonic()
    samples = 0
    previous = None
    first = None
    selected = None
    last_sample = None
    ordered = 'B Y RD WR A M DI DV DO OE DIR RDY P C S W R WA WD RA RV'.split()
    assert set(ordered) == FIELDS
    metadata = {'started_at': datetime.now().astimezone().isoformat(),
                'requested_seconds': args.seconds,
                'limitations': ['circa 10 campioni/s, non un analizzatore logico',
                                'A0-A2 dedotti dai select, non misurati',
                                'DI significativo solo con DV=1',
                                'reset e PS2 raw non inclusi nel protocollo CPU8v1',
                                'durante reset FPGA non trasmette; silenzio non prova un reset',
                                'contatori e ultimo accesso non conservano tutti gli accessi intermedi']}
    (args.output/'session.json').write_text(json.dumps(metadata, indent=2)+'\n')
    with (args.output/'samples.jsonl').open('w') as raw, \
         (args.output/'samples.csv').open('w', newline='') as csv_file, \
         (args.output/'events.log').open('w') as event_file:
        writer = csv.DictWriter(csv_file, fieldnames=['timestamp', 'elapsed_s', 'gap_s'] + ordered)
        writer.writeheader()
        try:
            for device in candidates:
                port = serial.Serial(baudrate=115200, timeout=0.2)
                port.dtr = False
                port.rts = False
                port.port = device
                try:
                    with port:
                        print(f'Porta aperta: {device}; attendo telemetria CPU8v1.', flush=True)
                        probe_deadline = time.monotonic() + 2
                        while time.monotonic()-start < args.seconds:
                            if args.port == 'auto' and not selected and time.monotonic() > probe_deadline:
                                break
                            line = port.readline().decode('ascii', errors='replace').strip()
                            snapshot = parse_line(line)
                            if snapshot is None:
                                continue
                            now = time.monotonic()
                            stamp = datetime.now().astimezone().isoformat(timespec='milliseconds')
                            if not selected:
                                selected = device
                                print(f'Monitor attivo: {device}; log: {args.output}', flush=True)
                            row = dict(timestamp=stamp, elapsed_s=round(now-start, 6),
                                       gap_s=None if last_sample is None else round(now-last_sample, 6),
                                       **snapshot)
                            raw.write(json.dumps(dict(row, raw=line))+'\n'); raw.flush()
                            writer.writerow(row); csv_file.flush()
                            for event in events_between(previous, snapshot):
                                message = f'{stamp} {event}'
                                event_file.write(message+'\n'); event_file.flush()
                                print(message, flush=True)
                            first = snapshot if first is None else first
                            previous = snapshot
                            last_sample = now
                            samples += 1
                    if selected:
                        break
                except (OSError, serial.SerialException) as error:
                    if selected:
                        raise
                    print(f'{device}: {error}', flush=True)
            if not selected:
                raise RuntimeError('Nessuna telemetria CPU8v1 ricevuta')
        except KeyboardInterrupt:
            print('Monitor interrotto; log salvati.', flush=True)
        finally:
            metadata.update(port=selected, samples=samples, first=first, last=previous,
                            ended_at=datetime.now().astimezone().isoformat())
            (args.output/'session.json').write_text(json.dumps(metadata, indent=2)+'\n')
    print(f'Fine acquisizione: {samples} campioni.', flush=True)


if __name__ == '__main__':
    main()
