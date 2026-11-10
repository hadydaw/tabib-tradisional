# Laporan Fase 6: Save System, Economy & Clinic Progression

Tanggal: 10 Nov 2026. Status: **kode selesai dan lolos CI; BELUM diuji di perangkat (nubia Neo 2 5G).** Semua koin, bahan, dan pengobatan fiktif.

## Ringkasan
| Target | Hasil |
|---|---|
| Simpan & Muat | `SaveSystem`: JSON berversi `user://save.json`, tulis atomik + cadangan `.bak`; berkas hilang/rusak/versi asing → cadangan → permainan baru (tanpa crash). Menyimpan hari+jam, bahasa, lokasi, koin, reputasi, buku kas, capaian, skill (XP), tanaman dikenal, inventaris, kebun, upgrade. |
| Ekonomi | Semua uang lewat buku kas (`ClinicStats`). Bayaran pasien (rumus Fase 5), Pasar Bahan beli/jual, biaya operasional harian, hadiah capaian/naik tingkat. Perubahan koin tampil sebagai toast "+N koin (alasan)", HUD, dan 3 transaksi terakhir di Buku Tabib. |
| Progres klinik | 6 upgrade × 2 tingkat dengan biaya + syarat reputasi/skill dan efek gameplay nyata. |
| Progres pemain | Skill Fase 5 terhubung: hadiah koin naik tingkat (25 × tingkat), 6 capaian, upgrade bersyarat skill. Tempo diuji otomatis. |

## Cara kerja
- **Alur simpan**: tulis `save.json.tmp` → validasi isinya → salin `save.json` lama ke `save.json.bak` → hapus lama → rename tmp. Bila crash di tengah, sisa `.tmp` diabaikan dan pemuatan jatuh ke `.bak`.
- **Simpan otomatis**: pergantian hari; menutup layar penuh (toko, upgrade, buku, kunjungan, kebun); aplikasi dijeda / kehilangan fokus / ditutup (Android: `NOTIFICATION_APPLICATION_PAUSED`). Manual: tombol **Simpan** di Buku Tabib.
- **Tidak disimpan** (disengaja): pasien yang sedang antre dan sesi minigame setengah jalan; keduanya dibuat ulang dari jadwal hari itu. Jam disimpan sampai menit, jadi memuat ulang tidak "memutar ulang" hari. Tampilan karakter (pakaian) belum ikut disimpan.
- **Biaya harian**: 20 + 5 per tingkat upgrade, dipotong saat ganti hari sebatas saldo (tidak pernah minus).

## Angka ekonomi (sementara, `EconomyDb`)
- Modal awal 100. Bahan 5–14 koin (jual 40% harga beli → beli-jual berulang selalu rugi).
- Pasien 3–5/hari; kunjungan nilai B ≈ 35–45 koin → ~110–150 koin bersih/hari.
- Upgrade 120–420 koin; termurah dalam ~1–2 hari, semua dalam ~2–3 minggu.
- Capaian 20–250 koin; naik tingkat skill 25 × tingkat.

| Upgrade | Efek | Biaya (T1/T2) | Syarat |
|---|---|---|---|
| Lentera Periksa | +1 energi periksa (Diagnosis) | 120 / 320 | Rep 20 / 30 + Diagnosis 2 |
| Set Jarum Perak | radius bidik +0,02 (~8%) | 180 / 420 | Akupunktur 2 / 3 (+Rep 35) |
| Lumpang Batu | toleransi takar +10% | 150 / 380 | Peracikan 2 / 3 (+Rep 35) |
| Rak Herbal Besar | stok harian minimal +1 | 140 / 300 | Rep 25 / 40 |
| Ruang Tunggu Nyaman | penalti menunggu −30% | 160 / 340 | Rep 25 / 40 |
| Pupuk & Pagar Kebun | panen identifikasi +1 | 130 / 300 | Identifikasi 2 / 3 (+Rep 30) |

Pemain nilai B mencapai skill tingkat 2 sekitar kunjungan ke-3, tingkat 3 sekitar ke-8, tingkat 5 sekitar ke-25 per cabang (nilai C jauh lebih lambat tetapi tetap ≤120).

## Pengujian (CI, GitHub Actions)
| Tes | Hasil |
|---|---|
| Unit dasar / Fase 3 / Fase 4 | 108 / 149 / 138 lolos (regresi) |
| Unit Fase 5 | 191 lolos (regresi; pemindai kunci UI diperluas ke Toko/Upgrade) |
| **Unit Fase 6** | **83 lolos**: ekonomi, buku kas, toko, aturan upgrade, efek upgrade pada diagnosis/akupunktur/peracikan/inventaris, simpan bolak-balik, 10 bentuk berkas salah, cadangan, `.tmp` sisa, sanitasi, tempo kemajuan, lokalisasi |
| Asap dasar / dunia / game / NPC / medis | 68 / 46 / 59 / 55 / 69 lolos (regresi) |
| **Asap ekonomi & simpan/muat** | **58 lolos**: dunia dibuang lalu dibuat ulang → koin, reputasi, XP, inventaris, upgrade, kebun, hari/jam, bahasa, lokasi sama; toko & upgrade lewat layar nyata; pembelian ditolak saat koin/syarat kurang; kunjungan pasien nyata → bayaran/XP/capaian; biaya harian; berkas utama rusak → cadangan; kedua rusak → permainan baru; berkas hilang → permainan baru |
| Kompatibilitas statis APK | 5/5 |

Tangkapan layar Pasar Bahan, Upgrade Klinik, dan Buku Tabib (dengan buku kas) diperiksa di CI; tata letak terbaca. Hanya rapikan koma sisa di daftar Buku.

## Yang BELUM diuji (perlu di HP)
- Rasa kontrol & keterbacaan layar Toko/Upgrade di layar nubia Neo 2 (ukuran tombol, jarak jempol).
- Simpan saat aplikasi di-background/di-swipe-close di Android dan membuka ulang (hanya diuji di headless).
- Keseimbangan ekonomi dan tempo kemajuan menurut rasa bermain; angka mudah diubah di `EconomyDb`/`ClinicUpgrades.DEFS`.
- Penyimpanan tidak menyimpan pasien antre/pakaian karakter (keputusan T-33).

## Berkas
Baru: `features/save/save_system.gd`, `features/economy/{economy_db,clinic_upgrades,clinic_shop}.gd`, `ui/minigame/{shop_view,upgrade_view,economy_text}.gd`, `tools/loc_fase6.py`, `tests/unit/run_tests_fase6.gd`, `tests/smoke/run_smoke_economy.gd`. Diubah (minimal): `clinic_stats`, `herb_inventory`, `garden_system`, `skill_progression_system` (serialisasi), `acupuncture_system` (`radius_bonus`), `herbal_crafting_system` (`tolerance_mult`), `treatment_manager` (titik pasang upgrade, capaian), `minigame_manager`, `info_view`, `game_world`.
