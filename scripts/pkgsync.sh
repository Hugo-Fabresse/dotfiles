#!/usr/bin/env bash
# pkgsync.sh — Save or restore package lists
# Usage: pkgsync.sh save | restore
set -euo pipefail

DOTFILES="$HOME/dotfiles"
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

info()  { echo -e "${CYAN}:: $1${RESET}"; }
ok()    { echo -e "${GREEN}✓  $1${RESET}"; }
err()   { echo -e "${RED}✗  $1${RESET}"; exit 1; }

save() {
    info "Saving package lists..."

    pacman -Qqe | grep -v "$(pacman -Qqem)" > "$DOTFILES/pkglist.txt"
    ok "pacman (official): $(wc -l < "$DOTFILES/pkglist.txt") packages"

    pacman -Qqem > "$DOTFILES/pkglist-aur.txt"
    ok "pacman (AUR):      $(wc -l < "$DOTFILES/pkglist-aur.txt") packages"

    flatpak list --app --columns=application > "$DOTFILES/flatpak.txt"
    ok "flatpak:           $(wc -l < "$DOTFILES/flatpak.txt") apps"
}

restore() {
    # Official packages
    if [ -f "$DOTFILES/pkglist.txt" ]; then
        info "Restoring official packages..."
        sudo pacman -S --needed --noconfirm - < "$DOTFILES/pkglist.txt"
        ok "Official packages restored"
    else
        err "pkglist.txt not found"
    fi

    # AUR packages
    if [ -f "$DOTFILES/pkglist-aur.txt" ]; then
        if command -v yay &>/dev/null; then
            info "Restoring AUR packages..."
            yay -S --needed --noconfirm - < "$DOTFILES/pkglist-aur.txt"
            ok "AUR packages restored"
        else
            err "yay not found — install yay first"
        fi
    else
        err "pkglist-aur.txt not found"
    fi

    # Flatpak
    if [ -f "$DOTFILES/flatpak.txt" ]; then
        info "Restoring flatpak apps..."
        while IFS= read -r app; do
            flatpak install -y flathub "$app" 2>/dev/null || true
        done < "$DOTFILES/flatpak.txt"
        ok "Flatpak apps restored"
    else
        err "flatpak.txt not found"
    fi
}

case "${1:-}" in
    save)    save ;;
    restore) restore ;;
    *)       echo "Usage: pkgsync.sh save | restore" ;;
esac
