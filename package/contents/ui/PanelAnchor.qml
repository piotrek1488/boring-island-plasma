import QtQuick
import QtQml.Models

Item {
    id: anchor
    required property Item source
    property Item targetItem: null
    property point origin: Qt.point(0, 0)
    readonly property var ancestors: {
        const items = [];
        for (let item = source; item; item = item.parent) items.push(item);
        return items;
    }
    function update() { origin = targetItem ? source.mapToItem(targetItem, 0, 0) : Qt.point(0, 0); }
    onTargetItemChanged: Qt.callLater(update)
    onAncestorsChanged: Qt.callLater(update)
    Instantiator {
        model: anchor.ancestors
        delegate: Connections {
            required property var modelData
            target: modelData
            function onXChanged() { anchor.update(); }
            function onYChanged() { anchor.update(); }
            function onWidthChanged() { anchor.update(); }
            function onHeightChanged() { anchor.update(); }
        }
    }
    Component.onCompleted: update()
}
