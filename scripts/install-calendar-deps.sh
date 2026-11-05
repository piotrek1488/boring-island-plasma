#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
calendar_env="${XDG_DATA_HOME:-$HOME/.local/share}/boring-island/calendar-venv"
python3 -m venv "$calendar_env"
"$calendar_env/bin/python" -m pip install -r "$project_dir/package/contents/code/requirements-calendar.txt"
printf '%s\n' 'Calendar support installed. Select ICS in the widget settings, paste calendar addresses, then Apply.'
