# DEVELOPMENT_ROADMAP

Status: v0.1. Urutan dan isi fase adalah **[USULAN]**. Tidak ada tanggal; perkiraan waktu tidak diberikan karena belum ada data kecepatan kerja. Fase bergantung pada keputusan PENDING di `GAME_DESIGN_DECISIONS.md`.

Aturan tiap fase [FINAL dari aturan kerja]: bertahap dan mandiri, uji setiap modul, perbaiki error sebelum lanjut, dokumentasikan perubahan, pakai GitHub.

## Fase 0: Fondasi (Tahap 1) — sedang/selesai
- Dokumen fondasi, struktur repo, konfigurasi dasar.
- Hasil pemeriksaan lingkungan: lihat `docs/reports/TAHAP1_PEMERIKSAAN.md`.
- **Syarat sebelum Fase 1:**
  1. Repo GitHub khusus tersedia (P-15).
  2. Godot 4.x terpasang di lingkungan kerja atau CI (P-02). Di lingkungan sesi ini unduhan Godot diblokir.
  3. Keputusan P-02, P-03 minimal dasar.

## Fase 1: Prototipe teknis isometrik
**Status (9 Nov 2026): CI, APK debug, alat ukur performa, dan pemeriksaan kompatibilitas statis selesai; uji di HP BELUM dilakukan.** Tidak ada fitur gameplay sebelum uji perangkat selesai (F-20). Lihat `docs/reports/FASE1_BUILD.md`. Ukuran tile belum dikunci.

- Proyek Godot berjalan, scene uji.
- Tile diamond, uji **64×32 vs 128×64** di HP (P-01), kunci ukuran.
- Pemain placeholder 8 arah, joystick virtual, Y-sort, kamera.
- Ekspor APK uji pertama dan jalankan di HP.
- Ukur performa dasar.
- Keluaran: keputusan ukuran tile, renderer, dan catatan performa.

## Fase 2: Dasar sistem
- Autoload (`EventBus`, `Game`, `Settings`, `Locale`, `SaveService`).
- Resource bertipe dan validator data.
- Interaction System, Dialogue System (dasar), Localization ID/EN.
- Save/Load dasar.
- Unit test dan tes data berjalan.

## Fase 3: Irisan vertikal klinik
- Patient + Diagnosis sederhana + satu terapi (jarum fiktif, mekanik dipilih lewat P-10) + hasil.
- Satu pasien, satu penyakit fiktif, satu ruangan klinik.
- Uji bermain di HP; evaluasi kenyamanan.

## Fase 4: Herbal dan racik
- Mengumpulkan, menanam, memanen; Crafting; Inventory.
- Hubungkan ke terapi di klinik.

## Fase 5: Dunia dan progres
- Wilayah pertama (desa, lalu hutan), NPC, Quest.
- Skill System, Economy (setelah P-12), reputasi, pengembangan klinik.
- Wilayah berikutnya (pegunungan, dll.) sesuai P-11.

## Fase 6: Pembuat karakter dan kepolesan
- Pembuat karakter (sesuai P-08), audio, efek, animasi aksi.
- Optimasi performa, aksesibilitas, peninjauan konten dan budaya (P-17).

## Fase 7: Uji dan rilis
- Uji di beberapa perangkat, perbaikan bug.
- Persiapan toko (ikon, deskripsi, kebijakan privasi bila perlu, tanda tangan).
- Rilis tertutup lalu rilis.

## Dependensi kunci
| Fase | Menunggu |
|---|---|
| 1 | P-15, P-02, P-03 |
| 3 | P-10, P-09 |
| 5 | P-11, P-12 |
| 6 | P-08, P-17 |
| 7 | P-06, P-07, P-12 |

## Definisi "selesai" per modul
Modul dianggap selesai jika: kode dan data terdokumentasi, tes otomatis lolos (bila ada logika murni), diuji di perangkat Android, tidak ada error yang diketahui, dan perubahan dicatat di `docs/CHANGELOG.md`.
