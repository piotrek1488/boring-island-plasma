#!/usr/bin/env python3
"""Exercise the real applet's hover path in an isolated plasmoidviewer session.

Run under dbus-run-session with Plasma 6.6+ and a display (e.g. xvfb-run).
Only a temporary package copy is instrumented; desktop configuration is isolated.
"""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--package", type=Path, default=root / "package")
parser.add_argument("--location", choices=["topedge", "bottomedge"], default="topedge")
args = parser.parse_args()

probe = """
    Timer {
        interval: 50; repeat: true; running: true
        property int stage: 0
        property int cycles: 0
        onTriggered: {
            if (!root.anchorItem || root.anchorItem.width <= 0) return;
            if (stage === 0) {
                Plasmoid.configuration.animationStyle = cycles % 2 ? "spring" : "smooth";
                Plasmoid.configuration.shape = cycles < 2 ? 0 : 1;
                root.hoverChanged(true, true);
                stage = 1;
            } else if (stage === 1 && root.opened && popupShell.progress === 1) {
                console.log("PANEL_HOVER_OPEN", cycles);
                root.compactHovered = false;
                root.hoverChanged(false, false);
                stage = 2;
            } else if (stage === 2 && !root.opened && !attachedDialog.visible && popupShell.progress === 0) {
                cycles++;
                stage = 0;
                if (cycles === 4) { stop(); console.log("PANEL_HOVER_OK"); }
            }
        }
    }
"""

with tempfile.TemporaryDirectory(prefix="boring-hover-") as directory:
    scratch = Path(directory)
    package = scratch / "package"
    shutil.copytree(args.package, package)
    main = package / "contents/ui/main.qml"
    source = main.read_text()
    assert source.count("    id: root\n") == 1
    main.write_text(source.replace("    id: root\n", "    id: root\n" + probe, 1))
    env = dict(os.environ)
    for key, name in [("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache"), ("XDG_DATA_HOME", "data")]:
        path = scratch / name
        path.mkdir()
        env[key] = str(path)
    env["QML_DISABLE_DISK_CACHE"] = "1"
    with (scratch / "viewer.log").open("w+") as log:
        process = subprocess.Popen(["plasmoidviewer", "-a", str(package), "-f", "horizontal", "-l", args.location, "-s", "800x64"],
                                   env=env, stdout=log, stderr=subprocess.STDOUT)
        output = ""
        success = False
        try:
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline and process.poll() is None:
                log.seek(0)
                output = log.read()
                if "PANEL_HOVER_OK" in output:
                    success = True
                    break
                time.sleep(0.1)
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            log.seek(0)
            output = log.read()
        errors = [line for line in output.splitlines() if str(package) in line and
                  re.search(r"Binding loop|TypeError|ReferenceError|Error:", line)]
        print(output)
        if not success or errors:
            raise SystemExit("Panel hover failed: applet exited, timed out, or emitted QML errors.")
        print("Panel hover passed: notch/island, smooth/spring, four complete open/close cycles.")
