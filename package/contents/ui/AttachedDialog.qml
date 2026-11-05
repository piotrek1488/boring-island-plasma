import QtQuick
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    property bool keyboardRequested: false
    // An overlay must have one positioning owner. Setting visualParent would
    // make Dialog::setVisible/syncToMainItemSize reposition it as a normal popup.
    visualParent: null
    location: PlasmaCore.Types.Floating
    type: PlasmaCore.Dialog.AppletPopup
    backgroundHints: PlasmaCore.Dialog.NoBackground
    hideOnWindowDeactivate: keyboardRequested
    flags: Qt.Window | Qt.FramelessWindowHint | (keyboardRequested ? 0 : Qt.WindowDoesNotAcceptFocus)
}
