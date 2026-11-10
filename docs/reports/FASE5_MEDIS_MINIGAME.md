# Laporan Fase 5: Gameplay Medis dan Sistem Minigame (10 Nov 2026)

**Status: kode selesai dan lolos tes otomatis di CI (run 42773379984, commit 6e721fb, versionCode 30). BELUM diuji di perangkat fisik (nubia Neo 2 5G): rasa sentuhan, kenyamanan ibu jari, keseimbangan kesulitan, dan performa belum dinilai. Semua angka keseimbangan bersifat sementara. Semua pengobatan adalah simulasi fiktif, bukan panduan medis.**

## Prinsip
Minigame adalah gameplay utama. Tidak ada jalur pengobatan lewat menu/tombol/timer saja: setiap tahap (diagnosis, akupunktur, peracikan) adalah permainan sentuh yang hasilnya ditentukan keterampilan pemain.

## Alur (terintegrasi dengan antrean Fase 4)
Pasien datang -> mengambil nomor -> pemain memanggil di Meja Penerimaan -> pasien duduk di ruang periksa -> pemain menyentuh **Tempat Periksa** -> **Diagnosis** -> **pilih metode** (akupunktur, ramuan, atau keduanya) -> **Akupunktur** (bila dipilih) -> **Peracikan** (bila dipilih) -> hasil dihitung dari performa -> **ringkasan kunjungan** -> pasien pulang.
- Tahap disimpan per pasien (`TreatmentSession`). Tombol **Tunda** menutup layar tanpa kehilangan kemajuan; menyentuh Tempat Periksa lagi melanjutkan di tahap yang sama.
- Pasien yang tidak ditangani pulang setelah 150 menit permainan di ruang periksa.
- Waktu dunia berhenti selama minigame; kontrol dunia (joystick, tombol interaksi) dikunci (`UiGate`).
- Peralihan: layar penuh dengan pudar halus dari dunia isometrik (0,28 dtk masuk).

## Minigame
1. **Diagnosis** (`DiagnosisSystem`, `DiagnosisView`): sentuh enam area pada tubuh pasien (dahi, mata, lidah, kulit, perut, nadi). Tiap pemeriksaan memakai tenaga periksa (4, naik dengan skill). **Nadi** = uji ritme: ketuk mengikuti denyut (hanya 3 denyut pertama diperlihatkan, sisanya dijaga ritmenya sendiri); denyut kurang jelas -> temuan tidak terbaca. Tombol **Amati gejala** memberi satu petunjuk gratis (yang paling lemah, sekali per sesi). Catatan temuan terisi; tabel kandidat memuat ciri tiap kemungkinan penyakit (dengan tanda cocok/bertentangan pada skill tingkat 2+). Dua kesempatan menetapkan. Bukan sekadar daftar penyakit: kandidat yang berbagi keluhan berbeda di minimal 3 area, jadi pemeriksaan yang tepat penting.
2. **Akupunktur** (`AcupunctureSystem`, `AcupunctureView`): tubuh pasien dengan 10 titik fiktif berlabel (nama + sifat). Pemain memilih titik sesuai petunjuk diagnosis (urutan pilihan = urutan penusukan, maks 5), lalu **membidik** jarum dengan menggeser pada panel bidik (ada getaran tangan), dan menekan tombol **JARUM** saat penanda kedalaman berada di zona hijau. Nilai: ketepatan posisi dan kedalaman, kelengkapan titik rencana, urutan, kesalahan (titik salah), waktu.
3. **Peracikan** (`HerbalCraftingSystem`, `CraftingView`): empat tahap. **Pilih**: ambil bahan dari rak/inventaris dalam jumlah dan urutan resep (bahan habis atau berlebih tercatat sebagai kesalahan). **Takar**: tahan tombol TUANG, lepas tepat di garis target. **Tumbuk**: mortar dan alu, ketuk saat cincin menyusut menyentuh lingkaran emas (ritme per resep). **Aduk**: putar jari melingkar dengan kecepatan stabil dalam pita hijau, searah. Tiap resep punya komposisi, urutan, takaran, jumlah ketukan, dan putaran berbeda. 7 resep.
4. **Identifikasi tanaman** (`PlantIdentificationSystem`, `PlantView`): tanaman utuh (gambar prosedural placeholder); sentuh daun/bunga/akar/buah untuk diamati dan dibaca cirinya; kartu pilihan menampilkan ciri tiap kandidat untuk bagian yang sudah diamati; pilih identitas (2 tebakan). Kesulitan naik dengan skill (lebih banyak pilihan, pengecoh mirip, bagian tertutup kabut). Berhasil: pengetahuan herbal tercatat + panen bahan ke inventaris. Terintegrasi dengan **kebun herbal** (4 petak) dan **3 titik liar** di desa; satu kali per titik per hari.

## Penilaian
`ScoringSystem`: komponen 0..1 dengan bobot per minigame dinormalisasi; **bobot waktu dibatasi maks 15%** (tidak pernah penentu tunggal) dan ada lantai faktor waktu. Skor 0-100 -> **S >= 92, A >= 80, B >= 65, C >= 45, D**. Batas nilai: diagnosis salah maks D; komposisi resep salah maks C/D; tanaman keliru maks D. Tampilan hasil: huruf, nama nilai, skor, batang tiap komponen, XP, naik tingkat.
- Kualitas metode = kecocokan metode terhadap penyakit x skor; gabungan dua metode = 1-(1-q1)(1-q2).
- Hasil: **sembuh** >= 0,60; **membaik** >= 0,35; **gagal** di bawahnya.
- Kepuasan = 35 + 65q - penalti menunggu. Bayaran = dasar x (0,4+0,8q) x (1+reputasi/250). Reputasi per nilai kunjungan: -2/0/+1/+2/+3. Skor kunjungan = 25% diagnosis + 75% kualitas.

## Skill (5 cabang, tingkat 1-5)
Diagnosis, Akupunktur, Pengetahuan Herbal, Peracikan, Identifikasi Tanaman (`SkillProgressionSystem`, `SkillDb`). XP dari nilai minigame (dasar 5/12/20/30/40 untuk D/C/B/A/S, +25% per tingkat kesulitan di atas 1; peracikan dan identifikasi juga menambah Pengetahuan Herbal). Efek hanya melonggarkan jendela secara terbatas (sekitar +30-40% pada tingkat 5; mis. tenaga periksa 4->6, radius titik, jendela ketuk/takar/aduk, tanda bantu tabel kandidat, takaran terlihat pada kartu resep, jumlah pilihan identifikasi) agar keterampilan manual tetap menentukan.

## Arsitektur dan data (dapat diperluas tanpa mengubah kode inti)
`AilmentDb` (12 penyakit fiktif, 6 area periksa), `AcupointDb` (10 titik, sifat unik), `HerbDb` (10 tanaman Nusantara: kunyit, jahe, temulawak, kencur, serai, lengkuas, sambiloto, kumis kucing, sirih, kayu manis; 4 ciri tiap tanaman), `RecipeDb` (7 resep berurutan), `SkillDb`. Sistem logika murni (tanpa node, dites unit) terpisah dari tampilan (`ui/minigame/`) dan alur (`TreatmentManager`, `MinigameManager`). `HerbInventory` (bahan; stok harian minimal 2 tiap bahan), `ClinicStats` (koin, reputasi, pasien), `GardenSystem`. HUD: tombol **Buku** (Buku Tabib: skill, bahan, tanaman dikenal, koin/reputasi) dan baris koin/reputasi.
Detail: `GODOT_ARCHITECTURE.md`, `GAMEPLAY_SYSTEMS.md`.

## Hasil tes (CI run 42773379984)
- Unit: dasar 108/0, Fase 3 149/0, Fase 4 138/0, **Fase 5 191/0** (penilaian, ritme, data, skill, inventaris, diagnosis, akupunktur, peracikan, identifikasi, kebun, alur terintegrasi dengan antrean, diagnosis salah/pengobatan gagal, kelengkapan localization termasuk pemindaian kunci di skrip UI).
- Asap: prototipe 68/0, dunia Fase 2 46/0, game Fase 3 59/0, NPC Fase 4 55/0 (mode Fase 4 dipertahankan lewat `set_medical_enabled(false)`), **medis Fase 5 69/0**: alur lengkap lewat layar nyata (tombol dan sentuhan disimulasikan) dari ruang periksa sampai pasien pulang, Tunda/lanjut, kunci kontrol dunia, jeda waktu, inventaris berkurang saat bahan diambil, kebun -> panen/pengetahuan/XP, satu kali per hari lalu terbuka hari berikutnya, Buku Tabib, jalur gagal (diagnosis salah -> D, titik salah dan meleset -> D, hasil gagal).
- Validasi proyek lolos; kompatibilitas statis 5/5; APK debug terbentuk.
- Tangkapan layar CI (renderer perangkat lunak) memeriksa tampilan 17 layar minigame dan memperlihatkan beberapa bug tata letak yang lalu diperbaiki (tabel kandidat menumpuk, teks terpotong, cincin tumbuk menimpa judul).

## Selesai
Empat minigame dapat dimainkan dan terhubung ke alur pasien; penilaian S-D; skill; inventaris; kebun/eksplorasi desa; dokumentasi; tes otomatis lolos; push ke main; APK dari GitHub Actions.

## Tertunda / batas yang jujur
- **Belum diuji di HP**: yang paling perlu dicek: kenyamanan membidik jarum dan tombol JARUM dengan ibu jari, ritme tumbuk/nadi (jendela ketuk), menuang takaran, memutar aduk, keterbacaan teks kecil (kartu pilihan identifikasi 15 px, ciri di tabel kandidat), kecepatan tampilan, dan apakah kesulitan terlalu mudah/sulit.
- Visual semua minigame placeholder (bentuk sederhana, gambar tanaman prosedural); belum ada audio/efek, animasi jarum dan alu, getar haptik.
- Angka keseimbangan sementara (ambang nilai, bayaran, tenaga, kesempatan, XP, jadwal stok bahan).
- Belum ada penyimpanan (skill, inventaris, koin hilang saat game ditutup) dan belum ada pembelian bahan; bahan hanya dari stok harian + panen. Keluhan dengan hanya 2 kandidat memberi kesempatan kedua yang selalu benar.
- Identifikasi tanaman di titik liar hanya 3 titik di desa; belum ada hutan/wilayah baru (di luar lingkup).
- Teks penyakit, titik, resep, ciri tanaman placeholder dan belum ditinjau budaya (P-17). Semua fiktif.
- Pose dan animasi pasien di ranjang masih placeholder (pasien duduk di tempat periksa).
