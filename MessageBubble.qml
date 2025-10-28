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

    Rectangle {
        id: messageBubble

        anchors.right: isUserMessage ? parent.right : undefined
        anchors.left: isUserMessage ? undefined : parent.left
        anchors.rightMargin: isUserMessage ? 0 : parent.width * 0.15
        anchors.leftMargin: isUserMessage ? parent.width * 0.15 : 0

        width: Math.min(messageContent.implicitWidth + 40, Math.min(600, parent.width * 0.75))
         height: messageContent.height + 25

        color: isUserMessage ? messageContainer.userColor : messageContainer.aiColor
        radius: 18
        opacity: 0.9

        Column {
            id: messageContent
            anchors.centerIn: parent
            width: parent.width - 30
            spacing: 12

            Repeater {
                model: {
                    var parsed = parseMessage(messageText)
                    var items = []
                    var thinkIdx = 0
                    var codeIdx = 0

                    for (var i = 0; i < parsed.textParts.length; i++) {
                        var part = parsed.textParts[i]

                        if (part === null) {
                            // Определяем, что это - think или code
                            if (thinkIdx < parsed.thinkBlocks.length) {
                                var thinkBlock = parsed.thinkBlocks[thinkIdx]
                                // Проверяем, что think блок должен быть здесь
                                if (i === 0 || parsed.textParts[i-1] !== null) {
                                    items.push({type: 'think', data: thinkBlock})
                                    thinkIdx++
                                    continue
                                }
                            }
                            if (codeIdx < parsed.codeBlocks.length) {
                                items.push({type: 'code', data: parsed.codeBlocks[codeIdx]})
                                codeIdx++
                            }
                        } else {
                            items.push({type: 'text', data: part})
                        }
                    }
                    return items
                }

                Loader {
                    width: messageContent.width
                    sourceComponent: {
                        if (modelData.type === 'text') {
                            return textComponent
                        } else if (modelData.type === 'think') {
                            return thinkComponent
                        } else if (modelData.type === 'code') {
                            return codeComponent
                        }
                    }

                    property var itemData: modelData.data
                }
            }

            // ===== TEXT COMPONENT =====
            Component {
                id: textComponent

                Text {
                    width: messageContent.width
                    text: {
                        var formatted = itemData
                        formatted = formatted.replace(/`([^`\n]+)`/g,
                            '<span style="background-color: #2d3748; color: #ffd700; padding: 2px 6px; border-radius: 4px; font-family: \'Consolas\', \'Monaco\', monospace; font-size: 13px;">$1</span>')
                        formatted = formatted.replace(/\n/g, '<br>')
                        formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>')
                        formatted = formatted.replace(/\*(.*?)\*/g, '<i>$1</i>')
                        return formatted
                    }
                    color: messageContainer.textColor
                    font.pixelSize: 14
                    font.family: "Segoe UI Symbol, Segoe UI Emoji, Segoe UI, Apple Color Emoji, Noto Color Emoji"
                    wrapMode: Text.Wrap
                    textFormat: Text.RichText
                    horizontalAlignment: isUserMessage ? Text.AlignRight : Text.AlignLeft
                }
            }

            // ===== THINK COMPONENT =====
            Component {
                id: thinkComponent

                Rectangle {
                    width: messageContent.width
                    height: thinkContent.height + 30
                    color: "#1a1a2e"
                    radius: 8
                    border.color: "#9b59b6"
                    border.width: 2
                    opacity: 0.9

                    Column {
                        id: thinkContent
                        anchors.centerIn: parent
                        width: parent.width - 20
                        spacing: 8

                        Row {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "💭"
                                font.pixelSize: 16
                                font.family: "Segoe UI"
                            }

                            Text {
                                text: itemData.isClosed ? "Thinking..." : "Thinking... (generating)"
                                color: "#bb86fc"
                                font.pixelSize: 12
                                font.italic: true
                                font.bold: true
                            }
                        }

                        Text {
                            width: parent.width
                            text: itemData.content
                            color: "#e0e0e0"
                            font.pixelSize: 12
                            font.family: "Segoe UI"  // ← ПРОСТОЙ ШРИФТ
                            wrapMode: Text.Wrap
                            font.italic: true
                        }
                    }
                }
            }

            // ===== CODE COMPONENT =====
            Component {
                id: codeComponent

                Rectangle {
                    width: messageContent.width
                    height: Math.max(codeEditWrapper.height + 60, 100)
                    color: "#0d1117"
                    radius: 8
                    border.color: itemData.isClosed ? "#21262d" : "#fbbf24"
                    border.width: itemData.isClosed ? 1 : 2

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5

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
                                    text: itemData.language || "code"
                                    color: "#58a6ff"
                                    font.pixelSize: 12
                                    font.family: "Consolas, Monaco, monospace"
                                    font.bold: true
                                }

                                Text {
                                    text: itemData.lineCount + " lines" + (itemData.isClosed ? "" : " (generating...)")
                                    color: itemData.isClosed ? "#7d8590" : "#fbbf24"
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
                                        clipboardHelper.copyText(itemData.content)
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

                        // Код с нумерацией строк
                        Item {
                            id: codeEditWrapper
                            width: parent.width
                            height: Math.min(codeEdit.contentHeight + 10, 400)
                            clip: true

                            Row {
                                anchors.fill: parent
                                spacing: 0

                                // Колонка с номерами строк
                                Rectangle {
                                    width: 45
                                    height: parent.height
                                    color: "#0d1117"

                                    Flickable {
                                        anchors.fill: parent
                                        contentY: codeFlickable.contentY
                                        interactive: false

                                        Column {
                                            id: lineNumbers
                                            width: parent.width
                                            spacing: 0

                                            Repeater {
                                                model: itemData.content.split('\n').length

                                                Text {
                                                    text: index + 1
                                                    color: "#484f58"
                                                    font.family: "Consolas"
                                                    font.pixelSize: 12
                                                    lineHeight: 1.2  // Добавь это - коэффициент межстрочного интервала
                                                    lineHeightMode: Text.ProportionalHeight  // И это
                                                    width: lineNumbers.width
                                                    height: {
                                                        var lineText = itemData.content.split('\n')[index]
                                                        var charWidth = 7.2
                                                        var availableWidth = codeEdit.width - 10
                                                        var wrappedLines = Math.max(1, Math.ceil((lineText.length * charWidth) / availableWidth))
                                                        return Math.ceil(12 * 1.155) * wrappedLines  // Изменено: учитываем lineHeight
                                                    }
                                                    horizontalAlignment: Text.AlignRight
                                                    rightPadding: 10
                                                    verticalAlignment: Text.AlignTop
                                                }
                                            }
                                        }
                                    }
                                }

                                // Разделитель
                                Rectangle {
                                    width: 1
                                    height: parent.height
                                    color: "#21262d"
                                }

                                // Область с кодом и кастомным скроллбаром
                                Item {
                                    width: parent.width - 46
                                    height: parent.height

                                    Flickable {
                                        id: codeFlickable
                                        anchors.fill: parent
                                        anchors.rightMargin: 10
                                        contentHeight: codeEdit.contentHeight
                                        boundsBehavior: Flickable.StopAtBounds
                                        clip: true

                                        TextEdit {
                                            id: codeEdit
                                            width: parent.width - 10
                                            text: itemData.content
                                            color: "#e6edf3"
                                            font.family: "Consolas"
                                            font.pixelSize: 12
                                            wrapMode: TextEdit.Wrap
                                            selectByMouse: true
                                            readOnly: true
                                            leftPadding: 10
                                            topPadding: 1

                                            Component.onCompleted: {
                                                if (itemData.language && itemData.language !== "text") {
                                                    var cppHighlighter = Qt.createQmlObject(
                                                        'import SyntaxHighlighter 1.0; SyntaxHighlighter { language: "' + itemData.language + '" }',
                                                        codeEdit
                                                    )
                                                    if (cppHighlighter) {
                                                        cppHighlighter.setDocument(codeEdit.textDocument)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Кастомный минималистичный скроллбар
                                    Rectangle {
                                        id: customScrollbar
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.rightMargin: 2
                                        anchors.topMargin: 5
                                        anchors.bottomMargin: 5
                                        width: 6
                                        visible: codeFlickable.contentHeight > codeFlickable.height
                                        color: "transparent"

                                        Rectangle {
                                            id: scrollThumb
                                            width: parent.width
                                            height: Math.max(20, parent.height * (codeFlickable.height / codeFlickable.contentHeight))
                                            y: codeFlickable.contentY * (parent.height - height) / Math.max(1, codeFlickable.contentHeight - codeFlickable.height)
                                            radius: 3
                                            color: scrollThumbArea.pressed ? "#58a6ff" :
                                                   scrollThumbArea.containsMouse ? "#484f58" : "#30363d"
                                            opacity: 0.8

                                            Behavior on color {
                                                ColorAnimation { duration: 150 }
                                            }

                                            MouseArea {
                                                id: scrollThumbArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                drag.target: scrollThumb
                                                drag.axis: Drag.YAxis
                                                drag.minimumY: 0
                                                drag.maximumY: customScrollbar.height - scrollThumb.height

                                                onPositionChanged: {
                                                    if (drag.active) {
                                                        var ratio = scrollThumb.y / (customScrollbar.height - scrollThumb.height)
                                                        codeFlickable.contentY = ratio * (codeFlickable.contentHeight - codeFlickable.height)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Mouse wheel handling
                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.NoButton
                                        onWheel: {
                                            var delta = wheel.angleDelta.y
                                            var scrollAmount = delta > 0 ? -30 : 30
                                            var newContentY = codeFlickable.contentY + scrollAmount
                                            newContentY = Math.max(0, Math.min(newContentY, codeFlickable.contentHeight - codeFlickable.height))
                                            codeFlickable.contentY = newContentY
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
        var result = {
            textParts: [],
            codeBlocks: [],
            thinkBlocks: []
        }

        var currentIndex = 0
        var thinkRegex = /<think>([\s\S]*?)(?:<\/think>|$)/g
        var codeRegex = /```(\w*)\n?([\s\S]*?)(?:```|$)/g

        // Находим все <think> блоки
        var thinkMatches = []
        var thinkMatch
        while ((thinkMatch = thinkRegex.exec(text)) !== null) {
            thinkMatches.push({
                start: thinkMatch.index,
                end: thinkMatch.index + thinkMatch[0].length,
                content: thinkMatch[1].trim(),
                isClosed: thinkMatch[0].includes('</think>')
            })
        }

        // Находим все code блоки
        var codeMatches = []
        var codeMatch
        while ((codeMatch = codeRegex.exec(text)) !== null) {
            codeMatches.push({
                start: codeMatch.index,
                end: codeMatch.index + codeMatch[0].length,
                language: codeMatch[1] || "text",
                content: codeMatch[2].replace(/^\n+/, '').replace(/\n+$/, ''),
                isClosed: codeMatch[0].endsWith('```'),
                lineCount: codeMatch[2].split('\n').length
            })
        }

        // Объединяем и сортируем все блоки
        var allBlocks = []
        thinkMatches.forEach(function(m) {
            allBlocks.push({type: 'think', data: m, start: m.start, end: m.end})
        })
        codeMatches.forEach(function(m) {
            allBlocks.push({type: 'code', data: m, start: m.start, end: m.end})
        })
        allBlocks.sort(function(a, b) { return a.start - b.start })

        // Разбиваем текст по блокам
        for (var i = 0; i < allBlocks.length; i++) {
            var block = allBlocks[i]

            // Добавляем текст перед блоком
            if (block.start > currentIndex) {
                var textBefore = text.substring(currentIndex, block.start).trim()
                if (textBefore) {
                    result.textParts.push(textBefore)
                }
            }

            // Добавляем блок
            if (block.type === 'think') {
                result.thinkBlocks.push(block.data)
                result.textParts.push(null) // Placeholder для think блока
            } else if (block.type === 'code') {
                result.codeBlocks.push(block.data)
                result.textParts.push(null) // Placeholder для code блока
            }

            currentIndex = block.end
        }

        // Добавляем оставшийся текст
        if (currentIndex < text.length) {
            var remainingText = text.substring(currentIndex).trim()
            if (remainingText) {
                result.textParts.push(remainingText)
            }
        }

        return result
    }

    function getFormattedText() {
        var parsed = parseMessage(messageText)
        var parts = []

        var thinkIndex = 0
        var codeIndex = 0

        for (var i = 0; i < parsed.textParts.length; i++) {
            var part = parsed.textParts[i]

            if (part === null) {
                // Пропускаем placeholder - блоки отрисуются через Repeater
                continue
            }

            // Форматируем обычный текст
            var formatted = part
            formatted = formatted.replace(/`([^`\n]+)`/g,
                '<span style="background-color: #2d3748; color: #ffd700; padding: 2px 6px; border-radius: 4px; font-family: Consolas, Monaco, monospace; font-size: 13px;">$1</span>')
            formatted = formatted.replace(/\n/g, '<br>')
            formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>')
            formatted = formatted.replace(/\*(.*?)\*/g, '<i>$1</i>')

            parts.push(formatted)
        }

        return parts.join('<br>')
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
