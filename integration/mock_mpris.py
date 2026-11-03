#!/usr/bin/env python3
"""An isolated, deterministic MPRIS service for protocol tests; no real audio."""
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

DBusGMainLoop(set_as_default=True)
ROOT = 'org.mpris.MediaPlayer2'
PLAYER = ROOT + '.Player'
PROPS = 'org.freedesktop.DBus.Properties'

class Player(dbus.service.Object):
    def __init__(self, bus):
        self.name = dbus.service.BusName(ROOT + '.boringtest', bus)
        super().__init__(bus, '/org/mpris/MediaPlayer2')
        self.root = dict(CanQuit=False, CanRaise=False, HasTrackList=False,
                         Identity='Boring protocol test', DesktopEntry='boringtest',
                         SupportedUriSchemes=dbus.Array(['file'], signature='s'),
                         SupportedMimeTypes=dbus.Array(['audio/ogg'], signature='s'))
        self.player = dict(PlaybackStatus='Paused', LoopStatus='None', Rate=1.0,
                          Shuffle=False, Volume=0.5, Position=dbus.Int64(0),
                          MinimumRate=1.0, MaximumRate=1.0,
                          CanGoNext=True, CanGoPrevious=True, CanPlay=True,
                          CanPause=True, CanSeek=True, CanControl=True,
                          Metadata=dbus.Dictionary({
                              'mpris:trackid': dbus.ObjectPath('/track/1'),
                              'mpris:length': dbus.Int64(180000000),
                              'xesam:title': 'Protocol test',
                              'xesam:artist': dbus.Array(['Boring Island'], signature='s')}, signature='sv'))

    @dbus.service.method(PROPS, in_signature='s', out_signature='a{sv}')
    def GetAll(self, interface):
        return self.player if interface == PLAYER else self.root

    @dbus.service.method(PROPS, in_signature='ss', out_signature='v')
    def Get(self, interface, key):
        return self.GetAll(interface)[key]

    @dbus.service.method(PROPS, in_signature='ssv')
    def Set(self, interface, key, value):
        self.player[key] = value
        self.PropertiesChanged(PLAYER, {key: value}, [])

    @dbus.service.signal(PROPS, signature='sa{sv}as')
    def PropertiesChanged(self, interface, changed, invalidated):
        pass

    @dbus.service.method(PLAYER)
    def PlayPause(self):
        self.Set(PLAYER, 'PlaybackStatus', 'Playing' if self.player['PlaybackStatus'] != 'Playing' else 'Paused')

    @dbus.service.method(PLAYER)
    def Next(self):
        metadata = self.player['Metadata'].copy()
        metadata['xesam:title'] = 'Next track'
        self.Set(PLAYER, 'Metadata', dbus.Dictionary(metadata, signature='sv'))

    @dbus.service.method(PLAYER)
    def Previous(self):
        metadata = self.player['Metadata'].copy()
        metadata['xesam:title'] = 'Previous track'
        self.Set(PLAYER, 'Metadata', dbus.Dictionary(metadata, signature='sv'))

    @dbus.service.method(PLAYER, in_signature='ox')
    def SetPosition(self, track_id, position):
        if track_id == self.player['Metadata']['mpris:trackid']:
            self.Set(PLAYER, 'Position', position)
            self.Seeked(position)

    @dbus.service.signal(PLAYER, signature='x')
    def Seeked(self, position):
        pass

player = Player(dbus.SessionBus())
GLib.MainLoop().run()
