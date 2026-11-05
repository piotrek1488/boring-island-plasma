# Verification of 0.3.5

Core offscreen tests cover minimum collapsed side padding at 50%, 100% and 150%
scale, visible intermediate collapse frames, hover without an interaction request,
and clicks on both the header and a tab requesting focus while preserving the tab
switch. The 0.3.4 battery warning, concave shoulders and panel geometry tests remain
in the core suite.

The focus fix follows [KWin's acceptsFocus implementation](https://github.com/KDE/kwin/blob/master/src/xdgshellwindow.cpp):
Notification honors panelTakesFocus, while AppletPopup does not. Hover now uses
Notification with WindowDoesNotAcceptFocus. A pointer click or keyboard activation
switches to AppletPopup and explicitly requests activation. Each new hover session
resets to nonactivating mode.

The native popup fixture covers both roles, focus flags, reset after interaction
and stable coordinates. It requires Plasma 6 modules unavailable in this cloud
workspace. Real compositor focus and smoothness still require a Plasma/Wayland
desktop. Core QML tests use Qt 6.4.2 with offscreen software rendering.

---

# Verification of 0.3.3

The core suites now additionally cover four battery percentage placements, power
state labels/translations, clamped levels, a hidden/absent battery with the gear
still available, gear clicks isolated from expansion (including a disabled
configure action), and configurable opening/closing duration with reduced-motion
precedence. The native battery state's API and configure action were checked
against KDE source. No physical battery or native configuration window is present
in this environment; confirm those on a Plasma 6.6+ desktop.

Run `./scripts/test-core.sh` and `python3 scripts/validate-package.py --qml` after
building. Core tests run offscreen on Qt 6.4.2; they do not certify Wayland timing
or hardware charging accuracy.

---

# Verification of 0.3.2

Core offscreen tests additionally cover panel fill-height allocation, manual
height updates, scale affecting width at the height cap, stable top-edge origin
and constant expanded text layout during animation. Core suites and archive/QML
validation pass on Ubuntu 24.04 / Qt 6.4.2.

The native `AttachedDialog` regression fixture (`./scripts/test-popup.sh`) covers
WindowDoesNotAcceptFocus on hover, explicit keyboard focus, no visualParent and
unchanged x/y across show and content resize. It requires Plasma 6 and cannot
run in this development environment. Test compositor-level focus preservation
and first-frame positioning on the user's Wayland desktop.

---

# Verification of 0.3.1

Ubuntu 24.04 / Qt 6.4.2, offscreen. Current tests cover 17 Python cases
(including release numbering/reruns), preview feed seeding and early-expired
arrivals, suppression, queue timeout/deletion, notification pinning, smooth
opening/closing inside a fixed viewport, compact scale/manual height, expanded
header insets and non-overlapping tabs in both languages.

The native notification fixture now also checks previews when history filtering
excludes the application, and deletion of such a preview. Native Plasma 6 modules
are still unavailable in this environment: that fixture and real Wayland animation
are NOT certified here. Run `./scripts/test-notifications.sh` and manually test
`notify-send` after restarting plasmashell. Check preview duration and deletion
from both the widget and KDE notification center.

CI runs `./scripts/test-core.sh`, builds the package and validates QML syntax,
archive integrity and the embedded version before publication. Release numbering
is tested for consecutive merges, reruns, invalid versions and explicit minor bumps.

---

# Verification of 0.3.0

Current development environment: Ubuntu 24.04, Qt 6.4.2, offscreen software
renderer. This environment has no Plasma 6/Kirigami 6 runtime or Wayland desktop.
Do not confuse the historical 0.2.2 validation below with validation of 0.3.0.

Executed successfully:

- 12 Python activity-provider tests: CPU deltas, package operations and queries,
  optional dependencies, LM Studio v1/Ollama fixture contracts, missing/malformed
  endpoints, generation token counters and resets between tasks.
- Notification queue QML suite: preview timeout, replacement, ordered bursts,
  external deletion, bounded pending queue, disabling and pin/automatic priority.
- Expansion QML suite: animated opening/closing, both shapes, 150% scaling,
  notification history UI/translation and loading the activity page.
- English default and Polish catalog coverage; QML syntax parsing.
- Actual local collector snapshot (CPU/RAM, no GPU/AI/audio devices available).

The native suites cannot run here: org.kde.notificationmanager, Plasma, Kirigami,
MPRIS and KDE Connect modules are missing. Shared notification deletion is
implemented against KDE's shared native model, but has NOT been verified against
a running Plasma notification center in this environment. Run
`./scripts/test-notifications.sh` on Plasma 6.6+; it creates a private D-Bus bus
and tests deletion in both directions, preview expiry and deletion after expiry.
Never run that fixture on the live desktop session bus.

Manual target checks before release:

1. Update the installed package and restart plasmashell. Exercise Notch and Island
   on top/bottom panels, floating panels, monitor changes and display scaling.
2. Check that the expanded surface stays attached without a gap throughout its
   animation; verify mouse/keyboard interaction, hover closing and reduced motion.
3. Send a real notification. Confirm the configured preview time, burst ordering,
   history after expiry, removal from either UI and Do Not Disturb behavior.
4. Try height/width limits and expanded scale, then restart to verify persistence.
5. Exercise real package operations, supported GPU counters, player activation,
   LM Studio/Ollama and optional terminal activation under Wayland focus policy.
6. Recheck KDE Connect delivery, calendar sync and existing shelf drag/drop.

Run `./scripts/test-core.sh` for the suites available without Plasma, and
`./scripts/test.sh` for all standard native suites on the target environment.

---

# Historical verification of 0.2.2


Environment: Ubuntu 26.04, Plasma 6.6.6, Qt 6.10.2. Tests run offscreen with a
software renderer and an isolated session bus. No files were sent to real devices.

Passed:

- Compact sizing: automatic fit at 16–128 logical pixels, manual clamping, notch
  top alignment, island centering, click area matching the visible height and
  enabling/disabling the manual height setting.

- Translation tests: catalog coverage, English default independently of system
  locale, Polish/English live switching, lazy-loaded calendar propagation, saved
  language selection, localized dates and KDE Connect status updates.
- QML component tests: media controls and capabilities, shelf validation and
  serialization, shape rendering, agenda display, missing-provider state and date
  navigation across the year boundary.
- Native MPRIS client against a D-Bus fixture: discovery, metadata, transport,
  position and volume, including clamping.
- Native KDE Connect client against a D-Bus fixture: reachable paired device list,
  share capability, exact encoded file URL, successful request acknowledgement,
  D-Bus error, and rejection of a non-local URL.
- Native Plasma Calendar plugin fixture (C++): plugin discovery, asynchronously
  emitted events, month/year boundary, and reload. This caught and guards a
  Plasma agenda-cache behavior affecting non-today dates.
- KPackage installation of the generated .plasmoid into an isolated package root.
- JSON, KConfig XML, shell syntax validation. The initial 0.1 package was also
  loaded by plasmawindowed offscreen; 0.2 component changes are covered above.

The installed KDE Connect module has an empty tooling .qmltypes file, so qmllint
reports unresolved native types even though the runtime integration tests pass.
Calendar's plugin model also exposes an invokable get() that is absent from its
base QAbstractListModel tooling definition. These are known tooling limitations;
we do not claim a warning-free static lint for the integration files.

Still requires target-device testing: actual KDE Connect file delivery, real
Akonadi account synchronization, physical battery status, Wayland panel interaction,
inter-application drag-and-drop, multi-monitor placement and login restoration.
The PIM Events plugin is not installed on the development desktop; the test plugin
was compiled into a temporary build directory and never installed globally.

Run ./scripts/test.sh for the standard suites. Run
./scripts/test-calendar-plugin.sh with Qt 6 Core development files, CMake, a C++
compiler and libkf6declarative-dev for the calendar protocol suite.
