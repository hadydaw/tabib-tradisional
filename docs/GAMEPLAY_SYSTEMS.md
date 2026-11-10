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
