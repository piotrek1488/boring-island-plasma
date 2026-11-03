#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
python3 "$project_dir/integration/connect/mock_connect.py" &
mock_pid=$!
trap 'kill "$mock_pid" 2>/dev/null || true; wait "$mock_pid" 2>/dev/null || true' EXIT
# Wait for ownership before constructing native KDE objects (avoid daemon activation).
python3 - <<'PY'
import time, dbus
bus = dbus.SessionBus()
for _ in range(100):
    if bus.name_has_owner('org.kde.kdeconnect'): break
    time.sleep(0.02)
else: raise SystemExit('Mock KDE Connect did not start')
PY
"${QMLTESTRUNNER:-/usr/lib/qt6/bin/qmltestrunner}" -input "$project_dir/integration/connect" -o -,txt
