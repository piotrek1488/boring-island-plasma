import QtQuick
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    property bool focusRequested: false
    // An overlay must have one positioning owner. Setting visualParent would
    // make Dialog::setVisible/syncToMainItemSize reposition it as a normal popup.
    visualParent: null
    location: PlasmaCore.Types.Floating
    // KWin honors panelTakesFocus for Notification, but not for AppletPopup.
    type: focusRequested ? PlasmaCore.Dialog.AppletPopup : PlasmaCore.Dialog.Notification
    backgroundHints: PlasmaCore.Dialog.NoBackground
    hideOnWindowDeactivate: focusRequested
    flags: Qt.Window | Qt.FramelessWindowHint | (focusRequested ? 0 : Qt.WindowDoesNotAcceptFocus)
}
