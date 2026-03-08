# dotfiles

Arch Linux — Hyprland setup.
Minimal, black, no noise.

---

## Stack

- **WM** : Hyprland
- **Bar** : Waybar
- **Launcher** : Wofi
- **Terminal** : Kitty
- **Shell** : Zsh + Oh My Zsh (theme: bureau)
- **Notifications** : Mako
- **Lock** : Hyprlock
- **Background** : Swaybg (black)
- **Widgets** : Calendar, Spotify PiP, Volume Input (PyQt6)

---

## Dependencies

```bash
# Core
sudo pacman -S hyprland hyprlock swaybg waybar wofi mako kitty

# Audio
sudo pacman -S pipewire pipewire-pulse wireplumber pavucontrol

# Network
sudo pacman -S networkmanager network-manager-applet

# Brightness / Screenshots
sudo pacman -S brightnessctl grim slurp

# Python widgets
sudo pacman -S python python-pyqt6 python-requests python-dbus

# Fonts
sudo pacman -S ttf-jetbrains-mono-nerd
yay -S maplemono-otf

# Flatpak (Spotify)
sudo pacman -S flatpak
flatpak install flathub com.spotify.Client

# Zsh
sudo pacman -S zsh zsh-autosuggestions zsh-syntax-highlighting fastfetch
chsh -s /usr/bin/zsh

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Oh My Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Enable NetworkManager
sudo systemctl enable --now NetworkManager
```

---

## Install

Backup your existing config first.

```bash
mv ~/.config/hypr ~/.config/hypr.bak
mv ~/.config/kitty ~/.config/kitty.bak
mv ~/.config/waybar ~/.config/waybar.bak
mv ~/.config/wofi ~/.config/wofi.bak
mv ~/.zshrc ~/.zshrc.bak
```

Clone the repo and create symlinks.

```bash
git clone https://github.com/Hugo-Fabresse/dotfiles.git ~/dotfiles

ln -s ~/dotfiles/hypr ~/.config/hypr
ln -s ~/dotfiles/kitty ~/.config/kitty
ln -s ~/dotfiles/waybar ~/.config/waybar
ln -s ~/dotfiles/wofi ~/.config/wofi
ln -s ~/dotfiles/zshrc ~/.zshrc
```

Copy the widget scripts.

```bash
mkdir -p ~/.local/bin
cp ~/dotfiles/hypr/bin/* ~/.local/bin/
chmod +x ~/.local/bin/*.py

mkdir -p ~/.local/share/hypr
ln -s ~/dotfiles/hypr/waybar ~/.local/share/hypr/waybar
cp ~/dotfiles/hypr/toggle_waybar.sh ~/.local/share/hypr/toggle_waybar.sh
cp ~/dotfiles/hypr/wofi_toggle.sh ~/.local/share/hypr/wofi_toggle.sh
chmod +x ~/.local/share/hypr/*.sh
```

Set Kitty to use Zsh.

```bash
echo "shell /usr/bin/zsh" >> ~/.config/kitty/kitty.conf
```

Reboot or restart Hyprland.

```bash
hyprctl reload
```

---

## Structure

```
dotfiles/
├── hypr/
│   ├── hyprland.conf
│   ├── hyprlock.conf
│   ├── startup_bg.sh
│   ├── toggle_waybar.sh
│   ├── wofi_toggle.sh
│   ├── waybar/
│   │   ├── config
│   │   └── style.css
│   └── bin/
│       ├── my_calendar.py
│       ├── spotify-pip.py
│       └── volume_input.py
├── kitty/
│   └── kitty.conf
├── waybar/
│   ├── config
│   └── style.css
├── wofi/
│   ├── config
│   └── style.css
└── zshrc
```

---

## Keybinds

| Key | Action |
|-----|--------|
| Super + Return | Terminal |
| Super + n | Browser |
| Super + s | Spotify |
| Super + Shift + s | Spotify PiP |
| Super + d | Launcher |
| Super + v | Volume input |
| Super + q | Close window |
| Super + f | Toggle float |
| Super + Space | Fullscreen |
| Super + b | Toggle Waybar |
| Super + Ctrl + l | Lock screen |
| Super + h/j/k/l | Move focus |
| Super + Shift + h/j/k/l | Move window |
| Super + 1-0 | Switch workspace |
| Super + Shift + 1-0 | Move to workspace |
| Print | Screenshot |
| Shift + Print | Screenshot selection |
