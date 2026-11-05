#!/usr/bin/env python3
"""Check and install stable releases of this plasmoid, without a shell or root."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import tempfile
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
from zipfile import BadZipFile, ZipFile

REPO = "piotrek1488/boring-island-plasma"
API = "https://api.github.com/repos/" + REPO
WEB = "https://github.com/" + REPO
PLUGIN_ID = "org.kde.plasma.boringisland"


class UpdateError(Exception):
    pass


def version(value):
    if not isinstance(value, str) or not re.fullmatch(r"[0-9]{1,6}\.[0-9]{1,6}\.[0-9]{1,6}", value):
        raise UpdateError("Update verification failed.")
    return tuple(map(int, value.split(".")))


def installed_version():
    return json.loads((Path(__file__).resolve().parents[2] / "metadata.json").read_text())["KPlugin"]["Version"]


def fetch(url, limit):
    request = Request(url, headers={"User-Agent": "Boring-Island-updater", "Accept": "application/vnd.github+json"})
    with urlopen(request, timeout=20) as response:
        data = response.read(limit + 1)
    if len(data) > limit:
        raise UpdateError("Update verification failed.")
    return data


def release_info(selected=None):
    if selected is not None:
        version(selected)
    release = json.loads(fetch(API + ("/releases/tags/v" + selected if selected else "/releases/latest"), 1024 * 1024))
    tag = release.get("tag_name", "")
    latest = tag[1:] if tag.startswith("v") else ""
    version(latest)
    if release.get("draft") or release.get("prerelease") or (selected and selected != latest):
        raise UpdateError("Update verification failed.")
    names = {asset["name"] for asset in release.get("assets", [])}
    if not {"boring-island-" + latest + ".plasmoid", "SHA256SUMS"}.issubset(names):
        raise UpdateError("Update verification failed.")
    return latest


def check(current):
    latest = release_info()
    return {"status": "available" if version(latest) > version(current) else "current", "installed": current, "latest": latest}


def verified_package(selected):
    version(selected)
    name = "boring-island-" + selected + ".plasmoid"
    base = WEB + "/releases/download/v" + selected + "/"
    checksums = fetch(base + "SHA256SUMS", 8192).decode("utf-8")
    matches = []
    for line in checksums.splitlines():
        parts = line.split(maxsplit=1)
        if len(parts) == 2 and PurePosixPath(parts[1].lstrip("*")).name == name:
            matches.append(parts[0])
    if len(matches) != 1 or not re.fullmatch(r"[0-9a-fA-F]{64}", matches[0]):
        raise UpdateError("Update verification failed.")
    data = fetch(base + name, 20 * 1024 * 1024)
    if hashlib.sha256(data).hexdigest() != matches[0].lower():
        raise UpdateError("Update verification failed.")
    with ZipFile(io.BytesIO(data)) as archive:
        if archive.namelist().count("metadata.json") != 1 or archive.getinfo("metadata.json").file_size > 65536:
            raise UpdateError("Update verification failed.")
        metadata = json.loads(archive.read("metadata.json"))
    if (metadata.get("KPackageStructure") != "Plasma/Applet" or metadata.get("KPlugin", {}).get("Id") != PLUGIN_ID
            or metadata.get("KPlugin", {}).get("Version") != selected):
        raise UpdateError("Update verification failed.")
    return data


def install(current, selected):
    if version(selected) <= version(current):
        return {"status": "current", "installed": current, "latest": selected}
    selected = release_info(selected)
    executable = shutil.which("kpackagetool6")
    if not executable:
        raise UpdateError("kpackagetool6 is required to install updates.")
    data = verified_package(selected)
    with tempfile.TemporaryDirectory(prefix="boring-island-update-") as directory:
        path = Path(directory) / ("boring-island-" + selected + ".plasmoid")
        path.write_bytes(data)
        result = subprocess.run([executable, "--type", "Plasma/Applet", "--upgrade", str(path)],
                                capture_output=True, timeout=90)
    if result.returncode:
        raise UpdateError("Update installation failed.")
    return {"status": "installed", "installed": selected, "latest": selected}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", choices=["info", "check", "install", "restart"], required=True)
    parser.add_argument("--version")
    args = parser.parse_args()
    try:
        current = installed_version()
        version(current)
        if args.action == "info":
            result = {"status": "idle", "installed": current}
        elif args.action == "check":
            result = check(current)
        elif args.action == "install":
            result = install(current, args.version)
        else:
            process = subprocess.run(["systemctl", "--user", "restart", "plasma-plasmashell.service"], capture_output=True, timeout=30)
            if process.returncode:
                raise UpdateError("Restart Plasma failed. Log out and back in to load the update.")
            result = {"status": "installed", "installed": current}
    except UpdateError as error:
        result = {"status": "error", "message": str(error)}
    except HTTPError as error:
        result = {"status": "error", "message": "GitHub request limit reached. Try again later." if error.code in (403, 429) else "Could not download the update. Try again later."}
    except (URLError, TimeoutError):
        result = {"status": "error", "message": "Could not download the update. Try again later."}
    except (OSError, ValueError, KeyError, TypeError, BadZipFile, subprocess.SubprocessError):
        result = {"status": "error", "message": "Update operation failed."}
    print(json.dumps(result))


if __name__ == "__main__":
    main()
