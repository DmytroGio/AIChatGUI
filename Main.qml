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

    // Gradient background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.backgroundColor }
            GradientStop { position: 1.0; color: "#16213e" }
        }
    }

    // Header
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: root.surfaceColor
            opacity: 0.8
            radius: 0
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
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
                    text: "AI Chat Assistant"
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
        anchors.left: parent.left
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

        ScrollView {
            id: scrollView
            anchors.fill: parent
            anchors.margins: 15
            clip: true

            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.Never

            Flickable {
                id: flickable
                contentHeight: chatContent.height
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: chatContent
                    width: scrollView.width
                    spacing: 15

                    // Welcome message
                    Rectangle {
                        width: parent.width
                        height: welcomeText.height + 30
                        color: "transparent"

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width * 0.8, 400)
                            height: parent.height
                            color: root.messageAiBg
                            opacity: 0.7
                            radius: 15

                            Text {
                                id: welcomeText
                                anchors.centerIn: parent
                                text: "🤖 Welcome to AI Chat Assistant!\nHow can I help you today?"
                                color: root.textPrimary
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                width: parent.width - 20
                            }
                        }
                    }
                }
            }
        }
    }

    // Input area
    Rectangle {
        id: inputArea
        anchors.bottom: parent.bottom
        anchors.left: parent.left
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
                background: Rectangle { color: "transparent" }
                selectByMouse: true

                Keys.onReturnPressed: {
                    sendButton.sendMessage()
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

            function sendMessage() {
                var messageText = inputField.text.trim()
                if (messageText !== "") {
                    addMessage(messageText, true)
                    lmstudio.sendMessage(messageText)
                    inputField.text = ""
                }
            }
        }
    }
    // Function to add messages
    function addMessage(text, isUser) {
        var messageComponent = Qt.createComponent("MessageBubble.qml")
        if (messageComponent.status === Component.Ready) {
            var messageObject = messageComponent.createObject(chatContent, {
                "messageText": text,
                "isUserMessage": isUser,
                "width": Qt.binding(function() { return chatContent.width })
            })
        } else {
            // Fallback if component doesn't exist
            addSimpleMessage(text, isUser)
        }
    }

    function addSimpleMessage(text, isUser) {
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
                        text: "${isUser ? '🟢 You: ' : '🤖 AI: '}${text}"
                        color: "${root.textPrimary}"
                        font.pixelSize: 14
                        wrapMode: Text.Wrap
                        width: parent.width - 20
                        horizontalAlignment: ${isUser ? 'Text.AlignRight' : 'Text.AlignLeft'}
                    }
                }
            }
        `, chatContent)
    }

    function scrollToBottom() {
        scrollTimer.restart()
    }

    Timer {
        id: scrollTimer
        interval: 100
        onTriggered: {
            scrollView.ScrollBar.vertical.position = 1.0
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
