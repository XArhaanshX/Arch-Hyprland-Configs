import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Drifting mist over the wallpaper, under every window. Click-through, never
// takes focus, animates only while the desktop is visible, hides while a
// window is fullscreen.
// Control: the `mist` command (on/off/strength), or
//   qs -c mist ipc call mist setStrength 0.5
ShellRoot {
    id: root
    property real strength: 0.65
    property int fps: 24            // when the desktop is visible
    property int windowsFps: 0      // when windows cover it (0 = hold still: behind
                                    // frosted glass nobody sees it move, and every
                                    // mist frame makes Hyprland redraw all the glass)
    // per monitor: windows on its visible workspace(s), fullscreen, ii's parallax pan
    property var monitorState: ({})
    readonly property bool desktopVisible: Object.values(monitorState).some(m => m.windows === 0 && !m.fullscreen)
    readonly property int activeFps: desktopVisible ? fps : windowsFps
    property real time: 0
    readonly property real startedAt: Date.now()
    property bool mapped: true

    // The ii shell's settings: which wallpaper, and how it zooms and pans it.
    FileView {
        id: iiConfig
        path: Quickshell.env("HOME") + "/.config/illogical-impulse/config.json"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property var bg: { try { return JSON.parse(iiConfig.text()).background ?? {}; } catch (e) { return {}; } }
    readonly property string wallpaperPath: {
        const p = bg.wallpaperPath ?? "";
        return /\.(mp4|webm|mkv|avi|mov)$/i.test(p) ? (bg.thumbnailPath ?? "") : p;   // videos: their thumbnail
    }
    readonly property bool workspaceParallax: bg.parallax?.enableWorkspace ?? true
    readonly property real zoom: bg.parallax?.workspaceZoom ?? 1.07

    // saved strength, so it survives restarts
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/mist/strength"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = parseFloat(text());
            if (!isNaN(v)) root.strength = Math.max(0, Math.min(1, v));
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            readonly property var mon: root.monitorState[modelData.name] ?? ({ windows: 0, fullscreen: false, panX: 0.5 })
            screen: modelData
            visible: root.mapped && !mon.fullscreen && root.strength > 0
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            // The ii wallpaper is on this same layer; staying above it is handled
            // by re-mapping whenever the wallpaper's layer opens (see below).
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "desktop-mist"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            MistEffect {
                anchors.fill: parent
                wallpaper: root.wallpaperPath ? "file://" + root.wallpaperPath : ""
                time: root.time
                strength: root.strength
                zoom: root.zoom
                panX: root.workspaceParallax ? mon.panX : 0.5
            }
        }
    }

    Timer {
        interval: Math.round(1000 / Math.max(1, root.activeFps))
        repeat: true
        running: root.strength > 0 && root.activeFps > 0
        onTriggered: root.time = ((Date.now() - root.startedAt) / 1000) % 1000000
    }

    // Ask hyprctl, like the ii shell does: Quickshell's typed workspace data is
    // empty in a fresh instance under Hyprland 0.57.
    Process {
        id: query
        command: ["sh", "-c", "hyprctl -j monitors; echo @@; hyprctl -j workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = text.split("@@");
                    const mons = JSON.parse(parts[0]), wss = JSON.parse(parts[1]), byId = {};
                    for (const ws of wss) byId[ws.id] = ws;
                    const chunk = 10;   // ii's bar.workspaces.shown
                    const st = {};
                    for (const m of mons) {
                        const ws = byId[m.activeWorkspace?.id] ?? {};
                        const sp = m.specialWorkspace?.id ? byId[m.specialWorkspace.id] : null;
                        // ii's parallax: pan by workspace across a group of 10
                        const used = wss.filter(w => w.monitor === m.name && w.id > 0 && w.windows > 0).map(w => w.id);
                        const last = used.length ? Math.max(...used) : 10;
                        const total = Math.ceil(last / chunk) * chunk;
                        const idx = (m.activeWorkspace?.id ?? 1) - 1;
                        st[m.name] = {
                            windows: (ws.windows ?? 0) + (sp?.windows ?? 0),
                            fullscreen: !!ws.hasfullscreen,
                            panX: total <= 1 ? 0.5 : Math.max(0, Math.min(1, idx / (total - 1))),
                        };
                    }
                    root.monitorState = st;
                } catch (e) { console.warn("mist: could not read hyprctl output:", e); }
            }
        }
    }
    Timer { id: refresh; interval: 80; onTriggered: query.running = true }
    // the wallpaper's layer came back (the ii shell restarted): map again so the
    // mist is the newer surface on the layer, above the wallpaper
    Timer { id: remap; interval: 60; onTriggered: root.mapped = true }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "openlayer" && event.data.trim() === "quickshell:background") {
                root.mapped = false;
                remap.restart();
                return;
            }
            if (["activewindow", "activewindowv2", "windowtitle", "windowtitlev2", "openlayer",
                 "closelayer", "screencast", "submap", "bell"].includes(event.name)) return;
            refresh.restart();
        }
    }
    Component.onCompleted: query.running = true

    IpcHandler {
        target: "mist"
        function setStrength(value: real): void { root.strength = Math.max(0, Math.min(1, value)); }
        function getStrength(): string { return root.strength.toFixed(2); }
        function setFps(value: int): void { root.fps = Math.max(0, Math.min(60, value)); }
        function setWindowsFps(value: int): void { root.windowsFps = Math.max(0, Math.min(60, value)); }
        function status(): string { return `strength ${root.strength.toFixed(2)}, ${root.activeFps} fps now (desktop ${root.fps}, behind windows ${root.windowsFps})`; }
    }
}
