pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: shell
    required property var backend
    required property var notifications
    required property var activities
    property var calendarBackend: null
    property string calendarMode: "kde"
    property string calendarSources: ""
    property int calendarAppletId: 0
    property string language: "en"
    property string compactAlternateText: ""
    property bool compactCycleText: false
    property int compactCycleInterval: 4000
    property bool compactBatteryOnly: false
    property var osd: null
    property string displayText: ""
    property string pinnedMode: "auto"
    property color accentColor: "#b9a3ff"
    property bool editing: false
    enabled: !editing
    property bool opened: false
    property bool fullView: false
    property bool presentedFullView: false
    property bool fixedViewport: false
    property bool notch: false
    property bool bottomEdge: false
    property bool showBattery: true
    property bool reduceMotion: false
    property string animationStyle: "smooth"
    readonly property bool springMotion: animationStyle === "spring" && !reduceMotion
    property int animationDuration: 400
    property string batteryWarning: ""
    property string batteryPercentPosition: "right"
    property bool configureEnabled: true
    signal configureRequested()
    signal interactionRequested()
    property real uiScale: 1
    property real compactWidth: 240
    property real compactHeight: 42
    property real expandedWidth: 600
    property real expandedHeight: 400
    property var shelf: []
    property int initialPage: 0
    property real progress: opened && !editing ? 1 : 0
    signal closeRequested()
    signal activated()
    signal filesDropped(var urls)
    signal hoverChanged(bool hovered)
    signal shelfEdited(var urls)
    signal interactionHeldChangedByUser(bool held)
    signal pinRequested(string mode)
    property real maximumWidth: 4096
    property real maximumHeight: 4096
    readonly property real targetWidth: Math.min(maximumWidth, Math.max(compactWidth, expandedWidth * uiScale))
    readonly property real expandedHeaderHeight: Math.max(compactHeight, 56 * uiScale)
    readonly property real bodyHeight: Math.max(0, Math.min(maximumHeight - expandedHeaderHeight, (presentedFullView ? expandedHeight * uiScale - expandedHeaderHeight : 126 * uiScale)))
    // OutBack with overshoot 0.85 peaks below 1.027. Reserve a static 4% envelope
    // before showing the dialog so the bounce cannot resize/move its native window.
    readonly property real horizontalMotionMargin: springMotion ? Math.ceil(Math.max(0, targetWidth - compactWidth) * 0.04 / 2) : 0
    readonly property real verticalMotionMargin: springMotion ? Math.ceil(Math.max(0, expandedHeaderHeight + bodyHeight - compactHeight) * 0.04) : 0
    readonly property real reveal: Math.max(0, Math.min(1, progress))
    readonly property real surfaceWidth: Math.min(maximumWidth, compactWidth + (targetWidth - compactWidth) * progress)
    readonly property real headerHeight: compactHeight + (expandedHeaderHeight - compactHeight) * progress
    readonly property real surfaceHeight: Math.min(maximumHeight, headerHeight + bodyHeight * progress)
    width: fixedViewport ? Math.min(maximumWidth, targetWidth + 2 * horizontalMotionMargin) : surfaceWidth
    height: fixedViewport ? Math.min(maximumHeight, expandedHeaderHeight + bodyHeight + verticalMotionMargin) : surfaceHeight
    readonly property int collapseDuration: Math.max(100, Math.min(220, Math.round(animationDuration * 0.7)))
    Behavior on progress {
        id: morphAnimation
        enabled: !shell.editing
        NumberAnimation {
            duration: shell.reduceMotion ? 0 : (morphAnimation.targetValue > 0 ? Math.max(50, Math.min(1000, shell.animationDuration)) : shell.collapseDuration)
            easing.type: morphAnimation.targetValue > 0 ? (shell.springMotion ? Easing.OutBack : Easing.OutQuint) : Easing.InOutCubic
            easing.overshoot: 0.85
        }
    }
    Item {
        id: morph
        objectName: "morphSurface"
        width: shell.surfaceWidth; height: shell.surfaceHeight
        x: (shell.width - width) / 2
        y: shell.bottomEdge ? shell.height - height : 0
        clip: true
        IslandSurface { anchors.fill: parent; notch: shell.notch }
        // Cross-fade two fixed text layouts instead of re-eliding and changing
        // font sizes on every frame of the expansion.
        CompactView {
            width: shell.compactWidth; height: shell.compactHeight
            x: (morph.width - width) / 2
            y: shell.bottomEdge ? morph.height - height : 0
            opacity: Math.max(0, 1 - shell.progress * 3)
            visible: opacity > 0
            alternateText: shell.compactAlternateText; cycleText: shell.compactCycleText
            cycleInterval: shell.compactCycleInterval; batteryOnly: shell.compactBatteryOnly
            reduceMotion: shell.reduceMotion
            backend: shell.backend; language: shell.language; notch: shell.notch
            showBattery: shell.showBattery; displayText: shell.displayText
            batteryPercentPosition: shell.batteryPercentPosition; configureEnabled: shell.configureEnabled
            onConfigureRequested: shell.configureRequested()
            onCloseRequested: shell.closeRequested()
            osd: shell.osd
            drawSurface: false; accentColor: shell.accentColor
            onActivated: shell.activated()
            onFilesDropped: urls => shell.filesDropped(urls)
        }
        CompactView {
            objectName: "expandedHeader"
            width: shell.targetWidth; height: shell.expandedHeaderHeight
            x: (morph.width - width) / 2
            y: shell.bottomEdge ? morph.height - height : 0
            expandedHeader: true; minimumTextScale: 1; compactScale: 1
            opacity: Math.max(0, (shell.reveal - 0.25) / 0.75)
            visible: opacity > 0
            backend: shell.backend; language: shell.language; notch: shell.notch
            showBattery: shell.showBattery; displayText: shell.displayText
            batteryPercentPosition: shell.batteryPercentPosition; configureEnabled: shell.configureEnabled
            onConfigureRequested: shell.configureRequested()
            onCloseRequested: shell.closeRequested()
            osd: shell.osd
            drawSurface: false; accentColor: shell.accentColor
            onActivated: shell.activated()
            onFilesDropped: urls => shell.filesDropped(urls)
        }
        Item {
            y: shell.bottomEdge ? 0 : shell.headerHeight + (shell.springMotion ? (1 - shell.reveal) * 8 * shell.uiScale : 0)
            x: (morph.width - width) / 2
            width: shell.targetWidth
            height: shell.bodyHeight
            opacity: Math.max(0, (shell.reveal - 0.25) / 0.75)
            Item {
                width: parent.width / shell.uiScale; height: parent.height / shell.uiScale
                scale: shell.uiScale; transformOrigin: Item.TopLeft
                IslandView {
                    id: content
                    anchors.fill: parent
                    visible: shell.presentedFullView
                    calendarBackend: shell.calendarBackend
                    calendarMode: shell.calendarMode; calendarSources: shell.calendarSources; calendarAppletId: shell.calendarAppletId
                    language: shell.language; backend: shell.backend; notifications: shell.notifications; activities: shell.activities
                    drawSurface: false; notch: shell.notch; reduceMotion: shell.reduceMotion; showBattery: shell.showBattery
                    shelf: shell.shelf; pinnedMode: shell.pinnedMode
                    onShelfEdited: urls => shell.shelfEdited(urls)
                    onCloseRequested: shell.closeRequested()
                    onInteractionHeldChangedByUser: held => shell.interactionHeldChangedByUser(held)
                    onPinRequested: mode => shell.pinRequested(mode)
                }
                Label {
                    objectName: "lowBatteryMessage"
                    anchors.fill: parent; anchors.margins: 24
                    visible: !shell.presentedFullView && shell.batteryWarning !== ""
                    text: shell.batteryWarning; color: "#ff9494"
                    font.pixelSize: 16; wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    textFormat: Text.PlainText
                }
                NotificationCard {
                    objectName: "notificationPreviewCard"
                    anchors.centerIn: parent
                    width: Math.max(0, Math.min(548, parent.width - 64))
                    height: Math.max(0, Math.min(implicitHeight, parent.height - 24))
                    visible: !shell.presentedFullView && shell.batteryWarning === "" && shell.notifications.preview !== null
                    backend: shell.notifications; language: shell.language
                    note: shell.notifications.preview; maximumBodyLines:2; maximumSummaryLines:1
                    onApplicationOpened: shell.closeRequested()
                }
            }
        }
        Translations { id: strings; language: shell.language }
        HoverHandler { onHoveredChanged: shell.hoverChanged(hovered) }
        // Observe presses first, then reject them so the original control gets
        // the same event. A passive TapHandler here can swallow legacy buttons.
        MouseArea {
            anchors.fill: parent; z: 1000
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: mouse => {
                shell.interactionRequested();
                mouse.accepted = false;
            }
        }
    }
    onInitialPageChanged: content.page = initialPage
    onFullViewChanged: if (fullView) { presentedFullView = true; content.page = initialPage; }
    onProgressChanged: if (progress === 0 && !opened) presentedFullView = false
    Component.onCompleted: if (fullView) presentedFullView = true
    Keys.onEscapePressed: closeRequested()
}
