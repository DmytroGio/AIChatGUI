import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    visible: true
    width: 500
    height: 700
    title: "AI Chat GUI"

    Column {
        anchors.fill: parent
        spacing: 10
        padding: 10

        ScrollView {
            id: scrollView
            width: parent.width
            height: parent.height * 0.8

            TextArea {
                id: chatArea
                readOnly: true
                wrapMode: Text.Wrap
                text: "🔷 Chat Started..."
                selectByMouse: true
            }
        }

        Row {
            spacing: 10
            width: parent.width

            TextField {
                id: inputField
                placeholderText: "Type your message..."
                width: parent.width - sendButton.width - parent.spacing

                Keys.onReturnPressed: {
                    sendButton.clicked()
                }
            }

            Button {
                id: sendButton
                text: "Send"
                onClicked: {
                    if (inputField.text.trim() !== "") {
                        chatArea.text += "\n\n🟢 You: " + inputField.text
                        lmstudio.sendMessage(inputField.text)
                        inputField.text = ""

                        // Прокрутка вниз
                        scrollView.ScrollBar.vertical.position = 1.0
                    }
                }
            }
        }

        Connections {
            target: lmstudio
            function onMessageReceived(response) {
                chatArea.text += "\n🔵 AI: " + response
                // Прокрутка вниз после получения ответа
                scrollView.ScrollBar.vertical.position = 1.0
            }
        }
    }
}
