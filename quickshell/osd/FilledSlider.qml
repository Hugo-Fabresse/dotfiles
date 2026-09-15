// Copié verbatim depuis components/controls/FilledSlider.qml de
// github.com/caelestia-dots/shell (GPLv3) — même mécanique (Slider template,
// fond + poignée qui se remplit, icône -> pourcentage pendant le drag).
// Seules les valeurs venant de leur système Colours/Tokens (un tout autre
// plugin C++ de theming) et MaterialIcon (police variable Material Symbols)
// sont remplacées par des équivalents statiques, cohérents avec le thème
// noir/blanc du reste des dotfiles. L'ombre (Elevation, dépend d'un module
// tiers non vendoré) est retirée.
import QtQuick
import QtQuick.Templates

Slider {
    id: root

    required property string icon
    property real oldValue
    property bool initialized

    orientation: Qt.Vertical

    background: StyledRect {
        color: "#33ffffff"
        radius: width / 2

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right

            y: root.handle.y
            implicitHeight: parent.height - y

            color: "#ffffff"
            radius: parent.radius
        }
    }

    handle: Item {
        id: handle

        property alias moving: iconText.moving

        y: root.visualPosition * (root.availableHeight - height)
        implicitWidth: root.width
        implicitHeight: root.width

        StyledRect {
            id: rect

            anchors.fill: parent

            color: "#ffffff"
            radius: width / 2
            border.width: 1
            border.color: "#33000000"

            MouseArea {
                id: handleInteraction

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }

            Text {
                id: iconText

                property bool moving

                anchors.centerIn: parent
                text: moving ? Math.round(root.value * 100) : root.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: moving ? 10 : 14
                color: "#000000"

                Behavior on moving {
                    SequentialAnimation {
                        NumberAnimation {
                            target: iconText
                            property: "scale"
                            to: 0.3
                            duration: 90
                            easing.type: Easing.InCubic
                        }
                        PropertyAction {}
                        NumberAnimation {
                            target: iconText
                            property: "scale"
                            to: 1
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    onPressedChanged: handle.moving = pressed

    onValueChanged: {
        if (!initialized) {
            initialized = true;
            return;
        }
        if (Math.abs(value - oldValue) < 0.01)
            return;
        oldValue = value;
        handle.moving = true;
        stateChangeDelay.restart();
    }

    Timer {
        id: stateChangeDelay

        interval: 500
        onTriggered: {
            if (!root.pressed)
                handle.moving = false;
        }
    }

    Behavior on value {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }
}
