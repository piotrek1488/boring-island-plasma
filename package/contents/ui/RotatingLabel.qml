import QtQuick

Item {
    id: label
    property string primaryText: ""
    property string secondaryText: ""
    property bool cycling: false
    property bool reduceMotion: false
    property int interval: 4000
    property real fontSize: 13
    property bool alternate: false
    property bool nextAlternate: false
    property real progress: 0
    property bool transitioning: false
    readonly property string shownText: alternate && cycling ? secondaryText : primaryText
    function reset() {
        if (motion) motion.stop();
        transitioning=false; alternate=false; progress=0;
        if (cycle) { cycle.stop(); if (visible && cycling && secondaryText.length) cycle.start(); }
    }
    onPrimaryTextChanged: reset()
    onCyclingChanged: reset()
    onVisibleChanged: reset()
    Component.onCompleted: reset()
    clip: true
    implicitHeight: first.implicitHeight
    Text {
        id: first
        objectName: "compactTitle"
        width: parent.width; height: parent.height
        y: -label.height * label.progress
        text: label.shownText; color: "#f5f5fa"; font.pixelSize: Math.round(label.fontSize)
        verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; textFormat: Text.PlainText
    }
    Text {
        width: parent.width; height: parent.height
        y: label.height * (1-label.progress)
        visible: label.transitioning
        text: label.nextAlternate ? label.secondaryText : label.primaryText
        color: "#f5f5fa"; font.pixelSize: Math.round(label.fontSize)
        verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; textFormat: Text.PlainText
    }
    NumberAnimation {
        id: motion; target: label; property: "progress"; from: 0; to: 1; duration: 240; easing.type: Easing.InOutCubic
        onFinished: { label.alternate=label.nextAlternate; label.transitioning=false; label.progress=0; }
    }
    Timer {
        id: cycle; interval: Math.max(1000,label.interval); repeat: true
        onTriggered: {
            if (!label.cycling || !label.visible) return;
            label.nextAlternate=!label.alternate;
            if (label.reduceMotion) label.alternate=label.nextAlternate;
            else { label.transitioning=true; motion.restart(); }
        }
    }
}
