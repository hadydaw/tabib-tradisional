# ANALISIS_PERFORMA_T820

Tanggal: 9 Nov 2026. Perangkat: nubia Neo 2 5G (Z2352N), Android 13, Unisoc T820 (Mali-G57 MP4), layar 120 Hz, renderer Compatibility (OpenGL ES 3.2 terukur di aplikasi), Godot 4.7.2.

**Status: MASALAH BELUM TERBUKTI SELESAI.** Bagian "kesimpulan" adalah hipotesis dari 4 titik data. Perbaikan yang dibuat (bagian 6) baru lolos tes otomatis di CI (51 tes unit, 68 tes asap, kompatibilitas statis 5/5). Belum ada satu pun angka dari HP untuk profil baru.

Batasan yang dipatuhi: kualitas visual tidak diturunkan, ukuran tile **tidak dikunci** (P-01), tidak ada fitur gameplay baru.

## 1. Koreksi atas klaim saya sebelumnya
Laporan kompatibilitas menyebut lantai "dicatat sekali, tidak digambar ulang". Itu salah. Ukuran 562 draw call pada kondisi normal membuktikan lantai digambar ulang tiap frame sebagai 512 perintah gambar (256 tile x poligon + garis). Pernyataan itu sudah dikoreksi di `KOMPATIBILITAS_NUBIA_NEO_2.md`.

## 2. Data dari pemilik (4 tangkapan layar)
| Kondisi | FPS | Frame rata2 (ms) | P95 (ms) | Terburuk (ms) | Draw call | Mem. statis |
|---|---|---|---|---|---|---|
| 64x32 normal | 59 | 19,2 | 26,7 | 54,8 | 562 | 31,5 MB |
| 64x32 +300 | 30 | 35,4 | 41,7 | 146 | 1762 | - |
| 128x64 normal | 57 | 17,1 | 20,2 | 75,6 | 562 | 32,8 MB |
| 128x64 +300 | 32 | 33,3 | 35,9 | 94,3 | 1642 | - |

Catatan data: refresh layar tercatat 60 Hz pada sebagian tangkapan dan 120 Hz pada yang lain; kondisi diam/bergerak tidak seragam. Perbandingan antar-tile di bawah harus dibaca dengan batasan ini.

## 3. Turunan angka (dihitung, bukan diukur langsung)
- Beban +300 menambah **1200** draw call pada 64x32 (tepat 4 per balok) dan **1080** pada 128x64. Selisih 120 call = ~30 balok yang berada di luar layar dan dibuang otomatis (culling per objek sudah bekerja).
- Tambahan waktu frame akibat beban: 16,2 ms pada keduanya, yaitu ~13,5 µs per draw call (64x32) dan ~15,0 µs (128x64). Total waktu per draw call saat beban nyala ~20 µs.
- Model linear dua titik (lemah, hanya dari titik beban): frame ≈ 4,6 ms + 0,0175 ms x draw call. Ekstrapolasi ke 562 call = ~14,4 ms. **Ini ekstrapolasi, bukan pengukuran**; fungsinya hanya menandai bahwa adegan "normal" sudah dekat anggaran 16,7 ms.
- Anggaran kasar bila biaya per call sama: ~690 call menyentuh 16,7 ms; ~410 call menyisakan 30% cadangan.
- 562 call = 512 (lantai) + ~50 (balok, pemain, HUD).
- FPS 30 saat beban pada layar 60 Hz adalah kuantisasi vsync: frame yang melewati 16,7 ms menunggu refresh berikutnya, jadi turun ke 30 alih-alih 45.

## 4. Perbedaan performa 64x32 vs 128x64
- Draw call identik (562) pada kondisi normal. Jumlah perintah gambar tidak bergantung ukuran tile.
- Selisih rata-rata 19,2 vs 17,1 ms (p95 26,7 vs 20,2) **bukan bukti** satu ukuran lebih cepat: refresh layar dan aktivitas pemain berbeda antar-tangkapan, dan jumlah piksel yang digambar 4x lebih besar pada 128x64 tanpa waktu frame yang jelas lebih buruk.
- Beban +300: balok 128x64 menutup ~4x piksel namun waktu frame hampir sama (33,3 vs 35,4 ms). Ini melemahkan dugaan bahwa fill-rate/GPU yang membatasi.
- **Kesimpulan:** data tidak menunjukkan tile size sebagai faktor performa. Keputusan ukuran tile harus berdasar uji visual. Tetap tidak dikunci.

## 5. Penyebab penurunan FPS saat +300 objek
Hipotesis paling konsisten (keyakinan sedang, belum terbukti): **biaya CPU untuk menyusun dan mengirim perintah gambar** (jumlah draw call dan/atau jumlah item kanvas), bukan GPU.

| Kandidat | Bukti | Penilaian |
|---|---|---|
| Fill-rate GPU | Waktu hampir sama walau piksel 4x | Kecil kemungkinannya |
| Jumlah draw call (CPU submit) | Waktu bertambah hampir linear dengan call, ~14-15 µs per call | Paling konsisten |
| Pemrosesan objek / Y-sort | Balok tidak punya skrip `_process`; biaya Y-sort 300 node belum terpisah dari biaya gambar | Belum bisa dibedakan dari data |
| CPU skrip | Skrip per frame ringan | Tidak mungkin dominan |
| Lonjakan terburuk 94-146 ms | Muncul tepat setelah tombol ditekan (bangun dunia / spawn 300 node) | Kemungkinan artefak toggle, bukan kondisi stabil |
| Telemetri sendiri | Label HUD diperbarui tiap 0,25 dtk, bisa menaikkan p95 | Mungkin berkontribusi; perlu diukur |

Yang belum bisa dipisahkan dari data: biaya **per draw call** vs biaya **per node/item kanvas**. Karena itu eksperimen di bagian 6 dirancang agar tiap profil mengubah satu hal.

## 6. Perubahan yang dibuat (alat uji dan eksperimen, bukan klaim perbaikan)
Bentuk dan warna sama di semua profil (satu sumber geometri, `IsoMeshes`); hanya cara menggambar yang berbeda. Tombol "Profil" di HP bergantian di antara:

| Profil | Lantai | Balok | Draw call lantai | Draw call per balok | Mengisolasi |
|---|---|---|---|---|---|
| 0 Poligon (awal) | per tile | poligon | 512 | 4 | pembanding |
| 1 Lantai mesh | 2 mesh | poligon | 2 | 4 | biaya lantai |
| 2 Lantai+balok mesh | 2 mesh | 1 mesh | 2 | 1 | draw call per balok dengan jumlah node sama |
| 3 Lantai mesh+atlas | 2 mesh | Sprite2D satu atlas | 2 | batch (jumlah tergantung engine) | efek batching tekstur |

Interpretasi hasil nanti:
- 1 jauh lebih cepat dari 0 -> 512 call lantai adalah beban utama normal.
- 2 jauh lebih cepat dari 1 pada beban +300 -> biaya per draw call; jumlah node bukan masalah utama.
- 2 hampir sama dengan 1 -> biaya per node/Y-sort; perlu strategi pengelolaan objek.
- 3 vs 2 -> apakah batching sprite menambah keuntungan (relevan untuk aset final berbentuk sprite).

Telemetri baru: p99, persen frame lambat (>20 ms), waktu skrip, waktu gambar sisi CPU (`frame_pre_draw` ke `frame_post_draw`), TIME_PROCESS, jumlah node, biaya penyegaran HUD, pemanasan 60 frame setelah setiap perubahan, panel diperbarui 1 dtk. Atlas sprite diraster dengan kode (hanya eksperimen biaya, bukan aset seni).

Catatan: `frame_pre_draw/post_draw` mengukur sisi CPU; pada driver GL, kerja GPU yang tertunda bisa muncul di waktu frame, bukan di angka itu. Jadi "Gambar-CPU kecil tapi frame besar" berarti menunggu GPU/vsync.

## 7. Evaluasi teknik optimasi (rekomendasi, belum terbukti di HP)
| Teknik | Relevansi | Biaya visual | Rekomendasi |
|---|---|---|---|
| Menggabung geometri statis (mesh/TileMap) | Lantai: 512 -> 2 call | Nol (bentuk sama) | Lakukan; pada aset final pakai TileMapLayer, yang menggabung tile per chunk |
| Batching sprite dari satu atlas | Aset final berbentuk sprite; tekstur sama berturutan dapat digabung | Nol | Rancang aset dalam atlas bersama; ukur lewat profil 3 |
| Culling visibilitas | Sudah otomatis per objek (terbukti: 1080 vs 1200 call). Item besar tunggal tidak dipotong sebagian | Nol | Untuk peta besar, pecah lantai jadi chunk agar yang di luar layar dibuang. Tidak berpengaruh pada peta 16x16 uji ini karena seluruh peta terlihat di 64x32 |
| Mengelola jumlah objek (pooling, nonaktifkan di luar layar) | Berguna bila biaya per node terbukti | Nol | Tunda sampai profil 1 vs 2 membedakan penyebabnya |
| Menurunkan resolusi (stretch viewport) / FPS 30 | Mengurangi beban | **Menurunkan kualitas** | Tidak dilakukan (instruksi pemilik); P-18/P-19 tetap terbuka |

Uji +300 balok poligon menilai terlalu tinggi biaya adegan final, karena balok final berupa sprite yang bisa di-batch. Angka sebenarnya baru diketahui dari profil 3 dan aset nyata.

## 8. Protokol uji ulang (dilakukan pemilik)
1. Perbarui APK dari Artifact run terbaru (versionCode 10 atau lebih; tanpa uninstall).
2. Untuk **tiap profil (0-3)**, pada **tiap tile**, dengan beban mati lalu **nyala**: biarkan ~10 detik (60 frame pemanasan lewat), jangan geser joystick, lalu screenshot panel. Ulangi sekali dengan joystick digerakkan.
3. Catat refresh layar (60/120 Hz) yang tertera; usahakan sama antar-uji.
4. Kirim semua tangkapan layar. Yang saya baca: draw call, rata2/p95/p99, % lambat, Skrip, Gambar-CPU, Node.

Kriteria sukses yang saya usulkan (belum disetujui pemilik): p99 di bawah 16,7 ms pada 60 Hz dalam gameplay normal dengan +300 objek, tanpa menurunkan kualitas.

## 9. Status
| Item | Status |
|---|---|
| Analisis dari data HP | Selesai (hipotesis, bukan bukti) |
| Perangkat uji eksperimen | Ada, lolos CI |
| 60 FPS stabil di nubia Neo 2 5G | **Belum terbukti** |
| Uji ulang di HP | **Belum dilakukan** |
