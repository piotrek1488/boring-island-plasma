#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
build_dir=${CALENDAR_TEST_BUILD_DIR:-"$project_dir/build/calendar-test"}
cmake -S "$project_dir/integration/calendar" -B "$build_dir" "$@"
cmake --build "$build_dir" -j2
# Test-only provider: never install this library into the desktop's plugin directory.
QT_PLUGIN_PATH="$build_dir/plugins" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software 
export QT_PLUGIN_PATH QT_QPA_PLATFORM QT_QUICK_BACKEND
dbus-run-session -- "${QMLTESTRUNNER:-/usr/lib/qt6/bin/qmltestrunner}" -input "$project_dir/integration/calendar" -o -,txt
