import QtQuick
import QtQuick.Layouts

// Remplace le ButtonRow du plugin C++ Caelestia.Components
// (plugin/src/Caelestia/Components/buttonrow.cpp) : une rangée où les
// enfants avec `fillWidth: true` se partagent l'espace restant à égalité,
// les autres gardant leur taille naturelle. Implémenté ici avec un
// RowLayout standard + l'attached property Layout.fillWidth posée depuis
// l'extérieur (les boutons eux-mêmes, dans Notification.qml, ne
// connaissent que leur propre `fillWidth`, pas Layout — comme avec le vrai
// composant C++, qui lit la même propriété sans que l'appelant importe
// QtQuick.Layouts).
RowLayout {
    id: root

    Component.onCompleted: sync()
    onChildrenChanged: sync()

    function sync() {
        for (const c of children) {
            if (c.fillWidth !== undefined)
                c.Layout.fillWidth = !!c.fillWidth;
            c.Layout.fillHeight = false;
            c.Layout.alignment = Qt.AlignVCenter;
        }
    }
}
