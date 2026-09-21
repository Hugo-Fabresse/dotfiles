pragma Singleton
import QtQuick

QtObject {
    readonly property QtObject border: QtObject {
        // Même valeur que notifications/compat/Caelestia/Config/Config.qml
        // (border.thickness) — l'épaisseur fine des bords non-fusionnés du
        // BlobInvertedRect.
        readonly property int thickness: 10
    }
}
