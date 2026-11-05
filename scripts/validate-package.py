#!/usr/bin/env python3
"""Validate an installable archive, including its embedded version and payload."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
from zipfile import ZipFile

root = Path(__file__).resolve().parents[1]
version = json.loads((root / 'package/metadata.json').read_text())['KPlugin']['Version']
parser = argparse.ArgumentParser()
parser.add_argument('archive', nargs='?', type=Path, default=root / f'build/boring-island-{version}.plasmoid')
parser.add_argument('--qml', action='store_true')
args = parser.parse_args()
archive = args.archive
with ZipFile(archive) as package:
    assert package.testzip() is None
    embedded = json.loads(package.read('metadata.json'))['KPlugin']['Version']
    assert archive.name == f'boring-island-{embedded}.plasmoid'
    for required in ['contents/ui/main.qml', 'contents/ui/NotificationBackend.qml', 'contents/code/collect.py', 'LICENSE', 'NOTICE.md']:
        assert required in package.namelist(), required
    assert not any('__pycache__' in name or name.endswith('.pyc') for name in package.namelist())
if args.qml:
    for source in (root / 'package/contents/ui').glob('*.qml'):
        subprocess.run(['/usr/lib/qt6/bin/qmlformat', str(source)], stdout=subprocess.DEVNULL, check=True)
print(f'Validated {archive.name}')
