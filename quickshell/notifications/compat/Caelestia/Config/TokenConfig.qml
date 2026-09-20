pragma Singleton
import QtQuick

// Notification.qml (référence) mélange "Tokens" et "TokenConfig" pour le
// même sous-arbre sizes.notifs — vraisemblablement un reliquat de
// refactor de leur côté. On expose le même sous-ensemble ici pour que le
// fichier reste identique sans le modifier.
QtObject {
    readonly property QtObject sizes: QtObject {
        readonly property QtObject notifs: QtObject {
            readonly property int image: 42
        }
    }
}
