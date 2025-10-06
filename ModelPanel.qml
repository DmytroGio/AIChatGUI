import QtQuick 2.15
import QtQuick.Controls 2.15


Rectangle {
    id: modelPanel
    width: isOpen ? 400 : 0
    height: parent.height
    color: backgroundColor
    clip: true

    property bool isOpen: false
    property color backgroundColor: "#1a1b2e"
    property color surfaceColor: "#16213e"
    property color primaryColor: "#4facfe"
    property color textPrimary: "#ffffff"
    property color textSecondary: "#a0a0a0"
    property color accentColor: "#6c5ce7"

    Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // Background gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: modelPanel.backgroundColor }
            GradientStop { position: 1.0; color: "#0f0f23" }
        }
        opacity: 0.95
    }

    // Main content
    Flickable {
        id: panelFlickable
        anchors.fill: parent
        anchors.margins: 15
        contentHeight: panelContent.height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: panelContent
            width: parent.width
            spacing: 20

            // ========== MODEL SELECTOR ==========
            Rectangle {
                width: parent.width
                height: selectorColumn.height + 20
                color: modelPanel.surfaceColor
                radius: 12
                border.color: modelPanel.primaryColor
                border.width: 1
                opacity: 0.9

                Column {
                    id: selectorColumn
                    anchors.centerIn: parent
                    width: parent.width - 20
                    spacing: 10

                    Row {
                        width: parent.width
                        spacing: 10

                        Text {
                            text: "🎯"
                            font.pixelSize: 24
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40

                            Text {
                                text: modelInfo.isLoaded ? modelInfo.modelName : "No Model Loaded"
                                color: modelPanel.textPrimary
                                font.pixelSize: 16
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelInfo.modelSize + " • " + modelInfo.layers + " • " + modelInfo.contextSize + " ctx"
                                color: modelPanel.textSecondary
                                font.pixelSize: 12
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 10

                        Button {
                            text: "Change Model"
                            width: parent.width * 0.65
                            height: 32
                            enabled: false
                            opacity: 0.5

                            background: Rectangle {
                                color: modelPanel.primaryColor
                                radius: 8
                            }

                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 13
                            }
                        }

                        Button {
                            text: "⚙️"
                            width: parent.width * 0.3
                            height: 32
                            enabled: false
                            opacity: 0.5

                            background: Rectangle {
                                color: modelPanel.surfaceColor
                                radius: 8
                                border.color: modelPanel.textSecondary
                                border.width: 1
                            }

                            contentItem: Text {
                                text: parent.text
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 16
                            }
                        }
                    }
                }
            }
            // ========== MODEL INFO ==========
            Grid {
                width: parent.width
                columns: 2
                rowSpacing: 8
                columnSpacing: 10

                // Left column
                Column {
                    width: parent.width / 2 - 5
                    spacing: 8

                    InfoRow { label: "Type:"; value: modelInfo.modelType }
                    InfoRow { label: "Layers:"; value: modelInfo.layers.toString() }
                    InfoRow { label: "Quant:"; value: modelInfo.quantization }
                }

                // Right column
                Column {
                    width: parent.width / 2 - 5
                    spacing: 8

                    InfoRow { label: "Params:"; value: modelInfo.parameters }
                    InfoRow { label: "Embed:"; value: modelInfo.embedding }
                    InfoRow { label: "Vocab:"; value: modelInfo.vocabSize }
                }
            }

            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Path:"
                    color: modelPanel.textSecondary
                    font.pixelSize: 11
                }

                Text {
                    text: modelInfo.modelPath
                    color: modelPanel.textPrimary
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                    width: parent.width
                }
            }

            Text {
                text: "Loaded: " + modelInfo.loadedTime
                color: modelPanel.textSecondary
                font.pixelSize: 11
            }

            // ========== RUNTIME STATS ==========
            Rectangle {
                width: parent.width
                height: runtimeColumn.height + 20
                color: modelPanel.surfaceColor
                radius: 12
                opacity: 0.8

                Column {
                    id: runtimeColumn
                    anchors.centerIn: parent
                    width: parent.width - 20
                    spacing: 12

                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "⚡ RUNTIME"
                            color: modelPanel.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: modelInfo.status === "Generating" ? "#4ade80" : "#808080"
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on opacity {
                                running: modelInfo.status === "Generating"
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 500 }
                                NumberAnimation { to: 1.0; duration: 500 }
                            }
                        }

                        Text {
                            text: modelInfo.status
                            color: modelPanel.textSecondary
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: modelPanel.textSecondary
                        opacity: 0.3
                    }

                    // Speed with sparkline
                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "Speed: " + modelInfo.speed.toFixed(1) + " tok/s"
                            color: modelPanel.textPrimary
                            font.pixelSize: 13
                        }

                        Rectangle {
                            width: parent.width
                            height: 50
                            color: "#0a0a15"
                            radius: 6

                            Canvas {
                                id: speedCanvas
                                anchors.fill: parent
                                anchors.margins: 5

                                property var dataPoints: []

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    if (dataPoints.length < 2) return

                                    ctx.strokeStyle = modelPanel.primaryColor
                                    ctx.lineWidth = 2
                                    ctx.beginPath()

                                    var maxY = Math.max(...dataPoints, 1)
                                    var stepX = width / (dataPoints.length - 1)

                                    for (var i = 0; i < dataPoints.length; i++) {
                                        var x = i * stepX
                                        var y = height - (dataPoints[i] / maxY) * height

                                        if (i === 0) ctx.moveTo(x, y)
                                        else ctx.lineTo(x, y)
                                    }

                                    ctx.stroke()
                                }

                                Connections {
                                    target: modelInfo
                                    function onSpeedDataPoint(speed) {
                                        speedCanvas.dataPoints.push(speed)
                                        if (speedCanvas.dataPoints.length > 50) {
                                            speedCanvas.dataPoints.shift()
                                        }
                                        speedCanvas.requestPaint()
                                    }
                                }
                            }
                        }
                    }

                    // Memory
                    Column {
                        width: parent.width
                        spacing: 6

                        Row {
                            width: parent.width

                            Text {
                                text: "Memory: " + modelInfo.memoryUsed.toFixed(1) + "/" +
                                      modelInfo.memoryTotal.toFixed(1) + " GB (" +
                                      modelInfo.memoryPercent + "%)"
                                color: modelPanel.textPrimary
                                font.pixelSize: 13
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 8
                            radius: 4
                            color: "#0a0a15"

                            Rectangle {
                                width: parent.width * (modelInfo.memoryPercent / 100.0)
                                height: parent.height
                                radius: parent.radius
                                color: modelPanel.primaryColor

                                Behavior on width {
                                    NumberAnimation { duration: 300 }
                                }
                            }
                        }
                    }

                    // Other stats
                    Grid {
                        width: parent.width
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 10

                        Text {
                            text: "Threads: " + modelInfo.threads
                            color: modelPanel.textSecondary
                            font.pixelSize: 12
                        }

                        Text {
                            text: "Load: " + (modelInfo.isLoaded ? "OK" : "None")
                            color: modelPanel.textSecondary
                            font.pixelSize: 12
                        }

                        Text {
                            text: "Avg Speed: " + modelInfo.speed.toFixed(1) + " tok/s"
                            color: modelPanel.textSecondary
                            font.pixelSize: 12
                        }

                        Text {
                            text: "Ctx: " + modelInfo.contextSize
                            color: modelPanel.textSecondary
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        text: "Total: " + modelInfo.tokensIn + " tok in • " +
                              modelInfo.tokensOut + " tok out"
                        color: modelPanel.textSecondary
                        font.pixelSize: 11
                    }
                }
            }

            // ========== REQUEST LOG ==========
            Rectangle {
                width: parent.width
                height: 300
                color: modelPanel.surfaceColor
                radius: 12
                opacity: 0.8

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Row {
                        width: parent.width

                        Text {
                            text: "📊 REQUEST LOG"
                            color: modelPanel.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            width: parent.width - 60
                        }

                        Button {
                            text: "CSV⬇"
                            width: 50
                            height: 24

                            background: Rectangle {
                                color: parent.pressed ? modelPanel.accentColor :
                                       parent.hovered ? Qt.lighter(modelPanel.accentColor, 1.2) :
                                       "transparent"
                                radius: 6
                                border.color: modelPanel.accentColor
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            contentItem: Text {
                                text: parent.text
                                color: modelPanel.textPrimary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 10
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: modelPanel.textSecondary
                        opacity: 0.3
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - 80
                        clip: true

                        model: ListModel {
                            id: logModel
                            // Placeholder
                        }

                        delegate: Rectangle {
                            width: parent.width
                            height: 30
                            color: "transparent"

                            Row {
                                anchors.fill: parent
                                spacing: 8

                                Text {
                                    text: "14:23"
                                    color: modelPanel.textSecondary
                                    font.pixelSize: 11
                                    width: 40
                                }

                                Text {
                                    text: "12→54"
                                    color: modelPanel.textPrimary
                                    font.pixelSize: 11
                                    width: 50
                                }

                                Text {
                                    text: "42tk/s"
                                    color: modelPanel.primaryColor
                                    font.pixelSize: 11
                                    width: 60
                                }

                                Text {
                                    text: "1.2s"
                                    color: modelPanel.textSecondary
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "No requests yet"
                            color: modelPanel.textSecondary
                            font.pixelSize: 12
                            opacity: 0.6
                            visible: logModel.count === 0
                        }
                    }

                    Button {
                        text: "Clear Log"
                        width: parent.width
                        height: 28

                        background: Rectangle {
                            color: parent.pressed ? "#c0392b" :
                                   parent.hovered ? "#e74c3c" :
                                   "transparent"
                            radius: 8
                            border.color: "#e74c3c"
                            border.width: 1

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: modelPanel.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    // Helper component for info rows
    component InfoRow: Row {
        property string label: ""
        property string value: ""
        spacing: 4

        Text {
            text: label
            color: modelPanel.textSecondary
            font.pixelSize: 11
            width: 55
        }

        Text {
            text: value
            color: modelPanel.textPrimary
            font.pixelSize: 11
            font.bold: true
        }
    }
}
