import QtQuick 2.15

Rectangle {
    id: messageContainer
    property string messageText: ""
    property bool isUserMessage: false

    width: parent.width
    height: messageBubble.height + 30
    color: "transparent"

    Rectangle {
        id: messageBubble

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        // ✅ ФИКСИРОВАННАЯ ширина — не меняется при resize
        width: 750

        height: messageContent.height + 30
        color: isUserMessage ? "#2d3748" : "#1a365d"
        radius: 18
        opacity: 0.9

        Text {
            id: messageContent
            anchors.centerIn: parent
            width: parent.width - 40

            text: {
                var formatted = messageText

                // ✅ Заголовки
                formatted = formatted.replace(/^### (.*?)$/gm,
                    '<span style="font-size: 16px; font-weight: bold; color: #60a5fa;">$1</span>')
                formatted = formatted.replace(/^## (.*?)$/gm,
                    '<span style="font-size: 18px; font-weight: bold; color: #3b82f6;">$1</span>')
                formatted = formatted.replace(/^# (.*?)$/gm,
                    '<span style="font-size: 20px; font-weight: bold; color: #2563eb;">$1</span>')

                // ✅ Inline code
                formatted = formatted.replace(/`([^`\n]+)`/g,
                    '<span style="background-color: #2d3748; color: #ffd700; padding: 2px 6px; border-radius: 4px; font-family: Consolas, Monaco, monospace; font-size: 13px;">$1</span>')

                // ✅ Bold/Italic
                formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>')
                formatted = formatted.replace(/\*(.*?)\*/g, '<i>$1</i>')

                // ✅ Переносы
                formatted = formatted.replace(/\n/g, '<br>')

                return formatted
            }

            color: "#ffffff"
            font.pixelSize: 14
            font.family: "Segoe UI"
            wrapMode: Text.Wrap
            textFormat: Text.RichText
            horizontalAlignment: Text.AlignLeft
        }
    }
}
