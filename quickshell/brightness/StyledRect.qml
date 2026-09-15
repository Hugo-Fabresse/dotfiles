// Copié verbatim depuis components/StyledRect.qml de
// github.com/caelestia-dots/shell (GPLv3), seul CAnim (lié à leur système
// Config) est remplacé par une ColorAnimation statique équivalente.
import QtQuick

Rectangle {
    id: root

    color: "transparent"

    Behavior on color {
        ColorAnimation { duration: 300 }
    }
}
