# Caelestia.Blobs (vendored)

Ce dossier contient une copie verbatim du plugin QML `Caelestia.Blobs`
(rendu SDF/metaball des panneaux) provenant de :

https://github.com/caelestia-dots/shell — dossier `plugin/src/Caelestia/Blobs/`

Licence : GPLv3 (voir `LICENSE` dans ce dossier). Le code n'a pas été modifié,
seul le système de build (`CMakeLists.txt`) a été simplifié pour ne compiler
que ce module isolément, sans le reste du shell Caelestia.

## Build

```sh
cmake -S . -B build -G Ninja
cmake --build build
```

Le module compilé (`Caelestia/Blobs/`) atterrit dans `build/`. Quickshell le
trouve via la variable d'env `QML2_IMPORT_PATH` pointée vers ce dossier
`build/` (voir `exec-once` dans hyprland.conf).
