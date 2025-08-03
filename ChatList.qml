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

        // Chat list
        ScrollView {
            width: parent.width
            height: parent.height - 60
            clip: true

            ListView {
                id: chatListView
                anchors.fill: parent
                model: chatManager.chatList
                spacing: 5

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
                        opacity: chatMouseArea.containsMouse ? 1.0 : 0.0
                        visible: !modelData.isCurrent || chatManager.chatList.length > 1

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
                            anchors.fill: parent
                            onClicked: {
                                chatManager.deleteChat(modelData.id)
                                mouse.accepted = true
                            }
                        }
                    }

                    MouseArea {
                        id: chatMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (!modelData.isCurrent) {
                                chatManager.switchToChat(modelData.id)
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
}
