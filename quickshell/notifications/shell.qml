import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config
import qs.services

// Panneau de notifications — remplace dunst/swaync.
//
// Notification.qml reste notre version maison (style noir/blanc, pas de
// plié/déplié, pas d'auto-expire — voir GlobalConfig.notifs.expire dans
// compat/). Content.qml/Wrapper.qml sont AUSSI notre version maison
// depuis le 2026-09-20 : on a testé la copie identique de la référence
// (ListView + une ClippingRectangle par carte) mais ce mécanisme ronge le
// bas des coins arrondis de la dernière carte dès que la bordure est fine
// (border.width: 1) — aucune marge de hauteur ajoutée ne suffisait à
// corriger ça proprement. Revenu à un Repeater-like (ListView sans
// ClippingRectangle par carte), qui n'a jamais eu ce problème.
//
// Le fond ("panelBg" ci-dessous) est un seul BlobRect dimensionné sur toute
// la zone du panneau — comme leur composant PanelBg dans modules/drawers/
// ContentWindow.qml, il encadre tout le groupe de notifications empilées
// d'un coup, jamais une carte individuellement.
//
// FENÊTRE PLEIN ÉCRAN (comme leur ContentWindow.qml), pas juste la largeur
// du panneau — pour donner au BlobInvertedRect de VRAIES dimensions
// d'écran avec des bordures réelles et proportionnées sur les 4 côtés.
// Fusion sur le HAUT et la DROITE (deux vrais canaux, chacun se relâchant
// là où rien ne le retient : bas pour la droite, gauche pour le haut).
Scope {
    id: root

    // Deux états seulement : ouvert ou fermé. SUPER+P (toggle) est le
    // contrôle manuel — il l'emporte toujours sur l'auto-repli ci-dessous
    // (voir autoHideTimer.stop() dans toggle()/close()).
    property bool shown: true

    // Compte la taille de Notifs.list au dernier changement connu, pour ne
    // réagir qu'aux VRAIS ajouts (une fermeture de notif change aussi la
    // liste, mais ne doit pas rouvrir le panneau). Valeur initiale simple
    // (0, la liste démarre toujours vide) — PAS une liaison vers
    // Notifs.list.length, sinon les deux côtés de la comparaison plus bas
    // changent toujours ensemble et ne sont jamais "supérieur".
    property int lastNotifCount: 0

    // Nouvelle notif reçue -> ouvrir, puis se replier tout seul après
    // 1.5s (la notif reste dans la liste, seul le panneau se cache — SUPER
    // +P le rouvre toujours sur l'historique complet).
    Connections {
        target: Notifs
        function onListChanged() {
            if (Notifs.list.length > root.lastNotifCount) {
                root.shown = true;
                autoHideTimer.restart();
            }
            root.lastNotifCount = Notifs.list.length;
        }
    }

    Timer {
        id: autoHideTimer
        interval: 1500
        onTriggered: root.shown = false
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            root.shown = !root.shown;
            // À l'ouverture (manuelle comme auto) : 1.5s avant repli, remis
            // à zéro par chaque action (flèches/Entrée/Retour arrière, via
            // le signal activity de Wrapper -> onActivity ci-dessous). À la
            // fermeture : plus besoin de compter.
            if (root.shown)
                autoHideTimer.restart();
            else
                autoHideTimer.stop();
        }

        function close(): void {
            autoHideTimer.stop();
            root.shown = false;
        }

        function clear(): void {
            for (const n of Notifs.list.slice())
                n.close();
        }
    }

    PanelWindow {
        id: panel

        // Largeur visuelle du panneau de cartes (pas la largeur de la
        // fenêtre, qui couvre tout l'écran) — Tokens.sizes.notifs.width
        // (430) + notre marge de fusion tout autour (panelBg.inset).
        readonly property int panelWidth: Tokens.sizes.notifs.width + panelBg.inset * 2

        // Toujours sur l'écran interne du laptop, jamais sur un moniteur
        // externe branché — même règle que l'OSD et le menu session.
        screen: Quickshell.screens.find(s => s.name === "eDP-1") ?? Quickshell.screens[0]

        WlrLayershell.namespace: "quickshell-notifications"
        // Overlay pour rester visible par-dessus une fenêtre en plein
        // écran, comme l'OSD et le menu session.
        WlrLayershell.layer: WlrLayer.Overlay
        // Sans ça, la fenêtre ne reçoit jamais les touches du clavier —
        // comme le menu session (session/shell.qml). Pris seulement
        // pendant que le panneau est affiché, jamais en permanence.
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // PLEIN ÉCRAN sur les 4 côtés (comme ContentWindow.qml) — pas
        // seulement top+bottom+right comme avant. exclusiveZone: 0 et le
        // fond transparent font que ça ne bloque rien visuellement ; le
        // mask (plus bas) limite les clics à la zone réelle du panneau.
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        exclusiveZone: 0
        color: "transparent"
        // Toujours mappée, jamais togglée via `visible` — comme l'OSD et le
        // menu session, qui ne cachent jamais leur fenêtre, seulement leur
        // pilule (en interne, via x). Le mask ne couvre que "panelBg" (la
        // zone réelle du panneau, à droite), pas toute la fenêtre plein
        // écran — sinon plus aucun clic ne passerait vers le bureau.
        mask: Region { item: root.shown ? panelBg : null }

        BlobGroup {
            id: blobGroup
            color: "#ffffff"
            smoothing: 32
        }

        BlobInvertedRect {
            // Cadre à VRAIE échelle écran, comme ContentWindow.qml :
            // anchors.fill + une petite marge de débordement (-50, comme
            // chez eux), PAS de x/y bricolés à -2000.
            //
            // borderRight ET borderTop nettement plus épais que les 2
            // autres : chacun crée un vrai CANAL (plat/collé à l'écran sur
            // toute sa longueur), pas juste un coin arrondi. Le canal droit
            // se relâche en BAS (rien ne coince la hauteur de panelBg —
            // coin bas-droit). Le canal du haut doit se relâcher à GAUCHE
            // (rien ne coince la largeur de panelBg de ce côté — coin
            // haut-gauche). borderLeft/Bottom restent fins (juste assez
            // pour ne pas écraser kFrame), sans dominer aucun des deux
            // canaux.
            anchors.fill: parent
            anchors.margins: -50
            group: blobGroup
            radius: 25
            borderLeft: Config.border.thickness
            borderRight: 49
            borderTop: 49
            borderBottom: Config.border.thickness
        }

        // Zone de clip : positionnée à DROITE dans la fenêtre plein écran.
        Item {
            x: parent.width - panel.panelWidth
            y: 0
            width: panel.panelWidth
            height: parent.height
            clip: true // ce qui dépasse (carte cachée) est invisible

            // La liste est un ENFANT de panelBg (pas un frère) — comme le
            // slider de l'OSD est un enfant de sa pilule. Elle hérite ainsi
            // automatiquement du glissement de panelBg (SUPER+P, première
            // notif) sans avoir sa propre animation pour ce cas.
            BlobRect {
                id: panelBg
                // Marge UNIFORME sur les 4 côtés — même logique que la
                // pilule du menu session qui entoure ses boutons avec un
                // espace visible tout autour.
                readonly property int inset: 12
                readonly property real hideOffset: panel.panelWidth + 40
                readonly property bool revealed: root.shown && Notifs.popups.length > 0
                readonly property bool hasNotifs: Notifs.popups.length > 0

                group: blobGroup
                x: revealed ? 0 : hideOffset
                Behavior on x {
                    // Même durée/easing que l'OSD/session et les cartes.
                    NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                }

                y: 0
                width: panel.panelWidth
                height: inset * 2 + wrapper.height
                // Repli différé : le compte passe à 0 -> on masque
                // seulement après hideDelay (le temps que la hauteur finisse
                // de descendre jusqu'au plancher ci-dessus).
                visible: hasNotifs || hideDelay.running
                onHasNotifsChanged: {
                    if (!hasNotifs)
                        hideDelay.restart();
                }
                Timer {
                    id: hideDelay
                    interval: 200
                }
                radius: 16
                deformScale: 0

                Wrapper {
                    id: wrapper

                    x: panelBg.inset
                    y: panelBg.inset

                    // Plafond de hauteur transmis depuis ICI (le seul
                    // endroit qui connaît la vraie contrainte d'écran) —
                    // panel.height = hauteur d'écran (anchors.top +
                    // anchors.bottom), symétrique haut/bas comme le "y:
                    // panelBg.inset" ci-dessus.
                    availableHeight: panel.height - panelBg.inset * 2

                    // Sélectionne la notif du haut à l'ouverture (pareil
                    // que btnLock.forceActiveFocus() dans session/shell.qml).
                    panelShown: root.shown
                    // Naviguer/agir au clavier = de l'activité, comme
                    // onActiveFocusChanged dans SessionButton.qml : ça
                    // relance le repli auto pour ne pas se refermer en
                    // pleine navigation.
                    onActivity: autoHideTimer.restart()
                }
            }
        }
    }
}
