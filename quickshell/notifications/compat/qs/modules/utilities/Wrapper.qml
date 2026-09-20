import QtQuick

// On n'a pas de panneau "utilities" (module_utilities) dans ce projet —
// stub minimal juste pour que le cast "as Utilities.Wrapper" de
// Content.qml reste résoluble. La branche qui l'utilise ne s'exécute
// jamais ici puisque ScreenState.utilities reste toujours false (voir
// shell.qml).
Item {
    readonly property real nonAnimHeight: 0
}
