#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
python3 "$project_dir/tests/check_translations.py"
python3 -m unittest discover -s "$project_dir/tests" -p 'test_*.py'
export QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software
qml_runner=${QMLTESTRUNNER:-/usr/lib/qt6/bin/qmltestrunner}
dbus-run-session -- "$qml_runner" -input "$project_dir/tests" -o -,txt
dbus-run-session -- "$project_dir/scripts/test-mpris.sh"

dbus-run-session -- "$project_dir/scripts/test-connect.sh"

"$project_dir/scripts/test-notifications.sh"
