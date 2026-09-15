#!/usr/bin/env bash
# bootstrap.sh — Setup dotfiles from scratch
# Arch Linux — Hyprland — Minimal, black, no noise
set -euo pipefail

DOTFILES="$HOME/dotfiles"
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

info()  { echo -e "${CYAN}:: $1${RESET}"; }
ok()    { echo -e "${GREEN}✓  $1${RESET}"; }
err()   { echo -e "${RED}✗  $1${RESET}"; }
warn()  { echo -e "${YELLOW}⚠  $1${RESET}"; }

# -------------------------------------------
# 0. Prerequisites
# -------------------------------------------
check_prereqs() {
    info "Checking prerequisites..."

    # SSH key for GitHub (submodules use git@github.com)
    if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
        warn "No SSH key found — submodules use git@github.com"
        warn "Generate one: ssh-keygen -t ed25519 -C \"your@email\""
        warn "Then add it to GitHub: https://github.com/settings/keys"
        read -rp "Continue anyway? [y/N] " yn
        [[ "$yn" =~ ^[Yy]$ ]] || exit 1
    fi

    # git is needed for everything
    if ! command -v git &>/dev/null; then
        err "git not found — install it first: sudo pacman -S git"
        exit 1
    fi

    ok "Prerequisites OK"
}

# -------------------------------------------
# 1. Packages
# -------------------------------------------
install_packages() {
    info "Installing pacman packages..."
    local pkgs=(
        # WM & desktop
        hyprland hyprlock swaybg waybar wofi dunst
        # Terminal & shell
        kitty zsh zsh-autosuggestions zsh-syntax-highlighting fastfetch
        # Audio
        pipewire pipewire-pulse wireplumber pavucontrol playerctl
        # Widgets / OSD
        quickshell
        # Network
        networkmanager network-manager-applet
        # Brightness & screenshots
        brightnessctl grim slurp
        # Python widgets
        python python-pyqt6 python-requests python-dbus python-html2text
        # Clipboard
        wl-clipboard cliphist
        # Fonts
        ttf-jetbrains-mono-nerd noto-fonts-emoji
        # Build tools (for ash/dentry, and the quickshell OSD blob plugin)
        cmake base-devel qt6-base qt6-declarative qt6-shadertools
        # Tools
        fzf pacman-contrib git jq imagemagick libnotify
        # Flatpak
        flatpak
        # Browser
        qutebrowser
        # Neovim
        neovim
        # Music
        spotify-player
    )
    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    ok "Pacman packages installed"
}

install_yay() {
    if command -v yay &>/dev/null; then
        ok "yay already installed"
        return
    fi
    info "Installing yay..."
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd "$DOTFILES"
    rm -rf "$tmpdir"
    ok "yay installed"
}

install_aur() {
    info "Installing AUR packages..."
    yay -S --needed --noconfirm maplemono-otf dentry
    ok "AUR packages installed"
}

install_flatpak() {
    info "Installing Flatpak apps..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    while IFS= read -r app; do
        [[ -z "$app" ]] && continue
        flatpak install -y flathub "$app" 2>/dev/null || true
    done < "$DOTFILES/flatpak.txt"
    ok "Flatpak apps installed"
}

# -------------------------------------------
# 2. Oh My Zsh & plugins
# -------------------------------------------
install_omz() {
    info "Setting up Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        ok "Oh My Zsh installed"
    else
        ok "Oh My Zsh already present"
    fi

    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ ! -d "$custom/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
    fi
    if [ ! -d "$custom/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
    fi
    ok "Oh My Zsh plugins ready"
}

set_default_shell() {
    if [ "$SHELL" != "/usr/bin/zsh" ]; then
        info "Setting zsh as default shell..."
        chsh -s /usr/bin/zsh
        ok "Default shell set to zsh"
    else
        ok "Default shell already zsh"
    fi
}

# -------------------------------------------
# 3. Submodules
# -------------------------------------------
init_submodules() {
    info "Initializing git submodules..."
    cd "$DOTFILES"
    git submodule update --init --recursive
    ok "Submodules initialized"
}

# -------------------------------------------
# 4. Symlinks
# -------------------------------------------
link() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            return  # already correct
        fi
        mv "$dst" "${dst}.bak"
        info "Backed up existing $(basename "$dst")"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
}

create_symlinks() {
    info "Creating symlinks..."

    # Config directories
    link "$DOTFILES/hypr"          "$HOME/.config/hypr"
    link "$DOTFILES/kitty"         "$HOME/.config/kitty"
    link "$DOTFILES/waybar"        "$HOME/.config/waybar"
    link "$DOTFILES/wofi"          "$HOME/.config/wofi"
    link "$DOTFILES/nvim"          "$HOME/.config/nvim"
    link "$DOTFILES/qutebrowser"   "$HOME/.config/qutebrowser"
    link "$DOTFILES/quickshell"    "$HOME/.config/quickshell"

    # Dunst (single file, not full directory)
    mkdir -p "$HOME/.config/dunst"
    link "$DOTFILES/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"

    # Zsh
    link "$DOTFILES/zsh/zshrc"     "$HOME/.zshrc"

    ok "Symlinks created"
}

# -------------------------------------------
# 5. Scripts
# -------------------------------------------
install_scripts() {
    info "Installing scripts..."

    # Widget scripts → ~/.local/bin/
    mkdir -p "$HOME/.local/bin"
    for f in "$DOTFILES/scripts/bin/"*; do
        [ -f "$f" ] || continue
        cp "$f" "$HOME/.local/bin/"
    done
    chmod +x "$HOME/.local/bin/"*.py "$HOME/.local/bin/"*.sh 2>/dev/null || true

    # Shell scripts → ~/.local/share/hypr/
    mkdir -p "$HOME/.local/share/hypr"
    cp "$DOTFILES/scripts/toggle_waybar.sh" "$HOME/.local/share/hypr/"
    cp "$DOTFILES/scripts/wofi_toggle.sh"   "$HOME/.local/share/hypr/"
    chmod +x "$HOME/.local/share/hypr/"*.sh

    # Utility scripts stay in ~/dotfiles/scripts/ (referenced directly by configs)
    chmod +x "$DOTFILES/scripts/"*.sh 2>/dev/null || true

    ok "Scripts installed"
}

# -------------------------------------------
# 6. Build custom apps
# -------------------------------------------
build_app() {
    local name="$1" dir="$DOTFILES/$1"
    if [ ! -f "$dir/CMakeLists.txt" ]; then
        err "$name: CMakeLists.txt not found, skipping"
        return 1
    fi
    info "Building $name..."
    cmake -S "$dir" -B "$dir/build" -DCMAKE_BUILD_TYPE=Release
    cmake --build "$dir/build" -j"$(nproc)"
    cp "$dir/build/$name" "$HOME/.local/bin/$name"
    ok "$name built and installed to ~/.local/bin/"
}

build_custom_apps() {
    build_app "ash"    || true
    build_app "dentry" || true
}

# Vendored Caelestia.Blobs QML plugin — compiled locally, not committed
# (see quickshell/osd/vendor/README.md). Needed by the volume OSD's
# "melt into the screen edge" rounding effect.
build_quickshell_osd_plugin() {
    local dir="$DOTFILES/quickshell/osd/vendor"
    if [ ! -f "$dir/CMakeLists.txt" ]; then
        err "quickshell OSD plugin: CMakeLists.txt not found, skipping"
        return 1
    fi
    info "Building quickshell OSD blob plugin..."
    cmake -S "$dir" -B "$dir/build" -DCMAKE_BUILD_TYPE=Release
    cmake --build "$dir/build" -j"$(nproc)"
    ok "quickshell OSD blob plugin built"
}

# -------------------------------------------
# 7. Services
# -------------------------------------------
enable_services() {
    info "Enabling services..."
    sudo systemctl enable --now NetworkManager 2>/dev/null || true
    ok "Services enabled"
}

# -------------------------------------------
# 8. Cron (autopush)
# -------------------------------------------
setup_cron() {
    info "Setting up autopush cron..."
    local cron_job="0 18 * * 5 $DOTFILES/scripts/autopush.sh >> $DOTFILES/scripts/autopush.log 2>&1"
    if crontab -l 2>/dev/null | grep -qF "autopush.sh"; then
        ok "Autopush cron already set"
    else
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        ok "Autopush cron added (every Friday 18:00)"
    fi
}

# -------------------------------------------
# Main
# -------------------------------------------
main() {
    echo ""
    echo "  dotfiles bootstrap — Arch Linux / Hyprland"
    echo "  ─────────────────────────────────────────"
    echo ""

    if [ ! -d "$DOTFILES" ]; then
        err "Dotfiles not found at $DOTFILES"
        err "Clone first: git clone --recursive git@github.com:Hugo-Fabresse/dotfiles.git ~/dotfiles"
        exit 1
    fi

    check_prereqs
    install_packages
    install_yay
    install_aur
    install_flatpak
    install_omz
    set_default_shell
    init_submodules
    create_symlinks
    install_scripts
    build_custom_apps
    build_quickshell_osd_plugin
    enable_services
    setup_cron

    echo ""
    ok "Bootstrap complete. Reboot or run: hyprctl reload"
    echo ""
    info "Optional: restore ALL packages from your saved lists:"
    echo "  ~/dotfiles/scripts/pkgsync.sh restore"
    echo ""
}

main "$@"
