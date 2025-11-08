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

            model: chatManager.messageModel
            spacing: 15
            clip: true

            // ✅ НОВОЕ: Увеличиваем буфер для меньших перезагрузок
            cacheBuffer: height * 3  // Было 1.5, стало 3
            displayMarginBeginning: 500  // Было 200
            displayMarginEnd: 500  // Было 200

            // ✅ Асинхронная загрузка
            reuseItems: true

            property bool shouldAutoScroll: true

            onCountChanged: {
                if (shouldAutoScroll && count > 0) {
                    Qt.callLater(function() {
                        positionViewAtEnd()
                    })
                }
            }

            onContentYChanged: {
                // Если скроллим почти к началу и есть ещё сообщения
                if (contentY < 300 && !atYBeginning && chatManager.messageModel.hasMoreMessages) {
                    // Защита от частых вызовов
                    if (!loadingOlderMessages) {
                        loadingOlderMessages = true
                        Qt.callLater(function() {
                            var oldContentHeight = contentHeight
                            chatManager.messageModel.loadOlderMessages(20)

                            // Сохраняем позицию скролла после загрузки
                            Qt.callLater(function() {
                                var newContentHeight = contentHeight
                                contentY += (newContentHeight - oldContentHeight)
                                loadingOlderMessages = false
                            })
                        })
                    }
                }
            }

            // ✅ НОВОЕ: Отключаем анимации во время активного скролла
            property bool isScrolling: false

            onMovingChanged: {
                if (moving) {
                    isScrolling = true
                } else {
                    scrollStopTimer.restart()
                }
            }

            Timer {
                id: scrollStopTimer
                interval: 200
                onTriggered: messagesView.isScrolling = false
            }

            property bool loadingOlderMessages: false

            delegate: MessageBubble {
                width: messagesView.width
                messageText: model.text
                isUserMessage: model.isUser
                parsedBlocks: model.blocks || []
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

        // ✅ ИСПРАВЛЕННЫЙ СКРОЛЛБАР
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
                width: parent.width
                radius: 4
                color: thumbMouseArea.pressed ? root.primaryColor :
                       thumbMouseArea.containsMouse ? root.secondaryColor :
                       root.accentColor
                opacity: 0.8

                // ✅ ИСПРАВЛЕНО: Стабильные расчёты высоты и позиции
                height: {
                    if (messagesView.contentHeight <= messagesView.height) return parent.height
                    var ratio = messagesView.height / messagesView.contentHeight
                    return Math.max(30, parent.height * ratio)  // Минимум 30px
                }

                y: {
                    if (messagesView.contentHeight <= messagesView.height) return 0

                    var maxContentY = messagesView.contentHeight - messagesView.height
                    var maxThumbY = parent.height - height

                    if (maxContentY <= 0) return 0

                    var ratio = messagesView.contentY / maxContentY
                    return Math.max(0, Math.min(ratio * maxThumbY, maxThumbY))
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }

                Behavior on height {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
            }

            MouseArea {
                id: thumbMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                property bool isDragging: false
                property real dragStartY: 0
                property real contentYAtDragStart: 0

                onPressed: function(mouse) {
                    isDragging = true
                    dragStartY = mouse.y
                    contentYAtDragStart = messagesView.contentY
                }

                onPositionChanged: function(mouse) {
                    if (!isDragging) return

                    var maxContentY = messagesView.contentHeight - messagesView.height
                    if (maxContentY <= 0) return

                    var maxThumbY = height - scrollThumb.height
                    if (maxThumbY <= 0) return

                    var deltaY = mouse.y - dragStartY
                    var deltaRatio = deltaY / maxThumbY
                    var newContentY = contentYAtDragStart + (deltaRatio * maxContentY)

                    messagesView.contentY = Math.max(0, Math.min(newContentY, maxContentY))
                }

                onReleased: {
                    isDragging = false
                }

                onWheel: function(wheel) {
                    var delta = wheel.angleDelta.y
                    var scrollAmount = delta > 0 ? -80 : 80
                    var maxContentY = messagesView.contentHeight - messagesView.height
                    var newContentY = messagesView.contentY + scrollAmount
                    messagesView.contentY = Math.max(0, Math.min(newContentY, maxContentY))
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

    // Connections for LM Studio
    Connections {
        target: llamaConnector

        property string currentResponse: ""
        property int currentMessageIndex: -1

        function onTokenGenerated(token) {
            currentResponse += token

            if (currentMessageIndex === -1) {
                chatManager.addMessage(currentResponse, false)
                currentMessageIndex = chatManager.messageCount - 1
            } else {
                chatManager.updateLastMessage(currentResponse)
            }

            // ✅ КРИТИЧНО: Обновляем модель при каждом токене
            messagesView.model = chatManager.getCurrentMessages()

            Qt.callLater(function() {
                messagesView.positionViewAtEnd()
            })
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
            messagesView.shouldAutoScroll = false
            Qt.callLater(function() {
                messagesView.positionViewAtEnd()
                messagesView.shouldAutoScroll = true
            })
        }

        function onMessageAdded(text, isUser) {
            // ✅ КРИТИЧНО: Принудительно обновляем модель
            //messagesView.model = chatManager.getCurrentMessages()
            Qt.callLater(function() {
                messagesView.positionViewAtEnd()
            })
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
    }

}
