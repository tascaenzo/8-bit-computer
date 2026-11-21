import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('debug_read', ROOT / 'tools/debug_read.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)

class DebugReaderTest(unittest.TestCase):
    def setUp(self):
        self.sample = reader.parse_line((ROOT / 'tools/debug-example-line.txt').read_text())
        self.sample.update(B=0, Y=2, RD=0, WR=1, A=0x2018, M=0xffff, DI=1,
                           DV=1, DO=1, OE=0, DIR=1, RDY=1, S=1)
        self.points = json.loads((ROOT / 'tools/hello_world_expected.json').read_text())

    def test_status_read_at_pdf_point_four(self):
        checks = reader.compare(self.sample, self.points[3])
        self.assertTrue(all(check['ok'] for check in checks))

    def test_missing_a3_is_detected(self):
        self.sample['A'] = 0x2010
        self.assertTrue(any(not check['ok'] and 'indirizzo' in check['signal']
                            for check in reader.compare(self.sample, self.points[3])))

    def test_write_direction_and_byte_are_checked(self):
        self.sample.update(A=0x2000, RD=1, WR=0, DI=0x48, DIR=0)
        self.assertTrue(all(c['ok'] for c in reader.compare(self.sample, self.points[90])))
        self.sample['DIR'] = 1
        self.assertTrue(any(not c['ok'] for c in reader.compare(self.sample, self.points[90])))

    def test_ram_data_is_not_claimed_visible(self):
        self.sample.update(Y=0, A=0, M=0xfff8, DI=0xff, DV=0, OE=1)
        checks = reader.compare(self.sample, self.points[0])
        self.assertTrue(all(c['ok'] for c in checks))
        self.assertFalse(any('dato' in c['signal'] for c in checks))

    def test_rejects_partial_or_unrelated_lines(self):
        self.assertIsNone(reader.parse_line('CPU8v1 B=0 Y=2'))
        self.assertIsNone(reader.parse_line('Arduino ready'))

if __name__ == '__main__':
    unittest.main()
