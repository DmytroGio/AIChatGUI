import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects

Rectangle {
    id: messageContainer
    property string messageText: ""
    property bool isUserMessage: false
    property color userColor: "#2d3748"
    property color aiColor: "#1a365d"
    property color primaryColor: "#4facfe"
    property color textColor: "#ffffff"

    width: parent.width
    height: messageContent.height + 25
    color: "transparent"

    // ЗАМЕНИТЬ ВЕСЬ Rectangle messageBubble в MessageBubble.qml на это:

    Rectangle {
        id: messageBubble
        anchors.right: isUserMessage ? parent.right : undefined
        anchors.left: isUserMessage ? undefined : parent.left
        anchors.rightMargin: isUserMessage ? 0 : parent.width * 0.15
        anchors.leftMargin: isUserMessage ? parent.width * 0.15 : 0

        width: Math.min(messageContent.implicitWidth + 30, parent.width * 0.75)
        height: messageContent.height + 20

        color: isUserMessage ? messageContainer.userColor : messageContainer.aiColor
        radius: 18
        opacity: 0.9

        Column {
            id: messageContent
            anchors.centerIn: parent
            width: parent.width - 20
            spacing: 10

            // Обычный текст
            Text {
                id: messageLabel
                width: parent.width
                text: getFormattedText()
                color: messageContainer.textColor
                font.pixelSize: 14
                wrapMode: Text.Wrap
                horizontalAlignment: isUserMessage ? Text.AlignRight : Text.AlignLeft
                visible: getFormattedText().length > 0
                textFormat: Text.RichText
            }

            // Код блоки
            Repeater {
                model: getCodeBlocks()

                Rectangle {
                    width: messageContent.width
                    height: codeColumn.height + 20
                    color: "#0d1117"
                    radius: 8
                    border.color: "#21262d"
                    border.width: 1

                    Column {
                        id: codeColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 5

                        // Заголовок
                        Rectangle {
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
                                    text: modelData.language || "code"
                                    color: "#58a6ff"
                                    font.pixelSize: 12
                                    font.family: "monospace"
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.lineCount + " lines"
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
                                    onClicked: {
                                        console.log("Copied:", modelData.code)
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
                        Rectangle {
                            width: parent.width
                            height: Math.min(codeArea.implicitHeight + 10, 250)
                            color: "#0d1117"
                            radius: 4

                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 8
                                contentWidth: codeArea.implicitWidth
                                contentHeight: codeArea.implicitHeight
                                clip: true

                                Text {
                                    id: codeArea
                                    text: modelData.code
                                    color: "#e6edf3"
                                    font.family: "Consolas, Monaco, monospace"
                                    font.pixelSize: 12
                                    wrapMode: Text.NoWrap
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function parseMessage(text) {
         var codeBlocks = []
         var cleanText = text

         // Извлекаем блоки кода
         var regex = /```(\w+)?\s*\n?([\s\S]*?)\n?```/g
         var match

         while ((match = regex.exec(text)) !== null) {
             var language = match[1] || "text"
             var code = match[2].trim()
             var lineCount = code.split('\n').length

             codeBlocks.push({
                 language: language,
                 code: code,
                 lineCount: lineCount
             })

             // Удаляем code block из текста
             cleanText = cleanText.replace(match[0], "\n\n")
         }

         // Очищаем лишние переносы
         cleanText = cleanText.replace(/\n{3,}/g, "\n\n").trim()

         return {
             textParts: cleanText,
             codeBlocks: codeBlocks
         }
     }

     function getFormattedText() {
         var parsed = parseMessage(messageText)
         var prefix = isUserMessage ? "🟢 " : "🤖 "

         if (!parsed.textParts || parsed.textParts.length === 0) return ""

         // Обрабатываем инлайн код
         var formattedText = parsed.textParts.replace(/`([^`\n]+)`/g,
             '<span style="background-color: #2d3748; color: #ffd700; padding: 1px 4px; border-radius: 3px; font-family: monospace;">$1</span>')

         return prefix + formattedText
     }

     function getCodeBlocks() {
         var parsed = parseMessage(messageText)
         return parsed.codeBlocks || []
     }

    // Tail for speech bubble effect
    Canvas {
        id: tail
        anchors.top: messageBubble.bottom
        anchors.topMargin: -5
        anchors.right: isUserMessage ? messageBubble.right : undefined
        anchors.left: isUserMessage ? undefined : messageBubble.left
        anchors.rightMargin: isUserMessage ? 20 : 0
        anchors.leftMargin: isUserMessage ? 0 : 20

        width: 15
        height: 10

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            ctx.fillStyle = isUserMessage ? messageContainer.userColor : messageContainer.aiColor
            ctx.beginPath()

            if (isUserMessage) {
                ctx.moveTo(0, 0)
                ctx.lineTo(15, 0)
                ctx.lineTo(10, 10)
            } else {
                ctx.moveTo(15, 0)
                ctx.lineTo(0, 0)
                ctx.lineTo(5, 10)
            }

            ctx.closePath()
            ctx.fill()
        }
    }
}
