# Laporan Fase 4: NPC dan Sistem Pasien (10 Nov 2026)

**Status: kode selesai dan lolos tes otomatis di CI (HASIL_CI). Belum diuji di perangkat fisik; performa dengan NPC belum diukur.**

## Yang dibangun
- **Penduduk (8 NPC)**: `NpcRoster`/`NpcData` (id, usia, rumah, tampilan, jadwal, permintaan). Nama/peran lewat localization. Tampilan memakai `CharacterAppearance` yang sama dengan pemain (`CharacterView`).
- **Jadwal harian**: tiap NPC punya entri `(jam, lokasi, spot, aktivitas)`; aktivitas: di rumah (tidak tampil), berkebun, ambil air, bersantai, berdagang, memancing, berjalan, bermain, mengantar rempah ke klinik (lintas lokasi). Jam permainan `GameClock`: 1 detik nyata = 1 menit permainan (1 hari = 24 menit), mulai 07:00 hari 1. Debug: tombol kecepatan x1/x8/x30.
- **Navigasi**: `GridPathfinder` (A* 8 arah pada grid sel yang sama dengan `GridCollision`, tanpa memotong sudut, keset pintu berbiaya tinggi). `NpcSimulation` menyimulasikan semua NPC sepanjang waktu (murah) dan hanya NPC di lokasi aktif yang digambar (`NpcNode`, masuk kelompok Y-sort yang sama dengan pemain).
- **Tabrakan**: sel yang dipakai/dipesan NPC menjadi sel terhalang sementara bagi pemain (`GridCollision.set_dynamic_blocked`); NPC tidak melangkah ke sel yang dipakai pemain/NPC lain.
- **Anti-tersangkut** (aturan di `NpcSimulation`): sel berikutnya terpakai -> tunggu (lebih lama untuk prioritas rendah) -> rencana ulang menghindari sel itu (maks 2x) -> batalkan tugas sementara dan menepi ke sel terbuka terdekat, jeda 3-6 detik, lalu rencana ulang. Pengawas kemajuan: 9 detik tanpa sel baru memaksa menepi. Pemain muncul di sel NPC -> NPC digeser.
- **Dialog**: `DialogueLibrary` membangun pohon dialog per NPC (sapaan, "Sedang apa?", cerita desa, permintaan), `DialogueRunner` menjalankannya, `DialoguePanel` menampilkan (tombol sentuh). Semua teks lewat `Locale` (Indonesia + English, 114 kunci, JSON dibuat dari `tools/gen_localization.py`). Debug: tombol ganti bahasa.
- **Permintaan sederhana**: `RequestDef`/`RequestLog` (4 permintaan: bicara dengan NPC lain, atau masuk zona; lapor ke pemberi). Tanpa hadiah.
- **Pasien**: `PatientSystem` + `ClinicQueue` + `PatientRecord`. Rencana harian deterministik (3-5 pasien, 08:15-15:00) atau tombol debug "Pasien baru". Alur: menuju klinik -> mendaftar di meja penerimaan (nomor antrean) -> duduk di salah satu 6 kursi (atau berdiri bila penuh, pindah duduk saat ada kursi kosong) -> dipanggil -> duduk di tempat periksa -> selesai -> pulang. Pasien menyerah setelah menunggu 120 menit permainan; antrean bubar saat klinik tutup (16:00).
- **Interaksi klinik**: Meja Penerimaan memanggil pasien berikutnya; Tempat Periksa mengakhiri pemeriksaan (placeholder). Pengganti sementara bila pemain tidak bertindak: pemanggilan otomatis setelah 12 menit dan pemeriksaan otomatis selesai setelah 25 menit (`auto_call`).
- **Struktur data tahap berikutnya (kosong, belum dipakai)**: `DiagnosisRecord`, `TreatmentRecord`, `ComplaintCatalog.ailment_hint`.
- Pose duduk `CharacterView` state `"sit"` (placeholder). HUD: jam/hari, status klinik, antrean, permintaan aktif.

## Di luar lingkup (sengaja tidak dibuat)
Diagnosis, akupunktur, peracikan obat, inventaris, hadiah/ekonomi, NPC memanggil NPC lain, penyimpanan.

## Hasil tes
HASIL_TES

## Batas yang jujur
- Tidak diuji di HP. Perlu dicek: NPC berjalan wajar dan tidak sering tersangkut, jadwal jalan, dialog terbaca, pasien datang dan antrean berjalan, Y-sort/tabrakan dengan NPC, rasa performa.
- Performa dengan NPC tidak diukur. Desain: maksimum 8 NPC, tiap NPC 1 node (menggambar ulang hanya saat bingkai animasi berganti), pencarian jalan hanya saat tujuan berubah.
- Visual NPC dan pose duduk placeholder. Gaya visual final belum disetujui (P-01/P-04).
- Teks dialog dan nama penduduk placeholder, belum ditinjau budaya (P-17).
