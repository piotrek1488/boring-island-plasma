#!/usr/bin/env python3
"""Check and install stable releases of this plasmoid, without a shell or root."""
import argparse
import hashlib
import io
import json
import os
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
PLUGIN_ID = "org.kde.plasma.boringisland"


class UpdateError(Exception):
    pass


class AuthenticationRequired(UpdateError):
    pass


LOGIN_HELP = "Sign in with gh auth login --hostname github.com using an account with access to this repository, then check again."


def rate_limited(error):
    headers = error.headers or {}
    return bool(error.code == 429 or (error.code == 403 and (headers.get("X-RateLimit-Remaining") == "0" or headers.get("Retry-After"))))


def authenticated_fetch(url, accept, original_error):
    executable = shutil.which("gh")
    if not executable:
        if rate_limited(original_error):
            raise original_error
        raise AuthenticationRequired("This release requires GitHub access. Install GitHub CLI (gh), then run gh auth login --hostname github.com.")
    # Let gh use its own credential store and handle signed asset redirects.
    # Never read, display or persist its token in the plasmoid's settings.
    environment = dict(os.environ, GH_PROMPT_DISABLED="1", GH_NO_UPDATE_NOTIFIER="1", GH_PAGER="cat")
    result = subprocess.run([executable, "api", "--hostname", "github.com", url[len("https://api.github.com/"):],
                             "--method", "GET", "--header", "Accept: " + accept],
                            capture_output=True, timeout=60, env=environment)
    if result.returncode == 0:
        return result.stdout
    if rate_limited(original_error):
        raise original_error
    if original_error.code in (401, 404) or result.returncode == 4:
        raise AuthenticationRequired(LOGIN_HELP)
    raise original_error


def version(value):
    if not isinstance(value, str) or not re.fullmatch(r"[0-9]{1,6}\.[0-9]{1,6}\.[0-9]{1,6}", value):
        raise UpdateError("Update verification failed.")
    return tuple(map(int, value.split(".")))


def installed_version():
    return json.loads((Path(__file__).resolve().parents[2] / "metadata.json").read_text())["KPlugin"]["Version"]


def fetch(url, limit):
    if not url.startswith(API + "/"):
        raise UpdateError("Update verification failed.")
    accept = "application/octet-stream" if "/releases/assets/" in url else "application/vnd.github+json"
    request = Request(url, headers={"User-Agent": "Boring-Island-updater", "Accept": accept})
    try:
        with urlopen(request, timeout=20) as response:
            data = response.read(limit + 1)
    except HTTPError as error:
        if error.code not in (401, 403, 404, 429):
            raise
        try:
            data = authenticated_fetch(url, accept, error)
        finally:
            error.close()
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
    required = {"boring-island-" + latest + ".plasmoid", "SHA256SUMS"}
    assets = {}
    for asset in release.get("assets", []):
        if asset.get("name") not in required:
            continue
        if type(asset.get("id")) is not int or asset["id"] <= 0 or asset["name"] in assets:
            raise UpdateError("Update verification failed.")
        assets[asset["name"]] = API + "/releases/assets/" + str(asset["id"])
    if set(assets) != required:
        raise UpdateError("Update verification failed.")
    return {"version": latest, "assets": assets}


def check(current):
    latest = release_info()["version"]
    return {"status": "available" if version(latest) > version(current) else "current", "installed": current, "latest": latest}


def verified_package(selected, release=None):
    version(selected)
    name = "boring-island-" + selected + ".plasmoid"
    release = release or release_info(selected)
    if release["version"] != selected:
        raise UpdateError("Update verification failed.")
    checksums = fetch(release["assets"]["SHA256SUMS"], 8192).decode("utf-8")
    matches = []
    for line in checksums.splitlines():
        parts = line.split(maxsplit=1)
        if len(parts) == 2 and PurePosixPath(parts[1].lstrip("*")).name == name:
            matches.append(parts[0])
    if len(matches) != 1 or not re.fullmatch(r"[0-9a-fA-F]{64}", matches[0]):
        raise UpdateError("Update verification failed.")
    data = fetch(release["assets"][name], 20 * 1024 * 1024)
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
    release = release_info(selected)
    executable = shutil.which("kpackagetool6")
    if not executable:
        raise UpdateError("kpackagetool6 is required to install updates.")
    data = verified_package(selected, release)
    with tempfile.TemporaryDirectory(prefix="boring-island-update-") as directory:
        path = Path(directory) / ("boring-island-" + selected + ".plasmoid")
        path.write_bytes(data)
        result = subprocess.run([executable, "--type", "Plasma/Applet", "--upgrade", str(path)],
                                capture_output=True, timeout=90)
    if result.returncode:
        raise UpdateError("Update installation failed.")
    return {"status": "installed", "installed": selected, "latest": selected}


def login():
    executable = shutil.which("gh")
    if not executable:
        raise AuthenticationRequired("This release requires GitHub access. Install GitHub CLI (gh), then run gh auth login --hostname github.com.")
    terminal = shutil.which("konsole") or shutil.which("xdg-terminal-exec")
    if not terminal:
        raise AuthenticationRequired(LOGIN_HELP)
    command = [terminal] + (["-e"] if Path(terminal).name == "konsole" else [])
    subprocess.Popen(command + [executable, "auth", "login", "--hostname", "github.com", "--web"],
                     stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    return {"status": "authRequired", "message": "Finish signing in in the terminal, then click Check for updates again."}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", choices=["info", "check", "install", "restart", "login"], required=True)
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
        elif args.action == "login":
            result = login()
        else:
            process = subprocess.run(["systemctl", "--user", "restart", "plasma-plasmashell.service"], capture_output=True, timeout=30)
            if process.returncode:
                raise UpdateError("Restart Plasma failed. Log out and back in to load the update.")
            result = {"status": "installed", "installed": current}
    except AuthenticationRequired as error:
        result = {"status": "authRequired", "message": str(error)}
    except UpdateError as error:
        result = {"status": "error", "message": str(error)}
    except HTTPError as error:
        limited = rate_limited(error)
        result = {"status": "error", "message": "GitHub request limit reached. Try again later." if limited else "GitHub refused the update request. Check that your account has repository access." if error.code == 403 else "Could not download the update. Try again later."}
    except (URLError, TimeoutError):
        result = {"status": "error", "message": "Could not download the update. Try again later."}
    except (OSError, ValueError, KeyError, TypeError, BadZipFile, subprocess.SubprocessError):
        result = {"status": "error", "message": "Update operation failed."}
    print(json.dumps(result))


if __name__ == "__main__":
    main()
