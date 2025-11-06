import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects

ApplicationWindow {
    id: root
    visible: true
    width: 2000
    height: 1000
    minimumWidth: 400
    minimumHeight: 500
    title: "AI Chat Assistant"

    // Dark theme colors
    property color backgroundColor: "#0f0f23"
    property color surfaceColor: "#1a1b2e"
    property color primaryColor: "#4facfe"
    property color secondaryColor: "#00f2fe"
    property color accentColor: "#6c5ce7"
    property color textPrimary: "#ffffff"
    property color textSecondary: "#a0a0a0"
    property color inputBackground: "#16213e"
    property color messageUserBg: "#2d3748"
    property color messageAiBg: "#1a365d"
    property bool showChatList: false
    property bool showModelPanel: true
    property bool showModelSelector: false



    // Gradient background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.backgroundColor }
            GradientStop { position: 1.0; color: "#16213e" }
        }
    }

    // Chat list panel
    ChatList {
        id: chatList
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        isOpen: root.showChatList
        z: 10
    }

    // Model panel
    ModelPanel {
        id: modelPanel
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        isOpen: root.showModelPanel
        z: 10
    }

    // Header
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: chatList.right
        anchors.right: modelPanel.left
        height: 60
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: root.surfaceColor
            opacity: 0.8
            radius: 0
        }

        // Menu button
        Rectangle {
            id: menuButton
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            width: 35
            height: 35
            radius: 8
            color: root.showChatList ? root.primaryColor : "transparent"

            Text {
                anchors.centerIn: parent
                text: "☰"
                color: root.textPrimary
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.showChatList = !root.showChatList
            }
        }

        Row {
            anchors.left: menuButton.right
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            spacing: 15

            Rectangle {
                width: 35
                height: 35
                radius: 18
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.primaryColor }
                    GradientStop { position: 1.0; color: root.secondaryColor }
                }

                Text {
                    anchors.centerIn: parent
                    text: "AI"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 14
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: chatManager.currentChatTitle
                    color: root.textPrimary
                    font.pixelSize: 18
                    font.bold: true
                }

                Text {
                    text: "Connected to Local Model"
                    color: root.textSecondary
                    font.pixelSize: 12
                }
            }
        }

        // Connection status indicator
        Rectangle {
            width: 12
            height: 12
            radius: 6
            color: modelInfo.isLoaded ? root.primaryColor : "#808080"
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.showModelPanel  // Скрываем когда панель открыта

            SequentialAnimation on opacity {
                running: modelInfo.status === "Generating"
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 500 }
                NumberAnimation { to: 1.0; duration: 500 }
            }
        }

        // Model Panel button
        Rectangle {
            id: modelPanelButton
            anchors.right: parent.right
            anchors.rightMargin: root.showModelPanel ? 20 : 50  // Смещаем влево когда панель открыта
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
            radius: 8
            color: root.showModelPanel ? root.primaryColor : "transparent"

            Text {
                anchors.centerIn: parent
                text: "📊"
                font.pixelSize: 20
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.showModelPanel = !root.showModelPanel

                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = 1.0
            }

            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            // Добавляем плавную анимацию смещения
            Behavior on anchors.rightMargin {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }
        }
    }

    // Main content area
    Rectangle {
        id: contentArea
        anchors.top: header.bottom
        anchors.left: chatList.right
        anchors.right: modelPanel.left
        anchors.bottom: inputArea.top
        anchors.margins: 20
        anchors.topMargin: 10
        color: "transparent"
        radius: 15

        Rectangle {
            anchors.fill: parent
            color: root.surfaceColor
            opacity: 0.6
            radius: parent.radius
        }


        // В Main.qml, заменить Flickable и его содержимое:

        ListView {
            id: messagesView
            anchors.fill: parent
            anchors.margins: 15
            anchors.rightMargin: 25

            model: chatManager.getCurrentMessages()
            spacing: 15
            clip: true

            // ✅ ОПТИМИЗАЦИИ ПРОИЗВОДИТЕЛЬНОСТИ
            cacheBuffer: height * 1.5  // Уменьшаем буфер для плавности
            displayMarginBeginning: 200
            displayMarginEnd: 200

            // ✅ Асинхронная загрузка делегатов (убирает лаги)
            reuseItems: true

            property bool shouldAutoScroll: true

            onCountChanged: {
                if (shouldAutoScroll && count > 0) {
                    Qt.callLater(function() {
                        positionViewAtEnd()
                    })
                }
            }

            delegate: MessageBubble {
                width: messagesView.width
                messageText: modelData.text
                isUserMessage: modelData.isUser
                parsedBlocks: modelData.blocks || []
            }

            header: Item {
                width: messagesView.width
                height: chatManager.messageCount === 0 ? 80 : 0

                Text {
                    anchors.centerIn: parent
                    text: "Start typing to begin..."
                    color: root.textSecondary
                    font.pixelSize: 16
                    font.weight: Font.Light
                    opacity: 0.7
                    visible: chatManager.messageCount === 0
                }
            }
        }

        // ✅ КАСТОМНЫЙ СКРОЛЛБАР
        Item {
            id: customScrollBar
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 5
            anchors.topMargin: 15
            anchors.bottomMargin: 15
            width: 8
            visible: messagesView.contentHeight > messagesView.height

            property real scrollBarHeight: messagesView.height
            property real contentHeight: messagesView.contentHeight
            property real thumbHeight: Math.max(20, scrollBarHeight * (scrollBarHeight / contentHeight))
            property real maxThumbY: scrollBarHeight - thumbHeight

            Rectangle {
                id: scrollTrack
                anchors.fill: parent
                color: root.surfaceColor
                opacity: 0.3
                radius: 4
            }

            Rectangle {
                id: scrollThumb
                x: 0
                y: {
                    if (customScrollBar.contentHeight <= customScrollBar.scrollBarHeight) return 0
                    var ratio = messagesView.contentY / Math.max(1, customScrollBar.contentHeight - customScrollBar.scrollBarHeight)
                    return ratio * customScrollBar.maxThumbY
                }
                width: parent.width
                height: customScrollBar.thumbHeight
                radius: 4
                color: thumbMouseArea.pressed ? root.primaryColor :
                       thumbMouseArea.containsMouse ? root.secondaryColor :
                       root.accentColor
                opacity: 0.8

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }

            MouseArea {
                id: thumbMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: {
                    var mouseY = mouseY
                    var isOverThumb = mouseY >= scrollThumb.y && mouseY <= (scrollThumb.y + scrollThumb.height)
                    return isOverThumb ? Qt.PointingHandCursor : Qt.ArrowCursor
                }

                property bool isDragging: false
                property real dragStartY: 0
                property real thumbStartY: 0

                onPressed: function(mouse) {
                    var mouseY = mouse.y
                    var thumbY = scrollThumb.y
                    var thumbBottom = thumbY + scrollThumb.height

                    if (mouseY >= thumbY && mouseY <= thumbBottom) {
                        isDragging = true
                        dragStartY = mouseY
                        thumbStartY = thumbY
                    } else {
                        if (customScrollBar.contentHeight <= customScrollBar.scrollBarHeight) return

                        var clickRatio = mouseY / height
                        var targetContentY = clickRatio * (customScrollBar.contentHeight - customScrollBar.scrollBarHeight)
                        messagesView.contentY = Math.max(0, Math.min(targetContentY, customScrollBar.contentHeight - customScrollBar.scrollBarHeight))
                    }
                }

                onPositionChanged: function(mouse) {
                    if (isDragging && customScrollBar.contentHeight > customScrollBar.scrollBarHeight) {
                        var delta = mouse.y - dragStartY
                        var newThumbY = thumbStartY + delta
                        newThumbY = Math.max(0, Math.min(newThumbY, customScrollBar.maxThumbY))

                        var ratio = newThumbY / customScrollBar.maxThumbY
                        var newContentY = ratio * (customScrollBar.contentHeight - customScrollBar.scrollBarHeight)
                        messagesView.contentY = Math.max(0, Math.min(newContentY, customScrollBar.contentHeight - customScrollBar.scrollBarHeight))
                    }
                }

                onReleased: {
                    isDragging = false
                }

                onWheel: function(wheel) {
                    var delta = wheel.angleDelta.y
                    var scrollAmount = delta > 0 ? -60 : 60
                    var newContentY = messagesView.contentY + scrollAmount
                    newContentY = Math.max(0, Math.min(newContentY, messagesView.contentHeight - messagesView.height))
                    messagesView.contentY = newContentY
                }
            }
        }

    }

    // Input area
    Rectangle {
        id: inputArea
        anchors.bottom: parent.bottom
        anchors.left: chatList.right
        anchors.right: modelPanel.left
        height: 70
        color: root.surfaceColor

        Rectangle {
            id: inputContainer
            anchors.left: parent.left
            anchors.right: sendButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 15
            anchors.rightMargin: 10
            height: 40
            color: root.inputBackground
            radius: 20
            border.color: inputField.activeFocus ? root.primaryColor : "transparent"
            border.width: 2

            TextField {
                id: inputField
                anchors.fill: parent
                anchors.margins: 10
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                placeholderText: "Type your message..."
                placeholderTextColor: root.textSecondary
                color: root.textPrimary
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true

                background: Rectangle {
                    color: "transparent"
                    border.width: 0
                }

                Keys.onReturnPressed: {
                    if (llamaConnector.isGenerating) {
                            return  // Блокируем отправку во время генерации
                        }
                    if (inputField.text.trim() !== "") {
                        chatManager.addMessage(inputField.text.trim(), true)
                        llamaConnector.sendMessage(inputField.text.trim())
                        inputField.text = ""
                    }
                }
            }
        }

        Rectangle {
            id: sendButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 15
            width: 40
            height: 40
            radius: 20
            color: llamaConnector.isGenerating ? "#1A77EB" : root.primaryColor

            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            Text {
                anchors.centerIn: parent
                text: llamaConnector.isGenerating ? "■" : "↑"
                color: "white"
                font.pixelSize: llamaConnector.isGenerating ? 14 : 16
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (llamaConnector.isGenerating) {
                        llamaConnector.stopGeneration()
                    } else {
                        sendMessage()
                    }
                }
            }
        }
    }

    function scrollToBottom() {
        messagesView.positionViewAtEnd()
    }

    function sendMessage() {
        if (llamaConnector.isGenerating) return

        var messageText = inputField.text.trim()
        if (messageText !== "") {
            inputField.text = ""
            chatManager.addMessage(messageText, true)
            llamaConnector.sendMessage(messageText)
        }
    }

    function loadMessages() {
        // Очищаем все сообщения кроме welcome message
        for (var i = chatContent.children.length - 1; i >= 1; i--) {
            chatContent.children[i].destroy()
        }

        var messages = chatManager.getCurrentMessages()
        console.log("Loading", messages.length, "messages from DB")  // ✅ Отладка

        for (var j = 0; j < messages.length; j++) {
            var msg = messages[j]
            console.log("Message", j, "- isUser:", msg.isUser, "blocks:", msg.blocks ? msg.blocks.length : 0)

            // ✅ Передаём blocks
            var bubble = createMessageBubble(msg.text, msg.isUser, msg.blocks)
            if (!bubble) {
                console.log("ERROR: Failed to create bubble for message", j)
            }
        }

        scrollToBottom()
    }

    // НОВАЯ функция для добавления одного сообщения без перезагрузки всех
    function addSingleMessage(text, isUser) {
        createSimpleBubble(text, isUser)
        scrollToBottom()
    }



    function createSimpleBubble(text, isUser) {
        var bubble = messageBubbleComponent.createObject(chatContent, {
            "messageText": text,
            "isUserMessage": isUser,
            "width": Qt.binding(function() { return chatContent.width })
        })

        if (!bubble) {
            console.log("ERROR: Failed to create MessageBubble")
        }
    }

    // Добавить новую функцию для создания сообщений
    function createMessageBubble(text, isUser, blocks) {
        var messageComponent = Qt.createComponent("MessageBubble.qml")
        if (messageComponent.status === Component.Ready) {
            var messageObject = messageComponent.createObject(chatContent, {
                "messageText": text,
                "isUserMessage": isUser,
                "parsedBlocks": blocks || [],
                "width": Qt.binding(function() { return chatContent.width })
            })
            return messageObject  // ДОБАВИТЬ
        }
        return null  // ДОБАВИТЬ
    }

    // Connections for LM Studio
    Connections {
        target: llamaConnector

        property string currentResponse: ""
        property int currentMessageIndex: -1

        function onTokenGenerated(token) {
            currentResponse += token

            // Обновляем ТОЛЬКО последнее сообщение модели
            if (currentMessageIndex === -1) {
                // Создаём новое сообщение в модели
                chatManager.addMessage(currentResponse, false)
                currentMessageIndex = chatManager.messageCount - 1
            } else {
                // Обновляем существующее (тут нужен метод updateLastMessage в C++)
                chatManager.updateLastMessage(currentResponse)
            }

            messagesView.positionViewAtEnd()
        }

        function onGenerationFinished(tokens, duration) {
            currentResponse = ""
            currentMessageIndex = -1

            // Финальное обновление с парсингом уже произошло в addMessage
            messagesView.positionViewAtEnd()
        }
    }

    // Connections for ChatManager
    Connections {
        target: chatManager

        function onCurrentChatChanged() {
            messagesView.shouldAutoScroll = false
            // ListView автоматически перезагрузит модель
            messagesView.model = chatManager.getCurrentMessages()
            Qt.callLater(function() {
                messagesView.positionViewAtEnd()
                messagesView.shouldAutoScroll = true
            })
        }

        function onMessageAdded(text, isUser) {
            // ListView автоматически обновится через model
            scrollToBottom()
        }
    }

    // Adaptive sizing
    onWidthChanged: {
        if (width < 600) {
            header.anchors.leftMargin = 10
            header.anchors.rightMargin = 10
            contentArea.anchors.margins = 10
            inputArea.anchors.margins = 10
        } else {
            header.anchors.leftMargin = 20
            header.anchors.rightMargin = 20
            contentArea.anchors.margins = 20
            inputArea.anchors.margins = 20
        }
    }

    Component.onCompleted: {
        inputField.forceActiveFocus()
        // loadMessages() больше не нужен!
    }

}
