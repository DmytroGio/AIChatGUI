import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs


Rectangle {
    id: modelPanel
    width: isOpen ? 700 : 0
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

            // ========== PINNED METRICS BAR (Quick Overview) ==========
            Rectangle {
                width: parent.width
                height: 70
                color: modelPanel.surfaceColor
                radius: 12
                border.color: modelInfo.isLoaded ? "#4ade80" : modelPanel.textSecondary
                border.width: 2
                opacity: 0.95

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Status Column
                    Column {
                        width: 80
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            spacing: 6
                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: modelInfo.isLoaded ? "#4ade80" : "#808080"
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on opacity {
                                    running: modelInfo.status === "Generating"
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 500 }
                                    NumberAnimation { to: 1.0; duration: 500 }
                                }
                            }

                            Text {
                                text: modelInfo.isLoaded ? "READY" : "IDLE"
                                color: modelPanel.textPrimary
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        Text {
                            text: modelInfo.status
                            color: modelPanel.textSecondary
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        width: 1
                        height: parent.height - 20
                        color: modelPanel.textSecondary
                        opacity: 0.3
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Speed Metric
                    Column {
                        width: 90
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "⚡ SPEED"
                            color: modelPanel.textSecondary
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            text: modelInfo.speed.toFixed(1) + " tok/s"
                            color: modelPanel.primaryColor
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: 1
                        height: parent.height - 20
                        color: modelPanel.textSecondary
                        opacity: 0.3
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Memory Metric
                    Column {
                        width: 110
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "💾 MEMORY"
                            color: modelPanel.textSecondary
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Row {
                            spacing: 4

                            Text {
                                text: modelInfo.memoryUsed.toFixed(1) + " GB"
                                color: modelPanel.textPrimary
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Text {
                                text: "(" + modelInfo.memoryPercent + "%)"
                                color: modelInfo.memoryPercent > 80 ? "#fbbf24" : modelPanel.textSecondary
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        height: parent.height - 20
                        color: modelPanel.textSecondary
                        opacity: 0.3
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Context Usage
                    Column {
                        width: parent.width - 350
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            spacing: 4

                            Text {
                                text: "📝 CONTEXT"
                                color: modelPanel.textSecondary
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Text {
                                text: (modelInfo.tokensIn + modelInfo.tokensOut) + " / " + modelInfo.contextSize
                                color: modelPanel.textPrimary
                                font.pixelSize: 10
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: "#0a0a15"

                            Rectangle {
                                width: parent.width * Math.min((modelInfo.tokensIn + modelInfo.tokensOut) / modelInfo.contextSize, 1.0)
                                height: parent.height
                                radius: parent.radius
                                color: {
                                    var usage = (modelInfo.tokensIn + modelInfo.tokensOut) / modelInfo.contextSize
                                    if (usage > 0.9) return "#ef4444"
                                    if (usage > 0.7) return "#fbbf24"
                                    return modelPanel.primaryColor
                                }

                                Behavior on width {
                                    NumberAnimation { duration: 300 }
                                }
                            }
                        }
                    }
                }
            }

            // ========== MODEL SELECTOR & INFO ==========
            Rectangle {
                width: parent.width
                height: modelDetailsColumn.height + 24
                color: modelPanel.surfaceColor
                radius: 12
                border.color: modelPanel.primaryColor
                border.width: 1
                opacity: 0.9

                Column {
                    id: modelDetailsColumn
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 12

                    // Model Name & Icon
                    Row {
                        width: parent.width
                        spacing: 12

                        Text {
                            text: "🔮"
                            font.pixelSize: 24
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 50
                            spacing: 4

                            Text {
                                text: modelInfo.isLoaded ? modelInfo.modelName : "No Model Loaded"
                                color: modelPanel.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelInfo.isLoaded ?
                                      modelInfo.modelSize + " • " + modelInfo.layers + " layers • " + modelInfo.contextSize + " ctx" :
                                      "Select a GGUF model to begin"
                                color: modelPanel.textSecondary
                                font.pixelSize: 12
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: modelPanel.textSecondary
                        opacity: 0.3
                    }

                    // Action Buttons
                    Row {
                        width: parent.width
                        spacing: 10

                        Button {
                            id: loadModelButton
                            text: modelInfo.isLoaded ? "Change Model" : "Load Model"
                            width: parent.width * 0.48
                            height: 38
                            enabled: true

                            onClicked: fileDialog.open()

                            background: Rectangle {
                                color: loadModelButton.pressed ? Qt.darker(modelPanel.primaryColor, 1.2) :
                                       loadModelButton.hovered ? Qt.lighter(modelPanel.primaryColor, 1.1) :
                                       modelPanel.primaryColor
                                radius: 8

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            contentItem: Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "📁"
                                    font.pixelSize: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: loadModelButton.text
                                    color: "white"
                                    font.pixelSize: 13
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Button {
                            id: unloadButton
                            text: "Unload"
                            width: parent.width * 0.24
                            height: 38
                            enabled: modelInfo.isLoaded

                            onClicked: {
                                llamaConnector.unloadModel()
                            }

                            background: Rectangle {
                                color: unloadButton.pressed ? "#c0392b" :
                                       unloadButton.hovered ? "#e74c3c" :
                                       "transparent"
                                radius: 8
                                border.color: "#e74c3c"
                                border.width: 1
                                opacity: unloadButton.enabled ? 1.0 : 0.4

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            contentItem: Text {
                                text: unloadButton.text
                                color: modelPanel.textPrimary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 13
                            }
                        }

                        Button {
                            id: settingsButton
                            text: "⚙️"
                            width: parent.width * 0.24
                            height: 38
                            enabled: modelInfo.isLoaded

                            onClicked: {
                                settingsPopup.open()
                            }

                            background: Rectangle {
                                color: settingsButton.pressed ? Qt.darker(modelPanel.accentColor, 1.2) :
                                       settingsButton.hovered ? Qt.lighter(modelPanel.accentColor, 1.1) :
                                       "transparent"
                                radius: 8
                                border.color: modelPanel.accentColor
                                border.width: 1
                                opacity: settingsButton.enabled ? 1.0 : 0.4

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            contentItem: Text {
                                text: settingsButton.text
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 18
                            }
                        }
                    }
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
                height: runtimeColumn.height + 30
                color: modelPanel.surfaceColor
                radius: 12
                opacity: 0.9
                border.color: modelPanel.primaryColor
                border.width: 1

                Column {
                    id: runtimeColumn
                    anchors.centerIn: parent
                    width: parent.width - 30
                    spacing: 16

                    // Header
                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "⚡ RUNTIME METRICS"
                            color: modelPanel.textPrimary
                            font.pixelSize: 16
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
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: modelPanel.textSecondary
                        opacity: 0.3
                    }

                    // GPU Section
                    Column {
                        width: parent.width
                        spacing: 12
                        visible: modelInfo.gpuName !== "N/A"

                        Row {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "🎮"
                                font.pixelSize: 16
                            }

                            Text {
                                text: "GPU: " + modelInfo.gpuName
                                color: modelPanel.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width - 30
                            }
                        }

                        // GPU Metrics Grid
                        Grid {
                            width: parent.width
                            columns: 2
                            columnSpacing: 15
                            rowSpacing: 12

                            // Temperature
                            Column {
                                width: (parent.width - 15) / 2
                                spacing: 6

                                Row {
                                    spacing: 6

                                    Text {
                                        text: "🌡️"
                                        font.pixelSize: 14
                                    }

                                    Text {
                                        text: "Temperature"
                                        color: modelPanel.textSecondary
                                        font.pixelSize: 12
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 35
                                    radius: 8
                                    color: "#0a0a15"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelInfo.gpuTemp + "°C"
                                        color: modelInfo.gpuTemp > 80 ? "#ef4444" :
                                               modelInfo.gpuTemp > 70 ? "#fbbf24" : "#4ade80"
                                        font.pixelSize: 18
                                        font.bold: true
                                    }
                                }
                            }

                            // Utilization
                            Column {
                                width: (parent.width - 15) / 2
                                spacing: 6

                                Row {
                                    spacing: 6

                                    Text {
                                        text: "⚙️"
                                        font.pixelSize: 14
                                    }

                                    Text {
                                        text: "Utilization"
                                        color: modelPanel.textSecondary
                                        font.pixelSize: 12
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 35
                                    radius: 8
                                    color: "#0a0a15"

                                    Rectangle {
                                        width: parent.width * (modelInfo.gpuUtil / 100.0)
                                        height: parent.height
                                        radius: parent.radius
                                        color: modelPanel.primaryColor
                                        opacity: 0.3

                                        Behavior on width {
                                            NumberAnimation { duration: 300 }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelInfo.gpuUtil + "%"
                                        color: modelPanel.textPrimary
                                        font.pixelSize: 18
                                        font.bold: true
                                    }
                                }
                            }

                            // GPU Memory
                            Column {
                                width: parent.width
                                spacing: 6

                                Row {
                                    spacing: 6

                                    Text {
                                        text: "💾"
                                        font.pixelSize: 14
                                    }

                                    Text {
                                        text: "GPU Memory: " + modelInfo.gpuMemUsed + " / " + modelInfo.gpuMemTotal + " MB"
                                        color: modelPanel.textSecondary
                                        font.pixelSize: 12
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 10
                                    radius: 5
                                    color: "#0a0a15"

                                    Rectangle {
                                        width: parent.width * (modelInfo.gpuMemUsed / Math.max(modelInfo.gpuMemTotal, 1))
                                        height: parent.height
                                        radius: parent.radius
                                        color: {
                                            var usage = modelInfo.gpuMemUsed / modelInfo.gpuMemTotal
                                            if (usage > 0.9) return "#ef4444"
                                            if (usage > 0.7) return "#fbbf24"
                                            return "#4ade80"
                                        }

                                        Behavior on width {
                                            NumberAnimation { duration: 300 }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: modelPanel.textSecondary
                            opacity: 0.2
                        }
                    }

                    // Speed with enhanced sparkline
                    Column {
                        width: parent.width
                        spacing: 8

                        Row {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: "⚡"
                                font.pixelSize: 16
                            }

                            Text {
                                text: "Generation Speed"
                                color: modelPanel.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Item { width: parent.width - 300 }

                            Text {
                                text: modelInfo.speed.toFixed(2) + " tok/s"
                                color: modelPanel.primaryColor
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 60
                            color: "#0a0a15"
                            radius: 8
                            border.color: modelPanel.primaryColor
                            border.width: 1
                            opacity: 0.8

                            Canvas {
                                id: speedCanvas
                                anchors.fill: parent
                                anchors.margins: 8

                                property var dataPoints: []

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    if (dataPoints.length < 2) return

                                    var maxY = Math.max(...dataPoints, 1)
                                    var stepX = width / (dataPoints.length - 1)

                                    // Gradient fill
                                    var gradient = ctx.createLinearGradient(0, 0, 0, height)
                                    gradient.addColorStop(0, modelPanel.primaryColor + "80")
                                    gradient.addColorStop(1, modelPanel.primaryColor + "10")

                                    ctx.fillStyle = gradient
                                    ctx.beginPath()
                                    ctx.moveTo(0, height)

                                    for (var i = 0; i < dataPoints.length; i++) {
                                        var x = i * stepX
                                        var y = height - (dataPoints[i] / maxY) * height
                                        ctx.lineTo(x, y)
                                    }

                                    ctx.lineTo(width, height)
                                    ctx.closePath()
                                    ctx.fill()

                                    // Line
                                    ctx.strokeStyle = modelPanel.primaryColor
                                    ctx.lineWidth = 2
                                    ctx.beginPath()

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
                                        if (speedCanvas.dataPoints.length > 60) {
                                            speedCanvas.dataPoints.shift()
                                        }
                                        speedCanvas.requestPaint()
                                    }
                                }
                            }
                        }
                    }

                    // System Memory & Threads
                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: 15
                        rowSpacing: 10

                        // RAM Usage
                        Column {
                            width: (parent.width - 15) / 2
                            spacing: 6

                            Row {
                                spacing: 4

                                Text {
                                    text: "🖥️ RAM"
                                    color: modelPanel.textSecondary
                                    font.pixelSize: 11
                                    font.bold: true
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
                                    color: modelInfo.memoryPercent > 80 ? "#fbbf24" : modelPanel.primaryColor

                                    Behavior on width {
                                        NumberAnimation { duration: 300 }
                                    }
                                }
                            }

                            Text {
                                text: modelInfo.memoryUsed.toFixed(1) + " / " +
                                      modelInfo.memoryTotal.toFixed(1) + " GB (" +
                                      modelInfo.memoryPercent + "%)"
                                color: modelPanel.textPrimary
                                font.pixelSize: 11
                            }
                        }

                        // Threads
                        Column {
                            width: (parent.width - 15) / 2
                            spacing: 6

                            Text {
                                text: "🔧 Threads: " + modelInfo.threads
                                color: modelPanel.textSecondary
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                text: "Context: " + modelInfo.contextSize
                                color: modelPanel.textPrimary
                                font.pixelSize: 11
                            }

                            Text {
                                text: "In: " + modelInfo.tokensIn + " • Out: " + modelInfo.tokensOut
                                color: modelPanel.textPrimary
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            // ========== RAW OUTPUT (COLLAPSIBLE) ==========
            Rectangle {
                width: parent.width
                height: rawOutputCollapsed ? 50 : 250
                color: modelPanel.surfaceColor
                radius: 12
                opacity: 0.8

                property bool rawOutputCollapsed: true

                Behavior on height {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // Header
                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "🔍 RAW OUTPUT"
                            color: modelPanel.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            width: parent.width - 80
                        }

                        Button {
                            text: parent.parent.parent.rawOutputCollapsed ? "▼" : "▲"
                            width: 30
                            height: 24

                            onClicked: parent.parent.parent.rawOutputCollapsed = !parent.parent.parent.rawOutputCollapsed

                            background: Rectangle {
                                color: parent.pressed ? Qt.darker(modelPanel.surfaceColor, 1.2) :
                                       parent.hovered ? Qt.lighter(modelPanel.surfaceColor, 1.2) :
                                       "transparent"
                                radius: 6
                                border.color: modelPanel.textSecondary
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

                        Button {
                            text: "📋"
                            width: 30
                            height: 24
                            visible: !parent.parent.parent.rawOutputCollapsed

                            onClicked: {
                                clipboardHelper.copyText(llamaConnector.getLastRawResponse())
                            }

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
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: modelPanel.textSecondary
                        opacity: 0.3
                        visible: !parent.parent.rawOutputCollapsed
                    }

                    // Raw text content
                    ScrollView {
                        width: parent.width
                        height: parent.parent.height - 70
                        visible: !parent.parent.rawOutputCollapsed
                        clip: true

                        TextArea {
                            id: rawOutputText
                            text: llamaConnector.getLastRawResponse()
                            color: modelPanel.textPrimary
                            font.pixelSize: 11
                            font.family: "Consolas, Monaco, monospace"
                            wrapMode: Text.Wrap
                            readOnly: true
                            selectByMouse: true

                            background: Rectangle {
                                color: "#0a0a15"
                                radius: 6
                            }

                            Connections {
                                target: llamaConnector
                                function onMessageReceived(response) {
                                    rawOutputText.text = response
                                }
                            }
                        }
                    }

                    Text {
                        text: "Last AI response (unprocessed)"
                        color: modelPanel.textSecondary
                        font.pixelSize: 10
                        visible: !parent.parent.rawOutputCollapsed
                        anchors.horizontalCenter: parent.horizontalCenter
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

                        model: modelInfo.requestLog

                        delegate: Rectangle {
                            width: parent ? parent.width : 0
                            height: 30
                            color: "transparent"

                            Row {
                                anchors.fill: parent
                                spacing: 8

                                Text {
                                    text: model.time
                                    color: modelPanel.textSecondary
                                    font.pixelSize: 11
                                    width: 60
                                }

                                Text {
                                    text: model.tokensIn + "→" + model.tokensOut
                                    color: modelPanel.textPrimary
                                    font.pixelSize: 11
                                    width: 60
                                }

                                Text {
                                    text: model.speed.toFixed(1) + "tk/s"
                                    color: modelPanel.primaryColor
                                    font.pixelSize: 11
                                    width: 70
                                }

                                Text {
                                    text: (model.duration / 1000).toFixed(1) + "s"
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
                            visible: parent.count === 0
                        }
                    }

                    Button {
                        text: "Clear Log"
                        width: parent.width
                        height: 28
                        enabled: modelInfo.requestLog.rowCount() > 0

                        onClicked: modelInfo.requestLog.clear()

                        background: Rectangle {
                            color: parent.pressed ? "#c0392b" :
                                   parent.hovered ? "#e74c3c" :
                                   "transparent"
                            radius: 8
                            border.color: "#e74c3c"
                            border.width: 1
                            opacity: parent.enabled ? 1.0 : 0.5

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

    // File Dialog для выбора модели
    FileDialog {
        id: fileDialog
        title: "Select Model File"
        nameFilters: ["GGUF Models (*.gguf)", "All Files (*)"]
        fileMode: FileDialog.OpenFile
        currentFolder: {
            if (modelInfo.isLoaded && modelInfo.modelPath !== "-") {
                var path = modelInfo.modelPath
                var lastSlash = Math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'))
                if (lastSlash > 0) {
                    return "file:///" + path.substring(0, lastSlash)
                }
            }
            return ""
        }

        onAccepted: {
            var path = fileDialog.selectedFile.toString()
            path = path.replace(/^(file:\/{3})/, "")
            if (Qt.platform.os === "windows") {
                path = path.replace(/^\//, "")
            }

            loadingPopup.open()
            llamaConnector.loadModel(path)
        }
    }

    // ========== MODEL SETTINGS POPUP (PLACEHOLDER) ==========
    Popup {
        id: settingsPopup
        anchors.centerIn: Overlay.overlay
        width: 450
        height: 550
        modal: true
        focus: true

        background: Rectangle {
            color: modelPanel.surfaceColor
            radius: 12
            border.color: modelPanel.accentColor
            border.width: 2
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Row {
                width: parent.width
                spacing: 12

                Text {
                    text: "⚙️"
                    font.pixelSize: 28
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Model Settings"
                    color: modelPanel.textPrimary
                    font.pixelSize: 20
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: modelPanel.textSecondary
                opacity: 0.3
            }

            // Placeholder content
            Column {
                width: parent.width
                spacing: 15

                Text {
                    text: "⚠️ Coming Soon"
                    color: modelPanel.primaryColor
                    font.pixelSize: 16
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Advanced model configuration options will be available here:"
                    color: modelPanel.textSecondary
                    font.pixelSize: 13
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Text { text: "• Temperature control"; color: modelPanel.textSecondary; font.pixelSize: 12 }
                    Text { text: "• Top-P / Top-K sampling"; color: modelPanel.textSecondary; font.pixelSize: 12 }
                    Text { text: "• Max tokens"; color: modelPanel.textSecondary; font.pixelSize: 12 }
                    Text { text: "• Context size adjustment"; color: modelPanel.textSecondary; font.pixelSize: 12 }
                    Text { text: "• GPU layers configuration"; color: modelPanel.textSecondary; font.pixelSize: 12 }
                    Text { text: "• Thread count"; color: modelPanel.textSecondary; font.pixelSize: 12 }
                }
            }

            Item { height: 20 }

            Button {
                text: "Close"
                width: 120
                height: 40
                anchors.horizontalCenter: parent.horizontalCenter

                onClicked: settingsPopup.close()

                background: Rectangle {
                    color: parent.pressed ? Qt.darker(modelPanel.accentColor, 1.2) :
                           parent.hovered ? Qt.lighter(modelPanel.accentColor, 1.1) :
                           modelPanel.accentColor
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }
    }

    // Loading Popup
    Popup {
        id: loadingPopup
        anchors.centerIn: Overlay.overlay
        width: 300
        height: 150
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose

        background: Rectangle {
            color: modelPanel.surfaceColor
            radius: 12
            border.color: modelPanel.primaryColor
            border.width: 2
        }

        Column {
            anchors.centerIn: parent
            spacing: 20

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: loadingPopup.visible

                contentItem: Item {
                    implicitWidth: 64
                    implicitHeight: 64

                    Item {
                        id: item
                        x: parent.width / 2 - 32
                        y: parent.height / 2 - 32
                        width: 64
                        height: 64
                        opacity: loadingPopup.visible ? 1 : 0

                        Behavior on opacity {
                            OpacityAnimator {
                                duration: 250
                            }
                        }

                        RotationAnimator {
                            target: item
                            running: loadingPopup.visible
                            from: 0
                            to: 360
                            loops: Animation.Infinite
                            duration: 1250
                        }

                        Repeater {
                            id: repeater
                            model: 6

                            Rectangle {
                                x: item.width / 2 - width / 2
                                y: item.height / 2 - height / 2
                                implicitWidth: 10
                                implicitHeight: 10
                                radius: 5
                                color: modelPanel.primaryColor
                                transform: [
                                    Translate {
                                        y: -Math.min(item.width, item.height) * 0.5 + 5
                                    },
                                    Rotation {
                                        angle: index / repeater.count * 360
                                        origin.x: 5
                                        origin.y: 5
                                    }
                                ]
                            }
                        }
                    }
                }
            }

            Text {
                text: "Loading model..."
                color: modelPanel.textPrimary
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Please wait"
                color: modelPanel.textSecondary
                font.pixelSize: 12
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Connections {
            target: llamaConnector

            function onModelLoadingFinished(success) {
                loadingPopup.close()
                if (!success) {
                    errorPopup.errorText = "Failed to load model"
                    errorPopup.open()
                }
            }

            function onErrorOccurred(error) {
                loadingPopup.close()
                errorPopup.errorText = error
                errorPopup.open()
            }
        }
    }

    // Error Popup
    Popup {
        id: errorPopup
        anchors.centerIn: Overlay.overlay
        width: 350
        height: 180
        modal: true
        focus: true

        property string errorText: ""

        background: Rectangle {
            color: modelPanel.surfaceColor
            radius: 12
            border.color: "#e74c3c"
            border.width: 2
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    text: "⚠️"
                    font.pixelSize: 32
                }

                Text {
                    text: "Error Loading Model"
                    color: modelPanel.textPrimary
                    font.pixelSize: 16
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: modelPanel.textSecondary
                opacity: 0.3
            }

            Text {
                text: errorPopup.errorText
                color: modelPanel.textSecondary
                font.pixelSize: 12
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: "OK"
                width: 100
                height: 35
                anchors.horizontalCenter: parent.horizontalCenter

                onClicked: errorPopup.close()

                background: Rectangle {
                    color: parent.pressed ? "#c0392b" :
                           parent.hovered ? "#e74c3c" :
                           "#e74c3c"
                    radius: 8

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 13
                    font.bold: true
                }
            }
        }
    }
}
