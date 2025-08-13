import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects

ApplicationWindow {
    id: root
    visible: true
    width: 900
    height: 700
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

    // Header
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: chatList.right
        anchors.right: parent.right
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
                    text: "Connected to LM Studio"
                    color: root.textSecondary
                    font.pixelSize: 12
                }
            }
        }

        // Connection status indicator
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: root.secondaryColor

            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 1000 }
                NumberAnimation { to: 1.0; duration: 1000 }
            }
        }
    }

    // Main content area
    Rectangle {
        id: contentArea
        anchors.top: header.bottom
        anchors.left: chatList.right
        anchors.right: parent.right
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


        // делаем простую структуру с Flickable
        Flickable {
            id: flickable
            anchors.fill: parent
            anchors.margins: 15
            anchors.rightMargin: 25  // Место для скроллбара
            contentHeight: chatContent.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            interactive: false

            onContentHeightChanged: scrollToBottom()

            Column {
                id: chatContent
                width: parent.width
                spacing: 15

                // Welcome message
                Rectangle {
                    width: parent.width
                    height: chatManager.messageCount === 0 ? 80 : 0
                    color: "transparent"
                    visible: chatManager.messageCount === 0

                    Behavior on height {
                        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Start typing to begin..."
                        color: root.textSecondary
                        font.pixelSize: 16
                        font.weight: Font.Light
                        opacity: 0.7
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: flickable
            acceptedButtons: Qt.NoButton  // Только колесико, не кнопки

            onWheel: {
                var delta = wheel.angleDelta.y
                var scrollAmount = delta > 0 ? -60 : 60
                var newContentY = flickable.contentY + scrollAmount
                newContentY = Math.max(0, Math.min(newContentY, flickable.contentHeight - flickable.height))
                flickable.contentY = newContentY
            }
        }
        // Добавляем кастомный скроллбар
        Item {
            id: customScrollBar
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 5
            anchors.topMargin: 15
            anchors.bottomMargin: 15
            width: 8
            visible: flickable.contentHeight > flickable.height

            property real scrollBarHeight: flickable.height
            property real contentHeight: flickable.contentHeight
            property real thumbHeight: Math.max(20, scrollBarHeight * (scrollBarHeight / contentHeight))
            property real thumbY: flickable.contentY * (scrollBarHeight - thumbHeight) / Math.max(1, contentHeight - scrollBarHeight)

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
                y: customScrollBar.thumbY
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

                MouseArea {
                    id: thumbMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    drag.target: scrollThumb
                    drag.axis: Drag.YAxis
                    drag.minimumY: 0
                    drag.maximumY: customScrollBar.scrollBarHeight - scrollThumb.height

                    onPositionChanged: {
                        if (drag.active) {
                            var newContentY = scrollThumb.y * (customScrollBar.contentHeight - customScrollBar.scrollBarHeight) / (customScrollBar.scrollBarHeight - scrollThumb.height)
                            flickable.contentY = Math.max(0, Math.min(newContentY, customScrollBar.contentHeight - customScrollBar.scrollBarHeight))
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var clickRatio = mouse.y / height
                    var targetContentY = clickRatio * (customScrollBar.contentHeight - customScrollBar.scrollBarHeight)
                    flickable.contentY = Math.max(0, Math.min(targetContentY, customScrollBar.contentHeight - customScrollBar.scrollBarHeight))
                }

                onWheel: {
                    var delta = wheel.angleDelta.y
                    var scrollAmount = delta > 0 ? -60 : 60
                    var newContentY = flickable.contentY + scrollAmount
                    newContentY = Math.max(0, Math.min(newContentY, flickable.contentHeight - flickable.height))
                    flickable.contentY = newContentY
                }
            }
        }
    }// Input area
    Rectangle {
        id: inputArea
        anchors.bottom: parent.bottom
        anchors.left: chatList.right
        anchors.right: parent.right
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
                    if (inputField.text.trim() !== "") {
                        chatManager.addMessage(inputField.text.trim(), true)
                        lmstudio.sendMessage(inputField.text.trim())
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
            color: root.primaryColor

            Text {
                anchors.centerIn: parent
                text: "→"
                color: "white"
                font.pixelSize: 16
            }

            MouseArea {
                anchors.fill: parent
                onClicked: sendMessage()
            }
        }
    }
    // Function to add messages
    function addMessage(text, isUser) {
        chatManager.addMessage(text, isUser)
    }

    function sendMessage() {
        var messageText = inputField.text.trim()
        if (messageText !== "") {
            // Сначала добавляем сообщение пользователя в ChatManager
            chatManager.addMessage(messageText, true)
            // Затем отправляем в LM Studio
            lmstudio.sendMessage(messageText)
            inputField.text = ""
        }
    }

    function loadMessages() {
        // Очищаем все сообщения кроме welcome message (первый элемент)
        for (var i = chatContent.children.length - 1; i >= 1; i--) {
            chatContent.children[i].destroy()
        }

        // Загружаем сообщения текущего чата
        var messages = chatManager.getCurrentMessages()
        for (var j = 0; j < messages.length; j++) {
            var msg = messages[j]
            createMessageBubble(msg.text, msg.isUser)
        }

        scrollToBottom()
    }

    // Добавить новую функцию для создания сообщений
    function createMessageBubble(text, isUser) {
        var messageComponent = Qt.createComponent("MessageBubble.qml")
        if (messageComponent.status === Component.Ready) {
            var messageObject = messageComponent.createObject(chatContent, {
                "messageText": text,
                "isUserMessage": isUser,
                "width": Qt.binding(function() { return chatContent.width })
            })
        } else {
            console.log("MessageBubble component error:", messageComponent.errorString())
            addSimpleMessage(text, isUser)
        }
    }

    // Удалить старую функцию addMessage и addSimpleMessage, заменить на:
    function addSimpleMessage(text, isUser) {
        // Проверяем есть ли код в сообщении
        var hasCode = text.includes('```')

        if (hasCode && !isUser) {
            // Если есть код, используем MessageBubble компонент
            var messageComponent = Qt.createComponent("MessageBubble.qml")
            if (messageComponent.status === Component.Ready) {
                var messageObject = messageComponent.createObject(chatContent, {
                    "messageText": text,
                    "isUserMessage": isUser,
                    "width": Qt.binding(function() { return chatContent.width })
                })
                scrollToBottom()
                return
            }
        }

        // Обычное сообщение без кода
        var messageRect = Qt.createQmlObject(`
            import QtQuick 2.15
            Rectangle {
                width: parent.width
                height: messageText.height + 20
                color: "transparent"

                Rectangle {
                    anchors.right: ${isUser ? 'parent.right' : 'undefined'}
                    anchors.left: ${isUser ? 'undefined' : 'parent.left'}
                    anchors.rightMargin: ${isUser ? '0' : 'parent.width * 0.2'}
                    anchors.leftMargin: ${isUser ? 'parent.width * 0.2' : '0'}
                    width: Math.min(messageText.implicitWidth + 30, parent.width * 0.8)
                    height: parent.height
                    color: "${isUser ? root.messageUserBg : root.messageAiBg}"
                    radius: 15
                    opacity: 0.8

                    Text {
                         id: messageText
                         anchors.centerIn: parent
                         text: "${text.replace(/"/g, '\\"').replace(/\n/g, '\\n')}"
                         color: "${root.textPrimary}"
                         font.pixelSize: 14
                         wrapMode: Text.Wrap
                         width: parent.width - 20
                         horizontalAlignment: ${isUser ? 'Text.AlignRight' : 'Text.AlignLeft'}
                     }
                }
            }
        `, chatContent)

        scrollToBottom()
    }

    function scrollToBottom() {
        scrollTimer.restart()
    }

    Timer {
        id: scrollTimer
        interval: 50
        onTriggered: {
            flickable.contentY = Math.max(0, flickable.contentHeight - flickable.height)
        }
    }

    // Connections for LM Studio
    Connections {
        target: lmstudio
        function onMessageReceived(response) {
            addMessage(response, false)
            scrollToBottom()
        }
    }

    // Connections for ChatManager
    Connections {
        target: chatManager
        function onMessagesChanged() {
            // Добавляем небольшую задержку для корректного обновления
            Qt.callLater(loadMessages)
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
        loadMessages()  // Добавить эту строку
    }

}
