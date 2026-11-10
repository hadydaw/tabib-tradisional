# Laporan Fase 8: Hubungan NPC, cerita, quest, dan event desa

**Status:** lolos validasi CI (GitHub Actions run 42801294408, commit 1d495bb). **Belum diuji di perangkat.**

## Ringkasan
- Hubungan NPC: kepercayaan 0..100 per penduduk (8 orang), naik lewat bicara harian, bahan hadiah (kesukaan +8, lainnya +3), dan bab cerita.
- Sapaan berubah menurut tingkat kepercayaan (0/1/2) bila tidak ada sapaan pasien khusus.
- Bab cerita: dua bab per penduduk (ambang 25 dan 60), terbuka berurutan, dicatat hanya bila didengar sampai habis.
- Quest cerita: empat quest dengan syarat, langkah (pengumpulan, identifikasi, area, pengobatan), dan dua pilihan berkonsekuensi.
- Reputasi desa memakai nilai klinik yang sudah ada; quest dan event menggesernya.
- Event desa berbasis jam permainan: Pasar Desa (tiap 3 hari, 08:00–10:00, 20 koin) dan Malam Bakti (tiap 4 hari, 18:00–19:00, kepercayaan semua penduduk +3, reputasi +2).
- Simpan/muat: kunci `social` menyimpan hubungan, bab, hari bicara dan pemberian, status quest, klaim event, dan permintaan Fase 4 (sebelumnya tidak tersimpan). Simpanan Fase 6–7 tetap dapat dimuat.
- Buku Tabib menampilkan tingkat hubungan dan jumlah tugas.

## Hasil tes CI (run 42801294408)
| Tes | Hasil |
|---|---|
| Unit Fase 8 | 100 pemeriksaan, 0 gagal |
| Unit Fase 2–7 (108 / 251 / 138 / 191 / 83 / 65) | semua 0 gagal |
| Asap (68 / 46 / 59 / 55 / 69 / 58 / 48) | semua 0 gagal |
| Asap sosial Fase 8 | 54 pemeriksaan, 0 gagal |
| Validasi proyek & kompatibilitas | lolos |
| Build APK debug | berhasil, versionCode 39 |
| Artifact | `tabib-tradisional-debug-apk`, `build-logs` |

Riwayat perbaikan selama CI: tes roundtrip kepercayaan (ekspektasi tes keliru, diperbaiki); sapaan tingkat kepercayaan tidak tampil bila NPC punya catatan pasien (diperbaiki di dialog).

## Tangkapan layar CI
- `39_dialog_kepercayaan`: dialog Wiryo. Sapaan ini masih sapaan pasien ("pulang dulu") karena ada catatan pasien; pilihan "Aku ingin mendengar ceritamu" dan "Ada tugas untukku?" tampil.
- `40_dialog_tugas`: dialog Karto dengan sapaan tingkat 1 dan pilihan tugas. Tata letak bersih, tidak ada teks terpotong atau bertumpuk.

## Yang perlu dicek di HP
- Bicara harian dan kenaikan kepercayaan (satu kali per hari per penduduk).
- Pemberian bahan: pilihan muncul hanya bila ada bahan dan belum memberi hari ini.
- Bab cerita terbuka bertahap; "Nanti saja" membuat bab muncul lagi.
- Alur quest: tawaran, status, lapor, dan pilihan dengan hadiah.
- Pasar Desa dan Malam Bakti muncul di HUD dan diklaim saat berada di desa.
- Simpan dan muat ulang: hubungan dan quest tetap ada.

## Batasan jujur
- Resep dan akses area baru belum menjadi hadiah; quest hanya empat.
- Event tidak memerlukan tindakan khusus selain berada di desa.
- Sapaan pasien tetap didahulukan saat pasien dengan status khusus (mis. "selesai").
- Belum ada pengujian di perangkat.
