import QtQuick

// Fin emballage autour de Content.qml — même rôle que notifications/
// Wrapper.qml (ne bloque jamais de clics avec un panneau vide). Pas de
// signal "activity" ici : contrairement aux notifs, le panneau todo n'a
// pas de repli automatique par inactivité (voir shell.qml) — il ne se
// ferme que sur SUPER+T, donc rien à relancer.
Item {
    id: root

    property int availableHeight: -1
    property bool panelShown: false

    visible: height > 0
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Content {
        id: content
        anchors.fill: parent
        availableHeight: root.availableHeight
        panelShown: root.panelShown
    }
}
