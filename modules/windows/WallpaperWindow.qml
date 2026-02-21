import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

PanelWindow {
    id: root
    
    visible: false
    color: "transparent"
    
    anchors { 
        left: true
        right: true
        top: true
        bottom: true 
    }
    
    exclusionMode: visible ? ExclusionMode.Normal : ExclusionMode.Ignore
    focusable: visible

    property bool showSettings: false

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.visible ? 0.6 : 0
        
        Behavior on opacity { 
            NumberAnimation { duration: 400 } 
        }
        
        MouseArea { 
            anchors.fill: parent
            onClicked: root.visible = false 
        }
    }

    ClippingRectangle {
        id: windowFrame
        width: 1050
        height: 680
        anchors.centerIn: parent
        radius: 36
        color: "#080809"
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        
        opacity: root.visible ? 1.0 : 0
        scale: root.visible ? 1.0 : 0.95
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

        MouseArea { 
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true 
        }

        Rectangle {
            anchors.fill: parent
            radius: 36
            color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.02) }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 32
                    
                    ColumnLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignHCenter
                        Text { 
                            text: "DESKTOP PREVIEW"
                            color: "white"
                            font.pixelSize: 10
                            font.weight: Font.Black
                            font.letterSpacing: 4
                            opacity: 0.3
                            Layout.alignment: Qt.AlignHCenter 
                        }
                        Rectangle { 
                            width: 40
                            height: 2
                            radius: 1
                            color: FrameConfig.accentColor
                            opacity: 0.4
                            Layout.alignment: Qt.AlignHCenter 
                        }
                    }

                    Item {
                        width: 600
                        height: 337
                        
                        Rectangle { 
                            anchors.fill: parent
                            anchors.margins: -10
                            radius: 30
                            color: FrameConfig.accentColor
                            opacity: 0.02
                            layer.enabled: true
                            layer.effect: MultiEffect { blurEnabled: true; blur: 0.6 } 
                        }
                        
                        Rectangle {
                            id: monitorFrame
                            anchors.fill: parent
                            radius: 24
                            color: "#000"
                            border.color: Qt.rgba(1, 1, 1, 0.15)
                            border.width: 1
                            
                            ClippingRectangle {
                                anchors.fill: parent
                                anchors.margins: 6
                                radius: 18
                                color: "black"
                                
                                Image { 
                                    id: previewImg
                                    anchors.fill: parent
                                    source: WallpaperService.previewWallpaper !== "" ? "file://" + WallpaperService.previewWallpaper : ""
                                    fillMode: Image.PreserveAspectCrop
                                    opacity: status === Image.Ready ? 1.0 : 0.1
                                    Behavior on source { PropertyAnimation { duration: 600 } } 
                                }
                                
                                Rectangle { 
                                    anchors.fill: parent
                                    radius: 18
                                    color: "transparent"
                                    border.color: "black"
                                    border.width: 2
                                    opacity: 0.4 
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 20
                        Layout.alignment: Qt.AlignHCenter
                        
                        Item {
                            width: 180
                            height: 48
                            property bool canSlideshow: WallpaperService.hasImages
                            
                            opacity: canSlideshow ? 1.0 : 0.0
                            scale: canSlideshow ? 1.0 : 0.8
                            visible: opacity > 0.01
                            
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 24
                                color: "#111112"
                                border.color: hSlide.hovered ? FrameConfig.accentColor : Qt.rgba(1, 1, 1, 0.1)
                                border.width: 1
                                
                                Text { 
                                    anchors.centerIn: parent
                                    text: "󰐊  SLIDESHOW"
                                    color: "white"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1
                                    opacity: hSlide.hovered ? 1.0 : 0.6 
                                }
                                scale: hSlide.hovered ? 1.02 : 1.0
                                Behavior on scale { NumberAnimation { duration: 200 } }
                            }
                            TapHandler { onTapped: { WallpaperService.startSlideshow(WallpaperService.currentDir); root.visible = false } }
                            HoverHandler { id: hSlide; cursorShape: Qt.PointingHandCursor }
                        }

                        Item {
                            width: 140
                            height: 48
                            opacity: WallpaperService.lastWallpaper !== "" ? 1.0 : 0.3
                            
                            Rectangle {
                                id: revBg
                                anchors.fill: parent
                                radius: 24
                                color: "#111112"
                                border.color: hRev.hovered ? "white" : Qt.rgba(1, 1, 1, 0.1)
                                border.width: 1
                                
                                Text { 
                                    anchors.centerIn: parent
                                    text: "󰕌  REVERT"
                                    color: "white"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1
                                    opacity: hRev.hovered ? 1.0 : 0.6 
                                }
                                scale: hRev.hovered ? 1.02 : 1.0
                                Behavior on scale { NumberAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                            }
                            TapHandler { enabled: WallpaperService.lastWallpaper !== ""; onTapped: WallpaperService.revert() }
                            HoverHandler { id: hRev; cursorShape: Qt.PointingHandCursor }
                        }

                        Item {
                            width: 240
                            height: 48
                            readonly property bool hasChanges: WallpaperService.previewWallpaper !== "" && WallpaperService.previewWallpaper !== WallpaperService.activeWallpaper
                            
                            opacity: hasChanges ? 1.0 : 0.0
                            scale: hasChanges ? 1.0 : 0.8
                            visible: opacity > 0.01
                            
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                            
                            Rectangle {
                                id: appBg
                                anchors.fill: parent
                                radius: 24
                                color: FrameConfig.accentColor
                                
                                Rectangle { 
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    radius: 28
                                    color: FrameConfig.accentColor
                                    opacity: hApp.hovered ? 0.02 : 0.0
                                    z: -1
                                    layer.enabled: true
                                    layer.effect: MultiEffect { blurEnabled: true; blur: 0.6 }
                                    Behavior on opacity { NumberAnimation { duration: 300 } } 
                                }
                                
                                Rectangle { 
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: 23
                                    color: "transparent"
                                    border.color: Qt.rgba(1, 1, 1, 0.3)
                                    border.width: 1 
                                }
                                
                                Text { 
                                    anchors.centerIn: parent
                                    text: "󰄬  CONFIRM CHANGES"
                                    color: "black"
                                    font.pixelSize: 11
                                    font.weight: Font.Black
                                    font.letterSpacing: 1 
                                }
                                scale: hApp.hovered ? 1.03 : 1.0
                                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            }
                            TapHandler { onTapped: { WallpaperService.apply(); root.visible = false } }
                            HoverHandler { id: hApp; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            Rectangle { 
                width: 1
                Layout.fillHeight: true
                color: "white"
                opacity: 0.05 
            }

            Rectangle {
                Layout.preferredWidth: 420
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.15)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20
                    
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 4
                            Text { 
                                text: root.showSettings ? "SETTINGS" : "EXPLORER"
                                color: "white"
                                font.pixelSize: 10
                                font.weight: Font.Black
                                font.letterSpacing: 3
                                opacity: 0.3 
                            }
                            Rectangle { 
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: Math.min(pathText.implicitWidth + 24, 250)
                                radius: 12
                                color: "white"
                                opacity: 0.12
                                border.color: Qt.rgba(1, 1, 1, 0.15)
                                border.width: 1
                                visible: !root.showSettings
                                
                                Text { 
                                    id: pathText
                                    anchors.centerIn: parent
                                    text: WallpaperService.currentDir
                                    color: "white"
                                    font.pixelSize: 9
                                    font.family: "Monospace"
                                    opacity: 1.0
                                    elide: Text.ElideLeft
                                    width: parent.width - 20 
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Row {
                            spacing: 10
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 10
                                color: root.showSettings ? FrameConfig.accentColor : "white"
                                opacity: root.showSettings ? 1.0 : 0.1
                                Text { 
                                    anchors.centerIn: parent
                                    text: "󰒓"
                                    color: root.showSettings ? "black" : "white"
                                    font.pixelSize: 18 
                                }
                                TapHandler { onTapped: root.showSettings = !root.showSettings }
                                HoverHandler { id: hSet; cursorShape: Qt.PointingHandCursor }
                                scale: hSet.hovered ? 1.1 : 1.0
                                Behavior on scale { NumberAnimation { duration: 200 } }
                            }
                            
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 10
                                color: WallpaperService.showHidden ? FrameConfig.accentColor : "white"
                                opacity: WallpaperService.showHidden ? 1.0 : 0.1
                                visible: !root.showSettings
                                
                                Text { 
                                    anchors.centerIn: parent
                                    text: "󰈈"
                                    color: WallpaperService.showHidden ? "black" : "white"
                                    font.pixelSize: 18 
                                }
                                TapHandler { onTapped: WallpaperService.showHidden = !WallpaperService.showHidden }
                                HoverHandler { id: hHidden; cursorShape: Qt.PointingHandCursor }
                                scale: hHidden.hovered ? 1.1 : 1.0
                                Behavior on scale { NumberAnimation { duration: 200 } }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        ClippingRectangle {
                            anchors.fill: parent
                            color: "transparent"
                            radius: 0
                            visible: !root.showSettings
                            
                            GridView { 
                                id: grid
                                anchors.fill: parent
                                anchors.margins: 10
                                model: WallpaperService.model
                                cellWidth: 124
                                cellHeight: 124
                                clip: false
                                
                                Behavior on contentY { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                                
                                delegate: Item { 
                                    width: 114
                                    height: 114
                                    
                                    Rectangle { 
                                        anchors.fill: parent
                                        radius: 20
                                        color: "#0A0A0B"
                                        border.color: (WallpaperService.previewWallpaper === model.path) ? FrameConfig.accentColor : Qt.rgba(1, 1, 1, 0.05)
                                        border.width: (WallpaperService.previewWallpaper === model.path) ? 2 : 1
                                        clip: true
                                        
                                        Rectangle { 
                                            anchors.fill: parent
                                            radius: 20
                                            color: "transparent"
                                            border.color: Qt.rgba(1, 1, 1, 0.05)
                                            border.width: 1
                                            anchors.margins: 1 
                                        }
                                        
                                        ColumnLayout { 
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 10
                                            
                                            Item { 
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Text { 
                                                    anchors.centerIn: parent
                                                    text: model.path === ".." ? "󰁝" : (model.isDir ? "󰉋" : "󰸉")
                                                    color: model.isDir ? FrameConfig.accentColor : "white"
                                                    font.pixelSize: model.isDir ? 42 : 36
                                                    opacity: (WallpaperService.previewWallpaper === model.path || hh.hovered) ? 1.0 : 0.3
                                                    Behavior on opacity { NumberAnimation { duration: 200 } } 
                                                }
                                            }
                                            
                                            Text { 
                                                text: model.name
                                                color: "white"
                                                font.pixelSize: 10
                                                font.weight: Font.Medium
                                                opacity: (WallpaperService.previewWallpaper === model.path || hh.hovered) ? 0.9 : 0.4
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight 
                                            }
                                        }
                                        
                                        MouseArea { 
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { 
                                                if (model.isDir) WallpaperService.changeDirectory(model.path)
                                                else WallpaperService.previewWallpaper = model.path 
                                            } 
                                        }
                                        
                                        scale: hh.hovered ? 1.05 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                        HoverHandler { id: hh }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            visible: root.showSettings
                            spacing: 24
                            
                            ColumnLayout {
                                spacing: 12
                                Layout.fillWidth: true
                                Text { 
                                    text: "TRANSITION TYPE"
                                    color: "white"
                                    font.pixelSize: 10
                                    font.weight: Font.Black
                                    font.letterSpacing: 2
                                    opacity: 0.4 
                                }
                                Row {
                                    spacing: 8
                                    Layout.fillWidth: true
                                    Repeater {
                                        model: ["simple", "grow", "fade", "wipe", "wave"]
                                        Rectangle {
                                            width: 70
                                            height: 32
                                            radius: 16
                                            color: WallpaperService.transitionType === modelData ? FrameConfig.accentColor : "white"
                                            opacity: WallpaperService.transitionType === modelData ? 1.0 : 0.05
                                            
                                            Text { 
                                                anchors.centerIn: parent
                                                text: modelData.toUpperCase()
                                                color: WallpaperService.transitionType === modelData ? "black" : "white"
                                                font.pixelSize: 8
                                                font.weight: Font.Bold 
                                            }
                                            TapHandler { onTapped: { WallpaperService.transitionType = modelData } }
                                            HoverHandler { id: hT; cursorShape: Qt.PointingHandCursor }
                                            scale: hT.hovered ? 1.05 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 200 } }
                                        }
                                    }
                                }
                            }
                            
                            ColumnLayout {
                                spacing: 12
                                Layout.fillWidth: true
                                Text { 
                                    text: "SLIDESHOW INTERVAL"
                                    color: "white"
                                    font.pixelSize: 10
                                    font.weight: Font.Black
                                    font.letterSpacing: 2
                                    opacity: 0.4 
                                }
                                RowLayout {
                                    spacing: 16
                                    Slider {
                                        id: sSlider
                                        Layout.fillWidth: true
                                        from: 60000
                                        to: 3600000
                                        stepSize: 60000
                                        value: WallpaperService.slideshowInterval
                                        onMoved: { WallpaperService.slideshowInterval = value }
                                    }
                                    Text { 
                                        text: Math.round(WallpaperService.slideshowInterval / 60000) + "m"
                                        color: "white"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        opacity: 0.6
                                        Layout.preferredWidth: 40 
                                    }
                                }
                            }
                            
                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }
        }
    }
}
