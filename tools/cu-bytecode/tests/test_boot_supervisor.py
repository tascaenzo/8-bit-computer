"""Modello logico della proposta in docs/boot-ready-run-controller.md.

Eseguire con python3 tools/cu-bytecode/tests/test_boot_supervisor.py.
START e POR sono gia sincronizzati. Nessuna simulazione elettrica.
"""
import unittest


# CLOCK_ALLOW, MODE_RUN, WRITE_BLOCK, MEM_ISOLATE, RESET_ACTIVE
OUTPUTS = {
    'RESET': (0, 0, 1, 1, 1),
    'BOOT_PREP': (0, 0, 1, 0, 0),
    'COPY': (1, 0, 0, 0, 0),
    'ISOLATE': (0, 0, 1, 1, 0),
    'MODE_RESET': (0, 1, 1, 1, 1),
    'READY': (0, 1, 1, 1, 0),
    'ARM': (0, 1, 1, 0, 0),
    'RUN': (1, 1, 0, 0, 0),
}


class Supervisor:
    def __init__(self):
        self.reset()

    def reset(self):
        self.state = 'RESET'
        self.pc = self.step = 0
        self.done = self.armed = False
        self.writes = []
        self.first_fetch = None
        self.pending_write = None
        self.ram = bytearray(8192)
        self.rom = bytes((i * 73 + (i >> 8)) & 255 for i in range(8192))

    def cycle(self, start=False):
        """Fronte positivo CPU, poi fronte negativo supervisore."""
        clock, mode, block, isolate, reset = OUTPUTS[self.state]
        if reset:
            self.pc = self.step = 0
        elif clock:
            if not mode:
                if self.step == 0 and not block and not isolate:
                    assert 0 <= self.pc < 8192
                    # Chiudendo T1 si entra in T2: /WE torna alto.
                    self.pending_write = (self.pc, self.rom[self.pc])
                if self.step == 1:
                    self.pc = (self.pc + 1) & 0xffff
                self.step = 0 if self.step == 2 else self.step + 1
                if self.pending_write is not None and self.step == 1:
                    address, data = self.pending_write
                    self.ram[address] = data
                    self.writes.append(address)
                    self.pending_write = None
            elif self.first_fetch is None:
                assert not isolate and not block and self.step == 0
                self.first_fetch = self.pc

        old = self.state
        if old == 'RESET':
            new = 'BOOT_PREP'
        elif old == 'BOOT_PREP':
            new = 'COPY'
        elif old == 'COPY':
            end = self.pc == 0x2000 and self.step == 2
            new = 'ISOLATE' if end else old
            self.done |= end
        elif old == 'ISOLATE':
            new = 'MODE_RESET'
        elif old == 'MODE_RESET':
            new = 'READY'
        elif old == 'READY':
            new = 'ARM' if self.armed and start else old
            if not start:
                self.armed = True
        elif old == 'ARM':
            new = 'RUN'
        else:
            new = 'RUN'
        if new != 'READY':
            self.armed = False
        # Il cambio banco e reset avviene dopo un periodo isolato e fermo.
        if OUTPUTS[old][1] != OUTPUTS[new][1]:
            assert not OUTPUTS[old][0] and OUTPUTS[old][2:4] == (1, 1)
            assert not OUTPUTS[new][0] and OUTPUTS[new][2:4] == (1, 1)
        self.state = new
        if OUTPUTS[new][4]:
            self.pc = self.step = 0


class BootTests(unittest.TestCase):
    def ready(self, held=False):
        s = Supervisor()
        for _ in range(25000):
            s.cycle(held)
            if s.state == 'READY':
                return s
        self.fail('Boot non terminato')

    def test_complete_copy_and_wait(self):
        s = self.ready()
        self.assertEqual(s.writes, list(range(8192)))
        self.assertEqual(s.ram, s.rom)
        self.assertTrue(s.done)
        self.assertEqual((s.pc, s.step), (0, 0))
        for _ in range(1000):
            s.cycle()
        self.assertEqual(s.state, 'READY')
        self.assertIsNone(s.first_fetch)
        self.assertEqual(len(s.writes), 8192)

    def test_start_requires_release_in_ready(self):
        s = self.ready(held=True)
        for _ in range(100):
            s.cycle(True)
        self.assertEqual(s.state, 'READY')
        s.cycle(False)
        s.cycle(True)
        self.assertEqual(s.state, 'ARM')
        self.assertIsNone(s.first_fetch)
        s.cycle(True)
        self.assertEqual(s.state, 'RUN')
        self.assertIsNone(s.first_fetch)
        s.cycle(True)
        self.assertEqual(s.first_fetch, 0)

    def test_start_in_boot_not_queued(self):
        s = Supervisor()
        for _ in range(50):
            s.cycle(True)
        for _ in range(25000):
            s.cycle(False)
        self.assertEqual(s.state, 'READY')
        self.assertIsNone(s.first_fetch)

    def test_global_reset_returns_to_boot(self):
        s = self.ready()
        s.cycle(False)
        for _ in range(3):
            s.cycle(True)
        self.assertEqual(s.first_fetch, 0)
        # Il reset hardware conserva la RAM: il modello la ripristina qui.
        memory = s.ram[:]
        s.reset()
        s.ram[:] = memory
        self.assertFalse(s.done)
        self.assertEqual(OUTPUTS[s.state], (0, 0, 1, 1, 1))
        s.cycle()
        self.assertEqual(s.state, 'BOOT_PREP')


if __name__ == '__main__':
    unittest.main(verbosity=2)
