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
                lineHeight: 1.3  // Добавляем межстрочный интервал
                    topPadding: 5    // Добавляем отступы
                    bottomPadding: 5
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
                            wrapMode: Text.Wrap  // ВАЖНО: включаем перенос строк
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

     function highlightSyntax(code, language) {
         if (!code) return ""

         switch((language || "").toLowerCase()) {
             case 'javascript':
             case 'js':
                 return highlightJavaScript(code)
             case 'python':
             case 'py':
                 return highlightPython(code)
             case 'cpp':
             case 'c++':
             case 'c':
                 return highlightCpp(code)
             case 'qml':
                 return highlightQml(code)
             default:
                 return escapeHtml(code)
         }
     }

     function escapeHtml(text) {
         return text.replace(/&/g, "&amp;")
                   .replace(/</g, "&lt;")
                   .replace(/>/g, "&gt;")
                   .replace(/"/g, "&quot;")
     }

     function highlightCpp(code) {
         // Экранируем HTML, но сохраняем переносы строк
         var highlighted = code.replace(/&/g, "&amp;")
                              .replace(/</g, "&lt;")
                              .replace(/>/g, "&gt;")

         // #include
         highlighted = highlighted.replace(/(#include)/g, '<font color="#ffa657">$1</font>')

         // Headers
         highlighted = highlighted.replace(/\b(iostream|string|vector|cstdlib)\b/g, '<font color="#a5d6ff">$1</font>')

         // Keywords
         highlighted = highlighted.replace(/\b(int|void|return|if|else|for|while|class|struct)\b/g, '<font color="#ff7b72">$1</font>')

         // Strings
         highlighted = highlighted.replace(/(".*?")/g, '<font color="#a5d6ff">$1</font>')

         // Comments (сохраняем до конца строки)
         highlighted = highlighted.replace(/(\/\/[^\n]*)/g, '<font color="#8b949e">$1</font>')

         // Numbers
         highlighted = highlighted.replace(/\b(\d+)\b/g, '<font color="#79c0ff">$1</font>')

         return highlighted
     }

     function highlightPython(code) {
         var highlighted = escapeHtml(code)
         var keywords = ['def', 'class', 'if', 'elif', 'else', 'for', 'while', 'try', 'except', 'finally', 'with', 'as', 'import', 'from', 'return', 'yield', 'lambda', 'and', 'or', 'not', 'in', 'is', 'None', 'True', 'False', 'print']

         keywords.forEach(function(keyword) {
             var regex = new RegExp('\\b' + keyword + '\\b', 'g')
             highlighted = highlighted.replace(regex, '<span style="color: #ff7b72">' + keyword + '</span>')
         })

         highlighted = highlighted.replace(/(&quot;[^&]*?&quot;|'[^']*?')/g, '<span style="color: #a5d6ff">$1</span>')
         highlighted = highlighted.replace(/(#.*$)/gm, '<span style="color: #8b949e">$1</span>')
         highlighted = highlighted.replace(/\b(\d+\.?\d*)\b/g, '<span style="color: #79c0ff">$1</span>')

         return highlighted
     }

     function highlightQml(code) {
         var highlighted = escapeHtml(code)
         var keywords = ['import', 'property', 'signal', 'function', 'var', 'let', 'const', 'if', 'else', 'for', 'while', 'return', 'Rectangle', 'Text', 'MouseArea', 'Column', 'Row', 'Item', 'Component', 'Connections', 'Timer']

         keywords.forEach(function(keyword) {
             var regex = new RegExp('\\b' + keyword + '\\b', 'g')
             highlighted = highlighted.replace(regex, '<span style="color: #ff7b72">' + keyword + '</span>')
         })

         highlighted = highlighted.replace(/(&quot;[^&]*?&quot;)/g, '<span style="color: #a5d6ff">$1</span>')
         highlighted = highlighted.replace(/(\/\/.*$)/gm, '<span style="color: #8b949e">$1</span>')

         return highlighted
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
