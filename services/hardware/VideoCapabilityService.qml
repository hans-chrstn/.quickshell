pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "VideoCapabilityParser.js" as CapabilityParser
import "VideoCodecEvidence.js" as CodecEvidence

Singleton {
    id: root

    property string state: "idle"
    property string error: ""
    property string vainfoPath: ""
    property var renderNodes: []
    property var deviceRecords: []
    property int nodeIndex: 0
    property bool hardwareFinished: false
    property bool encoderChecked: false
    property string ffmpegPath: ""
    property var softwareEncoders: []
    // Session-local until a later benchmark owner is accepted. Capability
    // discovery must never fabricate or persist measurements.
    property var codecEvidence: ({})

    readonly property bool busy: state === "discovering"
    readonly property var verifiedDecodeCodecs:
        CapabilityParser.mergedCodecs(deviceRecords)
    readonly property string recommendedCodec:
        CapabilityParser.recommendedCodec(verifiedDecodeCodecs)
    readonly property bool recommendationVerified:
        verifiedDecodeCodecs.indexOf(recommendedCodec) >= 0
    readonly property var codecCandidates: CapabilityParser.codecCandidates(
        verifiedDecodeCodecs, softwareEncoders)
    readonly property var codecEvaluations: CodecEvidence.evaluateCandidates(
        codecCandidates, codecEvidence)

    function refresh() {
        if (busy)
            return false
        state = "discovering"
        error = ""
        vainfoPath = ""
        renderNodes = []
        deviceRecords = []
        nodeIndex = 0
        hardwareFinished = false
        encoderChecked = false
        ffmpegPath = ""
        softwareEncoders = []
        toolCheck.output = ""
        toolCheck.command = ["/bin/sh", "-c", "command -v vainfo"]
        toolCheck.running = true
        encoderToolCheck.output = ""
        encoderToolCheck.command = ["/bin/sh", "-c", "command -v ffmpeg"]
        encoderToolCheck.running = true
        return true
    }

    function finishDiscovery() {
        if (!hardwareFinished || !encoderChecked)
            return
        if (deviceRecords.length > 0) {
            state = "ready"
            return
        }
        state = "unavailable"
        if (error.length === 0)
            error = "Hardware decode profiles are unavailable; using conservative H.264"
    }

    function inspectNextNode() {
        if (nodeIndex >= renderNodes.length) {
            hardwareFinished = true
            if (deviceRecords.length === 0 && error.length === 0)
                error = "No VAAPI render node could be inspected"
            finishDiscovery()
            return
        }
        const node = renderNodes[nodeIndex]
        profileCheck.output = ""
        profileCheck.command = [vainfoPath, "--display", "drm",
            "--device", node]
        profileCheck.running = true
    }

    function snapshot() {
        return {
            state: state,
            backend: vainfoPath.length > 0 ? "vainfo-vaapi" : "fallback",
            error: error,
            devices: deviceRecords,
            verifiedDecodeCodecs: verifiedDecodeCodecs,
            decodePreferredCodec: recommendedCodec,
            recommendationVerified: recommendationVerified,
            softwareEncoders: softwareEncoders,
            codecCandidates: codecCandidates,
            measurementRequirements: CodecEvidence.requirements(),
            codecEvaluations: codecEvaluations,
            conservativeCodec: "h264",
            autoSelectionReady:
                CodecEvidence.automaticSelectionReady(codecEvaluations),
            fallbackPolicy: recommendationVerified ? "none"
                : "conservative-h264"
        }
    }

    Process {
        id: toolCheck
        property string output: ""
        stdout: StdioCollector { onStreamFinished: toolCheck.output = text }
        onExited: exitCode => {
            root.vainfoPath = exitCode === 0 ? output.trim() : ""
            if (root.vainfoPath.length === 0) {
                root.error = "vainfo is unavailable; using conservative H.264"
                root.hardwareFinished = true
                root.finishDiscovery()
                return
            }
            nodeCheck.output = ""
            nodeCheck.command = ["find", "/dev/dri", "-maxdepth", "1",
                "-type", "c", "-name", "renderD*", "-print"]
            nodeCheck.running = true
        }
    }

    Process {
        id: nodeCheck
        property string output: ""
        stdout: StdioCollector { onStreamFinished: nodeCheck.output = text }
        onExited: exitCode => {
            root.renderNodes = exitCode === 0 ? output.split(/\r?\n/)
                .map(value => value.trim()).filter(value => value.length > 0)
                .sort() : []
            if (root.renderNodes.length === 0) {
                root.error = "No DRM render nodes are available; using conservative H.264"
                root.hardwareFinished = true
                root.finishDiscovery()
                return
            }
            root.nodeIndex = 0
            root.inspectNextNode()
        }
    }

    Process {
        id: profileCheck
        property string output: ""
        stdout: StdioCollector { onStreamFinished: profileCheck.output = text }
        stderr: StdioCollector {
            onStreamFinished: profileCheck.output += "\n" + text
        }
        onExited: exitCode => {
            const node = root.renderNodes[root.nodeIndex]
            if (exitCode === 0) {
                const record = CapabilityParser.parseVainfo(output, node)
                if (record.decodeCodecs.length > 0) {
                    const updated = root.deviceRecords.slice()
                    updated.push(record)
                    root.deviceRecords = updated
                }
            }
            root.nodeIndex += 1
            root.inspectNextNode()
        }
    }


    Process {
        id: encoderToolCheck
        property string output: ""
        stdout: StdioCollector {
            onStreamFinished: encoderToolCheck.output = text
        }
        onExited: exitCode => {
            root.ffmpegPath = exitCode === 0 ? output.trim() : ""
            if (root.ffmpegPath.length === 0) {
                root.encoderChecked = true
                root.finishDiscovery()
                return
            }
            encoderCheck.output = ""
            encoderCheck.command = [root.ffmpegPath, "-hide_banner", "-encoders"]
            encoderCheck.running = true
        }
    }

    Process {
        id: encoderCheck
        property string output: ""
        stdout: StdioCollector { onStreamFinished: encoderCheck.output = text }
        stderr: StdioCollector {
            onStreamFinished: encoderCheck.output += "\n" + text
        }
        onExited: exitCode => {
            root.softwareEncoders = exitCode === 0
                ? CapabilityParser.parseEncoders(output) : []
            root.encoderChecked = true
            root.finishDiscovery()
        }
    }
}
