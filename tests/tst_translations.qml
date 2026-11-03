import QtQuick
import QtTest
import "../package/contents/ui" as UI
import "../package/contents/code/Translations.js" as Catalog
Item {
    UI.Translations { id: strings }
    TestCase {
        name: "Translations"
        function test_default_and_fallback() {
            compare(strings.language, "en");
            compare(strings.text("Calendar"), "Calendar");
            strings.language = "pl";
            compare(strings.text("Calendar"), "Kalendarz");
            compare(strings.text("New untranslated message"), "New untranslated message");
            compare(new Date(2026,10,3).toLocaleDateString(strings.locale, "MMMM"), "listopada");
            strings.language = "en";
            compare(new Date(2026,10,3).toLocaleDateString(strings.locale, "MMMM"), "November");
            strings.language = "unknown";
            compare(strings.text("Calendar"), "Calendar");
        }
        function test_catalog_not_empty() {
            for (var key in Catalog.polish) {
                verify(typeof Catalog.polish[key] === "string" && Catalog.polish[key].length > 0);
            }
        }
    }
}
