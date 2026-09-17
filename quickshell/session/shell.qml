import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Blobs

// Menu session — même pilule/bord fusionné que l'OSD (osd/shell.qml),
// structure et mécanique identiques (BlobGroup/BlobInvertedRect/BlobRect,
// glissement via x + hideOffset, fenêtre pleine hauteur collée au bord
// droit). Seuls changent : le contenu (colonne de boutons au lieu d'un
// FilledSlider), les icônes, et ce que fait chaque interaction (actions
// système au lieu de régler une valeur).

Scope {
    id: root

    // ---------------------------------------------------------------
    // Actions système (remplace le suivi PipeWire/luminosité de l'OSD —
    // ici pas de valeur à suivre, juste des commandes à lancer).
    // ---------------------------------------------------------------
    Process {
        id: actionProc
        stdout: StdioCollector {}
    }

    function runDetached(cmd) {
        actionProc.command = cmd;
        actionProc.running = true;
        root.shown = false;
    }

    // Bascule appelée depuis un bind Hyprland via :
    //   qs -c session ipc call session toggle
    IpcHandler {
        target: "session"

        function toggle(): void {
            root.shown = !root.shown;
        }

        function close(): void {
            root.shown = false;
        }
    }

    // ---------------------------------------------------------------
    // État d'affichage — se referme tout seul après 1.5s, comme l'OSD.
    // onShownChanged se déclenche automatiquement à chaque changement de
    // "shown" (peu importe qui l'a changé : toggle(), close()...), pas
    // besoin de répéter hideTimer.restart() à chaque endroit qui touche
    // shown.
    // ---------------------------------------------------------------
    property bool shown: false

    onShownChanged: {
        if (shown) {
            hideTimer.restart();
            // Donne le focus clavier au premier bouton dès l'ouverture —
            // sans ça, Haut/Bas n'auraient aucun bouton "de départ" à partir
            // duquel naviguer.
            btnLock.forceActiveFocus();
        } else {
            hideTimer.stop();
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }

    PanelWindow {
        id: sessionWindow

        readonly property int pillWidth: 80
        readonly property int pillHeight: 284

        // Toujours sur l'écran interne du laptop, jamais sur un moniteur
        // externe branché.
        screen: Quickshell.screens.find(s => s.name === "eDP-1") ?? Quickshell.screens[0]

        WlrLayershell.namespace: "quickshell-session"
        WlrLayershell.layer: WlrLayer.Overlay
        // Sans ça, la fenêtre ne reçoit jamais les touches du clavier —
        // elles continuent d'aller à la fenêtre qui avait le focus avant
        // l'ouverture du menu. On ne le prend que pendant que le menu est
        // affiché, sinon il resterait bloqué dessus en permanence.
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Fenêtre sur toute la hauteur de l'écran, collée à droite — la
        // pilule elle-même reste centrée verticalement dedans.
        anchors.top: true
        anchors.bottom: true
        anchors.right: true
        readonly property int edgeOverhang: 8
        margins.right: -edgeOverhang

        exclusiveZone: 0
        color: "transparent"

        // Contrairement à l'OSD (toujours cliqué-à-travers, le slider ne
        // se pilote plus à la souris), ici les boutons doivent recevoir
        // les clics : le masque suit la position de la pilule elle-même,
        // donc redevient automatiquement transparent aux clics dès
        // qu'elle glisse hors de la zone visible (repliée).
        mask: Region { item: pill }

        implicitWidth: pillWidth + edgeOverhang

        // La zone de clip doit toujours s'arrêter pile à pillWidth, jamais
        // à la largeur de la fenêtre (qui inclut la marge invisible en
        // plus).
        Item {
            x: 0
            y: 0
            width: sessionWindow.pillWidth
            height: parent.height
            clip: true

            BlobGroup {
                id: blobGroup
                color: "#ffffff"
                smoothing: 32
            }

            BlobInvertedRect {
                // Bordure d'écran — placée hors de la zone visible de la
                // fenêtre, seule son influence de fusion sur la pilule
                // (via blobGroup) reste. Même géométrie que l'OSD.
                readonly property int holeOutset: 2
                group: blobGroup
                x: -2000
                y: -200
                width: 2000 + sessionWindow.pillWidth + holeOutset + 40
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
                width: sessionWindow.pillWidth
                height: sessionWindow.pillHeight
                anchors.verticalCenter: parent.verticalCenter
                radius: 20
                deformScale: 0

                readonly property real hideOffset: width + blobGroup.smoothing + 20

                x: root.shown ? 0 : hideOffset

                Behavior on x {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }

                // Colonne de boutons à la place du FilledSlider — icônes
                // vérifiées directement dans la police installée
                // (rasterisées et inspectées visuellement au préalable) :
                // lock=md-lock, logout=md-logout, power=fa-power_off
                // (md-power_off rendait un cercle vide dans cette police),
                // restart=md-restart.
                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    // KeyNavigation.up/down chaîne les boutons entre eux :
                    // quand celui qui a le focus reçoit Haut/Bas, QML
                    // déplace le focus vers le bouton désigné ici (bouclé :
                    // le dernier renvoie au premier). onActiveFocusChanged
                    // relance hideTimer à chaque déplacement — même principe
                    // que l'OSD (hideTimer.restart() à la source de chaque
                    // activité), sinon le menu se refermerait tout seul en
                    // pleine navigation.
                    SessionButton {
                        id: btnLock
                        glyph: String.fromCodePoint(0xF033E)
                        onActivated: root.runDetached(["hyprlock"])
                        KeyNavigation.up: btnRestart
                        KeyNavigation.down: btnLogout
                        onActiveFocusChanged: if (activeFocus) hideTimer.restart()
                    }

                    SessionButton {
                        id: btnLogout
                        glyph: String.fromCodePoint(0xF0343)
                        onActivated: root.runDetached(["hyprctl", "dispatch", "exit"])
                        KeyNavigation.up: btnLock
                        KeyNavigation.down: btnPower
                        onActiveFocusChanged: if (activeFocus) hideTimer.restart()
                    }

                    SessionButton {
                        id: btnPower
                        glyph: "\uf011"
                        onActivated: root.runDetached(["systemctl", "poweroff"])
                        KeyNavigation.up: btnLogout
                        KeyNavigation.down: btnRestart
                        onActiveFocusChanged: if (activeFocus) hideTimer.restart()
                    }

                    SessionButton {
                        id: btnRestart
                        glyph: String.fromCodePoint(0xF0709)
                        onActivated: root.runDetached(["systemctl", "reboot"])
                        KeyNavigation.up: btnPower
                        KeyNavigation.down: btnLock
                        onActiveFocusChanged: if (activeFocus) hideTimer.restart()
                    }
                }
            }
        }
    }
}
