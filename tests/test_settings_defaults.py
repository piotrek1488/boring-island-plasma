import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


class SettingsDefaults(unittest.TestCase):
    def test_reset_matches_all_preferences_in_kconfig(self):
        source = (ROOT / 'package/contents/code/SettingsDefaults.js').read_text()
        actual = json.loads(source.split('var values = ', 1)[1].split(';', 1)[0])
        ns = {'k': 'http://www.kde.org/standards/kcfg/1.0'}
        expected = {}
        for entry in ET.parse(ROOT / 'package/contents/config/main.xml').findall('.//k:entry', ns):
            if entry.get('name') == 'shelfJson':
                continue
            value = entry.find('k:default', ns).text or ''
            kind = entry.get('type')
            expected[entry.get('name')] = int(value) if kind == 'Int' else value == 'true' if kind == 'Bool' else value
        self.assertEqual(actual, expected)
        self.assertEqual(actual['animationDuration'], 400)
        self.assertEqual(actual['compactMinimumWidth'], 180)
        self.assertEqual(actual['expandedWidth'], 600)
        self.assertEqual(actual['expandedHeight'], 400)
        self.assertNotIn('shelfJson', actual)
