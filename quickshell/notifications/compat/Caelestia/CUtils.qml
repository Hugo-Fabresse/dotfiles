pragma Singleton
import QtQuick

// Remplace le CUtils du plugin C++ Caelestia (plugin/src/Caelestia/cutils.cpp) —
// seule la fonction réellement utilisée par Content.qml/StateLayer.qml (clamp)
// est reprise ici, en JS pur.
QtObject {
    function clamp(value: real, min: real, max: real): real {
        return Math.max(min, Math.min(max, value));
    }
}
