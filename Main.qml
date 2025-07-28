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

        TextArea {
            id: chatArea
            readOnly: true
            wrapMode: Text.Wrap
            height: parent.height * 0.8
            text: "🔷 Chat Started..."
        }

        Row {
            spacing: 10
            TextField {
                id: inputField
                placeholderText: "Type your message..."
                width: parent.width * 0.8
            }

            Button {
                text: "Send"
                onClicked: {
                    chatArea.text += "\n\n🟢 You: " + inputField.text
                    inputField.text = ""
                    // later: send to C++
                }
            }
        }
    }
}
