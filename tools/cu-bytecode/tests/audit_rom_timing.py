#!/usr/bin/env python3
"""Audit indipendente dei binari fisici, senza importare il generatore.

Uso: python3 tests/audit_rom_timing.py /tmp/cpu8-audit/microcode
Verifica parole stabili e sequenze ISA; NON simula ritardi elettrici.
Exit 0: controlli logici passati; i rischi temporali restano segnalati.
Mappa fisica fissata alla revisione verificata il 2026-09-28.
"""
import hashlib
import sys
from pathlib import Path


def require(ok, message):
    if not ok:
        raise AssertionError(message)


prefix = sys.argv[1]
roms = [Path(f"{prefix}-rom{i}.bin").read_bytes() for i in range(3)]
require(all(len(r) == 8192 for r in roms), "Dimensione ROM errata")

# Ordine D0..D7, con polarita indipendente dal codice C.
pins = [
    [('A0', 0), ('A1', 0), ('PI', 0), ('MW', 0), ('MO', 1),
     ('WW', 1), ('EO', 1), ('NF', 1)],
    [('IW', 0), ('PL', 1), ('ML', 0), ('RE', 0), ('RW', 0),
     ('RA', 0), ('ABW', 0), ('RB', 0)],
    [('AO', 1), ('FW', 0), ('MH', 0), ('RO', 1), ('XL', 0),
     ('XH', 0), ('SYS', 1)],
]


def decode(address):
    signals = {name for i, mapping in enumerate(pins)
               for bit, (name, low) in enumerate(mapping)
               if bool(roms[i][address] & (1 << bit)) != bool(low)}
    selector = int('A0' in signals) + 2 * int('A1' in signals)
    return selector, signals - {'A0', 'A1'}


def word(step, opcode, flags=0, run=1):
    reverse_step = ((step & 1) << 2) | (step & 2) | ((step & 4) >> 2)
    return decode((run << 12) | (flags << 8) | (opcode & 0xf8) | reverse_step)


def w(selector, names=''):
    return selector, set(names.split())


fetch = w(1, 'RO IW PI')
end = w(3, 'NF')
low = w(1, 'RO ML PI')
high = w(1, 'RO MH PI')
jumps = {0xa0: lambda f: True, 0xb0: lambda f: f & 2,
         0xb8: lambda f: not f & 2, 0xe0: lambda f: f & 1,
         0xe8: lambda f: not f & 1, 0xf0: lambda f: f & 4,
         0xf8: lambda f: not f & 4, 0x30: lambda f: f & 8,
         0xa8: lambda f: not f & 8}


def expected(op, flags):
    if op in (0, 1):
        return [fetch, w(3, 'SYS'), end]
    if 0x20 <= op <= 0x27:
        return [fetch, w(1, 'RO MW PI'), w(3, 'MO RE RW'), end]
    if 0x40 <= op <= 0x47:
        return [fetch, low, high, w(2, 'RO MW'), w(3, 'MO RE RW'), end]
    if 0x48 <= op <= 0x4f:
        return [fetch, low, high, w(3, 'RE MW'), w(2, 'MO WW'), end]
    if 0x50 <= op <= 0x57:
        return [fetch, w(0, 'RO MW'), w(3, 'MO RE RW'), end]
    if 0x58 <= op <= 0x5f:
        return [fetch, w(3, 'RE MW'), w(0, 'MO WW'), end]
    if 0x60 <= op <= 0x67 or op == 0x78:
        return [fetch, w(3, 'AO RA ABW FW'), end]
    if op == 0x69:
        return [fetch, w(3, 'FW'), end]
    if op in jumps:
        return [fetch, low, high, w(3, 'PL' if jumps[op](flags) else ''), end]
    if 0xc0 <= op <= 0xc7:
        return [fetch, w(3, 'RE RA ABW'), end]
    if 0xc8 <= op <= 0xcf:
        return [fetch, w(3, 'RE RB ABW'), end]
    if 0xd0 <= op <= 0xd7:
        return [fetch, w(3, 'RA RE RW'), end]
    if op == 0xd8:
        return [fetch, w(1, 'RO XL PI'), w(1, 'RO XH PI'), end]
    return None


for address in range(8192):
    selector, s = decode(address)
    sources = sum(x in s for x in ('RO', 'EO', 'MO', 'AO'))
    sources += ('RE' in s and 'RW' not in s) + ('RA' in s and 'ABW' not in s)
    sinks = bool(s & {'IW', 'MW', 'ML', 'MH', 'XL', 'XH', 'WW'})
    sinks |= 'RE' in s and 'RW' in s
    sinks |= bool(s & {'RA', 'RB'}) and 'ABW' in s
    require(sources <= 1, f"Contesa stabile @{address:04x}")
    require(not sinks or sources == 1, f"Scrittura senza sorgente @{address:04x}")
    require(not s & {'RO', 'EO', 'WW'} or selector != 3,
            f"Memoria senza indirizzo @{address:04x}")
    require(not {'RO', 'WW'} <= s, f"RAM letta e scritta @{address:04x}")
    require(not {'PI', 'PL'} <= s, f"PC incrementato e caricato @{address:04x}")

checks = 0
for op in range(256):
    for flags in range(16):
        require(word(0, op, flags) == fetch, 'Fetch dipendente da IR/flag')
        seq = expected(op, flags)
        if seq is not None:
            checks += 1
            for step in range(8):
                target = seq[step] if step < len(seq) else w(3)
                require(word(step, op, flags) == target,
                        f"ISA op={op:02x} flags={flags:x} T{step+1}")
        for step in range(8):
            boot = [w(1, 'EO WW'), w(1, 'EO PI'), w(1, 'EO NF')]
            require(word(step, op, flags, 0) == (boot[step] if step < 3 else w(3)),
                    'BOOT dipendente da opcode/flag o sequenza errata')
            s = word(step, op, flags)[1]
            halt = 'SYS' in s and (op & 7) == 0
            require(halt == (op == 0 and step == 1), 'Decoder HLT errato')

print(f'PASS: 8192 parole fisiche; {checks} sequenze opcode/flag '
      f'({checks // 16} opcode ISA); BOOT e HLT esaustivi.')
for i, rom in enumerate(roms):
    print(f'ROM{i} SHA256 {hashlib.sha256(rom).hexdigest()}')

# Controllo di transizione: la fine /WE deve precedere il rilascio dei bus.
# Una differenza evidenzia assenza di una fase di mantenimento, non misura ns.
for op, name in [(0x48, 'STA'), (0x58, 'STAI')]:
    for step in range(7):
        selector, s = word(step, op)
        following_selector, following = word(step + 1, op)
        if 'WW' in s and 'WW' not in following:
            if selector != following_selector or 'MO' not in following:
                print(f'RISCHIO: {name} T{step+1}->T{step+2}: /WE sale mentre '
                      'indirizzo/dato vengono rilasciati; hold non garantito.')
print('LIMITI: nessun modello di glitch, propagazione, clock gated, '
      'setup/hold o cablaggio ALU. PASS logico non autorizza il timing fisico.')
