#!/usr/bin/env python3
import sys, os
from PyQt6 import QtWidgets, QtGui, QtCore
import dbus
import requests

PID_FILE = "/tmp/spotify_pip.pid"

# Toggle existing instance
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

class SpotifyPiP(QtWidgets.QWidget):

    def __init__(self):
        super().__init__()
        self.setWindowTitle("Spotify PiP")
        self.setFixedSize(220, 340)
        self.setWindowFlag(QtCore.Qt.WindowType.FramelessWindowHint)
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_TranslucentBackground)

        # Layout principal
        self.main_layout = QtWidgets.QVBoxLayout()
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.main_layout.setSpacing(0)
        self.setLayout(self.main_layout)

        # Fond flouté / transparent
        # self.bg_widget = QtWidgets.QWidget(self)
        # self.bg_widget.setStyleSheet("background: transparent; border-radius: 12px;")
        # self.bg_widget.setGeometry(0, 0, 220, 340)
        # self.bg_widget.setAttribute(QtCore.Qt.WidgetAttribute.WA_TransparentForMouseEvents)

        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_TranslucentBackground, True)
        self.setWindowFlag(QtCore.Qt.WindowType.FramelessWindowHint, True)
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_NoSystemBackground, True)
        self.setAutoFillBackground(False)

        # Zone supérieure (artwork)
        self.top_widget = QtWidgets.QWidget()
        self.top_layout = QtWidgets.QVBoxLayout()
        self.top_layout.setContentsMargins(15, 15, 15, 12)
        self.top_layout.setSpacing(12)
        self.top_widget.setLayout(self.top_layout)
        self.main_layout.addWidget(self.top_widget)

        self.artwork_label = QtWidgets.QLabel()
        self.artwork_label.setFixedSize(190, 190)
        self.artwork_label.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        self.artwork_label.setStyleSheet("background: transparent; border-radius: 12px;")
        self.top_layout.addWidget(self.artwork_label, alignment=QtCore.Qt.AlignmentFlag.AlignCenter)

        # Zone inférieure (contrôles)
        self.bottom_widget = QtWidgets.QWidget()
        self.bottom_layout = QtWidgets.QVBoxLayout()
        self.bottom_layout.setContentsMargins(20, 10, 20, 25)
        self.bottom_layout.setSpacing(8)
        self.bottom_widget.setLayout(self.bottom_layout)
        self.main_layout.addWidget(self.bottom_widget)

        # Barre de progression
        progress_container = QtWidgets.QHBoxLayout()
        progress_container.setSpacing(10)
        self.time_label = QtWidgets.QLabel("0:00")
        self.time_label.setStyleSheet("color: #B3B3B3; font-size: 11px;")
        progress_container.addWidget(self.time_label)
        self.progress = QtWidgets.QSlider(QtCore.Qt.Orientation.Horizontal)
        self.progress.setStyleSheet("""
            QSlider::groove:horizontal { border: none; height: 4px; background: #4D4D4D; border-radius: 2px; }
            QSlider::handle:horizontal { background: #FFFFFF; border: none; width: 12px; height: 12px; margin: -4px 0; border-radius: 6px; }
            QSlider::sub-page:horizontal { background: #FFFFFF; border-radius: 2px; }
        """)
        progress_container.addWidget(self.progress, 1)
        self.duration_label = QtWidgets.QLabel("0:00")
        self.duration_label.setStyleSheet("color: #B3B3B3; font-size: 11px;")
        progress_container.addWidget(self.duration_label)
        self.bottom_layout.addLayout(progress_container)

        # Contrôles de lecture
        controls_layout = QtWidgets.QHBoxLayout()
        controls_layout.setSpacing(0)
        controls_layout.setContentsMargins(0, 15, 0, 0)

        self.prev_btn = self.create_button("prev", 50, 50)
        controls_layout.addWidget(self.prev_btn)
        controls_layout.addStretch()
        self.play_btn = self.create_button("play", 64, 64, True)
        controls_layout.addWidget(self.play_btn)
        controls_layout.addStretch()
        self.next_btn = self.create_button("next", 50, 50)
        controls_layout.addWidget(self.next_btn)
        self.bottom_layout.addLayout(controls_layout)

        # DBus setup
        self.session_bus = dbus.SessionBus()
        self.spotify = self.session_bus.get_object("org.mpris.MediaPlayer2.spotify",
                                                   "/org/mpris/MediaPlayer2")
        self.iface = dbus.Interface(self.spotify, dbus_interface="org.mpris.MediaPlayer2.Player")
        self.props_iface = dbus.Interface(self.spotify, dbus_interface="org.freedesktop.DBus.Properties")

        # Connect buttons
        self.play_btn.clicked.connect(lambda: self.iface.PlayPause())
        self.next_btn.clicked.connect(lambda: self.iface.Next())
        self.prev_btn.clicked.connect(lambda: self.iface.Previous())

        # Timer
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.update_metadata)
        self.timer.start(500)
        self.update_metadata()

    def create_button(self, icon_type, w, h, is_play=False):
        btn = QtWidgets.QPushButton()
        btn.setIcon(self.create_icon(icon_type))
        btn.setIconSize(QtCore.QSize(32, 32))
        btn.setFixedSize(w, h)
        if is_play:
            btn.setStyleSheet("""
                QPushButton { background-color: #FFFFFF; border: none; border-radius: 32px; color: #000000; }
                QPushButton:hover { background-color: #F0F0F0; }
            """)
        else:
            btn.setStyleSheet("""
                QPushButton { background: transparent; border: none; color: #B3B3B3; }
                QPushButton:hover { color: #FFFFFF; }
            """)
        return btn

    def create_icon(self, icon_type):
        pixmap = QtGui.QPixmap(32, 32)
        pixmap.fill(QtCore.Qt.GlobalColor.transparent)
        painter = QtGui.QPainter(pixmap)
        painter.setRenderHint(QtGui.QPainter.RenderHint.Antialiasing)
        if icon_type == "play":
            painter.setPen(QtCore.Qt.PenStyle.NoPen)
            painter.setBrush(QtGui.QBrush(QtGui.QColor("#000000")))
            points = [QtCore.QPointF(10, 8), QtCore.QPointF(10, 24), QtCore.QPointF(24, 16)]
            painter.drawPolygon(points)
        elif icon_type == "pause":
            painter.setPen(QtCore.Qt.PenStyle.NoPen)
            painter.setBrush(QtGui.QBrush(QtGui.QColor("#000000")))
            painter.drawRect(9, 8, 4, 16)
            painter.drawRect(19, 8, 4, 16)
        elif icon_type == "prev":
            painter.setPen(QtCore.Qt.PenStyle.NoPen)
            painter.setBrush(QtGui.QBrush(QtGui.QColor("#B3B3B3")))
            painter.drawRect(8, 10, 2, 12)
            points = [QtCore.QPointF(24, 10), QtCore.QPointF(24, 22), QtCore.QPointF(12, 16)]
            painter.drawPolygon(points)
        elif icon_type == "next":
            painter.setPen(QtCore.Qt.PenStyle.NoPen)
            painter.setBrush(QtGui.QBrush(QtGui.QColor("#B3B3B3")))
            painter.drawRect(22, 10, 2, 12)
            points = [QtCore.QPointF(8, 10), QtCore.QPointF(8, 22), QtCore.QPointF(20, 16)]
            painter.drawPolygon(points)
        painter.end()
        return QtGui.QIcon(pixmap)

    def format_time(self, seconds):
        minutes = int(seconds // 60)
        secs = int(seconds % 60)
        return f"{minutes}:{secs:02d}"

    def update_metadata(self):
        try:
            metadata = self.props_iface.Get("org.mpris.MediaPlayer2.Player", "Metadata")
            arturl = str(metadata.get("mpris:artUrl", ""))
            if arturl.startswith("file://"):
                arturl = arturl[7:]
                pix = QtGui.QPixmap(arturl)
            elif arturl.startswith("http"):
                r = requests.get(arturl, timeout=5)
                pix = QtGui.QPixmap()
                pix.loadFromData(r.content)
            else:
                pix = QtGui.QPixmap(190, 190)
                pix.fill(QtGui.QColor("#282828"))

            scaled_pix = pix.scaled(190, 190,
                                    QtCore.Qt.AspectRatioMode.KeepAspectRatio,
                                    QtCore.Qt.TransformationMode.SmoothTransformation)
            rounded_pix = QtGui.QPixmap(190, 190)
            rounded_pix.fill(QtCore.Qt.GlobalColor.transparent)
            painter = QtGui.QPainter(rounded_pix)
            painter.setRenderHint(QtGui.QPainter.RenderHint.Antialiasing)
            path = QtGui.QPainterPath()
            path.addRoundedRect(0, 0, 190, 190, 12, 12)
            painter.setClipPath(path)
            painter.drawPixmap(0, 0, scaled_pix)
            painter.end()
            self.artwork_label.setPixmap(rounded_pix)

            # Progression
            length = metadata.get("mpris:length", 0) / 1_000_000
            pos = self.props_iface.Get("org.mpris.MediaPlayer2.Player", "Position") / 1_000_000
            if length > 0:
                self.progress.setMaximum(int(length))
                self.progress.setValue(int(pos))
                self.time_label.setText(self.format_time(pos))
                self.duration_label.setText(self.format_time(length))

            # Play/pause
            playback_status = self.props_iface.Get("org.mpris.MediaPlayer2.Player", "PlaybackStatus")
            if playback_status == "Playing":
                self.play_btn.setIcon(self.create_icon("pause"))
            else:
                self.play_btn.setIcon(self.create_icon("play"))

        except Exception as e:
            print(f"Erreur: {e}")

# App launch
QtWidgets.QApplication.setAttribute(QtCore.Qt.ApplicationAttribute.AA_UseDesktopOpenGL)
fmt = QtGui.QSurfaceFormat()
fmt.setAlphaBufferSize(8)
QtGui.QSurfaceFormat.setDefaultFormat(fmt)
app = QtWidgets.QApplication(sys.argv)
window = SpotifyPiP()

def move_window():
    screen = QtWidgets.QApplication.primaryScreen()
    geom = screen.geometry()
    window.move(geom.width() - window.width() - 20,
                geom.height() - window.height() - 20)

QtCore.QTimer.singleShot(0, move_window)
window.show()
ret = app.exec()

if os.path.exists(PID_FILE):
    os.remove(PID_FILE)
sys.exit(ret)

