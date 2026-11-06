import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
from zipfile import ZipFile

spec = importlib.util.spec_from_file_location("updater", Path(__file__).resolve().parents[1] / "package/contents/code/update.py")
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


def package(version="1.2.3", plugin_id=updater.PLUGIN_ID):
    output = io.BytesIO()
    with ZipFile(output, "w") as archive:
        archive.writestr("metadata.json", json.dumps({"KPackageStructure": "Plasma/Applet", "KPlugin": {"Id": plugin_id, "Version": version}}))
    return output.getvalue()


def release(version="1.2.3"):
    return {"version": version, "assets": {"SHA256SUMS": updater.API + "/releases/assets/1",
            "boring-island-" + version + ".plasmoid": updater.API + "/releases/assets/2"}}


class Updates(unittest.TestCase):
    def test_versions_and_no_downgrade(self):
        for value in [None, "v1.2.3", "1.2", "1.2.3-rc1", "1.2.3;command", "../../file"]:
            with self.subTest(value=value), self.assertRaises(updater.UpdateError):
                updater.version(value)
        with patch.object(updater, "release_info", return_value=release("1.10.0")):
            self.assertEqual(updater.check("1.9.0")["status"], "available")
            self.assertEqual(updater.check("2.0.0")["status"], "current")
        with patch.object(updater, "release_info") as fetch, patch.object(updater.subprocess, "run") as run:
            self.assertEqual(updater.install("2.0.0", "1.9.0")["status"], "current")
            fetch.assert_not_called()
            run.assert_not_called()

    def test_release_validation(self):
        metadata = {"tag_name": "v1.2.3", "assets": [{"name": "boring-island-1.2.3.plasmoid", "id": 2}, {"name": "SHA256SUMS", "id": 1}]}
        with patch.object(updater, "fetch", return_value=json.dumps(metadata).encode()):
            self.assertEqual(updater.release_info(), release())
        for change in [{"prerelease": True}, {"draft": True}, {"tag_name": "bad"}, {"assets": []}, {"assets": [{"name": "SHA256SUMS", "id": "../outside"}]}]:
            with patch.object(updater, "fetch", return_value=json.dumps(dict(metadata, **change)).encode()), self.assertRaises(updater.UpdateError):
                updater.release_info()

    def test_checksum_identity_and_version(self):
        for data, digest, valid in [(package(), None, True), (package(), "0" * 64, False),
                                    (package(plugin_id="other.widget"), None, False), (package("9.9.9"), None, False)]:
            checksum = ((digest or hashlib.sha256(data).hexdigest()) + "  build/boring-island-1.2.3.plasmoid\n").encode()
            with patch.object(updater, "fetch", side_effect=[checksum, data]) as fetch:
                if valid:
                    self.assertEqual(updater.verified_package("1.2.3", release()), data)
                else:
                    with self.assertRaises(updater.UpdateError):
                        updater.verified_package("1.2.3", release())
                self.assertEqual([call.args[0] for call in fetch.call_args_list], [release()["assets"]["SHA256SUMS"], release()["assets"]["boring-island-1.2.3.plasmoid"]])

    def test_install_uses_verified_temporary_file_and_reports_failures(self):
        data = package()
        captured = []

        def run(command, **kwargs):
            captured.append(command)
            self.assertEqual(command[:4], ["/usr/bin/kpackagetool6", "--type", "Plasma/Applet", "--upgrade"])
            self.assertEqual(Path(command[4]).read_bytes(), data)
            self.assertNotIn("shell", kwargs)
            return subprocess.CompletedProcess(command, 0)

        with patch.object(updater, "release_info", return_value=release()), patch.object(updater.shutil, "which", return_value="/usr/bin/kpackagetool6"), \
                patch.object(updater, "verified_package", return_value=data), patch.object(updater.subprocess, "run", side_effect=run):
            self.assertEqual(updater.install("1.0.0", "1.2.3")["status"], "installed")
        self.assertFalse(Path(captured[0][4]).exists())
        with patch.object(updater, "release_info", return_value=release()), patch.object(updater.shutil, "which", return_value="/usr/bin/kpackagetool6"), \
                patch.object(updater, "verified_package", return_value=data), patch.object(updater.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)):
            with self.assertRaisesRegex(updater.UpdateError, "installation failed"):
                updater.install("1.0.0", "1.2.3")

    def test_oversized_download_is_rejected(self):
        with patch.object(updater, "urlopen", return_value=io.BytesIO(b"0123456789")), self.assertRaises(updater.UpdateError):
            updater.fetch(updater.API + "/releases/latest", 5)

    def test_private_metadata_and_binary_use_gh_without_exposing_credentials(self):
        for endpoint, accept, payload in [("/releases/latest", "application/vnd.github+json", b'{"tag_name":"v1.2.3"}'),
                                           ("/releases/assets/2", "application/octet-stream", b'PK\x03\x04fixture')]:
            error = HTTPError(updater.API + endpoint, 404, "Not Found", {}, None)
            with patch.object(updater, "urlopen", side_effect=error), patch.object(updater.shutil, "which", return_value="/usr/bin/gh"), \
                    patch.object(updater.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, stdout=payload)) as run:
                self.assertEqual(updater.fetch(updater.API + endpoint, 1000), payload)
                command = run.call_args.args[0]
                self.assertIn("Accept: " + accept, command)
                self.assertIn("repos/" + updater.REPO + endpoint, command)
                self.assertNotIn("token", command)
                self.assertNotIn("Authorization", " ".join(command))
                self.assertNotIn("shell", run.call_args.kwargs)

    def test_missing_cli_or_missing_access_gives_login_instructions(self):
        error = HTTPError(updater.API + "/releases/latest", 404, "Not Found", {}, None)
        with patch.object(updater, "urlopen", side_effect=error), patch.object(updater.shutil, "which", return_value=None), self.assertRaisesRegex(updater.AuthenticationRequired, "Install GitHub CLI"):
            updater.fetch(updater.API + "/releases/latest", 1000)
        with patch.object(updater, "urlopen", side_effect=error), patch.object(updater.shutil, "which", return_value="/usr/bin/gh"), \
                patch.object(updater.subprocess, "run", return_value=subprocess.CompletedProcess([], 4, stdout=b"", stderr=b"private detail")), self.assertRaisesRegex(updater.AuthenticationRequired, "gh auth login"):
            updater.fetch(updater.API + "/releases/latest", 1000)

    def test_public_releases_do_not_require_gh(self):
        with patch.object(updater, "urlopen", return_value=io.BytesIO(b"public")), patch.object(updater.subprocess, "run") as run:
            self.assertEqual(updater.fetch(updater.API + "/releases/assets/1", 100), b"public")
            run.assert_not_called()
        with self.assertRaises(updater.UpdateError):
            updater.fetch("https://outside.example/releases/assets/1", 100)

    def test_login_opens_only_the_auth_command_in_a_terminal(self):
        with patch.object(updater.shutil, "which", side_effect=["/usr/bin/gh", "/usr/bin/konsole"]), patch.object(updater.subprocess, "Popen") as start:
            self.assertEqual(updater.login()["status"], "authRequired")
            self.assertEqual(start.call_args.args[0], ["/usr/bin/konsole", "-e", "/usr/bin/gh", "auth", "login", "--hostname", "github.com", "--web"])

    def test_rate_limits_are_not_reported_as_missing_login(self):
        for code, headers in [(429, {}), (403, {"X-RateLimit-Remaining":"0"})]:
            error = HTTPError(updater.API+"/releases/latest", code, "Limit", headers, None)
            with patch.object(updater, "urlopen", side_effect=error), patch.object(updater.shutil, "which", return_value=None), self.assertRaises(HTTPError):
                updater.fetch(updater.API+"/releases/latest", 1000)
        denied = HTTPError(updater.API, 403, "Forbidden", {}, None)
        self.addCleanup(denied.close)
        self.assertFalse(updater.rate_limited(denied))
