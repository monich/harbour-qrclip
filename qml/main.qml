import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.qrclip 1.0

ApplicationWindow {
    id: appWindow

    allowedOrientations: Orientation.All
    initialPage: Component { MainPage { allowedOrientations: appWindow.allowedOrientations } }
    cover: Component {  CoverPage { } }

    Binding {
        target: QrCodeModel
        property: "text"
        value: HarbourClipboard.text
    }
}
