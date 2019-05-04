import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.qrclip 1.0

CoverBackground {
    id: cover

    readonly property int availableHeight: height - coverActionHeight
    readonly property int coverActionHeight: Theme.itemSizeSmall/parent.scale

    Image {
        id: background

        y: 2 * Math.round((availableHeight - height)/4)
        width: 2 * Math.round((limitWidth ? maxWidth : (maxHeight * ratioX / ratioY))/2)
        height: 2 * Math.round((limitWidth ? (maxWidth * ratioY / ratioX) : maxHeight)/2)
        sourceSize: Qt.size(width, height)
        anchors.horizontalCenter: parent.horizontalCenter
        source: "image://harbour/" + Qt.resolvedUrl("images/cover-background.svg") + "?" + Theme.highlightColor

        // The native aspect ratio of the background image is 4:5
        readonly property real ratioX: 4
        readonly property real ratioY: 5
        readonly property bool limitWidth: (ratioX * parent.height) > (ratioY * parent.width)
        readonly property real maxHeight: availableHeight - 2 * Theme.paddingLarge
        readonly property real maxWidth: parent.width - 2 * Theme.paddingLarge
    }

    Item {
        // The size of the opening in the middle is 3/4 of the background image width:
        height: Math.floor(3 * background.width / 4 - 2 * Theme.paddingSmall)
        width: height
        anchors {
            centerIn: background
            verticalCenterOffset: 2 * Math.round((background.height - background.width)/4)
        }

        Image {
            anchors.fill: parent
            smooth: false
            asynchronous: true
            source: HarbourQrCodeGenerator.qrcode ? "image://qrcode/" + HarbourQrCodeGenerator.qrcode + "?color=" + Theme.primaryColor : ""
            visible: opacity > 0
            opacity: HarbourQrCodeGenerator.qrcode ? 1 : 0
            Behavior on opacity { FadeAnimation { } }
        }

        Image {
            sourceSize: Qt.size(width, height)
            anchors.fill: parent
            asynchronous: true
            visible: opacity > 0
            source: (!HarbourQrCodeGenerator.text || HarbourQrCodeGenerator.qrcode || HarbourQrCodeGenerator.running) ? happy : unhappy
            opacity: (HarbourQrCodeGenerator.qrcode || HarbourQrCodeGenerator.running) ? 0 : 1
            Behavior on opacity { FadeAnimation { } }

            readonly property url happy: "image://harbour/" + Qt.resolvedUrl("images/happy.svg") + "?" + Theme.primaryColor
            readonly property url unhappy: "image://harbour/" + Qt.resolvedUrl("images/unhappy.svg") + "?" + Theme.primaryColor
        }
    }

    Label {
        //: Application title (rarely needs to be translated)
        //% "QR Clip"
        text: qsTrId("qrclip-app_name")
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        visible: !actionList.enabled
        color: Theme.highlightColor
        wrapMode: Text.NoWrap
        font.family: Theme.fontFamilyHeading
        anchors {
            left: parent.left
            right: parent.right
            top: background.bottom
            bottom: parent.bottom
        }
    }

    CoverActionList {
        id: actionList

        enabled: Clipboard.hasText
        CoverAction {
            iconSource: "image://theme/icon-cover-cancel"
            onTriggered: Clipboard.text = ""
        }
    }
}
