#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
qdbus_bin=$(command -v qdbus6 || command -v qdbus || true)
if [[ -z "$qdbus_bin" && -x /usr/lib/qt6/bin/qdbus ]]; then qdbus_bin=/usr/lib/qt6/bin/qdbus; fi
[[ -n "$qdbus_bin" ]] || { echo 'qdbus6 (Qt 6 tools) was not found.' >&2; exit 1; }
"$qdbus_bin" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$project_dir/scripts/add-top-panel.js")"
