import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch
from zipfile import ZipFile

spec = importlib.util.spec_from_file_location("updater", Path(__file__).resolve().parents[1] / "package/contents/code/update.py")
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


def package(version="1.2.3", plugin_id=updater.PLUGIN_ID):
    output = io.BytesIO()
    with ZipFile(output, "w") as archive:
        archive.writestr("metadata.json", json.dumps({"KPackageStructure": "Plasma/Applet", "KPlugin": {"Id": plugin_id, "Version": version}}))
    return output.getvalue()


class Updates(unittest.TestCase):
    def test_versions_and_no_downgrade(self):
        for value in [None, "v1.2.3", "1.2", "1.2.3-rc1", "1.2.3;command", "../../file"]:
            with self.subTest(value=value), self.assertRaises(updater.UpdateError):
                updater.version(value)
        with patch.object(updater, "release_info", return_value="1.10.0"):
            self.assertEqual(updater.check("1.9.0")["status"], "available")
            self.assertEqual(updater.check("2.0.0")["status"], "current")
        with patch.object(updater, "release_info") as fetch, patch.object(updater.subprocess, "run") as run:
            self.assertEqual(updater.install("2.0.0", "1.9.0")["status"], "current")
            fetch.assert_not_called()
            run.assert_not_called()

    def test_release_validation(self):
        release = {"tag_name": "v1.2.3", "assets": [{"name": "boring-island-1.2.3.plasmoid"}, {"name": "SHA256SUMS"}]}
        with patch.object(updater, "fetch", return_value=json.dumps(release).encode()):
            self.assertEqual(updater.release_info(), "1.2.3")
        for change in [{"prerelease": True}, {"draft": True}, {"tag_name": "bad"}, {"assets": []}]:
            with patch.object(updater, "fetch", return_value=json.dumps(dict(release, **change)).encode()), self.assertRaises(updater.UpdateError):
                updater.release_info()

    def test_checksum_identity_and_version(self):
        for data, digest, valid in [(package(), None, True), (package(), "0" * 64, False),
                                    (package(plugin_id="other.widget"), None, False), (package("9.9.9"), None, False)]:
            checksum = ((digest or hashlib.sha256(data).hexdigest()) + "  build/boring-island-1.2.3.plasmoid\n").encode()
            with patch.object(updater, "fetch", side_effect=[checksum, data]) as fetch:
                if valid:
                    self.assertEqual(updater.verified_package("1.2.3"), data)
                else:
                    with self.assertRaises(updater.UpdateError):
                        updater.verified_package("1.2.3")
                self.assertTrue(all(call.args[0].startswith(updater.WEB + "/releases/download/v1.2.3/") for call in fetch.call_args_list))

    def test_install_uses_verified_temporary_file_and_reports_failures(self):
        data = package()
        captured = []

        def run(command, **kwargs):
            captured.append(command)
            self.assertEqual(command[:4], ["/usr/bin/kpackagetool6", "--type", "Plasma/Applet", "--upgrade"])
            self.assertEqual(Path(command[4]).read_bytes(), data)
            self.assertNotIn("shell", kwargs)
            return subprocess.CompletedProcess(command, 0)

        with patch.object(updater, "release_info", return_value="1.2.3"), patch.object(updater.shutil, "which", return_value="/usr/bin/kpackagetool6"), \
                patch.object(updater, "verified_package", return_value=data), patch.object(updater.subprocess, "run", side_effect=run):
            self.assertEqual(updater.install("1.0.0", "1.2.3")["status"], "installed")
        self.assertFalse(Path(captured[0][4]).exists())
        with patch.object(updater, "release_info", return_value="1.2.3"), patch.object(updater.shutil, "which", return_value="/usr/bin/kpackagetool6"), \
                patch.object(updater, "verified_package", return_value=data), patch.object(updater.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)):
            with self.assertRaisesRegex(updater.UpdateError, "installation failed"):
                updater.install("1.0.0", "1.2.3")

    def test_oversized_download_is_rejected(self):
        with patch.object(updater, "urlopen", return_value=io.BytesIO(b"0123456789")), self.assertRaises(updater.UpdateError):
            updater.fetch(updater.API + "/releases/latest", 5)
