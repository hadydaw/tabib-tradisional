# Laporan Fase 3: Karakter dan Pengembangan Dunia (10 Nov 2026)

**Status: kode selesai, lolos tes otomatis di CI. Belum diuji di perangkat fisik, performa desa baru belum diukur.**
Build terakhir: run 42760732439 (commit 0b7cffb), versionCode 17.

## Yang dibangun
- **Karakter**: `CharacterAppearance` (Resource: kulit, rambut, warna rambut, gaya baju/celana/topi, simpan/muat aman), `OutfitItem` + `OutfitCatalog` (11 item placeholder, slot TOP/BOTTOM/HEAD), `CharacterPalette` (6 kulit, 6 warna rambut, 4 gaya rambut), `CharacterView` (gambar berlapis prosedural, 8 arah, idle/walk, antarmuka sama dengan `PlayerPlaceholder`). Tombol debug mengganti kulit/rambut/baju/celana/topi saat main.
- **Desa Nusantara 48x40**: jalan utama, gang, alun-alun batu, kolam, 6 rumah warga, klinik tabib, kebun herbal berpagar (24 tanaman herbal), pohon tropis (palem, pisang, bambu, buah), semak, bunga, batu, lentera, sumur, papan petunjuk.
- **Klinik 16x12 (potongan interior)**: area penerimaan, ruang pemeriksaan (ranjang), meja terapi, rak simpan herbal, area peracikan, bangku tunggu. Masuk/keluar lewat keset pintu (tile MAT) dengan fade.
- **Struktur interaksi**: `Interactable` + `InteractionSystem` (terdekat dalam radius, bonus arah hadap), tombol Interaksi + label. Interaksi klinik hanya memunculkan toast "[Placeholder]"; sistem pengobatan belum dibuat (sesuai batas fase).
- **Arsitektur dunia data-driven**: `LocationData`, `LocationBuilder`, `VillageLocation`, `ClinicLocation`, `LocationRegistry`; bangunan dipotong per sel dinding + satu atap agar Y-sort benar; satu mesh per prop (1 draw call).
- Scene utama kini `scenes/world/game_world.tscn`. `test_world` Fase 2 dipertahankan sebagai regresi.

## Hasil tes (CI run 42760732439)
Unit 108/0 gagal, unit Fase 3 142/0, asap prototipe 68/0, asap dunia Fase 2 46/0, asap game 59/0 (termasuk 36 variasi tampilan), validasi proyek OK, kompatibilitas statis 5/5, APK terbentuk.
Uji keterjangkauan (BFS): minimal 85% sel kosong terjangkau, semua interactable dan keset terjangkau. Anggaran node: desa < 450, klinik < 150.
Tangkapan layar CI (renderer perangkat lunak) menunjukkan desa, klinik, rumah, kebun, dan karakter terbaca.

## Batas yang jujur
- Tidak ada uji di HP. Yang perlu dicek: jalan di desa, masuk klinik lewat keset merah, Interaksi di dekat objek, tombol debug penampilan, Y-sort di sekitar rumah/pohon/atap, rasa performa.
- Performa desa tidak diukur (hanya estimasi ~330-400 node, ~1 draw call per node, objek di luar layar dipangkas).
- Semua visual placeholder. Karakter kasar (tampak belakang kepala polos, pose lengan/kaki sederhana). Gaya visual final belum disetujui (P-01).
- Di luar lingkup: sistem pengobatan, NPC, UI pembuat karakter, penyimpanan.
