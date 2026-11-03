# Boring Island for KDE Plasma

**English** | [Polski](README.pl.md)

A native Linux plasmoid inspired by the `dev` branch of
[boring.notch](https://github.com/TheBoredTeam/boring.notch/tree/dev).
Version **0.2.1** requires **Plasma 6.6+**. This is an unofficial reimplementation,
not a complete port of every macOS feature.

![Dynamic Island](docs/dynamic-island.png)

## Installation

Download the `.plasmoid` package from [Releases](https://github.com/piotrek1488/boring-island-plasma/releases)
and install it through Plasma's **Add Widgets → Get New Widgets → Install Widget
From Local File**. Add **Boring Island** to your desktop or a top panel.

Alternatively, from a source checkout:

```bash
./scripts/install.sh
```

Plasma saves the widget and its settings and restores them at login. No separate
service or autostart entry is needed.

An optional helper creates a small, centered top panel:

```bash
./scripts/add-top-panel.sh
```

It preserves existing panels and avoids adding a second copy if a panel already
contains Boring Island. The helper has not been tested on the user's live desktop.
If you already have a top panel, add the widget there manually to avoid overlap.

## Language and appearance

Right-click the widget and open its settings, then select **Boring Island**.

- **Language:** English by default, or Polski. The selection is saved for each
  widget separately and does not follow the system language. Labels, hints,
  accessibility descriptions and dates update when the setting is applied.
- **Notch:** a flat top edge and rounded bottom corners.
- **Dynamic Island:** a rounded capsule; the default shape.
- Configure compact width, hover delay, battery visibility and reduced motion.

Device names, filenames, track metadata and event content remain in their original
language. External KDE dialogs and service error details use their own language
settings. The configuration category uses the language-neutral name Boring Island.

For an island effect, enable a floating panel in Plasma settings. For a notch,
disable floating and place the panel at the top edge. Plasma's theme still controls
the panel background and margins. In a panel, the expanded view is a standard
Plasma popup; on the desktop, it expands inside the widget's allocated area.
It does not create an independent overlay above every window or a physical cutout.

## Features

- MPRIS media controls: previous/next track, play/pause, cover art, title, artist,
  position, seeking and **player** volume.
- KDE's automatic player selection, with controls respecting player capabilities.
- An idle clock and a date in the expanded view.
- A daily agenda from KDE/Akonadi calendars: timed and all-day events, calendar
  colors, previous/next day navigation and refresh.
- File sharing from the shelf through KDE Connect: click ↗, choose a paired and
  reachable device, then click **Send**. Dropping a file never sends it automatically.
- Internal battery percentage and external power status; hidden on systems without
  an internal battery. `+` means external power, not necessarily active charging.
- A persistent shelf of up to 24 local file/folder shortcuts: drop, open, drag out
  or remove a shortcut with ×. Removing a shortcut never deletes the original.
- Independent settings and shelf contents for each widget instance.

The shelf stores addresses only. Moving or deleting the original breaks its
shortcut. MPRIS support and available controls depend on the player. An empty media
view means no active MPRIS source. Player volume does not change system volume.
Cover art may be fetched from URLs supplied by the player.

## KDE Connect and calendars

**KDE Connect:** install it on the computer and receiving device, connect both to
the same network and pair them. Enable the sharing plugin. Click ↗ beside a shelf
file and **Send** beside a device. The ⚙ button opens pairing settings.

Only paired, reachable devices appear. Devices without the sharing capability have
a disabled button. The widget acknowledges handing the request to KDE Connect;
this does **not** confirm delivery. KDE Connect notifications report progress and
final errors. Archive a folder before sending it; this integration sends files.

**Calendars:** install Plasma's **Calendar Events** (`pimevents`) plugin and configure
calendars in Akonadi/KOrganizer. Ubuntu provides the plugin in `kdepim-addons`; it
is not bundled in the plasmoid package. In the Plasma clock settings, enable the
calendar events plugin and select your calendars. Reload the widget after installing
the plugin.

The widget shares the calendar selection within the Plasma process. It does not
copy events or store account passwords. `plasmawindowed` has separate application
configuration, so it may not see the calendar selection used by `plasmashell`.
The intended host is the Plasma panel or desktop. A missing plugin produces setup
instructions rather than a misleading empty agenda. Create or edit events in
KOrganizer; the widget's agenda is read-only.

## Scope and limitations

Not implemented: AirDrop, camera preview, lyrics, clipboard history, a full
notification queue, measured audio visualization, system OSD replacement and
fullscreen detection. See the [source analysis, in Polish](docs/ANALIZA.md).

The MPRIS and battery integrations use **private Plasma APIs**. The verified
environment is Plasma 6.6.6 / Qt 6.10.2 on Ubuntu 26.04. Plasma 5 and older Plasma 6
versions are not supported. Future API changes may require updates.

## Development and testing

```bash
./scripts/test.sh
python3 ./scripts/package.py  # creates build/boring-island-0.2.1.plasmoid
plasmawindowed ./package
```

The standard suites require Qt Quick Test (`qmltestrunner`), `dbus-run-session`,
`python3-dbus`, `python3-gi` and the KDE Connect QML module. Set `QMLTESTRUNNER` if
your distribution installs the runner elsewhere. No translation compilation step
is required: the English/Polish catalog ships inside the package.

The optional native calendar provider test requires CMake, a C++ compiler, Qt 6
Core development files and `libkf6declarative-dev` headers:

```bash
./scripts/test-calendar-plugin.sh
```

It builds a local test plugin and checks asynchronous events and month/year
boundaries. Never install the test plugin into the system plugin directory.

Tests use isolated D-Bus fixtures and synthetic calendar events. They do not send
files to a real phone or access private calendars. Real-device transfer, Akonadi
account synchronization, interactive Wayland panel behavior, physical battery
status, inter-application drag-and-drop, multi-monitor placement and login
restoration still need target-device testing. Screenshots use test data.
See [verification details](docs/TESTING.md).

## Uninstall

Remove the widget from the panel or desktop, then run:

```bash
kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.boringisland
```

Licensed under GPL-3.0-only. See [NOTICE.md](NOTICE.md) for attribution.
