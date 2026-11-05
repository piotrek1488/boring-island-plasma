#!/usr/bin/env python3
"""Launch a registered desktop entry with KDE; never interpret notification text as a command."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess


def desktop_file(entry, directories):
    if not re.fullmatch(r'[A-Za-z0-9_.-]{1,250}', entry):
        return None
    name = entry if entry.endswith('.desktop') else entry + '.desktop'
    for directory in directories:
        direct = Path(directory) / name
        if direct.is_file():
            return direct
        if Path(directory).is_dir():
            for candidate in Path(directory).rglob('*.desktop'):
                if '-'.join(candidate.relative_to(directory).parts) == name:
                    return candidate
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--desktop-id', required=True)
    args = parser.parse_args()
    data_home = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share'))
    directories = [data_home / 'applications'] + [Path(p) / 'applications' for p in os.environ.get('XDG_DATA_DIRS', '/usr/local/share:/usr/share').split(':') if p]
    file = desktop_file(args.desktop_id, directories)
    launcher = shutil.which('kioclient6') or shutil.which('kioclient')
    if not file or not launcher:
        return 1
    try:
        return subprocess.run([launcher, 'exec', str(file)], timeout=15, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode
    except (OSError, subprocess.TimeoutExpired):
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
