# CHARACTER_DESIGN

Status: v0.1. **[FINAL]**: pemain dapat membuat karakter sendiri; karakter beranimasi 8 arah; Y-sort di kaki; dunia Fantasi Nusantara.
Selebihnya **[PENDING]** sampai disetujui. Tidak ada tokoh, nama, atau latar karakter yang ditetapkan di dokumen ini.

## 1. Karakter pemain
### Final
- Pemain membuat karakter sendiri.
- 8 arah animasi, pivot kaki.

### Pending (P-08)
Pertanyaan untuk pemilik:
1. Pilihan gender: apa saja?
2. Apa yang bisa disesuaikan: wajah, rambut, warna kulit, pakaian, aksesori?
3. Apakah nama bebas diisi, dan adakah tanggal lahir atau asal daerah?
4. Apakah pakaian tabib bisa diganti dan memengaruhi gameplay?

### Usulan struktur teknis (tidak mengikat konten)
Karakter dibangun dari **lapisan sprite** yang bisa diganti (tubuh, pakaian, rambut, aksesori) dengan kerangka animasi 8 arah yang sama, agar variasi tidak mengalikan jumlah animasi. Detail kerangka dikunci setelah gaya seni dan ukuran tile ditetapkan.

## 2. NPC dan pasien
- Pasien dan warga memakai kerangka animasi yang sama dengan pemain (8 arah) untuk menghemat produksi.
- Variasi lewat kombinasi lapisan dan palet.
- Daftar tokoh penting **PENDING (P-11)**.

## 3. Kebutuhan visual minimum (Fase prototipe)
- 1 tubuh placeholder (netral) dengan `idle` dan `walk` 8 arah.
- Dipakai untuk menguji ukuran tile, Y-sort, dan kontrol, bukan sebagai desain final.

## 4. Pedoman budaya (USULAN)
Dunia terinspirasi Nusantara. Pakaian, motif, dan nama daerah diperlakukan dengan hormat dan akurat; tidak mencampur atribut sakral dengan cara yang merendahkan. Peninjauan budaya direncanakan sebelum konten final (P-17).
