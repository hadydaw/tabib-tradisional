# ASSET_PRODUCTION_GUIDE

Status: v0.1. Semua isi **[USULAN]** kecuali standar yang diturunkan dari keputusan FINAL (isometrik, 8 arah, pivot kaki, layer terpisah, visual konsisten). Gaya seni dan sumber aset **PENDING (P-04)**. Ukuran tile **PENDING (P-01)**.

Aset proyek ini dibuat baru. **Tidak ada aset dari Ladang Reinkarnasi atau proyek lain yang dipakai** [FINAL F-01].

## 1. Folder
| Lokasi | Isi |
|---|---|
| `assets/_source/` | File sumber (psd, aseprite, kra, blend), tidak masuk build |
| `assets/characters/` | Sprite karakter (tubuh, pakaian, rambut, aksesori) |
| `assets/tiles/` | Tileset per wilayah |
| `assets/props/` | Objek dunia (pohon, tanaman, perabot) |
| `assets/ui/` | Ikon, bingkai, tombol |
| `assets/audio/` | Musik dan efek |
| `assets/fx/` | Efek partikel dan sprite efek |
Aset siap impor disalin/ditautkan ke `game/` oleh skrip di `tools/` agar sumber dan hasil tidak tercampur.

## 2. Penamaan
`<kategori>_<nama>_<varian>_<arah/frame>.png`, semua huruf kecil, tanpa spasi.
Contoh: `char_body_base_walk_se_01.png`, `tile_grass_a.png`, `prop_tree_banyan_a.png`, `ui_btn_interact.png`.
Arah memakai `s, sw, w, nw, n, ne, e, se`.

## 3. Standar teknis
| Item | Standar |
|---|---|
| Format gambar | PNG (RGBA) |
| Tile | Sesuai ukuran terkunci (usulan 64×32) |
| Pivot | Karakter dan objek: tengah-bawah di titik kaki/dasar |
| Latar | Transparan |
| Ruang warna | sRGB |
| Atlas | Dikemas per kategori; dimensi pangkat dua bila diperlukan untuk kompresi |
| Skala | Satu skala piksel untuk seluruh game; tidak mencampur resolusi |
| Kompresi di build | Diputuskan setelah uji (P-03) |

## 4. Karakter (8 arah)
- Kerangka animasi seragam: `idle`, `walk` pada 8 arah. Aksi lain ditambah bertahap.
- Lapisan terpisah (tubuh, pakaian, rambut, aksesori) dengan urutan susun tetap dan titik jangkar sama.
- Opsi hemat: gambar 5 arah lalu cerminkan untuk 3 lainnya (hanya jika desain simetris). Diputuskan per desain.

## 5. Tileset dan lingkungan
- Tile diamond; satu tileset per wilayah dengan palet sendiri.
- Tepi dan transisi (rumput ke tanah, dll.) disiapkan sejak awal.
- Objek tinggi (pohon, bangunan) dipisah dari tile tanah agar bisa di-Y-sort.
- Uji tile tidak menunjukkan celah atau garis pada kamera bergerak.

## 6. UI
- Ikon dan tombol dirancang untuk landscape dan sentuhan (target ≥48 dp).
- Satu bahasa visual; kontras cukup dibaca di luar ruangan.
- Teks tidak ditanam di gambar (agar bisa dilokalisasi).

## 7. Audio (rencana)
Format usulan: OGG untuk musik dan efek panjang, WAV untuk efek pendek. Volume dinormalisasi. Detail ditambahkan saat fase audio.

## 8. Alur produksi
1. Brief aset (nama, ukuran, arah, kegunaan).
2. Buat di `_source`, ekspor ke PNG.
3. Validasi (ukuran, pivot, nama) dengan skrip `tools/`.
4. Impor ke Godot, uji di scene uji.
5. Uji di HP.
6. Catat di daftar aset (`docs/ASSET_REGISTER.md`, dibuat saat aset pertama masuk).

## 9. Lisensi dan sumber [PENDING P-04]
Setiap aset harus tercatat asal dan lisensinya. Aturan awal:
- Dilarang memakai aset yang tidak jelas lisensinya.
- Aset buatan AI atau berlisensi pihak ketiga hanya dipakai bila pemilik menyetujui dan lisensinya dicatat.
- Pemilik belum menetapkan sumber aset; sampai itu ditetapkan, gunakan **placeholder** buatan sendiri (bentuk sederhana) untuk prototipe.

## 10. Placeholder prototipe
Untuk Fase 1: diamond berwarna sebagai tile, kapsul/siluet sederhana sebagai karakter dengan penanda arah. Ini hanya untuk menguji ukuran, Y-sort, dan kontrol.

## Fase 3: Kontrak penggantian placeholder
- Prop: ganti per jenis di `PropCatalog` (35 jenis); titik sortir = kaki objek, tabrakan dari tabel BLOCKS.
- Bangunan: dinding per sel kolom/baris depan + satu atap; aset final harus dapat dipotong per sel 64x32 (sementara, T-14).
- Pakaian: ganti per id `OutfitCatalog` dan slot (TOP/BOTTOM/HEAD).
- Animasi: nama `idle_<arah>`/`walk_<arah>` x 8 arah.
