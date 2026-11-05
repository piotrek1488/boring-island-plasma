#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
python3 "$project_dir/tests/check_translations.py"
python3 -m unittest discover -s "$project_dir/tests" -p 'test_*.py'
export QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software
qml_runner=${QMLTESTRUNNER:-/usr/lib/qt6/bin/qmltestrunner}
"$qml_runner" -input "$project_dir/tests/tst_notification_queue.qml" -o -,txt
"$qml_runner" -input "$project_dir/tests/tst_expansion.qml" -o -,txt

"$qml_runner" -input "$project_dir/tests/tst_battery.qml" -o -,txt
"$qml_runner" -input "$project_dir/tests/tst_notch.qml" -o -,txt
"$qml_runner" -input "$project_dir/tests/tst_settings_defaults.qml" -o -,txt
"$qml_runner" -input "$project_dir/tests/tst_calendar_month.qml" -o -,txt
"$qml_runner" -input "$project_dir/tests/tst_agenda_order.qml" -o -,txt
"$qml_runner" -input "$project_dir/tests/tst_compact_activity.qml" -o -,txt
"$qml_runner" -input "$project_dir/tests/tst_reminders.qml" -o -,txt
"$qml_runner" -input "$project_dir/tests/tst_notification_card.qml" -o -,txt
