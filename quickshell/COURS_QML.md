# Cours QML — à partir du code réel de l'OSD et du menu session

Ce cours explique **tout** ce qui a été utilisé dans `quickshell/osd/` et
`quickshell/session/` : la syntaxe QML de base, le framework Quickshell
(fenêtres, IPC, process shell...), et le plugin custom `Caelestia.Blobs`.
Chaque section renvoie à du code réel de ton projet.

---

## Sommaire

1. [Qu'est-ce que QML](#1-quest-ce-que-qml)
2. [Anatomie d'un fichier .qml](#2-anatomie-dun-fichier-qml)
3. [Les properties](#3-les-properties)
4. [Les bindings (liaisons réactives)](#4-les-bindings-liaisons-réactives)
5. [Les signaux et leurs handlers](#5-les-signaux-et-leurs-handlers)
6. [Behavior et Animation](#6-behavior-et-animation)
7. [Le système d'anchors (ancrage)](#7-le-système-danchors-ancrage)
8. [Les composants réutilisables (fichiers .qml séparés)](#8-les-composants-réutilisables)
9. [Les types Qt Quick de base](#9-les-types-qt-quick-de-base)
10. [Slider (QtQuick.Templates) — la mécanique du FilledSlider](#10-slider-qtquicktemplates)
11. [Le JavaScript intégré dans QML](#11-le-javascript-intégré-dans-qml)
12. [Quickshell : Scope et PanelWindow](#12-quickshell--scope-et-panelwindow)
13. [Quickshell.Wayland : layer-shell et fullscreen](#13-quickshellwayland--layer-shell-et-fullscreen)
14. [Quickshell.Io : Process, FileView, IpcHandler](#14-quickshellio--process-fileview-ipchandler)
15. [Quickshell.Services.Pipewire](#15-quickshellservicespipewire)
16. [Le masque d'input : Region](#16-le-masque-dinput-region)
17. [Caelestia.Blobs : le plugin de fusion metaball](#17-caelestiablobs--le-plugin-de-fusion-metaball)
18. [Walkthrough complet : osd/shell.qml](#18-walkthrough-complet--osdshellqml)
19. [Walkthrough complet : session/shell.qml](#19-walkthrough-complet--sessionshellqml)
20. [Glossaire](#20-glossaire)

---

## 1. Qu'est-ce que QML

QML (Qt Modeling Language) est un langage **déclaratif** : au lieu d'écrire
des instructions ("crée un rectangle, puis mets sa couleur, puis ajoute-le à
la fenêtre"), tu **décris une arborescence d'objets** et leurs propriétés,
et le moteur QML se charge de construire et maintenir cette arborescence à
jour.

Différence avec du code impératif (JS, Python...) :

```js
// Impératif : tu dis COMMENT faire, étape par étape
let rect = new Rectangle();
rect.color = "red";
rect.width = 100;
window.addChild(rect);
```

```qml
// Déclaratif : tu décris CE QUE tu veux, l'arbre final
Rectangle {
    color: "red"
    width: 100
}
```

Le gros avantage : les propriétés peuvent être des **expressions** qui se
recalculent toutes seules quand leurs dépendances changent (voir
[§4 Bindings](#4-les-bindings-liaisons-réactives)). C'est ce qui permet à
ton OSD de changer de couleur/position juste parce qu'une variable a changé,
sans jamais écrire "redessine-toi maintenant".

QML est utilisé par Qt Quick (interfaces graphiques Qt) et, dans ton cas,
par **Quickshell**, qui ajoute des types spécifiques pour construire des
shells Wayland (barres, OSD, popups...).

---

## 2. Anatomie d'un fichier .qml

Regarde le début de `osd/shell.qml` :

```qml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Caelestia.Blobs

Scope {
    id: root
    // ...
}
```

- **`import`** : charge un module de types. Chaque `import` rend disponibles
  de nouveaux mots-clés/types (ex : `import Quickshell.Io` donne accès à
  `Process`, `FileView`, `IpcHandler`).
- **Un seul objet racine** : un fichier .qml décrit toujours **un seul**
  objet au niveau supérieur (ici `Scope { ... }`). Tout le reste est niché
  dedans.
- **`id: root`** : donne un nom à l'objet, utilisable partout dans le
  fichier pour le référencer (`root.shown`, `root.volume`, etc.). `id`
  n'est **pas** une string — pas de guillemets, et il doit être unique dans
  le fichier.
- **Les accolades `{ }`** définissent la hiérarchie parent/enfant. Tout ce
  qui est entre les `{ }` d'un objet est soit une **property** (`clé:
  valeur`), soit un **objet enfant**.
- **Commentaires** : `//` pour une ligne, `/* ... */` pour un bloc — comme
  en JS/C++.

---

## 3. Les properties

Une property est un attribut de l'objet. Syntaxe : `nom: valeur`.

```qml
Rectangle {
    width: 100        // property intégrée à Rectangle
    color: "#ffffff"  // idem
}
```

### Déclarer tes propres properties

Tu peux ajouter des properties qui n'existent pas nativement, avec le
mot-clé `property` :

```qml
// osd/shell.qml
property string activeMode: "volume"
property bool shown: false
```

Syntaxe : `property <type> <nom>: <valeur initiale>`. Types courants : `int`,
`real`, `string`, `bool`, `var` (n'importe quoi), ou un type d'objet
(`QtObject`, etc.).

### `readonly property`

Une property qui ne peut être définie qu'une fois (à la déclaration), pas
réassignée ensuite depuis l'extérieur :

```qml
// osd/shell.qml
readonly property int pillWidth: 56
readonly property int pillHeight: 180
```

Utile pour des constantes de config qui ne doivent pas bouger — ici, les
dimensions fixes de la pilule.

### `required property`

Utilisé dans un **composant réutilisable** (voir §8) pour dire "qui utilise
ce composant DOIT fournir cette valeur" :

```qml
// SessionButton.qml
required property string glyph
```

Si tu oublies `glyph:` quand tu instancies `SessionButton { }`, QML lève une
erreur au chargement — ça évite les oublis silencieux.

---

## 4. Les bindings (liaisons réactives)

C'est **le** concept le plus important de QML. Quand tu écris :

```qml
x: root.shown ? 0 : hideOffset
```

Ce n'est **pas** une assignation unique — c'est un **binding** : QML
mémorise cette expression, et la **réévalue automatiquement** à chaque fois
qu'une de ses dépendances (ici `root.shown`) change. Tu n'as jamais besoin
d'écrire "quand shown change, recalcule x" : c'est implicite, tant que tu
utilises la syntaxe `propriété: expression`.

Exemple concret dans `FilledSlider.qml` :

```qml
color: mouseArea.containsMouse ? "#000000" : "#ffffff"
```

Cette ligne se réévalue toute seule à chaque survol/sortie de souris, parce
que `mouseArea.containsMouse` change.

Autre exemple, dans le slider de l'OSD :

```qml
icon: root.activeMode === "volume"
      ? ((root.muted || root.volume < 0.01) ? String.fromCodePoint(0xF075F)
         : (root.volume < 0.34) ? String.fromCodePoint(0xF057F)
         : (root.volume < 0.67) ? String.fromCodePoint(0xF0580)
         : String.fromCodePoint(0xF057E))
      : ((root.brightness < 0.34) ? String.fromCodePoint(0xF00DA)
         : (root.brightness < 0.67) ? String.fromCodePoint(0xF00DD)
         : String.fromCodePoint(0xF00E0))
```

Un seul binding, mais il dépend de `activeMode`, `muted` et `volume` (ou
`brightness`) — dès que N'IMPORTE LAQUELLE de ces valeurs change, l'icône se
recalcule. C'est pour ça qu'on n'a jamais eu besoin d'écrire de code
"écoute le volume et change l'icône" à la main : le binding fait tout.

> **Piège à connaître** : si tu assignes une valeur avec `=` dans du code
> JavaScript (dans une `function`), ce n'est **pas** un binding, c'est une
> affectation ponctuelle classique. Les bindings n'existent que dans la
> syntaxe déclarative `propriété: expression`.

---

## 5. Les signaux et leurs handlers

Un **signal** est émis quand quelque chose se produit. Un **handler**
(toujours nommé `onNomDuSignal`) réagit à ce signal.

### Signaux intégrés

```qml
// SessionButton.qml
MouseArea {
    onClicked: root.activated()
}
```

`MouseArea` a un signal intégré `clicked`, et `onClicked:` est son handler.

### Déclarer ton propre signal

```qml
// SessionButton.qml
signal activated
```

Puis on l'émet en l'appelant comme une fonction : `root.activated()`. Celui
qui utilise le composant peut alors écouter ce signal :

```qml
// session/shell.qml
SessionButton {
    glyph: String.fromCodePoint(0xF033E)
    onActivated: root.runDetached(["hyprlock"])
}
```

### `Connections` — écouter un objet externe

Pour écouter les signaux d'un objet que tu ne contrôles pas directement
(ici, l'état audio de PipeWire), on utilise `Connections` :

```qml
// osd/shell.qml
Connections {
    target: Pipewire.defaultAudioSink?.audio

    function onVolumeChanged() {
        root.activeMode = "volume";
        root.shown = true;
        hideTimer.restart();
    }

    function onMutedChanged() {
        // ...
    }
}
```

- `target:` = l'objet à écouter.
- Chaque fonction `onXChanged()` réagit au signal `XChanged` de `target`.
  (Qt génère automatiquement un signal `xxxChanged` pour toute property
  nommée `xxx` — c'est ce qui permet aux bindings de fonctionner.)
- `?.` = **optional chaining** JS classique : si `Pipewire.defaultAudioSink`
  est `null`/`undefined`, l'expression entière vaut `undefined` au lieu de
  planter.

---

## 6. Behavior et Animation

Un `Behavior` dit : "quand cette property change de valeur, au lieu de
sauter instantanément à la nouvelle valeur, anime la transition."

```qml
// osd/shell.qml — la pilule glisse au lieu d'apparaître d'un coup
x: root.shown ? 0 : hideOffset

Behavior on x {
    NumberAnimation {
        duration: 280
        easing.type: Easing.OutCubic
    }
}
```

- `Behavior on <property>` s'attache à une property précise.
- Dedans, le type d'animation dépend du type de la property :
  `NumberAnimation` (int/real), `ColorAnimation` (couleurs), etc.
- `duration` en millisecondes, `easing.type` = la courbe d'accélération
  (`Easing.OutCubic` = démarre vite, ralentit en douceur à l'arrivée —
  très utilisé pour un slide qui a l'air "naturel").

Autre exemple, `StyledRect.qml` :

```qml
Rectangle {
    color: "transparent"

    Behavior on color {
        ColorAnimation { duration: 300 }
    }
}
```

N'importe quel changement de `color` sur ce rectangle sera fondu sur
300ms au lieu d'être instantané.

Il existe aussi des animations plus complexes, comme dans le handle du
slider (`FilledSlider.qml`) :

```qml
Behavior on moving {
    SequentialAnimation {
        NumberAnimation { target: iconText; property: "scale"; to: 0.3; duration: 90; easing.type: Easing.InCubic }
        PropertyAction {}
        NumberAnimation { target: iconText; property: "scale"; to: 1; duration: 140; easing.type: Easing.OutCubic }
    }
}
```

`SequentialAnimation` enchaîne plusieurs étapes : ici, l'icône rétrécit
(0.3), puis une `PropertyAction` (change une valeur instantanément, sans
animation — ici ça change le `text` affiché au milieu de la transition),
puis regrossit à 1. Effet : l'icône "flip" pendant qu'on glisse le slider.

---

## 7. Le système d'anchors (ancrage)

Plutôt que de calculer des positions en pixels à la main, QML propose un
système d'ancrage relatif :

```qml
// FilledSlider.qml
StyledRect {
    anchors.left: parent.left
    anchors.right: parent.right
    y: root.handle.y
    implicitHeight: parent.height - y
}
```

- `anchors.left/right/top/bottom: <référence>` : colle un bord de l'objet à
  un bord d'un autre objet (souvent `parent`).
- `anchors.fill: parent` : raccourci pour ancrer les 4 bords en même temps
  (l'objet occupe tout l'espace du parent).
- `anchors.centerIn: parent` : centre l'objet horizontalement ET
  verticalement dans le parent.
- `anchors.verticalCenter: parent.verticalCenter` : centre seulement
  verticalement (utilisé pour la pilule OSD, centrée dans une fenêtre pleine
  hauteur).
- `anchors.<côté>Margin` : ajoute une marge à un ancrage précis (ex :
  `margins.right` sur une `PanelWindow`, voir §12).

**Piège rencontré dans ce projet** : une `PanelWindow` layer-shell ne peut
s'ancrer qu'aux **bords de l'écran** (`top`/`bottom`/`left`/`right`), pas
à `centerIn`. Pour centrer verticalement une fenêtre layer-shell, on ancre
`top` ET `bottom` (donc elle prend toute la hauteur), et c'est le **contenu
à l'intérieur** (la pilule) qui utilise `anchors.verticalCenter` pour se
centrer dans cette fenêtre pleine hauteur.

---

## 8. Les composants réutilisables

En QML, **chaque fichier `.qml` est automatiquement un composant**, nommé
d'après son nom de fichier (en PascalCase). Pas besoin d'`export`/`import`
explicite pour les fichiers d'un même dossier — QML les découvre tout
seul.

Dans ce projet :
- `FilledSlider.qml` → utilisable comme `FilledSlider { ... }` dans
  `osd/shell.qml`.
- `StyledRect.qml` → utilisé à l'intérieur de `FilledSlider.qml`.
- `SessionButton.qml` → utilisable comme `SessionButton { ... }` dans
  `session/shell.qml`.

Un composant, c'est juste un fichier dont l'objet racine définit "à quoi
ressemble une instance". Exemple complet, `SessionButton.qml` :

```qml
import QtQuick

Rectangle {
    id: root

    required property string glyph   // §3 : property obligatoire à fournir
    signal activated                  // §5 : signal custom

    width: 56
    height: 56
    radius: width / 2
    color: mouseArea.containsMouse ? "#000000" : "#ffffff"  // §4 : binding
    border.width: 1
    border.color: "#33000000"

    Behavior on color {               // §6
        ColorAnimation { duration: 120 }
    }

    Text {
        anchors.centerIn: parent      // §7
        text: root.glyph
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 20
        color: mouseArea.containsMouse ? "#ffffff" : "#000000"
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
```

Chaque instance (`SessionButton { glyph: ...; onActivated: ... }`) obtient
sa propre copie indépendante de cet arbre (son propre `mouseArea`, son
propre `Text`, etc.) — exactement comme une classe qu'on instancie
plusieurs fois.

---

## 9. Les types Qt Quick de base

Types génériques utilisés partout dans le projet :

| Type | Rôle | Exemple dans le projet |
|---|---|---|
| `Item` | Type de base invisible (position/taille, pas de rendu propre) | La zone de clip dans `osd/shell.qml` |
| `Rectangle` | Rectangle coloré, avec coins arrondis (`radius`) et bordure | `SessionButton.qml`, `StyledRect.qml` |
| `Text` | Affiche du texte (ou un glyphe d'icône via une police) | icône du slider, icônes des boutons |
| `Column` | Empile ses enfants verticalement avec un espacement (`spacing`) | colonne de boutons du menu session |
| `MouseArea` | Zone invisible qui capte les clics/survol | boutons, handle du slider |
| `Timer` | Déclenche une action après un délai (`interval`), une fois ou en boucle (`repeat`) | `hideTimer` (auto-hide de l'OSD) |

Exemple `Timer` :

```qml
// osd/shell.qml
Timer {
    id: hideTimer
    interval: 1500
    onTriggered: root.shown = false
}
```

`interval` en ms. `onTriggered` = handler appelé quand le délai s'écoule.
`hideTimer.restart()` relance le compte à rebours depuis zéro (utilisé à
chaque changement de volume/luminosité pour repousser l'auto-hide).

Exemple `MouseArea` avec toutes ses options utilisées ici :

```qml
MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true              // sans ça, containsMouse ne marche pas
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()
}
```

Dans `FilledSlider.qml`, le handle a une `MouseArea` avec
`acceptedButtons: Qt.NoButton` — volontairement désactivée pour les clics
(juste pour garder le curseur "main" au survol), car l'interaction souris a
été retirée du slider (décision produit : "j'aime pas" l'interaction
souris sur le slider).

---

## 10. Slider (QtQuick.Templates)

`FilledSlider.qml` est basé sur `Slider`, un type de
`QtQuick.Templates` — les "templates" Qt Quick Controls fournissent la
**logique** (valeur, drag, plage min/max) sans **aucun style visuel** par
défaut : à toi de fournir `background` et `handle`.

```qml
import QtQuick.Templates

Slider {
    id: root
    required property string icon

    orientation: Qt.Vertical

    background: StyledRect { /* ... */ }
    handle: Item { /* ... */ }
}
```

Properties clés fournies gratuitement par `Slider` :
- `value` (0 à 1 par défaut, ou entre `from`/`to`)
- `visualPosition` : position normalisée (0-1) tenant compte de
  l'orientation et du sens
- `availableHeight` / `availableWidth` : espace dispo pour déplacer le
  handle
- `pressed` : `true` pendant qu'on clique/glisse
- `orientation: Qt.Vertical` : slider vertical au lieu d'horizontal (par
  défaut)

Dans le handle :

```qml
handle: Item {
    y: root.visualPosition * (root.availableHeight - height)
    implicitWidth: root.width
    implicitHeight: root.width
    // ...
}
```

Le handle se positionne lui-même en binding sur `visualPosition` — c'est
le template `Slider` qui met à jour `visualPosition` automatiquement
pendant le drag (même si dans ce projet le drag souris est désactivé, la
valeur peut aussi être poussée par programme : `Pipewire...volume = ...`
déclenche le même mécanisme).

Le "remplissage" du fond (`background`) suit la même logique :

```qml
background: StyledRect {
    color: "#33000000"
    radius: width / 2

    StyledRect {
        anchors.left: parent.left
        anchors.right: parent.right
        y: root.handle.y                      // suit le handle
        implicitHeight: parent.height - y      // remplit depuis le handle jusqu'en bas
        color: "#000000"
        radius: parent.radius
    }
}
```

Astuce : un `StyledRect` imbriqué dans un autre, positionné dynamiquement
en fonction de `root.handle.y`, donne l'effet "rempli jusqu'au niveau
actuel" — pas besoin de dessiner une barre de progression séparément, c'est
juste un rectangle noir dont le `y`/`height` sont des bindings.

---

## 11. Le JavaScript intégré dans QML

QML autorise du JS inline dans deux contextes :

**1. Dans une expression de binding** (une seule ligne, une seule
expression) :

```qml
icon: root.muted ? "..." : "..."
```

**2. Dans un bloc de fonction/handler** (code impératif classique) :

```qml
// osd/shell.qml
function setBrightness(percent) {
    setBrightnessProc.command = ["brightnessctl", "--device=" + backlightDevice, "set", Math.round(percent * 100) + "%", "-q"];
    setBrightnessProc.running = true;
}
```

Tout le JS standard est dispo : `Math.round`, template-like concat avec
`+`, `String.fromCodePoint(...)` (utilisé pour transformer un codepoint
Unicode d'icône en caractère affichable), `Number(...)`, `isNaN(...)`,
`.trim()`, etc.

Un handler de signal peut aussi contenir plusieurs lignes :

```qml
function onVolumeChanged() {
    root.activeMode = "volume";
    root.shown = true;
    hideTimer.restart();
}
```

Contrairement à un binding (`propriété: expr`), ici c'est de
l'**impératif classique** : ces lignes s'exécutent dans l'ordre, une seule
fois, quand le signal se déclenche — pas de ré-évaluation automatique.

---

## 12. Quickshell : Scope et PanelWindow

### `Scope`

```qml
Scope {
    id: root
    // ...
}
```

`Scope` est l'objet racine typique d'une config Quickshell : un conteneur
**non-visuel** qui regroupe l'état partagé (properties, functions,
IpcHandler...) et une ou plusieurs fenêtres. Il ne dessine rien lui-même —
c'est juste la racine logique du fichier.

### `PanelWindow`

Le type central pour créer une fenêtre **layer-shell** (une fenêtre système
Wayland, pas une fenêtre d'application normale — pas de bordure, pas dans
la liste des tâches, positionnable sur les bords d'écran).

```qml
PanelWindow {
    id: osdWindow

    screen: Quickshell.screens.find(s => s.name === "eDP-1") ?? Quickshell.screens[0]

    anchors.top: true
    anchors.bottom: true
    anchors.right: true
    margins.right: -edgeOverhang

    exclusiveZone: 0
    color: "transparent"
    implicitWidth: pillWidth + edgeOverhang
}
```

- **`screen:`** : sur quel moniteur afficher cette fenêtre.
  `Quickshell.screens` est la liste de tous les écrans connectés ;
  `.find(...)` cherche celui qui s'appelle `"eDP-1"` (l'écran interne du
  laptop), et `?? Quickshell.screens[0]` est un repli si jamais ce nom
  n'existe pas.
- **`anchors.top/bottom/right: true`** : contrairement aux anchors "objet
  normal" du §7, sur une `PanelWindow` ça ancre aux **bords de l'écran**
  physique.
- **`margins.right`** : décale la fenêtre au-delà du bord ancré. Une valeur
  **négative** pousse la fenêtre hors de l'écran (utilisé pour le petit
  débordement `edgeOverhang` qui garantit que le flou du plugin Blobs sorte
  bien de l'écran physique, pas juste de la zone visible).
- **`exclusiveZone: 0`** : dit au compositeur "ne réserve pas d'espace pour
  cette fenêtre, laisse les autres fenêtres passer derrière" (contraire
  d'une vraie barre de tâches qui, elle, pousse le contenu).
- **`color: "transparent"`** : fond de la fenêtre transparent — seul ce
  qu'on dessine explicitement dedans (la pilule) est visible.

---

## 13. Quickshell.Wayland : layer-shell et fullscreen

```qml
import Quickshell.Wayland

WlrLayershell.namespace: "quickshell-osd"
WlrLayershell.layer: WlrLayer.Overlay
```

- **`WlrLayershell.namespace`** : identifiant texte de la fenêtre, utile
  pour la cibler depuis Hyprland (ex : une `layerrule` qui matche
  `namespace`).
- **`WlrLayershell.layer`** : sur quelle "couche" de rendu se place la
  fenêtre. Les couches wlr-layer-shell (de bas en haut) : `Background` <
  `Bottom` < `Top` < `Overlay`. Une fenêtre en fullscreen passe normalement
  **au-dessus** de la couche `Top` (où vit par défaut ce genre d'OSD) —
  d'où le bug initial "l'OSD disparaît en plein écran", corrigé en passant
  à `WlrLayer.Overlay`, la seule couche qui reste au-dessus d'une fenêtre
  fullscreen.
- **`WlrKeyboardFocus`** (mentionné dans les notes du projet, pas utilisé
  ici) : contrôle si une fenêtre layer-shell peut recevoir le focus clavier
  (`None`, `OnDemand`, `Exclusive`).

---

## 14. Quickshell.Io : Process, FileView, IpcHandler

### `Process` — lancer une commande shell

```qml
// osd/shell.qml
Process {
    id: maxBrightnessProc
    command: ["cat", "/sys/class/backlight/" + root.backlightDevice + "/max_brightness"]
    running: true
    stdout: StdioCollector {
        onStreamFinished: {
            const v = Number(text.trim());
            if (!isNaN(v) && v > 0)
                root.maxBrightness = v;
        }
    }
}
```

- **`command:`** : liste de strings = `["binaire", "arg1", "arg2", ...]`
  (jamais une seule string shell — pas d'injection shell possible, chaque
  élément est un argument séparé).
- **`running: true`** : lance le process. On peut aussi laisser `running:
  false` et le déclencher plus tard en assignant `running = true` — c'est
  le pattern utilisé pour `setBrightnessProc`/`actionProc` (déclenchés à la
  demande depuis une fonction, pas au démarrage).
- **`stdout: StdioCollector { onStreamFinished: ... }`** : capture toute la
  sortie standard, et `onStreamFinished` s'exécute une fois que le process
  a fini d'écrire (la sortie complète est dans `text`).

Pattern "relancer avec de nouveaux arguments" (`session/shell.qml`) :

```qml
Process {
    id: actionProc
    stdout: StdioCollector {}
}

function runDetached(cmd) {
    actionProc.command = cmd;   // change les arguments
    actionProc.running = true;  // relance
    root.shown = false;
}
```

On réutilise le **même** objet `Process` pour plusieurs commandes
différentes (`hyprlock`, `systemctl poweroff`, etc.) en réassignant juste
`command` avant chaque lancement.

### `FileView` — lire/surveiller un fichier

```qml
// osd/shell.qml
FileView {
    id: brightnessFile
    path: root.brightnessPath
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
        const v = Number(text().trim());
        // ...
    }
}
```

- **`path:`** : chemin du fichier à lire.
- **`watchChanges: true`** : active une surveillance système (inotify) du
  fichier — dès qu'il change sur disque (même modifié par un **autre**
  programme, comme `brightnessctl` lancé depuis un raccourci clavier
  externe), Quickshell est notifié.
- **`onFileChanged: reload()`** : quand le fichier change, on doit appeler
  `reload()` nous-même pour que `FileView` relise le contenu (ce n'est pas
  automatique — juste la notification l'est).
- **`onLoaded`** : appelé après un chargement/rechargement réussi.
  `text()` (méthode, avec parenthèses) renvoie le contenu actuel du
  fichier en string.

### `IpcHandler` — se faire piloter depuis l'extérieur

```qml
// session/shell.qml
IpcHandler {
    target: "session"

    function toggle(): void {
        root.shown = !root.shown;
    }

    function close(): void {
        root.shown = false;
    }
}
```

Expose des fonctions QML **appelables depuis l'extérieur du process**, en
ligne de commande :

```
qs -c session ipc call session toggle
```

`target: "session"` = le nom sous lequel ce handler est identifiable (`qs
-c session ipc call <target> <fonction>`). C'est comme ça qu'un raccourci
clavier Hyprland (`bind = $mainMod, Escape, exec, qs -c session ipc call
session toggle`) peut piloter une instance de `qs` **déjà lancée en fond**
sans avoir à en relancer une nouvelle à chaque appui de touche.

---

## 15. Quickshell.Services.Pipewire

```qml
import Quickshell.Services.Pipewire

PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
}

readonly property real volume: Pipewire.defaultAudioSink?.audio.volume ?? 0
readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false
```

- **`Pipewire.defaultAudioSink`** : objet représentant la sortie audio
  actuelle du système (haut-parleurs/casque). Ses properties
  (`.audio.volume`, `.audio.muted`) sont des **bindings réactifs** — dès
  que le volume système change (même changé par une autre appli, ou les
  touches clavier `XF86AudioRaiseVolume`), ces properties se mettent à
  jour toutes seules.
- **`PwObjectTracker`** : nécessaire pour que Quickshell "s'abonne"
  activement à cet objet PipeWire (sans ça, l'objet ne serait pas tenu à
  jour en continu).
- **Assignation directe** (pas juste lecture) : `Pipewire.defaultAudioSink
  .audio.volume = value` dans `onMoved` — changer cette property change
  *réellement* le volume système, ce n'est pas juste une variable locale.

---

## 16. Le masque d'input : Region

Une `PanelWindow` layer-shell occupe une zone rectangulaire de l'écran, et
par défaut **capte tous les clics** dans cette zone — même la partie
transparente qui ne montre rien à l'utilisateur. `mask:` permet de
restreindre quelle sous-partie de la fenêtre reçoit réellement les
événements souris.

```qml
// osd/shell.qml — jamais interactif à la souris
mask: Region {}
```

`Region {}` vide = la fenêtre entière laisse passer les clics (totalement
"cliquable-à-travers") — les clics arrivent aux fenêtres/applications
derrière, comme si l'OSD n'existait pas pour la souris.

```qml
// session/shell.qml — les boutons doivent être cliquables
mask: Region { item: pill }
```

`Region { item: pill }` = seule la zone occupée par l'objet `pill`
(la `BlobRect`) capte les clics. Comme `pill.x` est animé (§6) entre
`hideOffset` (replié, hors de la fenêtre visible) et `0` (déplié), la zone
cliquable **suit automatiquement** la position de la pilule : repliée, elle
tombe hors des limites de la fenêtre → clics totalement transparents ;
dépliée, elle capte les clics sur les boutons. Un seul mécanisme (le
binding sur `x`) gère à la fois l'animation visuelle ET l'interactivité,
sans code séparé pour les deux.

---

## 17. Caelestia.Blobs : le plugin de fusion metaball

C'est le seul module **non standard** de ce projet : un plugin C++/QML
compilé sur mesure (vendoré depuis `caelestia-dots/shell`, licence GPLv3),
qui simule un effet "metaball" (façon lave-lampe) — plusieurs formes qui
**fusionnent visuellement** entre elles quand elles sont proches, avec un
contour lisse et déformable, au lieu de simplement se chevaucher.

Trois types QML exposés par le plugin :

### `BlobGroup`

Le "contexte" partagé — toutes les formes qui doivent pouvoir fusionner
entre elles doivent référencer le **même** `BlobGroup`.

```qml
BlobGroup {
    id: blobGroup
    color: "#ffffff"   // couleur de rendu commune à toutes les formes du groupe
    smoothing: 32       // rayon d'influence de la fusion (plus grand = fusion plus "molle"/étendue)
}
```

### `BlobRect`

Une forme "normale" qui participe à la fusion — dans ce projet, c'est la
pilule elle-même.

```qml
BlobRect {
    id: pill
    group: blobGroup     // lien vers le groupe partagé
    width: 56
    height: 180
    radius: 20            // arrondi des coins
    deformScale: 0         // 0 = pas d'étirement "gélatine" pendant le déplacement
}
```

### `BlobInvertedRect`

Une forme "en creux" (un trou) — utilisée ici pour représenter le bord de
l'écran : au lieu d'apparaître comme une forme pleine, elle influence la
fusion des autres formes du groupe comme si l'écran avait un "bord mou" qui
attire/fusionne avec la pilule quand elle s'en approche. Dans ce projet,
elle est délibérément placée **hors de la zone visible** (coordonnées
négatives / au-delà de la fenêtre), donc jamais rendue elle-même — seule
son **influence sur la fusion** compte, pas son apparence :

```qml
BlobInvertedRect {
    group: blobGroup
    x: -2000
    y: -200
    width: 2000 + pillWidth + holeOutset + 40
    height: parent.height + 400
    radius: 25
    borderRight: 40   // "épaisseur" du bord qui fusionne avec la pilule
}
```

Ce que ce système donne concrètement : quand la pilule glisse vers `x: 0`
(dépliée), son coin qui touche le bord d'écran **se fond** dans ce bord
plutôt que de faire un angle net — l'effet "coin qui se fond dans le bord
de l'écran" qu'on voulait reproduire depuis le début. Ce n'est pas une
astuce CSS/QML pure : c'est un vrai calcul de champ de distance (SDF,
*signed distance field*) fait par un shader GLSL fourni par le plugin.

---

## 18. Walkthrough complet : osd/shell.qml

Vue d'ensemble de l'assemblage complet, dans l'ordre du fichier :

```qml
Scope {
    id: root

    // 1. État réactif PipeWire (§15) — volume/muted toujours à jour
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property real volume: Pipewire.defaultAudioSink?.audio.volume ?? 0
    readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false

    // 2. Réagir aux changements (§5 Connections) → déclenche l'affichage
    Connections {
        target: Pipewire.defaultAudioSink?.audio
        function onVolumeChanged() { root.activeMode = "volume"; root.shown = true; hideTimer.restart(); }
        function onMutedChanged() { /* idem */ }
    }

    // 3. Luminosité : lecture fichier système (§14 FileView) + écriture (§14 Process)
    FileView { path: root.brightnessPath; watchChanges: true; onFileChanged: reload(); onLoaded: { /* ... */ } }
    function setBrightness(percent) { /* Process avec brightnessctl */ }

    // 4. État d'affichage partagé (§3 properties, §6 Timer)
    property string activeMode: "volume"
    property bool shown: false
    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }

    // 5. La fenêtre (§12 PanelWindow, §13 layer-shell)
    PanelWindow {
        id: osdWindow
        readonly property int pillWidth: 56
        readonly property int pillHeight: 180
        screen: /* eDP-1 */
        WlrLayershell.namespace: "quickshell-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        anchors.top: true; anchors.bottom: true; anchors.right: true
        mask: Region {}   // (§16) jamais interactive

        // 6. Zone de rendu (§9 Item + clip)
        Item {
            width: osdWindow.pillWidth
            height: parent.height
            clip: true

            // 7. Le système de fusion (§17)
            BlobGroup { id: blobGroup; color: "#ffffff"; smoothing: 32 }
            BlobInvertedRect { group: blobGroup; /* bord d'écran, hors-champ */ }

            // 8. La pilule elle-même, animée (§4 binding + §6 Behavior)
            BlobRect {
                id: pill
                group: blobGroup
                x: root.shown ? 0 : hideOffset
                Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                // 9. Le contenu (§10 Slider custom)
                FilledSlider {
                    icon: /* ternaire géant selon activeMode/volume/brightness */
                    value: /* idem */
                    onMoved: /* écrit le volume ou la luminosité */
                }
            }
        }
    }
}
```

Le fil conducteur : **état** (PipeWire + fichier système) → **événements**
qui mettent `shown`/`activeMode` à jour → **bindings** partout ailleurs qui
réagissent tout seuls (position de la pilule, icône affichée, valeur du
slider) → **Behavior** qui anime les transitions. À aucun moment il n'y a
de code du genre "maintenant redessine la fenêtre" — tout découle des
bindings.

---

## 19. Walkthrough complet : session/shell.qml

Même structure de fenêtre/pilule que l'OSD (§18, points 5 à 8 identiques),
mais la partie "état" et le contenu de la pilule sont différents :

```qml
Scope {
    id: root

    // 1. Pas d'état externe à suivre : juste une action à lancer (§14 Process)
    Process { id: actionProc; stdout: StdioCollector {} }
    function runDetached(cmd) {
        actionProc.command = cmd;
        actionProc.running = true;
        root.shown = false;   // se referme après avoir lancé l'action
    }

    // 2. Piloté depuis l'extérieur (§14 IpcHandler), pas par un signal PipeWire
    IpcHandler {
        target: "session"
        function toggle(): void { root.shown = !root.shown; }
        function close(): void { root.shown = false; }
    }

    property bool shown: false
    // Pas de hideTimer : contrairement à l'OSD (qui doit disparaître tout
    // seul après inactivité), le menu session reste ouvert tant qu'on ne
    // clique pas sur un bouton ou qu'on ne rappuie pas sur le raccourci —
    // comportement volontairement différent, pas un oubli.

    PanelWindow {
        // ... même structure que l'OSD (screen, WlrLayershell, anchors)

        // Différence clé : mask suit la pilule (§16), car il FAUT
        // pouvoir cliquer sur les boutons (contrairement au slider,
        // jamais interactif à la souris)
        mask: Region { item: pill }

        Item {
            clip: true
            BlobGroup { /* identique */ }
            BlobInvertedRect { /* identique, juste pillWidth différent (80 au lieu de 56) */ }

            BlobRect {
                id: pill
                x: root.shown ? 0 : hideOffset   // même mécanique exacte que l'OSD
                Behavior on x { /* identique */ }

                // Contenu différent : une colonne de boutons (§9 Column, §8 composant)
                // au lieu d'un FilledSlider
                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    SessionButton { glyph: /* cadenas */; onActivated: root.runDetached(["hyprlock"]) }
                    SessionButton { glyph: /* logout */;  onActivated: root.runDetached(["hyprctl", "dispatch", "exit"]) }
                    SessionButton { glyph: /* power */;   onActivated: root.runDetached(["systemctl", "poweroff"]) }
                    SessionButton { glyph: /* restart */; onActivated: root.runDetached(["systemctl", "reboot"]) }
                }
            }
        }
    }
}
```

Ce qui est **volontairement identique** à l'OSD : toute la mécanique
fenêtre/fusion/glissement (§12, §13, §17, le binding `x` + `Behavior`).
Ce qui **change**, et pourquoi c'est logique vu le rôle différent :
- Pas de `Connections`/`PwObjectTracker` : rien à observer en continu, le
  menu ne s'ouvre que sur commande explicite (`IpcHandler`).
- Pas de `hideTimer` : un menu d'actions ne doit pas se refermer tout seul
  pendant que tu regardes tes options — seul un clic ou un nouveau
  raccourci le referme.
- `mask` dynamique au lieu de `Region {}` fixe : les boutons doivent
  recevoir les clics, le slider ne le devait pas.

---

## 20. Glossaire

| Terme | Sens |
|---|---|
| **binding** | Expression `propriété: expr` qui se réévalue automatiquement quand ses dépendances changent |
| **signal** | Événement qu'un objet peut émettre |
| **handler** | Fonction `onNomDuSignal` qui réagit à un signal |
| **property** | Attribut d'un objet, lisible/modifiable, qui génère automatiquement un signal `xChanged` |
| **id** | Identifiant local (pas une string) pour référencer un objet ailleurs dans le même fichier |
| **composant** | Un fichier `.qml` = un type réutilisable, nommé d'après le nom du fichier |
| **layer-shell** | Protocole Wayland pour des fenêtres système (barres, OSD...) hors du cycle de vie des fenêtres normales |
| **anchors** | Système de positionnement relatif (coller un bord à un autre) |
| **Behavior** | Anime automatiquement les changements d'une property |
| **Scope** | Racine non-visuelle d'une config Quickshell |
| **PanelWindow** | Fenêtre layer-shell Quickshell (ancrée aux bords de l'écran) |
| **exclusiveZone** | Espace réservé sur l'écran par une fenêtre layer-shell (0 = n'en réserve pas) |
| **mask / Region** | Restreint quelle zone d'une fenêtre reçoit les clics |
| **Process** | Lance une commande shell depuis QML |
| **FileView** | Lit/surveille un fichier, avec notification de changement |
| **IpcHandler** | Expose des fonctions QML appelables en ligne de commande (`qs ipc call`) |
| **BlobGroup / BlobRect / BlobInvertedRect** | Types du plugin custom Caelestia.Blobs pour l'effet de fusion metaball |
