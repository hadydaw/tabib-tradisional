# Laporan Fase 1: Build CI dan APK Debug

Tanggal: 2026-11-09. Pelapor: Claude.

## Ringkasan jujur
- CI **berhasil** membangun APK debug dan menyimpannya sebagai artifact.
- APK **belum diuji di perangkat Android** oleh siapa pun. Semua klaim di bawah hanya soal build dan inspeksi berkas.

## Riwayat run
| Run | Hasil | Penyebab / catatan |
|---|---|---|
| #1 (commit 6dba71a) | Gagal di validasi | Kelas `VirtualJoystick` bentrok dengan kelas native Godot 4.7 ("hides a native class"). Ditangkap oleh cek sintaks per skrip. |
| #2 (commit ae0de2c) | Gagal di ekspor | Godot mewajibkan kompresi tekstur ETC2/ASTC untuk Android. Validasi sudah lolos penuh (36 tes unit). |
| #3 (commit 33df44e) | **Sukses** | APK dihasilkan dan ditandatangani. |

## Hasil run sukses (#3)
- Godot: 4.7.2.stable (official)
- Validasi: pemeriksaan statis 14/14, semua skrip lolos sintaks, 36 tes unit lolos.
- APK: `tabib-tradisional-debug.apk`, 28.366.679 byte (±27 MB), SHA-256 `feb15dc2cd4f56e39bb17d35ce456667d99241509b0d5520c2e52240a11dd06d`.
- Tanda tangan: terverifikasi skema v2 dan v3 (sertifikat debug sementara).
- Manifest: package `com.hadydaw.tabibtradisional.debug`, versionCode 1, targetSdk 36, native-code hanya `arm64-v8a`.
- Artifact: `tabib-tradisional-debug-apk` dan `build-logs`.

## Yang sudah ada di prototipe (hanya diverifikasi lewat kode dan tes logika)
Scene `res://scenes/proto/iso_test.tscn`: lantai diamond 16x16, tombol ganti tile 64x32 / 128x64, pemain placeholder 8 arah, joystick sentuh, 6 balok untuk uji Y-sort, kamera mengikuti, tombol interaksi, dan info perangkat (FPS, layar, DPI, renderer, model HP).

## Belum diverifikasi (butuh HP Android)
1. APK terpasang dan terbuka tanpa crash.
2. Orientasi landscape terkunci benar (nilai 4 = sensor landscape).
3. Joystick dan tombol bisa dipakai bersamaan (multi-touch).
4. Y-sort benar di semua sisi objek.
5. Keterbacaan tile 64x32 vs 128x64, dan ukuran sentuhan.
6. FPS dan panas pada perangkat nyata.
7. Perilaku area aman (notch) dan tombol kembali.
8. Setelah uji: keputusan ukuran tile (P-01) dan renderer (P-03).

## Peringatan
- Package name `...debug` bersifat sementara (P-07).
- Karena keystore debug dibuat baru tiap run, copot APK lama sebelum memasang yang baru.
