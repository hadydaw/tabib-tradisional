# FASE2_DUNIA_PEMAIN

Tanggal: 10 Nov 2026. Build: GitHub Actions run 42663761542, versionCode 14, commit 031c19a.
Status: **lolos tes otomatis di CI. Belum diuji di perangkat (nubia Neo 2 5G).** Rasa kontrol, kenyamanan joystick, dan urutan gambar Y-sort yang sebenarnya hanya bisa dinilai di HP.

Keputusan pemilik: investigasi performa dihentikan, kondisi performa saat ini diterima. Tidak ada benchmark atau perbandingan profil baru di fase ini.

## 1. Yang dibangun
| Target | Hasil |
|---|---|
| Dunia isometrik 2D | Peta uji 24x24 (`WorldLayout`, data teks) dengan rumput, tanah, batu, air; sekitar 90 objek placeholder (pohon, batu, dinding, peti) |
| Sistem tile dan ground | `TileKinds` (jenis, warna, dapat dilewati), `GroundMap` (data), `IsoMapMeshes` + `IsoGroundMapView` (tampilan: 1 mesh per jenis tile + 1 mesh garis) |
| Pemain sprite sementara | `PlayerPlaceholder`: boneka bergaya sederhana, 8 arah (wajah bergeser, tampak belakang berambut) |
| Gerak 8 arah | `Player` + `IsoMath.snap_input_8`/`input_to_grid_velocity`: masukan dikunci ke 8 arah, kecepatan sama di semua arah (3,5 kotak/detik) |
| Animasi idle dan walking | `PlayerAnimator` (idle bernapas, walk ayun kaki + naik-turun); nama animasi `idle_s`, `walk_ne`, dst. sudah sesuai konvensi aset final |
| Virtual joystick Android | `TouchJoystick` mode melayang: muncul di titik sentuh di separuh kiri layar, mengikuti jari bila ditarik melewati radius; multi-touch tetap |
| Collision dan batas | `GridCollision` berbasis sel: kotak pemain radius 0,25, luncur di dinding, langkah kecil anti-tembus, batas peta, air terblokir |
| Y-sort | Pemain dan semua objek satu kelompok `y_sort_enabled`; titik urut = kaki |
| Kamera ikut | `FollowCamera`: perataan eksponensial, dibatasi kotak peta, zoom 1,5 |
| Kontrol Android landscape | Area aman (`SafeArea`), joystick melayang kiri, tombol Debug kanan-atas |

Tombol **Debug** menampilkan sel terblokir (merah), kotak tabrakan pemain (hijau), sel pemain (kuning), FPS, draw call, posisi grid, nama animasi.

Prototipe Fase 1 (`scenes/proto/iso_test`) tidak diubah dan tetap dites; scene utama sekarang `scenes/world/test_world.tscn`.

## 2. Hasil pengujian (CI, headless)
| Tes | Hasil |
|---|---|
| Unit | 108 tes, 0 gagal (gerak, tabrakan, peta, animator, klamp kamera, statistik, mesh) |
| Asap prototipe Fase 1 | 68 pemeriksaan, 0 gagal |
| Asap dunia Fase 2 | 46 pemeriksaan, 0 gagal |
| Kompatibilitas statis APK | 5/5 |
| Build APK debug | Berhasil (28,2 MB), tanda tangan sama dengan build sebelumnya, bisa di-update |

Tes asap dunia memeriksa: arah gerak layar tepat untuk tiap dari 8 arah; jarak tempuh 8 arah beda <1% (diagonal konsisten); tertahan objek, batas peta, dan air; kamera menyusul pemain dan tetap di batas; pemain dan objek dalam satu kelompok Y-sort dengan titik urut di kaki; joystick sintetis (sentuh, geser, jari kedua, tarik melewati radius, lepas); transisi idle dan walk.

**Keterbatasan tes ini:** renderer headless tidak menggambar, jadi urutan gambar Y-sort yang terlihat, ketajaman, FPS, dan rasa sentuh tidak terukur. Yang diuji hanya struktur Y-sort yang benar.

## 3. Bug yang ditemukan tes dan diperbaiki
- Tabrakan menganggap kotak yang hanya menyentuh tepi sel sebagai menabrak (tepi atas tertutup). Diubah ke tepi setengah-terbuka agar pemain bisa merapat ke dinding dan meluncur.
- Dua ekspektasi tes saya salah (geometri uji luncur dinding; kamera saat peta lebih kecil dari layar). Tes dikoreksi, bukan perilaku.

## 4. Performa
Tidak diukur ulang (sesuai instruksi). Perkiraan dari desain, **bukan hasil ukur**: lantai ~5 draw call (sebelumnya 512), tiap objek 1 draw call, pemain ~10, sehingga total jauh di bawah 562 call adegan Fase 1 yang sudah diterima.

## 5. Yang perlu dicek pemilik di HP
1. Joystick: apakah muncul di titik sentuh dan mengikuti jari dengan nyaman; zona sentuh (separuh kiri, 70% bawah) cukup; kecepatan jalan pas.
2. Berjalan melewati pohon dan dinding gubuk (kiri-bawah): apakah pemain tampil di depan/belakang objek dengan benar.
3. Merapat ke batu/dinding/air: apakah meluncur mulus tanpa tersangkut.
4. Kamera: halus, tidak bergetar, berhenti di tepi peta.
5. Ketuk Debug untuk melihat kotak tabrakan bila ada yang terasa janggal.

## 6. Catatan teknis
- Sel penuh menghalangi (kotak 1x1), walau bentuk visual objek lebih kecil. Sederhana dan jelas; bentuk tabrakan khusus bisa menyusul bila perlu.
- Y-sort memakai titik tengah sel objek. Objek tinggi dan lebar (dinding) dapat tampak salah urut pada sudut tertentu; pemecahan standar (objek besar dipecah per sel) dipakai bila terlihat.
- Gerak dikunci 8 arah; arah analog bebas tidak dipakai (F-09 menetapkan 8 arah).
