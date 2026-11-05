pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: tabs
    property var entries: []
    property int currentPage: 0
    signal pageRequested(int page)
    implicitHeight: column.implicitHeight
    FontMetrics { id: metrics; font.pixelSize: 16 }
    readonly property var rows: {
        const result = [];
        let row = [], used = 0;
        for (let i = 0; i < entries.length; ++i) {
            const itemWidth = Math.max(42, Math.ceil(metrics.advanceWidth(entries[i].text)) + 24);
            if (row.length && used + 5 + itemWidth > width) { result.push(row); row = []; used = 0; }
            used += (row.length ? 5 : 0) + itemWidth;
            row.push(i);
        }
        if (row.length) result.push(row);
        return result;
    }
    Column {
        id: column
        width: tabs.width; spacing: 5
        Repeater {
            model: tabs.rows
            delegate: Row {
                id: row
                required property var modelData
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                Repeater {
                    model: row.modelData
                    delegate: ActionButton {
                        required property int modelData
                        objectName: tabs.entries[modelData].name
                        text: tabs.entries[modelData].text
                        width: Math.min(implicitWidth, tabs.width)
                        implicitHeight: 34; showTooltip: false
                        accent: tabs.currentPage === tabs.entries[modelData].page
                        onClicked: tabs.pageRequested(tabs.entries[modelData].page)
                    }
                }
            }
        }
    }
}
