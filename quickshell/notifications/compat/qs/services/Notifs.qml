pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Version allégée de leur services/Notifs.qml : le NotificationServer réel
// + la liste "popups" que Content.qml lit directement (Notifs.popups),
// exactement comme la référence. Sans DND, sans persistance disque JSON,
// sans détection plein écran Hyprland (voir NotifData.qml) — ces
// fonctionnalités dépendent de services qu'on n'a pas construits pour ce
// module.
Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> popups: list.filter(n => n.popup)

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;
            const comp = notifComp.createObject(root, {
                popup: true,
                notification: notif
            });
            root.list = [comp, ...root.list];
        }
    }

    IpcHandler {
        target: "notifs"

        function clear(): void {
            for (const notif of root.list.slice())
                notif.close();
        }
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
