pragma Singleton
import QtQuick

// Remplace le plugin C++ Caelestia.Config (plugin/src/Caelestia/Config/tokens.hpp) —
// mêmes valeurs numériques exactes (padding/spacing/rounding/durées/courbes
// de bézier M3), recopiées depuis leur source, mais en QML/JS pur : pas de
// fichier de settings modifiable par l'utilisateur comme chez eux, juste les
// valeurs par défaut de leur schéma.
QtObject {
    readonly property QtObject padding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
    }

    readonly property QtObject spacing: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
    }

    readonly property QtObject rounding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
        readonly property int full: 2147483647
        // Pas d'accessibilité "reduce roundness" chez nous -> toujours 1.
        readonly property real scale: 1
    }

    readonly property QtObject fontSize: QtObject {
        readonly property int small: 11
        readonly property int smaller: 12
        readonly property int normal: 13
        readonly property int larger: 15
        readonly property int large: 18
        readonly property int extraLarge: 28
    }

    readonly property QtObject sizes: QtObject {
        readonly property QtObject notifs: QtObject {
            readonly property int width: 430
            readonly property int image: 42
            readonly property int badge: 20
        }
    }

    readonly property QtObject anim: QtObject {
        readonly property QtObject durations: QtObject {
            readonly property int small: 200
            readonly property int normal: 400
            readonly property int large: 600
            readonly property int extraLarge: 1000
            readonly property int expressiveFastSpatial: 350
            readonly property int expressiveDefaultSpatial: 500
            readonly property int expressiveSlowSpatial: 650
            readonly property int expressiveFastEffects: 150
            readonly property int expressiveDefaultEffects: 200
            readonly property int expressiveSlowEffects: 300
        }

        // Courbes M3 exactes (tokens.hpp AnimCurves) : {type: BezierSpline,
        // bezierCurve: [x1,y1,x2,y2,x3,y3, ...]} — QML sait convertir cet
        // objet JS en QEasingCurve pour la propriété groupée "easing" d'une
        // NumberAnimation (voir Anim.qml/AnchorAnim.qml, vendorés tels
        // quels, qui font littéralement "easing: Tokens.anim.X").
        readonly property var emphasized: ({
                type: Easing.BezierSpline,
                bezierCurve: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
            })
        readonly property var emphasizedAccel: ({ type: Easing.BezierSpline, bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1] })
        readonly property var emphasizedDecel: ({ type: Easing.BezierSpline, bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] })
        readonly property var standard: ({ type: Easing.BezierSpline, bezierCurve: [0.2, 0, 0, 1, 1, 1] })
        readonly property var standardAccel: ({ type: Easing.BezierSpline, bezierCurve: [0.3, 0, 1, 1, 1, 1] })
        readonly property var standardDecel: ({ type: Easing.BezierSpline, bezierCurve: [0, 0, 0, 1, 1, 1] })
        readonly property var expressiveFastSpatial: ({ type: Easing.BezierSpline, bezierCurve: [0.42, 1.67, 0.21, 0.9, 1, 1] })
        readonly property var expressiveDefaultSpatial: ({ type: Easing.BezierSpline, bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1] })
        readonly property var expressiveSlowSpatial: ({ type: Easing.BezierSpline, bezierCurve: [0.39, 1.29, 0.35, 0.98, 1, 1] })
        readonly property var expressiveFastEffects: ({ type: Easing.BezierSpline, bezierCurve: [0.31, 0.94, 0.34, 1, 1, 1] })
        readonly property var expressiveDefaultEffects: ({ type: Easing.BezierSpline, bezierCurve: [0.34, 0.8, 0.34, 1, 1, 1] })
        readonly property var expressiveSlowEffects: ({ type: Easing.BezierSpline, bezierCurve: [0.34, 0.88, 0.34, 1, 1, 1] })
    }

    // Pas de vraie police variable Material Symbols pilotée par une chaîne
    // de FontBuilder C++ (plugin/src/Caelestia/Config/fontbuilder.hpp) —
    // mini-builder JS qui accepte la même API fluide (size/weight/vaxes/
    // fill/grade/build) mais les axes variables (vaxes/fill/grade) sont
    // des no-op ici : on n'a pas la police variable Material Symbols avec
    // ses axes FILL/GRAD/opsz/wght pilotables depuis QML sans plugin C++.
    function _fontBuilder(base) {
        return {
            _f: base,
            family: function (f) { return Tokens._fontBuilder(Object.assign({}, this._f, { family: f })); },
            size: function (pt) { return Tokens._fontBuilder(Object.assign({}, this._f, { pointSize: pt })); },
            weight: function (w) { return Tokens._fontBuilder(Object.assign({}, this._f, { weight: w })); },
            italic: function (on) { return Tokens._fontBuilder(Object.assign({}, this._f, { italic: on === undefined ? true : on })); },
            vaxes: function () { return this; },
            fill: function () { return this; },
            grade: function () { return this; },
            build: function () { return this._f; }
        };
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject body: QtObject {
            readonly property font small: ({ family: "JetBrainsMono Nerd Font", pointSize: 9, weight: Font.Normal })
        }
        readonly property QtObject label: QtObject {
            readonly property font medium: ({ family: "JetBrainsMono Nerd Font", pointSize: 10, weight: Font.Medium })
        }
        readonly property QtObject icon: QtObject {
            readonly property font small: ({ family: "Material Symbols Rounded", pointSize: 11 })
            readonly property font medium: ({ family: "Material Symbols Rounded", pointSize: 13 })
            function size(pt) { return Tokens._fontBuilder({ family: "Material Symbols Rounded", pointSize: pt }); }
        }
    }
}
