# ADR 0002: Build dan validasi lewat GitHub Actions

- Tanggal: 2026-11-09
- Status: Diterima (disetujui pemilik, F-17)

## Konteks
Lingkungan kerja Claude tidak bisa mengunduh Godot. Pemilik tidak memakai PC untuk build. Dibutuhkan jalur otomatis: validasi proyek dan APK debug untuk diuji di HP.

## Keputusan
Workflow `.github/workflows/android-debug.yml` pada setiap push ke `main`, pull request, dan manual:
1. Pasang JDK 17 (Temurin), Godot (versi di `env.GODOT_VERSION`) dan export template resmi.
2. Siapkan Android SDK (build-tools 35.0.1, platform 35), keystore debug sementara, dan pengaturan editor.
3. `tools/ci/validate.sh`: pemeriksaan statis `project.godot` (Python), impor proyek, cek sintaks tiap `.gd`, tes unit.
4. `tools/ci/export_apk.sh`: ekspor preset "Android Debug", verifikasi tanda tangan, inspeksi manifest.
5. Unggah APK dan log sebagai Actions Artifact (retensi 14 hari).

## Konsekuensi
- APK debug memakai keystore debug **tetap** (`tools/ci/debug.keystore`, dikomit; kunci ini publik dan hanya untuk debug), dan `version/code` diisi dari `GITHUB_RUN_NUMBER`. Dengan begitu build baru bisa dipasang sebagai **update** di atas build lama tanpa mencopot. Keystore rilis yang berbeda harus disiapkan sebelum rilis (di GitHub Secrets).
- Build yang lolos berarti proyek terbentuk dan terpaket, **bukan** bahwa aplikasi berjalan benar di perangkat.
- Versi Godot dikunci di workflow; menaikkannya dilakukan dengan mengubah satu variabel dan melihat hasil CI.
