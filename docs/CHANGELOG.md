# CHANGELOG

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
