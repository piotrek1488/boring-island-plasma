pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../code/Shelf.js" as Shelf
PlasmoidItem {
    id: root
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool desktopOpen: false
    property bool interactionHeld: false
    property bool compactHovered: false
    property bool fullHovered: false
    readonly property var savedShelf: Shelf.decode(Plasmoid.configuration.shelfJson)
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    toolTipMainText: "Boring Island"
    toolTipSubText: systemBackend.title || qsTr("Media and file shelf")
    SystemBackend { id: systemBackend }
    function open() { if (inPanel) expanded = true; else desktopOpen = true; }
    function close() { expanded = false; desktopOpen = false; }
    function hoverChanged(compact, hovered) {
        if (compact) compactHovered = hovered; else fullHovered = hovered;
        if (hovered) { closeTimer.stop(); if (Plasmoid.configuration.hoverOpen) openTimer.restart(); }
        else { openTimer.stop(); closeTimer.restart(); }
    }
    function storeShelf(urls) { Plasmoid.configuration.shelfJson = JSON.stringify(urls); }
    Timer { id: openTimer; interval: Math.max(100, Plasmoid.configuration.hoverDelay); onTriggered: root.open() }
    Timer { id: closeTimer; interval: 650; onTriggered: { if (!root.interactionHeld && !root.compactHovered && !root.fullHovered) root.close(); } }
    compactRepresentation: CompactView {
        backend: systemBackend; notch: Plasmoid.configuration.shape === 0; showBattery: Plasmoid.configuration.showBattery
        Layout.minimumWidth: 120; Layout.preferredWidth: Plasmoid.configuration.compactWidth
        Layout.minimumHeight: 32
        onActivated: root.expanded = !root.expanded
        onHoverChanged: hovered => root.hoverChanged(true, hovered)
        onFilesDropped: urls => { root.storeShelf(Shelf.merge(root.savedShelf, urls)); root.open(); }
    }
    fullRepresentation: Item {
        implicitWidth: 440; implicitHeight: 286
        Layout.minimumWidth: 360; Layout.minimumHeight: 286
        CompactView {
            visible: !root.inPanel && !root.desktopOpen
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, Plasmoid.configuration.compactWidth); height: 42
            backend: systemBackend; notch: Plasmoid.configuration.shape === 0; showBattery: Plasmoid.configuration.showBattery
            onActivated: root.open()
            onHoverChanged: hovered => root.hoverChanged(true, hovered)
            onFilesDropped: urls => { root.storeShelf(Shelf.merge(root.savedShelf, urls)); root.open(); }
        }
        IslandView {
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width; height: parent.height
            visible: root.inPanel || root.desktopOpen
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Plasmoid.configuration.reduceMotion ? 0 : 160 } }
            backend: systemBackend; shelf: root.savedShelf
            notch: Plasmoid.configuration.shape === 0; showBattery: Plasmoid.configuration.showBattery
            onShelfEdited: urls => root.storeShelf(urls)
            onHoverChanged: hovered => root.hoverChanged(false, hovered)
            onInteractionHeldChangedByUser: held => root.interactionHeld = held
            onCloseRequested: root.close()
        }
    }
}
