import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects

Rectangle {
    id: messageContainer
    property string messageText: ""
    property bool isUserMessage: false
    property color userColor: "#2d3748"
    property color aiColor: "#1a365d"
    property color primaryColor: "#4facfe"
    property color textColor: "#ffffff"

    width: parent.width
    height: messageBubble.height + 15
    color: "transparent"

    Rectangle {
        id: messageBubble
        anchors.right: isUserMessage ? parent.right : undefined
        anchors.left: isUserMessage ? undefined : parent.left
        anchors.rightMargin: isUserMessage ? 0 : parent.width * 0.15
        anchors.leftMargin: isUserMessage ? parent.width * 0.15 : 0

        width: Math.min(messageLabel.implicitWidth + 25, parent.width * 0.75)
        height: messageLabel.height + 20

        gradient: isUserMessage ? userGradient : aiGradient
        radius: 18
        opacity: 0.9

        // Add subtle shadow effect
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 2
            radius: 8
            samples: 16
            color: "#20000000"
        }

        Gradient {
            id: userGradient
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: messageContainer.userColor }
            GradientStop { position: 1.0; color: Qt.darker(messageContainer.userColor, 1.1) }
        }

        Gradient {
            id: aiGradient
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: messageContainer.aiColor }
            GradientStop { position: 1.0; color: messageContainer.primaryColor }
        }

        TextEdit {
            id: messageLabel
            anchors.centerIn: parent
            text: (isUserMessage ? "🟢 " : "🤖 ") + messageText
            color: messageContainer.textColor
            font.pixelSize: 14
            wrapMode: TextEdit.Wrap
            width: Math.min(contentWidth, parent.parent.width * 0.75 - 25)
            horizontalAlignment: isUserMessage ? TextEdit.AlignRight : TextEdit.AlignLeft

            readOnly: true
            selectByMouse: true
            selectionColor: Qt.rgba(0.3, 0.6, 1.0, 0.3)
            selectedTextColor: messageContainer.textColor

            // Обязательно добавить прозрачный background
            background: Rectangle {
                color: "transparent"
                border.width: 0
            }

            // Убрать отступы
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0
        }

        // Добавить контекстное меню после TextArea

        // Subtle animation on creation
        NumberAnimation on opacity {
            from: 0
            to: 0.9
            duration: 300
            easing.type: Easing.OutCubic
        }

        NumberAnimation on scale {
            from: 0.8
            to: 1.0
            duration: 300
            easing.type: Easing.OutBack
        }
    }

    // Tail for speech bubble effect
    Canvas {
        id: tail
        anchors.top: messageBubble.bottom
        anchors.topMargin: -5
        anchors.right: isUserMessage ? messageBubble.right : undefined
        anchors.left: isUserMessage ? undefined : messageBubble.left
        anchors.rightMargin: isUserMessage ? 20 : 0
        anchors.leftMargin: isUserMessage ? 0 : 20

        width: 15
        height: 10

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            ctx.fillStyle = isUserMessage ? messageContainer.userColor : messageContainer.aiColor
            ctx.beginPath()

            if (isUserMessage) {
                ctx.moveTo(0, 0)
                ctx.lineTo(15, 0)
                ctx.lineTo(10, 10)
            } else {
                ctx.moveTo(15, 0)
                ctx.lineTo(0, 0)
                ctx.lineTo(5, 10)
            }

            ctx.closePath()
            ctx.fill()
        }
    }
}
