#!/bin/bash
# autopush.sh — push automatique des dotfiles chaque vendredi à 18h

cd ~/dotfiles || exit 1

git submodule foreach '
    git add .
    git diff --cached --quiet || git commit -m "auto: weekly push $(date +%Y-%m-%d)"
    git push
'

git add .
git diff --cached --quiet || git commit -m "auto: weekly push $(date +%Y-%m-%d)"
git push
