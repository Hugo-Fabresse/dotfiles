import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config

// Panneau todo — même mécanique visuelle que notifications/shell.qml
// (fenêtre plein écran, BlobInvertedRect fusionné haut+droite, panneau de
// cartes qui glisse depuis la droite), voir ce fichier pour le détail du
// pourquoi de la géométrie des bordures.
//
// Différences : pas d'ouverture automatique sur nouvel item (une tâche
// s'ajoute depuis LE panneau lui-même, via "a" — pas d'événement externe
// à écouter comme Notifs.onListChanged), donc pas de repli auto par
// inactivité non plus : seul SUPER+T (toggle) contrôle l'état, comme le
// menu session avec SUPER+Escape. Pas de "clearDone" : cocher une tâche la
// supprime déjà elle-même (voir Todo.qml/Todos.qml), il n'y a jamais
// d'accumulation de tâches faites à purger.
Scope {
    id: root

    // Fermé par défaut au lancement (contrairement à notifications qui
    // démarre à `true` mais reste invisible tant qu'il n'y a pas de popup —
    // ici rien n'empêcherait un panneau todo rempli de s'afficher dès la
    // connexion si on démarrait à true).
    property bool shown: false

    IpcHandler {
        target: "todo"

        function toggle(): void {
            root.shown = !root.shown;
        }

        function close(): void {
            root.shown = false;
        }
    }

    PanelWindow {
        id: panel

        readonly property int panelWidth: Tokens.sizes.todo.width + panelBg.inset * 2

        screen: Quickshell.screens.find(s => s.name === "eDP-1") ?? Quickshell.screens[0]

        WlrLayershell.namespace: "quickshell-todo"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        exclusiveZone: 0
        color: "transparent"
        mask: Region { item: root.shown ? panelBg : null }

        BlobGroup {
            id: blobGroup
            color: "#ffffff"
            smoothing: 32
        }

        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -50
            group: blobGroup
            radius: 25
            borderLeft: Config.border.thickness
            borderRight: 49
            borderTop: 49
            borderBottom: Config.border.thickness
        }

        Item {
            x: parent.width - panel.panelWidth
            y: 0
            width: panel.panelWidth
            height: parent.height
            clip: true

            BlobRect {
                id: panelBg
                readonly property int inset: 12
                readonly property real hideOffset: panel.panelWidth + 40

                group: blobGroup
                x: root.shown ? 0 : hideOffset
                Behavior on x {
                    NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                }

                y: 0
                width: panel.panelWidth
                height: inset * 2 + wrapper.height
                radius: 16
                deformScale: 0

                Wrapper {
                    id: wrapper

                    x: panelBg.inset
                    y: panelBg.inset

                    availableHeight: panel.height - panelBg.inset * 2
                    panelShown: root.shown
                }
            }
        }
    }
}
