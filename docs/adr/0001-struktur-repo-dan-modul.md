# ADR 0001: Struktur repo dan batas modul

- Tanggal: 2026-11-09
- Status: Diterima (keputusan teknis rutin oleh Claude; bisa diubah)

## Konteks
Pemilik meminta sistem modular dengan 19 modul dan data berbasis Resource, tanpa ketergantungan antarmodul yang tidak perlu.

## Keputusan
1. Proyek Godot berada di `game/`; dokumen, aset mentah, tes, dan alat di luar `game/`.
2. Satu folder per fitur di `game/features/`. Fitur tidak mengimpor fitur lain; komunikasi lewat `EventBus` (signal).
3. `core/` tidak bergantung pada fitur atau UI.
4. Konten adalah Resource bertipe di `data/`, direferensikan lewat ID `snake_case`.
5. Autoload dijaga sedikit: `EventBus`, `Game`, `SaveService`, `Locale`, `Settings`.

## Konsekuensi
- Modul dapat diuji dan diganti terpisah.
- Perlu disiplin: pelanggaran batas modul harus ditangkap saat review.
- Signal global harus bertipe dan terdokumentasi agar tidak berantakan.

## Alternatif
Satu skrip besar per sistem atau pemanggilan langsung antarfitur: ditolak karena sulit diuji dan melanggar permintaan modularitas.
