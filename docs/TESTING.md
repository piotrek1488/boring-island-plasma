# Verification of 0.4.1

The full applet reproduced an invalid `Window.window.screen.width` read and
height/bodyHeight binding loops during hover expansion. Geometry now uses the
source item's Screen attachment, caches screen bounds/available height before
opening, and queues position updates after native Dialog size synchronization.
Positioning no longer writes the height limit from a height-change callback.

The new full-applet probe copies the package to a temporary directory and invokes
the real hover handler through four open/close cycles (notch/island × smooth/spring).
It isolates XDG configuration/data/cache, checks completion and rejects applet QML
errors. The unchanged 0.4.0 package fails this probe on its screen/geometry errors;
0.4.1 passes on Plasma 6.7.4 / Qt 6.11.2 under X11 and headless KWin Wayland,
with software Qt Quick and Mesa OpenGL. Top and bottom panel locations pass.
Native popup tests pass (11 cases), as does the existing Qt 6.4.2 core suite.
The expansion suite also passes all 30 cases on Qt 6.11.2 with KDE controls;
its loader tests now wait for layout/rendering before checking geometry or clicks.

Run in an isolated bus on a Plasma 6.6+ test machine:

```bash
QT_QPA_PLATFORM=xcb xvfb-run -a dbus-run-session -- python3 scripts/test-panel-hover.py
QT_QPA_PLATFORM=xcb xvfb-run -a dbus-run-session -- python3 scripts/test-panel-hover.py --location bottomedge
QT_QPA_PLATFORM=xcb xvfb-run -a ./scripts/test-popup.sh
```

CI now runs native popup/full-applet tests in addition to core tests, and release
publication requires both jobs. The user's process crash itself was not reproduced
in this environment; a target-system backtrace is still needed to conclusively
associate that crash with these geometry faults. This test environment also emits
unrelated SDK desktop-containment, missing system-bus/device and theme warnings;
the probe rejects errors from the package under test.

---

# Verification of 0.4.0

Core Qt tests exercise activity precedence and zero-notification fallback, media
text rotation (including real upward frames), current playback position after a
notification, zero playback commands, OSD limits/mute/filter/expiry, preview queue
suspension, battery-only mode, and manual Shelf tab preservation. Reminder tests
cover lead/start phases, refresh deduplication, acknowledged persistent state,
failed-delivery retry, all-day exclusion, disabling, and midnight/recurrence.
Python tests include next-month/year ICS lookahead and registered desktop ID
lookup (flat/nested) with rejection of paths/shell syntax. Notification-card tests
cover click-to-open, hover color, icon order, disabled actions, async completion,
and delete without opening. Existing UI/data suites remain enabled.

The native integration fixture now verifies Notify delivery through the Plasma
D-Bus QML module into both shared histories and invoking the reminder's default
action. These modules are unavailable in the Qt 6.4.2 cloud environment, so this
fixture was added but not run here. API signatures were checked against KDE's
Plasma/6.6 D-Bus signal/method autotests and NotificationManager API. Actual OSD
signals, activation tokens, kioclient launching and live Akonadi synchronization
need target-desktop checks. Tests do not access personal accounts or launch real
applications.

---

# Verification of 0.3.10

Agenda tests cover default hiding of finished events, the ↑/↓ toggle, revealing
history above the current agenda, no-remaining-events state, date reset, historical
day access, clock boundaries and scroll stability. No calendar data is mutated.

Both animation styles are tested with configurable duration and reduced motion.
The spring profile is sampled through opening/closing to assert bounded overshoot,
fixed native viewport dimensions, stable top/bottom anchoring and no surface
clipping. Cases include island/notch, screen-size limits, interrupted transitions
and edit-mode dismissal. KConfig/reset parity covers the new style preference.
Native compositor frame pacing still requires a Plasma/Wayland desktop; these
checks run offscreen with Qt 6.4.2 software rendering.

---

# Verification of 0.3.9

Core agenda tests use a fixed local clock and cover ongoing/upcoming/past ordering,
end-exclusive boundaries, all-day events, overnight events, zero-length/missing
times, chronological ordering for other dates, clock-driven updates, preserving
scroll when order is unchanged, and returning to today's first event.

The expansion fixture injects a calendar backend and verifies that brand/date stay
visible, tab coordinates match the media page, the month grid retains at least
200 px of height, and all content fits inside the default 600 × 400 shell. The
KConfig/default-reset parity test verifies the new 400 px height. All core tests
run offscreen; native provider synchronization still needs a Plasma desktop.

---

# Verification of 0.3.8

The core month-calendar fixture runs without Plasma modules using an injected
backend. It checks left/right pane order, grid bounds at normal/narrow/compact
sizes, day selection and agenda updates, month/year navigation, leap-year clamping,
Monday/Sunday week starts, localized month names, Today and event dots. The rendered
568 × 200 calendar pane was visually inspected with offscreen Qt 6.4.2.

Python tests cover whole-month recurrence markers, EXDATE, exclusive multi-day ends,
month-boundary clipping and zero-length events. Existing calendar/notification/UI
suites remain in the core run. Native KDE event marker population and live ICS
refresh still require target-desktop verification; no personal account was used.

---

# Verification of 0.3.7

Core tests cover minimum compact width fitting/overrides/scaling, 600 × 330 total
expanded geometry, close button placement and isolated clicks, the year in the
header, and clicking individual history rows using KDE's notificationId role.
The isolated native notification fixture now exercises the real delete button
with two notifications and checks that only one disappears from both histories.
It requires Plasma modules and cannot run in this cloud workspace.

Python calendar tests use real icalendar/recurring-ical-events libraries with local
fixtures: recurrence, EXDATE, all-day exclusive ends, cancelled events, overnight
UTC/local conversion, partial-source errors, private KConfig source loading,
end-to-end CLI invocation, network caching and explicit refresh. Network calls are
mocked; no Google/Microsoft account or personal calendar was accessed. Core tests
require the optional calendar requirements installed in the test environment.
Native DataSource/KConfig Apply timing and actual provider subscription refresh
still need target-desktop verification.

---

# Verification of 0.3.6

Core tests verify reset values against every KConfig preference (excluding shelf
content), a 400 ms default, restoring control aliases, preserving shelf data and
unrelated fields, immediate collapse/disabled input during editing, and disabled
input on the reparented compact visual. Existing animation, notification and
battery suites remain enabled.

The native configuration fixture also exercises restoring all cfg_ properties on
the real Kirigami form. It requires Plasma/Kirigami modules unavailable here.
Panel editing detection uses containment.userConfiguring and corona.editMode, as
exposed by KDE. The actual panel remove controls and Apply/Cancel integration
still require testing on a Plasma 6.6+ desktop.

---

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
