import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import SyntaxHighlighter 1.0

Rectangle {
    id: messageContainer
    property string messageText: ""
    property bool isUserMessage: false
    property var parsedBlocks: []
    property color userColor: "#2d3748"
    property color aiColor: "#1a365d"
    property color primaryColor: "#4facfe"
    property color textColor: "#ffffff"

    // ✅ Отключаем antialiasing где не критично
    antialiasing: false

    width: parent.width
    height: messageContent.height + 30
    color: "transparent"

    Rectangle {
        id: messageBubble

        anchors.right: isUserMessage ? parent.right : undefined
        anchors.left: isUserMessage ? undefined : parent.left
        anchors.rightMargin: isUserMessage ? 0 : parent.width * 0.15
        anchors.leftMargin: isUserMessage ? parent.width * 0.15 : 0

        width: Math.min(messageContent.implicitWidth + 40, Math.min(800, parent.width * 0.85))
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

                    // ✅ Если есть готовые блоки из C++ - используем их
                    if (messageContainer.parsedBlocks && messageContainer.parsedBlocks.length > 0) {
                        return messageContainer.parsedBlocks
                    }

                    // Fallback для user messages (они не парсятся)
                    if (isUserMessage) {
                        return [{
                            type: 0,           // 0 = Text
                            content: messageText,
                            language: "",
                            isClosed: true,
                            lineCount: 0
                        }]
                    }

                    return []
                }

                Loader {
                    width: messageContent.width
                    sourceComponent: {
                        var type = modelData.type
                        if (type === 0) return textComponent      // Text
                        else if (type === 2) return thinkComponent // Think
                        else if (type === 1) return codeComponent  // Code
                    }

                    property var itemData: modelData
                }
            }

            // ===== TEXT COMPONENT =====
            Component {
                id: textComponent

                Text {
                    width: messageContent.width

                    text: {
                        var formatted = itemData.content || ""

                        // Форматируем один раз
                        formatted = formatted.replace(/^### (.*?)$/gm, '<span style="font-size: 16px; font-weight: bold; color: #60a5fa;">$1</span>')
                        formatted = formatted.replace(/^## (.*?)$/gm, '<span style="font-size: 18px; font-weight: bold; color: #3b82f6;">$1</span>')
                        formatted = formatted.replace(/^# (.*?)$/gm, '<span style="font-size: 20px; font-weight: bold; color: #2563eb;">$1</span>')
                        formatted = formatted.replace(/`([^`\n]+)`/g, '<span style="background-color: #2d3748; color: #ffd700; padding: 2px 6px; border-radius: 4px; font-family: \'Consolas\', \'Monaco\', monospace; font-size: 13px;">$1</span>')
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
                    height: thinkHeader.height + (thinkExpanded ? thinkContent.height + 20 : 0) + 20
                    color: "#1a1a2e"
                    radius: 8
                    border.color: "#9b59b6"
                    border.width: 2
                    opacity: 0.9

                    property bool thinkExpanded: false

                    Behavior on height {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        // Заголовок с кнопкой сворачивания
                        Rectangle {
                            id: thinkHeader
                            width: parent.width
                            height: 25
                            color: "#161b22"
                            radius: 4

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Text {
                                    text: "💭"
                                    font.pixelSize: 16
                                    font.family: "Segoe UI"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: itemData.isClosed ? "Thinking..." : "Thinking... (generating)"
                                    color: "#bb86fc"
                                    font.pixelSize: 12
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Индикатор генерации когда свёрнуто
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: "#bb86fc"
                                    visible: !thinkExpanded && !itemData.isClosed
                                    anchors.verticalCenter: parent.verticalCenter

                                    SequentialAnimation on opacity {
                                        running: !thinkExpanded && !itemData.isClosed
                                        loops: Animation.Infinite
                                        NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
                                        NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
                                    }
                                }
                            }

                            // Кнопка сворачивания/разворачивания справа
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 50
                                height: 18
                                radius: 4
                                color: toggleArea.containsMouse ? "#9b59b6" : "#21262d"

                                Text {
                                    anchors.centerIn: parent
                                    text: thinkExpanded ? "Hide" : "Show"
                                    color: "#ffffff"
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: toggleArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: thinkExpanded = !thinkExpanded
                                }
                            }
                        }

                        // Содержимое (показывается только когда развёрнуто)
                        Text {
                            id: thinkContent
                            width: parent.width
                            text: itemData.content
                            color: "#e0e0e0"
                            font.pixelSize: 12
                            font.family: "Segoe UI"
                            wrapMode: Text.Wrap
                            visible: thinkExpanded
                            opacity: thinkExpanded ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
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

                        // Код с нумерацией строк (без ограничения высоты)
                        Item {
                            id: codeEditWrapper
                            width: parent.width
                            height: codeEdit.contentHeight + 10

                            Row {
                                anchors.fill: parent
                                spacing: 0

                                // Колонка с номерами строк
                                Rectangle {
                                    width: 45
                                    height: parent.height
                                    color: "#0d1117"

                                    // ✅ ОПТИМИЗАЦИЯ: Простые номера строк без измерения высоты
                                    Column {
                                        id: lineNumbers
                                        width: 45
                                        spacing: 0

                                        Repeater {
                                            model: itemData.content.split('\n').length

                                            Text {
                                                text: (index + 1).toString()
                                                color: "#484f58"
                                                font.family: codeEdit.font.family
                                                font.pixelSize: codeEdit.font.pixelSize
                                                width: lineNumbers.width
                                                height: codeEdit.font.pixelSize + 2  // ✅ Фиксированная высота
                                                horizontalAlignment: Text.AlignRight
                                                rightPadding: 10
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

                                // Область с кодом
                                TextEdit {
                                    id: codeEdit
                                    width: parent.width - 46
                                    text: itemData.content
                                    color: "#e6edf3"
                                    font.family: "Consolas"
                                    font.pixelSize: 12
                                    wrapMode: TextEdit.Wrap
                                    selectByMouse: true
                                    readOnly: true
                                    renderType: Text.NativeRendering
                                    leftPadding: 10
                                    topPadding: 1

                                    Component.onCompleted: {
                                        // ✅ Подсветка синтаксиса ТОЛЬКО для маленьких блоков (<30 строк)
                                        /*
                                        if (itemData.language && itemData.language !== "text" && itemData.lineCount < 30) {
                                            Qt.callLater(function() {
                                                try {
                                                    var cppHighlighter = Qt.createQmlObject(
                                                        'import SyntaxHighlighter 1.0; SyntaxHighlighter { language: "' + itemData.language + '" }',
                                                        codeEdit
                                                    )
                                                    if (cppHighlighter) {
                                                        cppHighlighter.setDocument(codeEdit.textDocument)
                                                    }
                                                } catch (e) {
                                                    // Игнорируем ошибки подсветки
                                                }
                                            })
                                        }
                                        */
                                    }

                                }
                            }
                        }

                    }
                }
            }

        }
    }

    /*
    // ✅ Shape быстрее Canvas для простых фигур
    Item {
        id: tail
        anchors.top: messageBubble.bottom
        anchors.topMargin: -5
        anchors.right: isUserMessage ? messageBubble.right : undefined
        anchors.left: isUserMessage ? undefined : messageBubble.left
        anchors.rightMargin: isUserMessage ? 20 : 0
        anchors.leftMargin: isUserMessage ? 0 : 20

        width: 15
        height: 10

        // Простой треугольник через Rectangle с rotation
        Rectangle {
            width: 10
            height: 10
            rotation: 45
            color: isUserMessage ? messageContainer.userColor : messageContainer.aiColor
            anchors.top: parent.top
            anchors.topMargin: isUserMessage ? -3 : -3
            anchors.right: isUserMessage ? parent.right : undefined
            anchors.left: isUserMessage ? undefined : parent.left
            anchors.rightMargin: isUserMessage ? 5 : 0
            anchors.leftMargin: isUserMessage ? 0 : 5
        }
    }
    */
}
