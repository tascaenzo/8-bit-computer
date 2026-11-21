#!/usr/bin/env python3
"""Crea immagini sperimentali con preparazione MAR, senza alterare la CU base.

Uso: python3 experiment_mar_prepare.py PREFIX_BASE DIRECTORY_NUOVA [--idx-prepare]
Accetta solo la baseline verificata il 15 novembre 2026. Nessun accesso seriale.
"""
import hashlib
import json
import argparse
from pathlib import Path


EXPECTED = [
    '0c2b70e88ee7c9edc0a587893fe0d7716438512d677a43a8ea21ff2a741f9116',
    '8e057d5f18e986151234c6300a31c76d3993d22bd1ad4d6398f198e1307220ac',
    'cbe864db58cc8ae403741dba0d03045e2b86b4eb806b6ad1b13f34118dd98bbc',
]


def address(op, flags, step):
    return 0x1000 | flags << 8 | (op & 0xf8) | ((step & 1) << 2) | (step & 2) | ((step & 4) >> 2)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('prefix')
    parser.add_argument('destination')
    parser.add_argument('--idx-prepare', action='store_true',
                        help='aggiunge preparazione basso/alto anche a LDX')
    args = parser.parse_args()
    prefix, destination = args.prefix, args.destination
    original = [Path(f'{prefix}-rom{i}.bin').read_bytes() for i in range(3)]
    if [hashlib.sha256(r).hexdigest() for r in original] != EXPECTED:
        raise SystemExit('Baseline diversa: riesaminare la variante prima di generarla.')
    result = [bytearray(r) for r in original]

    def word(op, flags, step):
        a = address(op, flags, step)
        return bytes(r[a] for r in original)

    # Parola fisica: PC selezionato, /RD attivo, nessuna cattura né PC_INC.
    prepare = bytes.fromhex('F1 02 41')
    changed_groups = [0x40, 0x48, 0xa0, 0xb0, 0xb8, 0xe0, 0xe8,
                      0xf0, 0xf8, 0x30, 0xa8]
    if args.idx_prepare:
        changed_groups.append(0xd8)
    for flags in range(16):
        for op in changed_groups:
            old = [word(op, flags, step) for step in range(8)]
            seq = [old[0], prepare, old[1], prepare, old[2]]
            if op == 0x40:  # LDA: lettura in MDR, trasferimento Rn, ritorno.
                seq += old[3:6]
            elif op == 0x48:
                # STA: Rn -> MDR, scrittura, hold con ritorno sincrono.
                # T8 mantiene MAR/MDR e chiude /WR; /NEXT_FETCH va a zero.
                hold_return = bytes([old[6][0] & 0x7f, *old[6][1:]])
                seq += [old[3], old[5], hold_return]
            else:  # Salti: esecuzione/ritorno; LDX: ritorno T6, poi inattivo.
                seq += old[3:6]
            for step, control in enumerate(seq):
                a = address(op, flags, step)
                for i in range(3):
                    result[i][a] = control[i]

    output = Path(destination)
    output.mkdir(parents=True, exist_ok=False)
    rollback = output / 'baseline'
    rollback.mkdir()
    report = {'variant': 'mar-idx-prepare' if args.idx_prepare else 'mar-prepare',
              'physical_timing_validated': False,
              'requires_synchronous_next_fetch': True, 'roms': []}
    for i, (before, after) in enumerate(zip(original, result)):
        (rollback / f'microcode-rom{i}.bin').write_bytes(before)
        (output / f'microcode-rom{i}.bin').write_bytes(after)
        report['roms'].append({'rom': i, 'baseline_sha256': EXPECTED[i],
                              'sha256': hashlib.sha256(after).hexdigest(),
                              'changed_bytes': sum(a != b for a, b in zip(before, after))})
    (output / 'generation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
