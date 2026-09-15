import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Blobs

// OSD luminosité — même pilule/position/dimensions que le module son
// (quickshell/osd/shell.qml), juste une autre source de données.
// Réactif à /sys/class/backlight (donc à toute source : touches clavier,
// brightnessctl en ligne de commande, etc), pas seulement au drag du slider.

Scope {
    id: root

    readonly property string backlightDevice: "amdgpu_bl1"
    readonly property string brightnessPath: "/sys/class/backlight/" + backlightDevice + "/brightness"

    property real maxBrightness: 65535 // écrasé au démarrage par maxProc
    property real brightness: 0
    property bool brightnessInitialized: false
    property bool shown: false

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }

    // Lu une seule fois au démarrage (max_brightness ne change jamais).
    Process {
        id: maxProc
        command: ["cat", "/sys/class/backlight/" + root.backlightDevice + "/max_brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = Number(text.trim());
                if (!isNaN(v) && v > 0)
                    root.maxBrightness = v;
            }
        }
    }

    // Le noyau émet un événement inotify sur ce fichier à chaque
    // changement (touches, brightnessctl externe, notre propre slider) —
    // FileView le relit automatiquement, pas de polling.
    FileView {
        id: brightnessFile
        path: root.brightnessPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = Number(text().trim());
            if (isNaN(v) || root.maxBrightness <= 0)
                return;
            root.brightness = v / root.maxBrightness;

            if (root.brightnessInitialized) {
                root.shown = true;
                hideTimer.restart();
            } else {
                root.brightnessInitialized = true;
            }
        }
    }

    Process {
        id: setProc
        stdout: StdioCollector {}
    }

    function setBrightness(percent) {
        setProc.command = ["brightnessctl", "--device=" + backlightDevice, "set", Math.round(percent * 100) + "%", "-q"];
        setProc.running = true;
    }

    PanelWindow {
        id: osdWindow

        readonly property int pillWidth: 56
        readonly property int pillHeight: 180

        // Fenêtre sur toute la hauteur de l'écran, collée à droite — comme
        // la vraie bordure de Caelestia qui longe tout le bord, pas juste
        // une zone autour de la pilule. La pilule elle-même reste centrée
        // verticalement dedans.
        anchors.top: true
        anchors.bottom: true
        anchors.right: true
        // Débordement hors moniteur : doit être strictement plus grand que
        // holeOutset (le cadre commence à pillWidth + holeOutset) pour que
        // ce cadre — et son propre flou d'anti-aliasing — tombe vraiment
        // hors de l'écran physique, pas juste hors de notre zone de clip.
        readonly property int edgeOverhang: 8
        margins.right: -edgeOverhang

        exclusiveZone: 0
        color: "transparent"
        mask: Region {} // ne bloque jamais les clics

        implicitWidth: pillWidth + edgeOverhang

        // La zone de clip doit toujours s'arrêter pile à pillWidth, jamais
        // à la largeur de la fenêtre (qui inclut la marge invisible en
        // plus) — sinon élargir cette marge laisse passer davantage de la
        // bordure dans notre propre rendu au lieu de moins.
        Item {
            x: 0
            y: 0
            width: osdWindow.pillWidth
            height: parent.height
            clip: true // ce qui dépasse à droite (pilule cachée) est invisible

            BlobGroup {
                id: blobGroup
                color: "#ffffff"
                smoothing: 32
            }

            BlobInvertedRect {
                // Bordure invisible — voir quickshell/osd/shell.qml pour le
                // détail complet de cette géométrie (identique ici).
                readonly property int holeOutset: 2
                group: blobGroup
                x: -2000
                y: -200
                width: 2000 + osdWindow.pillWidth + holeOutset + 40
                height: parent.height + 400
                radius: 25
                borderLeft: 0
                borderRight: 40
                borderTop: 0
                borderBottom: 0
            }

            BlobRect {
                id: pill
                group: blobGroup
                width: osdWindow.pillWidth
                height: osdWindow.pillHeight
                anchors.verticalCenter: parent.verticalCenter
                radius: 20
                deformScale: 0.0005

                readonly property real hideOffset: width + blobGroup.smoothing + 20

                // x = hideOffset -> entièrement hors de la zone clippée (caché)
                // x = 0          -> flush avec le bord interne (affiché)
                x: root.shown ? 0 : hideOffset

                Behavior on x {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }

                FilledSlider {
                    width: 35
                    height: 150
                    anchors.centerIn: parent

                    // Codepoints vérifiés directement dans la police
                    // installée (md-brightness_1/4/7 — progression basse/
                    // moyenne/haute officielle de Material Design).
                    icon: (root.brightness < 0.34) ? String.fromCodePoint(0xF00DA)
                          : (root.brightness < 0.67) ? String.fromCodePoint(0xF00DD)
                          : String.fromCodePoint(0xF00E0)
                    value: root.brightness
                    to: 1.0

                    onMoved: root.setBrightness(value)
                }
            }
        }
    }
}
