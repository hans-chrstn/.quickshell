import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.services

Item {
    id: root
    property var player: null
    
    RowLayout { 
        anchors.fill: parent
        anchors.margins: 15
        spacing: 20
        
        Item {
            Layout.preferredWidth: ThemeService.musicArtSize
            Layout.preferredHeight: ThemeService.musicArtSize
            Layout.alignment: Qt.AlignVCenter
            visible: ThemeService.showMusicArt
            
            Item {
                id: vinylDisk
                anchors.fill: parent
                z: 1 
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowOpacity: ThemeService.musicArtShadowOpacity
                    shadowBlur: 0.4
                    shadowVerticalOffset: 2
                }                
                NumberAnimation on rotation {
                    from: 0; to: 360
                    duration: ThemeService.musicRotationDuration
                    loops: Animation.Infinite
                    running: root.player && root.player.playbackState === MprisPlaybackState.Playing
                }
                
                ClippingRectangle { 
                    anchors.fill: parent
                    radius: ThemeService.musicArtRadius
                    color: ThemeService.surfaceVariant
                    
                    Image {
                        id: artImage
                        anchors.fill: parent
                        source: (root.player && root.player.trackArtUrl) || ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 500 } }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"; color: ThemeService.backgroundContent; opacity: 0.2; font.pixelSize: 24
                        visible: !root.player || !root.player.trackArtUrl || (parent.children[0] && parent.children[0].status !== Image.Ready)
                    }
                }
                
                Rectangle {
                    anchors.centerIn: parent
                    width: ThemeService.musicHoleSize
                    height: ThemeService.musicHoleSize
                    radius: width / 2
                    color: ThemeService.backgroundMain
                    border.color: ThemeService.outlineVariant; border.width: 1
                }
            }
        }
        
        ColumnLayout { 
            Layout.fillWidth: true; spacing: 4
            Layout.alignment: Qt.AlignVCenter
            
            Text { 
                Layout.fillWidth: true
                text: (root.player && root.player.trackTitle) || "No Music"
                color: ThemeService.backgroundContent; font.weight: Font.DemiBold; font.pixelSize: 14
                elide: Text.ElideRight 
            }
            Text { 
                Layout.fillWidth: true
                text: (root.player && root.player.trackArtist) || "Nothing playing"
                color: ThemeService.secondaryContent; opacity: 0.8; font.pixelSize: 11
                elide: Text.ElideRight 
            }
            
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 4; Layout.topMargin: 8
                
                property bool hovered: barMouseArea.containsMouse
                property bool dragging: barMouseArea.pressed
                
                height: hovered || dragging ? 8 : 4
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                
                Rectangle { anchors.fill: parent; radius: 2; color: ThemeService.backgroundContent; opacity: 0.1 }
                
                Rectangle {
                    height: parent.height; radius: 2; color: ThemeService.backgroundContent; opacity: 0.8
                    width: (root.player && root.player.length > 0) ? parent.width * (root.player.position / root.player.length) : 0
                }
                
                MouseArea {
                    id: barMouseArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor
                    
                    function seek(mouse) {
                        if (root.player && root.player.length > 0) {
                            var pct = Math.max(0, Math.min(1, mouse.x / width))
                            root.player.position = pct * root.player.length
                        }
                    }
                    
                    onPressed: (mouse) => seek(mouse)
                    onPositionChanged: (mouse) => { if (pressed) seek(mouse) }
                }
            }

            RowLayout { 
                Layout.fillWidth: true; Layout.topMargin: 8
                spacing: ThemeService.musicControlSpacing
                Layout.alignment: Qt.AlignHCenter
                
                Item { Layout.fillWidth: true }
                
                Text { 
                    text: "󰒮"; color: ThemeService.backgroundContent; opacity: 0.6; font.pixelSize: 20
                    Layout.alignment: Qt.AlignVCenter
                    
                    scale: thPrev.pressed ? 0.9 : (hhPrev.hovered ? 1.2 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    
                    TapHandler { id: thPrev; onTapped: root.player.previous() } 
                    HoverHandler { id: hhPrev; cursorShape: Qt.PointingHandCursor }
                }
                
                Text { 
                    text: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                    color: ThemeService.backgroundContent; font.pixelSize: 28
                    Layout.alignment: Qt.AlignVCenter
                    
                    scale: thPlay.pressed ? 0.9 : (hhPlay.hovered ? 1.2 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    
                    TapHandler { id: thPlay; onTapped: root.player.togglePlaying() }
                    HoverHandler { id: hhPlay; cursorShape: Qt.PointingHandCursor }
                }
                
                Text { 
                    text: "󰒭"; color: ThemeService.backgroundContent; opacity: 0.6; font.pixelSize: 20
                    Layout.alignment: Qt.AlignVCenter
                    
                    scale: thNext.pressed ? 0.9 : (hhNext.hovered ? 1.2 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    
                    TapHandler { id: thNext; onTapped: root.player.next() }
                    HoverHandler { id: hhNext; cursorShape: Qt.PointingHandCursor }
                }
                
                Item { Layout.fillWidth: true }
            }
        }
    }
}
