"""Teks Fase 7 (petualangan & eksplorasi). Dipanggil dari gen_localization.py: register(add)."""

AREAS = {
  "hutan": ("Hutan", "Forest"),
  "sungai": ("Sungai", "River"),
  "pegunungan": ("Pegunungan", "Mountains"),
}

FORAGE = {
  "forage_hutan_1": ("Rumpun Hutan Utara", "Northern Forest Clump"),
  "forage_hutan_2": ("Semak Hutan Timur", "Eastern Forest Scrub"),
  "forage_hutan_3": ("Rimbun Hutan Barat", "Western Forest Thicket"),
  "forage_hutan_4": ("Tanah Lembap Hutan", "Damp Forest Ground"),
  "forage_sungai_1": ("Tepi Barat Sungai", "West Riverbank"),
  "forage_sungai_2": ("Tepi Seberang", "Far Bank"),
  "forage_sungai_3": ("Batu Sungai Utara", "Northern River Rocks"),
  "forage_pegunungan_1": ("Lereng Barat", "Western Slope"),
  "forage_pegunungan_2": ("Punggung Bukit", "Ridge Top"),
  "forage_pegunungan_3": ("Lereng Timur", "Eastern Slope"),
}

MISSIONS = {
  "m_hutan": ("Kumpulkan bahan dari hutan", "Gather herbs from the forest",
              "Kumpulkan 4 bahan dari titik-titik di Hutan.", "Gather 4 herbs from spots in the Forest."),
  "m_kenali": ("Kenali tanaman baru", "Identify new plants",
               "Identifikasi 3 tanaman liar yang belum kamu kenal.", "Identify 3 wild plants you have not learned yet."),
  "m_jelajah": ("Jelajahi tepi lain", "Explore beyond",
                "Kunjungi Sungai dan Pegunungan.", "Visit the River and the Mountains."),
  "m_celah": ("Celah batu rahasia", "The hidden cleft",
              "Baca tanda di celah batu di Pegunungan. Butuh Identifikasi tingkat 2, atau 3 tanaman dikenal.",
              "Read the sign at the rock cleft in the Mountains. Needs Identification level 2, or 3 known plants."),
}

LORE = {
  "kunyit": ("tepi sungai yang lembap", "damp riverbanks", "bahan ramuan penghangat", "warming remedy ingredient"),
  "jahe": ("kebun desa", "village gardens", "bahan tumbukan perut", "belly pound ingredient"),
  "temulawak": ("lereng pegunungan", "mountain slopes", "bahan seduhan penyejuk", "cooling brew ingredient"),
  "kencur": ("tepi hutan yang teduh", "shady forest edges", "bahan tumbukan perut", "belly pound ingredient"),
  "serai": ("rumpun dekat sumur", "clumps near wells", "bahan air tenang kepala", "calm-head water ingredient"),
  "lengkuas": ("tepi sungai", "riverbanks", "bahan lulur pelentur sendi", "joint scrub ingredient"),
  "sambiloto": ("tanah kering berbatu", "dry rocky ground", "bahan bilasan mata", "eye-rinse ingredient"),
  "kumis_kucing": ("semak hutan", "forest scrub", "bahan jamu pelega napas", "breath tonic ingredient"),
  "sirih": ("tepi kolam dan sumur", "pond and well edges", "bahan jamu pelega napas", "breath tonic ingredient"),
  "kayu_manis": ("lereng hutan tinggi", "high forest slopes", "bahan tumbukan wangi", "fragrant pound ingredient"),
}

UI = {
  "ui.stamina": ("Stamina: {n}", "Stamina: {n}"),
  "area.hutan.name": ("Hutan", "Forest"),
  "area.sungai.name": ("Sungai", "River"),
  "area.pegunungan.name": ("Pegunungan", "Mountains"),
  "adv.forage_prompt": ("Cari tanaman liar", "Search for wild plants"),
  "adv.board_prompt": ("Papan Pengembara", "Wanderer's board"),
  "adv.secret_prompt": ("Baca tanda di celah", "Read the sign at the cleft"),
  "adv.forage_got": ("Kamu menemukan {name} ×{n}.", "You found {name} ×{n}."),
  "adv.node_resting": ("Tanaman ini belum tumbuh kembali. Coba beberapa jam lagi.", "This plant has not regrown yet. Try again in a few hours."),
  "adv.too_tired": ("Stamina kurang. Waktu berjalan akan memulihkannya.", "Not enough stamina. Time will restore it."),
  "adv.first_visit": ("Area baru ditemukan: {name} (+koin)", "New area found: {name} (+coins)"),
  "adv.secret_title": ("Celah Batu", "Rock Cleft"),
  "adv.secret_found": ("Di balik celah ada {name} ×{n} dan {coin} koin tersembunyi.", "Behind the cleft: {name} ×{n} and {coin} hidden coins."),
  "adv.secret_done": ("Celah ini sudah dikosongkan.", "This cleft has already been emptied."),
  "adv.secret_locked": ("Tandanya terlalu samar. Kenali lebih banyak tanaman (Identifikasi tingkat 2, atau 3 tanaman dikenal).",
                        "The sign is too faint. Identify more plants (Identification level 2, or 3 known plants)."),
  "board.title": ("Papan Pengembara", "Wanderer's Board"),
  "board.progress": ("Kemajuan: {done}/{total}", "Progress: {done}/{total}"),
  "board.claimed": ("Misi selesai! Hadiah +{coin} koin.", "Mission complete! Reward +{coin} coins."),
  "board.all_done": ("Semua misi sudah selesai. Terima kasih, tabib muda.", "All missions are done. Thank you, young healer."),
  "plant.lore": ("Habitat (fiktif): {habitat}. Kegunaan (fiktif): {use}.", "Habitat (fictional): {habitat}. Use (fictional): {use}."),
  "ledger.jelajah": ("Penemuan {item}", "Discovered {item}"),
  "ledger.misi": ("Misi: {item}", "Mission: {item}"),
  "ledger.celah": ("Celah batu rahasia", "Hidden rock cleft"),
}


def register(add):
    for k, (i, e) in UI.items():
        add(k, i, e)
    for aid, (i, e) in AREAS.items():
        add(f"area.{aid}.name", i, e)
    for fid, (i, e) in FORAGE.items():
        add(f"forage.{fid}", i, e)
    for mid, (ti, te, di, de) in MISSIONS.items():
        add(f"mission.{mid}.title", ti, te)
        add(f"mission.{mid}.desc", di, de)
    for hid, (hi, he, ui_, ue) in LORE.items():
        add(f"lore.{hid}.habitat", hi, he)
        add(f"lore.{hid}.use", ui_, ue)
