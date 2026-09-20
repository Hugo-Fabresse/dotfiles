import QtQuick

// Fin emballage autour de Content.qml (notre version maison), visible
// seulement s'il a une hauteur — pour ne jamais bloquer de clics avec un
// panneau vide entre deux notifications.
Item {
    id: root

    property int availableHeight: -1
    // Transmis depuis shell.qml (root.shown) : sélectionne la notif du
    // haut à chaque ouverture, comme btnLock.forceActiveFocus() dans le
    // menu session.
    property bool panelShown: false
    // Navigation/action clavier = activité, relance le repli auto côté
    // shell.qml (comme onActiveFocusChanged dans SessionButton.qml).
    signal activity

    visible: height > 0
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Content {
        id: content
        anchors.fill: parent
        availableHeight: root.availableHeight
        panelShown: root.panelShown
        onActivity: root.activity()
    }
}
