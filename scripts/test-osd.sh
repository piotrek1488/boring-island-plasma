#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software
cmake -S "$project_dir/integration/osd" -B "$project_dir/build/osd-tests"
cmake --build "$project_dir/build/osd-tests" --parallel 2
# Own fixture service names only on a private bus, never on the desktop bus.
dbus-run-session -- "$project_dir/build/osd-tests/osd-tests" -input "$project_dir/integration/osd" -o -,txt
