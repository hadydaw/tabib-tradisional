# ANDROID_REQUIREMENTS

Status: v0.1. **[FINAL]**: Android saja, landscape first, virtual joystick, tombol interaksi, HUD khusus landscape, UI responsif, optimasi performa HP Android, tanpa target produksi PC/Web.
Nilai teknis lain adalah **[USULAN]** dan bergantung pada P-02, P-03, P-06, P-07.

## 1. Platform
| Item | Nilai |
|---|---|
| Target | Android (satu-satunya target produksi) |
| Orientasi | Landscape. Usulan: sensor-landscape (dua arah landscape), potret dikunci |
| Android minimum | Usulan API 26 (Android 8.0), **PENDING (P-06)** |
| CPU | Usulan arm64-v8a; armeabi-v7a **PENDING** |
| Renderer | Usulan Compatibility, **PENDING (P-03)**, ditentukan lewat benchmark |
| Package name | **PENDING (P-07)** |
| Format rilis | Usulan: APK untuk uji, AAB untuk toko; **PENDING** |

## 2. Layar
- Kanvas referensi 1280×720, `canvas_items`, aspect `expand`.
- Dukung rasio 16:9 sampai 20:9 atau lebih lebar.
- Zona aman: UI penting tidak berada di area notch/cutout dan sudut layar.
- Teks cukup besar untuk dibaca di layar kecil; skala UI mengikuti DPI.

## 3. Kontrol [FINAL]
- **Virtual joystick** di sisi kiri bawah untuk gerak 8 arah.
- **Tombol interaksi** di sisi kanan bawah, ukuran sentuh minimal ~48 dp.
- Tombol menu/tas di sisi atas.
- Multi-touch: joystick dan tombol dipakai bersamaan.
- Posisi dan ukuran dapat diatur (pengaturan) [USULAN].
- Tap-to-move **PENDING (P-14)**.

## 4. HUD khusus landscape [FINAL, rincian USULAN]
Pembagian: kiri-atas status pemain, kanan-atas menu, kiri-bawah joystick, kanan-bawah interaksi/aksi, tengah-bawah petunjuk konteks. Panel besar (tas, diagnosis) memanfaatkan lebar layar dengan tata letak dua kolom.

## 5. Performa [FINAL: optimasi untuk HP Android]
Target awal (USULAN, diukur di Fase 1):
- 60 FPS di perangkat kelas menengah; minimal 30 FPS stabil di perangkat bawah.
- Atlas tekstur terkompresi dan ukuran terbatas.
- Hindari pembuatan objek per frame; gunakan pooling.
- Batasi node aktif dan pemrosesan di luar layar.
- Perhatikan baterai dan panas: batasi FPS saat menu/idle.
- Profiling di perangkat nyata, bukan hanya editor.

## 6. Siklus aplikasi
- Pause otomatis saat aplikasi ke latar belakang atau panggilan masuk.
- Simpan otomatis di titik aman dan saat dijeda.
- Tangani tombol/gestur kembali Android.

## 7. Penyimpanan
- Data di `user://` (penyimpanan privat aplikasi).
- Tidak ada izin (permission) Android yang tidak perlu. Daftar izin dicatat bila ada tambahan.
- Cloud **PENDING (P-13)**.

## 8. Build dan tanda tangan
- Ekspor lewat Godot dengan template ekspor Android (butuh JDK dan Android SDK).
- Keystore **tidak** disimpan di repo; disimpan di rahasia CI atau penyimpanan aman pemilik.
- Nomor versi dinaikkan setiap rilis.
- Kebutuhan: lihat Fase 0 pada DEVELOPMENT_ROADMAP.md.

## 9. Pengujian perangkat
Minimal: satu HP kelas bawah, satu menengah, satu dengan notch. Catat hasil di `docs/reports/`. Perangkat milik pemilik: **belum diketahui di dokumen ini**.

## 10. Lokalisasi, aksesibilitas, privasi
- Bahasa ID dan EN; bahasa perangkat menentukan awal, pengguna bisa mengganti.
- Opsi ukuran teks dan getar dapat dimatikan [USULAN].
- Kebijakan privasi diperlukan bila ada pengumpulan data atau iklan (terkait P-12).

## 11. Perangkat uji utama [FINAL, F-19]
nubia Neo 2 5G (Z2352N), Android 13 (API 33), Unisoc T820, Mali-G57 MP4, layar 6,72" 1080x2400 120 Hz, RAM fisik 8 GB (RAM virtual tidak dihitung). Detail, sumber, hasil pemeriksaan, dan protokol uji: `docs/reports/KOMPATIBILITAS_NUBIA_NEO_2.md`.
