import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

// Notre propre Content.qml — PAS celui de la référence. Leur version
// (ListView + une ClippingRectangle par carte, dimensionnée pile à
// notif.implicitHeight) ronge le bas des coins arrondis dès que la
// bordure de la carte est fine (voir Notification.qml, border.width: 1) :
// le masque de découpe arrondi de la dernière carte perdait sa courbe du
// bas, sans qu'aucune marge de hauteur ne suffise à corriger ça
// proprement. Cette version-ci (ListView standard, sans ClippingRectangle
// par carte) n'a jamais eu ce problème.
//
// Lit Notifs.popups directement (service compat/qs/services/Notifs.qml) —
// pas besoin qu'on nous passe une liste, la fermeture d'une notif
// (NotifData.close()) se retire déjà toute seule de cette liste.
Item {
    id: root

    // -1 = pas de limite (comportement simple : hauteur naturelle, jamais
    // de scroll). Transmis par Wrapper.qml depuis shell.qml, qui est le
    // seul endroit à connaître la vraie contrainte d'écran.
    property int availableHeight: -1

    // Transmis depuis shell.qml (root.shown) : sélectionne la notif du
    // haut (currentIndex: 0) à chaque ouverture — même principe que
    // btnLock.forceActiveFocus() dans session/shell.qml.
    property bool panelShown: false
    onPanelShownChanged: if (panelShown) selectTop()
    // panelShown vaut déjà true dès le lancement (root.shown démarre à
    // true dans shell.qml) — onPanelShownChanged ne se déclenche JAMAIS
    // pour une valeur initiale en QML, seulement sur un vrai changement.
    // Sans ceci, list.forceActiveFocus() n'était donc appelé qu'après une
    // fermeture puis réouverture manuelle (SUPER+P) — jamais au tout
    // premier lancement, d'où les flèches mortes tant qu'on n'avait pas
    // fait au moins un aller-retour de visibilité.
    Component.onCompleted: if (panelShown) selectTop()

    function selectTop() {
        list.currentIndex = 0;
        list.forceActiveFocus();
    }

    // Navigation (Haut/Bas) et actions (Entrée/Retour arrière) = de
    // l'activité, remontée jusqu'à shell.qml pour relancer le repli auto
    // (comme onActiveFocusChanged dans SessionButton.qml).
    signal activity

    readonly property int padding: 12
    // Bande réservée en haut/bas pour les badges "+N" quand ça déborde —
    // la liste elle-même est rétrécie d'autant, donc aucune carte ne peut
    // être rendue dessous.
    readonly property int indicatorBand: 22

    implicitWidth: Tokens.sizes.notifs.width

    readonly property real naturalHeight: {
        const count = list.count;
        if (count === 0)
            return 0;

        let height = (count - 1) * padding;
        for (let i = 0; i < count; i++)
            height += (list.itemAtIndex(i))?.nonAnimHeight ?? 0;

        return height + padding * 2;
    }

    readonly property bool overflowing: availableHeight >= 0 && naturalHeight > availableHeight

    implicitHeight: overflowing ? availableHeight : naturalHeight
    Behavior on implicitHeight {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    ListView {
        id: list

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        anchors.topMargin: root.padding + (root.overflowing ? root.indicatorBand : 0)
        anchors.bottomMargin: root.padding + (root.overflowing ? root.indicatorBand : 0)
        clip: true

        orientation: Qt.Vertical
        spacing: 0
        interactive: root.overflowing

        // Nécessaire pour recevoir les touches — sans ça, Haut/Bas/Entrée/
        // Retour arrière n'arriveraient jamais jusqu'ici (même principe
        // que btnLock.forceActiveFocus() : il faut UN point de départ).
        focus: true
        // Haut/Bas -> currentIndex géré nativement par ListView (aucun
        // code à écrire) ; on relance juste le repli auto à chaque
        // déplacement, comme onActiveFocusChanged dans SessionButton.qml.
        onCurrentIndexChanged: root.activity()

        // Une nouvelle notif est insérée en TÊTE de liste (index 0, donc en
        // haut visuellement). Sans ceci, currentIndex resterait "collé" à
        // la carte qu'il pointait avant (ListView le fait suivre le même
        // item quand des éléments sont insérés devant lui) — la notif du
        // haut ne serait donc PLUS sélectionnée après un nouvel ajout tant
        // que le panneau n'a pas été refermé puis rouvert. On force
        // currentIndex à 0 à chaque changement du nombre de cartes (ajout
        // ou suppression), pour toujours retomber sur la plus récente.
        onCountChanged: if (count > 0) currentIndex = 0

        model: ScriptModel {
            // .filter() convertit la liste QML en vrai tableau JS —
            // ScriptModel.values n'accepte pas une list<NotifData> brute.
            values: Notifs.popups.filter(n => !n.closed)
        }

        delegate: NotifWrapper {}

        move: Transition {
            NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
        }

        displaced: Transition {
            NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic }
        }

        // Haut/Bas gérés à la main : la navigation clavier NATIVE de
        // ListView ne bouge currentIndex que quand "interactive" vaut
        // true, or on le met à false exprès dès que la liste ne déborde
        // pas (root.overflowing) pour couper le scroll à la souris/tactile
        // dans ce cas — ça coupait aussi les flèches avec elle. Bouclé
        // (dernier <-> premier), comme KeyNavigation.up/down dans
        // session/shell.qml.
        //
        // Retour arrière = supprimer la notif sélectionnée (NotifData
        // .close() se retire déjà seule de Notifs.list, rien d'autre à
        // faire ici). Qt.Key_Backspace n'a pas de raccourci dédié du genre
        // "Keys.onBackspacePressed" — on passe par onPressed.
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Up) {
                if (count > 0)
                    currentIndex = (currentIndex - 1 + count) % count;
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                if (count > 0)
                    currentIndex = (currentIndex + 1) % count;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backspace) {
                currentItem?.modelData?.close();
                root.activity();
                event.accepted = true;
            }
        }
        // Entrée/Retour = copier le corps de la notif sélectionnée dans
        // le presse-papiers (même geste que le bouton copier de
        // Notification.qml, mais sans avoir besoin de la souris).
        Keys.onReturnPressed: {
            if (currentItem?.modelData)
                Quickshell.clipboardText = currentItem.modelData.body;
            root.activity();
        }
        Keys.onEnterPressed: {
            if (currentItem?.modelData)
                Quickshell.clipboardText = currentItem.modelData.body;
            root.activity();
        }
    }

    // Port simplifié d'un indicateur de débordement : un badge plat
    // noir/blanc, dans la bande réservée, jamais par-dessus le texte
    // d'une carte.
    ExtraBadge {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: (root.indicatorBand - height) / 2
        count: {
            const scrollY = list.contentY;
            let height = 0;
            for (let i = 0; i < list.count; i++) {
                height += (list.itemAtIndex(i)?.nonAnimHeight ?? 0) + root.padding;
                if (height - root.padding >= scrollY)
                    return i;
            }
            return list.count;
        }
    }

    ExtraBadge {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: (root.indicatorBand - height) / 2
        count: {
            const scrollY = list.contentHeight - (list.contentY + list.height);
            let height = 0;
            for (let i = list.count - 1; i >= 0; i--) {
                height += (list.itemAtIndex(i)?.nonAnimHeight ?? 0) + root.padding;
                if (height - root.padding >= scrollY)
                    return list.count - i - 1;
            }
            return 0;
        }
    }

    component ExtraBadge: Rectangle {
        required property int count

        visible: root.overflowing && count > 0
        width: label.implicitWidth + 12
        height: 18
        radius: 9
        color: "#000000"

        Text {
            id: label
            anchors.centerIn: parent
            text: "+" + parent.count
            color: "#ffffff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.bold: true
        }
    }

    component NotifWrapper: Item {
        id: wrapper

        required property var modelData
        required property int index
        readonly property alias nonAnimHeight: notif.nonAnimHeight
        property int idx

        onIndexChanged: {
            if (index !== -1)
                idx = index;
        }

        implicitWidth: notif.implicitWidth
        implicitHeight: notif.implicitHeight + (idx === 0 ? 0 : root.padding)

        ListView.onRemove: removeAnim.start()

        SequentialAnimation {
            id: removeAnim

            PropertyAction {
                target: wrapper
                property: "ListView.delayRemove"
                value: true
            }
            PropertyAction {
                target: wrapper
                property: "enabled"
                value: false
            }
            PropertyAction {
                target: wrapper
                property: "implicitHeight"
                value: 0
            }
            PropertyAction {
                target: wrapper
                property: "z"
                value: 1
            }
            NumberAnimation {
                target: notif
                property: "x"
                to: (notif.x >= 0 ? root.width : -root.width) * 2
                duration: 200
                easing.type: Easing.OutCubic
            }
            PropertyAction {
                target: wrapper
                property: "ListView.delayRemove"
                value: false
            }
        }

        // PAS de ClippingRectangle ici (contrairement à Content.qml de la
        // référence) — c'est exactement ce composant, dimensionné pile à
        // notif.implicitHeight avec un masque de découpe arrondi, qui
        // rongeait le bas des coins de la dernière carte. Un Item nu ne
        // découpe rien : la carte peut légèrement déborder de sa propre
        // hauteur nominale (son antialiasing, son ombre de bordure) sans
        // que rien ne la rogne.
        Item {
            anchors.top: parent.top
            anchors.topMargin: wrapper.idx === 0 ? 0 : root.padding

            implicitWidth: notif.implicitWidth
            implicitHeight: notif.implicitHeight

            Notification {
                id: notif

                modelData: wrapper.modelData
                // root.width tout court débordait de 2*root.padding (24px)
                // sur la droite — la liste (list) a déjà des marges
                // gauche/droite de root.padding chacune, la carte doit
                // tenir DANS cet espace-là, pas dans la largeur totale.
                implicitWidth: root.width - root.padding * 2
                // ListView.isCurrentItem : propriété injectée automatiquement
                // par ListView sur chaque délégué — pas besoin de la
                // calculer nous-mêmes.
                selected: wrapper.ListView.isCurrentItem
            }
        }
    }
}
