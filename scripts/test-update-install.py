#!/usr/bin/env python3
"""Verify upgrade with real kpackagetool6, temporary XDG data and local release assets."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from unittest.mock import patch

root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("updater", root / "package/contents/code/update.py")
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)

with tempfile.TemporaryDirectory(prefix="boring-update-test-") as directory:
    profile = Path(directory)
    environment = dict(os.environ)
    for name in ("CONFIG", "DATA", "CACHE"):
        path = profile / name.lower()
        path.mkdir()
        environment["XDG_" + name + "_HOME"] = str(path)
    environment["QT_QPA_PLATFORM"] = "offscreen"
    sentinel = profile / "config/plasma-org.kde.plasma.desktop-appletsrc"
    sentinel.write_text("[Existing widget settings]\nkeep=this\n")
    for version in ("1.0.0", "1.0.1"):
        subprocess.run([sys.executable, str(root / "scripts/package.py"), "--version", version, "--output-dir", str(profile)], check=True)
    subprocess.run(["kpackagetool6", "--type", "Plasma/Applet", "--install", str(profile / "boring-island-1.0.0.plasmoid")], env=environment, check=True)
    data = (profile / "boring-island-1.0.1.plasmoid").read_bytes()
    sums = (hashlib.sha256(data).hexdigest() + "  build/boring-island-1.0.1.plasmoid\n").encode()
    with patch.dict(os.environ, environment), patch.object(updater, "release_info", return_value="1.0.1"), patch.object(updater, "fetch", side_effect=[sums, data]):
        result = updater.install("1.0.0", "1.0.1")
    assert result["status"] == "installed", result
    metadata = json.loads((profile / "data/plasma/plasmoids" / updater.PLUGIN_ID / "metadata.json").read_text())
    assert metadata["KPlugin"]["Version"] == "1.0.1"
    assert sentinel.read_text() == "[Existing widget settings]\nkeep=this\n"
    print("Verified package upgrade installed with kpackagetool6; existing configuration preserved.")
