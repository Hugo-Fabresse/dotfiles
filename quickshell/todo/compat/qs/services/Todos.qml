pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Service de persistance du module todo — liste de tâches stockée en JSON
// sur disque (~/.local/share/quickshell/todos.json), lue/sauvegardée
// automatiquement via JsonAdapter (Quickshell.Io, voir jsonadapter.hpp :
// tout changement de propriété déclare dans le JsonAdapter émet
// FileView.adapterUpdated, ici branché sur writeAdapter()).
//
// Contrairement à compat/qs/services/NotifData.qml (module notifications),
// pas de classe QtObject dédiée par item : chaque tâche est un objet JS
// brut {id, text, createdAt} dans un tableau immuable (chaque fonction
// réassigne data.items en entier plutôt que de muter en place — c'est ce
// qui déclenche la notification de changement de propriété que JsonAdapter
// observe). Rien ici ne dépend d'un service externe (pas de dismiss()/
// lock() à coordonner comme pour une vraie notif système), un tableau
// suffit.
//
// Pas de champ "done" persisté : cocher une tâche (Todo.qml, Content.qml)
// la supprime directement après une courte animation locale (cercle rempli
// + texte barré) — il n'existe donc jamais d'état "faite mais gardée" à
// stocker sur disque, juste "présente" ou "plus là".
Singleton {
    id: root

    readonly property alias items: data.items

    function add(text) {
        const t = (text ?? "").trim();
        if (t.length === 0)
            return;
        const item = {
            // Assez unique pour ce cas d'usage (une seule personne, un seul
            // appareil) : horodatage en base36 + quelques caractères
            // aléatoires, pas besoin d'un vrai UUID.
            id: Date.now().toString(36) + Math.random().toString(36).slice(2, 8),
            text: t,
            createdAt: Date.now()
        };
        // Ajoutée en TÊTE (comme une nouvelle notif dans Notifs.qml) : la
        // tâche la plus récente reste la plus visible, en haut du panneau.
        data.items = [item, ...data.items];
    }

    function remove(id) {
        data.items = data.items.filter(t => t.id !== id);
    }

    FileView {
        id: fileView

        path: Quickshell.env("HOME") + "/.local/share/quickshell/todos.json"
        // Chargé tout de suite au lancement de `qs -c todo` plutôt qu'à la
        // première lecture — on veut que la liste soit déjà remplie avant
        // même que SUPER+T n'ouvre le panneau pour la première fois.
        preload: true
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: data
            property list<var> items: []
        }
    }
}
