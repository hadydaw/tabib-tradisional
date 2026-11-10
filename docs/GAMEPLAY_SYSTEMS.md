# GAMEPLAY_SYSTEMS

Status: v0.1. Daftar sistem dan aktivitas adalah **[FINAL]** (instruksi pemilik). Cara kerja di bawah ini adalah **[USULAN]** untuk didiskusikan; **belum ada yang disetujui sebagai desain final**. Tidak ada angka keseimbangan.

Semua mekanik pengobatan **fiktif** [FINAL]: bukan panduan medis nyata. Nama titik, penyakit, dan ramuan dibuat fiktif dan tidak memetakan ke pengobatan sungguhan.

## 1. Patient System
- Pasien datang ke klinik (atau ditemui di dunia), membawa keluhan.
- Data: `PatientData` + `AilmentData` (fiktif).
- Status: menunggu, diperiksa, diobati, sembuh/belum.
- Pending: antrean, batas waktu, perilaku pasien (P-09, P-10).

## 2. Diagnosis System
Usulan alur: pasien menyebut keluhan → pemain memeriksa (mis. mengamati, bertanya, memeriksa bagian tertentu) → petunjuk terkumpul → pemain memilih kesimpulan penyakit fiktif → umpan balik.
- Pemeriksaan memberi **petunjuk fiktif**, bukan teknik diagnosis nyata.
- Pending: jumlah jenis pemeriksaan, apakah salah diagnosis berakibat.

## 3. Acupuncture System
Usulan: pemain menempatkan jarum pada **titik fiktif** di model tubuh pasien untuk menghasilkan efek (mis. meredakan gejala fiktif).
Opsi mekanik untuk dipilih pemilik (P-10):
- A. Tap titik pada model dengan urutan atau kombinasi.
- B. Minigame sentuh: tekanan/ritme.
- C. Puzzle pola titik.
Catatan keamanan konten: titik, namanya, dan efeknya fiktif dan tidak mewakili lokasi atau khasiat akupuntur nyata.

## 4. Herbal System
- Mengumpulkan tanaman liar di dunia.
- Menanam dan memanen di petak/kebun klinik.
- Data: `HerbData` (fiktif atau terinspirasi, tanpa klaim khasiat nyata).
- Pending: sistem waktu pertumbuhan dan musim (P-09).

## 5. Crafting System
- Meracik obat dari bahan menurut `RecipeData`.
- Usulan: resep dipelajari lewat Skill atau Quest; hasil berupa item.
- Pending: ada minigame racik atau tidak.

## 6. Inventory System
- Tas dengan item bertumpuk (`ItemData`), kategori (herbal, ramuan, alat, misi).
- Pending: batas kapasitas dan bobot.

## 7. Quest System
- Misi dan tujuan dengan status (belum, aktif, selesai).
- Pending: struktur cerita (P-11).

## 8. Economy System
- Uang, harga, toko, imbalan pasien.
- Pending seluruhnya (P-12). Tidak ada angka ditetapkan.

## 9. Skill System
- Mempelajari teknik pengobatan baru (`SkillData`) yang membuka terapi, resep, atau area.
- Pending: pohon skill, XP atau guru.

## 10. Reputasi dan klinik
- Reputasi bertambah dari pasien yang tertolong dan memengaruhi jenis pasien/akses.
- Klinik dapat dikembangkan (ruangan, alat).
- Pending: pohon pengembangan dan ambang reputasi.

## 11. NPC, Dialogue, Interaction
- NPC: rutinitas sederhana dan pathfinding grid.
- Dialogue: teks bercabang dengan kunci lokalisasi, bisa menampilkan nama pemain.
- Interaction: objek yang bisa diinteraksi menampilkan prompt dan menjalankan aksi lewat tombol interaksi.

## 12. World, Movement, Camera, Player
- Lihat `GODOT_ARCHITECTURE.md` dan `ISOMETRIC_VISUAL_STANDARD.md`.
- Pergerakan 8 arah lewat joystick virtual; kamera mengikuti pemain.

## 13. Save System
- Simpan state ke `user://`. Detail di arsitektur.

## 14. Urutan prioritas implementasi
Lihat `DEVELOPMENT_ROADMAP.md`. Irisan vertikal pertama: gerak isometrik → interaksi → satu pasien dengan diagnosis sederhana → satu terapi → hasil.

## Fase 4: NPC, dialog, pasien (struktur)
- **Penduduk**: jadwal harian per NPC; aktivitas ditampilkan di dialog ("Sedang apa?").
- **Permintaan**: terima dari NPC, penuhi (bicara/kunjungi), lapor. Tanpa hadiah.
- **Pasien**: keluhan fiktif ringan; antrean bernomor; satu ruang periksa. Tahap berikutnya mengisi `DiagnosisRecord`/`TreatmentRecord` (belum ada sistem diagnosis, akupunktur, atau peracikan).


## Fase 5: pengobatan lewat minigame (implementasi)
Prinsip: **minigame adalah gameplay utama**; pengobatan tidak lewat menu/timer. Semua pengobatan fiktif; tidak ada panduan medis nyata.
- **Alur**: pasien dipanggil -> Tempat Periksa -> Diagnosis -> Metode (akupunktur, ramuan, atau keduanya) -> minigame metode (akupunktur dulu, lalu ramuan) -> hasil -> ringkasan -> pasien pulang.
- **Diagnosis**: 6 area periksa (dahi, mata, lidah, kulit, perut, nadi). Tiap pemeriksaan memakai "tenaga periksa" (4, naik dengan skill). Nadi = uji ritme (ketuk mengikuti denyut, 3 denyut pertama ditampilkan). "Amati" memberi satu petunjuk (yang paling lemah). Tabel kandidat memuat tanda cocok/bertentangan (skill tingkat 2+). Dua kesempatan menetapkan; salah = nilai maksimum D.
- **Akupunktur**: pilih titik (urutan pilihan = urutan tusuk; maks 5), bidik jarum dengan geser pada bidang bidik (ada getaran), tekan JARUM saat penanda kedalaman di zona. Nilai: ketepatan posisi/kedalaman, kelengkapan rencana, urutan, kesalahan, waktu.
- **Peracikan**: ambil bahan sesuai urutan resep dari inventaris, takar (tahan TUANG, lepas di garis), tumbuk (ketuk berirama), aduk (lingkar dengan kecepatan stabil). Komposisi/urutan salah membatasi nilai.
- **Identifikasi tanaman**: amati bagian (sebagian tertutup pada skill tinggi), bandingkan dengan ciri di kartu pilihan, pilih (2 tebakan). Berhasil: pengetahuan + panen bahan. Satu kali per titik per hari.
- **Penilaian**: skor 0-100 -> S>=92, A>=80, B>=65, C>=45, D. Kualitas metode = kecocokan x skor; gabungan = 1-(1-q1)(1-q2). Hasil: sembuh >=0.60, membaik >=0.35, gagal. Bayaran = dasar x (0.4+0.8q) x (1+reputasi/250); reputasi -2/0/+1/+2/+3 menurut nilai kunjungan.
- **Skill** (tingkat 1-5; XP dari nilai minigame): Diagnosis, Akupunktur, Pengetahuan Herbal (membuka resep, petunjuk takaran), Peracikan, Identifikasi Tanaman.
- **Menambah konten**: tambahkan entri di `data/ailments`, `data/points`, `data/herbs`, `data/recipes` + teks di `tools/loc_fase5.py`; tes data memeriksa konsistensi.


## Fase 6: ekonomi, upgrade klinik, dan simpanan (implementasi)
Semua koin dan bahan fiktif. Angka sementara (`EconomyDb`, `ClinicUpgrades.DEFS`), perlu disetel setelah uji di HP.
- **Pemasukan**: bayaran pasien (rumus Fase 5, naik dengan kualitas & reputasi); jual surplus bahan (40% harga beli); capaian sekali (pasien ke-1/10/30, sembuh pertama, reputasi 40/70: 20-250 koin); naik tingkat skill (25 x tingkat baru).
- **Pengeluaran**: beli bahan di Pasar (Rak Herbal klinik, harga 5-14); upgrade; biaya operasional harian (20 + 5 per tingkat upgrade) dipotong saat pergantian hari, tidak pernah membuat saldo minus.
- **Tempo**: 3-5 pasien/hari; kunjungan nilai B ~ 35-45 koin. Upgrade termurah (120) terjangkau dalam ~1-2 hari, semua upgrade dalam ~2-3 minggu. Pemain nilai B mencapai skill tingkat 2 setelah ~3 kunjungan dan tingkat 5 setelah ~25 per cabang (diuji di `run_tests_fase6.gd`).
- **Upgrade** (6 x 2 tingkat; Meja Pengobatan): Lentera Periksa (+1 energi periksa diagnosis), Set Jarum Perak (radius bidik +0,02; syarat Akupunktur 2/3), Lumpang Batu (toleransi takaran +10%; Peracikan 2/3), Rak Herbal Besar (stok harian minimal +1), Ruang Tunggu Nyaman (penalti menunggu -30%), Pupuk & Pagar Kebun (panen +1; Identifikasi 2/3). Biaya 120-420, syarat reputasi 20-40; setiap tingkat menambah biaya harian 5.
- **Simpan**: otomatis saat pergantian hari, menutup layar penuh, aplikasi dijeda/ditutup; manual lewat Buku Tabib. Pasien yang sedang antre tidak disimpan.
- **Menambah upgrade/bahan**: tambahkan entri di `ClinicUpgrades.DEFS` + `IDS` + fungsi efek + teks `upgrade.<id>.name/.effect` di `tools/loc_fase6.py`; harga bahan di `EconomyDb.HERB_BUY`.


## Fase 7: eksplorasi, pengumpulan, dan misi (implementasi)
Semua tanaman dan efek fiktif; tidak ada panduan pengobatan nyata.
- **Area**: Hutan (barat desa; 4 titik pengumpulan; papan Pengembara), Sungai (timur desa; sungai dengan jembatan; 3 titik), Pegunungan (utara hutan; 3 titik; celah rahasia). Kunjungan pertama memberi 15 koin.
- **Pengumpulan**: tanaman yang sudah dikenal langsung masuk inventaris (1 bahan, 2 bila langka; 15% peluang langka per titik). Tanaman belum dikenal membuka identifikasi (Fase 5); berhasil = dikenal, masuk Buku Tabib, dan panen. Setiap titik tumbuh kembali setelah 240 menit permainan (4 jam).
- **Stamina** (0-100): pulih 0,1 per menit permainan (penuh dalam sekitar 1000 menit). Biaya: bahan dikenal 8, identifikasi 12, celah 10. Berjalan dan menjelajah tidak memakai stamina. Bila ditunda sebelum selesai, stamina dikembalikan. Stamina tidak pernah menghentikan gerak.
- **Misi Pengembara** (berurutan; hadiah koin): kumpulkan 4 bahan di hutan (60), kenali 3 tanaman baru (90), kunjungi Sungai dan Pegunungan (80), baca celah rahasia (150).
- **Celah rahasia**: butuh Identifikasi tingkat 2 atau 3 tanaman dikenal. Sekali seumur permainan: 2 Kayu Manis dan 40 koin.
- **Integrasi**: inventaris, Buku Tabib (tanaman baru), identifikasi Fase 5, ekonomi Fase 6 (hadiah koin masuk buku kas), simpan Fase 6 (kunci `adventure`), dan skill (XP identifikasi).
- **Menambah titik**: entri di `ForageDb.all_nodes()` dan teks di `tools/loc_fase7.py`; sel harus dapat dilewati (diperiksa tes lokasi).

## Fase 8: hubungan NPC, cerita, quest, dan event desa

**Hubungan (kepercayaan).** Setiap penduduk (8 orang) punya kepercayaan 0..100, mulai dari 10. Tingkat sapaan: 0 (di bawah 35, belum akrab), 1 (35..69), 2 (70 ke atas). Sapaan tiap penduduk punya tiga varian per tingkat.
- Bicara: +2, sekali per hari per penduduk.
- Berikan bahan (pilihan dialog "Berikan bahan herbal"): +8 bila bahan kesukaan penduduk, +3 untuk bahan lain. Satu kali per hari per penduduk. Bahan dikurangi dari tas.
- Bab cerita: +4 saat pemain memilih "Ceritakan lebih banyak".

**Bab cerita.** Setiap penduduk punya dua bab (ambang kepercayaan 25 dan 60). Tiap bab punya teks utama dan lanjutan. Bab terbuka berurutan, dan dicatat hanya bila didengar sampai habis; "Nanti saja" membuat bab muncul lagi.

**Quest cerita.** Empat quest, masing-masing diberikan satu penduduk:
- Ramuan untuk Mbah Wiryo (min. kepercayaan 30): kumpulkan 3 bahan dari titik liar. Pilihan: "jujur" (25 koin, reputasi +1, kepercayaan +6) atau "untung" (60 koin, reputasi -1, kepercayaan -4).
- Cerita dari Sungai (min. kepercayaan 15): kunjungi Sungai, lalu lapor ke Dewi. Pilihan: "apa adanya" (15 koin, reputasi +1, kepercayaan +5, kayu manis) atau "dilebihkan" (30 koin, reputasi -2).
- Pasien Pilihan (min. kepercayaan 25, reputasi desa 30): tangani 3 pasien dengan hasil B ke atas. Pilihan: "upah" (50 koin) atau "bagi" (10 koin, reputasi +2, kepercayaan +6, jahe).
- Tanaman Liar di Kebun Karto (min. kepercayaan 40): identifikasi 2 tanaman baru. Pilihan: "bagi jasa" (20 koin, reputasi +2, kepercayaan +6) atau "ambil pujian" (40 koin, reputasi -1, kepercayaan -4).

Alur: tawaran muncul di dialog penduduk pemberi bila syarat terpenuhi, lalu "Soal tugasmu..." untuk status, dan "Tugasku sudah selesai" saat siap diserahkan. Quest siap diberi tahu lewat toast dan baris HUD.

**Event desa.**
- Pasar Desa: setiap hari kelipatan 3, pukul 08:00 sampai 10:00. Pemain di desa mendapat 20 koin dan reputasi +1.
- Malam Bakti: setiap hari kelipatan 4, pukul 18:00 sampai 19:00. Pemain di desa membuat semua penduduk makin percaya (+3) dan reputasi +2.
Setiap event hanya dihitung sekali per hari. HUD menampilkan "Event berikutnya".

**Reputasi desa** memakai nilai reputasi klinik yang sudah ada (0..100). Quest dan event menggesernya; pelayanan pasien tetap menjadi sumber utamanya.

**Buku Tabib** menampilkan tingkat hubungan tiap penduduk dan jumlah tugas selesai/berjalan.

**Simpan/muat.** Hubungan, bab, hari bicara dan pemberian, status quest, klaim event, serta permintaan Fase 4 disimpan di kunci `social`. Simpanan Fase 6 dan 7 tanpa kunci ini tetap bisa dimuat dan mulai dari keadaan awal.

**Batasan jujur.** Resep dan akses area baru belum termasuk hadiah; quest hanya empat. Event tidak meminta tindakan khusus selain berada di desa.
