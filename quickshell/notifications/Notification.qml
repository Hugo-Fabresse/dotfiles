import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Notifications

// Port de modules/notifications/Notification.qml de
// github.com/caelestia-dots/shell (GPLv3) : glisser pour fermer, anneau de
// progression, bouton copier, actions — réécrit en QtQuick brut — leur
// bibliothèque de composants (StyledRect/StyledText/Colours/Tokens/Config,
// tout le système de couleurs Material You généré depuis le fond d'écran)
// n'existe pas dans ce projet, donc remplacée par des Rectangle/Text
// simples et des couleurs statiques noir/blanc (même esprit que le reste
// des dotfiles — pas de Material You, voir SessionButton.qml).
//
// Contrairement à la référence, PAS de plier/déplier : Hugo veut tout le
// contenu (nom d'appli, titre, corps complet, actions) toujours visible
// d'un coup, plus de mode réduit.
//
// L'anim de sortie (glisser + rétrécir) vit dans Content.qml (NotifWrapper),
// PAS ici — comme la référence : Notification.qml ne gère que son propre
// contenu et son entrée, jamais sa propre disparition du modèle.
//
// Différence assumée par rapport à la référence : PAS d'auto-expire par
// timer (chez eux une notif expire seule sauf "resident"). Hugo veut
// garder le contrôle total : "elles disparaissent que si je les
// supprime" — seuls le swipe, la croix, le clic milieu, ou une fermeture
// distante par l'appli source retirent une notif.
//
// modelData vient de notre service compat/qs/services/NotifData.qml (pas
// l'objet Quickshell.Notification brut) : .close() remplace .dismiss(),
// tout le reste (urgency, actions, hints...) a la même forme.
Rectangle {
    id: root

    required property var modelData
    // Sélection clavier (Haut/Bas dans Content.qml, ListView.isCurrentItem)
    // — inversion noir/blanc complète de la carte, comme SessionButton.qml
    // (color: activeFocus ? noir : blanc). Le texte/icônes doivent suivre
    // pour rester lisibles — voir bg/borderCol/fgPrimary/fgMuted/fgBody
    // ci-dessous, utilisés partout à la place de couleurs figées.
    property bool selected: false

    readonly property color bg: selected ? "#000000" : "#ffffff"
    readonly property color borderCol: selected ? "#33ffffff" : "#33000000"
    readonly property color fgPrimary: selected ? "#ffffff" : "#000000"
    readonly property color fgMuted: selected ? "#aaaaaa" : "#777777"
    readonly property color fgBody: selected ? "#eeeeee" : "#333333"

    // Capturé une fois à la création plutôt que lié en direct à
    // `modelData` : dismiss() peut invalider l'objet pendant l'anim de
    // sortie (gérée par Content.qml, voir NotifWrapper).
    property string summary: ""
    property string body: ""
    property string appName: ""
    property string appIcon: ""
    property string image: ""
    property int urgency: NotificationUrgency.Normal
    property var actionsList: []
    property real progressValue: -1 // hints.value ; -1 = pas de barre de progression
    property date time: new Date()
    property int ageMins: 0

    function snapshot() {
        summary = modelData?.summary ?? "";
        body = modelData?.body ?? "";
        appName = modelData?.appName ?? "";
        appIcon = modelData?.appIcon ?? "";
        image = modelData?.image ?? "";
        urgency = modelData?.urgency ?? NotificationUrgency.Normal;
        actionsList = (modelData?.actions ?? []).filter(a => a.identifier !== "default");
        const v = modelData?.hints?.value;
        progressValue = (v === undefined || v === null) ? -1 : v;
    }

    Component.onCompleted: {
        snapshot();
        // Position initiale hors-champ (implicitWidth valait 0 ici — un
        // Rectangle ne le calcule pas comme un Text, contrairement à ce
        // que la référence suppose avec son propre composant — la carte
        // démarrait donc déjà à x:0, sans rien à animer).
        x = 0;
    }

    Connections {
        target: root.modelData
        function onClosed() {
            root.closed();
        }
    }

    // Fermeture confirmée (signal `closed` du vrai objet Notification) —
    // c'est Content.qml (NotifWrapper) qui écoute ça pour retirer cet objet
    // de root.notifs, immédiatement (comme leur NotifData.close() qui fait
    // Notifs.list = Notifs.list.filter(...) tout de suite, avant même que
    // l'anim de sortie ne joue).
    signal closed

    readonly property bool hasImage: image.length > 0
    readonly property bool hasAppIcon: appIcon.length > 0
    readonly property int bodyTextFormat: /[<*_`#\[\]]/.test(body) ? Text.MarkdownText : Text.PlainText
    readonly property string timeStr: ageMins < 1 ? "now" : ageMins < 60 ? (ageMins + "m") : ageMins < 1440 ? (Math.floor(ageMins / 60) + "h") : (Math.floor(ageMins / 1440) + "d")
    readonly property color accent: urgency === NotificationUrgency.Critical ? "#c0392b" : fgPrimary
    readonly property color accentFg: urgency === NotificationUrgency.Critical ? "#ffffff" : bg
    // Tokens.spacing.small dans la référence (plugin/src/Caelestia/Config/tokens.hpp)
    readonly property int spacingSmall: 8

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.ageMins = Math.floor((Date.now() - root.time.getTime()) / 60000)
    }

    color: bg
    radius: 16
    // Bordure translucide — même esprit que SessionButton.qml : elle suit
    // l'inversion (noire sur fond blanc, blanche sur fond noir) plutôt que
    // de s'épaissir quand la carte est sélectionnée au clavier (voir
    // Content.qml : ListView.isCurrentItem).
    border.width: 1
    border.color: borderCol
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    // La référence utilise "x: implicitWidth" ici, mais implicitWidth vaut
    // 0 pour un Rectangle brut (jamais calculé depuis les enfants comme
    // leur propre composant le suppose) — la carte démarrerait déjà à x:0,
    // sans rien à animer. hideOffset est la vraie valeur "cachée", comme
    // dans osd/shell.qml. C'est un vrai bug de portage à corriger, pas une
    // histoire de fidélité à la référence.
    readonly property real hideOffset: width + 40
    x: hideOffset
    Behavior on x {
        // Même durée que l'OSD/session (osd/shell.qml, session/shell.qml).
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    // Il manquait le spacingSmall entre appNameLabel et bodyText (chacun a
    // pourtant bien un anchors.topMargin: spacingSmall vers l'élément
    // précédent) — la hauteur totale était donc sous-comptée de 8px, ce qui
    // grignotait sur le padding du bas (inner.anchors.margins) puisque le
    // contenu débordait légèrement au-delà de la hauteur calculée.
    // +radius (test) : confirmé par diagnostic (radius:0 -> bord du bas
    // complet, radius:16 -> bord du bas s'efface en s'approchant des
    // coins) que le manque de hauteur du masque de découpe de
    // ClippingRectangle (Content.qml, référence) ronge la COURBE du coin
    // arrondi, pas juste le dernier pixel d'un bord droit — +border.width
    // seul était trop petit face à un rayon de 16px.
    readonly property int cardHeight: summaryRow.implicitHeight + spacingSmall + appNameLabel.implicitHeight + spacingSmall + bodyText.implicitHeight + (actionsRow.visible ? spacingSmall + actionsRow.implicitHeight : 0) + inner.anchors.margins * 2 + radius
    // Utilisé par Content.qml (NotifWrapper) pour calculer sa propre
    // implicitHeight — comme la référence, qui expose ce même nom pour
    // séparer "la vraie taille du contenu" de "implicitHeight", que
    // removeAnim écrase temporairement à 0 pendant la sortie.
    readonly property int nonAnimHeight: cardHeight

    implicitHeight: cardHeight
    Behavior on implicitHeight {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    MouseArea {
        id: dragArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor
        preventStealing: true

        drag.target: root
        drag.axis: Drag.XAxis

        onPressed: event => {
            if (event.button === Qt.MiddleButton)
                root.modelData.close();
        }
        onReleased: event => {
            if (Math.abs(root.x) < root.width * 0.5)
                root.x = 0;
            else
                root.modelData.close();
        }
        onClicked: event => {
            if (event.button === Qt.LeftButton && root.actionsList.length === 1)
                root.actionsList[0].invoke();
        }
    }

    Item {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        // Tokens.padding.medium dans la référence.
        anchors.margins: 12

        implicitHeight: root.cardHeight - inner.anchors.margins * 2

        // ---- icône / image + anneau de progression --------------------
        Item {
            id: iconArea
            // Tokens.sizes.notifs.image dans la référence.
            width: 42
            height: 42
            anchors.top: parent.top
            anchors.left: parent.left

            Rectangle {
                id: iconBox
                anchors.fill: parent
                // Toujours ronde (Tokens.rounding.full), même avec une
                // image — la référence ne fait jamais de coin arrondi
                // "carré" pour l'icône/image.
                radius: width / 2
                color: root.accent
                clip: true

                Image {
                    anchors.fill: parent
                    visible: root.hasImage || root.hasAppIcon
                    source: root.hasImage ? Qt.resolvedUrl(root.image) : (root.hasAppIcon ? Quickshell.iconPath(root.appIcon) : "")
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.hasImage && !root.hasAppIcon
                    text: String.fromCodePoint(0xf129) // fa-info, générique (icône par défaut de la référence)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.bold: true
                    color: root.accentFg
                }
            }

            // Anneau de progression (notifications de type volume/média/
            // téléchargement qui exposent hints.value 0-100).
            Shape {
                visible: root.progressValue >= 0
                anchors.centerIn: parent
                width: parent.width + 6
                height: parent.height + 6
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    capStyle: ShapePath.RoundCap
                    fillColor: "transparent"
                    strokeWidth: 2
                    strokeColor: root.accent

                    PathAngleArc {
                        radiusX: (iconArea.width + 6) / 2 - 1
                        radiusY: (iconArea.height + 6) / 2 - 1
                        centerX: (iconArea.width + 6) / 2
                        centerY: (iconArea.height + 6) / 2
                        startAngle: -90
                        sweepAngle: (Math.max(0, Math.min(100, root.progressValue)) / 100) * 360
                    }
                }
            }
        }

        // ---- ligne d'en-tête : nom de l'appli • heure -------------------
        Item {
            id: summaryRow
            anchors.top: parent.top
            anchors.left: iconArea.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            implicitHeight: Math.max(headerText.implicitHeight, headerButtons.height)

            Text {
                id: headerText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, parent.width - timeSep.implicitWidth - timeText.implicitWidth - headerButtons.width - 24)
                text: root.appName
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: root.fgMuted
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                id: timeText
                anchors.left: headerText.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeStr
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: root.fgMuted
            }

            // Le point sépare l'heure des boutons, plus l'appli/titre de
            // l'heure.
            Text {
                id: timeSep
                anchors.left: timeText.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: root.fgMuted
            }

            // Fermer + copier — à la place de l'ancien bouton déplier,
            // juste à droite du point.
            Row {
                id: headerButtons
                anchors.left: timeSep.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Rectangle {
                    id: closeBtn
                    width: 22
                    height: 22
                    radius: 11
                    color: closeArea.containsMouse ? "#000000" : "#ffffff"
                    border.width: 1
                    border.color: "#33000000"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: String.fromCodePoint(0xf00d) // fa-times
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: closeArea.containsMouse ? "#ffffff" : "#000000"
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modelData.close()
                    }
                }

                Rectangle {
                    id: copyBtn
                    width: 22
                    height: 22
                    radius: 11
                    color: copyArea.containsMouse ? "#000000" : "#ffffff"
                    border.width: 1
                    border.color: "#33000000"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: copyTimer.running ? String.fromCodePoint(0xf00c) : String.fromCodePoint(0xf0c5) // fa-check / fa-copy
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: copyArea.containsMouse ? "#ffffff" : "#000000"
                    }

                    MouseArea {
                        id: copyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.clipboardText = root.body;
                            copyTimer.restart();
                        }
                    }

                    Timer {
                        id: copyTimer
                        interval: 3000
                    }
                }
            }
        }

        // ---- titre en gros ----------------------------------------------
        Text {
            id: appNameLabel
            anchors.top: summaryRow.bottom
            anchors.topMargin: root.spacingSmall
            anchors.left: iconArea.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            text: root.summary
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            color: root.fgPrimary
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        // ---- corps complet ------------------------------------------------
        Text {
            id: bodyText
            anchors.top: appNameLabel.bottom
            anchors.topMargin: root.spacingSmall
            anchors.left: iconArea.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            visible: root.body.length > 0
            height: visible ? implicitHeight : 0
            textFormat: root.bodyTextFormat
            text: root.body
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: root.fgBody
            wrapMode: Text.WordWrap

            onLinkActivated: link => Qt.openUrlExternally(link)
        }

        // ---- actions personnalisées de la notif (fermer/copier sont dans
        // l'en-tête, à côté de l'heure) ------------------------------------
        Row {
            id: actionsRow
            anchors.top: bodyText.bottom
            anchors.topMargin: root.spacingSmall
            anchors.left: iconArea.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            visible: root.actionsList.length > 0
            height: visible ? implicitHeight : 0
            spacing: 4

            Repeater {
                model: root.actionsList

                Rectangle {
                    id: actionBtn
                    required property var modelData

                    width: actionLabel.implicitWidth + 16
                    height: 26
                    radius: 13
                    color: actionArea.containsMouse ? "#000000" : "#ffffff"
                    border.width: 1
                    border.color: "#33000000"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionBtn.modelData.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: actionArea.containsMouse ? "#ffffff" : "#000000"
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: actionBtn.modelData.invoke()
                    }
                }
            }
        }
    }
}
