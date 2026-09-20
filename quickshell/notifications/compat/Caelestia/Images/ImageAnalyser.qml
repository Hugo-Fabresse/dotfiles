import QtQuick

// Remplace le plugin C++ Caelestia.Images (imageanalyser.cpp), qui calcule
// la vraie couleur dominante d'une image pour anti-bander la recoloration
// (Colouriser, dans ColouredIcon.qml, vendoré tel quel). Pas d'analyse
// réelle ici : couleur fixe, ce qui revient à une recoloration plate — le
// seul renoncement visuel de cette couche de compatibilité (tout le reste
// de ColouredIcon.qml/Colouriser.qml est le vrai code de la référence).
QtObject {
    required property Item sourceItem
    readonly property color dominantColour: "#ffffff"

    function requestUpdate(): void {}
}
