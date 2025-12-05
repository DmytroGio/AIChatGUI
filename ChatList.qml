import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects

Rectangle {
    id: chatListPanel
    property bool isOpen: false
    property real panelWidth: 280

    width: isOpen ? panelWidth : 0
    color: "#16213e"
    clip: true

    Behavior on width {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        color: "#1a1b2e"
        opacity: 0.9
    }

    Column {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // 🎨 НОВЫЙ СТИЛЬНЫЙ ХЕДЕР
        Rectangle {
            id: headerContainer
            width: parent.width
            height: 100
            radius: 15

            // Градиентный фон
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1e2749" }
                GradientStop { position: 1.0; color: "#16213e" }
            }

            // Эффект свечения
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#4facfe"
                shadowOpacity: 0.25
                shadowBlur: 0.5
                shadowScale: 1.03
            }

            // Декоративная полоска сверху
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 3
                radius: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#4facfe" }
                    GradientStop { position: 0.5; color: "#00f2fe" }
                    GradientStop { position: 1.0; color: "#6c5ce7" }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                anchors.topMargin: 15
                spacing: 12

                // Верхняя часть - иконка и заголовок
                Row {
                    width: parent.width
                    height: 42
                    spacing: 12

                    // Иконка в стильной рамке
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#16213e"
                        border.color: "#4facfe"
                        border.width: 2

                        // Внутреннее свечение
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 8
                            color: "transparent"
                            border.color: "#4facfe"
                            border.width: 1
                            opacity: 0.3
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: "/icons/Chat_Icon.svg"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    // Текст и счётчик
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: "Chat History"
                            color: "#ffffff"
                            font.pixelSize: 18
                            font.bold: true
                            font.letterSpacing: 0.5
                        }

                        Row {
                            spacing: 8

                            Rectangle {
                                width: chatCountText.width + 12
                                height: 18
                                radius: 9
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#4facfe" }
                                    GradientStop { position: 1.0; color: "#6c5ce7" }
                                }

                                Text {
                                    id: chatCountText
                                    anchors.centerIn: parent
                                    text: chatManager.chatList.length + " chats"
                                    color: "#ffffff"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            // Индикатор активности
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: "#00f2fe"
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on opacity {
                                    running: true
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 1000 }
                                    NumberAnimation { to: 1.0; duration: 1000 }
                                }
                            }
                        }
                    }

                    Item {
                        width: 1
                        height: 1
                    }
                }

                // Нижняя часть - кнопка New Chat
                Rectangle {
                    id: newChatBtn
                    width: parent.width
                    height: 40
                    radius: 10
                    color: newChatMouseArea.containsMouse ? "#2d3748" : "#1a2332"
                    border.color: newChatMouseArea.containsMouse ? "#4facfe" : "transparent"
                    border.width: 2

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: 200 }
                    }

                    // Эффект при нажатии
                    scale: newChatMouseArea.pressed ? 0.97 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 100 }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 10

                        // Иконка плюса в кружочке
                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            anchors.verticalCenter: parent.verticalCenter
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#4facfe" }
                                GradientStop { position: 1.0; color: "#00f2fe" }
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: "/icons/NewChat_Icon.svg"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "New Conversation"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }

                        // Стрелка
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "→"
                            color: "#4facfe"
                            font.pixelSize: 16
                            opacity: newChatMouseArea.containsMouse ? 1.0 : 0.5

                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
                            }
                        }
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
        }

        // Декоративный разделитель с градиентом
        Rectangle {
            width: parent.width
            height: 2
            radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: "#4facfe" }
                GradientStop { position: 1.0; color: "transparent" }
            }
            opacity: 0.4
        }

        // Chat list area
        Item {
            width: parent.width
            height: parent.height - 115

            ListView {
                id: chatListView
                anchors.fill: parent
                anchors.rightMargin: 15
                model: chatManager.chatList
                spacing: 8
                clip: true

                delegate: Rectangle {
                    width: chatListView.width
                    height: 55
                    color: modelData.isCurrent ? "#2d3748" : "transparent"
                    radius: 10
                    border.color: modelData.isCurrent ? "#4facfe" : "transparent"
                    border.width: modelData.isCurrent ? 2 : 0

                    // Фоновая подсветка при hover
                    Rectangle {
                        anchors.fill: parent
                        color: "#4facfe"
                        opacity: chatMouseArea.containsMouse && !modelData.isCurrent ? 0.08 : 0.0
                        radius: parent.radius

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        // Иконка чата
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: modelData.isCurrent ? "#4facfe" : "#1e2749"
                            border.color: modelData.isCurrent ? "transparent" : "#4facfe"
                            border.width: 1

                        }

                        // Контент
                        Column {
                            width: parent.width - 32 - deleteBtn.width - 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Text {
                                text: modelData.title
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.weight: modelData.isCurrent ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: formatTime(modelData.lastTimestamp)
                                color: modelData.isCurrent ? "#4facfe" : "#7a7a8c"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                        }

                        // Кнопка удаления
                        Rectangle {
                            id: deleteBtn
                            width: 32
                            height: 32
                            radius: 8
                            color: deleteBtnMouseArea.containsMouse ? "#e74c3c" : "#2d3748"
                            opacity: (chatMouseArea.containsMouse || deleteBtnMouseArea.containsMouse) ? 1.0 : 0.0
                            visible: !modelData.isCurrent || chatManager.chatList.length > 1
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
                            }

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }

                            // Иконка корзины
                            Text {
                                anchors.centerIn: parent
                                text: "🗑"
                                font.pixelSize: 14
                            }

                            MouseArea {
                                id: deleteBtnMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    chatListPanel.showDeleteDialog(modelData.id, modelData.title)
                                    mouse.accepted = true
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: chatMouseArea
                        anchors.fill: parent
                        anchors.rightMargin: deleteBtn.width + 12
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (!modelData.isCurrent) {
                                chatManager.switchToChat(modelData.id)
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: chatListView.right

                onWheel: {
                    var delta = wheel.angleDelta.y
                    var scrollAmount = delta > 0 ? -60 : 60
                    var newContentY = chatListView.contentY + scrollAmount
                    newContentY = Math.max(0, Math.min(newContentY, chatListView.contentHeight - chatListView.height))
                    chatListView.contentY = newContentY
                }
            }
        }
    }

    // Кастомный скроллбар
    Item {
        id: chatListScrollBar
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 95
        anchors.bottom: parent.bottom
        anchors.rightMargin: 5
        anchors.bottomMargin: 15
        width: 8
        visible: isOpen && chatListView.contentHeight > chatListView.height

        property real scrollBarHeight: chatListView.height
        property real contentHeight: chatListView.contentHeight
        property real thumbHeight: Math.max(20, (contentHeight > 0) ? scrollBarHeight * (scrollBarHeight / contentHeight) : 20)
        property real maxThumbY: scrollBarHeight - thumbHeight

        Rectangle {
            id: chatScrollTrack
            anchors.fill: parent
            color: "#16213e"
            opacity: 0.3
            radius: 4
        }

        Rectangle {
            id: chatScrollThumb
            x: 0
            y: {
                if (chatListScrollBar.contentHeight <= chatListScrollBar.scrollBarHeight) return 0
                return chatListView.contentY * chatListScrollBar.maxThumbY / Math.max(1, chatListScrollBar.contentHeight - chatListScrollBar.scrollBarHeight)
            }
            width: parent.width
            height: chatListScrollBar.thumbHeight
            radius: 4
            color: chatThumbMouseArea.pressed ? "#4facfe" :
                   chatThumbMouseArea.containsMouse ? "#00f2fe" :
                   "#6c5ce7"
            opacity: 0.8

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }

        MouseArea {
            id: chatThumbMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: {
                var mouseY = mouseY
                var isOverThumb = mouseY >= chatScrollThumb.y && mouseY <= (chatScrollThumb.y + chatScrollThumb.height)
                return isOverThumb ? Qt.PointingHandCursor : Qt.ArrowCursor
            }

            property bool isDragging: false
            property real dragStartY: 0
            property real thumbStartY: 0

            onPressed: function(mouse) {
                var mouseY = mouse.y
                var thumbY = chatScrollThumb.y
                var thumbBottom = thumbY + chatScrollThumb.height

                if (mouseY >= thumbY && mouseY <= thumbBottom) {
                    isDragging = true
                    dragStartY = mouseY
                    thumbStartY = thumbY
                } else {
                    if (chatListScrollBar.contentHeight <= chatListScrollBar.scrollBarHeight) return

                    var clickRatio = mouseY / height
                    var targetContentY = clickRatio * (chatListScrollBar.contentHeight - chatListScrollBar.scrollBarHeight)
                    chatListView.contentY = Math.max(0, Math.min(targetContentY, chatListScrollBar.contentHeight - chatListScrollBar.scrollBarHeight))
                }
            }

            onPositionChanged: function(mouse) {
                if (isDragging && chatListScrollBar.contentHeight > chatListScrollBar.scrollBarHeight) {
                    var delta = mouse.y - dragStartY
                    var newThumbY = thumbStartY + delta
                    newThumbY = Math.max(0, Math.min(newThumbY, chatListScrollBar.maxThumbY))

                    var ratio = newThumbY / chatListScrollBar.maxThumbY
                    var newContentY = ratio * (chatListScrollBar.contentHeight - chatListScrollBar.scrollBarHeight)
                    chatListView.contentY = Math.max(0, Math.min(newContentY, chatListScrollBar.contentHeight - chatListScrollBar.scrollBarHeight))
                }
            }

            onReleased: {
                isDragging = false
            }

            onWheel: function(wheel) {
                var delta = wheel.angleDelta.y
                var scrollAmount = delta > 0 ? -60 : 60
                var newContentY = chatListView.contentY + scrollAmount
                newContentY = Math.max(0, Math.min(newContentY, chatListView.contentHeight - chatListView.height))
                chatListView.contentY = newContentY
            }
        }
    }

    // Диалог подтверждения удаления
    Rectangle {
        id: deleteDialog
        anchors.fill: parent
        color: "#80000000"
        visible: false
        z: 100
        focus: visible

        property string chatIdToDelete: ""
        property string chatTitleToDelete: ""

        Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                chatManager.deleteChat(deleteDialog.chatIdToDelete)
                deleteDialog.visible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                deleteDialog.visible = false
                event.accepted = true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: deleteDialog.visible = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.9, 300)
            height: 140
            color: "#1a1b2e"
            radius: 15
            border.color: "#4facfe"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 20
                width: parent.width - 40

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Delete Chat"
                    color: "#ffffff"
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: 'Delete "' + deleteDialog.chatTitleToDelete + '"?'
                    color: "#a0a0a0"
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 15

                    Rectangle {
                        width: 80
                        height: 35
                        radius: 8
                        color: "#6c5ce7"

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "white"
                            font.pixelSize: 14
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                deleteDialog.visible = false
                            }
                        }
                    }

                    Rectangle {
                        width: 80
                        height: 35
                        radius: 8
                        color: "#e74c3c"

                        Text {
                            anchors.centerIn: parent
                            text: "Delete"
                            color: "white"
                            font.pixelSize: 14
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                chatManager.deleteChat(deleteDialog.chatIdToDelete)
                                deleteDialog.visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    function formatTime(timestamp) {
        if (!timestamp) return ""
        var date = new Date(timestamp)
        var now = new Date()

        if (date.toDateString() === now.toDateString()) {
            return date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})
        } else {
            return date.toLocaleDateString()
        }
    }

    function showDeleteDialog(chatId, chatTitle) {
        deleteDialog.chatIdToDelete = chatId
        deleteDialog.chatTitleToDelete = chatTitle
        deleteDialog.visible = true
        deleteDialog.forceActiveFocus()
    }
}
