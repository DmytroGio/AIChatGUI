import QtQuick 2.15
import QtQuick.Controls 2.15

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
        anchors.margins: 15
        spacing: 10

        // Header
        Row {
            width: parent.width
            height: 40
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "💬 Chats"
                color: "#ffffff"
                font.pixelSize: 18
                font.bold: true
            }

            Item { width: parent.width - newChatBtn.width - 80 }

            Rectangle {
                id: newChatBtn
                width: 30
                height: 30
                radius: 15
                color: "#4facfe"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: chatManager.createNewChat()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#4facfe"
            opacity: 0.3
        }

        // Chat list area
        Item {
            width: parent.width
            height: parent.height - 60

            ListView {
                id: chatListView
                anchors.fill: parent
                anchors.rightMargin: 15  // Место для скроллбара
                model: chatManager.chatList
                spacing: 5
                clip: true

                delegate: Rectangle {
                    width: chatListView.width
                    height: 70
                    color: modelData.isCurrent ? "#2d3748" : "transparent"
                    radius: 10

                    Rectangle {
                        anchors.fill: parent
                        color: parent.color
                        opacity: chatMouseArea.containsMouse ? 0.7 : 0.5
                        radius: parent.radius

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.right: deleteBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 12
                        spacing: 4

                        Text {
                            text: modelData.title
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.bold: modelData.isCurrent
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: modelData.lastMessage
                            color: "#a0a0a0"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: formatTime(modelData.lastTimestamp)
                            color: "#6c5ce7"
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        id: deleteBtn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 8
                        width: 24
                        height: 24
                        radius: 12
                        color: "#e74c3c"
                        opacity: (chatMouseArea.containsMouse || deleteBtnMouseArea.containsMouse) ? 1.0 : 0.0
                        visible: !modelData.isCurrent || chatManager.chatList.length > 1
                        z: 10

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: "white"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            id: deleteBtnMouseArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            z: 11

                            onClicked: {
                                console.log("Delete button clicked for:", modelData.title)
                                chatListPanel.showDeleteDialog(modelData.id, modelData.title)
                                mouse.accepted = true
                            }

                            onPressed: mouse.accepted = true
                            onReleased: mouse.accepted = true
                        }
                    }

                    MouseArea {
                        id: chatMouseArea
                        anchors.fill: parent
                        anchors.rightMargin: 32
                        hoverEnabled: true
                        onClicked: {
                            if (!modelData.isCurrent) {
                                chatManager.switchToChat(modelData.id)
                            }
                        }
                    }
                }
            }

            // MouseArea для обработки колеса мыши в зоне между чатами и скроллбаром
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

    // Кастомный скроллбар на уровне всей панели
    // Кастомный скроллбар
        Item {
            id: customScrollBar
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 70
            anchors.bottom: parent.bottom
            anchors.rightMargin: 5
            anchors.bottomMargin: 5
            width: 8
            visible: chatListView.contentHeight > chatListView.height

            property real scrollBarHeight: chatListView.height
            property real contentHeight: chatListView.contentHeight
            property real thumbHeight: Math.max(20, scrollBarHeight * (scrollBarHeight / contentHeight))
            property real thumbY: chatListView.contentY * (scrollBarHeight - thumbHeight) / Math.max(1, contentHeight - scrollBarHeight)

            Rectangle {
                id: scrollTrack
                anchors.fill: parent
                color: "#16213e"
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
                color: thumbMouseArea.pressed ? "#4facfe" :
                       thumbMouseArea.containsMouse ? "#00f2fe" :
                       "#6c5ce7"
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
                            chatListView.contentY = Math.max(0, Math.min(newContentY, customScrollBar.contentHeight - customScrollBar.scrollBarHeight))
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var clickRatio = mouse.y / height
                    var targetContentY = clickRatio * (customScrollBar.contentHeight - customScrollBar.scrollBarHeight)
                    chatListView.contentY = Math.max(0, Math.min(targetContentY, customScrollBar.contentHeight - customScrollBar.scrollBarHeight))
                }

                onWheel: {
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

        property string chatIdToDelete: ""
        property string chatTitleToDelete: ""

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
                                console.log("Cancel clicked")
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
                                console.log("Confirm delete clicked")
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
        console.log("showDeleteDialog called:", chatId, chatTitle)
        deleteDialog.chatIdToDelete = chatId
        deleteDialog.chatTitleToDelete = chatTitle
        deleteDialog.visible = true
    }
}
