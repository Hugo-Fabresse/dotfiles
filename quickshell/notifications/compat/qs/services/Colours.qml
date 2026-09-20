pragma Singleton
import QtQuick

// Remplace leur moteur Material You (services/Colours.qml, ~800 lignes,
// génère une palette M3 complète depuis le fond d'écran + un cache disque
// JSON). Ici, une palette PLATE reprenant notre esthétique déjà en place
// (cartes blanches, texte/icônes noirs, accent rouge pour le critique —
// voir l'ancien Notification.qml/SessionButton.qml) plutôt que des
// couleurs dynamiques. Seules les clés m3* réellement lues par
// Notification.qml et les composants vendorés (ButtonBase/IconButton/
// TextButton/StateLayer/ExtraIndicator/Elevation) sont fournies.
QtObject {
    id: root

    readonly property bool light: true

    readonly property QtObject palette: QtObject {
        readonly property color m3primary: "#000000"
        readonly property color m3onPrimary: "#ffffff"
        readonly property color m3secondary: "#000000"
        readonly property color m3onSecondary: "#ffffff"
        readonly property color m3secondaryContainer: "#f2f2f2"
        readonly property color m3onSecondaryContainer: "#000000"
        readonly property color m3surfaceContainerHighest: "#e0e0e0"
        readonly property color m3onSurface: "#000000"
        readonly property color m3onSurfaceVariant: "#777777"
        readonly property color m3error: "#c0392b"
        readonly property color m3onError: "#ffffff"
        readonly property color m3tertiary: "#000000"
        readonly property color m3onTertiary: "#ffffff"
        readonly property color m3shadow: "#000000"
    }

    readonly property QtObject tPalette: QtObject {
        readonly property color m3surfaceContainer: "#ffffff"
    }

    // Éclaircit une couleur par palier ("layer") — chez eux un vrai calcul
    // de tonalité M3 sur le fond d'écran ; ici une approximation simple.
    function layer(colour: color, level: int): color {
        return Qt.lighter(colour, 1 + level * 0.15);
    }
}
