import QtQuick 2.15

Rectangle {
    id: messageContainer
    property string messageText: ""
    property bool isUserMessage: false

    width: parent.width
    height: messageContent.height + 30
    color: "transparent"

    Rectangle {
        id: messageBubble
        anchors.right: isUserMessage ? parent.right : undefined
        anchors.left: isUserMessage ? undefined : parent.left
        anchors.rightMargin: isUserMessage ? 0 : parent.width * 0.15
        anchors.leftMargin: isUserMessage ? parent.width * 0.15 : 0

        width: Math.min(messageContent.implicitWidth + 40, parent.width * 0.85)
        height: messageContent.height + 25

        color: isUserMessage ? "#2d3748" : "#1a365d"
        radius: 18
        opacity: 0.9

        Text {
            id: messageContent
            anchors.centerIn: parent
            width: parent.width - 30

            text: messageText
            color: "#ffffff"
            font.pixelSize: 14
            font.family: "Segoe UI"
            wrapMode: Text.Wrap
        }
    }
}
