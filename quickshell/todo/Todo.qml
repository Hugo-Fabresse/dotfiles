import QtQuick
import qs.services

// Carte d'une tâche — même esprit visuel que notifications/Notification.qml
// (carte noir/blanc, inversion complète quand sélectionnée au clavier,
// bordure translucide qui suit l'inversion) mais adaptée au todo :
// checkbox à cocher au lieu d'icône d'appli, pas d'image/anneau de
// progression/actions custom, pas de glisser-pour-fermer (une tâche est
// une donnée qu'on garde, pas une notif jetable — un swipe accidentel ne
// doit pas pouvoir la supprimer).
//
// Pas de bouton fermer : cocher EST l'action de suppression. startComplete()
// (appelé par le clic sur la checkbox ou par Entrée/Espace dans
// Content.qml) joue une petite séquence — cercle rempli, puis (une fois
// cette anim de couleur terminée) texte barré, puis suppression réelle
// (Todos.remove) une fois qu'on a eu le temps de voir l'état barré. "checked"
// est un état purement visuel local, jamais persisté (voir Todos.qml) :
// dès que Todos.remove() tourne, ce délégué disparaît de toute façon.
//
// Contrairement à Notification.qml, pas de snapshot figé à la création :
// modelData est un objet JS brut (pas un NotifData qui peut se détruire
// pendant une anim de sortie), donc une carte doit refléter EN DIRECT tout
// changement de texte. Seule garde : si modelData devient undefined (la
// tâche vient d'être supprimée du tableau, le délégué joue encore son anim
// de sortie via ListView.delayRemove dans Content.qml), on garde le
// dernier texte connu au lieu d'afficher une carte vide pendant le fondu.
Rectangle {
    id: root

    required property var modelData
    property bool selected: false
    // Coupe l'anim de couleur (Behaviors ci-dessous) juste le temps qu'une
    // nouvelle tâche vole la sélection à celle-ci — Hugo veut que la
    // nouvelle tâche redevienne sélectionnée tout de suite (currentIndex
    // reste forcé à 0 dans Content.qml), mais SANS le fondu noir->blanc
    // visible sur l'ancienne carte sélectionnée. Piloté depuis Content.qml
    // (root.suppressSelectionAnim) pendant ce court instant seulement — la
    // navigation normale au clavier garde son fondu.
    property bool animateSelection: true

    readonly property color bg: selected ? "#000000" : "#ffffff"
    readonly property color borderCol: selected ? "#33ffffff" : "#33000000"
    readonly property color fgPrimary: selected ? "#ffffff" : "#000000"
    readonly property color fgMuted: selected ? "#aaaaaa" : "#777777"

    property string taskText: ""
    property date time: new Date()
    property int ageMins: 0

    // État purement visuel (jamais lu depuis/écrit vers modelData) : voir
    // le commentaire de tête.
    property bool checked: false
    property bool struckOut: false

    function startComplete() {
        if (checked)
            return; // déjà en cours — Entrée/clic répété ne relance rien
        checked = true;
        completeSequence.start();
    }

    SequentialAnimation {
        id: completeSequence
        // Laisse le Behavior on color de la checkbox (120ms) finir de se
        // remplir avant de barrer le texte — sinon les deux anims
        // démarrent pile en même temps et ça fait un seul geste confus au
        // lieu de deux étapes lisibles.
        PauseAnimation { duration: 180 }
        ScriptAction { script: root.struckOut = true }
        // Laisse le temps de VOIR la tâche barrée avant qu'elle disparaisse.
        PauseAnimation { duration: 450 }
        ScriptAction { script: if (root.modelData) Todos.remove(root.modelData.id) }
    }

    function snapshot() {
        if (!modelData)
            return;
        taskText = modelData.text ?? "";
        time = modelData.createdAt ? new Date(modelData.createdAt) : new Date();
        ageMins = Math.floor((Date.now() - time.getTime()) / 60000);
    }

    onModelDataChanged: snapshot()
    Component.onCompleted: snapshot()

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.ageMins = Math.floor((Date.now() - root.time.getTime()) / 60000)
    }

    readonly property string timeStr: ageMins < 1 ? "now" : ageMins < 60 ? (ageMins + "m") : ageMins < 1440 ? (Math.floor(ageMins / 60) + "h") : (Math.floor(ageMins / 1440) + "d")
    readonly property int spacingSmall: 8
    readonly property int checkArea: 42

    color: bg
    radius: 16
    border.width: 1
    border.color: borderCol
    Behavior on color { enabled: root.animateSelection; ColorAnimation { duration: 120 } }
    Behavior on border.color { enabled: root.animateSelection; ColorAnimation { duration: 120 } }

    // Pas de glissement d'entrée (contrairement à Notification.qml) : Hugo
    // ne veut pas voir une nouvelle tâche arriver depuis la droite — elle
    // apparaît directement à sa place (x:0, valeur par défaut d'un Item).
    // "x" reste la propriété que TodoWrapper.removeAnim anime pour la
    // SORTIE (voir Content.qml) — seule l'entrée est retirée ici.

    readonly property int contentHeight: Math.max(checkArea, headerRow.implicitHeight + spacingSmall + taskLabel.implicitHeight)
    readonly property int cardHeight: contentHeight + inner.anchors.margins * 2
    readonly property int nonAnimHeight: cardHeight

    implicitHeight: cardHeight
    Behavior on implicitHeight {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Item {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12

        implicitHeight: root.cardHeight - inner.anchors.margins * 2

        // ---- checkbox --------------------------------------------------
        Item {
            id: checkAreaItem
            width: root.checkArea
            height: root.checkArea
            anchors.top: parent.top
            anchors.left: parent.left

            Rectangle {
                id: checkbox
                anchors.centerIn: parent
                width: 24
                height: 24
                radius: 12
                color: root.checked ? root.fgPrimary : root.bg
                border.width: 1.5
                border.color: root.fgPrimary
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    visible: root.checked
                    text: String.fromCodePoint(0xf00c) // fa-check
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                    color: root.bg
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.startComplete()
                }
            }
        }

        // ---- ligne d'en-tête : heure ------------------------------------
        Item {
            id: headerRow
            anchors.top: parent.top
            anchors.left: checkAreaItem.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            implicitHeight: timeText.implicitHeight

            Text {
                id: timeText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeStr
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: root.fgMuted
            }
        }

        // ---- texte de la tâche -------------------------------------------
        Text {
            id: taskLabel
            anchors.top: headerRow.bottom
            anchors.topMargin: root.spacingSmall
            anchors.left: checkAreaItem.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            text: root.taskText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.strikeout: root.struckOut
            color: root.struckOut ? root.fgMuted : root.fgPrimary
            wrapMode: Text.WordWrap
            // fgPrimary/fgMuted dépendent aussi de root.selected (pas
            // seulement de struckOut) — sans ce garde, le texte de
            // l'ancienne carte sélectionnée continuerait à faire un fondu
            // de couleur même avec le fond (Behavior plus haut) coupé.
            Behavior on color { enabled: root.animateSelection; ColorAnimation { duration: 200 } }
        }
    }
}
