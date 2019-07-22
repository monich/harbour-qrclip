import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.qrclip 1.0

Page {
    id: page

    allowedOrientations: appAllowedOrientations

    property bool showText
    property real spaceForText: showText ? maxSpaceForText : 0
    property string lastSavedQrCode
    readonly property string qrCode: HarbourQrCodeGenerator.code
    readonly property bool haveQrCode: qrCode.length > 0
    readonly property bool needPullDownMenu: haveQrCode && qrCode !== lastSavedQrCode
    readonly property real maxSpaceForText: Math.max(Screen.width, Screen.height) - Math.min(Screen.width, Screen.height)

    SilicaFlickable {
        id: flickable

        anchors.fill: parent

        PullDownMenu {
            id: menu

            visible: page.needPullDownMenu

            property string savedQrCode

            onActiveChanged: {
                if (!active && savedQrCode) {
                    // Don't save the same code twice
                    page.lastSavedQrCode = savedQrCode
                    savedQrCode = ""
                }
            }

            MenuItem {
                //: Pulley menu item
                //% "Save to Gallery"
                text: qsTrId("qrclip-menu-save_to_gallery")
                onClicked: {
                    if (FileUtils.saveToGallery(page.qrCode, "QRClip", "qrcode", Math.min(qrcodeImage.n, 5))) {
                        menu.savedQrCode = page.qrCode
                    }
                }
            }
        }

        MouseArea {
            id: imageItem

            visible: page.haveQrCode
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }

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
                    source: page.haveQrCode ? "image://qrcode/" + page.qrCode : ""
                    width: sourceSize.width * n
                    height: sourceSize.height * n
                    smooth: false

                    readonly property int maxDisplaySize: Math.min(Screen.width, Screen.height) - 4 * Theme.horizontalPageMargin
                    readonly property int maxSourceSize: Math.max(sourceSize.width, sourceSize.height)
                    readonly property int n: maxSourceSize ? Math.floor(maxDisplaySize/maxSourceSize) : 0
                }
            }

            onClicked: showText = !showText
        }

        Item {
            id: textItem

            visible: opacity > 0
            opacity: spaceForText/maxSpaceForText

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: textLabel.height
                clip: true

                Label {
                    id: textLabel

                    width: parent.width
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.Wrap
                    text: page.haveQrCode ? HarbourQrCodeGenerator.text : ""
                }

                VerticalScrollDecorator { }
            }
        }

        ViewPlaceholder {
            // No need to animate opacity
            Behavior on opacity { enabled: false }
            enabled: !startTimer.running && !HarbourQrCodeGenerator.code && !HarbourQrCodeGenerator.running
            text: HarbourQrCodeGenerator.running ? "" : HarbourQrCodeGenerator.text ?
                //: Placeholder text
                //% "Text in clipboard is too long for QR code."
                qsTrId("qrclip-placeholder-text_too_long") :
                //: Placeholder text
                //% "No text in clipboard."
                qsTrId("qrclip-placeholder-no_text")
        }
    }

    Behavior on spaceForText { SmoothedAnimation { duration: 150 } }

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
                    target: imageItem
                    anchors {
                        rightMargin: 0
                        bottomMargin: spaceForText
                    }
                },
                PropertyChanges {
                    target: textItem
                    x: qrcodeRect.margins
                    y: qrcodeRect.y + qrcodeRect.height + qrcodeRect.margins
                    width: page.width - 2 * qrcodeRect.margins
                    height: page.height - page.width - qrcodeRect.margins
                }
            ]
        },
        State {
            name: "landscape"
            when: !isPortrait
            changes: [
                PropertyChanges {
                    target: imageItem
                    anchors {
                        rightMargin: spaceForText
                        bottomMargin: 0
                    }
                },
                PropertyChanges {
                    target: textItem
                    x: qrcodeRect.x + qrcodeRect.width + qrcodeRect.margins
                    y: qrcodeRect.margins
                    width: page.width - page.height - Theme.horizontalPageMargin
                    height: page.height - 2 * qrcodeRect.margins
                }
            ]
        }
    ]
}
