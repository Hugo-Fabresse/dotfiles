pragma Singleton
import QtQuick

// Valeurs par défaut des propriétés "globales" (CONFIG_GLOBAL_PROPERTY dans
// notifsconfig.hpp) — chez eux partagées entre tous les écrans, ici on n'a
// qu'un écran donc c'est équivalent à Config.
QtObject {
    readonly property QtObject notifs: QtObject {
        // false (pas leur défaut réel, true) : Hugo veut garder le
        // contrôle total sur ses notifs — "elles disparaissent que si je
        // les supprime". Le timer (NotifData.qml) continue de tourner et
        // de se déclencher normalement, il ne fait juste plus rien.
        readonly property bool expire: false
        readonly property int defaultExpireTimeout: 5000
        readonly property int fullscreenExpireTimeout: 2000
        readonly property bool actionOnClick: false
    }
}
