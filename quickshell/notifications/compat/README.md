# Couche de compatibilité pour le portage à l'identique

`Content.qml`, `Notification.qml` et `Wrapper.qml` (dossier parent) sont des
copies **verbatim, non modifiées**, de `modules/notifications` de
github.com/caelestia-dots/shell (GPLv3). Ce dossier fournit tout ce dont
ils ont besoin pour tourner seuls, sans le reste de leur shell.

## Vendoré tel quel (copie verbatim depuis leur repo)

- `qs/components/`: CAnim, ScreenState, StyledRect, StyledText,
  StyledClippingRect, Anim, AnchorAnim, StateLayer, MaterialIcon
- `qs/components/containers/StyledListView.qml`
- `qs/components/widgets/ExtraIndicator.qml`
- `qs/components/controls/`: ButtonBase, IconButton, TextButton
- `qs/components/effects/`: ColouredIcon, Colouriser, Elevation
- `qs/utils/Icons.qml`

## Réécrit à la main (leur version dépend de choses qu'on n'a pas :
## plugin C++ Caelestia.Config, service Hypr, i18n, toasts, cache disque...)

- `Caelestia/CUtils.qml` — juste `clamp()`.
- `Caelestia/Config/{Tokens,Config,GlobalConfig,TokenConfig}.qml` — mêmes
  valeurs numériques EXACTES que leur `tokens.hpp`/`notifsconfig.hpp`/
  `borderconfig.hpp` (paddings, durées, courbes de bézier M3...), mais en
  QML/JS pur (pas de plugin C++, pas de fichier de settings modifiable).
- `Caelestia/Components/ButtonRow.qml` — leur version est un vrai widget
  C++ ; ici un `RowLayout` + `Layout.fillWidth` posé depuis l'extérieur.
- `Caelestia/Images/ImageAnalyser.qml` — stub (couleur dominante fixe,
  pas de vraie analyse d'image) pour que `ColouredIcon.qml` (vendoré)
  compile sans le plugin C++ Caelestia.Images.
- `qs/services/Colours.qml` — palette PLATE (noir/blanc/rouge critique,
  notre esthétique existante), pas leur moteur Material You généré depuis
  le fond d'écran.
- `qs/services/{Notifs,NotifData}.qml` — même API publique que la
  référence (popup/closed/timeStr/timer/lock/unlock/close/summary/...),
  auto-expire par timer inclus (redemandé explicitement par Hugo), MAIS
  sans : persistance JSON entre redémarrages, détection plein écran
  Hyprland, do-not-disturb, i18n, cache disque d'images.
- `qs/modules/utilities/Wrapper.qml` — stub vide (pas de panneau
  "utilities" dans ce projet), juste pour que le cast `as Utilities.Wrapper`
  de `Content.qml` reste résoluble.

## Résultat

Rendu et interactions (plié/déplié, glisser pour fermer, ring de
progression, actions, auto-expire) identiques à la référence. Ce qui reste
différent : les couleurs (plates, pas Material You dynamique) et quelques
détails de service (pas de DND/historique disque).
