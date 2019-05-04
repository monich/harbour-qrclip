import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.qrclip 1.0

ApplicationWindow {
    id: appWindow

    readonly property int appAllowedOrientations: Orientation.All

    allowedOrientations: appAllowedOrientations
    initialPage: Component { MainPage { } }
    cover: Component {  CoverPage { } }

    Component.onCompleted: HarbourQrCodeGenerator.text = Clipboard.text

    Connections {
        target: Clipboard
        onTextChanged: HarbourQrCodeGenerator.text = Clipboard.text
    }
}
