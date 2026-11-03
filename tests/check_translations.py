#!/usr/bin/env python3
"""Ensure all literal UI strings have Polish entries and English stays default."""
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
root = Path(__file__).resolve().parents[1]
catalog_source = (root / 'package/contents/code/Translations.js').read_text()
catalog = json.loads(catalog_source.split('var polish = ', 1)[1].split(';\n', 1)[0])
used = set()
for path in (root / 'package/contents/ui').glob('*.qml'):
    source = path.read_text()
    used.update(re.findall(r'strings\.text\("([^"\n]+)"\)', source))
    used.update(re.findall(r'statusKey = "([^"\n]+)"', source))
missing = used - catalog.keys()
assert not missing, f'Missing Polish translations: {sorted(missing)}'
assert all(isinstance(value, str) and value for value in catalog.values())
config = ET.parse(root / 'package/contents/config/main.xml')
ns = {'k': 'http://www.kde.org/standards/kcfg/1.0'}
assert config.find(".//k:entry[@name='language']/k:default", ns).text == 'en'
assert '[Polski](README.pl.md)' in (root / 'README.md').read_text()
assert '[English](README.md)' in (root / 'README.pl.md').read_text()
print(f'Translation coverage: {len(used)} UI strings; English default and README links verified.')
