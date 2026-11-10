# CHANGELOG

## 2026-11-10: Fase 9, wilayah baru, dungeon, dan penemuan langka
- **Wilayah baru**: Rawa (di timur Sungai) dengan kabut yang menutup rawa dalam sampai teka-teki Penjaga Rawa dipecahkan; Gua Kapur (di timur Pegunungan) yang terbuka setelah 2 jenis penemuan langka.
- **Teka-teki**: tiga teka-teki urutan simbol (Penjaga Rawa, Tablet Batu, Tuas Batu). Jawaban salah mengosongkan urutan. Jawaban benar memberi koin dan satu bahan langka, lalu membuka kabut, pintu tablet, atau celah tuas.
- **Dungeon (Gua Kapur)**: pintu tablet membuka ruang dalam dengan titik langka; tuas membuka celah ke ceruk tempat Peti Gua (koin dan dua benih).
- **Penemuan langka**: enam jenis bahan (akar rawa, benih kemuning, benih cendana, jamur gua, batu kompas, kristal tetes) dari enam titik (4 di rawa, 2 di gua). Titik beristirahat 300 menit permainan. Bahan langka tidak punya efek pengobatan; tercatat di Buku Tabib beserta penemuan pertama (+15 koin).
- **Quest eksplorasi**: Lastri (kumpulkan 3 penemuan langka) dan Joko (selesaikan Gua Kapur). Keduanya memakai alur quest Fase 8.
- **Simpan/muat**: kunci `frontier` (penemuan, titik, teka-teki, peti) dengan sanitasi; simpanan Fase 2-8 tetap terbaca.
- **Tes**: unit Fase 9 (keterjangkauan wilayah dengan dan tanpa segel), tes asap eksplorasi Fase 9, dan tes Fase 8 diperbarui untuk dua jenis quest baru.
- Belum diuji di perangkat. Integrasi penemuan langka ke identifikasi dan resep belum dibuat (lihat laporan).

## 2026-11-10: Fase 8, hubungan NPC, cerita, quest, dan event desa
- **Hubungan NPC**: kepercayaan 0..100 per penduduk. Bicara harian (+2), bahan hadiah (+8 bila disukai, +3 lainnya, sekali per hari), dan bab cerita (+4). Sapaan berubah menurut tingkat (0/1/2).
- **Bab cerita**: dua bab per penduduk (ambang 25 dan 60) dengan teks utama dan lanjutan. Terbuka berurutan; tercatat hanya bila didengar sampai habis.
- **Quest cerita**: empat quest (Ramuan untuk Mbah Wiryo, Cerita dari Sungai, Pasien Pilihan, Tanaman Liar di Kebun Karto) dengan syarat kepercayaan dan reputasi, langkah dari klinik/eksplorasi/identifikasi, dan dua pilihan berkonsekuensi (koin, reputasi, kepercayaan, bahan).
- **Reputasi desa** memakai nilai klinik yang sudah ada; quest dan event menggesernya.
- **Event desa**: Pasar Desa (tiap 3 hari, 08:00–10:00) dan Malam Bakti (tiap 4 hari, 18:00–19:00), dihitung sekali per hari bila pemain berada di desa. HUD menampilkan event berikutnya.
- **Simpan/muat**: kunci `social` menyimpan hubungan, bab, quest, klaim event, dan permintaan Fase 4 (yang sebelumnya tidak tersimpan). Simpanan Fase 6–7 tetap dapat dimuat.
- **Buku Tabib**: tingkat hubungan dan jumlah tugas.
- **Dialog**: aksi baru lewat sinyal `DialogueRunner.action_requested`; logika permintaan Fase 4 tidak berubah.
- Localization 643 kunci (ID + EN). Tes: unit Fase 8, tes asap sosial (dialog, bahan, bab, quest, event, simpan lintas dunia), regresi Fase 2–7 utuh, tangkapan layar dialog kepercayaan dan tugas.
- Batasan: resep dan akses area baru belum jadi hadiah; quest hanya empat. Belum diuji di perangkat.

## 2026-11-10: Fase 7, petualangan dan eksplorasi
- **Area baru**: Hutan, Sungai, dan Pegunungan, masing-masing dengan tanaman liar berbeda dan transisi jelas (desa <-> hutan/sungai, hutan <-> pegunungan). Desa kini punya gerbang barat dan timur.
- **Pengumpulan herbal**: titik liar dapat diambil langsung, masuk inventaris, dan pulih setelah 240 menit. Peluang bahan langka kecil (15%) per titik.
- **Identifikasi tanaman baru** memakai minigame Fase 5 yang sama, lalu tanaman tercatat di Buku Tabib beserta habitat dan kegunaan fiktif.
- **Stamina** non-hukuman: pengumpulan -8, identifikasi -12, celah rahasia -10, berjalan tidak memakai stamina, dan dipulihkan 0,1 per menit. Batal membatalkan biaya.
- **Papan Pengembara**: 4 misi berurutan (hutan, kenali tanaman, jelajah, celah) dengan hadiah koin.
- **Celah rahasia** di pegunungan: terbuka dengan Identifikasi tingkat 2 atau 3 tanaman dikenal, sekali, memberi bahan dan koin.
- **Hadiah jelajah**: kunjungan pertama ke tiap area memberi 15 koin.
- Simpan/muat menyimpan progres petualangan (`adventure`), kompatibel dengan simpanan Fase 6.
- Localization 527 kunci (ID + EN). Tes: unit Fase 7 (65), tes asap petualangan (48), regresi Fase 2-6 utuh, 3 tangkapan layar baru (hutan, pegunungan, papan).
- Perbaikan tes asap pada CI pertama: ekspektasi jenis layar papan dan syarat celah rahasia di tes diperbaiki (kode game tidak berubah).
- Dokumen: `docs/GODOT_ARCHITECTURE.md`, `docs/GAMEPLAY_SYSTEMS.md`, `docs/GAME_DESIGN_DECISIONS.md` (T-36, T-37). Belum diuji di perangkat.

## 2026-11-10: Fase 6, simpan, ekonomi, dan progres klinik
- **Simpan/Muat** (`SaveSystem`): JSON berversi di `user://save.json`, ditulis atomik (berkas sementara -> cadangan `.bak` -> ganti nama). Berkas utama hilang/rusak/versi tak dikenal -> otomatis dari cadangan, lalu permainan baru; tidak pernah crash. Isi: hari & jam, bahasa, lokasi, koin, reputasi, buku kas, capaian, skill, tanaman dikenal, inventaris, kebun, upgrade. Simpan otomatis: pergantian hari, menutup layar penuh (toko/upgrade/buku/kunjungan/kebun), aplikasi dijeda/kehilangan fokus/ditutup, dan tombol Simpan di Buku Tabib.
- **Ekonomi**: `ClinicStats` kini punya buku kas (`add_money`/`spend`/`charge_up_to`, 40 catatan terakhir), sinyal `money_changed`, toast "+N koin (alasan)" di HUD. `EconomyDb` memuat modal awal 100, harga beli/jual 10 bahan (jual 40% dari beli, tanpa arbitrase), biaya operasional harian (20 + 5/tingkat upgrade, tak pernah membuat saldo minus), hadiah capaian & naik tingkat skill.
- **Pasar Bahan** (`ShopView`, dari Rak Herbal) dan **Upgrade Klinik** (`UpgradeView`, dari Meja Pengobatan): 6 fasilitas x 2 tingkat, tiap tingkat punya biaya + syarat reputasi/skill dan efek nyata: Lentera (+1 energi diagnosis), Jarum Perak (radius bidik +0,02), Lumpang Batu (toleransi takar +10%), Rak Herbal Besar (stok harian min +1), Ruang Tunggu (penalti menunggu -30%), Kebun (panen +1).
- Buku Tabib: daftar fasilitas, 3 transaksi terakhir, tombol Simpan. Ringkasan kunjungan menampilkan capaian baru.
- Localization 466 kunci (ID + EN). Tes: unit Fase 6 (83), tes asap ekonomi & simpan/muat tutup-buka ulang (58), regresi Fase 2-5 utuh.
- Laporan: `docs/reports/FASE6_SAVE_EKONOMI_KLINIK.md`. Belum diuji di perangkat.

## 2026-11-10: Fase 5, gameplay medis dan sistem minigame
- Alur pengobatan penuh terintegrasi dengan antrean Fase 4: pasien dipanggil -> ruang periksa -> **diagnosis (minigame)** -> pilih metode -> **akupunktur (minigame)** dan/atau **peracikan ramuan (minigame)** -> hasil dari performa -> ringkasan -> pasien pulang. Tahap disimpan per pasien (`TreatmentSession`), "Tunda" lalu lanjut ke tahap yang sama.
- Empat minigame sentuh: diagnosis (6 area periksa, uji nadi berirama, catatan temuan, tabel kandidat), akupunktur (tubuh, pilih titik, bidik dengan geser, tekan kedalaman), peracikan (ambil bahan, takar tahan-tuang, tumbuk berirama, aduk melingkar), identifikasi tanaman (amati daun/bunga/akar/buah, pilih identitas).
- Penilaian S/A/B/C/D (`ScoringSystem`): ketepatan, urutan, kesalahan, kesesuaian, waktu (bobot maksimum 15%, tidak pernah penentu tunggal). Hasil memengaruhi kualitas pengobatan, kepuasan, reputasi, bayaran, XP.
- Lima cabang skill (`SkillProgressionSystem`, tingkat 1-5), efek terbatas (+-30-40% jendela) agar keterampilan manual tetap menentukan.
- Data dapat diperluas tanpa mengubah kode inti: 12 penyakit fiktif, 10 titik, 10 tanaman, 7 resep (`game/data/*`).
- Inventaris bahan (`HerbInventory`), statistik klinik (`ClinicStats`), kebun herbal/titik liar (`GardenSystem`), Buku Tabib (skill, bahan, tanaman, koin/reputasi), koin/reputasi di HUD.
- `MinigameManager` (layar penuh dengan pudar halus, `UiGate` mengunci kontrol dunia, waktu dunia berhenti selama minigame). Mode `set_medical_enabled(false)` mempertahankan perilaku Fase 4 untuk tes regresi.
- Localization 409 kunci (ID + EN). Tes: unit Fase 5, tes asap alur medis, tangkapan layar tiap minigame di CI.
- Laporan: `docs/reports/FASE5_MEDIS_MINIGAME.md`. Belum diuji di perangkat.

## 2026-11-10: Fase 4, NPC dan sistem pasien
- 8 NPC penduduk dengan identitas, jadwal harian, aktivitas, dan navigasi A* (`GridPathfinder`, `NpcSimulation`); tabrakan dinamis dengan pemain; anti-tersangkut (tunggu, rencana ulang, batalkan sementara dan menepi).
- Dialog berlokalisasi Indonesia/English (`Locale`, `DialogueLibrary/Runner/Panel`), permintaan sederhana (`RequestLog`).
- Pasien dan antrean klinik (`PatientSystem`, `ClinicQueue`): mendaftar, duduk di area penerimaan, dipanggil ke ruang periksa, pulang. Struktur data diagnosis/perawatan disiapkan (kosong).
- `GameClock` (1 detik = 1 menit permainan), HUD jam/antrean/permintaan, tombol debug waktu/bahasa/pasien baru.
- Perbaikan: `TouchActionButton` mengabaikan sentuhan saat tidak terlihat.
- Laporan: `docs/reports/FASE4_NPC_PASIEN.md`. Belum diuji di perangkat.

## 2026-11-10: Fase 3, karakter dan dunia
- Sistem karakter kustom (`CharacterAppearance`, `OutfitCatalog`, `CharacterPalette`, `CharacterView`) dengan idle/walk 8 arah dan pergantian pakaian.
- Desa 48x40 dan klinik 16x12 data-driven; transisi lewat keset pintu; `Interactable` + `InteractionSystem`.
- Tile baru: WOOD, WOOD_DARK, MAT, PLOT. Katalog 35 prop. Scene utama: `game_world.tscn`.
- Tes: unit Fase 3 142, asap game 59; CI lolos (run 42760732439, versionCode 17).
- Belum diuji di perangkat. Laporan: `docs/reports/FASE3_KARAKTER_DUNIA.md`.

## 2026-11-10: Fase 2, dunia isometrik dan kontrol pemain
- Investigasi performa dihentikan atas keputusan pemilik; kondisi performa saat ini diterima.
- Dunia uji 24x24: `TileKinds`, `GroundMap`, `IsoMapMeshes`, `IsoGroundMapView`, `WorldLayout`, `WorldObjectKinds`.
- Pemain: `Player`, `PlayerAnimator` (idle/walk x 8 arah), `PlayerPlaceholder` dengan animasi.
- Gerak 8 arah seragam (`IsoMath.snap_input_8`, `input_to_grid_velocity`, `speed_factor`), `GridCollision`.
- `FollowCamera` (ikut, perataan, batas peta), `SafeArea`, `DebugOverlay`, joystick melayang.
- Scene utama diganti ke `scenes/world/test_world.tscn`; prototipe Fase 1 tetap ada.
- Tes: unit 108, asap prototipe 68, asap dunia 46; CI lolos (run 42663761542, versionCode 14).
- Belum diuji di perangkat. Laporan: `docs/reports/FASE2_DUNIA_PEMAIN.md`.

## 2026-11-09: Fase 1, analisis performa T820 dan alat eksperimen
- Laporan `docs/reports/ANALISIS_PERFORMA_T820.md` dari hasil uji HP pemilik; koreksi klaim keliru "lantai dicatat sekali" di laporan kompatibilitas.
- Prototipe: 4 profil render (poligon, lantai mesh, lantai+balok mesh, atlas sprite) dengan bentuk visual sama; tombol Profil.
- Telemetri: p99, persen frame lambat, waktu skrip, waktu gambar CPU, jumlah node, biaya HUD, pemanasan 60 frame, panel 1 dtk.
- Kelas baru: `IsoMeshes`, `IsoGroundMesh`, `IsoMeshProp`, `IsoSpriteAtlas`, `PerfStats`.
- Tes: unit 36 -> 51; tes asap headless 68 pemeriksaan (semua profil x tile x beban). CI run build #10 lolos.
- **Masalah performa belum terbukti selesai**; menunggu uji ulang di nubia Neo 2 5G. Ukuran tile tetap tidak dikunci.

## 2026-11-09: Fase 1, penyesuaian perangkat uji (nubia Neo 2 5G)
- Prototipe: telemetri performa dan info perangkat, tombol Beban +300 dan FPS maks.
- `tools/check_apk_compat.py` + langkah CI: kompatibilitas statis APK terhadap Android 13 / arm64 / landscape.
- Laporan `docs/reports/KOMPATIBILITAS_NUBIA_NEO_2.md` dengan protokol uji di HP.
- Keputusan F-19, F-20, T-11, T-12; pending P-18, P-19.
- Belum diuji di perangkat.

## 2026-11-09: Fase 1, prototipe dan CI
- Workflow GitHub Actions: pasang Godot 4.7.2, validasi, ekspor APK debug, unggah artifact.
- Prototipe isometrik (`game/scenes/proto/`): lantai diamond, pemain 8 arah, joystick sentuh, Y-sort, kamera, tombol interaksi, info perangkat.
- `IsoMath` (logika murni) dengan 36 tes unit; runner di `game/tests/unit/run_tests.gd`.
- `tools/check_project.py` untuk pemeriksaan statis `project.godot`.
- Perbaikan: `VirtualJoystick` diganti `TouchJoystick` (bentrok kelas native); aktifkan ETC2/ASTC.
- Dokumen: ADR 0002, laporan `docs/reports/FASE1_BUILD.md`, keputusan F-17, F-18, T-06 s.d. T-10.
- APK belum diuji di perangkat.

## 2026-11-09: Tahap 1, Project Foundation
- Repo git lokal baru dibuat (terpisah dari proyek lain).
- Ditambahkan 9 dokumen fondasi, register keputusan (FINAL/PENDING), ADR 0001, dan laporan pemeriksaan.
- Dibuat kerangka direktori (`game/`, `assets/`, `tests/`, `tools/`, `export/`).
- Ditambahkan `game/project.godot` dasar (belum divalidasi di Godot).
- Belum ada kode gameplay.
