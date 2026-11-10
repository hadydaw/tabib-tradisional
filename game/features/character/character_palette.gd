class_name CharacterPalette
extends RefCounted
## Pilihan warna dan gaya rambut yang bisa disesuaikan pemain (placeholder).
## Lingkup pilihan karakter final (P-08) masih menunggu keputusan pemilik; ini hanya
## memastikan sistemnya siap menampung pilihan.

const SKIN_TONES: Array[Color] = [
	Color("#f1c9a5"), Color("#e0b48a"), Color("#c68e5f"), Color("#a8744a"), Color("#8a5a38"), Color("#5e3b24"),
]
const HAIR_COLORS: Array[Color] = [
	Color("#2a1d16"), Color("#4a2e1c"), Color("#7a5030"), Color("#b0883c"), Color("#7d7d80"), Color("#8a2a2a"),
]
const HAIR_STYLES: PackedStringArray = ["botak", "pendek", "panjang", "sanggul"]
