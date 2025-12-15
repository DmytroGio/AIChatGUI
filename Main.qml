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
    title: "Chat Assistant"

    flags: Qt.Window | Qt.WindowTitleHint | Qt.WindowSystemMenuHint |
           Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint |
           Qt.WindowCloseButtonHint

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

        // Menu and New Chat button group
        Rectangle {
            id: controlButtonsGroup
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            width: root.showChatList ? menuButton.width : (menuButton.width + newChatButton.width + 10)
            height: 35
            radius: 8
            color: root.inputBackground
            opacity: 0.6

            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }

            // Menu button
            Rectangle {
                id: menuButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 35
                height: 35
                radius: 8
                color: root.showChatList ? root.primaryColor : "transparent"
                border.color: menuMouseArea.containsMouse ? "white" : "transparent"
                border.width: 2

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "/icons/Chats_Icon.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: menuMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.showChatList = !root.showChatList
                }

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }

            // New Chat button (visible when chat list is closed)
            Rectangle {
                id: newChatButton
                anchors.left: menuButton.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 35
                height: 35
                radius: 8
                color: newChatMouseArea.pressed ? root.primaryColor : "transparent"
                border.color: newChatMouseArea.containsMouse ? "white" : "transparent"
                border.width: 2
                visible: !root.showChatList
                opacity: root.showChatList ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "/icons/NewChat_Icon.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: newChatMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        chatManager.createNewWelcomeChat()
                    }
                }
            }
        }

        // AI icon and info block
        Rectangle {
            id: aiInfoBlock
            anchors.left: controlButtonsGroup.right
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            height: 45
            width: aiInfoRow.width + 20
            radius: 10
            color: root.inputBackground
            opacity: 0.9

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: root.primaryColor
                shadowOpacity: 0.3
                shadowBlur: 0.4
                shadowScale: 1.02
            }

            Row {
                id: aiInfoRow
                anchors.centerIn: parent
                spacing: 12

                Image {
                    width: 32
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter
                    source: "/icons/Ai_Icon.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: chatManager.isWelcomeChat ? "New Chat" : chatManager.currentChatTitle
                        color: root.textPrimary
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: "Connected to Local Model"
                        color: root.textSecondary
                        font.pixelSize: 11
                    }
                }
            }
        }

        // Connection status and Model Panel button group
        Rectangle {
            id: statusButtonsGroup
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            width: root.showModelPanel ? modelPanelButton.width : (connectionStatus.width + modelPanelButton.width + 10)
            height: 40
            radius: 8
            color: root.inputBackground
            opacity: 0.6

            Behavior on width {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }

            // Connection status indicator
            Rectangle {
                id: connectionStatus
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 8
                color: "transparent"
                visible: !root.showModelPanel
                opacity: root.showModelPanel ? 0 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                }

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: modelInfo.isLoaded ? root.primaryColor : "#808080"
                    anchors.centerIn: parent

                    SequentialAnimation on opacity {
                        running: modelInfo.status === "Generating"
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
                    }
                }
            }

            // Model Panel button
            Rectangle {
                id: modelPanelButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 8
                color: root.showModelPanel ? root.primaryColor : "transparent"
                border.color: modelMouseArea.containsMouse ? "white" : "transparent"
                border.width: 2

                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: "/icons/Stats_Icon.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: modelMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showModelPanel = !root.showModelPanel
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
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

        // Welcome page
        Item {
            id: welcomePage
            anchors.fill: parent
            visible: chatManager.isWelcomeChat

            Column {
                anchors.centerIn: parent
                spacing: 30

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 200
                    height: 200
                    source: "/icons/AiGui_Logo_med.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Hello, User!"
                    color: root.textPrimary
                    font.pixelSize: 36
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Start chatting with the AI assistant"
                    color: root.textSecondary
                    font.pixelSize: 16
                    opacity: 0.8
                }

                // Example questions
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Repeater {
                        model: chatManager.exampleQuestions

                        Rectangle {
                            width: 450
                            height: editScrollView.visible ? Math.min(editField.contentHeight + 20, 140) : 50
                            color: root.inputBackground
                            radius: 12
                            border.color: editScrollView.visible ? root.primaryColor : "transparent"
                            border.width: 2

                            Behavior on height {
                                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                            }

                            // Question text
                            Item {
                                anchors.left: parent.left
                                anchors.right: editButton.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 15
                                anchors.rightMargin: 5

                                Text {
                                    id: questionText
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    text: modelData
                                    color: root.textSecondary
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    visible: !editField.visible
                                }

                                ScrollView {
                                    id: editScrollView
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: Math.min(editField.contentHeight + 4, 120)
                                    visible: false
                                    clip: true
                                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                    ScrollBar.vertical.policy: editField.contentHeight > 116 ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

                                    TextEdit {
                                        id: editField
                                        width: editScrollView.width
                                        text: modelData
                                        color: root.textPrimary
                                        font.pixelSize: 14
                                        selectByMouse: true
                                        selectionColor: root.primaryColor
                                        selectedTextColor: "white"
                                        wrapMode: TextEdit.Wrap

                                        Keys.onReturnPressed: {
                                            saveEdit()
                                        }
                                        Keys.onEscapePressed: {
                                            editScrollView.visible = false
                                            editField.text = modelData
                                        }

                                        function saveEdit() {
                                            chatManager.updateExampleQuestion(index, editField.text)
                                            editScrollView.visible = false
                                        }
                                    }
                                }

                                MouseArea {
                                    id: suggestionArea
                                    anchors.fill: parent
                                    anchors.rightMargin: -40  // Расширяем область на кнопку
                                    hoverEnabled: true
                                    cursorShape: containsMouse && mouseX < width - 40 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    enabled: !editField.visible

                                    onClicked: function(mouse) {
                                        // Кликаем только если не в зоне кнопки
                                        if (mouse.x < width - 40) {
                                            var cleanText = modelData.replace(/^[\u{1F000}-\u{1F9FF}]\s*/u, "")
                                            inputField.text = cleanText
                                            inputField.forceActiveFocus()
                                        }
                                    }
                                }
                            }

                            // Edit button
                            Rectangle {
                                id: editButton
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 30
                                radius: 6
                                color: editMouseArea.pressed ? root.primaryColor :
                                       editMouseArea.containsMouse ? Qt.darker(root.inputBackground, 1.2) :
                                       Qt.darker(root.inputBackground, 1.2)

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: editScrollView.visible ? "✓" : "✎"
                                    color: editScrollView.visible ? "white" : root.textSecondary
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    id: editMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (editScrollView.visible) {
                                            editField.saveEdit()
                                        } else {
                                            editScrollView.visible = true
                                            editField.forceActiveFocus()
                                            editField.selectAll()
                                        }
                                    }
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation { duration: 200 }
                            }
                        }


                    }
                }
            }
        }

        // Messages list
        ListView {
            id: messagesView
            anchors.fill: parent
            anchors.margins: 15
            anchors.rightMargin: 30
            model: chatManager.messageModel
            spacing: 15
            clip: true
            visible: !welcomePage.visible

            cacheBuffer: 50000
            reuseItems: false

            ScrollBar.vertical: null
            ScrollBar.horizontal: null

            property bool shouldAutoScroll: true

            onCountChanged: {
                if (shouldAutoScroll && count > 0) {
                    Qt.callLater(function() {
                        positionViewAtEnd()
                    })
                }
            }

            delegate: SimpleMessageBubble {
                width: messagesView.width
                messageText: model.text || ""
                isUserMessage: model.isUser || false
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

        // Custom scrollbar
        Item {
            id: customScrollBar
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 5
            anchors.topMargin: 15
            anchors.bottomMargin: 15
            width: 10

            visible: messagesView.contentHeight > messagesView.height

            Rectangle {
                id: scrollTrack
                anchors.fill: parent
                color: root.surfaceColor
                opacity: 0.3
                radius: 5
            }

            Rectangle {
                id: scrollThumb
                x: 0
                width: parent.width
                radius: 5
                color: thumbMouseArea.pressed ? root.primaryColor :
                       thumbMouseArea.containsMouse ? root.secondaryColor :
                       root.accentColor
                opacity: 0.8

                height: {
                    if (messagesView.contentHeight <= 0) return 30
                    var viewHeight = messagesView.height
                    var contentHeight = messagesView.contentHeight

                    if (contentHeight <= viewHeight) return parent.height

                    var ratio = viewHeight / contentHeight
                    return Math.max(30, parent.height * ratio)
                }

                y: {
                    if (messagesView.contentHeight <= messagesView.height) return 0

                    var viewHeight = messagesView.height
                    var contentHeight = messagesView.contentHeight
                    var contentY = messagesView.contentY

                    var maxContentY = contentHeight - viewHeight
                    if (maxContentY <= 0) return 0

                    var maxThumbY = parent.height - height
                    if (maxThumbY <= 0) return 0

                    var ratio = contentY / maxContentY
                    return Math.max(0, Math.min(ratio * maxThumbY, maxThumbY))
                }

                Behavior on color {
                    ColorAnimation { duration: 200 }
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
                    messagesView.shouldAutoScroll = false
                }

                onPositionChanged: function(mouse) {
                    if (!isDragging) return

                    var viewHeight = messagesView.height
                    var contentHeight = messagesView.contentHeight
                    var maxContentY = contentHeight - viewHeight

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

                    var maxContentY = messagesView.contentHeight - messagesView.height
                    if (messagesView.contentY >= maxContentY - 10) {
                        messagesView.shouldAutoScroll = true
                    }
                }

                onWheel: function(wheel) {
                    var delta = wheel.angleDelta.y
                    var scrollAmount = delta > 0 ? -80 : 80
                    var maxContentY = messagesView.contentHeight - messagesView.height
                    var newContentY = messagesView.contentY + scrollAmount
                    messagesView.contentY = Math.max(0, Math.min(newContentY, maxContentY))

                    if (scrollAmount < 0) {
                        messagesView.shouldAutoScroll = false
                    }

                    if (messagesView.contentY >= maxContentY - 10) {
                        messagesView.shouldAutoScroll = true
                    }
                }
            }
        }

        // Middle mouse button auto-scroll
        MouseArea {
            id: autoScrollArea
            anchors.fill: parent
            acceptedButtons: Qt.MiddleButton
            hoverEnabled: true
            propagateComposedEvents: true

            property bool isAutoScrolling: false
            property point anchorPos

            onPressed: function(mouse) {
                if (mouse.button === Qt.MiddleButton) {
                    isAutoScrolling = true
                    anchorPos = Qt.point(mouse.x, mouse.y)

                    autoScrollCursor.x = anchorPos.x - autoScrollCursor.width / 2
                    autoScrollCursor.y = anchorPos.y - autoScrollCursor.height / 2
                    autoScrollCursor.visible = true

                    messagesView.shouldAutoScroll = false
                    scrollTimer.start()
                }
            }

            onReleased: function(mouse) {
                if (mouse.button === Qt.MiddleButton) {
                    isAutoScrolling = false
                    autoScrollCursor.visible = false
                    scrollTimer.stop()

                    var maxContentY = messagesView.contentHeight - messagesView.height
                    if (messagesView.contentY >= maxContentY - 10) {
                        messagesView.shouldAutoScroll = true
                    }
                }
            }

            Timer {
                id: scrollTimer
                interval: 16
                repeat: true
                running: false

                onTriggered: {
                    if (!autoScrollArea.isAutoScrolling) return

                    var globalPos = autoScrollArea.mapToGlobal(Qt.point(autoScrollArea.mouseX, autoScrollArea.mouseY))
                    var localPos = autoScrollArea.mapFromGlobal(globalPos)

                    var deltaY = localPos.y - autoScrollArea.anchorPos.y

                    // Speed depends on distance (dead zone 10px)
                    var speed = Math.abs(deltaY) > 10 ? deltaY * 0.4 : 0

                    var maxContentY = messagesView.contentHeight - messagesView.height
                    var newContentY = messagesView.contentY + speed
                    messagesView.contentY = Math.max(0, Math.min(newContentY, maxContentY))

                    // Update cursor color and direction
                    if (Math.abs(deltaY) < 10) {
                        autoScrollCursor.color = root.textSecondary
                        autoScrollCursor.showDirection = "none"
                    } else if (deltaY < 0) {
                        autoScrollCursor.color = root.primaryColor
                        autoScrollCursor.showDirection = "up"
                    } else {
                        autoScrollCursor.color = root.secondaryColor
                        autoScrollCursor.showDirection = "down"
                    }
                }
            }

            // Auto-scroll indicator
            Rectangle {
                id: autoScrollCursor
                width: 40
                height: 40
                radius: 20
                color: root.textSecondary
                opacity: 0.8
                visible: false
                z: 100

                property string showDirection: "none"

                Item {
                    anchors.centerIn: parent
                    width: 20
                    height: 20

                    Text {
                        anchors.centerIn: parent
                        text: autoScrollCursor.showDirection === "none" ? "◆" :
                              autoScrollCursor.showDirection === "up" ? "▲" : "▼"
                        color: "white"
                        font.pixelSize: autoScrollCursor.showDirection === "none" ? 16 : 14
                        font.bold: true
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }

    // Input area
    Rectangle {
        id: inputArea
        height: Math.min(Math.max(70, inputField.contentHeight + 30), 300)
        anchors.bottom: parent.bottom
        anchors.left: chatList.right
        anchors.right: modelPanel.left
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.bottomMargin: 20
        color: root.surfaceColor

        Behavior on height {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                inputField.forceActiveFocus()
                inputField.cursorPosition = inputField.length
            }
            propagateComposedEvents: true
            z: -1
        }

        Rectangle {
            id: inputContainer
            anchors.left: parent.left
            anchors.right: sendButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 15
            anchors.rightMargin: 10
            height: Math.min(Math.max(40, inputField.contentHeight + 16), 270)
            color: root.inputBackground
            radius: 20
            border.color: inputField.activeFocus ? root.primaryColor : "transparent"
            border.width: 2

            Behavior on height {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    inputField.forceActiveFocus()
                    inputField.cursorPosition = inputField.length
                }
                propagateComposedEvents: true
                z: -1
            }

            ScrollView {
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: inputField.contentHeight > 200 ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

                Item {
                    width: parent.width
                    height: Math.max(parent.height, inputField.contentHeight)

                    TextEdit {
                        id: inputField
                        width: parent.width
                        color: root.textPrimary
                        font.pixelSize: 16
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        selectionColor: root.primaryColor
                        selectedTextColor: "white"
                        leftPadding: 8
                        rightPadding: 8
                        verticalAlignment: TextEdit.AlignVCenter
                        renderType: Text.NativeRendering

                        Keys.onReturnPressed: function(event) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                event.accepted = false
                            } else {
                                event.accepted = true
                                if (inputField.text.trim().length > 0) {
                                    sendMessage()
                                }
                            }
                        }

                        Keys.onEnterPressed: function(event) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                event.accepted = false
                            } else {
                                event.accepted = true
                                if (inputField.text.trim().length > 0) {
                                    sendMessage()
                                }
                            }
                        }

                        Text {
                            id: placeholderText
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            text: "Type your message..."
                            color: root.textSecondary
                            font.pixelSize: 16
                            verticalAlignment: Text.AlignVCenter
                            visible: inputField.text.length === 0
                            enabled: false
                        }

                        cursorDelegate: Rectangle {
                            width: 1
                            color: "white"
                            visible: inputField.cursorVisible

                            SequentialAnimation on visible {
                                running: inputField.cursorVisible
                                loops: Animation.Infinite
                                PropertyAnimation { to: true; duration: 0 }
                                PauseAnimation { duration: 500 }
                                PropertyAnimation { to: false; duration: 0 }
                                PauseAnimation { duration: 500 }
                            }
                        }
                    }

                    // MouseArea over the entire Item container
                    MouseArea {
                        anchors.fill: parent
                        onClicked: function(mouse) {
                            inputField.forceActiveFocus()
                            if (mouse.y <= inputField.contentHeight) {
                                inputField.cursorPosition = inputField.positionAt(mouse.x, mouse.y)
                            } else {
                                inputField.cursorPosition = inputField.length
                            }
                        }
                        onPressed: function(mouse) {
                            inputField.forceActiveFocus()
                            mouse.accepted = false
                        }
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

            property bool hasText: inputField.text.trim().length > 0

            color: {
                if (llamaConnector.isGenerating) return "#1A77EB"
                if (!hasText) return root.inputBackground
                if (sendMouseArea.containsMouse) return Qt.lighter(root.primaryColor, 1.2)
                return root.primaryColor
            }

            opacity: hasText || llamaConnector.isGenerating ? 1.0 : 0.4

            layer.enabled: hasText || llamaConnector.isGenerating
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: llamaConnector.isGenerating ? "#1A77EB" : root.primaryColor
                shadowOpacity: sendMouseArea.containsMouse ? 0.3 : 0.15
                shadowBlur: sendMouseArea.containsMouse ? 0.35 : 0.25
                shadowScale: 1.02
            }

            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            scale: (hasText && sendMouseArea.containsMouse && !llamaConnector.isGenerating) ? 1.05 : 1.0

            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }

            Image {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: "/icons/Send_Icon.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: !llamaConnector.isGenerating
                opacity: hasText ? 1.0 : 0.5

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "■"
                color: "white"
                font.pixelSize: 14
                font.bold: true
                visible: llamaConnector.isGenerating
            }

            MouseArea {
                id: sendMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: parent.hasText || llamaConnector.isGenerating ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: parent.hasText || llamaConnector.isGenerating

                onClicked: {
                    if (llamaConnector.isGenerating) {
                        llamaConnector.stopGeneration()
                    } else if (parent.hasText) {
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

    // Connections for LlamaConnector
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

            Qt.callLater(function() {
                messagesView.positionViewAtEnd()
            })
        }

        function onGenerationFinished(tokens, duration) {
            currentResponse = ""
            currentMessageIndex = -1
            messagesView.positionViewAtEnd()
        }
    }

    // Connections for ChatManager
    Connections {
        target: chatManager

        function onCurrentChatChanged() {
            messagesView.shouldAutoScroll = false

            Qt.callLater(function() {
                messagesView.positionViewAtEnd()
                messagesView.currentIndex = messagesView.count - 1

                Qt.callLater(function() {
                    messagesView.positionViewAtEnd()
                    messagesView.shouldAutoScroll = true
                })
            })
        }

        function onMessageAdded(text, isUser) {
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
