#!/usr/bin/env python3
"""Build a reproducible Plasma package with source and license, no dependencies."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import json
import argparse
import re
root = Path(__file__).resolve().parents[1]
source_version = json.loads((root / 'package/metadata.json').read_text())['KPlugin']['Version']
parser = argparse.ArgumentParser()
parser.add_argument('--version', default=source_version)
parser.add_argument('--output-dir', type=Path, default=root / 'build')
args = parser.parse_args()
version = args.version
if not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", version):
    parser.error("--version must be MAJOR.MINOR.PATCH")
args.output_dir.mkdir(parents=True, exist_ok=True)
target = args.output_dir / f'boring-island-{version}.plasmoid' 
with ZipFile(target, 'w', compression=ZIP_DEFLATED) as archive:
    files = [(p, p.relative_to(root / 'package').as_posix())
             for p in sorted((root / 'package').rglob('*')) if p.is_file() and '__pycache__' not in p.parts and p.suffix != '.pyc']
    files += [(root / 'LICENSE', 'LICENSE'), (root / 'NOTICE.md', 'NOTICE.md')]
    for path, name in files:
        entry = ZipInfo(name, date_time=(2026, 11, 3, 0, 0, 0))
        entry.external_attr = 0o100644 << 16
        entry.compress_type = ZIP_DEFLATED
        data = path.read_bytes()
        if name == 'metadata.json':
            metadata = json.loads(data)
            metadata['KPlugin']['Version'] = version
            data = (json.dumps(metadata, ensure_ascii=False, indent=2) + '\n').encode()
        archive.writestr(entry, data)
print(target)
