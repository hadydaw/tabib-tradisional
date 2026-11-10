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
| F-19 | (9 Nov 2026) Perangkat uji utama: nubia Neo 2 5G (Z2352N), Android 13, Unisoc T820, RAM fisik 8 GB. RAM virtual 12 GB tidak dihitung sebagai RAM. |
| F-20 | (9 Nov 2026) Tidak ada fitur gameplay tambahan sebelum fondasi aplikasi berhasil diuji di perangkat utama. Ukuran tile tidak dikunci sebelum uji visual. |
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
| T-11 | Prototipe menampilkan telemetri (FPS, waktu frame, draw call, memori, info GPU) dan punya tombol uji beban serta batas FPS. | Mengukur di perangkat tanpa alat tambahan. |
| T-12 | CI memeriksa kompatibilitas statis APK terhadap profil perangkat uji (`tools/check_apk_compat.py`) dan menggagalkan build bila menyimpang. | Menjaga APK tetap cocok dengan target. Bukan pengganti uji perangkat. |
| T-13 | Prototipe punya 4 profil render dengan visual sama untuk memisahkan penyebab biaya (draw call vs node vs batching). Telemetri memakai pemanasan 60 frame dan p99. Ini alat ukur, bukan keputusan arsitektur render final. | Data uji awal tidak bisa membedakan penyebab. |
| T-14 | Tile 64x32 dipakai sebagai **standar kerja sementara** agar pekerjaan tidak terhambat. Ini bukan penguncian P-01; ukuran final tetap ditentukan pemilik. Kode memakai `tile` sebagai parameter. | Instruksi Fase 2. |
| T-15 | Tabrakan pemain berbasis sel grid (`GridCollision`), kotak sejajar sumbu grid, gerak per sumbu. Tidak memakai fisika Godot. | Sederhana, deterministik, bisa dites tanpa engine. |
| T-16 | Lantai dari `GroundMap` + mesh per jenis tile (bukan `TileMapLayer`) untuk saat ini. Dapat diganti `TileMapLayer` saat aset tile final ada; data `GroundMap` tetap sumber kebenaran tabrakan. | Menjaga draw call rendah tanpa aset; tidak mengubah sistem yang sudah diterima. |
| T-17 | Joystick melayang di separuh kiri layar; masukan dikunci ke 8 arah dengan faktor kecepatan 0,4-1,0. | Nyaman di HP; sesuai F-09. **Belum diuji di perangkat.** |
| T-10 | UI sentuh memakai kontrol buatan sendiri yang membaca `InputEventScreenTouch/Drag`, dengan `emulate_mouse_from_touch=false`. | Emulasi mouse hanya melayani satu jari; joystick dan tombol harus bisa dipakai bersamaan. **Belum diuji di perangkat.** |

| T-18 | Lokasi berbasis data (`LocationData` + `LocationBuilder`); desa dan klinik adalah dua lokasi, perpindahan lewat tile MAT dan nama spawn. | Menambah lokasi tanpa mengubah mesin dunia. |
| T-19 | Bangunan dipotong per sel dinding yang terlihat + satu atap; atap digeser +2 px di node dan -2 px di mesh (Node2D Godot 4 tidak punya `y_sort_origin`). | Y-sort benar untuk bangunan lebar. |
| T-20 | Satu `ArrayMesh` per prop/bangunan (1 draw call). Katalog `PropCatalog` memetakan jenis ke bentuk dan tabrakan. | Menjaga draw call rendah tanpa aset final. |
| T-21 | Tampilan karakter dari `CharacterAppearance` (Resource) + `OutfitItem` per slot; kontrak nama animasi `idle_<arah>`/`walk_<arah>`. Placeholder prosedural, bukan keputusan gaya. UI pembuat karakter tetap P-08. | Memudahkan penggantian ke sprite final. |
| T-22 | Interaksi klinik hanya struktur (`Interactable`, sinyal `interaction_requested`); sistem pengobatan belum ada. | Batas lingkup Fase 3. |

| T-23 | NPC disimulasikan semua sepanjang waktu (logika murni `NpcSimulation`), hanya NPC di lokasi aktif yang punya node. Jadwal = daftar `(jam, lokasi, spot, aktivitas)`; tujuan berupa spot bernama di data lokasi. | Murah (maks 8 NPC), lintas lokasi tanpa kasus khusus, dites tanpa engine. |
| T-24 | Navigasi NPC memakai A* pada sel yang sama dengan `GridCollision` (tanpa memotong sudut). Hunian sel dipesan sebelum melangkah; sel NPC menjadi sel terhalang sementara bagi pemain. | Tidak bertumpuk; konsisten dengan T-15. |
| T-25 | Anti-tersangkut berjenjang: tunggu -> rencana ulang -> batalkan tugas dan menepi -> jeda -> ulang; pengawas kemajuan 9 detik. | Instruksi Fase 4. Dites 3 hari permainan tanpa macet >30 detik. |
| T-26 | Localization: JSON per bahasa di `res://localization/`, dibuat dari `tools/gen_localization.py`; fungsi `Locale.t(key, args)` (bukan `tr`, bentrok dengan `Object.tr`); fallback ke Indonesia lalu ke kunci. | Dukungan English tanpa mengubah kode. |
| T-27 | Dialog = pohon node data (`DialogueLibrary`) + runner murni + panel tampilan terpisah. Permintaan NPC hanya dua syarat (bicara dengan NPC / masuk zona), tanpa hadiah. | "Informasi dan permintaan sederhana" tanpa sistem quest penuh. |
| T-28 | Pasien: alur MENUJU -> MENDAFTAR -> MENUNGGU -> DIPANGGIL -> DIPERIKSA -> SELESAI/BATAL. Pemanggilan/pemeriksaan bisa oleh pemain; bila tidak, `auto_call` otomatis (12 dan 25 menit permainan) sebagai pengganti sementara sampai diagnosis dibuat. | Antrean tetap berjalan tanpa campur tangan pemain. |
| T-29 | Jam permainan: 1 detik nyata = 1 menit (hari = 24 menit nyata), klinik buka 08:00-16:00. Angka sementara, belum keputusan desain final. | Cukup untuk menguji jadwal; mudah diubah (`GameClock.minutes_per_second`). |
| T-30 | Fase 5: minigame sebagai gameplay utama; nilai S-D, waktu maksimum 15% bobot; efek skill terbatas (<= sekitar 40% pelonggaran jendela). Angka (ambang nilai, bayaran, tenaga periksa, 2 tebakan) sementara, perlu disetel setelah uji di HP. | Arahan pemilik Fase 5; angka mudah diubah (`Grade`, `ScoringSystem`, `SkillDb`, `ClinicStats`). |
| T-31 | Pengobatan dan semua data medis murni fiktif (penyakit, titik, ramuan). | Sesuai arahan; bukan panduan medis nyata. |
| T-32 | Waktu dunia berhenti selama minigame; pasien tidak menunggu sambil dimainkan. | Adil bagi pemain; mudah diubah di `game_world.step_world`. |
| T-33 | Fase 6: simpan lokal berversi, atomik (sementara -> cadangan -> ganti nama), jatuh ke cadangan lalu permainan baru bila rusak. Pasien antre dan sesi minigame setengah jalan tidak disimpan (dibuat ulang dari jadwal hari itu); jam disimpan tepat sampai menit. Penyimpanan mati saat tes headless. | Aman dari berkas rusak/aplikasi dimatikan; tidak ada cloud (P-13 tetap PENDING). Angka mudah diubah di `SaveSystem`. |
| T-34 | Fase 6: koin fiktif; semua transaksi lewat buku kas `ClinicStats` (`add_money`/`spend`). Modal awal 100, biaya operasional harian 20 + 5/tingkat upgrade (dipotong sebatas saldo, tidak pernah minus), jual = 40% harga beli. Bukan keputusan monetisasi (P-12 tetap PENDING). | Angka sementara di `EconomyDb`; perlu disetel setelah uji di HP. |
| T-35 | Fase 6: upgrade klinik harus berefek gameplay (bukan dekorasi) dan berbiaya + bersyarat (reputasi/skill). Efek kecil dan berlapis (mis. +0,02 radius bidik) agar keterampilan manual tetap menentukan. | Konsisten dengan T-30. Data di `ClinicUpgrades.DEFS`. |
| T-36 | Fase 7: bahan langka bukan item khusus baru, melainkan peluang kecil dari titik tertentu (15%). Tidak menambah tanaman baru agar kunci identifikasi (ciri unik) tidak berubah. | Menjaga keseimbangan minigame Fase 5; tanaman baru bisa ditambah nanti lewat `HerbDb`. |
| T-37 | Fase 7: stamina hanya untuk pengumpulan, identifikasi, dan celah; berjalan tidak memakai stamina dan tidak pernah menghentikan gerak. Pembatalan minigame mengembalikan stamina. | Sesuai syarat "tidak terlalu menghukum". |
| T-38 | Fase 8: hubungan NPC = kepercayaan 0..100 (awal 10). Naik lewat bicara harian (+2), bahan hadiah (+8 bila disukai, +3 lainnya), dan bab cerita (+4). Turun hanya lewat pilihan quest yang tidak jujur. | Bicara tidak bisa diulang-ulang untuk farming kepercayaan (sekali per hari). |
| T-39 | Fase 8: bab cerita terbuka berurutan (ambang kepercayaan 25 dan 60) dan dicatat didengar hanya bila pemain memilih "Ceritakan lebih banyak". "Nanti saja" tidak mencatat, sehingga bab muncul lagi. | Cerita terbuka bertahap dan tidak terasa diulang. Sapaan berubah menurut tingkat (0/1/2). |
| T-40 | Fase 8: quest cerita hanya empat, masing-masing dengan satu pemberi, satu langkah utama, dan dua pilihan. Hadiah = koin, reputasi desa, kepercayaan, atau bahan. Resep dan akses area baru belum dibuat. | Ruang lingkup Fase 8; resep dan akses ditunda agar tidak melebar. Dicatat sebagai batasan jujur di laporan. |
| T-41 | Fase 8: event desa = jadwal tetap berdasarkan hari dan jam permainan (pasar tiap 3 hari, malam bakti tiap 4 hari). Peserta otomatis bila pemain berada di desa, sekali per hari per event. | Tidak ada menu tambahan; event terlihat di HUD sebagai "event berikutnya". |
| T-42 | Fase 8: reputasi desa memakai `ClinicStats.reputation` yang sudah ada (Fase 6). Quest dan event hanya menggeser nilainya; tidak ada sistem reputasi kedua. | Menghindari dua sumber kebenaran untuk reputasi. |

## C. Keputusan PENDING (menunggu persetujuan pemilik)

| ID | Pertanyaan | Opsi / usulan Claude | Dampak jika terlambat |
|---|---|---|---|
| P-01 | Ukuran tile | Usulan pemilik: 64×32 (rasio 2:1). Harus diuji di HP sebelum dikunci. Alternatif: 128×64 untuk detail lebih. | Seluruh aset visual menunggu ini. |
| P-02 | Versi pasti Godot 4.x | **Sementara terjawab oleh T-06 (4.7.2 stable).** Perlu konfirmasi bila pemilik ingin versi lain. | Menghalangi build. |
| P-03 | Renderer | Usulan: Compatibility (OpenGL ES 3) untuk jangkauan perangkat luas. Alternatif: Mobile (Vulkan). Perlu benchmark. | Performa dan kompatibilitas HP. |
| P-04 | Gaya seni (pixel art, painted, vektor) dan sumber aset (buat sendiri, generasi AI, aset berlisensi) | Belum ada. Lihat ASSET_PRODUCTION_GUIDE.md. | Pipeline aset. |
| P-05 | Tinggi/lebar kanvas referensi | Usulan: 1280×720 dengan stretch `canvas_items`. | Layout UI. |
| P-06 | Versi Android minimum dan arsitektur CPU | Perangkat uji utama Android 13 (API 33), arm64. minSdk 24 saat ini hanya bawaan Godot, **belum diputuskan**. | Jangkauan perangkat. |
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
| P-18 | Mode stretch: `canvas_items` (tajam, render resolusi asli) atau `viewport` (render 1280x720, lebih hemat GPU, lebih buram) | Diputuskan setelah uji di T820. | Performa, panas, ketajaman. |
| P-19 | Batas FPS (auto/60/30) pada layar 120 Hz | Diputuskan setelah data panas dan baterai. | Baterai, panas. |
| P-17 | Rating usia dan sensitivitas budaya (penggunaan istilah tradisional, simbol, dan nama) | Belum ditentukan. | Konten dan rilis. |

## D. Aturan perubahan
- Keputusan FINAL hanya berubah atas instruksi pemilik; catat sebagai F-xx baru dengan tanggal.
- Keputusan PENDING pindah ke FINAL hanya setelah persetujuan eksplisit pemilik.
- Keputusan teknis (bagian B) dicatat dalam `docs/adr/` bila diubah.
