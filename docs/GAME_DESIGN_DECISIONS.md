# GAME_DESIGN_DECISIONS: Register Keputusan

Dokumen ini memisahkan keputusan yang **sudah dikonfirmasi pemilik proyek** dari keputusan yang **masih menunggu persetujuan**. Apa pun yang tidak tercantum di bagian FINAL bukan keputusan final.

Sumber FINAL: instruksi proyek dari pemilik (Tahap 1, 9 Nov 2026).

## A. Keputusan FINAL (dikonfirmasi pemilik)

| ID | Keputusan |
|---|---|
| F-01 | Proyek benar-benar baru dan terpisah dari Ladang Reinkarnasi, game hacking, dan proyek lain. Tidak memakai ulang kode, aset, atau arsitektur proyek lama. |
| F-02 | Nama sementara: **Tabib Tradisional**. Nama bersifat sementara. |
| F-03 | Genre: Hybrid Simulator + Adventure + RPG. |
| F-04 | Tema dunia: Fantasi Nusantara. |
| F-05 | Engine: Godot Engine 4.x. Bahasa: GDScript. |
| F-06 | Platform: Android saja. Tidak ada target produksi PC atau Web. |
| F-07 | Orientasi: Landscape (horizontal). |
| F-08 | Kamera: 2D isometrik, orthographic, tampilan diagonal dari atas, tile diamond. |
| F-09 | Karakter dengan animasi 8 arah. Y-sorting berdasarkan posisi kaki. Lingkungan dalam layer terpisah. |
| F-10 | Bahasa utama Indonesia, bahasa kedua English. |
| F-11 | Pemain adalah tabib tradisional dan dapat membuat karakter sendiri. |
| F-12 | Aktivitas inti (10): terima dan obati pasien, diagnosis lewat pemeriksaan, jarum akupuntur sebagai mekanik pengobatan, kumpulkan herbal, tanam dan panen tanaman obat, racik obat tradisional, jelajah desa/hutan/pegunungan/wilayah lain, pelajari teknik baru, kembangkan klinik, bangun reputasi. |
| F-13 | Unsur pengobatan adalah **simulasi fiktif**, bukan panduan medis nyata. |
| F-14 | Sistem modular (19 modul, lihat GODOT_ARCHITECTURE.md). Data tanaman, resep, pasien, penyakit fiktif, item, dan skill memakai Godot Resource. Hindari ketergantungan antarmodul yang tidak perlu. |
| F-15 | Android landscape first: virtual joystick, tombol interaksi, HUD khusus horizontal, UI responsif, optimasi untuk HP Android. |
| F-16 | Alur kerja memakai GitHub, bertahap, mandiri, diuji per modul, semua perubahan didokumentasikan. |
| F-17 | (9 Nov 2026) Build dan validasi dilakukan di GitHub Actions: pasang Godot 4.x stabil di server GitHub, periksa `project.godot`, bangun APK debug Android, simpan sebagai Actions Artifact. Hasil build tidak boleh diklaim "teruji" sebelum benar-benar diuji di perangkat Android. |
| F-18 | (9 Nov 2026) Repository proyek ini: `hadydaw/tabib-tradisional` (publik). |

## B. Keputusan TEKNIS yang diambil Claude (rutin, bisa diubah lewat ADR)

Ini bukan keputusan desain pemilik. Diambil agar pekerjaan tidak berhenti, dengan alasan tertulis.

| ID | Keputusan | Alasan |
|---|---|---|
| T-01 | Struktur repo: `game/` (proyek Godot), `docs/`, `assets/` mentah, `tests/`, `tools/`. Proyek Godot berada di `game/`. | Memisahkan dokumen dan aset sumber dari paket build. |
| T-02 | Satu folder per fitur di `game/features/`, data di `game/data/`, resource script di `game/core/resources/`. | Mendukung modularitas (F-14). |
| T-03 | Komunikasi antarmodul lewat signal dan satu autoload `EventBus`. | Mengurangi ketergantungan langsung. |
| T-04 | Orientasi dikonfigurasi sensor-landscape (kedua arah landscape). | Nyaman di HP; tetap landscape sesuai F-07. Belum diuji di perangkat. |
| T-05 | Penamaan: file `snake_case`, kelas `PascalCase`, ID konten `snake_case` berawalan jenis. | Konsistensi. |
| T-06 | Godot **4.7.2 stable** dipakai di CI dan prototipe (rilis stabil terbaru yang ditemukan; diunduh dan dijalankan sukses di CI). Menjawab P-02 sementara. | Pemilik mendelegasikan: "versi 4.x yang stabil dan kompatibel". |
| T-07 | Renderer **Compatibility** dipakai untuk prototipe. P-03 tetap terbuka sampai ada benchmark di perangkat. | Jangkauan perangkat luas; belum ada data performa. |
| T-08 | Tes unit berada di `game/tests/` (bukan `tests/` di akar repo) dan dijalankan dengan runner sederhana tanpa plugin. | Skrip headless Godot butuh path `res://`. |
| T-09 | Nama kelas kustom wajib dicek terhadap kelas native Godot. Kasus nyata: `VirtualJoystick` bentrok dengan kelas native Godot 4.7, diganti `TouchJoystick`. | Ditangkap oleh validasi CI. |
| T-10 | UI sentuh memakai kontrol buatan sendiri yang membaca `InputEventScreenTouch/Drag`, dengan `emulate_mouse_from_touch=false`. | Emulasi mouse hanya melayani satu jari; joystick dan tombol harus bisa dipakai bersamaan. **Belum diuji di perangkat.** |

## C. Keputusan PENDING (menunggu persetujuan pemilik)

| ID | Pertanyaan | Opsi / usulan Claude | Dampak jika terlambat |
|---|---|---|---|
| P-01 | Ukuran tile | Usulan pemilik: 64×32 (rasio 2:1). Harus diuji di HP sebelum dikunci. Alternatif: 128×64 untuk detail lebih. | Seluruh aset visual menunggu ini. |
| P-02 | Versi pasti Godot 4.x | **Sementara terjawab oleh T-06 (4.7.2 stable).** Perlu konfirmasi bila pemilik ingin versi lain. | Menghalangi build. |
| P-03 | Renderer | Usulan: Compatibility (OpenGL ES 3) untuk jangkauan perangkat luas. Alternatif: Mobile (Vulkan). Perlu benchmark. | Performa dan kompatibilitas HP. |
| P-04 | Gaya seni (pixel art, painted, vektor) dan sumber aset (buat sendiri, generasi AI, aset berlisensi) | Belum ada. Lihat ASSET_PRODUCTION_GUIDE.md. | Pipeline aset. |
| P-05 | Tinggi/lebar kanvas referensi | Usulan: 1280×720 dengan stretch `canvas_items`. | Layout UI. |
| P-06 | Versi Android minimum dan arsitektur CPU | Usulan: Android 8.0 (API 26) ke atas, arm64. Perlu persetujuan. | Jangkauan perangkat. |
| P-07 | Package name | Untuk APK debug dipakai ID sementara `com.hadydaw.tabibtradisional.debug`. **Bukan keputusan final**; ID rilis ditentukan pemilik dan tidak bisa diubah setelah rilis. | Tidak bisa diubah setelah rilis. |
| P-08 | Lingkup pembuat karakter (gender, wajah, pakaian, nama) | Belum ditentukan. | CHARACTER_DESIGN.md. |
| P-09 | Sistem waktu (jam nyata atau jam game, hari, musim) | Belum ditentukan. | Herbal, klinik, ekonomi. |
| P-10 | Detail mekanik akupuntur (minigame, urutan titik, atau puzzle) | Usulan awal ada di GAMEPLAY_SYSTEMS.md, belum disetujui. | Inti gameplay. |
| P-11 | Struktur cerita dan wilayah (jumlah wilayah, urutan, tokoh) | Belum ada. | Quest dan dunia. |
| P-12 | Model ekonomi dan monetisasi (berbayar, gratis, iklan, IAP, atau tanpa) | Belum ada. | Ekonomi dan legal. |
| P-13 | Penyimpanan online/cloud | Usulan: lokal saja untuk fase awal. | Save System. |
| P-14 | Kontrol: tap-to-move, joystick saja, atau keduanya | Joystick sudah diminta. Tap-to-move belum. | Input. |
| P-15 | Repository GitHub khusus proyek ini | **Selesai**: lihat F-18. | - |
| P-16 | Isi dunia fantasi: apakah ada makhluk dan unsur supernatural (jin, roh), seberapa besar | Belum ditentukan. | Penyakit fiktif, cerita. |
| P-17 | Rating usia dan sensitivitas budaya (penggunaan istilah tradisional, simbol, dan nama) | Belum ditentukan. | Konten dan rilis. |

## D. Aturan perubahan
- Keputusan FINAL hanya berubah atas instruksi pemilik; catat sebagai F-xx baru dengan tanggal.
- Keputusan PENDING pindah ke FINAL hanya setelah persetujuan eksplisit pemilik.
- Keputusan teknis (bagian B) dicatat dalam `docs/adr/` bila diubah.
