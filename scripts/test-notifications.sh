#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
qml_runner=${QMLTESTRUNNER:-/usr/lib/qt6/bin/qmltestrunner}
export QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software
# The test owns org.freedesktop.Notifications on this private bus only.
dbus-run-session -- "$qml_runner" -input "$project_dir/integration/notifications" -o -,txt
