# 0001 — plasmashell SIGSEGV in libdbusplugin on calendar-reminder Notify at startup

- **Status**: fixed
- **Affected**: Boring Island 0.4.4 on Plasma 6.6.6, Qt 6, Wayland (Ubuntu 26.04)
- **Severity**: high — plasmashell crash loop, desktop never comes up

## Symptom

plasmashell crashed repeatedly with `SIGSEGV`, and systemd restarted it into the
same crash until it gave up, leaving the panel and desktop gone. Kernel log for
every crash (10 occurrences across 12–13 Nov):

```
kernel: plasmashell[...]: segfault at 0 ip ...6a9 ... in libdbusplugin.so[246a9,...]
systemd[...]: plasma-plasmashell.service: Main process exited, code=dumped, status=11/SEGV
```

Always `segfault at 0` (null dereference), always the same module and offset
`libdbusplugin.so + 0x246a9`.

## Evidence

A real core dump was captured by systemd-coredump (PID 486235, 13 Nov 17:30).
Backtrace of the crashing thread:

```
#0  Decoder::dbusToVariant(QVariant const&)                          libdbusplugin.so +0x246a9
#1  Decoder::decode(QDBusMessage const&)                             libdbusplugin.so +0x54f6c
#2  Plasma::DBusPendingReply::callInternal(...)::<lambda(QDBusPendingCallWatcher*)>
...
#9  QDBusPendingCallWatcher::finished
```

The crashing instruction at `0x246a9` is `mov 0x0,%eax; ud2` — the compiler's
pattern for reading a value that was assumed non-null. Confirmed the kernel's
fault address equals the gdb frame #0 address (`...3d68a6a9`). `libdbusplugin.so`
is stripped, so frame locals were not recoverable; the null value itself was not
read out of the core, only inferred from the instruction and the call chain.

The reply-decoding path (`DBusPendingReply::callInternal` → `Decoder::decode`)
is reached only from `DBus.SessionBus.asyncCall(..., resolve, reject)`. In this
package that call exists in exactly one place: `NativeServices.notify()`, which
sends `org.freedesktop.Notifications.Notify` for calendar reminders.

The notification service is hosted by plasmashell itself:

```
/usr/share/dbus-1/services/org.kde.plasma.Notifications.service
Name=org.freedesktop.Notifications
Exec=/usr/bin/plasma_waitforname org.freedesktop.Notifications
```

Crashes happened a few seconds after each shell start (process 132432 lived ~7s),
and the journal shows calendar activity right before the fault
(`akonadiserver: PlasmaEventModelMonitor`). `ReminderScheduler.evaluate()` runs on
`Component.onCompleted`, so a reminder due at startup fires `notify()` immediately —
before plasmashell's own notification server owns the name. Decoding that early /
degenerate reply crashed the whole process, and the reminder stayed due after the
restart, producing the loop.

## Root cause

`NativeServices.notify()` called `asyncCall(Notify)` unconditionally, including
during shell startup when `org.freedesktop.Notifications` was not yet owned. The
reply decoder in `libdbusplugin.so` dereferences null on the resulting early/empty
reply instead of surfacing an error. The decoder bug belongs to plasma-workspace,
but the plasmoid was the trigger by emitting Notify too early.

## Fix

Gate `Notify` on the notification server being ready, and queue anything
requested before then (`package/contents/ui/NativeServices.qml`):

- new `notificationsReady` property, bound in `main.qml` to
  `notifications.available` (= `NM.Server.valid`);
- `notify()` pushes onto `pendingNotifications` while not ready and returns
  without calling `asyncCall`;
- `flushPending()` drains the queue through `deliver()` once ready.

This removes the early `asyncCall`, so the decoder is never handed a startup
reply. No behaviour change once the server is up.

## Verification

- Live desktop: after reinstalling the fixed package and restarting plasmashell,
  it stayed up 19+ minutes with reminders enabled and **zero** new
  `libdbusplugin[246a9]` segfaults; previously it died every ~7s. `NRestarts=0`.
- Live Notify shape: calling `org.freedesktop.Notifications.Notify` with the
  plasmoid's exact arguments against the running Plasma server returns a
  well-formed `(uint32 4,)` and does not crash — the decoder copes with a healthy
  reply. The crash only occurs on the degenerate reply seen before the server
  owns the name at shell startup.
- Regression test `test_notify_is_queued_while_server_not_ready` in
  `integration/notifications/tst_notifications.qml`: with `notificationsReady=false`,
  `notify()` enqueues both requests in order and delivers nothing (never calling
  asyncCall). Verified passing in an isolated runner (`Totals: passed`). The full
  delivery path (ready → flush → delivered) remains covered by
  `test_native_reminder_joins_shared_history`.

## Open questions

- The full notification fixture cannot run to completion in a headless/offscreen
  runner: its synthetic server returns a reply shape the stripped
  `libdbusplugin` decoder crashes on, and the runner SIGSEGVs partway through.
  This is independent of this fix — a clean `origin/main` checkout crashes at the
  same point. On a real desktop the live server's reply is well-formed. The new
  regression test deliberately asserts only the queue/gate (no real delivery) so
  it is not blocked by that fixture limitation.
- The underlying null dereference in `libdbusplugin.so`
  (`dbusdecoder.cpp:85`, `Decoder::dbusToVariant`) should be reported upstream to
  plasma-workspace; a well-behaved decoder would return an error rather than
  crash on a malformed/early reply.
