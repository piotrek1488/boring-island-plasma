#!/usr/bin/env python3
"""Isolated KDE Connect protocol fixture. Never reads or transfers a file."""
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
name = dbus.service.BusName('org.kde.kdeconnect', bus)
BASE = '/modules/kdeconnect'
DAEMON = 'org.kde.kdeconnect.daemon'
DEVICE = 'org.kde.kdeconnect.device'
PROPS = 'org.freedesktop.DBus.Properties'

class Daemon(dbus.service.Object):
    @dbus.service.method(DAEMON, in_signature='bb', out_signature='as')
    def devices(self, reachable, paired):
        return ['test_phone']

class Device(dbus.service.Object):
    @dbus.service.method(PROPS, in_signature='ss', out_signature='v')
    def Get(self, interface, key):
        return {'name': 'Test phone', 'type': 'phone', 'iconName': 'smartphone',
                'isReachable': True, 'isPaired': True, 'isPairRequested': False,
                'isPairRequestedByPeer': False, 'pairState': dbus.Int32(2)}[key]
    @dbus.service.method(DEVICE, in_signature='s', out_signature='b')
    def hasPlugin(self, plugin):
        return plugin == 'kdeconnect_share'
    @dbus.service.method(DEVICE, in_signature='s', out_signature='s')
    def pluginIconName(self, plugin):
        return 'document-share'

class Share(dbus.service.Object):
    @dbus.service.method(DEVICE + '.share', in_signature='s')
    def shareUrl(self, url):
        if url == 'file:///tmp/failure.txt':
            raise dbus.exceptions.DBusException('Simulated offline device', name='org.kde.kdeconnect.Error')
        if url != 'file:///tmp/report%20space.pdf':
            raise dbus.exceptions.DBusException('Unexpected URL', name='org.kde.kdeconnect.Error')

daemon = Daemon(bus, BASE)
device = Device(bus, BASE + '/devices/test_phone')
share = Share(bus, BASE + '/devices/test_phone/share')
GLib.MainLoop().run()
