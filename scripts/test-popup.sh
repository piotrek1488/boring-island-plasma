#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
qml_runner=${QMLTESTRUNNER:-/usr/lib/qt6/bin/qmltestrunner}
export QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen} QT_QUICK_BACKEND=software
dbus-run-session -- "$qml_runner" -input "$project_dir/integration/popup" -o -,txt
