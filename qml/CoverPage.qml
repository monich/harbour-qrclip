import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.qrclip 1.0

import "harbour"

CoverBackground {
    id: cover

    property var model

    readonly property int _availableHeight: height - _coverActionHeight
    readonly property int _coverActionHeight: Theme.itemSizeSmall/parent.scale

    HarbourHighlightIcon {
        id: background

        y: 2 * Math.round((_availableHeight - height)/4)
        width: 2 * Math.round((limitWidth ? maxWidth : (maxHeight * ratioX / ratioY))/2)
        height: 2 * Math.round((limitWidth ? (maxWidth * ratioY / ratioX) : maxHeight)/2)
        sourceSize: Qt.size(width, height)
        anchors.horizontalCenter: parent.horizontalCenter
        source: "images/cover-background.svg"
        highlightColor: Theme.primaryColor
        opacity: 0.2

        // The native aspect ratio of the background image is 4:5
        readonly property real ratioX: 4
        readonly property real ratioY: 5
        readonly property bool limitWidth: (ratioX * parent.height) > (ratioY * parent.width)
        readonly property real maxHeight: _availableHeight - 2 * Theme.paddingLarge
        readonly property real maxWidth: parent.width - 2 * Theme.paddingLarge
    }

    Item {
        height: background.width - 2 * Theme.paddingLarge
        width: height
        anchors {
            centerIn: background
            verticalCenterOffset: 2 * Math.round((background.height - background.width)/4)
        }

        Image {
            anchors.fill: parent
            smooth: false
            asynchronous: true
            source: model.qrcode ? "image://qrcode/" + model.qrcode + "?color=" + Theme.primaryColor : ""
            visible: opacity > 0
            opacity: model.qrcode ? 1 : 0
            Behavior on opacity { FadeAnimation { } }
        }

        HarbourHighlightIcon {
            sourceSize: Qt.size(width, height)
            anchors.fill: parent
            asynchronous: true
            visible: opacity > 0
            highlightColor: Theme.secondaryHighlightColor
            source: (!model.text || model.qrcode || model.running) ?
                "images/happy.svg" : "images/unhappy.svg"
            opacity: (model.qrcode || model.running) ? 0 : 1
            Behavior on opacity { FadeAnimation { } }
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

        enabled: HarbourClipboard.text.length > 0
        CoverAction {
            iconSource: "image://theme/icon-cover-cancel"
            onTriggered: HarbourClipboard.text = ""
        }
    }
}
