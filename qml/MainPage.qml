import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.qrclip 1.0

import "harbour"

Page {
    id: page

    property bool showText
    property real spaceForText: showText ? maxSpaceForText : minSpaceForText
    readonly property int maxSpaceForText: Math.max(Screen.width, Screen.height) - Math.min(Screen.width, Screen.height)
    readonly property int minSpaceForText: Math.round(maxSpaceForText/2)
    readonly property int maxDisplaySize: Math.min(Screen.width, Screen.height) - 4 * Theme.horizontalPageMargin
    readonly property bool haveQrCode: qrCodes.count > 0
    property alias currentItem: qrCodes.currentItem

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            id: menu

            visible: haveQrCode && showText

            property string savedQrCode

            onActiveChanged: {
                if (!active && savedQrCode && currentItem) {
                    // Don't save the same code twice
                    currentItem.lastSavedQrCode = savedQrCode
                    savedQrCode = ""
                }
            }

            MenuItem {
                //: Pulley menu item
                //% "Save to Gallery"
                text: qsTrId("qrclip-menu-save_to_gallery")
                visible: currentItem && currentItem.needToSaveImage
                onClicked: {
                    if (currentItem && FileUtils.saveToGallery(currentItem.qrCode, "QRClip", "qrcode", Math.min(currentItem.qrCodeScale, 5))) {
                        menu.savedQrCode = currentItem.qrCode
                    }
                }
            }
            MenuLabel {
                //: Pulley menu label
                //% "Level %1"
                text: currentItem ? qsTrId("qrclip-menu-level").arg(currentItem.ecLevel) : ""
            }
        }

        SilicaListView {
            id: qrCodes

            anchors.fill: parent
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            model: QrCodeModel

            delegate: MouseArea {

                width: page.width
                height: page.height

                property string lastSavedQrCode
                readonly property string qrCode: model.qrcode
                readonly property bool needToSaveImage: qrCode !== lastSavedQrCode
                readonly property int qrCodeScale: qrcodeImage.n
                readonly property var ecLevel: {
                    switch (model.eclevel) {
                    case HarbourQrCodeGenerator.ECLevel_L: return "L"
                    case HarbourQrCodeGenerator.ECLevel_M: return "M"
                    case HarbourQrCodeGenerator.ECLevel_Q: return "Q"
                    case HarbourQrCodeGenerator.ECLevel_H: return "H"
                    }
                    return model.eclevel
                }

                Item {
                    x: isPortrait ? 0 : itemOffset
                    y: isLandscape ? 0 : itemOffset
                    width: itemSize
                    height: itemSize

                    readonly property int itemSize: Math.min(Screen.width, Screen.height)
                    readonly property int itemOffset: Math.round((Math.max(Screen.width, Screen.height) - itemSize)/2 - (spaceForText - minSpaceForText))

                    Rectangle {
                        id: qrcodeRect

                        color: "white"
                        radius: Theme.paddingMedium
                        anchors.centerIn: parent
                        width: qrcodeImage.width + 2 * Theme.horizontalPageMargin
                        height: qrcodeImage.height + 2 * Theme.horizontalPageMargin

                        readonly property int margins: Math.round((Math.min(Screen.width, Screen.height) - Math.max(width, height))/2)

                        Image {
                            id: qrcodeImage

                            asynchronous: true
                            anchors.centerIn: parent
                            source: "image://qrcode/" + model.qrcode
                            width: sourceSize.width * n
                            height: sourceSize.height * n
                            smooth: false

                            readonly property int maxSourceSize: Math.max(sourceSize.width, sourceSize.height)
                            readonly property int n: maxSourceSize ? Math.floor(maxDisplaySize/maxSourceSize) : 0
                        }
                    }
                }

                onClicked: showText = !showText
            }
        }

        Item {
            id: textItem

            z: (qrCodes.moving || textFlickable.contentHeight <= textFlickable.height) ? qrCodes.z - 1 : qrCodes.z
            visible: opacity > 0
            opacity: (spaceForText - minSpaceForText)/(maxSpaceForText - minSpaceForText)

            SilicaFlickable {
                id: textFlickable

                anchors.fill: parent
                contentHeight: textLabel.height
                quickScroll: false
                clip: true

                Label {
                    id: textLabel

                    width: parent.width
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.Wrap
                    text: haveQrCode ? QrCodeModel.text : ""
                    color: Theme.highlightColor
                }

                VerticalScrollDecorator { }
            }
        }

        Loader {
            active: !startTimer.running && !qrCodes.count && !QrCodeModel.running
            anchors.fill: parent
            sourceComponent: Item {
                InfoLabel {
                    y: Math.round(parent.height/3 - height/2)
                    text: QrCodeModel.running ? "" : QrCodeModel.text ?
                        //: Placeholder text
                        //% "Text in clipboard is too long for QR code."
                        qsTrId("qrclip-placeholder-text_too_long") :
                        //: Placeholder text
                        //% "No text in clipboard."
                        qsTrId("qrclip-placeholder-no_text")
                }
                HarbourHighlightIcon {
                    y: Math.round(2*parent.height/3 - height/2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceSize.height: Theme.iconSizeLarge
                    source: QrCodeModel.running ? "" : QrCodeModel.text ? "images/too-long.svg" : "images/shrug.svg"
                    highlightColor: Theme.secondaryHighlightColor
                }
            }
        }
    }

    Behavior on spaceForText { SmoothedAnimation { duration: 200 } }

    Timer {
        id: startTimer

        running: true
        interval: 200
    }

    states: [
        State {
            name: "portrait"
            when: isPortrait
            changes: [
                PropertyChanges {
                    target: textItem
                    x: 2 * Theme.horizontalPageMargin
                    y: page.height - spaceForText
                    width: page.width - 2 * x
                    height: maxSpaceForText
                }
            ]
        },
        State {
            name: "landscape"
            when: !isPortrait
            changes: [
                PropertyChanges {
                    target: textItem
                    x: page.width - spaceForText
                    y: 2 * Theme.horizontalPageMargin // Yes, horizontal
                    width: maxSpaceForText
                    height: page.height - 2 * y
                }
            ]
        }
    ]
}
