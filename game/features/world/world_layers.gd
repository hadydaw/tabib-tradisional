class_name WorldLayers
extends RefCounted
## Urutan lapisan dunia (z_index). Aturan: lantai paling bawah; semua objek bergerak dan
## berdiri (pemain, bangunan, pohon, perabot) berbagi SATU kelompok Y-sort pada z 0;
## overlay debug di atasnya; HUD di CanvasLayer terpisah (layer 10).

const Z_GROUND: int = -10
const Z_ACTORS: int = 0
const Z_OVERLAY: int = 5
const HUD_LAYER: int = 10
