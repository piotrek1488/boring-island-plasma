import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('release_version', Path(__file__).resolve().parents[1] / 'scripts/release_version.py')
versions = importlib.util.module_from_spec(spec)
spec.loader.exec_module(versions)

class ReleaseVersions(unittest.TestCase):
    def test_first_release(self):
        self.assertEqual(versions.select('0.3.1', ['v0.2.2'], []), '0.3.1')
    def test_increment_and_ignore_non_versions(self):
        self.assertEqual(versions.select('0.3.1', ['v0.3.1', 'v0.3.9', 'v0.3.10-rc1', 'docs'], []), '0.3.10')
    def test_rerun_uses_same_tag(self):
        self.assertEqual(versions.select('0.3.1', ['v0.3.5'], ['v0.3.4']), '0.3.4')
    def test_explicit_new_minor(self):
        self.assertEqual(versions.select('0.4.0', ['v0.3.5'], []), '0.4.0')
    def test_invalid_base(self):
        with self.assertRaises(ValueError): versions.select('arbitrary', [], [])
