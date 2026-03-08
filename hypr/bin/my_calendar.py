#!/usr/bin/env python3
import sys, os
from PyQt6 import QtWidgets, QtCore, QtGui
from datetime import date
import calendar

PID_FILE = "/tmp/hypr_calendar.pid"

# Toggle logic
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

class CalendarWindow(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        self.today = date.today()
        self.year = self.today.year
        self.month = self.today.month

        self.setWindowTitle("Hyprland Calendar")
        self.setFixedSize(280, 340)
        
        # Flags pour que Hyprland le traite comme une layer
        self.setWindowFlags(
            QtCore.Qt.WindowType.FramelessWindowHint |
            QtCore.Qt.WindowType.WindowStaysOnTopHint |
            QtCore.Qt.WindowType.Tool
        )
        
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_StyledBackground)
        self.setAttribute(QtCore.Qt.WidgetAttribute.WA_TranslucentBackground)

        # Layout principal
        main_layout = QtWidgets.QVBoxLayout()
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)
        self.setLayout(main_layout)

        # Header avec gradient
        header = QtWidgets.QWidget()
        header.setStyleSheet("background: transparent;")
        header_layout = QtWidgets.QVBoxLayout()
        header_layout.setContentsMargins(20, 20, 20, 15)
        header_layout.setSpacing(15)
        header.setLayout(header_layout)

        # Navigation
        nav_layout = QtWidgets.QHBoxLayout()
        nav_layout.setSpacing(0)

        self.prev_btn = QtWidgets.QPushButton("‹")
        self.prev_btn.setFixedSize(40, 40)
        self.prev_btn.setStyleSheet("""
            QPushButton {
                background: transparent;
                border: none;
                color: #B3B3B3;
                font-size: 28px;
                font-weight: bold;
            }
            QPushButton:hover {
                color: #FFFFFF;
            }
        """)
        self.prev_btn.clicked.connect(lambda: self.change_month(-1))

        self.title_label = QtWidgets.QLabel()
        self.title_label.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        self.title_label.setStyleSheet("""
            font-size: 18px;
            font-weight: bold;
            color: #FFFFFF;
        """)

        self.next_btn = QtWidgets.QPushButton("›")
        self.next_btn.setFixedSize(40, 40)
        self.next_btn.setStyleSheet("""
            QPushButton {
                background: transparent;
                border: none;
                color: #B3B3B3;
                font-size: 28px;
                font-weight: bold;
            }
            QPushButton:hover {
                color: #FFFFFF;
            }
        """)
        self.next_btn.clicked.connect(lambda: self.change_month(1))

        nav_layout.addWidget(self.prev_btn)
        nav_layout.addStretch()
        nav_layout.addWidget(self.title_label)
        nav_layout.addStretch()
        nav_layout.addWidget(self.next_btn)

        header_layout.addLayout(nav_layout)

        # Jours de la semaine
        weekdays_layout = QtWidgets.QHBoxLayout()
        weekdays_layout.setSpacing(0)
        for day in ['L', 'M', 'M', 'J', 'V', 'S', 'D']:
            label = QtWidgets.QLabel(day)
            label.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
            label.setStyleSheet("""
                color: #B3B3B3;
                font-size: 11px;
                font-weight: bold;
            """)
            label.setFixedHeight(20)
            weekdays_layout.addWidget(label)
        
        header_layout.addLayout(weekdays_layout)
        main_layout.addWidget(header)

        # Grille des jours
        days_widget = QtWidgets.QWidget()
        days_widget.setStyleSheet("background-color: transparent;")
        self.days_layout = QtWidgets.QGridLayout()
        self.days_layout.setContentsMargins(10, 10, 10, 10)
        self.days_layout.setSpacing(2)
        days_widget.setLayout(self.days_layout)
        main_layout.addWidget(days_widget)

        self.day_labels = []
        for row in range(6):
            for col in range(7):
                label = QtWidgets.QLabel()
                label.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
                label.setFixedSize(34, 34)
                label.setStyleSheet("""
                    color: #FFFFFF;
                    font-size: 13px;
                    border-radius: 17px;
                """)
                self.days_layout.addWidget(label, row, col)
                self.day_labels.append(label)

        self.render()

    def render(self):
        # Mise à jour du titre
        month_name = calendar.month_name[self.month]
        self.title_label.setText(f"{month_name} {self.year}")

        # Obtenir le calendrier du mois
        cal = calendar.monthcalendar(self.year, self.month)
        
        # Réinitialiser tous les labels
        for label in self.day_labels:
            label.setText("")
            label.setStyleSheet("""
                color: #FFFFFF;
                font-size: 13px;
                border-radius: 17px;
                background: transparent;
            """)

        # Remplir les jours
        idx = 0
        for week in cal:
            for day in week:
                if idx < len(self.day_labels):
                    if day == 0:
                        self.day_labels[idx].setText("")
                    else:
                        self.day_labels[idx].setText(str(day))
                        
                        # Marquer le jour actuel
                        if (day == self.today.day and 
                            self.month == self.today.month and 
                            self.year == self.today.year):
                            self.day_labels[idx].setStyleSheet("""
                                color: #000000;
                                font-size: 13px;
                                font-weight: bold;
                                border-radius: 17px;
                                background: #FFFFFF;
                            """)
                    idx += 1

    def change_month(self, delta):
        self.month += delta
        if self.month > 12:
            self.month = 1
            self.year += 1
        elif self.month < 1:
            self.month = 12
            self.year -= 1
        self.render()

    def focusOutEvent(self, event):
        self.close()

    def keyPressEvent(self, event):
        # Navigation avec flèches
        if event.key() == QtCore.Qt.Key.Key_Left:
            self.change_month(-1)
        elif event.key() == QtCore.Qt.Key.Key_Right:
            self.change_month(1)

app = QtWidgets.QApplication(sys.argv)
win = CalendarWindow()

# Position en haut à droite
screen = app.primaryScreen().geometry()
win.move(screen.width() - win.width() - 20, 70)

# Ou centré : win.move(screen.center().x() - win.width() // 2, 70)
# Ou en haut à gauche : win.move(20, 70)

win.show()
app.exec()

if os.path.exists(PID_FILE):
    os.remove(PID_FILE)
