class_name UiGate
extends RefCounted
## Gerbang masukan global: bila `blocked` benar (layar minigame/panel penuh terbuka), kontrol HUD dunia
## (joystick, tombol interaksi, dialog) mengabaikan sentuhan.

static var blocked: bool = false
