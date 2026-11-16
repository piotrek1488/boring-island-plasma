# 0001 — plasmashell SIGSEGV in libdbusplugin when a calendar reminder is sent

- **Status**: fixed (second attempt; the first fix was based on a wrong cause)
- **Affected**: Boring Island 0.4.4 on Plasma 6.6.6 / plasma-workspace
  4:6.6.6-0ubuntu0.1, Qt 6, Wayland (Ubuntu 26.04)
- **Severity**: high — plasmashell crash loop, desktop never comes up

## Symptom

plasmashell crashed repeatedly with `SIGSEGV`; systemd/KCrash restarted it into
the same crash until it gave up. Every crash (12, 13 and 16 Nov) has the same
kernel line:

```
kernel: plasmashell[...]: segfault at 0 ip ...6a9 ... in libdbusplugin.so[246a9,...]
```

## Evidence

Backtrace (systemd-coredump, with plasma-workspace debug symbols):

```
#6  Decoder::dbusToVariant(QVariant const&)     dbusdecoder.cpp:85   libdbusplugin.so +0x246a9
#7  Decoder::decode(QDBusMessage const&)        dbusdecoder.cpp:108
#8  Plasma::DBusPendingReply::callInternal(...)::<lambda(QDBusPendingCallWatcher*)>
                                                dbuspendingreply.cpp:83
#15 QDBusPendingCallWatcher::finished
```

The faulting instruction is `mov 0x0,%eax; ud2`. In the core (PID 1399890) the
reply being decoded had exactly one argument: a `QVariant` of metatype `uint`
(typeId 3) flagged `is_null = 1`. `org.freedesktop.Notifications.Notify` returns
a `uint32` notification id. `Plasma::DBusPendingReply` is the reply object of
`DBus.SessionBus.asyncCall(...)` from the QML module
`org.kde.plasma.workspace.dbus`, which `NativeServices.notify()` used to send
reminders.

Controlled experiment (`asyncCall` from that QML module):

| Call | Result |
|---|---|
| out-of-process mock returning `uint`, `string`, nothing | OK |
| the applet's exact `Notify` call (signature, `DBus.uint32`, `-1`) to an out-of-process mock | OK, `value=4` |
| the same `Notify` to the **real Plasma server**, from a separate process | OK, `value=16` |
| the same `Notify` to the notification server **in the same process** (integration fixture, which hosts `NotificationManager::Server` in-process like plasmashell) | **SIGSEGV at `dbusdecoder.cpp:85`** |

Only the in-process case crashes, so neither the reply type nor the call shape is
the cause.

## Root cause

plasmashell hosts `org.freedesktop.Notifications` itself
(`/usr/share/dbus-1/services/org.kde.plasma.Notifications.service`), and the
applet runs inside plasmashell. A D-Bus method call from a process to a service
owned by its own connection is delivered by Qt locally, without going through the
bus. The QML D-Bus decoder in plasma-workspace 6.6.6 dereferences null on that
locally delivered `uint` reply. So **every** reminder the applet sent crashed
plasmashell, whenever it was sent — not only at startup.

The loop: the crash happens before the reply callback, so the reminder is never
acknowledged (`reminderStateJson` stayed empty). After the restart the same
reminder is still due and fires again, until its time window passes.

Inferred, not proven: the core cannot name the destination service (QtDBus
private types have no symbols). The `uint` reply type, the experiment and the
fact that the loop stopped once the reminder window ended all point to the
applet's `Notify`. Other installed applets also use `asyncCall` from the same
module, but call methods that do not return `uint`.

## The first fix was wrong

Commits `4024467`/`065f25b` gated `Notify` until `NM.Server.valid`, on the theory
that only an early reply during shell startup was degenerate. That only delayed
the crash to the first reminder sent after startup. The crash loop on 16 Nov
happened with that gate installed. The gate has been removed.

Also corrected: the integration fixture crashing in offscreen mode was not "a
synthetic server reply shape". It is this same in-process bug, because the
fixture hosts the real notification server in-process.

## Fix

`NativeServices.notify()` now sends reminders with KNotification
(`org.kde.notification`, the KF6 library plasmashell itself uses), using the
`plasma_workspace` / `notification` event:

- KNotification talks to the server through C++ QtDBus, which handles in-process
  calls correctly; the QML `asyncCall` decoder is no longer involved.
- plasmashell stays the sender. Plasma's server clears a notification's actions
  when its sender disconnects (verified: a short-lived sender loses the default
  action within ~300 ms), so sending from a child process (e.g. `busctl`) was
  rejected: it avoided the crash but broke click-to-open.
- The default action is a `NotificationAction` whose `activated` signal opens the
  calendar page, so the `ActionInvoked`/`NotificationClosed` signal watchers and
  the id bookkeeping were removed.
- `delivered(key)` is emitted after `sendEvent()`; KNotification does not report
  the server id to QML.

Visible change: the notification's application name is Plasma's system
notifications component instead of "Boring Island".

## Verification

- Integration suite (`scripts/test-notifications.sh`) on the affected machine
  (Plasma 6.6.6): **12/12 pass**. Before this fix the runner always crashed with
  this exact SIGSEGV before finishing. New regression test
  `test_reminder_in_process_keeps_text_and_action`: with the server in-process,
  sending does not crash, a title containing quotes, `$()`, backticks, a leading
  dash and non-ASCII arrives verbatim, and the default action survives.
  `test_native_reminder_joins_shared_history` covers click-to-open.
- OSD suite: 7/7. Core suite (with the calendar venv): 39 Python tests + 11 QML
  suites pass. Package builds and validates.
- Not verified on the live desktop yet: sending a real reminder from the
  installed applet. That requires a calendar event inside the reminder window.

## Open questions

- Report the null dereference in `Decoder::dbusToVariant` for locally delivered
  replies upstream (plasma-workspace). CI (Debian unstable, Qt 6.11.2) passed the
  old in-process test, so a newer plasma-workspace probably no longer crashes;
  not checked against upstream sources.
- The `prepareDialog()` screen guard (`9b5ecfd`) came from an earlier, also
  unconfirmed hypothesis about this crash. It is harmless defensive code and was
  kept.
