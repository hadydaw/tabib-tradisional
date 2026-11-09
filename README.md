# Tabib Tradisional

Game Hybrid Simulator + Adventure + RPG bertema Fantasi Nusantara. Kamu menjadi tabib tradisional: periksa pasien, diagnosis, gunakan jarum dan ramuan, kumpulkan dan tanam herbal, jelajahi dunia, dan bangun reputasi.

- Engine: Godot 4.x, GDScript
- Platform: Android saja, landscape
- Kamera: 2D isometrik
- Bahasa: Indonesia (utama), English (kedua)
- Semua mekanik pengobatan **fiktif**, bukan panduan medis.

Nama "Tabib Tradisional" bersifat sementara.

## Status
**Fase 1: prototipe teknis.** CI GitHub Actions memvalidasi proyek dan membangun APK debug (Godot 4.7.2). Isinya prototipe isometrik, bukan gameplay. **APK belum diuji di perangkat Android.** Lihat `docs/reports/FASE1_BUILD.md`.

## APK debug
Actions → run terbaru → Artifacts → `tabib-tradisional-debug-apk`. Copot versi lama sebelum memasang yang baru (tanda tangan debug berbeda tiap build).

## Proyek ini terpisah
Tidak ada hubungan dengan Ladang Reinkarnasi atau proyek lain. Tidak ada kode, aset, atau arsitektur yang dipakai ulang.

## Dokumen
| Dokumen | Isi |
|---|---|
| `docs/GDD_MASTER.md` | Dokumen desain utama |
| `docs/GAME_DESIGN_DECISIONS.md` | Keputusan FINAL vs PENDING |
| `docs/GODOT_ARCHITECTURE.md` | Arsitektur teknis dan struktur direktori |
| `docs/ISOMETRIC_VISUAL_STANDARD.md` | Standar visual isometrik |
| `docs/CHARACTER_DESIGN.md` | Karakter |
| `docs/GAMEPLAY_SYSTEMS.md` | Sistem gameplay |
| `docs/ANDROID_REQUIREMENTS.md` | Kebutuhan Android |
| `docs/ASSET_PRODUCTION_GUIDE.md` | Standar produksi aset |
| `docs/DEVELOPMENT_ROADMAP.md` | Roadmap |
| `docs/CHANGELOG.md` | Catatan perubahan |
| `docs/adr/` | Catatan keputusan teknis |
| `docs/reports/` | Laporan pemeriksaan dan uji |

## Struktur
`game/` proyek Godot (buka `game/project.godot`), `assets/` aset mentah, `tests/`, `tools/`, `export/`, `docs/`.

## Cara membuka
1. Pasang Godot 4.x (versi pasti belum diputuskan, P-02).
2. Impor `game/project.godot`.
3. Build Android otomatis lewat `.github/workflows/android-debug.yml`.
