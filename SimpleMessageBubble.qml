import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: messageContainer
    property string messageText: ""
    property bool isUserMessage: false
    property var parsedBlocks: []

    width: parent.width
    height: messageContent.height + 30
    color: "transparent"

    Rectangle {
        id: messageBubble
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        width: 750
        height: messageContent.height + 30

        color: isUserMessage ? "#2d3748" : "#1a365d"
        radius: 18
        opacity: 0.9

        Column {
            id: messageContent
            anchors.centerIn: parent
            width: parent.width - 40
            spacing: 12

            Repeater {
                model: {
                    if (parsedBlocks && parsedBlocks.length > 0) {
                        return parsedBlocks
                    }
                    return [{
                        type: 0,
                        content: messageText,
                        language: "",
                        lineCount: 0
                    }]
                }

                Loader {
                    width: messageContent.width
                    sourceComponent: {
                        var blockType = modelData.type
                        if (blockType === 1) return codeBlockComponent
                        return textBlockComponent
                    }
                    property var blockData: modelData
                }
            }
        }
    }

    // ===== TEXT COMPONENT =====
    Component {
        id: textBlockComponent

        TextEdit {
            width: messageContent.width
            text: blockData.content || ""
            color: "#ffffff"
            font.pixelSize: 14
            font.family: "Segoe UI"
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.PlainText
            renderType: Text.NativeRendering
            readOnly: true
            selectByMouse: true
            selectionColor: "#4facfe"
            selectedTextColor: "#ffffff"

            // ✅ Пропускаем события скролла в ListView
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onWheel: function(wheel) {
                    wheel.accepted = false  // Передаём скролл дальше
                }
            }
        }
    }

    // ===== CODE COMPONENT =====
    Component {
        id: codeBlockComponent

        Rectangle {
            width: messageContent.width
            height: codeContent.height + headerBar.height + 20
            color: "#0d1117"
            radius: 8
            border.color: "#21262d"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Заголовок
                Rectangle {
                    id: headerBar
                    width: parent.width
                    height: 30
                    color: "#161b22"
                    radius: 4

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            text: blockData.language || "code"
                            color: "#58a6ff"
                            font.pixelSize: 12
                            font.family: "Consolas"
                            font.bold: true
                        }

                        Text {
                            text: blockData.lineCount + " lines"
                            color: "#7d8590"
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 50
                        height: 20
                        radius: 4
                        color: copyArea.containsMouse ? "#238636" : "#21262d"

                        Text {
                            id: copyText
                            anchors.centerIn: parent
                            text: "Copy"
                            color: "#ffffff"
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: copyArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                clipboardHelper.copyText(blockData.content)
                                copyText.text = "Copied!"
                                resetTimer.restart()
                            }

                            Timer {
                                id: resetTimer
                                interval: 1500
                                onTriggered: copyText.text = "Copy"
                            }
                        }
                    }
                }

                // ✅ Код без Flickable и скроллбаров
                Rectangle {
                    width: parent.width
                    height: codeContent.contentHeight + 10
                    color: "transparent"

                    TextEdit {
                        id: codeContent
                        width: parent.width - 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: blockData.content
                        color: "#e6edf3"
                        font.family: "Consolas, Monaco, monospace"
                        font.pixelSize: 13
                        textFormat: TextEdit.PlainText
                        renderType: Text.NativeRendering
                        wrapMode: TextEdit.Wrap
                        leftPadding: 10
                        topPadding: 5
                        readOnly: true
                        selectByMouse: true
                        selectionColor: "#4facfe"
                        selectedTextColor: "#ffffff"
                    }
                }
            }
        }
    }
}
