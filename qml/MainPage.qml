import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import harbour.qrclip 1.0

import "harbour"

Page {
    id: page

    property alias model: qrCodes.model

    property alias _showText: showText.value
    property real _spaceForText: _showText ? _maxSpaceForText : _minSpaceForText
    readonly property int _maxSpaceForText: Math.max(qrCodes.width, qrCodes.height) - Math.min(qrCodes.width, qrCodes.height)
    readonly property int _minSpaceForText: Math.round(_maxSpaceForText/2)
    readonly property int _maxDisplaySize: Math.min(qrCodes.width, qrCodes.height) - 4 * Theme.horizontalPageMargin
    readonly property bool _haveQrCode: qrCodes.count > 0
    readonly property int _topNotch: ('topCutout' in Screen) ? Screen.topCutout.height : 0
    property alias _currentItem: qrCodes.currentItem

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            id: menu

            visible: _haveQrCode && _showText

            property string savedQrCode

            onActiveChanged: {
                if (!active && savedQrCode && _currentItem) {
                    // Don't save the same code twice
                    _currentItem.lastSavedQrCode = savedQrCode
                    savedQrCode = ""
                }
            }

            MenuItem {
                //: Pulley menu item
                //% "Save to Gallery"
                text: qsTrId("qrclip-menu-save_to_gallery")
                visible: _currentItem && _currentItem.needToSaveImage
                onClicked: {
                    if (_currentItem && FileUtils.saveToGallery(_currentItem.qrCode, "QRClip", "qrcode", Math.min(_currentItem.qrCodeScale, 5))) {
                        menu.savedQrCode = _currentItem.qrCode
                    }
                }
            }
            MenuLabel {
                //: Pulley menu label
                //% "Level %1"
                text: _currentItem ? qsTrId("qrclip-menu-level").arg(_currentItem.ecLevel) : ""
            }
        }

        SilicaListView {
            id: qrCodes

            anchors {
                fill: parent
                topMargin: _topNotch
            }
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange

            delegate: MouseArea {

                width: qrCodes.width
                height: qrCodes.height

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

                    readonly property int itemSize: Math.min(qrCodes.width, qrCodes.height)
                    readonly property int itemOffset: Math.round((Math.max(qrCodes.width, qrCodes.height) - itemSize)/2 - (_spaceForText - _minSpaceForText))

                    Rectangle {
                        id: qrcodeRect

                        color: "white"
                        radius: Theme.paddingMedium
                        anchors.centerIn: parent
                        width: qrcodeImage.width + 2 * Theme.horizontalPageMargin
                        height: qrcodeImage.height + 2 * Theme.horizontalPageMargin

                        readonly property int margins: Math.round((Math.min(qrCodes.width, qrCodes.height) - Math.max(width, height))/2)

                        Image {
                            id: qrcodeImage

                            asynchronous: true
                            anchors.centerIn: parent
                            source: "image://qrcode/" + model.qrcode
                            width: sourceSize.width * n
                            height: sourceSize.height * n
                            smooth: false

                            readonly property int maxSourceSize: Math.max(sourceSize.width, sourceSize.height)
                            readonly property int n: maxSourceSize ? Math.floor(_maxDisplaySize/maxSourceSize) : 0
                        }
                    }
                }

                onClicked: _showText = !_showText
            }
        }

        Item {
            id: textItem

            z: (qrCodes.moving || textFlickable.contentHeight <= textFlickable.height) ? qrCodes.z - 1 : qrCodes.z
            visible: opacity > 0
            opacity: (_spaceForText - _minSpaceForText)/(_maxSpaceForText - _minSpaceForText)

            SilicaFlickable {
                id: textFlickable

                anchors.fill: parent
                contentHeight: textLabel.height
                quickScroll: false
                clip: true

                Label {
                    id: textLabel

                    x: isPortrait ? 2 * Theme.horizontalPageMargin : 0
                    width: parent.width - (isPortrait ? 4 : 1) * Theme.horizontalPageMargin
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.Wrap
                    text: _haveQrCode ? model.text : ""
                    color: Theme.highlightColor
                }

                VerticalScrollDecorator { }
            }
        }

        Loader {
            active: !startTimer.running && !qrCodes.count && !model.running
            anchors.fill: parent
            sourceComponent: Item {
                InfoLabel {
                    y: Math.round(parent.height/3 - height/2)
                    text: model.running ? "" : model.text ?
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
                    source: model.running ? "" : model.text ? "images/too-long.svg" : "images/shrug.svg"
                    highlightColor: Theme.secondaryHighlightColor
                }
            }
        }
    }

    Behavior on _spaceForText { SmoothedAnimation { duration: 200 } }

    states: [
        State {
            name: "portrait"
            when: isPortrait
            changes: [
                PropertyChanges {
                    target: textItem
                    x: qrCodes.x
                    y: qrCodes.y + qrCodes.height - _spaceForText
                    width: qrCodes.width
                    height: _maxSpaceForText
                }
            ]
        },
        State {
            name: "landscape"
            when: !isPortrait
            changes: [
                PropertyChanges {
                    target: textItem
                    x: qrCodes.x + qrCodes.width - _spaceForText
                    y: qrCodes.y + 2 * Theme.horizontalPageMargin // Yes, horizontal
                    width: _maxSpaceForText
                    height: qrCodes.height - 2 * y
                }
            ]
        }
    ]

    Timer {
        id: startTimer

        running: true
        interval: 200
    }

    ConfigurationValue {
        id: showText

        key: "/apps/harbour-qrclip/showText"
        defaultValue: false
    }
}
