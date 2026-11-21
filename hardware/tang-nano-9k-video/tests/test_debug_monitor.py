import importlib.util
from pathlib import Path
import sys
import unittest

TOOLS = Path(__file__).resolve().parents[1] / 'tools'
sys.path.insert(0, str(TOOLS))
spec = importlib.util.spec_from_file_location('debug_monitor', TOOLS/'debug_monitor.py')
monitor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(monitor)


class MonitorTest(unittest.TestCase):
    def setUp(self):
        self.sample = monitor.parse_line((TOOLS/'debug-example-line.txt').read_text())

    def test_floating_data_changes_are_not_reported_as_cpu_data(self):
        before = dict(self.sample, DV=0, DI=0)
        self.assertEqual(monitor.events_between(before, dict(before, DI=122)), [])

    def test_missing_intermediate_transactions_are_explicit(self):
        after = dict(self.sample, W=self.sample['W']+3, WA=0x2000, WD=0x48)
        events = ' '.join(monitor.events_between(self.sample, after))
        self.assertIn('+3', events)
        self.assertIn('2000:48', events)
        self.assertIn('2 accessi intermedi non disponibili', events)

    def test_counter_restart_does_not_claim_a_measured_reset(self):
        events = ' '.join(monitor.events_between(dict(self.sample, W=5), dict(self.sample, W=0)))
        self.assertIn('possibile reset FPGA o wrap', events)


if __name__ == '__main__':
    unittest.main()
