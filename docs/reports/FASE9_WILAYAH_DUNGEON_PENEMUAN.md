# Laporan Fase 9: Wilayah baru, dungeon, dan penemuan langka

Status: **dibangun dan dites otomatis (CI); belum diuji di perangkat.** Godot tidak tersedia di lingkungan pengembangan ini, jadi seluruh tes dijalankan oleh CI pada commit ini.

## Yang dibuat

| Area | Isi |
|---|---|
| Rawa | Lokasi baru di timur Sungai. Kolam dan jalan tanah, 4 titik penemuan langka, batu Penjaga Rawa, dan kabut yang menutup rawa dalam (dua titik lagi). |
| Gua Kapur | Lokasi baru di timur Pegunungan. Aula dengan Tablet Batu dan Tuas Batu, pintu tablet ke ruang dalam (2 titik langka), celah tuas ke ceruk Peti Gua. |
| Teka-teki | Tiga teka-teki urutan simbol. Jawaban salah mengosongkan urutan. Jawaban benar memberi koin dan satu bahan langka. |
| Peti Gua | Sekali seumur permainan: 60 koin dan 2 Benih Cendana. |
| Penemuan langka | 6 jenis bahan di Rawa dan Gua. Titik beristirahat 300 menit. Penemuan pertama memberi 15 koin dan tercatat di Buku Tabib. |
| Gerbang | Gua Kapur terbuka setelah 2 jenis penemuan langka. Gerbang terkunci memberi tahu sekali per sel. |
| Segel | Kabut, pintu tablet, dan celah tuas diblokir secara dinamis dan dibuka setelah teka-teki selesai. |
| Quest | `q_lastri_rawa` (Lastri, kumpulkan 3 penemuan) dan `q_joko_gua` (Joko, selesaikan Gua Kapur). Keduanya memakai alur quest Fase 8. |
| Simpan/muat | Kunci `frontier` berisi penemuan, titik, teka-teki, dan peti. Data rusak atau tak dikenal dibuang. Simpanan Fase 2 sampai 8 tetap terbaca. |
| Lokalisasi | `tools/loc_fase9.py`, Indonesia dan Inggris (706 kunci di total). |

## Tes

- Unit `run_tests_fase9.gd`: data langka dan teka-teki, status eksplorasi, cooldown, roundtrip dan data rusak, pintu antar-lokasi, titik kembali, dan keterjangkauan. Keterjangkauan dihitung dengan pencarian lebar pada sel yang tidak diblokir, dengan dan tanpa segel.
- Asap `run_smoke_frontier.gd`: masuk Rawa, ambil bahan, cooldown, jawaban salah lalu benar, kabut terangkat, gerbang gua, tablet, tuas, peti, dan simpan/muat lintas dunia.
- Unit Fase 8 diperbarui agar daftar jenis langkah quest menerima `discover` dan `dungeon`.
- Screenshot baru (41 rawa, 42 gua, 43 teka-teki, 44 Buku Tabib) di `capture.gd`.

## Batasan yang harus diketahui

1. **Penemuan langka belum masuk identifikasi dan resep.** Keputusan T-43: bahan disimpan sebagai inventaris terpisah agar tes identifikasi Fase 5 dan 6 tidak rusak. Tidak ada resep yang memakai bahan langka.
2. **Bahan langka tidak punya efek pengobatan.** Ini sesuai spesifikasi: hanya koleksi, quest, dan kunci akses.
3. **Belum diuji di perangkat.** Kontrol sentuh, ukuran teks layar teka-teki, dan keterbacaan kabut serta segel perlu dicek di HP.
4. **Tantangan lingkungan hanya teka-teki.** Belum ada rintangan lain (misalnya jembatan runtuh atau arus). Tidak ada yang wajib pertarungan.
5. **Quest eksplorasi memakai jalur yang sama dengan quest Fase 8.** Belum ada penilaian keseimbangan hadiah.

## Keputusan terkait

T-43 sampai T-46 di `docs/GAME_DESIGN_DECISIONS.md`.
