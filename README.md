# dotfiles

Arch Linux — Hyprland setup.
Minimal, black, no noise.

---

## Quick install

> **Le repo doit etre clone dans `~/dotfiles`** — les configs Hyprland et Waybar referencent `~/dotfiles/scripts/` en dur.

```bash
# 1. SSH key (les submodules utilisent git@github.com)
ssh-keygen -t ed25519 -C "your@email"
# Ajouter sur GitHub : https://github.com/settings/keys

# 2. Clone et install
git clone --recursive git@github.com:Hugo-Fabresse/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh

# 3. (optionnel) Restaurer TOUS les packages (112 pacman + 7 AUR + flatpaks)
~/dotfiles/scripts/pkgsync.sh restore
```

Le bootstrap installe les packages essentiels au desktop. Pour retrouver l'environnement complet (lazygit, docker, btop, discord, etc.), lancer `pkgsync.sh restore` apres.

---

## What bootstrap.sh does

| Step | Detail |
|------|--------|
| **Prerequisites** | Checks for SSH key + git |
| **Pacman** | Installs all packages (hyprland, waybar, kitty, fzf, pacman-contrib, etc.) |
| **yay** | Auto-installs yay if missing, then installs AUR packages (maplemono-otf, dentry) |
| **Flatpak** | Reads `flatpak.txt` and installs all listed apps (Spotify, Steam) |
| **Oh My Zsh** | Installs OMZ + plugins (autosuggestions, syntax-highlighting) |
| **Shell** | Sets zsh as default shell |
| **Submodules** | `git submodule update --init --recursive` |
| **Symlinks** | Links config dirs to `~/.config/` and zshrc to `~/.zshrc` |
| **Scripts** | Copies widget scripts to `~/.local/bin/`, shell scripts to `~/.local/share/hypr/` |
| **Build** | Builds ash and dentry from source, installs to `~/.local/bin/` |
| **Services** | Enables NetworkManager |
| **Cron** | Autopush dotfiles every Friday at 18:00 |

---

## Stack

- **WM** : Hyprland
- **Bar** : Waybar
- **Launcher** : Wofi
- **Terminal** : Kitty
- **Shell** : Zsh + Oh My Zsh (theme: bureau)
- **Editor** : Neovim (Nihil)
- **Browser** : Qutebrowser
- **Notifications** : Dunst
- **Lock** : Hyprlock
- **Background** : Swaybg (black)
- **File manager** : [Dentry](https://github.com/Hugo-Fabresse/dentry) (C++/Qt6)
- **Spotify PiP** : [Ash](https://github.com/Hugo-Fabresse/ash) (C++/Qt6)
- **Widgets** : Calendar, Volume Input, Notification Panel (PyQt6)

---

## Package sync

The repo tracks the full list of installed packages so you can restore your exact environment on a new machine.

```bash
# Save current state
~/dotfiles/scripts/pkgsync.sh save

# Restore on a new machine
~/dotfiles/scripts/pkgsync.sh restore
```

| File | Content |
|------|---------|
| `pkglist.txt` | Official pacman packages (`pacman -Qqe` minus AUR) |
| `pkglist-aur.txt` | AUR packages (`pacman -Qqem`) |
| `flatpak.txt` | Flatpak apps |

Run `pkgsync.sh save` after installing or removing packages to keep the lists up to date.

> `bootstrap.sh` installe les ~30 packages essentiels au desktop. `pkgsync.sh restore` installe les 112+ packages complets (dev tools, docker, lazygit, etc.).

---

## Structure

```
dotfiles/
├── bootstrap.sh           # Full setup from scratch
├── pkglist.txt            # Official pacman packages
├── pkglist-aur.txt        # AUR packages
├── flatpak.txt            # Flatpak apps
├── hypr/                  # Hyprland + Hyprlock config
├── kitty/                 # Kitty terminal config
├── waybar/                # Waybar config + style
├── wofi/                  # Wofi launcher config + style
├── nvim/                  # Neovim (Nihil) config
├── dunst/                 # Dunst notification config
├── qutebrowser/           # Qutebrowser config + dark.css
├── zsh/                   # Zsh config (.zshrc)
├── ash/                   # Spotify PiP controller (C++/Qt6)
├── dentry/                # File manager (C++/Qt6)
└── scripts/
    ├── autopush.sh        # Weekly auto-push (cron)
    ├── pkgsync.sh         # Save / restore package lists
    ├── update_picker.sh   # Interactive update picker (wofi)
    ├── cliphist.sh        # Clipboard history (wofi)
    ├── force_close.sh     # Kill stubborn apps
    ├── minimize.sh        # Restore minimized windows
    ├── toggle_waybar.sh   # Toggle waybar visibility
    ├── wofi_toggle.sh     # Toggle wofi launcher
    └── bin/
        ├── launch_calendar.sh
        ├── my_calendar.py
        ├── notif_panel.py
        ├── notif_waybar.sh
        └── volume_input.py
```

---

## Keybinds

| Key | Action |
|-----|--------|
| Super + Return | Terminal (Kitty) |
| Super + n | Browser (Qutebrowser) |
| Super + s | Spotify (spotify_player in Kitty) |
| Super + Shift + s | Ash (Spotify PiP toggle) |
| Super + d | Launcher (Wofi) |
| Super + v | Volume input |
| Super + p | Notification panel |
| Super + Shift + p | Clear notification history |
| Super + c | Clipboard history |
| Super + Shift + c | Wipe clipboard |
| Super + u | Update picker |
| Super + q | Close window |
| Super + Shift + q | Exit Hyprland |
| Super + f | Toggle float |
| Super + Space | Fullscreen |
| Super + b | Toggle Waybar |
| Super + m | Minimize to special workspace |
| Super + Shift + m | Restore minimized window |
| Super + Tab | Scratchpad terminal |
| Super + Ctrl + l | Lock screen |
| Super + h/j/k/l | Move focus |
| Super + Shift + arrows | Resize window |
| Super + 1-0 | Switch workspace |
| Super + Shift + 1-0 | Move to workspace |
| Print | Screenshot (full) |
| Shift + Print | Screenshot (selection) |
