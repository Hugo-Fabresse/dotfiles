pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Notifications
import Caelestia.Config

// Version allégée de leur services/NotifData.qml (253 lignes) : même API
// publique lue par Notification.qml/Content.qml (popup, closed, timeStr,
// timer, lock/unlock, close(), summary/body/appIcon/appName/image/hints/
// urgency/actions) — mais SANS la détection plein écran Hyprland, l'i18n,
// le cache disque d'images et la persistance JSON entre redémarrages, qui
// dépendent de services qu'on n'a pas construits ici (Hypr.qml, Tr.qml,
// Paths.qml...). L'auto-expire par timer, lui, EST repris (Hugo l'a
// explicitement redemandé pour ce test à l'identique).
QtObject {
    id: notif

    property bool popup: true
    property bool closed: false
    property var locks: new Set()

    property date time: new Date()
    property int ageMins: 0
    readonly property string timeStr: {
        if (ageMins < 1)
            return "now";
        const h = Math.floor(ageMins / 60);
        const d = Math.floor(h / 24);
        if (d > 0)
            return d + "d";
        if (h > 0)
            return h + "h";
        return ageMins + "m";
    }

    readonly property Timer timeStrTimer: Timer {
        running: !notif.closed
        repeat: true
        interval: 5000
        onTriggered: notif.updateTimeStr()
    }

    property Notification notification
    property string notificationId
    property string summary
    property string body
    property string appIcon
    property string appName
    property string image
    property var hints
    property real expireTimeout: GlobalConfig.notifs.defaultExpireTimeout
    property int urgency: NotificationUrgency.Normal
    property bool resident
    property list<var> actions

    readonly property Timer timer: Timer {
        running: true
        interval: notif.expireTimeout > 0 ? notif.expireTimeout : GlobalConfig.notifs.defaultExpireTimeout
        onTriggered: {
            if (GlobalConfig.notifs.expire)
                notif.popup = false;
        }
    }

    readonly property Connections conn: Connections {
        target: notif.notification

        function onSummaryChanged(): void { notif.summary = notif.notification.summary; }
        function onBodyChanged(): void { notif.body = notif.notification.body; }
        function onAppIconChanged(): void { notif.appIcon = notif.notification.appIcon; }
        function onAppNameChanged(): void { notif.appName = notif.notification.appName; }
        function onImageChanged(): void { notif.image = notif.notification.image; }
        function onExpireTimeoutChanged(): void { notif.expireTimeout = notif.notification.expireTimeout; }
        function onUrgencyChanged(): void { notif.urgency = notif.notification.urgency; }
        function onResidentChanged(): void { notif.resident = notif.notification.resident; }
        function onHintsChanged(): void { notif.hints = notif.notification.hints; }
        function onActionsChanged(): void {
            notif.actions = notif.notification.actions.map(a => ({
                        identifier: a.identifier,
                        text: a.text,
                        invoke: () => a.invoke()
                    }));
        }
        function onClosed(): void { notif.close(); }
    }

    function updateTimeStr(): void {
        const diff = Date.now() - time.getTime();
        ageMins = Math.floor(diff / 60000);
    }

    function lock(item): void {
        locks.add(item);
    }

    function unlock(item): void {
        locks.delete(item);
        if (closed)
            close();
    }

    function close(): void {
        closed = true;
        if (locks.size === 0 && Notifs.list.includes(notif)) {
            Notifs.list = Notifs.list.filter(n => n !== notif);
            notification?.dismiss();
            notif.destroy();
        }
    }

    Component.onCompleted: {
        if (!notification)
            return;

        notificationId = notification.id;
        summary = notification.summary;
        body = notification.body;
        appIcon = notification.appIcon;
        appName = notification.appName;
        image = notification.image;
        expireTimeout = notification.expireTimeout;
        hints = notification.hints;
        urgency = notification.urgency;
        resident = notification.resident;
        actions = notification.actions.map(a => ({
                    identifier: a.identifier,
                    text: a.text,
                    invoke: () => a.invoke()
                }));
    }
}
