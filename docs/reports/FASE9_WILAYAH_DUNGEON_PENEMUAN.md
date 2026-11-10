# Laporan Fase 9: Wilayah baru, dungeon, dan penemuan langka

Status: **lolos CI (run 42806096395, kode 0a30567); APK sudah dibuat; belum diuji di perangkat.** Godot tidak tersedia di lingkungan pengembangan ini, jadi seluruh tes dijalankan oleh CI pada commit ini.

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

## Hasil CI final

Run GitHub Actions `42806096395` pada kode `0a30567`: **sukses**. Validasi lolos.

| Tes | Hasil |
|---|---|
| Unit Fase 2-8 (`run_tests`, fase3..fase8) | lolos, 0 gagal |
| Unit Fase 9 | 55 pemeriksaan, 0 gagal |
| Asap regresi (Fase 2-8) | lolos |
| Asap sosial Fase 8 | 54 pemeriksaan, 0 gagal |
| Asap eksplorasi Fase 9 | 34 pemeriksaan, 0 gagal |
| APK debug | dibuat; artifact `tabib-tradisional-debug-apk` (sekitar 28,6 MB) |

Versi APK: `version/code=1` (belum dinaikkan di konfigurasi ekspor).

Lewat CI tiga kali sebelum hijau: bool dari teks (data rusak), gua tanpa dinding dan keterjangkauan 85% (batu padat di luar ruangan), dan urutan tes gerbang. Penyebab tiap kegagalan sudah diperbaiki di kode, bukan dengan melonggarkan tes.

Screenshot yang diperiksa: rawa (41), gua (42), teka-teki (43), Buku Tabib (44). Tidak ada teks terpotong atau lokasi kosong. Di gua, batu padat membentuk massa besar di sekitar ruangan; ini sengaja untuk tampilan gua, tetapi perlu dilihat di HP.

## Batasan yang harus diketahui

1. **Penemuan langka belum masuk identifikasi dan resep.** Keputusan T-43: bahan disimpan sebagai inventaris terpisah agar tes identifikasi Fase 5 dan 6 tidak rusak. Tidak ada resep yang memakai bahan langka.
2. **Bahan langka tidak punya efek pengobatan.** Ini sesuai spesifikasi: hanya koleksi, quest, dan kunci akses.
3. **Belum diuji di perangkat.** Kontrol sentuh, ukuran teks layar teka-teki, dan keterbacaan kabut serta segel perlu dicek di HP.
4. **Tantangan lingkungan hanya teka-teki.** Belum ada rintangan lain (misalnya jembatan runtuh atau arus). Tidak ada yang wajib pertarungan.
5. **Quest eksplorasi memakai jalur yang sama dengan quest Fase 8.** Belum ada penilaian keseimbangan hadiah.

## Keputusan terkait

T-43 sampai T-46 di `docs/GAME_DESIGN_DECISIONS.md`.
