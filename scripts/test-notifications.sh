#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software
cmake -S "$project_dir/integration/notifications" -B "$project_dir/build/notification-tests"
cmake --build "$project_dir/build/notification-tests" --parallel 2
test_profile=$(mktemp -d)
trap 'rm -rf -- "$test_profile"' EXIT
export XDG_CONFIG_HOME="$test_profile/config" XDG_CACHE_HOME="$test_profile/cache" XDG_DATA_HOME="$test_profile/data"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
# The test owns org.freedesktop.Notifications on this private bus only.
dbus-run-session -- "$project_dir/build/notification-tests/notification-tests" -input "$project_dir/integration/notifications" -o -,txt
