# ISOMETRIC_VISUAL_STANDARD

Status: v0.1. **[FINAL]**: 2D isometrik, kamera orthographic, tampilan diagonal dari atas, tile diamond, karakter 8 arah, Y-sort berdasarkan kaki, lingkungan dalam layer terpisah, visual konsisten, target Android landscape.
**[PENDING]**: ukuran tile 64×32 (usulan pemilik, harus diuji sebelum dikunci, P-01) dan gaya seni (P-04).

## 1. Proyeksi
- "Isometrik" di sini berarti proyeksi 2:1 (dimetrik piksel) yang lazim di game 2D: tile diamond dengan lebar dua kali tinggi. Ini bukan isometrik matematis 30°. Dicatat agar tidak ambigu.
- Kamera orthographic: tidak ada perspektif. Di Godot 2D ini otomatis.

## 2. Ukuran tile (USULAN, belum dikunci)
| Item | Nilai usulan |
|---|---|
| Tile dasar (diamond) | 64 × 32 px |
| Rasio | 2:1 |
| Langkah grid → layar | `x_layar = (gx - gy) * 32`, `y_layar = (gx + gy) * 16` |
| Tinggi satu level elevasi | 16 px (usulan) |

Rumus langkah mengikuti ukuran tile dan akan ikut berubah jika ukuran dikunci berbeda.

### Rencana pengujian sebelum dikunci (Fase 1)
1. Bangun scene uji dengan 64×32 dan satu karakter placeholder.
2. Tampilkan di HP Android nyata (landscape).
3. Nilai: keterbacaan tile, ukuran sentuhan objek interaksi, kejelasan karakter, jumlah tile terlihat, performa.
4. Bandingkan dengan 128×64 pada tolok ukur yang sama.
5. Pemilik memutuskan, lalu dicatat sebagai F-xx dan ADR.

## 3. Resolusi dan layar (USULAN)
- Kanvas referensi: 1280×720 (16:9), `stretch mode = canvas_items`, aspect `expand`.
- Tangani layar lebih lebar (20:9) tanpa memotong UI penting; area permainan boleh lebih lebar.
- Render piksel: filter `nearest` bila gaya piksel (bergantung P-04).

## 4. Layer dunia [FINAL: layer terpisah]
Urutan dari bawah ke atas (usulan nama):
| Layer | Isi | Y-sort |
|---|---|---|
| `ground` | Tanah, rumput, jalan | Tidak |
| `ground_detail` | Bercak, jejak, bayangan permanen | Tidak |
| `water` | Air, sungai | Tidak |
| `obstacles` | Tembok, pohon, batu, bangunan | Ya |
| `entities` | Pemain, NPC, pasien, hewan | Ya |
| `overlay` | Atap yang memudar, kanopi | Ya |
| `fx` | Partikel, cuaca | Tidak |
| `ui_world` | Penanda interaksi di dunia | Tidak |

`obstacles` dan `entities` berada dalam satu kelompok Y-sort agar urutan gambar benar antara objek dan karakter.

## 5. Y-sort [FINAL: berdasarkan posisi kaki]
- Titik urut setiap objek berada di **posisi kaki** (pivot di dasar sprite), bukan di tengah gambar.
- Pivot karakter: tengah-bawah telapak kaki.
- Objek besar (bangunan, pohon) memiliki satu titik urut di dasar jejak lantainya. Objek yang lebih lebar dari satu tile memakai urutan berdasarkan tepi terdepan; kasus khusus dicatat per aset.
- Uji wajib: pemain berjalan di depan dan di belakang objek di keempat sisi tanpa glitch urutan.

## 6. Arah karakter [FINAL: 8 arah]
Urutan nama arah (tetap, dipakai nama animasi dan kode):
`s, sw, w, nw, n, ne, e, se`
(s = menghadap bawah-layar, n = menghadap atas-layar). Gerak 8 arah di layar dipetakan dari joystick; di ruang grid, arah layar horizontal/vertikal berarti gerak diagonal grid. Aturan pemetaan joystick → arah dibuat di modul Isometric Movement.

## 7. Animasi (USULAN)
Set minimum per karakter: `idle`, `walk` (8 arah). Aksi (`gather`, `treat`, dll.) ditambah per fase. Jumlah frame dan fps ditentukan saat gaya seni dikunci (P-04). Penamaan: `<aksi>_<arah>` (mis. `walk_se`).

## 8. Pencahayaan dan bayangan (USULAN)
Bayangan blob sederhana di bawah entitas (sprite terpisah) untuk menjaga performa. Pencahayaan dinamis tidak dipakai awal.

## 9. Warna dan konsistensi
- Satu palet utama per wilayah; palet dikunci setelah gaya seni disetujui.
- Sumber cahaya dianggap dari kiri-atas layar; semua aset mengikuti arah yang sama.
- Semua aset dibuat pada skala tile yang sama (bagian 2).

## 10. Batas performa visual (USULAN, diukur nanti)
Target awal: 60 FPS stabil di HP kelas menengah. Batasi jumlah node aktif, ukuran atlas, dan overdraw. Angka diukur di Fase 1.
