#!/usr/bin/env python3
"""
Notification panel — pixel-identical to wofi style.
Toggle via PID file, same pattern as other Hyprland widgets.
"""
import sys, os, json, subprocess, math
from PyQt6 import QtWidgets, QtCore, QtGui

PID_FILE = "/tmp/hypr_notif_panel.pid"

if os.path.exists(PID_FILE):
    with open(PID_FILE, "r") as f:
        pid = int(f.read())
    try:
        os.kill(pid, 9)
    except ProcessLookupError:
        pass
    os.remove(PID_FILE)
    sys.exit(0)

with open(PID_FILE, "w") as f:
    f.write(str(os.getpid()))


# ── Wofi exact values ──────────────────────────────────────────
WINDOW_W         = 520
WINDOW_H         = 400
WINDOW_RADIUS    = 8
BORDER_COLOR     = QtGui.QColor(255, 255, 255, 25)   # rgba(255,255,255,0.1)
SEPARATOR_COLOR  = QtGui.QColor(255, 255, 255, 20)   # rgba(255,255,255,0.08)

FONT_FAMILY      = "JetBrainsMono Nerd Font"
TEXT_PX           = 13
INPUT_PX         = 15

# #entry padding
ENTRY_PAD_TOP    = 6
ENTRY_PAD_BOT    = 6
ENTRY_PAD_LEFT   = 20
ENTRY_PAD_RIGHT  = 22

# #entry:selected
SEL_RADIUS       = 6
SEL_MARGIN       = 6
SEL_PAD_LEFT     = 30

# #inner-box padding
LIST_PAD_TOP     = 8
LIST_PAD_BOT     = 8

# #input padding
INPUT_PAD_TOP    = 12
INPUT_PAD_BOT    = 12
INPUT_PAD_LEFT   = 12
INPUT_PAD_RIGHT  = 22


def get_notifications():
    try:
        result = subprocess.run(
            ["dunstctl", "history"],
            capture_output=True, text=True, timeout=2
        )
        data = json.loads(result.stdout)
        notifs = []
        for entry in data.get("data", [[]])[0]:
            appname = entry.get("appname", {}).get("data", "")
            summary = entry.get("summary", {}).get("data", "")
            body = entry.get("body", {}).get("data", "")
            notifs.append((appname, summary, body))
        return notifs
    except Exception:
        return []


def make_font(px, bold=False):
    f = QtGui.QFont(FONT_FAMILY)
    f.setPixelSize(px)
    f.setBold(bold)
    return f


class NotifPanel(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Notification Panel")
        self.setFixedSize(WINDOW_W, WINDOW_H)

        self.setWindowFlags(
            QtCore.Qt.WindowType.FramelessWindowHint
            | QtCore.Qt.WindowType.WindowStaysOnTopHint
            | QtCore.Qt.WindowType.Tool
        )
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_StyledBackground)
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setMouseTracking(True)

        self.all_texts = get_notifications()
        self.filtered = list(self.all_texts)
        self.selected = 0 if self.filtered else -1
        self.scroll_offset = 0
        self.query = ""
        self.cursor_visible = True

        # Cursor blink timer
        self.blink_timer = QtCore.QTimer(self)
        self.blink_timer.timeout.connect(self._blink)
        self.blink_timer.start(530)

    # ── geometry helpers ───────────────────────────────────────
    def _input_rect(self):
        """Full input area rect"""
        fm = QtGui.QFontMetrics(make_font(INPUT_PX, bold=True))
        h = INPUT_PAD_TOP + fm.height() + INPUT_PAD_BOT
        return QtCore.QRectF(0, 0, self.width(), h)

    def _list_top(self):
        return self._input_rect().height() + 1  # +1 for separator

    def _entry_height(self):
        fm_app = QtGui.QFontMetrics(make_font(9))
        fm_sum = QtGui.QFontMetrics(make_font(TEXT_PX, bold=True))
        fm_body = QtGui.QFontMetrics(make_font(TEXT_PX))
        return ENTRY_PAD_TOP + fm_app.height() + fm_sum.height() + fm_body.height() + ENTRY_PAD_BOT

    def _visible_count(self):
        avail = self.height() - self._list_top() - LIST_PAD_TOP - LIST_PAD_BOT
        return max(1, int(avail / self._entry_height()))

    # ── painting ───────────────────────────────────────────────
    def paintEvent(self, event):
        p = QtGui.QPainter(self)
        p.setRenderHint(QtGui.QPainter.RenderHint.Antialiasing)

        w, h = self.width(), self.height()
        win_rect = QtCore.QRectF(0, 0, w, h)

        # Clip to rounded window
        clip = QtGui.QPainterPath()
        clip.addRoundedRect(win_rect, WINDOW_RADIUS, WINDOW_RADIUS)
        p.setClipPath(clip)

        # Window border — 1px solid rgba(255,255,255,0.1)
        pen = QtGui.QPen(BORDER_COLOR)
        pen.setWidthF(1)
        p.setPen(pen)
        p.setBrush(QtCore.Qt.BrushStyle.NoBrush)
        p.drawRoundedRect(win_rect.adjusted(0.5, 0.5, -0.5, -0.5), WINDOW_RADIUS, WINDOW_RADIUS)

        # ── #input ─────────────────────────────────────────────
        input_r = self._input_rect()
        input_font = make_font(INPUT_PX, bold=True)
        p.setFont(input_font)
        fm_input = QtGui.QFontMetrics(input_font)

        # Search icon — hand-drawn to match Adwaita GTK search icon
        # Circle + diagonal handle, same proportions as the Adwaita SVG
        icon_size = 16
        icon_cx = INPUT_PAD_LEFT + icon_size / 2
        icon_cy = INPUT_PAD_TOP + fm_input.height() / 2
        circle_r = icon_size * 0.35  # lens radius
        pen = QtGui.QPen(QtGui.QColor(255, 255, 255, 204))  # 0.8 opacity
        pen.setWidthF(1.8)
        pen.setCapStyle(QtCore.Qt.PenCapStyle.RoundCap)
        p.setPen(pen)
        p.setBrush(QtCore.Qt.BrushStyle.NoBrush)
        # Lens circle — slightly up-left of center
        lens_cx = icon_cx - 1
        lens_cy = icon_cy - 1
        p.drawEllipse(QtCore.QPointF(lens_cx, lens_cy), circle_r, circle_r)
        # Handle — from bottom-right of circle, going down-right
        angle = math.radians(45)
        hx1 = lens_cx + circle_r * math.cos(angle)
        hy1 = lens_cy + circle_r * math.sin(angle)
        handle_len = icon_size * 0.3
        hx2 = hx1 + handle_len * math.cos(angle)
        hy2 = hy1 + handle_len * math.sin(angle)
        p.drawLine(QtCore.QPointF(hx1, hy1), QtCore.QPointF(hx2, hy2))

        # Clear button — right side of input bar
        clear_font = make_font(11)
        fm_clear = QtGui.QFontMetrics(clear_font)
        clear_text = "clear"
        clear_tw = fm_clear.horizontalAdvance(clear_text)
        clear_pad_h = 10
        clear_pad_v = 4
        clear_w = clear_tw + clear_pad_h * 2
        clear_h = fm_clear.height() + clear_pad_v * 2
        clear_x = w - INPUT_PAD_RIGHT - clear_w
        clear_y = INPUT_PAD_TOP + (fm_input.height() - clear_h) / 2
        self._clear_rect = QtCore.QRectF(clear_x, clear_y, clear_w, clear_h)

        # Draw clear button
        hovering_clear = hasattr(self, '_mouse_pos') and self._clear_rect.contains(self._mouse_pos)
        if hovering_clear:
            p.setPen(QtCore.Qt.PenStyle.NoPen)
            p.setBrush(QtGui.QColor("#ffffff"))
            p.drawRoundedRect(self._clear_rect, 4, 4)
            p.setFont(clear_font)
            p.setPen(QtGui.QColor("#000000"))
        else:
            p.setPen(QtGui.QPen(QtGui.QColor("#ffffff"), 1))
            p.setBrush(QtCore.Qt.BrushStyle.NoBrush)
            p.drawRoundedRect(self._clear_rect, 4, 4)
            p.setFont(clear_font)
            p.setPen(QtGui.QColor("#ffffff"))
        p.drawText(self._clear_rect, QtCore.Qt.AlignmentFlag.AlignCenter, clear_text)

        # Text area starts after icon, ends before clear button
        icon_advance = icon_size + 8
        text_r = QtCore.QRectF(
            INPUT_PAD_LEFT + icon_advance, INPUT_PAD_TOP,
            clear_x - INPUT_PAD_LEFT - icon_advance - 8, fm_input.height()
        )

        p.setFont(input_font)
        if self.query:
            p.setPen(QtGui.QColor("#ffffff"))
            p.drawText(text_r, QtCore.Qt.AlignmentFlag.AlignVCenter | QtCore.Qt.AlignmentFlag.AlignLeft, self.query)
            # Cursor after text
            if self.cursor_visible:
                cx = text_r.left() + fm_input.horizontalAdvance(self.query)
                p.setPen(QtGui.QColor("#ffffff"))
                p.drawLine(
                    QtCore.QPointF(cx, text_r.top() + 2),
                    QtCore.QPointF(cx, text_r.bottom() - 2)
                )
        else:
            if self.cursor_visible:
                cx = text_r.left()
                p.setPen(QtGui.QColor("#ffffff"))
                p.drawLine(
                    QtCore.QPointF(cx, text_r.top() + 2),
                    QtCore.QPointF(cx, text_r.bottom() - 2)
                )

        # Separator — border-bottom: 1px solid rgba(255,255,255,0.08)
        sep_y = input_r.bottom()
        p.setPen(QtGui.QPen(SEPARATOR_COLOR, 1))
        p.drawLine(QtCore.QPointF(0, sep_y), QtCore.QPointF(w, sep_y))

        # ── entries ────────────────────────────────────────────
        app_font = make_font(9)
        sum_font = make_font(TEXT_PX, bold=True)
        body_font = make_font(TEXT_PX)
        fm_app = QtGui.QFontMetrics(app_font)
        fm_sum = QtGui.QFontMetrics(sum_font)
        fm_body = QtGui.QFontMetrics(body_font)
        eh = self._entry_height()
        vis = self._visible_count()
        top = self._list_top() + LIST_PAD_TOP

        if not self.filtered:
            p.setFont(body_font)
            p.setPen(QtGui.QColor(255, 255, 255, 51))
            empty_r = QtCore.QRectF(0, top, w, self.height() - top)
            p.drawText(empty_r, QtCore.Qt.AlignmentFlag.AlignCenter, "aucune notification")
        else:
            if self.selected < self.scroll_offset:
                self.scroll_offset = self.selected
            elif self.selected >= self.scroll_offset + vis:
                self.scroll_offset = self.selected - vis + 1

            for i in range(vis):
                idx = self.scroll_offset + i
                if idx >= len(self.filtered):
                    break

                y = top + i * eh
                is_sel = (idx == self.selected)
                appname, summary, body = self.filtered[idx]

                pad_left = SEL_MARGIN + SEL_PAD_LEFT if is_sel else ENTRY_PAD_LEFT
                text_w = (w - 2 * SEL_MARGIN - SEL_PAD_LEFT - ENTRY_PAD_RIGHT) if is_sel else (w - ENTRY_PAD_LEFT - ENTRY_PAD_RIGHT)

                if is_sel:
                    sel_rect = QtCore.QRectF(SEL_MARGIN, y, w - 2 * SEL_MARGIN, eh)
                    p.setPen(QtCore.Qt.PenStyle.NoPen)
                    p.setBrush(QtGui.QColor("#ffffff"))
                    p.drawRoundedRect(sel_rect, SEL_RADIUS, SEL_RADIUS)

                cy = y + ENTRY_PAD_TOP

                # Line 1: appname (small, dimmed)
                p.setFont(app_font)
                p.setPen(QtGui.QColor(0, 0, 0, 128) if is_sel else QtGui.QColor(255, 255, 255, 128))
                app_r = QtCore.QRectF(pad_left, cy, text_w, fm_app.height())
                elided_app = fm_app.elidedText(appname, QtCore.Qt.TextElideMode.ElideRight, int(text_w))
                p.drawText(app_r, QtCore.Qt.AlignmentFlag.AlignVCenter | QtCore.Qt.AlignmentFlag.AlignLeft, elided_app)
                cy += fm_app.height()

                # Line 2: summary (bold)
                p.setFont(sum_font)
                p.setPen(QtGui.QColor("#000000") if is_sel else QtGui.QColor("#ffffff"))
                sum_r = QtCore.QRectF(pad_left, cy, text_w, fm_sum.height())
                elided_sum = fm_sum.elidedText(summary, QtCore.Qt.TextElideMode.ElideRight, int(text_w))
                p.drawText(sum_r, QtCore.Qt.AlignmentFlag.AlignVCenter | QtCore.Qt.AlignmentFlag.AlignLeft, elided_sum)
                cy += fm_sum.height()

                # Line 3: body (dimmed)
                p.setFont(body_font)
                p.setPen(QtGui.QColor(0, 0, 0, 166) if is_sel else QtGui.QColor(255, 255, 255, 166))
                body_r = QtCore.QRectF(pad_left, cy, text_w, fm_body.height())
                elided_body = fm_body.elidedText(body, QtCore.Qt.TextElideMode.ElideRight, int(text_w))
                p.drawText(body_r, QtCore.Qt.AlignmentFlag.AlignVCenter | QtCore.Qt.AlignmentFlag.AlignLeft, elided_body)

        p.end()

    # ── mouse ──────────────────────────────────────────────────
    def mouseMoveEvent(self, event):
        self._mouse_pos = event.position()
        top = self._list_top() + LIST_PAD_TOP
        eh = self._entry_height()
        y = event.position().y()
        if y >= top:
            row = int((y - top) / eh)
            idx = self.scroll_offset + row
            if 0 <= idx < len(self.filtered) and idx != self.selected:
                self.selected = idx
        self.update()

    def mousePressEvent(self, event):
        pos = event.position()
        if hasattr(self, '_clear_rect') and self._clear_rect.contains(pos):
            subprocess.run(["dunstctl", "history-clear"], capture_output=True)
            self.all_texts = []
            self.filtered = []
            self.selected = -1
            self.scroll_offset = 0
            self.query = ""
            self.update()
            return
        self.close()

    # ── keyboard ───────────────────────────────────────────────
    def keyPressEvent(self, event):
        key = event.key()
        text = event.text()

        if key == QtCore.Qt.Key.Key_Escape:
            self.close()
        elif key == QtCore.Qt.Key.Key_Return or key == QtCore.Qt.Key.Key_Enter:
            self.close()
        elif key == QtCore.Qt.Key.Key_Down:
            if self.filtered and self.selected < len(self.filtered) - 1:
                self.selected += 1
                self.update()
        elif key == QtCore.Qt.Key.Key_Up:
            if self.filtered and self.selected > 0:
                self.selected -= 1
                self.update()
        elif key == QtCore.Qt.Key.Key_Backspace:
            if self.query:
                self.query = self.query[:-1]
                self._refilter()
        elif text and text.isprintable():
            self.query += text
            self._refilter()

    def _refilter(self):
        q = self.query.lower()
        self.filtered = [t for t in self.all_texts if q in f"{t[0]} {t[1]} {t[2]}".lower()]
        self.selected = 0 if self.filtered else -1
        self.scroll_offset = 0
        self.update()

    def _blink(self):
        self.cursor_visible = not self.cursor_visible
        self.update()

    def wheelEvent(self, event):
        delta = event.angleDelta().y()
        if delta > 0 and self.scroll_offset > 0:
            self.scroll_offset -= 1
            self.update()
        elif delta < 0 and self.scroll_offset < len(self.filtered) - self._visible_count():
            self.scroll_offset += 1
            self.update()


app = QtWidgets.QApplication(sys.argv)
app.setFont(make_font(TEXT_PX))

win = NotifPanel()

screen = app.primaryScreen().geometry()
win.move(screen.width() - win.width() - 12, 36)

win.show()
app.exec()

if os.path.exists(PID_FILE):
    os.remove(PID_FILE)
