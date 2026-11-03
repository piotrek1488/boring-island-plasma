#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
python3 "$project_dir/integration/mock_mpris.py" &
mock_pid=$!
trap 'kill "$mock_pid" 2>/dev/null || true; wait "$mock_pid" 2>/dev/null || true' EXIT
"${QMLTESTRUNNER:-/usr/lib/qt6/bin/qmltestrunner}" -input "$project_dir/integration/tst_mpris.qml" -o -,txt
