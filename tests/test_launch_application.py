import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('launch_application', Path(__file__).resolve().parents[1] / 'package/contents/code/launch_application.py')
launcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(launcher)


class ApplicationEntries(unittest.TestCase):
    def test_registered_flat_and_nested_ids(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            file = folder / 'org.example.Mail.desktop'; file.write_text('[Desktop Entry]\nType=Application\nExec=example-mail\n')
            self.assertEqual(launcher.desktop_file('org.example.Mail', [folder]), file)
            self.assertEqual(launcher.desktop_file('org.example.Mail.desktop', [folder]), file)
            nested = folder / 'kde'; nested.mkdir()
            editor = nested / 'editor.desktop'; editor.write_text('[Desktop Entry]\n')
            self.assertEqual(launcher.desktop_file('kde-editor', [folder]), editor)

    def test_missing_and_untrusted_desktop_ids(self):
        with tempfile.TemporaryDirectory() as directory:
            for name in ('missing', '../evil', '/tmp/evil.desktop', 'app;touch /tmp/evil', '$(bad)', "app'", ''):
                self.assertIsNone(launcher.desktop_file(name, [Path(directory)]))
