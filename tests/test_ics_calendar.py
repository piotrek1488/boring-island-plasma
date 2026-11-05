import importlib.util
from datetime import date
from pathlib import Path
import tempfile
import os
import sys
import json
import subprocess
import unittest
from unittest.mock import patch
from zoneinfo import ZoneInfo

spec = importlib.util.spec_from_file_location('calendar_ics', Path(__file__).resolve().parents[1] / 'package/contents/code/calendar_ics.py')
ics = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ics)


def calendar(events):
    return ('BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Boring Island//Tests//EN\r\n' + events.replace('\n', '\r\n') + '\r\nEND:VCALENDAR\r\n').encode()


class IcsCalendar(unittest.TestCase):
    def test_recurrence_exclusion_and_timezone(self):
        payload = calendar('''BEGIN:VEVENT
UID:weekly
DTSTART;TZID=Europe/Warsaw:20261026T090000
DTEND;TZID=Europe/Warsaw:20261026T100000
RRULE:FREQ=WEEKLY;COUNT=3
EXDATE;TZID=Europe/Warsaw:20261102T090000
SUMMARY:Weekly sync
END:VEVENT''')
        self.assertEqual(ics.events_for_day(payload, date(2026, 11, 2), ZoneInfo('Europe/Warsaw')), [])
        events = ics.events_for_day(payload, date(2026, 11, 9), ZoneInfo('Europe/Warsaw'))
        self.assertEqual(len(events), 1)
        self.assertTrue(events[0]['startDateTime'].endswith('09:00:00+01:00'))
        self.assertEqual(events[0]['title'], 'Weekly sync')

    def test_all_day_exclusive_end_and_cancelled(self):
        payload = calendar('''BEGIN:VEVENT
UID:trip
DTSTART;VALUE=DATE:20261105
DTEND;VALUE=DATE:20261107
SUMMARY:Trip
END:VEVENT
BEGIN:VEVENT
UID:cancelled
DTSTART:20261105T100000Z
DTEND:20261105T110000Z
STATUS:CANCELLED
SUMMARY:Cancelled
END:VEVENT''')
        events = ics.events_for_day(payload, date(2026, 11, 6), ZoneInfo('UTC'))
        self.assertEqual([e['title'] for e in events], ['Trip'])
        self.assertTrue(events[0]['isAllDay'])
        self.assertEqual(ics.events_for_day(payload, date(2026, 11, 7), ZoneInfo('UTC')), [])

    def test_utc_conversion_and_overnight(self):
        payload = calendar('''BEGIN:VEVENT
UID:night
DTSTART:20261105T223000Z
DTEND:20261106T003000Z
SUMMARY:Night
END:VEVENT''')
        events = ics.events_for_day(payload, date(2026, 11, 6), ZoneInfo('Europe/Warsaw'))
        self.assertEqual(len(events), 1)
        self.assertTrue(events[0]['startDateTime'].endswith('23:30:00+01:00'))

    def test_private_config_sources_and_local_file(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            config = folder / 'appletsrc'
            config.write_text('[Containments][2][Applets][7][Configuration][General]\ncalendarSources=https://example.invalid/private.ics\\n/tmp/calendar.ics\n')
            self.assertEqual(ics.read_sources(config, 7), ['https://example.invalid/private.ics', '/tmp/calendar.ics'])
            self.assertEqual(ics.read_sources(config, 8), [])
            file = folder / 'calendar.ics'
            file.write_bytes(calendar('''BEGIN:VEVENT
UID:one
DTSTART;VALUE=DATE:20261105
SUMMARY:Local file
END:VEVENT'''))
            result = ics.agenda([str(file), 'unsupported://private-token'], date(2026, 11, 5), folder / 'cache')
            self.assertEqual(len(result['events']), 1)
            self.assertTrue(result['error'])
            self.assertNotIn('private-token', result['error'])

    def test_cli_reads_saved_applet_configuration(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            file = folder / 'calendar.ics'
            file.write_bytes(calendar('BEGIN:VEVENT\nUID:cli\nDTSTART;VALUE=DATE:20261105\nSUMMARY:CLI event\nEND:VEVENT'))
            (folder / 'plasma-org.kde.plasma.desktop-appletsrc').write_text(
                '[Containments][2][Applets][7][Configuration][General]\ncalendarSources=' + str(file) + '\n')
            env = dict(os.environ, XDG_CONFIG_HOME=str(folder), XDG_CACHE_HOME=str(folder), TZ='UTC')
            result = subprocess.run([sys.executable, str(Path(ics.__file__)), '--applet-id', '7', '--date', '2026-11-05'],
                                    env=env, capture_output=True, text=True, check=True)
            output = json.loads(result.stdout)
            self.assertEqual(output['error'], '')
            self.assertEqual(output['events'][0]['title'], 'CLI event')

    def test_month_markers_include_recurrence_and_exclusive_end(self):
        payload = calendar('BEGIN:VEVENT\nUID:trip\nDTSTART;VALUE=DATE:20261105\nDTEND;VALUE=DATE:20261108\nSUMMARY:Trip\nEND:VEVENT\nBEGIN:VEVENT\nUID:weekly\nDTSTART;VALUE=DATE:20261102\nRRULE:FREQ=WEEKLY;COUNT=3\nEXDATE;VALUE=DATE:20261109\nSUMMARY:Weekly\nEND:VEVENT')
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            file = folder / 'calendar.ics'; file.write_bytes(payload)
            result = ics.agenda([str(file)], date(2026,11,6), folder / 'cache')
            self.assertEqual(result['monthDays'], ['2026-11-02','2026-11-05','2026-11-06','2026-11-07','2026-11-16'])
            self.assertEqual([e['title'] for e in result['events']], ['Trip'])

    def test_event_markers_clip_to_month_and_keep_zero_length_events(self):
        event = {'startDateTime':'2026-10-31T23:00:00+00:00','endDateTime':'2026-11-02T00:00:00+00:00'}
        self.assertEqual(list(ics.event_dates(event,date(2026,11,1),date(2026,12,1))), [date(2026,11,1)])
        event['startDateTime']=event['endDateTime']='2026-11-05T12:00:00+00:00'
        self.assertEqual(list(ics.event_dates(event,date(2026,11,1),date(2026,12,1))), [date(2026,11,5)])

    def test_network_cache_and_explicit_refresh(self):
        payload = calendar('')
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            with patch.object(ics, 'urlopen') as request:
                request.return_value.__enter__.return_value.read.return_value = payload
                ics.read_source('https://example.invalid/private.ics', folder)
                ics.read_source('https://example.invalid/private.ics', folder)
                self.assertEqual(request.call_count, 1)
                ics.read_source('https://example.invalid/private.ics', folder, refresh=True)
                self.assertEqual(request.call_count, 2)
                cache = next(folder.glob('*.ics'))
                self.assertEqual(cache.stat().st_mode & 0o777, 0o600)
                self.assertNotIn('private', cache.name)
