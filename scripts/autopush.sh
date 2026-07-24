#!/bin/bash
# autopush.sh — push automatique des dotfiles chaque vendredi à 18h

cd ~/dotfiles || exit 1

# Vérifier la connexion réseau avant de push
if ! ping -c 1 -W 5 github.com &>/dev/null; then
    echo "$(date): No network — skipping push"
    exit 1
fi

git submodule foreach '
    git add -u
    git diff --cached --quiet || git commit -m "auto: weekly push $(date +%Y-%m-%d)"
    git push || echo "WARN: push failed for $name"
'

git add -u
git diff --cached --quiet || git commit -m "auto: weekly push $(date +%Y-%m-%d)"
git push || echo "WARN: push failed for dotfiles"
