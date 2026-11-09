# GDD MASTER: Tabib Tradisional

Status: **v0.1 (Tahap 1)**. Nama bersifat sementara.
Label di setiap bagian: **[FINAL]** dari instruksi pemilik, **[USULAN]** dari Claude dan belum disetujui. Daftar lengkap ada di `GAME_DESIGN_DECISIONS.md`.

## 1. Identitas [FINAL]
- Judul sementara: Tabib Tradisional
- Genre: Hybrid Simulator + Adventure + RPG
- Dunia: Fantasi Nusantara
- Platform: Android saja, landscape
- Engine: Godot 4.x, GDScript
- Kamera: 2D isometrik orthographic
- Bahasa: Indonesia (utama), English (kedua)

## 2. Pitch [USULAN, ringkasan dari konsep pemilik]
Kamu adalah seorang tabib tradisional di dunia fantasi bernuansa Nusantara. Pasien datang ke kliniknya. Kamu memeriksa, mendiagnosis, mengobati dengan jarum dan ramuan, lalu menjelajah desa, hutan, dan pegunungan untuk mencari bahan, belajar teknik baru, dan membangun nama sebagai tabib.

## 3. Pilar desain [USULAN]
1. **Merawat dengan teliti.** Diagnosis dan pengobatan terasa seperti pekerjaan tangan yang cermat, bukan sekadar menekan tombol.
2. **Alam sebagai apotek.** Herbal dikumpulkan, ditanam, dan diolah; dunia memberi bahan.
3. **Klinik yang tumbuh.** Reputasi dan klinik berkembang dari pasien yang tertolong.
4. **Nyaman di genggaman.** Semua dimainkan satu tangan atau dua jempol di layar landscape.
5. **Fiktif dan aman.** Semua mekanik pengobatan fiktif (lihat bagian 9).

## 4. Aktivitas inti [FINAL]
1. Menerima dan mengobati pasien
2. Mendiagnosis penyakit melalui pemeriksaan
3. Menggunakan jarum akupuntur sebagai mekanik pengobatan
4. Mengumpulkan tanaman herbal
5. Menanam dan memanen tanaman obat
6. Meracik obat tradisional
7. Menjelajahi desa, hutan, pegunungan, dan wilayah lain
8. Mempelajari teknik pengobatan baru
9. Mengembangkan klinik
10. Membangun reputasi sebagai tabib

## 5. Loop permainan [USULAN]
- **Loop menit-ke-menit:** pasien datang, periksa, diagnosis, pilih terapi (jarum dan/atau ramuan), hasil, imbalan.
- **Loop sesi:** kumpulkan atau panen bahan, racik, rawat pasien, belanjakan hasil untuk klinik atau pelajaran.
- **Loop jangka panjang:** buka wilayah baru, pelajari teknik baru, tingkatkan reputasi, naikkan klinik.

## 6. Sistem inti
Rincian di `GAMEPLAY_SYSTEMS.md` (semua status USULAN kecuali tercantum). Daftar modul [FINAL]: Player Controller, Isometric Movement, Camera, World, NPC, Dialogue, Interaction, Patient, Diagnosis, Acupuncture, Herbal, Crafting, Inventory, Quest, Economy, Skill, Save, Localization, Android UI.

## 7. Dunia [USULAN, dasar saja]
Wilayah yang disebut pemilik: desa, hutan, pegunungan, "wilayah lainnya". Jumlah, nama, dan urutan wilayah **PENDING (P-11)**. Tidak ada peta atau cerita yang ditetapkan di dokumen ini.

## 8. Karakter
Pemain membuat karakter sendiri [FINAL]. Lingkup pembuat karakter **PENDING (P-08)**. Lihat `CHARACTER_DESIGN.md`.

## 9. Ketentuan konten pengobatan [FINAL]
- Semua penyakit, titik, ramuan, dan efek adalah **fiktif**.
- Game tidak memberi saran medis nyata. Nama titik, ramuan, dan gejala dirancang agar tidak bisa dipakai sebagai panduan pengobatan sungguhan.
- Tanaman dan istilah tradisional yang nyata boleh menjadi inspirasi nama dan tampilan, tetapi khasiat dalam game tidak boleh diklaim sebagai fakta kesehatan. Perlu peninjauan konten sebelum rilis (P-17).

## 10. Antarmuka dan kontrol [FINAL, rincian USULAN]
Landscape, virtual joystick, tombol interaksi, HUD horizontal, UI responsif. Lihat `ANDROID_REQUIREMENTS.md`.

## 11. Visual dan audio
Visual: lihat `ISOMETRIC_VISUAL_STANDARD.md`. Gaya seni **PENDING (P-04)**. Audio belum dirancang; masuk roadmap fase berikutnya.

## 12. Ekonomi dan progres
Ada modul Economy dan Skill [FINAL sebagai modul]. Isi dan angka **PENDING (P-12)**. Tidak ada angka keseimbangan yang ditetapkan.

## 13. Cakupan dan non-tujuan
- Bukan target: PC, Web, multiplayer. Ini keputusan pemilik untuk PC dan Web; multiplayer belum dibahas dan dianggap di luar cakupan awal [USULAN].
- Tahap 1 hanya fondasi dan dokumen. Belum ada gameplay.

## 14. Risiko
| Risiko | Mitigasi |
|---|---|
| Godot tidak bisa diunduh di lingkungan kerja ini, sehingga proyek belum bisa dijalankan dan diuji di sini | Dicatat di laporan. Pemilik atau CI harus menyediakan Godot (lihat DEVELOPMENT_ROADMAP.md Fase 0). |
| Ukuran tile belum dikunci | Uji prototipe di HP dulu (P-01). |
| Aset isometrik 8 arah mahal dibuat | Standar dan batasan di ASSET_PRODUCTION_GUIDE.md; mulai dari set kecil. |
| Salah paham konten pengobatan | Aturan di bagian 9 dan peninjauan konten. |
| Lingkup terlalu besar | Roadmap bertahap dengan vertical slice kecil. |
