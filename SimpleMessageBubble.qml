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
                        if (blockType === 2) return thinkBlockComponent  // ✅ Think
                        return textBlockComponent
                    }
                    property var blockData: modelData
                }
            }
        }
    }

    // ===== THINK COMPONENT =====
    Component {
        id: thinkBlockComponent

        Rectangle {
            width: messageContent.width
            height: thinkColumn.implicitHeight + 20
            color: "#1a1a2e"
            radius: 8
            border.color: "#9b59b6"
            border.width: 1
            opacity: 0.85

            Column {
                id: thinkColumn
                anchors.centerIn: parent
                width: parent.width - 20
                spacing: 8

                // Заголовок
                Row {
                    spacing: 8
                    Text {
                        text: "💭"
                        font.pixelSize: 16
                    }
                    Text {
                        text: "Thinking"
                        color: "#bb86fc"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                // Содержимое
                TextEdit {
                    width: parent.width
                    text: blockData.content || ""
                    color: "#e0e0e0"
                    font.pixelSize: 12
                    font.family: "Segoe UI"
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    renderType: Text.NativeRendering
                    readOnly: true
                    selectByMouse: true
                    selectionColor: "#9b59b6"
                    selectedTextColor: "#ffffff"
                }
            }
        }
    }

    // ===== TEXT COMPONENT =====
    Component {
        id: textBlockComponent

        TextEdit {
            width: messageContent.width

            text: {
                var formatted = blockData.content || ""

                // ✅ Простой парсинг markdown
                // Заголовки (### ## #)
                formatted = formatted.replace(/^### (.+)$/gm, '<span style="font-size: 16px; font-weight: bold; color: #60a5fa;">$1</span><br>')
                formatted = formatted.replace(/^## (.+)$/gm, '<span style="font-size: 18px; font-weight: bold; color: #3b82f6;">$1</span><br>')
                formatted = formatted.replace(/^# (.+)$/gm, '<span style="font-size: 20px; font-weight: bold; color: #2563eb;">$1</span><br>')

                // Горизонтальная линия
                formatted = formatted.replace(/^---$/gm, '<hr style="border: none; border-top: 2px solid #4a5568; margin: 12px 0;">')

                // Bold/Italic
                formatted = formatted.replace(/\*\*(.+?)\*\*/g, '<b>$1</b>')
                formatted = formatted.replace(/\*(.+?)\*/g, '<i>$1</i>')

                // Inline code (`text`)
                formatted = formatted.replace(/`([^`\n]+)`/g, '<span style="background-color: #2d3748; color: #ffd700; padding: 2px 6px; border-radius: 3px; font-family: Consolas, monospace; font-size: 13px;">$1</span>')

                // Переносы строк
                formatted = formatted.replace(/\n/g, '<br>')

                return formatted
            }

            color: "#ffffff"
            font.pixelSize: 14
            font.family: "Segoe UI"
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.RichText
            renderType: Text.NativeRendering
            readOnly: true
            selectByMouse: true
            selectionColor: "#4facfe"
            selectedTextColor: "#ffffff"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onWheel: function(wheel) {
                    wheel.accepted = false
                }
            }
        }
    }

    // ===== CODE COMPONENT =====
    Component {
        id: codeBlockComponent

        Rectangle {
            width: messageContent.width
            height: codeColumn.implicitHeight + 20
            color: "#0d1117"
            radius: 8
            border.color: "#21262d"
            border.width: 1

            Column {
                id: codeColumn
                anchors.centerIn: parent
                width: parent.width - 20
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

                // Код
                TextEdit {
                    id: codeContent
                    width: parent.width
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
