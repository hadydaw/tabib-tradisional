# CHANGELOG

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
