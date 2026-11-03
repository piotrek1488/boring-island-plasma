import QtQml
import "../code/Translations.js" as Catalog
QtObject {
    property string language: "en"
    readonly property var locale: Qt.locale(language === "pl" ? "pl_PL" : "en_GB")
    function text(source) { return Catalog.text(language, source); }
}
