#!/usr/bin/env python3
"""Build a reproducible Plasma package with source and license, no dependencies."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import json
import argparse
root = Path(__file__).resolve().parents[1]
version = json.loads((root / 'package/metadata.json').read_text())['KPlugin']['Version']
parser = argparse.ArgumentParser()
parser.add_argument('--output-dir', type=Path, default=root / 'build')
args = parser.parse_args()
args.output_dir.mkdir(parents=True, exist_ok=True)
target = args.output_dir / f'boring-island-{version}.plasmoid' 
with ZipFile(target, 'w', compression=ZIP_DEFLATED) as archive:
    files = [(p, p.relative_to(root / 'package').as_posix())
             for p in sorted((root / 'package').rglob('*')) if p.is_file()]
    files += [(root / 'LICENSE', 'LICENSE'), (root / 'NOTICE.md', 'NOTICE.md')]
    for path, name in files:
        entry = ZipInfo(name, date_time=(2026, 11, 3, 0, 0, 0))
        entry.external_attr = 0o100644 << 16
        entry.compress_type = ZIP_DEFLATED
        archive.writestr(entry, path.read_bytes())
print(target)
