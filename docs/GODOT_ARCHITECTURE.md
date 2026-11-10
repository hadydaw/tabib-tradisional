# GODOT_ARCHITECTURE

Status: v0.1. Daftar modul adalah **[FINAL]** (instruksi pemilik). Pilihan teknis lainnya adalah **[USULAN TEKNIS]** dan dapat diubah lewat ADR di `docs/adr/`.
Versi pasti Godot 4.x dan renderer masih **PENDING (P-02, P-03)**.

## 1. Prinsip
1. **Modular.** Satu fitur, satu folder di `game/features/<fitur>/`. Fitur tidak mengimpor fitur lain secara langsung.
2. **Data-driven.** Konten (tanaman, resep, pasien, penyakit fiktif, item, skill) adalah `Resource` bertipe, bukan angka di dalam skrip.
3. **State terpisah dari tampilan.** Logika dan data di skrip/Resource; node hanya menampilkan.
4. **Komunikasi lewat signal.** Antarmodul memakai `EventBus` (autoload) atau antarmuka kecil yang eksplisit.
5. **Android dulu.** Setiap keputusan dinilai dari dampak ke HP Android.
6. **Bisa diuji.** Logika murni (tanpa node) diuji dengan unit test.

## 2. Modul [FINAL]
| Modul | Folder | Tanggung jawab |
|---|---|---|
| Player Controller | `features/player` | Input pemain jadi perintah gerak dan aksi |
| Isometric Movement | `features/player` + `core/systems` | Konversi grid ke layar, kecepatan, tabrakan, 8 arah |
| Camera System | `features/camera` | Ikuti pemain, batas dunia, zoom tetap |
| World System | `features/world` | Peta, wilayah, tile, layer, perpindahan area |
| NPC System | `features/npc` | Warga, rutinitas, pathfinding |
| Dialogue System | `features/dialogue` | Percakapan, pilihan, variabel teks |
| Interaction System | `features/interaction` | Objek yang bisa diinteraksi, prompt tombol |
| Patient System | `features/patient` | Pasien, antrean, kondisi, hasil |
| Diagnosis System | `features/diagnosis` | Pemeriksaan, petunjuk, kesimpulan |
| Acupuncture System | `features/acupuncture` | Mekanik jarum (fiktif) |
| Herbal System | `features/herbal` | Mengumpulkan, menanam, panen tanaman obat |
| Crafting System | `features/crafting` | Meracik obat dari resep |
| Inventory System | `features/inventory` | Tas, tumpukan item |
| Quest System | `features/quest` | Misi, tujuan, status |
| Economy System | `features/economy` | Uang, harga, toko |
| Skill System | `features/skill` | Teknik pengobatan dan kemajuan |
| Save System | `features/save` | Simpan dan muat |
| Localization | `features/localization` | Teks ID dan EN |
| Android UI | `ui/` | HUD, panel, joystick, tombol |

## 3. Lapisan
```
UI (ui/)                 membaca state, mengirim niat lewat signal
Fitur (features/*)       node dan skrip per fitur
Inti (core/)             Resource bertipe, sistem murni, util
Data (data/*.tres)       konten
Autoload                 EventBus, Game, SaveService, Locale, Settings
```
Aturan ketergantungan: UI dan fitur boleh memakai `core/` dan autoload. `core/` tidak boleh bergantung pada fitur atau UI. Fitur A tidak boleh memanggil fitur B langsung; gunakan `EventBus`.

## 4. Autoload (usulan, sengaja sedikit)
| Autoload | Isi |
|---|---|
| `EventBus` | Kumpulan signal global bertipe (mis. `patient_treated`, `item_added`) |
| `Game` | State sesi (pemain, hari, referensi ke layanan), tanpa logika fitur |
| `SaveService` | Serialisasi dan penyimpanan |
| `Locale` | Bahasa aktif dan pencarian teks |
| `Settings` | Pengaturan pengguna (suara, bahasa, kontrol) |

## 5. Resource bertipe [FINAL: pakai Resource]
Skema berada di `game/core/resources/`. Instans konten di `game/data/`.
| Resource | Isi (usulan) | Folder data |
|---|---|---|
| `HerbData` | id, nama (kunci), ikon, tempat tumbuh, lama tumbuh, kelangkaan | `data/herbs` |
| `RecipeData` | id, bahan (id + jumlah), hasil, tingkat skill | `data/recipes` |
| `AilmentData` | id, nama, gejala (id), tingkat keparahan, terapi yang cocok (fiktif) | `data/ailments` |
| `PatientData` | id, penampilan, keluhan, penyakit | `data/patients` |
| `ItemData` | id, nama, jenis, tumpukan maks, harga dasar | `data/items` |
| `SkillData` | id, nama, syarat, efek | `data/skills` |
| `AcuPointData` | id, nama fiktif, posisi pada model, efek fiktif | `data/points` |

Aturan: ID bersifat `snake_case` dan stabil. Referensi antar-Resource memakai ID (bukan path) agar save dan lokalisasi tahan perubahan. Teks tampilan memakai kunci lokalisasi, bukan string langsung.

## 6. Dunia isometrik (ringkas)
Detail di `ISOMETRIC_VISUAL_STANDARD.md`. Usulan teknis: `TileMapLayer` dengan `tile_shape = isometric`, satu layer per fungsi (tanah, dekor, rintangan, dll.), `y_sort_enabled` aktif, pemain dan NPC di node ber-Y-sort. Akan diverifikasi di prototipe (Fase 1).

## 7. Lokalisasi
Kunci teks dalam CSV atau PO (usulan: CSV untuk kemudahan edit), dua bahasa: `id` (utama, harus lengkap) dan `en` (kedua). Aturan: tidak ada string tampilan di skrip; tes otomatis memeriksa kunci yang hilang.

## 8. Save
Format JSON versi (`save_version`), ditulis ke `user://`. Hanya data state (bukan referensi node). Migrasi versi disiapkan sejak awal. Penyimpanan cloud PENDING (P-13).

## 9. Input dan UI Android
Joystick virtual dan tombol dibuat sebagai `Control` yang mengirim `InputEvent` atau memanggil `Input.action_press`. Pemetaan aksi (`move_*`, `interact`, `menu`) didefinisikan di `project.godot`. Multi-touch wajib. Zona aman (notch/cutout) diperhitungkan. Lihat `ANDROID_REQUIREMENTS.md`.

## 10. Pengujian
- Unit test logika murni: runner sederhana `game/tests/unit/run_tests.gd` (tanpa plugin), dijalankan di CI. Plugin seperti GUT bisa ditambah nanti bila perlu.
- Tes data: semua Resource valid, semua ID unik, semua kunci teks ada di `id` dan `en`.
- Uji di perangkat sebelum modul dianggap selesai.

## 11. Build
Ekspor Android dari Godot (template ekspor). Tanda tangan dan keystore disimpan di rahasia CI, tidak di repo. Detail di `ANDROID_REQUIREMENTS.md` dan roadmap.

## 12. Struktur direktori
```
tabib-tradisional/
├── README.md
├── docs/                 dokumen proyek (+ adr/, reports/)
├── game/                 proyek Godot (project.godot di sini)
│   ├── autoload/
│   ├── core/{resources,systems}/
│   ├── features/<19 fitur>/
│   ├── ui/{hud,panels,virtual_input}/
│   ├── data/{herbs,recipes,patients,ailments,items,skills,points}/
│   ├── scenes/            (proto/ = prototipe Fase 1)
│   ├── tests/{unit,integration}/
│   └── localization/
├── assets/               aset mentah per kategori (+ _source/)
├── tools/                skrip bantu (check_project.py, ci/*.sh)
├── .github/workflows/    CI: validasi + APK debug
└── export/               preset dan catatan ekspor (tanpa rahasia)
```
Catatan: aset siap-pakai-engine ditempatkan di `game/` saat diimpor; `assets/` menyimpan sumber dan versi kerja (lihat ASSET_PRODUCTION_GUIDE.md).

## Fase 3: folder baru
- `features/character/`: appearance, outfit, palette, view.
- `features/interaction/`: `Interactable`, `InteractionSystem`.
- `features/world/shapes/` (ShapeBuilder), `props/` (PropCatalog), `structures/` (StructureBuilder), `locations/` (data lokasi, builder, desa, klinik, registry).
- `scenes/world/game_world.tscn`: scene utama (HUD, pemuatan lokasi, transisi fade).

## Fase 4: folder dan kelas baru
- `core/systems/grid_pathfinder.gd`: A* sel (logika murni). `GridCollision` mendapat sel dinamis.
- `features/npc/`: `GameClock`, `NpcData`, `NpcRoster`, `NpcGoal`, `NpcAgent`, `NpcSimulation`, `NpcNode`.
- `features/dialogue/`: `DialogueLibrary`, `DialogueRunner`. UI: `ui/hud/dialogue_panel.gd`.
- `features/quest/`: `RequestDef`, `RequestLog` (permintaan sederhana).
- `features/patient/`: `PatientRecord`, `ClinicQueue`, `PatientSystem`, `ComplaintCatalog`, `DiagnosisRecord`, `TreatmentRecord`.
- `features/localization/locale.gd`: `Locale.t()`; data `localization/id.json`, `en.json` (dibuat oleh `tools/gen_localization.py`).
- Data lokasi bertambah: `spots`, `seats`, `doors` (`LocationData`).
- Alur per frame di `game_world.gd`: input -> `step_world` (simulasi NPC + pasien, sinkron sel dinamis, sinkron node) -> interaksi.
