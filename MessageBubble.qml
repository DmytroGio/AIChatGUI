import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import SyntaxHighlighter 1.0

Rectangle {
    id: messageContainer
    property string messageText: ""
    property bool isUserMessage: false
    property color userColor: "#2d3748"
    property color aiColor: "#1a365d"
    property color primaryColor: "#4facfe"
    property color textColor: "#ffffff"

    SyntaxHighlighter {
         id: highlighter
     }

    width: parent.width
    height: messageContent.height + 30
    color: "transparent"

    // ЗАМЕНИТЬ ВЕСЬ Rectangle messageBubble в MessageBubble.qml на это:

    Rectangle {
        id: messageBubble
        anchors.right: isUserMessage ? parent.right : undefined
        anchors.left: isUserMessage ? undefined : parent.left
        anchors.rightMargin: isUserMessage ? 0 : parent.width * 0.15
        anchors.leftMargin: isUserMessage ? parent.width * 0.15 : 0

         width: Math.min(messageContent.implicitWidth + 40, parent.width * 0.75)  // Увеличиваем отступ
         height: messageContent.height + 25

        color: isUserMessage ? messageContainer.userColor : messageContainer.aiColor
        radius: 18
        opacity: 0.9

        Column {
         id: messageContent
         anchors.centerIn: parent
         width: parent.width - 30
         spacing: 12

         // Обычный текст
         TextInput {
             id: messageLabel
             width: parent.width
             text: getFormattedText()
             color: messageContainer.textColor
             font.pixelSize: 14
             wrapMode: TextInput.Wrap
             visible: getFormattedText().length > 0
             readOnly: true
             selectByMouse: true
             horizontalAlignment: isUserMessage ? TextInput.AlignRight : TextInput.AlignLeft
         }

            // Код блоки
            // Код блоки с улучшенной подсветкой
            // Код блоки с подсветкой
            Repeater {
                model: getCodeBlocks()

                Rectangle {
                    width: messageContent.width
                    height: codeText.implicitHeight + 50
                    color: "#0d1117"
                    radius: 8
                    border.color: "#21262d"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5

                        // Заголовок
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
                                        clipboardHelper.copyText(modelData.code)
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

                        // Код без скроллбаров, с переносом строк
                        Text {
                            id: codeText
                            width: parent.width
                            text: highlightSyntax(modelData.code, modelData.language)
                            color: "#e6edf3"
                            font.family: "Consolas, Monaco, monospace"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            textFormat: Text.RichText
                            lineHeight: 1.2

                            leftPadding: 8
                            rightPadding: 8
                            topPadding: 5
                            bottomPadding: 5
                        }
                    }
                }
            }
        }
    }

    function parseMessage(text) {
        var codeBlocks = []
        var cleanText = text

        console.log("Original text:", text.substring(0, 200))

        // Улучшенное извлечение блоков кода
        var regex = /```(\w+)?\s*\n?([\s\S]*?)\n?```/g
        var match
        var matchCount = 0

        while ((match = regex.exec(text)) !== null) {
            matchCount++
            console.log("Found code block", matchCount, "Language:", match[1], "Code length:", match[2].length)

            var language = match[1] || "text"
            var code = match[2]

            // Убираем ведущие и завершающие переносы строк
            code = code.replace(/^\n+/, '').replace(/\n+$/, '')

            var lineCount = code.split('\n').length

            codeBlocks.push({
                language: language,
                code: code,
                lineCount: lineCount,
                fullMatch: match[0]
            })

            console.log("Code block content:", code.substring(0, 100))
        }

        // Удаляем все найденные code blocks из текста
        for (var i = 0; i < codeBlocks.length; i++) {
            cleanText = cleanText.replace(codeBlocks[i].fullMatch, "\n[CODE_BLOCK_" + i + "]\n")
        }

        // Очищаем лишние переносы
        cleanText = cleanText.replace(/\n{3,}/g, "\n\n").trim()

        // Удаляем маркеры code blocks
        cleanText = cleanText.replace(/\[CODE_BLOCK_\d+\]/g, "").trim()

        console.log("Clean text:", cleanText.substring(0, 100))
        console.log("Code blocks found:", codeBlocks.length)

        return {
            textParts: cleanText,
            codeBlocks: codeBlocks
        }
    }

    function getFormattedText() {
        var parsed = parseMessage(messageText)

        if (!parsed.textParts || parsed.textParts.length === 0) return ""

        var formattedText = parsed.textParts

        // Обрабатываем инлайн код только если это не пустой текст
        if (formattedText.trim().length > 0) {
            formattedText = formattedText.replace(/`([^`\n]+)`/g,
                '<span style="background-color: #2d3748; color: #ffd700; padding: 1px 4px; border-radius: 3px; font-family: monospace;">$1</span>')
        }

        return formattedText
    }


    function getCodeBlocks() {
        var parsed = parseMessage(messageText)
        console.log("getCodeBlocks returning:", parsed.codeBlocks ? parsed.codeBlocks.length : 0, "blocks")
        return parsed.codeBlocks || []
    }

    function highlightSyntax(code, language) {
        if (!code) return ""

        console.log("Full code to highlight:", code)
        console.log("Language:", language)

        var highlighted = highlighter.highlightCode(code, language || 'text')

        console.log("Full highlighted result:", highlighted)

        return highlighted || escapeHtml(code)
    }

     function escapeHtml(text) {
         return text.replace(/&/g, "&amp;")
                   .replace(/</g, "&lt;")
                   .replace(/>/g, "&gt;")
                   .replace(/"/g, "&quot;")
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
