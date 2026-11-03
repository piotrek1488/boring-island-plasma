#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
command -v kpackagetool6 >/dev/null || { echo 'Wymagane KDE Plasma 6.6+ i kpackagetool6.' >&2; exit 1; }
package_id=org.kde.plasma.boringisland
if kpackagetool6 -t Plasma/Applet -s "$package_id" >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Applet -u "$project_dir/package"
else
    kpackagetool6 -t Plasma/Applet -i "$project_dir/package"
fi
printf '%s\n' 'Zainstalowano Boring Island. Dodaj element interfejsu „Boring Island” do panelu lub pulpitu.' 'Wygląd zmienisz w ustawieniach widżetu: Notch / Dynamic Island.'
