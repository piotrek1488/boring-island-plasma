# Verification of 0.2.1

Environment: Ubuntu 26.04, Plasma 6.6.6, Qt 6.10.2. Tests run offscreen with a
software renderer and an isolated session bus. No files were sent to real devices.

Passed:

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
