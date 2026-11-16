import QtQuick

// The mist itself: the shader, rendered at a fraction of the screen's
// resolution (mist has no fine detail, and this keeps it cheap), lit by a
// tiny copy of the wallpaper placed exactly as the ii shell shows it.
Item {
    id: root
    property url wallpaper
    property real time: 0
    property real strength: 0.65
    property int downscale: 4       // render at 1/4 resolution, upscaled smoothly
    property real zoom: 1.07        // ii's background.parallax.workspaceZoom
    property real panX: 0.5         // ii's horizontal parallax position, 0..1

    // the wallpaper as ii shows it: covering the screen, zoomed, panned by
    // workspace, then shrunk to a blur
    Item {
        id: wallFrame
        anchors.fill: parent
        clip: true
        visible: false
        Image {
            id: wall
            source: root.wallpaper
            sourceSize: Qt.size(480, 300)   // keeps the aspect ratio; small on purpose
            smooth: true
            readonly property real ar: implicitHeight > 0 ? implicitWidth / implicitHeight : 16 / 9
            readonly property bool wide: ar > root.width / Math.max(1, root.height)
            height: (wide ? root.height : root.width / ar) * root.zoom
            width: height * ar
            x: width > root.width ? -(width - root.width) * root.panX : (root.width - width) / 2
            y: -(height - root.height) / 2
            onStatusChanged: if (status === Image.Ready) sceneTex.scheduleUpdate()
        }
    }
    ShaderEffectSource {
        id: sceneTex
        sourceItem: wallFrame
        textureSize: Qt.size(96, 60)
        smooth: true
        hideSource: true
        live: false
    }
    onPanXChanged: sceneTex.scheduleUpdate()
    onZoomChanged: sceneTex.scheduleUpdate()
    onWidthChanged: sceneTex.scheduleUpdate()

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.max(1, Math.round(width / root.downscale)),
                                   Math.max(1, Math.round(height / root.downscale)))
        ShaderEffect {
            anchors.fill: parent
            property real time: root.time
            property real aspect: root.width / Math.max(1, root.height)
            property real strength: root.strength
            property var scene: sceneTex
            fragmentShader: Qt.resolvedUrl("shaders/mist.frag.qsb")
        }
    }
}
