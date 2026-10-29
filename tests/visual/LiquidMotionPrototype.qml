import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.tests.visual

ShellRoot {
    id: root

    readonly property string requestedScreen: Quickshell.env("QS_VISUAL_TEST_SCREEN")
    readonly property var targetScreen: {
        for (const candidate of Quickshell.screens) {
            if (candidate.name === requestedScreen)
                return candidate;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    PanelWindow {
        id: window

        property bool expanded: Quickshell.env("QS_VISUAL_LAB_EXPANDED") === "1"
        property bool reducedMotion: Quickshell.env("QS_VISUAL_LAB_REDUCED_MOTION") === "1"
        property bool sampleLoadingComplete: false
        readonly property bool constrained: Quickshell.env("QS_VISUAL_LAB_CONSTRAINED") === "1"
        readonly property bool blurAvailable: Quickshell.env("QS_VISUAL_LAB_NO_BLUR") !== "1"
        property real morphProgress: expanded ? 1 : 0
        property int materialMode: {
            const requested = (Quickshell.env("QS_VISUAL_LAB_MATERIAL") ?? "").toLowerCase();
            if (requested === "opaque")
                return 0;
            if (requested === "glass")
                return 1;
            return 2;
        }
        readonly property real secondaryReveal: Math.max(0, Math.min(1, (morphProgress - 0.48) / 0.22))
        readonly property var materialNames: ["Opaque", "Glass", "Adaptive"]

        screen: root.targetScreen
        anchors.top: true
        anchors.left: true
        margins.top: 56
        margins.left: 56
        implicitWidth: 760
        implicitHeight: 460
        color: "#d0060608"
        WlrLayershell.namespace: "inspire-visual-lab"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Behavior on morphProgress {
            NumberAnimation {
                duration: window.reducedMotion ? 90 : 520
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#e609090c"

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: "#10ffffff"
            }
        }

        Rectangle {
            x: 470
            y: 84
            width: 210
            height: 210
            radius: 105
            color: "#14ff9f0a"
        }

        Rectangle {
            x: 86
            y: 250
            width: 170
            height: 170
            radius: 85
            color: "#0cffffff"
        }

        Text {
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: 28
                topMargin: 22
            }
            text: "VISUAL SYSTEM LAB"
            color: "#73737b"
            font.family: "SF Pro Text"
            font.pixelSize: 10
            font.letterSpacing: 1.4
            font.weight: Font.DemiBold
        }

        Text {
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 28
                topMargin: 20
            }
            text: window.reducedMotion ? "Reduced motion" : window.blurAvailable ? "Spatial motion" : "Matte fallback"
            color: "#8b8b92"
            font.family: "SF Pro Text"
            font.pixelSize: 11

            TapHandler {
                onTapped: window.reducedMotion = !window.reducedMotion
            }
        }

        Rectangle {
            id: materialPicker

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 54
            }
            width: 306
            height: 34
            radius: 17
            color: "#0effffff"
            border.width: 1
            border.color: "#16ffffff"

            Row {
                anchors.fill: parent

                Repeater {
                    model: window.materialNames

                    delegate: Item {
                        required property int index
                        required property string modelData

                        width: materialPicker.width / 3
                        height: materialPicker.height

                        Rectangle {
                            anchors {
                                fill: parent
                                margins: 3
                            }
                            radius: 14
                            color: window.materialMode === index ? "#18ffffff" : pickerTap.pressed ? "#10ffffff" : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 140
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: window.materialMode === index ? "#f2f2f4" : "#85858d"
                            font.family: "SF Pro Text"
                            font.pixelSize: 11
                            font.weight: window.materialMode === index ? Font.DemiBold : Font.Medium
                        }

                        TapHandler {
                            id: pickerTap

                            onTapped: window.materialMode = index
                        }
                    }
                }
            }
        }

        Item {
            id: island

            anchors.centerIn: parent
            width: 252 + 356 * window.morphProgress
            height: 46 + 240 * window.morphProgress
            clip: true

            VisualLabSurface {
                anchors.fill: parent
                morphProgress: window.morphProgress
                materialMode: window.materialMode
                blurAvailable: window.blurAvailable
            }

            Item {
                id: stage

                anchors.centerIn: parent
                width: 560
                height: 280

                readonly property real compactIconX: (width - 220) / 2
                readonly property real compactIconY: (height - 36) / 2

                Rectangle {
                    id: iconWell

                    x: stage.compactIconX + (24 - stage.compactIconX) * window.morphProgress
                    y: stage.compactIconY + (20 - stage.compactIconY) * window.morphProgress
                    width: 36
                    height: 36
                    radius: 13
                    color: "#17ffffff"

                    VisualLabGlyph {
                        anchors.centerIn: parent
                        width: 19
                        height: 19
                        glyphColor: "#f5f5f7"
                    }
                }

                Text {
                    id: systemTitle

                    x: stage.compactIconX + 48 + (72 - stage.compactIconX - 48) * window.morphProgress
                    y: stage.compactIconY + 9 + (18 - stage.compactIconY - 9) * window.morphProgress
                    text: "Inspire"
                    color: "#f5f5f7"
                    font.family: "SF Pro Display"
                    font.pixelSize: 23
                    font.weight: Font.DemiBold
                    scale: 0.66 + 0.34 * window.morphProgress
                    transformOrigin: Item.TopLeft
                }

                Text {
                    x: systemTitle.x
                    y: systemTitle.y + systemTitle.height * systemTitle.scale + 2
                    text: "Fluid graphite · bounded state feedback"
                    color: "#8c8c93"
                    opacity: window.secondaryReveal
                    font.family: "SF Pro Text"
                    font.pixelSize: 11
                }

                Rectangle {
                    x: stage.compactIconX + 196
                    y: systemTitle.y + systemTitle.height * systemTitle.scale / 2 - height / 2
                    width: 7
                    height: 7
                    radius: 3.5
                    color: "#ffffa21a"
                    opacity: 1 - window.secondaryReveal
                    scale: 0.76 + 0.24 * (1 - window.secondaryReveal)
                }

                Text {
                    anchors {
                        left: parent.left
                        top: parent.top
                        topMargin: 111
                    }
                    text: "STATE FEEDBACK"
                    color: "#696970"
                    opacity: window.secondaryReveal
                    font.family: "SF Pro Text"
                    font.pixelSize: 9
                    font.letterSpacing: 1.2
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    x: 0
                    y: 132
                    width: 560
                    height: 116
                    radius: 18
                    color: "#05ffffff"
                    border.width: 1
                    border.color: "#10ffffff"
                    opacity: Math.max(0, Math.min(1, (window.morphProgress - 0.58) / 0.2))

                    VisualLabStatusRow {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        height: 58
                        title: window.sampleLoadingComplete ? "Preview prepared" : "Preparing preview"
                        detail: window.sampleLoadingComplete ? "Optimized frames are ready" : "Generating a lightweight working set"
                        state: window.sampleLoadingComplete ? "ready" : "loading"
                        enabled: parent.opacity > 0.98
                        onActivated: window.sampleLoadingComplete = !window.sampleLoadingComplete
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 16
                            rightMargin: 16
                        }
                        height: 1
                        color: "#10ffffff"
                    }

                    VisualLabStatusRow {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: 58
                        title: "Hardware texture path"
                        detail: "Unavailable on this simulated backend"
                        state: "unavailable"
                        enabled: false
                    }
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: eventPoint => {
                    if (eventPoint.position.y < 70 || !window.expanded)
                        window.expanded = !window.expanded;
                }
            }
        }

        Text {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 22
            }
            text: "Activate the loading row to hand off to ready · animation stops when hidden"
            color: "#686870"
            font.family: "SF Pro Text"
            font.pixelSize: 10
        }

        FocusScope {
            anchors.fill: parent
            focus: true

            Keys.onSpacePressed: window.expanded = !window.expanded
            Keys.onEscapePressed: window.expanded = false
            Keys.onPressed: event => {
                if (event.key === Qt.Key_R) {
                    window.reducedMotion = !window.reducedMotion;
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()
        }

        Timer {
            interval: 1600
            repeat: true
            running: Quickshell.env("QS_VISUAL_LAB_AUTOPLAY") === "1"
            onTriggered: window.expanded = !window.expanded
        }
    }
}
