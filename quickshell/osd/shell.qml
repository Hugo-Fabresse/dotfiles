import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Caelestia.Blobs

// OSD son + luminosité — une seule pilule partagée au centre du bord droit.
// Affiche le contenu de la dernière source déclenchée (son ou luminosité) ;
// comme les deux ne se déclenchent jamais en même temps, un seul process/
// fenêtre suffit et évite tout problème d'ordre d'empilement entre deux
// fenêtres séparées.

Scope {
    id: root

    // ---------------------------------------------------------------
    // Son (PipeWire)
    // ---------------------------------------------------------------
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property real volume: Pipewire.defaultAudioSink?.audio.volume ?? 0
    readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false

    Connections {
        target: Pipewire.defaultAudioSink?.audio

        function onVolumeChanged() {
            root.activeMode = "volume";
            root.shown = true;
            hideTimer.restart();
        }

        function onMutedChanged() {
            root.activeMode = "volume";
            root.shown = true;
            hideTimer.restart();
        }
    }

    // ---------------------------------------------------------------
    // Luminosité (/sys/class/backlight)
    // ---------------------------------------------------------------
    readonly property string backlightDevice: "amdgpu_bl1"
    readonly property string brightnessPath: "/sys/class/backlight/" + backlightDevice + "/brightness"

    property real maxBrightness: 65535 // écrasé au démarrage par maxBrightnessProc
    property real brightness: 0
    property bool brightnessInitialized: false

    // Lu une seule fois au démarrage (max_brightness ne change jamais).
    Process {
        id: maxBrightnessProc
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
                root.activeMode = "brightness";
                root.shown = true;
                hideTimer.restart();
            } else {
                root.brightnessInitialized = true;
            }
        }
    }

    Process {
        id: setBrightnessProc
        stdout: StdioCollector {}
    }

    function setBrightness(percent) {
        setBrightnessProc.command = ["brightnessctl", "--device=" + backlightDevice, "set", Math.round(percent * 100) + "%", "-q"];
        setBrightnessProc.running = true;
    }

    // ---------------------------------------------------------------
    // État d'affichage partagé
    // ---------------------------------------------------------------
    // "volume" ou "brightness" — la dernière source déclenchée gagne
    // l'affichage de la pilule unique.
    property string activeMode: "volume"
    property bool shown: false

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }

    PanelWindow {
        id: osdWindow

        readonly property int pillWidth: 56
        readonly property int pillHeight: 180

        // Toujours sur l'écran interne du laptop, jamais sur un moniteur
        // externe branché (sinon Quickshell choisit arbitrairement lequel
        // affiche la pilule selon l'ordre de connexion).
        screen: Quickshell.screens.find(s => s.name === "eDP-1") ?? Quickshell.screens[0]

        // Namespace dédié pour cibler cette fenêtre précisément dans la
        // règle de flou Hyprland (layerrule), comme pour wofi/waybar.
        WlrLayershell.namespace: "quickshell-osd"

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
                // Quasiment transparent (même valeur que wofi : rgba(200,
                // 200, 200, 0.01) dans wofi/style.css) — c'est le flou
                // Hyprland qui fait tout le travail visuel, pas la couleur.
                color: Qt.rgba(200 / 255, 200 / 255, 200 / 255, 0.01)
                smoothing: 32
            }

            BlobInvertedRect {
                // La "bordure d'écran" de la référence — sauf que la nôtre
                // est entièrement placée hors de la zone visible de la
                // fenêtre (x >= pillWidth), donc jamais un seul pixel n'en
                // est rendu. Seule son influence de fusion sur la pilule
                // (via blobGroup) reste. Elle longe maintenant TOUTE la
                // hauteur de l'écran, comme la vraie bordure de Caelestia
                // (pas juste une zone locale autour de la pilule).
                // Le trou s'arrête 2px APRÈS pillWidth (pas pile dessus) :
                // le flou d'anti-aliasing du shader déborde d'~1px À
                // L'INTÉRIEUR du bord du trou, donc s'il coïncide exactement
                // avec le bord de la pilule, ce flou reste visible dans notre
                // zone — aucune marge hors écran ne peut le cacher puisqu'il
                // est DANS la zone visible, pas au-delà. En repoussant le
                // trou 2px plus loin, ce flou retombe derrière le bord
                // opaque de la pilule elle-même (x < 56), et le début du
                // cadre (x >= 58) est ensuite masqué par la marge hors écran.
                // Verticalement, le trou dépasse largement des deux côtés :
                // son propre coin arrondi (radius) ne doit jamais coïncider
                // avec le haut/bas de la fenêtre (sinon la courbe du coin
                // devient visible là où la fenêtre se coupe, comme le coin
                // droit avant qu'on l'écarte de l'écran).
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
                // 0 = pas d'étirement/compression façon gélatine pendant le
                // glissement, juste la translation gauche/droite.
                deformScale: 0

                // Le rendu du BlobRect déborde de sa propre largeur/hauteur
                // logique (marge = blobGroup.smoothing, pour le calcul de
                // fusion) — donc "caché" doit pousser plus loin que `width`
                // seul, sinon ce halo reste visible même au repos.
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

                // Le vrai FilledSlider de la référence (copié verbatim dans
                // FilledSlider.qml) — fond + poignée blanche qui se remplit,
                // glyphe -> pourcentage pendant le déplacement. Interactif :
                // on peut aussi glisser dedans pour changer la valeur.
                // Contenu (icône/valeur/action) basculé selon activeMode.
                FilledSlider {
                    width: 35
                    height: 150
                    anchors.centerIn: parent

                    // Codepoints vérifiés directement dans la police
                    // installée — pas devinés, glyphes confirmés
                    // visuellement au préalable (md-volume_* et
                    // md-brightness_1/4/7).
                    icon: root.activeMode === "volume"
                          ? ((root.muted || root.volume < 0.01) ? String.fromCodePoint(0xF075F)
                             : (root.volume < 0.34) ? String.fromCodePoint(0xF057F)
                             : (root.volume < 0.67) ? String.fromCodePoint(0xF0580)
                             : String.fromCodePoint(0xF057E))
                          : ((root.brightness < 0.34) ? String.fromCodePoint(0xF00DA)
                             : (root.brightness < 0.67) ? String.fromCodePoint(0xF00DD)
                             : String.fromCodePoint(0xF00E0))
                    value: root.activeMode === "volume"
                           ? (root.muted ? 0 : root.volume)
                           : root.brightness
                    to: 1.0

                    onMoved: {
                        if (root.activeMode === "volume")
                            Pipewire.defaultAudioSink.audio.volume = value;
                        else
                            root.setBrightness(value);
                    }
                }
            }
        }
    }
}
