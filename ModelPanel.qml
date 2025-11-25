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
            spacing: 15

            // ========== STATUS HEADER ==========
            Rectangle {
                width: parent.width
                height: 80
                color: modelPanel.surfaceColor
                radius: 12
                border.color: modelInfo.isLoaded ? "#4ade80" : modelPanel.textSecondary
                border.width: 2

                Row {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    // Status indicator
                    Column {
                        width: 70
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: modelInfo.isLoaded ? "#4ade80" : "#808080"
                            anchors.horizontalCenter: parent.horizontalCenter

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
                            font.pixelSize: 11
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Rectangle {
                        width: 1
                        height: parent.height - 30
                        color: modelPanel.textSecondary
                        opacity: 0.2
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Key metrics
                    Row {
                        spacing: 20
                        anchors.verticalCenter: parent.verticalCenter

                        MetricItem {
                            icon: "⚡"
                            label: "SPEED"
                            value: modelInfo.speed.toFixed(1)
                            unit: "tok/s"
                        }

                        MetricItem {
                            icon: "💾"
                            label: "MEMORY"
                            value: modelInfo.memoryUsed.toFixed(1)
                            unit: "GB"
                            warning: modelInfo.memoryPercent > 80
                        }

                        MetricItem {
                            icon: "📝"
                            label: "CONTEXT"
                            value: ((modelInfo.tokensIn + modelInfo.tokensOut) / modelInfo.contextSize * 100).toFixed(0)
                            unit: "%"
                            warning: (modelInfo.tokensIn + modelInfo.tokensOut) / modelInfo.contextSize > 0.9
                        }
                    }
                }
            }

            // ========== MODEL INFO ==========
            Rectangle {
                width: parent.width
                height: modelInfoColumn.height + 24
                color: modelPanel.surfaceColor
                radius: 12
                border.color: modelPanel.primaryColor
                border.width: 1

                Column {
                    id: modelInfoColumn
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 12

                    // Current model
                    Row {
                        width: parent.width
                        spacing: 12
                        visible: modelInfo.isLoaded

                        Text {
                            text: "🔮"
                            font.pixelSize: 24
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 50
                            spacing: 4

                            Text {
                                text: modelInfo.modelName
                                color: modelPanel.textPrimary
                                font.pixelSize: 18
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelInfo.modelSize + " • " + modelInfo.layers + " layers • " + modelInfo.contextSize + " ctx"
                                color: modelPanel.textSecondary
                                font.pixelSize: 12
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: modelPanel.textSecondary
                        opacity: 0.2
                        visible: modelInfo.isLoaded
                    }

                    // Action buttons
                    Row {
                        width: parent.width
                        spacing: 8

                        ActionButton {
                            text: modelInfo.modelsFolder ? "📁 Change" : "📁 Choose"
                            width: parent.width * 0.35
                            isPrimary: true
                            onClicked: folderDialog.open()
                        }

                        ActionButton {
                            text: "🔄"
                            width: parent.width * 0.12
                            enabled: modelInfo.modelsFolder !== ""
                            onClicked: modelInfo.scanModelsFolder()
                            tooltipText: "Rescan folder"
                        }

                        ActionButton {
                            text: "⚙️"
                            width: parent.width * 0.12
                            enabled: modelInfo.isLoaded
                            onClicked: settingsPopup.open()
                        }

                        ActionButton {
                            text: "Unload"
                            width: parent.width * 0.35
                            enabled: modelInfo.isLoaded
                            isDanger: true
                            onClicked: llamaConnector.unloadModel()
                        }
                    }

                    // Folder path
                    Text {
                        width: parent.width
                        text: "📂 " + modelInfo.modelsFolder
                        color: modelPanel.textSecondary
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                        visible: modelInfo.modelsFolder !== ""
                    }

                    // Models list (collapsible)
                    Rectangle {
                        width: parent.width
                        height: modelsListCollapsed ? 40 : Math.min(modelsListView.contentHeight + 50, 400)
                        color: "#0a0a15"
                        radius: 8
                        visible: modelInfo.modelsFolder !== ""

                        property bool modelsListCollapsed: false

                        Behavior on height {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            // Header
                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "📋 Available Models (" + modelInfo.availableModels.length + ")"
                                    color: modelPanel.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    width: parent.width - 40
                                }

                                Button {
                                    text: parent.parent.parent.modelsListCollapsed ? "▼" : "▲"
                                    width: 30
                                    height: 24

                                    onClicked: parent.parent.parent.modelsListCollapsed = !parent.parent.parent.modelsListCollapsed

                                    background: Rectangle {
                                        color: parent.pressed ? Qt.darker(modelPanel.surfaceColor, 1.2) :
                                               parent.hovered ? Qt.lighter(modelPanel.surfaceColor, 1.2) :
                                               "transparent"
                                        radius: 6
                                        border.color: modelPanel.textSecondary
                                        border.width: 1
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

                            // Models ListView
                            ListView {
                                id: modelsListView
                                width: parent.width
                                height: parent.height - 40
                                clip: true
                                visible: !parent.parent.modelsListCollapsed

                                model: modelInfo.availableModels

                                delegate: Rectangle {
                                    width: modelsListView.width
                                    height: 70
                                    color: modelArea.containsMouse ? Qt.lighter(modelPanel.surfaceColor, 1.1) : "transparent"
                                    radius: 6

                                    MouseArea {
                                        id: modelArea
                                        anchors.fill: parent
                                        hoverEnabled: true

                                        onClicked: {
                                            if (modelData.fullPath !== modelInfo.modelPath) {
                                                loadingPopup.open()
                                                llamaConnector.loadModel(modelData.fullPath)
                                            }
                                        }
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 12

                                        // Auto-load checkbox
                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 4
                                            color: "transparent"
                                            border.color: modelData.isAutoLoad ? "#4ade80" : modelPanel.textSecondary
                                            border.width: 2
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.isAutoLoad ? "✓" : ""
                                                color: "#4ade80"
                                                font.pixelSize: 16
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if (modelData.isAutoLoad) {
                                                        modelInfo.autoLoadModelPath = ""
                                                    } else {
                                                        modelInfo.autoLoadModelPath = modelData.fullPath
                                                    }
                                                    modelInfo.scanModelsFolder()
                                                }
                                            }
                                        }

                                        Column {
                                            width: parent.width - 40
                                            spacing: 4
                                            anchors.verticalCenter: parent.verticalCenter

                                            Row {
                                                width: parent.width
                                                spacing: 8

                                                Text {
                                                    text: modelData.fileName
                                                    color: modelData.fullPath === modelInfo.modelPath ? modelPanel.primaryColor : modelPanel.textPrimary
                                                    font.pixelSize: 13
                                                    font.bold: modelData.fullPath === modelInfo.modelPath
                                                    elide: Text.ElideRight
                                                    width: parent.width - 120
                                                }

                                                Rectangle {
                                                    width: 55
                                                    height: 20
                                                    radius: 4
                                                    color: modelPanel.accentColor
                                                    opacity: 0.3
                                                    visible: modelData.fullPath === modelInfo.modelPath

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "LOADED"
                                                        color: modelPanel.textPrimary
                                                        font.pixelSize: 9
                                                        font.bold: true
                                                    }
                                                }
                                            }

                                            Row {
                                                spacing: 12

                                                Text {
                                                    text: "📦 " + modelData.size
                                                    color: modelPanel.textSecondary
                                                    font.pixelSize: 11
                                                }

                                                Text {
                                                    text: "🔢 " + modelData.parameters
                                                    color: modelPanel.textSecondary
                                                    font.pixelSize: 11
                                                }

                                                Text {
                                                    text: modelData.isAutoLoad ? "⚡ Auto-load" : ""
                                                    color: "#4ade80"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width - 16
                                        height: 1
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: modelPanel.textSecondary
                                        opacity: 0.2
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "No models found\nClick 'Choose Folder' to select models directory"
                                    color: modelPanel.textSecondary
                                    font.pixelSize: 12
                                    opacity: 0.6
                                    visible: modelsListView.count === 0
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }

            // ========== HARDWARE METRICS ==========
            Rectangle {
                width: parent.width
                height: hardwareColumn.height + 24
                color: modelPanel.surfaceColor
                radius: 12
                border.color: modelPanel.primaryColor
                border.width: 1

                Column {
                    id: hardwareColumn
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 15

                    Text {
                        text: "⚡ HARDWARE"
                        color: modelPanel.textPrimary
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Row {
                        width: parent.width
                        spacing: 15

                        // GPU
                        HardwareCard {
                            width: (parent.width - 15) / 2
                            icon: "🎮"
                            name: modelInfo.gpuName
                            visible: modelInfo.gpuName !== "N/A"

                            metrics: [
                                { label: "Temp", value: modelInfo.gpuTemp + "°C", color: modelInfo.gpuTemp > 80 ? "#ef4444" : "#4ade80" },
                                { label: "Usage", value: modelInfo.gpuUtil + "%", progress: modelInfo.gpuUtil / 100.0 },
                                { label: "Memory", value: modelInfo.gpuMemUsed + "/" + modelInfo.gpuMemTotal + " MB", progress: modelInfo.gpuMemUsed / Math.max(modelInfo.gpuMemTotal, 1) }
                            ]
                        }

                        // CPU
                        HardwareCard {
                            width: (parent.width - 15) / 2
                            icon: "🖥️"
                            name: modelInfo.cpuName
                            visible: modelInfo.cpuName !== "N/A"

                            metrics: [
                                { label: "Usage", value: modelInfo.cpuUsage + "%", progress: modelInfo.cpuUsage / 100.0 },
                                { label: "Clock", value: (modelInfo.cpuClock / 1000.0).toFixed(2) + " GHz", color: "#4ade80" },
                                {
                                    label: modelInfo.isLoaded ? "RAM (Model: " + modelInfo.modelMemoryUsed.toFixed(1) + " GB)" : "RAM",
                                    value: modelInfo.memoryUsed.toFixed(1) + "/" + modelInfo.memoryTotal.toFixed(1) + " GB",
                                    progress: modelInfo.memoryPercent / 100.0
                                }
                            ]
                        }
                    }

                    // Speed chart
                    Column {
                        width: parent.width
                        spacing: 8

                        Row {
                            spacing: 8

                            Text {
                                text: "⚡ Speed"
                                color: modelPanel.textPrimary
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Item { width: parent.parent.width - 180 }

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

                                    // Gradient
                                    var gradient = ctx.createLinearGradient(0, 0, 0, height)
                                    gradient.addColorStop(0, modelPanel.primaryColor + "60")
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
                            text: "📄 RAW OUTPUT"
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

                    // Raw text content с кастомным скроллбаром
                    Item {
                        width: parent.width
                        height: parent.parent.height - 95  // Увеличено с 85 до 95
                        visible: !parent.parent.rawOutputCollapsed
                        clip: true

                        // Фон
                        Rectangle {
                            anchors.fill: parent
                            color: "#0a0a15"
                            radius: 6
                        }

                        Flickable {
                            id: rawOutputFlickable
                            anchors.fill: parent
                            anchors.rightMargin: 10
                            anchors.bottomMargin: 5
                            contentHeight: rawOutputText.contentHeight + 15
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            TextEdit {
                                id: rawOutputText
                                width: parent.width - 10
                                text: llamaConnector.getLastRawResponse()
                                color: modelPanel.textPrimary
                                font.pixelSize: 11
                                font.family: "Consolas, Monaco, monospace"
                                wrapMode: Text.Wrap
                                readOnly: true
                                selectByMouse: true
                                leftPadding: 10
                                rightPadding: 10
                                topPadding: 8
                                bottomPadding: 10

                                Connections {
                                    target: llamaConnector
                                    function onMessageReceived(response) {
                                        rawOutputText.text = response
                                    }
                                }
                            }
                        }

                        // Кастомный скроллбар
                        Rectangle {
                            id: rawScrollbar
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: 2
                            anchors.topMargin: 5
                            anchors.bottomMargin: 5
                            width: 6
                            visible: rawOutputFlickable.contentHeight > rawOutputFlickable.height
                            color: "transparent"

                            Rectangle {
                                id: rawScrollThumb
                                width: parent.width
                                height: Math.max(20, parent.height * (rawOutputFlickable.height / rawOutputFlickable.contentHeight))
                                y: rawOutputFlickable.contentY * (parent.height - height) / Math.max(1, rawOutputFlickable.contentHeight - rawOutputFlickable.height)
                                radius: 3
                                color: rawScrollThumbArea.pressed ? modelPanel.primaryColor :
                                       rawScrollThumbArea.containsMouse ? modelPanel.accentColor : "#30363d"
                                opacity: 0.8

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }

                                MouseArea {
                                    id: rawScrollThumbArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    drag.target: rawScrollThumb
                                    drag.axis: Drag.YAxis
                                    drag.minimumY: 0
                                    drag.maximumY: rawScrollbar.height - rawScrollThumb.height

                                    onPositionChanged: {
                                        if (drag.active) {
                                            var ratio = rawScrollThumb.y / (rawScrollbar.height - rawScrollThumb.height)
                                            rawOutputFlickable.contentY = ratio * (rawOutputFlickable.contentHeight - rawOutputFlickable.height)
                                        }
                                    }
                                }
                            }
                        }

                        // Mouse wheel handling
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            onWheel: function(wheel) {
                                var delta = wheel.angleDelta.y
                                var scrollAmount = delta > 0 ? -40 : 40
                                var newContentY = rawOutputFlickable.contentY + scrollAmount
                                newContentY = Math.max(0, Math.min(newContentY, rawOutputFlickable.contentHeight - rawOutputFlickable.height))
                                rawOutputFlickable.contentY = newContentY
                            }
                        }
                    }

                    Text {
                        text: "Last AI response (unprocessed)"
                        color: modelPanel.textSecondary
                        font.pixelSize: 10
                        visible: !parent.parent.rawOutputCollapsed
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 8  // Увеличено с 5 до 8
                    }
                }
            }
        }
    }

    // ========== REUSABLE COMPONENTS ==========

    component MetricItem: Column {
        property string icon: ""
        property string label: ""
        property string value: ""
        property string unit: ""
        property bool warning: false

        width: 80
        spacing: 4

        Text {
            text: icon + " " + label
            color: modelPanel.textSecondary
            font.pixelSize: 9
            font.bold: true
        }

        Row {
            spacing: 4

            Text {
                text: value
                color: warning ? "#fbbf24" : modelPanel.primaryColor
                font.pixelSize: 16
                font.bold: true
            }

            Text {
                text: unit
                color: modelPanel.textSecondary
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    component ActionButton: Button {
        property bool isPrimary: false
        property bool isDanger: false
        property string tooltipText: ""

        height: 38

        ToolTip.visible: tooltipText !== "" && hovered
        ToolTip.text: tooltipText

        background: Rectangle {
            color: {
                if (parent.pressed) {
                    return isDanger ? "#c0392b" : Qt.darker(isPrimary ? modelPanel.primaryColor : modelPanel.accentColor, 1.2)
                }
                if (parent.hovered) {
                    return isDanger ? "#e74c3c" : Qt.lighter(isPrimary ? modelPanel.primaryColor : modelPanel.accentColor, 1.1)
                }
                if (isPrimary) return modelPanel.primaryColor
                if (isDanger) return "transparent"
                return "transparent"
            }
            radius: 8
            border.color: isDanger ? "#e74c3c" : (isPrimary ? "transparent" : modelPanel.accentColor)
            border.width: isPrimary ? 0 : 1
            opacity: parent.enabled ? 1.0 : 0.4
        }

        contentItem: Text {
            text: parent.text
            color: isPrimary ? "white" : modelPanel.textPrimary
            font.pixelSize: 13
            font.bold: isPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    component CollapsibleSection: Rectangle {
        property string title: ""
        property real contentHeight: 200
        property bool collapsed: true
        property alias content: contentLoader.sourceComponent

        height: collapsed ? 50 : contentHeight + 60
        color: modelPanel.surfaceColor
        radius: 12

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: title
                    color: modelPanel.textPrimary
                    font.pixelSize: 13
                    font.bold: true
                    width: parent.width - 40
                }

                Button {
                    text: parent.parent.parent.collapsed ? "▼" : "▲"
                    width: 30
                    height: 24
                    onClicked: parent.parent.parent.collapsed = !parent.parent.parent.collapsed

                    background: Rectangle {
                        color: parent.hovered ? Qt.lighter(modelPanel.surfaceColor, 1.2) : "transparent"
                        radius: 6
                        border.color: modelPanel.textSecondary
                        border.width: 1
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

            Loader {
                id: contentLoader
                width: parent.width
                height: parent.parent.contentHeight
                visible: !parent.parent.collapsed
            }

            children: [contentLoader]
        }
    }

    component ModelItem: Rectangle {
        property var modelData

        height: 60
        color: modelArea.containsMouse ? Qt.lighter(modelPanel.surfaceColor, 1.1) : "transparent"
        radius: 6

        MouseArea {
            //id: modelArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (modelData.fullPath !== modelInfo.modelPath) {
                    loadingPopup.open()
                    llamaConnector.loadModel(modelData.fullPath)
                }
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            Rectangle {
                width: 20
                height: 20
                radius: 4
                color: "transparent"
                border.color: modelData.isAutoLoad ? "#4ade80" : modelPanel.textSecondary
                border.width: 2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: modelData.isAutoLoad ? "✓" : ""
                    color: "#4ade80"
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        modelInfo.autoLoadModelPath = modelData.isAutoLoad ? "" : modelData.fullPath
                        modelInfo.scanModelsFolder()
                    }
                }
            }

            Column {
                width: parent.width - 35
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: modelData.fileName
                    color: modelData.fullPath === modelInfo.modelPath ? modelPanel.primaryColor : modelPanel.textPrimary
                    font.pixelSize: 13
                    font.bold: modelData.fullPath === modelInfo.modelPath
                    elide: Text.ElideRight
                    width: parent.width
                }

                Row {
                    spacing: 12

                    Text {
                        text: "📦 " + modelData.size
                        color: modelPanel.textSecondary
                        font.pixelSize: 10
                    }

                    Text {
                        text: "🔢 " + modelData.parameters
                        color: modelPanel.textSecondary
                        font.pixelSize: 10
                    }

                    Text {
                        text: modelData.isAutoLoad ? "⚡ Auto" : ""
                        color: "#4ade80"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
        }
    }

    component HardwareCard: Column {
        property string icon: ""
        property string name: ""
        property var metrics: []

        spacing: 10

        Row {
            spacing: 8

            Text {
                text: icon
                font.pixelSize: 16
            }

            Text {
                text: name
                color: modelPanel.textPrimary
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
                width: parent.parent.width - 30
            }
        }

        Repeater {
            model: metrics

            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: modelData.label
                    color: modelPanel.textSecondary
                    font.pixelSize: 10
                }

                Rectangle {
                    width: parent.width
                    height: 28
                    radius: 6
                    color: "#0a0a15"

                    Rectangle {
                        width: parent.width * (modelData.progress || 0)
                        height: parent.height
                        radius: parent.radius
                        color: modelPanel.primaryColor
                        opacity: 0.3
                        visible: modelData.progress !== undefined

                        Behavior on width {
                            NumberAnimation { duration: 300 }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.value
                        color: modelData.color || modelPanel.textPrimary
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
            }
        }
    }

    // ========== DIALOGS ==========

    FolderDialog {
        id: folderDialog
        title: "Select Models Folder"
        currentFolder: modelInfo.modelsFolder ? "file:///" + modelInfo.modelsFolder : ""

        onAccepted: {
            var path = folderDialog.selectedFolder.toString()
            path = path.replace(/^(file:\/{3})/, "")
            if (Qt.platform.os === "windows") {
                path = path.replace(/^\//, "")
            }
            modelInfo.modelsFolder = path
        }
    }

    Popup {
        id: settingsPopup
        anchors.centerIn: Overlay.overlay
        width: 400
        height: 450
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

            Text {
                text: "⚙️ Model Settings"
                color: modelPanel.textPrimary
                font.pixelSize: 20
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 1
                color: modelPanel.textSecondary
                opacity: 0.3
            }

            Text {
                text: "⚠️ Coming Soon"
                color: modelPanel.primaryColor
                font.pixelSize: 16
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Column {
                width: parent.width
                spacing: 8

                Text { text: "• Temperature control"; color: modelPanel.textSecondary; font.pixelSize: 12 }
                Text { text: "• Top-P / Top-K sampling"; color: modelPanel.textSecondary; font.pixelSize: 12 }
                Text { text: "• Max tokens"; color: modelPanel.textSecondary; font.pixelSize: 12 }
                Text { text: "• Context size"; color: modelPanel.textSecondary; font.pixelSize: 12 }
                Text { text: "• GPU layers"; color: modelPanel.textSecondary; font.pixelSize: 12 }
            }

            Item { height: 20 }

            ActionButton {
                text: "Close"
                width: 120
                anchors.horizontalCenter: parent.horizontalCenter
                isPrimary: true
                onClicked: settingsPopup.close()
            }
        }
    }

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
            }

            Text {
                text: "Loading model..."
                color: modelPanel.textPrimary
                font.pixelSize: 14
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

            Text {
                text: "⚠️ Error Loading Model"
                color: modelPanel.textPrimary
                font.pixelSize: 16
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
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

            ActionButton {
                text: "OK"
                width: 100
                anchors.horizontalCenter: parent.horizontalCenter
                isDanger: true
                onClicked: errorPopup.close()
            }
        }
    }
}
