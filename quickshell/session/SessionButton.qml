import QtQuick

// Bouton rond du menu session — même esprit noir/blanc que le reste des
// dotfiles (pas de Material You), inversion simple au survol.
Rectangle {
    id: root

    required property string glyph
    signal activated

    width: 56
    height: 56
    radius: width / 2
    // Même palette que la pilule OSD : fond blanc, icône noire, inversion
    // au survol OU quand le bouton a le focus clavier (navigation flèches).
    color: (mouseArea.containsMouse || root.activeFocus) ? "#000000" : "#ffffff"
    border.width: 1
    border.color: "#33000000"

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Text {
        anchors.centerIn: parent
        text: root.glyph
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 20
        color: (mouseArea.containsMouse || root.activeFocus) ? "#ffffff" : "#000000"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    // Entrée/Espace déclenche le bouton actuellement focus — sans ça,
    // naviguer au clavier permettrait de se déplacer mais pas d'agir.
    Keys.onReturnPressed: root.activated()
    Keys.onEnterPressed: root.activated()
    Keys.onSpacePressed: root.activated()
}
