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
             visible: getFormattedText().length > 0
             textFormat: Text.RichText  // Добавить эту строку для поддержки HTML
             horizontalAlignment: isUserMessage ? Text.AlignRight : Text.AlignLeft
         }

            // Код блоки с подсветкой
             Repeater {
                 model: getCodeBlocks()

                 Rectangle {
                     width: messageContent.width
                     height: Math.max(codeEdit.contentHeight + 60, 100)
                     color: "#0d1117"
                     radius: 8
                     border.color: "#21262d"
                     border.width: 1

                     Column {
                         anchors.fill: parent
                         anchors.margins: 10
                         spacing: 5

                         // Заголовок (оставляем как есть)
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

                         // Заменяем на TextEdit с SyntaxHighlighter
                         ScrollView {
                             width: parent.width
                             height: parent.parent.height - 35
                             clip: true

                             TextEdit {
                                 id: codeEdit
                                 text: modelData.code
                                 color: "#e6edf3"
                                 font.family: "Consolas, Monaco, monospace"
                                 font.pixelSize: 12
                                 wrapMode: TextEdit.Wrap
                                 selectByMouse: true
                                 readOnly: true

                                 Component.onCompleted: {
                                     if (modelData.language && modelData.language !== "text") {
                                         var highlighter = Qt.createComponent("qrc:/SyntaxHighlighter/SyntaxHighlighter.qml")
                                         if (highlighter.status === Component.Ready) {
                                             var highlighterInstance = highlighter.createObject(codeEdit)
                                             if (highlighterInstance) {
                                                 highlighterInstance.language = modelData.language
                                                 highlighterInstance.setDocument(codeEdit.textDocument)
                                             }
                                         } else {
                                             // Fallback - создаем через C++
                                             var cppHighlighter = Qt.createQmlObject(
                                                 'import SyntaxHighlighter 1.0; SyntaxHighlighter { language: "' + modelData.language + '" }',
                                                 codeEdit
                                             )
                                             if (cppHighlighter) {
                                                 cppHighlighter.setDocument(codeEdit.textDocument)
                                             }
                                         }
                                     }
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
        var cleanText = ""

        // Улучшенное регулярное выражение для блоков кода
        var regex = /```(\w*)\n?([\s\S]*?)```/g
        var match
        var lastIndex = 0

        while ((match = regex.exec(text)) !== null) {
            // Добавляем текст до блока кода
            if (match.index > lastIndex) {
                var textBefore = text.substring(lastIndex, match.index)
                cleanText += textBefore
            }

            var language = match[1] || "text"
            var code = match[2]

            // Убираем лишние переводы строк в начале и конце
            code = code.replace(/^\n+/, '').replace(/\n+$/, '')

            codeBlocks.push({
                language: language,
                code: code,
                lineCount: code.split('\n').length
            })

            lastIndex = regex.lastIndex
        }

        // Добавляем оставшийся текст после последнего блока
        if (lastIndex < text.length) {
            cleanText += text.substring(lastIndex)
        }

        // Очищаем текст от лишних пробелов и переводов строк
        cleanText = cleanText.trim()

        // Заменяем множественные переводы строк на двойные
        cleanText = cleanText.replace(/\n{3,}/g, '\n\n')

        return {
            textParts: cleanText,
            codeBlocks: codeBlocks
        }
    }

    function getFormattedText() {
        var parsed = parseMessage(messageText)

        if (!parsed.textParts || parsed.textParts.length === 0) {
            return ""
        }

        var formattedText = parsed.textParts

        // Добавляем inline код блоки (одинарные бэктики)
        formattedText = formattedText.replace(/`([^`\n]+)`/g,
            '<span style="background-color: #2d3748; color: #ffd700; padding: 2px 6px; border-radius: 4px; font-family: Consolas, Monaco, monospace; font-size: 13px;">$1</span>')

        // Обрабатываем переводы строк для HTML
        formattedText = formattedText.replace(/\n/g, '<br>')

        // Обрабатываем жирный текст
        formattedText = formattedText.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>')

        // Обрабатываем курсив
        formattedText = formattedText.replace(/\*(.*?)\*/g, '<i>$1</i>')

        return formattedText
    }

    function getCodeBlocks() {
        var parsed = parseMessage(messageText)
        console.log("getCodeBlocks returning:", parsed.codeBlocks ? parsed.codeBlocks.length : 0, "blocks")
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
