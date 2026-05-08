# ───────────────────────────────────────────
# qutebrowser — configuration minimaliste
# DA : noir absolu, blanc pur, zero bruit
# Discipline : rapidite, silence, efficacite
# ───────────────────────────────────────────

config.load_autoconfig(False)

# ───────────────────────────────────────────
# GENERAL
# ───────────────────────────────────────────
c.url.default_page = "https://www.google.com"
c.url.start_pages = ["https://www.google.com"]
c.url.searchengines = {"DEFAULT": "https://www.google.com/search?q={}"}

# Fake Chrome user-agent (Google login)
config.set("content.headers.user_agent",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "https://*.google.com/*")

# ───────────────────────────────────────────
# DARK MODE — noir absolu sur les pages web
# ───────────────────────────────────────────
c.colors.webpage.bg = "#000000"
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.page = "always"
c.colors.webpage.darkmode.policy.images = "never"

# ───────────────────────────────────────────
# FONTS — Maple Mono NF partout
# ───────────────────────────────────────────
c.fonts.default_family = "Maple Mono NF"
c.fonts.default_size = "11px"
c.fonts.web.family.fixed = "Maple Mono NF"
c.fonts.statusbar = "bold 11px Maple Mono NF"
c.fonts.tabs.selected = "bold 11px Maple Mono NF"
c.fonts.tabs.unselected = "11px Maple Mono NF"
c.fonts.hints = "bold 11px Maple Mono NF"
c.fonts.completion.entry = "11px Maple Mono NF"
c.fonts.completion.category = "bold 11px Maple Mono NF"
c.fonts.downloads = "11px Maple Mono NF"
c.fonts.keyhint = "11px Maple Mono NF"
c.fonts.prompts = "11px Maple Mono NF"

# ───────────────────────────────────────────
# TABS — style waybar (noir, actif = blanc inverse)
# ───────────────────────────────────────────
c.tabs.position = "top"
c.tabs.show = "multiple"
c.tabs.padding = {"top": 4, "bottom": 4, "left": 10, "right": 10}
c.tabs.indicator.width = 0
c.tabs.favicons.show = "never"
c.tabs.title.format = "{audio}{index}: {current_title}"
c.tabs.last_close = "close"
c.tabs.mousewheel_switching = False

# Tab bar
c.colors.tabs.bar.bg = "#000000"

# Tab active — blanc sur noir (comme workspace actif waybar)
c.colors.tabs.selected.even.bg = "#ffffff"
c.colors.tabs.selected.even.fg = "#000000"
c.colors.tabs.selected.odd.bg = "#ffffff"
c.colors.tabs.selected.odd.fg = "#000000"

# Tabs inactives — gris discret
c.colors.tabs.even.bg = "#000000"
c.colors.tabs.even.fg = "#aaaaaa"
c.colors.tabs.odd.bg = "#000000"
c.colors.tabs.odd.fg = "#aaaaaa"

# Tab pinned
c.colors.tabs.pinned.selected.even.bg = "#ffffff"
c.colors.tabs.pinned.selected.even.fg = "#000000"
c.colors.tabs.pinned.selected.odd.bg = "#ffffff"
c.colors.tabs.pinned.selected.odd.fg = "#000000"
c.colors.tabs.pinned.even.bg = "#000000"
c.colors.tabs.pinned.even.fg = "#aaaaaa"
c.colors.tabs.pinned.odd.bg = "#000000"
c.colors.tabs.pinned.odd.fg = "#aaaaaa"

# ───────────────────────────────────────────
# STATUSBAR — noir, texte blanc, discret
# ───────────────────────────────────────────
c.statusbar.show = "in-mode"
c.statusbar.padding = {"top": 4, "bottom": 4, "left": 10, "right": 10}

c.colors.statusbar.normal.bg = "#000000"
c.colors.statusbar.normal.fg = "#ffffff"
c.colors.statusbar.insert.bg = "#000000"
c.colors.statusbar.insert.fg = "#559944"
c.colors.statusbar.command.bg = "#000000"
c.colors.statusbar.command.fg = "#ffffff"
c.colors.statusbar.passthrough.bg = "#000000"
c.colors.statusbar.passthrough.fg = "#336699"
c.colors.statusbar.caret.bg = "#000000"
c.colors.statusbar.caret.fg = "#775599"
c.colors.statusbar.url.fg = "#ffffff"
c.colors.statusbar.url.hover.fg = "#aaaaaa"
c.colors.statusbar.url.success.https.fg = "#559944"
c.colors.statusbar.url.error.fg = "#cc3333"
c.colors.statusbar.url.warn.fg = "#999922"
c.colors.statusbar.progress.bg = "#ffffff"

# ───────────────────────────────────────────
# COMPLETION — style wofi (noir, selection blanc inverse)
# ───────────────────────────────────────────
c.colors.completion.fg = "#ffffff"
c.colors.completion.odd.bg = "#000000"
c.colors.completion.even.bg = "#000000"
c.colors.completion.category.bg = "#000000"
c.colors.completion.category.fg = "#ffffff"
c.colors.completion.category.border.top = "#000000"
c.colors.completion.category.border.bottom = "#222222"
c.colors.completion.item.selected.bg = "#ffffff"
c.colors.completion.item.selected.fg = "#000000"
c.colors.completion.item.selected.border.top = "#ffffff"
c.colors.completion.item.selected.border.bottom = "#ffffff"
c.colors.completion.item.selected.match.fg = "#000000"
c.colors.completion.match.fg = "#aaaaaa"
c.colors.completion.scrollbar.bg = "#000000"
c.colors.completion.scrollbar.fg = "#444444"

# ───────────────────────────────────────────
# HINTS — noir sur blanc, net
# ───────────────────────────────────────────
c.hints.border = "1px solid #ffffff"
c.hints.radius = 4
c.colors.hints.bg = "#ffffff"
c.colors.hints.fg = "#000000"
c.colors.hints.match.fg = "#444444"

# ───────────────────────────────────────────
# DOWNLOADS
# ───────────────────────────────────────────
c.colors.downloads.bar.bg = "#000000"
c.colors.downloads.start.bg = "#336699"
c.colors.downloads.start.fg = "#ffffff"
c.colors.downloads.stop.bg = "#559944"
c.colors.downloads.stop.fg = "#ffffff"
c.colors.downloads.error.bg = "#cc3333"
c.colors.downloads.error.fg = "#ffffff"

# ───────────────────────────────────────────
# PROMPTS & MESSAGES
# ───────────────────────────────────────────
c.colors.prompts.bg = "#0d0d0d"
c.colors.prompts.fg = "#ffffff"
c.colors.prompts.border = "1px solid #222222"
c.colors.prompts.selected.bg = "#ffffff"
c.colors.prompts.selected.fg = "#000000"

c.colors.messages.info.bg = "#0d0d0d"
c.colors.messages.info.fg = "#eeeeee"
c.colors.messages.info.border = "#222222"
c.colors.messages.warning.bg = "#0d0d0d"
c.colors.messages.warning.fg = "#cccc44"
c.colors.messages.warning.border = "#222222"
c.colors.messages.error.bg = "#0d0d0d"
c.colors.messages.error.fg = "#ff4444"
c.colors.messages.error.border = "#3a0000"

# ───────────────────────────────────────────
# KEYHINT
# ───────────────────────────────────────────
c.colors.keyhint.bg = "rgba(0, 0, 0, 0.92)"
c.colors.keyhint.fg = "#ffffff"
c.colors.keyhint.suffix.fg = "#aaaaaa"

# ───────────────────────────────────────────
# COMPORTEMENT
# ───────────────────────────────────────────
c.scrolling.smooth = True
c.content.blocking.method = "adblock"
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
]
c.content.autoplay = False
c.content.notifications.enabled = False
c.content.javascript.clipboard = "access"
c.downloads.location.directory = "~/Downloads"
c.editor.command = ["kitty", "--", "nvim", "{file}"]
c.auto_save.session = True
c.confirm_quit = ["downloads"]

# ───────────────────────────────────────────
# KEYBINDS CUSTOM
# ───────────────────────────────────────────
# Les defaults vim sont deja bons (J/K tabs, H/L back/forward,
# o/O open, f/F hints, yy yank, etc.)
# On ajoute uniquement ce qui manque ou ameliore

# Fermer tab avec x (au lieu de d par defaut)
config.bind("x", "tab-close")
config.bind("X", "undo")

# Deplacer les tabs
config.bind("<Ctrl-Shift-l>", "tab-move +")
config.bind("<Ctrl-Shift-h>", "tab-move -")

# Edition dans Neovim depuis un champ texte
config.bind("<Ctrl-e>", "edit-text", mode="insert")

# No scrollbar, pas de bruit
c.scrolling.bar = "never"
