#!/usr/bin/env python3
import sys, os
from PyQt6 import QtWidgets, QtCore, QtGui
import subprocess

PID_FILE = "/tmp/volume_input.pid"

# Kill existing instance
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

class VolumeInput(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Volume Input")
        self.setFixedSize(180, 80)

        # Flags pour overlay minimal
        self.setWindowFlags(
            QtCore.Qt.WindowType.FramelessWindowHint |
            QtCore.Qt.WindowType.WindowStaysOnTopHint |
            QtCore.Qt.WindowType.Tool
        )
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_StyledBackground)
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_TranslucentBackground)

        # Layout minimaliste
        layout = QtWidgets.QVBoxLayout()
        layout.setContentsMargins(20, 15, 20, 15)
        layout.setSpacing(8)
        self.setLayout(layout)

        # Label minimal
        label = QtWidgets.QLabel("Volume")
        label.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        label.setStyleSheet("color: #B3B3B3; font-size: 12px;")
        layout.addWidget(label)

        # Input
        self.input = QtWidgets.QLineEdit()
        self.input.setPlaceholderText("0-100")
        self.input.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        self.input.setFixedHeight(32)
        self.input.setStyleSheet("""
            QLineEdit {
                border: none;
                border-radius: 8px;
                font-size: 18px;
                font-weight: bold;
                color: #FFFFFF;
                background-color: rgba(255, 255, 255, 0.1);
                selection-background-color: transparent;
                qproperty-cursorWidth: 0;
            }
            QLineEdit:focus {
                background-color: rgba(255, 255, 255, 0.15);
            }
        """)
        self.input.returnPressed.connect(self.set_volume)
        layout.addWidget(self.input)

        # Focus initial
        self.input.setFocus()

        # Signal pour fermer si focus perdu
        QtWidgets.QApplication.instance().focusChanged.connect(self.on_focus_changed)

    def set_volume(self):
        try:
            value = int(self.input.text())
            if 0 <= value <= 100:
                subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{value}%"])
        except ValueError:
            pass
        self.cleanup_and_close()

    def cleanup_and_close(self):
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)
        self.close()
        sys.exit(0)

    def focusOutEvent(self, event):
        self.cleanup_and_close()

    def on_focus_changed(self, old, new):
        if old is not None and old is self.input and (new is None or not self.isAncestorOf(new)):
            self.cleanup_and_close()

    def keyPressEvent(self, event):
        if event.key() == QtCore.Qt.Key.Key_Escape:
            self.cleanup_and_close()


# App launch
app = QtWidgets.QApplication(sys.argv)
window = VolumeInput()

# Positionnement en bas à droite
def move_window():
    screen = QtWidgets.QApplication.primaryScreen()
    geom = screen.geometry()
    window.move(
        geom.width() - window.width() - 20,
        geom.height() - window.height() - 60
    )

QtCore.QTimer.singleShot(0, move_window)
window.show()
ret = app.exec()

if os.path.exists(PID_FILE):
    os.remove(PID_FILE)
sys.exit(ret)

