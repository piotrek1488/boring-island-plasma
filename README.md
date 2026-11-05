# Boring Island for KDE Plasma

**English** | [Polski](README.pl.md)

A native Linux plasmoid inspired by the `dev` branch of
[boring.notch](https://github.com/TheBoredTeam/boring.notch/tree/dev).
Version **0.4.2** requires **Plasma 6.6+**. This is an unofficial reimplementation,
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
- **Notch:** outward-curving top shoulders and rounded bottom corners.
- **Dynamic Island:** a rounded capsule; the default shape.
- **Fit height to panel:** enabled by default; follows the panel window height.
- Edit **Compact height (px)** from 16 to 128 to disable automatic fitting. The
  shape uses the requested height multiplied by compact scale. Text, indicator and padding
  scale with the height; compact width remains independently configurable.
- A smaller notch stays aligned to the top edge of the panel window; a smaller island
  is centered vertically. On the desktop, automatic height is 42 px.
- Sizes use Qt logical pixels, so desktop display scaling still applies. The notch bypasses internal applet padding/clipping; the expanded content has separate width, height and 60–200% scale controls.
- Configure hover delay, battery visibility and reduced motion.

Device names, filenames, track metadata and event content remain in their original
language. External KDE dialogs and service error details use their own language
settings. The configuration category uses the language-neutral name Boring Island.

For an island effect, enable a floating panel in Plasma settings. For a notch,
disable floating and place the panel at the top edge. Plasma's theme still controls
the panel background and margins. The expanded view uses a single animated surface containing the compact header and
content. In a panel, a frameless Plasma dialog overlays the compact widget at its
screen position, with no themed popup gap. The desktop view uses the same surface.
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
- Battery icon with charge level and actual KDE charge state: charging, discharging,
  fully charged or plugged in without charging. Hidden without an internal battery.
  Percentage can appear inside, left/right of the icon, or be hidden. The old `+`
  power indicator has been replaced by a bolt to the left, only while charging.
  At 20% or less the icon turns red; an unplugged battery shows a temporary low
  battery message once per discharge episode, using the notification preview duration.
- A persistent shelf of up to 24 local file/folder shortcuts: drop, open, drag out
  or remove a shortcut with ×. Removing a shortcut never deletes the original.
- Independent settings and shelf contents for each widget instance.

The shelf stores addresses only. Moving or deleting the original breaks its
shortcut. MPRIS support and available controls depend on the player. An empty media
view means no active MPRIS source. Player volume does not change system volume.
Cover art may be fetched from URLs supplied by the player.

## Notifications and activity

- **Notifications:** a preview appears inside the notch/island for **4 seconds** by
  default (configurable from 1 to 60 seconds). Bursts are queued, with at most 20
  pending previews. Expiry hides only the preview, leaving KDE's history intact.
- Hover or click to expand, then choose **Notifications**. Delete one entry with
  **×**, or use **Clear all**. This uses Plasma's shared notification model:
  deleting here removes it from KDE's notification center, and vice versa.
  Existing history is not replayed when the widget loads. Live arrivals use a
  separate native model so history filters and early expiry do not drop previews. Do Not Disturb and
  application popup/history preferences are respected. Transient notifications
  still follow KDE's retention rules; the widget does not keep a private archive.
- **Automatic priority:** volume/brightness feedback → new notification → playing
  media → nonempty shelf → package activity → local AI → preferred view/idle.
  The preferred panel view is a fallback, not a hard pin: Notifications with a zero
  count falls back to idle. Temporary messages restore the current underlying
  activity without sending playback commands. Manual tabs remain selected while
  the expanded widget is in use.
- **System:** CPU/RAM and available GPU utilization. AMD-compatible sysfs counters
  and optional `nvidia-smi`/`intel_gpu_top` are supported; unsupported GPUs are omitted. Click ↗
  to launch Plasma System Monitor, or `top` in Konsole as a fallback.
- **Packages:** detects command-line operations from APT/dpkg, pacman, DNF/Yum,
  Zypper, Flatpak, pip and npm. The moving bar means activity, not a measured
  percentage. Disappearing processes are not reported as successful installs.
  Processes hidden by system permissions cannot be detected. Discover/PackageKit
  operations are not guaranteed to be detected. Focusing the terminal requires
  optional `kdotool`; Wayland focus policy can still prevent activation.
- **Local AI:** optional, disabled by default. Reads loaded models and context from
  LM Studio (localhost:1234, REST v1 with v0 fallback) or Ollama (localhost:11434).
  Shows inference-process CPU/RSS when readable, and Ollama's reported model memory.
  Generation state and tok/s are shown only when an LM Studio inference process
  exposes an accessible local llama-server `/slots` endpoint with decoded-token
  counters. An unavailable measurement stays unknown. Authenticated/custom-port
  APIs and Ollama's live generation rate are not supported.
- **Media:** retains MPRIS controls, adds a button to raise the player when supported
  and an optional audio output label via `pactl`. The pulsing indicator is decorative.
- **Size:** retain Notch/Dynamic Island, panel height fitting and manual compact
  height. Compact width now supports 80–1000 logical pixels, optionally used as an
  automatic-width limit. Expanded width, height and content scale are independent.
  **Compact scale (%)** (50–200%) also adjusts the collapsed height, width and text;
  the shape bypasses the smaller applet allocation. Editing manual height disables auto-fit.
  Reduced motion disables the expansion and pulse animations.

The optional activity provider requires **Python 3** and Plasma's
`org.kde.plasma.plasma5support` executable data engine. It is started by the widget
for each snapshot (~every 3 seconds), without a service or autostart entry. Disable
individual monitors to stop querying their data; local AI never receives prompts
from the widget. Notifications require the native `org.kde.notificationmanager`
module and the **plasmashell process**. A separate `plasmawindowed` process cannot
share in-memory notification history with the desktop. System notification popups
remain governed by KDE; this version does not globally disable them.

### Build and update

From your local clone:

```bash
git pull --ff-only origin main
python3 scripts/package.py
kpackagetool6 --type Plasma/Applet --upgrade build/boring-island-0.4.2.plasmoid
systemctl --user restart plasma-plasmashell.service
```

For a first installation use `--install` instead of `--upgrade`. The restart
reloads the desktop/panels without logging out; running applications stay open.
Alternatively, `./scripts/install.sh` chooses install or upgrade from source.
Settings and shelf shortcuts are retained. Live Wayland positioning and shared
notification deletion still need testing on a Plasma 6.6+ desktop; see
[verification status](docs/TESTING.md).

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

Not implemented: AirDrop, camera preview, lyrics, clipboard history, measured audio visualization, system OSD replacement and
fullscreen detection. See the [source analysis, in Polish](docs/ANALIZA.md).

The MPRIS, battery, dialog and notification integrations use **private Plasma APIs**.
Earlier releases were verified on Plasma 6.6.6 / Qt 6.10.2 on Ubuntu 26.04.
The 0.3.1 core tests run on Qt 6.4.2 without a Plasma session. Plasma 5 and older Plasma 6
versions are not supported. Future API changes may require updates.

## Development and testing

```bash
./scripts/test.sh
python3 ./scripts/package.py  # creates build/boring-island-0.4.2.plasmoid
plasmawindowed ./package
```

The standard suites require Qt Quick Test (`qmltestrunner`), `dbus-run-session`,
`python3-dbus`, `python3-gi` and the KDE Connect QML module. Set `QMLTESTRUNNER` if
your distribution installs the runner elsewhere. No translation compilation step
is required: the English/Polish catalog ships inside the package.

The core activity, queue and expansion suites can also run without Plasma:

```bash
./scripts/test-core.sh
```

The shared notification integration test requires Plasma 6.6+ modules, `gdbus`,
CMake, a C++ compiler and Plasma Workspace development files
(`plasma-workspace-dev`, Qt Quick Test and KF6 Config development packages):

```bash
./scripts/test-notifications.sh
```

It uses its own private D-Bus session; do not run the QML fixture on your desktop bus.

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

## Automated releases

[GitHub Actions](.github/workflows/release.yml) runs core/updater tests, native KDE
forms/popup/notification tests and an isolated package-upgrade test, then validates
the package on pull requests. Every push/merge to `main` then publishes a GitHub release
with the `.plasmoid` and `SHA256SUMS`; it can also be run manually on `main`.
The workflow uses actions/checkout **7.0.1** and actions/setup-python **7.1.0**
(the latest stable releases checked on 2026-11-05), and the GitHub CLI to publish.
Only the publication job has `contents: write`; no extra secret is required.

The first release uses the metadata version if it is newer than existing tags.
Subsequent merges increment the latest patch version automatically; raising the
metadata version selects a new minor/major release. The built package embeds that
version without a bot commit to the source. A rerun reuses an existing tag on the
same commit and leaves an already published release unchanged. Jobs are serialized
to avoid version collisions. Publication requires both core and native jobs.
Interactive Wayland behavior and real hardware still need desktop testing.

### Overlay interaction (0.3.2)

Hover and notification previews use a nonactivating Notification window role,
so the current application keeps focus. A click inside switches the overlay to
an interactive AppletPopup and requests activation. Controls keep their original
click actions. Opening with a keyboard shortcut/Enter/Space also enables focus.
The overlay has no automatic Plasma visual parent: its position is set before
the first expansion frame, and its compact origin/size are held during expansion.
Collapsed content has at least 28 logical pixels of side padding for a notch
(22 for an island), including when compact scale is reduced.
The compact shape follows manual height multiplied by compact scale. Since 0.3.4,
it renders directly in the panel content item, bypassing applet padding and clipping.
The panel window remains the physical drawing boundary; increase the panel height
if the requested shape is taller than that window. A non-floating top panel is
required to reach the physical screen edge. Fixed-size header text layers cross-fade instead of resizing each frame.

`./scripts/test-popup.sh` adds native Plasma tests for nonactivating hover, stable
show/resize position and explicit keyboard focus. It needs Plasma 6 modules;
real compositor animation and focus should also be checked on Wayland.

### Battery, settings and animation speed (0.3.4)

The header's **gear button**, to the right of the battery, opens this widget
instance's native Plasma settings, only in the expanded header. It remains available there when battery display is
disabled or the computer has no internal battery. It follows the availability of
Plasma's configure action; clicking it does not toggle the expansion.

In settings, **Battery percentage** selects Inside the icon / Left of the icon /
Right of the icon (default) / Hidden. Only actual charging shows a bolt, positioned
to the left of the battery. Full and plugged-in states have no badge; hover for the
localized status and exact percentage. These use the existing private KDE battery
model, with no extra polling or service.

**Animation duration (ms)** controls opening and automatic width changes,
from 50 to 1000 ms. The new default is **400 ms**. Lower values
are faster; this changes duration, not display refresh rate. Hover delay remains
independent. After the pointer leaves, a manually opened view waits 30 ms for
header/body hover handoff, then closes with an InOutCubic curve in 70% of the
opening duration, bounded to 100–220 ms (220 ms by default).
Reduce motion overrides both durations with no animation.

### Defaults and panel editing (0.3.6)

The default animation duration is now **400 ms**. Existing saved values are kept;
use **Restore default settings** at the bottom of the Boring Island settings page
and then **Apply** or **OK** to reset all appearance/behavior preferences, including
language and animation duration. **Cancel** discards the draft reset. Shelf
shortcuts and Plasma's panel placement/global shortcut are preserved.

While configuring the widget, editing its panel, or using Plasma's global edit
mode, expansion is blocked. Existing popups close immediately, hover timers stop,
and notification previews are suppressed without deleting KDE history. The compact
shape returns inside its applet allocation with input disabled, exposing Plasma's
edit/remove controls. Closing edit mode restores normal behavior.

### Size, header and notification fixes (0.3.7)

Automatic compact width now has a configurable **Minimum compact width (px)**,
default **180** (lower it to 80 if preferred). The existing compact width remains
the upper limit and wins if set below that minimum. Compact scale applies after
fitting. Expanded defaults are **600 × 330 logical pixels**; expanded height now
includes the header instead of adding the header to the configured height.
Saved values remain unchanged; reset preferences to apply the new defaults.
Reset is the last settings control. The expanded header has **battery → settings
→ close**; the date includes the year. Individual notification deletion now uses
KDE's `notificationId` role, preserving shared-history synchronization.

## Google and Outlook calendars without Akonadi

The **ICS subscriptions / files** calendar source reads Google Calendar and
Outlook subscription feeds independently of Akonadi/PIM Events. It is read-only;
changes are made in the original calendar service. Up to 16 feed URLs/local ICS
paths can be entered, one per line. It supports recurring events, exclusions,
all-day/multi-day events and local timezone conversion. Feeds refresh every five
minutes while the agenda is loaded; ↻ fetches immediately. Google/Microsoft may
update their exported feed later than their own application.

From a source checkout, install the optional calendar libraries once:

```bash
./scripts/install-calendar-deps.sh
```

This creates a dedicated Python venv in `$XDG_DATA_HOME/boring-island/calendar-venv`
(default `~/.local/share/boring-island/calendar-venv`). Python 3 with `venv` and pip
is required; on Debian/Ubuntu install `python3-venv` if venv creation is unavailable.
Then select **Calendar source → ICS subscriptions / files**, paste the addresses,
and press **Apply** or **OK**. Existing KDE/Akonadi mode remains available.

- **Google Calendar:** on the website, open Settings → select the calendar →
  Integrate calendar → **Secret address in iCal format**, then copy that address.
  [Google instructions](https://support.google.com/calendar/answer/37648).
- **Outlook:** open Calendar settings → Shared calendars → Publish a calendar,
  choose the calendar/permissions, publish it and copy the **ICS** subscription
  link, rather than the HTML link.
  [Microsoft instructions](https://support.microsoft.com/en-us/outlook/share-your-calendar-in-outlook-com).
  Work/school policies may prevent calendar publishing; this feature does not
  bypass those policies or provide Microsoft/Google OAuth sign-in.
- A local `.ics` file or `file:///…` URL is also supported; it is reread when the
  agenda refreshes. A downloaded export is a snapshot, not a live subscription.

Subscription URLs can grant access to calendar contents. They are saved in the
widget's Plasma configuration and are read directly by the helper, never passed
as process arguments or included in error messages. Downloaded feeds are cached
under `$XDG_CACHE_HOME/boring-island/calendars` with user-only file permissions.
Resetting preferences removes the configured sources but preserves shelf data.

Development tests additionally require:

```bash
python3 -m pip install -r package/contents/code/requirements-calendar.txt
```

Run this inside a development venv where system Python enforces PEP 668.

### Month calendar (0.3.8)

The Calendar tab shows the selected day's agenda on the **left** and a complete
six-week month grid on the **right**. Select any day to update the agenda. Month
arrows cross year boundaries and clamp the selected day to the destination month's
length; **Today** restores the current month/day. Names and week start follow the
widget language. Today's date, the selected date and days with events have distinct
markers. Both KDE/Akonadi and ICS sources provide current-month event markers.
ICS recurrence is expanded once per month; the agenda still lists only the selected
day. Older asynchronous ICS responses are discarded after changing the selection.

The calendar tab hides the duplicate brand/date row and uses tighter outer spacing
to fit both panes within the default 600 × 330 expanded widget. Event lists and
status messages scroll independently of the month grid.

### Current events and consistent calendar layout (0.3.9)

Today's agenda puts ongoing timed events first, then upcoming events from nearest
to latest, all-day events, and finished events from most recently ended to oldest.
Finished events remain available below. Other dates use chronological order with
all-day events first. The order is refreshed every 30 seconds and on data changes;
an unchanged order preserves the user's scroll position. Selecting another date
starts its agenda at the top.

The brand/date row and tab positions now stay identical across pages, including
Calendar. The default expanded size is **600 × 400 logical pixels**, leaving room
for the original header, spacing and the full month grid. Existing saved heights
are preserved: if yours is 330, change **Expanded height (px)** to **400**. This
avoids resetting other preferences or configured calendar sources.

### Earlier events and animation styles (0.3.10)

Finished timed events are hidden by default in today's agenda. A circular **↑**
button appears beside the day controls when earlier events exist; its tooltip and
accessible name include their count. Clicking it reveals earlier events above the
current agenda, oldest first. **↓** hides them again. Changing the day or reopening
the calendar resets this toggle. Explicitly selected past/future dates still show
their full day. When only finished events remain, the empty-state message and ↑
button let you choose whether to show them. Calendar source data is never deleted.

**Animation style** offers **Smooth** (the existing default) and **Dynamic Island —
spring**. Smooth opens with OutQuint and closes with InOutCubic. The new style uses
a bounded OutBack curve (overshoot 0.85) for a small spring-like expansion and soft
settling, plus a short content reveal. It is inspired by Dynamic Island, using our
own Qt animation rather than Apple's implementation. Closing remains quick and
smooth. Both styles respect the configured duration and Reduce motion; the latter
also removes overshoot. The style applies to full expansion and notification
previews, for both notch and island shapes.

Spring motion reserves a small static transparent envelope before the popup opens,
so the native window does not resize or shift during the bounce. The shape remains
attached to its original edge, and motion is bounded by the screen dimensions.

## Live compact activity (0.4.0)

The idle view is configurable: **Clock and battery** (default), **Date, clock and
battery**, **Date and battery** (without the time), or **Battery only**. Battery-only falls back to the clock when the
battery is hidden or unavailable. Existing battery percentage placement is kept.
A playing MPRIS source takes precedence over shelf/history/preferences. The
collapsed title cycles upward to **elapsed / total time**, then back to the title,
every four seconds by default (configurable 1–15). Missing total duration displays
an em dash. KDE's MPRIS metadata supplies the title or filename when available.
Reduced motion switches the text without sliding. Text-width measurement reserves
both frames so the notch does not alternate widths on each cycle.

Notifications only take over the display. They **never pause, stop, seek or resume
the player**. Playback position continues to update while a preview is visible;
afterward the current activity is shown again. A nonempty shelf shows its item
count and becomes the default opening tab when nothing is playing. Emptying the
shelf restores the next activity/fallback. A manually opened tab is not replaced
by automatic activity changes.

**Show volume and brightness in the compact widget** adds a live icon/bar/percent
using Plasma's OSD signals, with a configurable timeout (default two seconds after
the last change). Notification previews and the low-battery message are held while
this feedback is visible, then receive their full display duration. KDE's own OSD
remains enabled: these are additional indicators, not a global OSD replacement.
The feature depends on KDE emitting OSD events for the change; unsupported hardware
or other applications' private sliders may not emit them.

**Calendar reminders** run independently of the Calendar tab for the configured
KDE/Akonadi or ICS source. Defaults: 15 minutes before and at the start, for timed
events; all-day events are excluded. Set lead time to zero for start-only reminders,
or disable reminders entirely. Tomorrow is included for reminders before midnight,
including month/year boundaries. ICS uses its normal five-minute refresh/cache.
Delivery uses KDE's notification service and shared history; clicking a live
reminder opens the widget's Calendar tab. Do Not Disturb and notification popup
preferences still apply. The per-widget delivery journal survives normal restarts
and prevents refresh duplicates. Start reminders have a two-minute catch-up window;
old missed reminders are not replayed after long sleep/offline periods. Existing
KOrganizer/provider alarms can also notify independently. Resetting preferences
preserves the delivery journal, as well as shelf data.

Notification cards and previews now have **↗ before ×**, a clickable body and a
subtle hover highlight. The default notification action is preferred, preserving
links to the original message/document and native activation. In history, an
installed sender's desktop entry can be launched through `kioclient`/`kioclient6`
when the original action has expired. No command is constructed from notification
body text. If no action or recognized application identifier is available, opening
is disabled. Successfully handing off an open action removes that notification
from both the widget and KDE history. A failed application launch keeps the entry;
× still deletes without opening anything. Actual window activation is
subject to the application's behavior and compositor policy.

## Settings and updates (0.4.2)

The settings form has a permanent vertical scrollbar. Scroll to its bottom to
reach **Restore default settings**; Apply/OK saves the reset and preserves shelf
shortcuts. The tab rows and category content are centered, including wrapped tab
rows and wider expanded widgets. Preview notifications have symmetric side margins.

Open settings → **About / O programie** → **Check for updates**. If a newer stable
release is available, **Install update** downloads it from this repository's GitHub
releases. The updater checks SHA-256 against the release's SHA256SUMS, checks the
package ID/version and upgrades with `kpackagetool6` as your user. Python 3 and
`kpackagetool6` are required; no root password or calendar dependencies are needed.
Your settings stay in place. Installation is only performed on button click;
updates are not checked or installed automatically.

After installation, click **Restart Plasma**, or log out and back in. Restart is
separate from installation and closes the widget/settings window. Network/rate-limit
errors can be retried; a failed verification does not install the package. The
manual download/install method remains available. Install 0.4.2 manually once to
get these controls for subsequent releases.
