import QtQuick
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.private.battery as Battery
Item {
    id: backend
    visible: false
    readonly property var player: players.currentPlayer
    readonly property bool available: player !== null
    readonly property bool playing: available && player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property string title: available ? player.track : ""
    readonly property string artist: available ? player.artist : ""
    readonly property string artwork: available ? player.artUrl : ""
    readonly property string identity: available ? player.identity : ""
    readonly property bool canRaise: available && player.canRaise
    function raisePlayer() { if (canRaise) player.Raise(); }
    readonly property bool canToggle: available && (playing ? player.canPause : player.canPlay)
    readonly property bool canNext: available && player.canGoNext
    readonly property bool canPrevious: available && player.canGoPrevious
    readonly property bool canSeek: available && player.canSeek && player.length > 0
    readonly property real duration: available ? player.length : 0
    readonly property real position: available ? player.position : 0
    readonly property real volume: available ? player.volume : 0
    readonly property bool hasBattery: battery.hasInternalBatteries
    readonly property int percent: battery.percent
    readonly property bool charging: battery.pluggedIn
    function toggle() { if (canToggle) player.PlayPause(); }
    function next() { if (canNext) player.Next(); }
    function previous() { if (canPrevious) player.Previous(); }
    function seek(value) { if (canSeek) player.position = Math.max(0, Math.min(duration, value)); }
    function setVolume(value) { if (available && player.canControl) player.volume = Math.max(0, Math.min(1, value)); }
    Mpris.Mpris2Model { id: players }
    Battery.BatteryControlModel { id: battery }
    Timer { interval: 1000; repeat: true; running: backend.playing; onTriggered: backend.player.updatePosition() }
}
