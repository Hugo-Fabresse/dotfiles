import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

// Squelette (ListView + overflow badges + Wrapper autour de chaque carte)
// copié depuis notifications/Content.qml (voir ce fichier pour le détail
// de pourquoi c'est un ListView nu, sans ClippingRectangle par carte).
// Différences propres au todo :
//   - lit Todos.items (tout le tableau, pas un sous-ensemble "popups" —
//     une tâche supprimée est retirée du tableau tout de suite par
//     Todo.qml/Todos.remove(), il n'y a pas d'état "closed" intermédiaire)
//   - Entrée/Espace = cocher la tâche sélectionnée, ce qui la supprime
//     après une animation (voir Todo.qml:startComplete) — pas de copier
//     dans le presse-papiers comme pour les notifs, ça n'a pas de sens ici
//   - Espace ouvre un champ de saisie en haut du panneau pour ajouter une
//     tâche ; Entrée valide, Échap annule (voir addBar plus bas)
Item {
    id: root

    property int availableHeight: -1

    property bool panelShown: false
    onPanelShownChanged: {
        if (panelShown)
            selectTop();
        else
            cancelAdd();
    }
    Component.onCompleted: if (panelShown) selectTop()

    property bool adding: false

    // Coupe le fondu noir->blanc de sélection (Todo.qml:animateSelection)
    // pendant l'instant où une nouvelle tâche vole la sélection à
    // l'ancienne (voir onCountChanged plus bas) — la navigation normale au
    // clavier garde son fondu, elle ne passe jamais par ce flag.
    property bool suppressSelectionAnim: false

    // Coupe l'anim de hauteur du panneau (Behavior on implicitHeight plus
    // bas) et le repositionnement animé des cartes (move/displaced de
    // ListView) au moment précis de commitAdd(). Idée de Hugo : la carte
    // brouillon (addBar) réserve déjà exactement la place que la vraie
    // tâche va occuper une fois créée — animer quoi que ce soit à cet
    // instant-là, c'est recalculer une position déjà correcte, ce qui
    // provoquait un "pop" (tout remonte d'un coup puis redescend se
    // replacer) au lieu d'un remplacement silencieux du brouillon par la
    // vraie carte.
    property bool suppressLayoutAnim: false

    function selectTop() {
        list.currentIndex = 0;
        list.forceActiveFocus();
    }

    function startAdd() {
        adding = true;
        addField.text = "";
        addField.forceActiveFocus();
    }

    function cancelAdd() {
        adding = false;
        addField.text = "";
        list.forceActiveFocus();
    }

    function commitAdd() {
        suppressLayoutAnim = true;
        Todos.add(addField.text);
        cancelAdd();
        Qt.callLater(() => root.suppressLayoutAnim = false);
    }

    readonly property int padding: 12
    readonly property int indicatorBand: 22
    // Hauteur réservée au champ d'ajout (carte + marge au-dessus de la
    // liste) quand il est ouvert — 0 sinon. addBar.height suit maintenant
    // le texte tapé (wrapMode: WordWrap, comme une vraie carte), donc
    // cette hauteur n'est plus fixe : elle grandit avec la tâche en cours
    // de saisie.
    readonly property int addFieldHeight: adding ? addBar.height + padding : 0

    implicitWidth: Tokens.sizes.todo.width

    // Contrairement à notifications/Content.qml (0 notif = rien à montrer,
    // le panneau reste invisible), un panneau todo vide doit quand même
    // réserver la hauteur du message "No tasks…" — sinon Wrapper.qml
    // (visible: height > 0) masque tout le panneau, y compris le champ
    // d'ajout, dès qu'il ne reste plus aucune tâche.
    readonly property int emptyStateHeight: 24

    // list.count chute dès que Todos.remove() tourne (Todo.qml,
    // startComplete) — AVANT que le glissement de sortie de la carte
    // (TodoWrapper.removeAnim, 200ms) n'ait fini de jouer, puisque
    // ListView.onRemove ne fait que garder le délégué en vie
    // (ListView.delayRemove), pas grandir "count". Si on rétrécissait le
    // panneau tout de suite sur cette valeur, le ListView (clip: true)
    // couperait la carte en plein vol — c'est ce qui donnait l'impression
    // qu'une tâche "part plus vite" qu'une notif : on ne voyait jamais la
    // fin du glissement, juste le panneau qui se refermait dessus. On
    // retient donc la hauteur précédente le temps que le glissement se
    // termine (durée du NumberAnimation de TodoWrapper.removeAnim),
    // seulement quand la hauteur DIMINUE — un ajout doit rester instantané.
    readonly property real rawListHeight: {
        const count = list.count;
        if (count === 0)
            return adding ? 0 : emptyStateHeight;

        let height = (count - 1) * padding;
        for (let i = 0; i < count; i++)
            height += (list.itemAtIndex(i))?.nonAnimHeight ?? 0;

        return height + padding * 2;
    }

    property real heldListHeight: rawListHeight
    onRawListHeightChanged: {
        if (rawListHeight < heldListHeight)
            shrinkDelay.restart();
        else {
            shrinkDelay.stop();
            heldListHeight = rawListHeight;
        }
    }
    Timer {
        id: shrinkDelay
        interval: 220 // >= la durée du slide de sortie (200ms)
        onTriggered: root.heldListHeight = root.rawListHeight
    }

    readonly property real naturalListHeight: heldListHeight

    readonly property bool overflowing: availableHeight >= 0 && (naturalListHeight + addFieldHeight) > availableHeight
    readonly property real listAreaHeight: overflowing ? Math.max(0, availableHeight - addFieldHeight) : naturalListHeight

    implicitHeight: addFieldHeight + listAreaHeight
    Behavior on implicitHeight {
        enabled: !root.suppressLayoutAnim
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    // ---- champ d'ajout d'une tâche --------------------------------------
    // Habillée exactement comme une vraie carte Todo.qml (cercle à cocher
    // désactivé, "now" à la place de l'âge, même grille checkArea/
    // spacingSmall/radius/couleurs) plutôt qu'une simple barre de recherche
    // — Hugo veut voir la future tâche prendre forme pendant qu'il tape,
    // pas remplir un champ générique. Pas de composant partagé avec
    // Todo.qml : celui-ci exige un modelData réel (required property), et
    // cette carte-ci n'en a pas encore (la tâche n'existe qu'à la
    // validation, voir commitAdd()) — dupliquer ces ~50 lignes de style
    // évite d'entortiller Todo.qml avec un mode "brouillon" conditionnel.
    Rectangle {
        id: addBar
        visible: root.adding
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.padding
        height: addBarInner.implicitHeight + addBarInner.anchors.margins * 2
        Behavior on height {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        radius: 16
        color: "#ffffff"
        border.width: 1
        border.color: "#33000000"

        Item {
            id: addBarInner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            implicitHeight: Math.max(42, addBarHeader.implicitHeight + 8 + addField.implicitHeight)

            // Cercle purement décoratif : la tâche n'existe pas encore,
            // rien à cocher tant qu'on n'a pas validé.
            Item {
                id: addCheckArea
                width: 42
                height: 42
                anchors.top: parent.top
                anchors.left: parent.left

                Rectangle {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    radius: 12
                    color: "#ffffff"
                    border.width: 1.5
                    border.color: "#000000"
                }
            }

            Item {
                id: addBarHeader
                anchors.top: parent.top
                anchors.left: addCheckArea.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                implicitHeight: addTimeText.implicitHeight

                Text {
                    id: addTimeText
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    // Vraie tâche créée seulement à la validation (Todos.add
                    // dans commitAdd()) — "now" est donc toujours exact tant
                    // que ce brouillon est affiché.
                    text: "now"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: "#777777"
                }
            }

            Text {
                anchors.top: addBarHeader.bottom
                anchors.topMargin: 8
                anchors.left: addCheckArea.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                visible: addField.text.length === 0
                text: "New task… (Esc to cancel)"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: "#999999"
                wrapMode: Text.WordWrap
            }

            TextInput {
                id: addField
                anchors.top: addBarHeader.bottom
                anchors.topMargin: 8
                anchors.left: addCheckArea.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: "#000000"
                wrapMode: TextInput.WordWrap

                Keys.onEscapePressed: root.cancelAdd()
                Keys.onReturnPressed: root.commitAdd()
                Keys.onEnterPressed: root.commitAdd()
            }
        }
    }

    // ---- état vide --------------------------------------------------------
    Text {
        visible: list.count === 0 && !root.adding
        anchors.top: parent.top
        anchors.topMargin: root.addFieldHeight + root.padding + 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: "No tasks — press Space to add one"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: "#999999"
    }

    ListView {
        id: list

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        anchors.topMargin: root.addFieldHeight + root.padding + (root.overflowing ? root.indicatorBand : 0)
        anchors.bottomMargin: root.padding + (root.overflowing ? root.indicatorBand : 0)
        clip: true

        orientation: Qt.Vertical
        spacing: 0
        interactive: root.overflowing

        focus: true

        // Une tâche ajoutée arrive en tête (Todos.add prépend) — on
        // retombe toujours dessus, même logique que Notifs (nouvelle notif
        // en tête). Le changement de sélection lui-même reste instantané
        // (suppressSelectionAnim coupe le fondu noir->blanc, voir
        // Todo.qml:animateSelection) : Hugo veut bien que la nouvelle
        // tâche redevienne la sélection, mais sans voir l'ancienne carte
        // faire un fondu de couleur qu'il n'a pas demandé.
        onCountChanged: {
            if (count > 0) {
                root.suppressSelectionAnim = true;
                currentIndex = 0;
                Qt.callLater(() => root.suppressSelectionAnim = false);
            }
        }

        model: ScriptModel {
            values: Todos.items
        }

        delegate: TodoWrapper {}

        // NumberAnimation n'a pas de propriété "enabled" (seul Behavior en
        // a une) — on coupe l'anim en mettant duration à 0 le temps de
        // commitAdd() plutôt que de désactiver l'animation elle-même.
        move: Transition {
            NumberAnimation {
                property: "y"
                duration: root.suppressLayoutAnim ? 0 : 200
                easing.type: Easing.OutCubic
            }
        }

        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: root.suppressLayoutAnim ? 0 : 200
                easing.type: Easing.OutCubic
            }
        }

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
                if (currentItem?.modelData)
                    Todos.remove(currentItem.modelData.id);
                event.accepted = true;
            }
        }
        // Entrée = cocher la tâche sélectionnée (coche le cercle, barre le
        // texte, puis la supprime — voir Todo.qml:startComplete — à la
        // place du "copier dans le presse-papiers" de Content.qml des
        // notifs, qui n'a pas de sens ici).
        Keys.onReturnPressed: currentItem?.requestComplete()
        Keys.onEnterPressed: currentItem?.requestComplete()
        // Espace = ouvrir le champ d'ajout (plus "a" — Espace est plus
        // proche naturellement du geste "ajouter" que la lettre A).
        Keys.onSpacePressed: root.startAdd()
    }

    // Indicateurs de débordement "+N" — identiques à notifications/
    // Content.qml (voir ce fichier pour le détail du calcul).
    ExtraBadge {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: root.addFieldHeight + (root.indicatorBand - height) / 2
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

    component TodoWrapper: Item {
        id: wrapper

        required property var modelData
        required property int index
        readonly property alias nonAnimHeight: todo.nonAnimHeight
        property int idx

        function requestComplete() {
            todo.startComplete();
        }

        onIndexChanged: {
            if (index !== -1)
                idx = index;
        }

        implicitWidth: todo.implicitWidth
        implicitHeight: todo.implicitHeight + (idx === 0 ? 0 : root.padding)

        ListView.onRemove: removeAnim.start()

        SequentialAnimation {
            id: removeAnim

            PropertyAction { target: wrapper; property: "ListView.delayRemove"; value: true }
            PropertyAction { target: wrapper; property: "enabled"; value: false }
            PropertyAction { target: wrapper; property: "implicitHeight"; value: 0 }
            PropertyAction { target: wrapper; property: "z"; value: 1 }
            NumberAnimation {
                target: todo
                property: "x"
                to: (todo.x >= 0 ? root.width : -root.width) * 2
                duration: 200
                easing.type: Easing.OutCubic
            }
            PropertyAction { target: wrapper; property: "ListView.delayRemove"; value: false }
        }

        Item {
            anchors.top: parent.top
            anchors.topMargin: wrapper.idx === 0 ? 0 : root.padding

            implicitWidth: todo.implicitWidth
            implicitHeight: todo.implicitHeight

            Todo {
                id: todo

                modelData: wrapper.modelData
                implicitWidth: root.width - root.padding * 2
                selected: wrapper.ListView.isCurrentItem
                animateSelection: !root.suppressSelectionAnim
            }
        }
    }
}
