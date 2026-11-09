# Laporan Kompatibilitas: nubia Neo 2 5G (perangkat uji utama)

Tanggal: 2026-11-09. Pelapor: Claude.
Build acuan: run #9, commit `aa6625d`, versionCode 9.
https://github.com/hadydaw/tabib-tradisional/actions/runs/42655451202

## Ringkasan jujur
- Pemeriksaan **statis** APK terhadap profil perangkat ini: **lolos 5 dari 5**.
- **Belum ada uji di perangkat.** Semua yang berlabel "terukur di HP" di bawah masih kosong sampai kamu menjalankannya.
- Tidak ada keputusan performa yang dikunci. Ukuran tile (P-01) tetap terbuka.

## 1. Profil perangkat
| Item | Nilai | Sumber / status |
|---|---|---|
| Merek, model | nubia Neo 2 5G, Z2352N | Dari pemilik |
| Android | 13 (API 33) | Pemilik; GSMArena memuat Android 13 |
| Chipset | Unisoc T820, 6 nm | Pemilik; GSMArena, Notebookcheck |
| CPU | 8 inti: 1x Cortex-A76 2,7 GHz, 3x A76 2,3 GHz, 4x A55 2,1 GHz | GSMArena, Notebookcheck |
| GPU | Mali-G57 MP4 (hingga 850 MHz menurut Notebookcheck) | Notebookcheck, GSMArena |
| Versi OpenGL ES / Vulkan | **Tidak tercantum di sumber** | Diukur di aplikasi (baris "GPU / API" pada info layar) |
| Layar | 6,72" IPS, 1080x2400 (20:9), 120 Hz | GSMArena |
| Cutout/notch | Tidak tercantum di sumber | Diukur di aplikasi (area aman) |
| RAM fisik | 8 GB | Pemilik; GSMArena (varian 8 GB + 256 GB UFS 3.1) |
| RAM virtual | 12 GB | **Tidak dihitung sebagai RAM.** Itu perluasan berbasis penyimpanan (lebih lambat). Anggaran memori game dihitung dari RAM fisik 8 GB dan sisa yang dipakai sistem dan aplikasi lain. |

## 2. Hasil pemeriksaan statis APK (CI)
| Pemeriksaan | Hasil | Keterangan |
|---|---|---|
| minSdk 24 <= API 33 | OK | minSdk bawaan Godot, bukan keputusan (P-06) |
| targetSdk 36 >= API 33 | OK | Android 13 menjalankan aplikasi dengan target lebih tinggi |
| ABI | OK | `arm64-v8a` saja, sesuai T820 (64-bit) |
| Orientasi manifest | OK | `userLandscape` (landscape, mengikuti kunci rotasi pengguna) |
| OpenGL ES | OK | Manifest meminta ES 3.0; sesuai renderer Compatibility |
| Izin (permission) | Tidak ada | Aplikasi tidak meminta izin apa pun, jadi tidak ada prompt izin Android 13 |
| Tanda tangan | OK | v2/v3, kunci debug tetap (update tanpa copot) |
| Validasi proyek | OK | 14/14 pemeriksaan statis, semua skrip lolos, 36 tes unit |

Pemeriksaan ini otomatis di setiap build (`tools/check_apk_compat.py`) dan akan menggagalkan build jika ABI atau orientasi menyimpang dari profil.

## 3. Penyesuaian konfigurasi untuk perangkat ini
| Konfigurasi | Nilai | Alasan |
|---|---|---|
| ABI | arm64-v8a saja | T820 adalah 64-bit; membuang ABI lain memperkecil APK |
| Renderer | Compatibility (OpenGL ES) | Sementara (T-07). Vulkan/Mobile baru dipertimbangkan jika ada data |
| Kompresi tekstur | ETC2 dan ASTC aktif | Godot menyertakan keduanya; perangkat memakai yang didukung |
| Orientasi | sensor landscape (`userLandscape`) | Dua arah landscape |
| Resolusi | Kanvas 1280x720, `canvas_items`, aspect `expand` | 20:9 menjadi sekitar 1600x720 virtual; area aman dihitung di kode |

**Yang sengaja tidak diubah:** minSdk (belum diputuskan), ukuran tile (belum diuji), batas FPS (belum diukur).

## 4. Catatan performa untuk Unisoc T820 (analisis, belum terukur)
- Kelas menengah: 4 inti besar A76 dan GPU Mali-G57 MP4. Layar 1080x2400 pada 120 Hz berarti banyak piksel per frame, jadi **fill-rate dan panas** lebih mungkin jadi hambatan daripada CPU untuk game 2D.
- `canvas_items` merender pada resolusi asli layar (2400x1080). Mode `viewport` merender pada 1280x720 lalu diperbesar: lebih hemat GPU tetapi lebih buram. **Pending P-18**, diputuskan setelah data.
- Dengan layar 120 Hz, tanpa batas FPS game bisa mencoba 120 FPS: halus tetapi lebih panas dan boros baterai. Tombol "FPS maks" (auto/60/30) disediakan untuk membandingkan. **Pending P-19.**
- Sudah hemat di desain: hanya 2D, tanpa bayangan/cahaya dinamis, gambar lantai dicatat sekali (tidak digambar ulang tiap frame), satu kelompok Y-sort.
- Tidak ada angka performa yang diklaim. Semua menunggu pengukuran di HP.

## 5. Alat ukur di APK (versi 9 ke atas)
Panel kiri atas menampilkan: FPS, waktu frame rata-rata/p95/terburuk, batas FPS, draw call, jumlah objek, resolusi layar dan virtual, refresh rate, DPI, area aman, RAM fisik yang dilaporkan OS, memori statis game, model HP, renderer, nama GPU, dan versi API grafis.
Tombol: ganti tile (64x32 / 128x64), **Beban +300** (300 objek tambahan, posisi acak tetap agar hasil bisa dibandingkan), **FPS maks** (auto/60/30).

## 6. Protokol uji di HP (kamu jalankan)
Ambil APK run #9 atau yang lebih baru dari Artifacts. Karena kunci debug tetap, ini update bila sebelumnya memakai build #7 ke atas; jika masih memakai build #1 sampai #6, copot sekali.

| No | Langkah | Yang dicatat |
|---|---|---|
| 1 | Pasang dan buka | Terbuka tanpa crash? Landscape? Ada bar hitam atau UI terpotong notch? |
| 2 | Diam 10 detik (tile 64x32, beban mati, FPS auto) | Screenshot panel info |
| 3 | Jalan memutar dengan joystick, sambil mengetuk Interaksi dengan jari lain | Bisa bersamaan? Joystick macet? |
| 4 | Lewati depan dan belakang balok di semua sisi | Urutan gambar benar? |
| 5 | Beban NYALA, jalan 20 detik | Screenshot panel (FPS, p95, terburuk) |
| 6 | Ganti ke tile 128x64, ulangi no. 2 dan 5 | Bandingkan keterbacaan dan FPS |
| 7 | FPS maks 60, lalu 30, ulangi no. 5 | Perbedaan FPS dan rasa |
| 8 | Main 5 menit dengan beban nyala | Hangat atau tidak, baterai turun berapa persen |
| 9 | Tekan home lalu buka lagi; gestur kembali | Lanjut normal atau reset/crash |
| 10 | Putar HP (jika rotasi aktif) | Tetap landscape, UI pindah benar |
| 11 | Ketuk tombol dengan ibu jari: terasa nyaman? | Tombol terlalu kecil/besar? |

Kirim screenshot panel info untuk langkah 2, 5, dan 6. Dari situ saya isi tabel hasil dan kita putuskan ukuran tile, batas FPS, dan mode resolusi.

## 7. Hasil uji perangkat
| Uji | Hasil |
|---|---|
| Semua langkah di bagian 6 | **Belum dijalankan** |

## 8. Risiko yang diketahui
- Kontrol sentuh buatan sendiri (T-10) belum pernah dicoba di layar nyata.
- Info "RAM fisik" dari OS belum tentu terisi di Android; jika tidak, tertulis "tidak dilaporkan".
- Versi OpenGL ES/Vulkan perangkat belum diketahui; Compatibility butuh ES 3.0 (umum di Mali-G57, tetapi belum dibuktikan di sini).
- Panel info memakai banyak teks; di layar 6,72" mungkin kecil. Akan disesuaikan dari hasil uji.
