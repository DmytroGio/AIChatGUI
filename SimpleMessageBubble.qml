import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: messageContainer
    property string messageText: ""
    property bool isUserMessage: false

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
                model: parseMessage()

                Loader {
                    width: messageContent.width
                    sourceComponent: modelData.type === "code" ? codeBlockComponent : textBlockComponent
                    property var blockData: modelData
                }
            }
        }
    }

    // ===== ФУНКЦИЯ ПАРСИНГА =====
    function parseMessage() {
        var blocks = []
        var text = messageText

        // Регулярка для код-блоков: ```язык\nкод\n```
        var codeBlockRegex = /```(\w*)\n([\s\S]*?)```/g
        var lastIndex = 0
        var match

        while ((match = codeBlockRegex.exec(text)) !== null) {
            // Текст до код-блока
            if (match.index > lastIndex) {
                var textBefore = text.substring(lastIndex, match.index).trim()
                if (textBefore) {
                    blocks.push({
                        type: "text",
                        content: textBefore
                    })
                }
            }

            // Код-блок
            blocks.push({
                type: "code",
                language: match[1] || "text",
                content: match[2]
            })

            lastIndex = codeBlockRegex.lastIndex
        }

        // Оставшийся текст
        if (lastIndex < text.length) {
            var textAfter = text.substring(lastIndex).trim()
            if (textAfter) {
                blocks.push({
                    type: "text",
                    content: textAfter
                })
            }
        }

        // Если нет код-блоков, возвращаем весь текст
        if (blocks.length === 0) {
            blocks.push({
                type: "text",
                content: text
            })
        }

        return blocks
    }

    // ===== TEXT COMPONENT =====
    Component {
        id: textBlockComponent

        Text {
            width: messageContent.width

            text: {
                var formatted = blockData.content

                // ✅ Заголовки
                formatted = formatted.replace(/^### (.*?)$/gm,
                    '<span style="font-size: 16px; font-weight: bold; color: #60a5fa;">$1</span>')
                formatted = formatted.replace(/^## (.*?)$/gm,
                    '<span style="font-size: 18px; font-weight: bold; color: #3b82f6;">$1</span>')
                formatted = formatted.replace(/^# (.*?)$/gm,
                    '<span style="font-size: 20px; font-weight: bold; color: #2563eb;">$1</span>')

                // ✅ Inline code
                formatted = formatted.replace(/`([^`\n]+)`/g,
                    '<span style="background-color: #2d3748; color: #ffd700; padding: 2px 6px; border-radius: 4px; font-family: Consolas, Monaco, monospace; font-size: 13px;">$1</span>')

                // ✅ Bold/Italic
                formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>')
                formatted = formatted.replace(/\*(.*?)\*/g, '<i>$1</i>')

                // ✅ Переносы
                formatted = formatted.replace(/\n/g, '<br>')

                return formatted
            }

            color: "#ffffff"
            font.pixelSize: 14
            font.family: "Segoe UI"
            wrapMode: Text.Wrap
            textFormat: Text.RichText
            horizontalAlignment: Text.AlignLeft
        }
    }

    // ===== CODE COMPONENT =====
    Component {
        id: codeBlockComponent

        Rectangle {
            width: messageContent.width
            height: Math.min(codeScrollView.contentHeight + 60, 500)  // Максимум 500px
            color: "#0d1117"
            radius: 8
            border.color: "#21262d"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                // Заголовок с языком
                Rectangle {
                    width: parent.width
                    height: 25
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
                            font.family: "Consolas, Monaco, monospace"
                            font.bold: true
                        }

                        Text {
                            text: blockData.content.split('\n').length + " lines"
                            color: "#7d8590"
                            font.pixelSize: 11
                        }
                    }

                    // Кнопка копирования
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 50
                        height: 18
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

                // Код с прокруткой
                ScrollView {
                    id: codeScrollView
                    width: parent.width
                    height: parent.height - 30
                    clip: true

                    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    TextEdit {
                        id: codeEdit
                        text: blockData.content
                        color: "#e6edf3"
                        font.family: "Consolas"
                        font.pixelSize: 12
                        wrapMode: TextEdit.NoWrap
                        selectByMouse: true
                        readOnly: true
                        leftPadding: 10
                        topPadding: 5
                    }
                }
            }
        }
    }
}
