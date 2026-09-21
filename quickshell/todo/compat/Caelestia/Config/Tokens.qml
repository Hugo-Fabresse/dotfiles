pragma Singleton
import QtQuick

// Contrairement à notifications/compat/Caelestia/Config/Tokens.qml, ce
// module n'est pas le port d'une référence externe (pas de fidélité à
// reproduire) : seules les valeurs réellement utilisées par Content.qml/
// shell.qml sont ici, rien de plus.
QtObject {
    readonly property QtObject sizes: QtObject {
        readonly property QtObject todo: QtObject {
            readonly property int width: 430
        }
    }
}
