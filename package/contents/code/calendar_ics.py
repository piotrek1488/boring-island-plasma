#!/usr/bin/env python3
"""Read-only iCalendar agenda. URLs stay in KConfig, never in process arguments."""
import argparse
import configparser
from datetime import date, datetime, time, timedelta
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
from urllib.parse import unquote, urlparse
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

MAX_BYTES = 10 * 1024 * 1024


def read_sources(config_path, applet_id):
    config = configparser.ConfigParser(interpolation=None, strict=False)
    config.read(config_path, encoding='utf-8')
    suffix = f'][Applets][{applet_id}][Configuration][General'
    for section in config.sections():
        if section.endswith(suffix):
            encoded = config[section].get('calendarSources', '')
            decoded = re.sub(r'\\([\\nst])', lambda m: {'\\': '\\', 'n': '\n', 's': ' ', 't': '\t'}[m[1]], encoded)
            return list(dict.fromkeys(line.strip() for line in decoded.splitlines() if line.strip()))[:16]
    return []


def local_timezone():
    if os.environ.get('TZ'):
        return ZoneInfo(os.environ['TZ'])
    with open('/etc/localtime', 'rb') as handle:
        return ZoneInfo.from_file(handle)


def read_source(source, cache_dir, refresh=False):
    if source.startswith('webcal://'):
        source = 'https://' + source[len('webcal://'):]
    parsed = urlparse(source)
    if parsed.scheme in ('', 'file'):
        if parsed.netloc not in ('', 'localhost'):
            raise ValueError('Non-local file')
        with Path(unquote(parsed.path)).expanduser().open('rb') as handle:
            payload = handle.read(MAX_BYTES + 1)
    elif parsed.scheme in ('https', 'http'):
        cache_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
        cache = cache_dir / (hashlib.sha256(source.encode()).hexdigest() + '.ics')
        if not refresh and cache.exists() and datetime.now().timestamp() - cache.stat().st_mtime < 300:
            return cache.read_bytes()
        with urlopen(Request(source, headers={'User-Agent': 'BoringIsland/1.0'}), timeout=10) as response:
            payload = response.read(MAX_BYTES + 1)
        if len(payload) > MAX_BYTES or b'BEGIN:VCALENDAR' not in payload[:1024]:
            raise ValueError('Invalid calendar response')
        with tempfile.NamedTemporaryFile(dir=cache_dir, delete=False) as handle:
            handle.write(payload)
            temporary = handle.name
        os.replace(temporary, cache)
    else:
        raise ValueError('Unsupported calendar source')
    if len(payload) > MAX_BYTES:
        raise ValueError('Calendar too large')
    return payload


def events_for_range(payload, first, until, timezone):
    from icalendar import Calendar
    import recurring_ical_events
    start = datetime.combine(first, time.min, timezone)
    end = datetime.combine(until, time.min, timezone)
    calendar = Calendar.from_ical(payload)
    result = []
    for event in recurring_ical_events.of(calendar).between(start, end):
        if str(event.get('STATUS', '')).upper() == 'CANCELLED':
            continue
        begin = event.decoded('DTSTART')
        finish = event.decoded('DTEND', begin)
        all_day = not isinstance(begin, datetime)
        def timestamp(value):
            if not isinstance(value, datetime):
                value = datetime.combine(value, time.min, timezone)
            if value.tzinfo is None:
                value = value.replace(tzinfo=timezone)
            return value.astimezone(timezone).isoformat()
        result.append({'title': str(event.get('SUMMARY', '')), 'description': str(event.get('DESCRIPTION', '')),
                       'isAllDay': all_day, 'startDateTime': timestamp(begin), 'endDateTime': timestamp(finish),
                       'eventColor': '#89b4fa'})
    return result


def events_for_day(payload, selected, timezone):
    return events_for_range(payload, selected, selected + timedelta(days=1), timezone)


def event_dates(event, first, until):
    begin = datetime.fromisoformat(event['startDateTime'])
    end = datetime.fromisoformat(event['endDateTime'])
    # DTEND is exclusive, including for multi-day all-day events.
    last = (end - timedelta(microseconds=1)).date() if end > begin else begin.date()
    current = max(first, begin.date())
    while current <= last and current < until:
        yield current
        current += timedelta(days=1)


def agenda(sources, selected, cache_dir, refresh=False):
    import icalendar  # noqa: F401 - explicit dependency check, including empty source lists
    import recurring_ical_events  # noqa: F401
    if not sources:
        return {'events': [], 'error': 'Add an ICS calendar address or local file in widget settings.'}
    events = []
    month_days = set()
    first = selected.replace(day=1)
    until = (first.replace(day=28) + timedelta(days=4)).replace(day=1)
    errors = 0
    timezone = local_timezone()
    for source in sources:
        try:
            month_events = events_for_range(read_source(source, cache_dir, refresh), first, until, timezone)
            for event in month_events:
                days = set(event_dates(event, first, until))
                month_days.update(day.isoformat() for day in days)
                if selected in days:
                    events.append(event)
        except Exception:
            # Exception text can contain the private subscription URL. Never return it.
            errors += 1
    events.sort(key=lambda e: (not e['isAllDay'], e['startDateTime'], e['title']))
    return {'events': events[:500], 'monthDays': sorted(month_days), 'error': 'Some calendars could not be loaded. Check the ICS addresses and network connection.' if errors else ''}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--applet-id', type=int, required=True)
    parser.add_argument('--date', type=date.fromisoformat, required=True)
    parser.add_argument('--refresh', action='store_true')
    args = parser.parse_args()
    try:
        config_dir = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config'))
        cache_dir = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache')) / 'boring-island/calendars'
        result = agenda(read_sources(config_dir / 'plasma-org.kde.plasma.desktop-appletsrc', args.applet_id), args.date, cache_dir, args.refresh)
    except ImportError:
        result = {'events': [], 'error': 'ICS support requires Python calendar dependencies. See the calendar setup instructions.'}
    except Exception:
        result = {'events': [], 'error': 'Calendar data could not be loaded.'}
    print(json.dumps(result, ensure_ascii=False))


if __name__ == '__main__':
    main()
