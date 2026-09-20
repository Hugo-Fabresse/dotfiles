pragma Singleton
import QtQuick

// Valeurs par défaut de leur schéma (plugin/src/Caelestia/Config/
// notifsconfig.hpp, borderconfig.hpp) pour les propriétés "par écran"
// (CONFIG_PROPERTY) utilisées par Content.qml/Notification.qml.
QtObject {
    readonly property QtObject border: QtObject {
        readonly property int thickness: 10
    }

    readonly property QtObject notifs: QtObject {
        readonly property real clearThreshold: 0.3
        readonly property int expandThreshold: 20
        readonly property bool openExpanded: false
    }
}
