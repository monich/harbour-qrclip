import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.qrclip 1.0

ApplicationWindow {
    id: appWindow

    allowedOrientations: Orientation.All
    initialPage: Component {
        MainPage {
            allowedOrientations: appWindow.allowedOrientations
            model: qrcodes
        }
    }
    cover: Component {
        CoverPage {
            model: qrcodes
        }
    }

    QrCodeModel {
        id: qrcodes

        text: HarbourClipboard.text
    }
}
