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
- **Akupunktur**: pilih titik (urutan pilihan = urutan tusuk; maks 4), bidik jarum dengan geser pada bidang bidik (ada getaran), tekan JARUM saat penanda kedalaman di zona. Nilai: ketepatan posisi/kedalaman, kelengkapan rencana, urutan, kesalahan, waktu.
- **Peracikan**: ambil bahan sesuai urutan resep dari inventaris, takar (tahan TUANG, lepas di garis), tumbuk (ketuk berirama), aduk (lingkar dengan kecepatan stabil). Komposisi/urutan salah membatasi nilai.
- **Identifikasi tanaman**: amati bagian (sebagian tertutup pada skill tinggi), bandingkan dengan ciri di kartu pilihan, pilih (2 tebakan). Berhasil: pengetahuan + panen bahan. Satu kali per titik per hari.
- **Penilaian**: skor 0-100 -> S>=92, A>=80, B>=65, C>=45, D. Kualitas metode = kecocokan x skor; gabungan = 1-(1-q1)(1-q2). Hasil: sembuh >=0.60, membaik >=0.35, gagal. Bayaran = dasar x (0.4+0.8q) x (1+reputasi/250); reputasi -2/0/+1/+2/+3 menurut nilai kunjungan.
- **Skill** (tingkat 1-5; XP dari nilai minigame): Diagnosis, Akupunktur, Pengetahuan Herbal (membuka resep, petunjuk takaran), Peracikan, Identifikasi Tanaman.
- **Menambah konten**: tambahkan entri di `data/ailments`, `data/points`, `data/herbs`, `data/recipes` + teks di `tools/loc_fase5.py`; tes data memeriksa konsistensi.
