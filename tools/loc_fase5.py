"""Teks Fase 5 (medis, minigame). Dipanggil dari gen_localization.py: register(add)."""

AILMENTS = {
  "demam_embun": ("Demam Embun", "Dew Fever", "Menggigil di pagi hari; dahi terasa hangat dan nadi berdenyut cepat.", "Shivering at dawn; a warm forehead and a quick pulse."),
  "angin_gelombang": ("Angin Gelombang", "Wave Wind", "Pusing seperti terombang-ambing; tubuh dingin dan nadi lambat.", "Dizziness like drifting on waves; a cool body and a slow pulse."),
  "kepala_kabut": ("Kepala Kabut", "Misty Head", "Kepala terasa berkabut; mata sayu dan nadi lemah.", "A foggy head with droopy eyes and a weak pulse."),
  "perut_kabut": ("Perut Kabut", "Misty Belly", "Perut kembung dan lemas; lidah putih dan nadi lemah.", "A bloated, sluggish belly with a white tongue and a weak pulse."),
  "lambung_panas": ("Lambung Panas", "Hot Stomach", "Perut nyeri dan panas; lidah kuning, nadi kuat.", "A tender, hot belly with a yellow tongue and a strong pulse."),
  "batuk_debu": ("Batuk Debu", "Dust Cough", "Batuk kering seperti tertiup debu; mata merah, nadi lambat.", "A dry cough as if choked by dust; red eyes and a slow pulse."),
  "tenggorok_kering": ("Tenggorok Kering", "Dry Throat", "Tenggorokan kering dan gatal; lidah merah, nadi kuat.", "A dry, itchy throat with a red tongue and a strong pulse."),
  "sendi_karat": ("Sendi Karat", "Rusty Joints", "Sendi kaku seperti berkarat; tubuh dingin, nadi lambat.", "Stiff joints as if rusted; a cool body and a slow pulse."),
  "otot_tegang": ("Otot Tegang", "Tense Muscles", "Otot menegang dan panas; lidah merah, nadi kuat.", "Tight, warm muscles with a red tongue and a strong pulse."),
  "kulit_getah": ("Kulit Getah", "Sap Skin", "Ruam gatal seperti terkena getah; lidah kuning, nadi cepat.", "An itchy rash as if touched by sap; yellow tongue, quick pulse."),
  "kulit_lembap": ("Kulit Lembap", "Damp Skin", "Ruam lembap dan perut kembung; dahi berkeringat, nadi bergelombang.", "A damp rash and bloating; a sweaty forehead and a wavy pulse."),
  "mata_pasir": ("Mata Pasir", "Sandy Eyes", "Mata perih seperti kemasukan pasir; lidah merah, nadi bergelombang.", "Stinging eyes as if full of sand; red tongue, wavy pulse."),
}

AREAS = {"dahi": ("Dahi", "Forehead"), "mata": ("Mata", "Eyes"), "lidah": ("Lidah", "Tongue"),
         "kulit": ("Kulit", "Skin"), "perut": ("Perut", "Belly"), "nadi": ("Nadi", "Pulse")}

FINDINGS = {
  "dahi": {"hangat": ("hangat", "warm"), "dingin": ("dingin", "cool"), "berkeringat": ("berkeringat", "sweaty"), "normal": ("biasa", "ordinary")},
  "mata": {"merah": ("merah", "red"), "kuning": ("kekuningan", "yellowish"), "berair": ("berair", "watery"), "sayu": ("sayu", "droopy")},
  "lidah": {"putih": ("berlapis putih", "white-coated"), "kuning": ("kekuningan", "yellowish"), "merah": ("merah", "red"), "pucat": ("pucat", "pale")},
  "kulit": {"kering": ("kering", "dry"), "lembap": ("lembap", "damp"), "panas": ("hangat membara", "burning warm"), "ruam": ("berruam", "rashy")},
  "perut": {"kembung": ("kembung", "bloated"), "nyeri": ("nyeri ditekan", "tender"), "lunak": ("lunak", "soft"), "normal": ("biasa", "ordinary")},
  "nadi": {"cepat": ("cepat", "quick"), "lambat": ("lambat", "slow"), "kuat": ("kuat", "strong"), "lemah": ("lemah", "weak"), "bergelombang": ("bergelombang", "wavy")},
}

POINTS = {
  "ubun_embun": ("Ubun Embun", "Dew Crown"), "alis_pagi": ("Alis Pagi", "Morning Brow"),
  "pelipis_angin": ("Pelipis Angin", "Wind Temple"), "leher_kendi": ("Leher Kendi", "Pitcher Neck"),
  "bahu_batu": ("Bahu Batu", "Stone Shoulder"), "dada_telaga": ("Dada Telaga", "Lake Chest"),
  "pusar_bulan": ("Pusar Bulan", "Moon Navel"), "pergelangan_nadi": ("Pergelangan Nadi", "Pulse Wrist"),
  "lutut_batu": ("Lutut Batu", "Stone Knee"), "telapak_akar": ("Telapak Akar", "Root Sole"),
}
TAGS = {"tenang": ("penenang", "Calming"), "segar": ("penyegar", "Refreshing"), "sejuk": ("penyejuk", "Cooling"),
        "lancar": ("pelancar", "Easing"), "longgar": ("pelonggar", "Loosening"), "lapang": ("pelapang", "Opening"),
        "hangat": ("penghangat", "Warming"), "selaras": ("penyelaras", "Balancing"), "kuat": ("penguat", "Strengthening"),
        "menurun": ("penurun", "Grounding")}
REGIONS = {"kepala": ("Kepala", "Head"), "leher": ("Leher", "Neck"), "bahu": ("Bahu", "Shoulder"), "dada": ("Dada", "Chest"),
           "perut": ("Perut", "Belly"), "lengan": ("Lengan", "Arm"), "tungkai": ("Tungkai", "Leg")}

HERBS = {"kunyit": ("Kunyit", "Turmeric"), "jahe": ("Jahe", "Ginger"), "temulawak": ("Temulawak", "Javanese turmeric"),
         "kencur": ("Kencur", "Aromatic ginger"), "serai": ("Serai", "Lemongrass"), "lengkuas": ("Lengkuas", "Galangal"),
         "sambiloto": ("Sambiloto", "Andrographis"), "kumis_kucing": ("Kumis Kucing", "Cat's whiskers"),
         "sirih": ("Daun Sirih", "Betel leaf"), "kayu_manis": ("Kayu Manis", "Cinnamon")}
PARTS = {"daun": ("Daun", "Leaf"), "bunga": ("Bunga", "Flower"), "akar": ("Akar", "Root"), "buah": ("Buah", "Fruit")}
TRAITS = {
  "daun": {
    "lebar_lanset": ("Daun lebar berbentuk lanset, ujung runcing.", "Broad lance-shaped leaf with a pointed tip."),
    "lanset_sempit": ("Daun sempit memanjang, tersusun dua baris.", "Narrow elongated leaves arranged in two rows."),
    "pita_panjang": ("Daun panjang seperti pita, tepi tajam, tumbuh berumpun.", "Long ribbon-like leaves with sharp edges, growing in clumps."),
    "membulat_pendek": ("Daun membulat lebar, biasanya dua helai dekat tanah.", "Wide rounded leaves, usually two close to the ground."),
    "hati_mengkilap": ("Daun berbentuk hati, mengkilap, tanaman merambat.", "Glossy heart-shaped leaves on a climbing vine."),
    "bergerigi": ("Daun bertepi bergerigi dengan tangkai pendek.", "Serrated leaves on short stalks."),
    "lanset_kecil": ("Daun kecil berpasangan, rasanya pahit.", "Small paired leaves with a bitter taste."),
    "tiga_tulang": ("Daun kaku dengan tiga tulang daun memanjang.", "Stiff leaf with three lengthwise veins."),
  },
  "bunga": {
    "putih_kuning": ("Bunga putih dengan bibir kuning.", "White flower with a yellow lip."),
    "merah_kerucut": ("Bunga merah menyala dalam tandan kerucut.", "Bright red flowers in a cone-shaped spike."),
    "ungu_kerucut": ("Bunga ungu muda dalam tandan kerucut.", "Pale purple flowers in a cone-shaped spike."),
    "putih_ungu_kecil": ("Bunga kecil putih dengan bercak ungu.", "Small white flowers with purple marks."),
    "kumis_panjang": ("Bunga putih dengan benang sari panjang seperti kumis.", "White flower with long whisker-like stamens."),
    "tak_mencolok": ("Bunga tidak mencolok, jarang terlihat.", "Inconspicuous flowers, rarely seen."),
    "bulir_hijau": ("Bunga berupa bulir kecil kehijauan.", "Tiny greenish flower spikes."),
    "kuning_pucat": ("Bunga kecil kuning pucat dalam malai.", "Tiny pale-yellow flowers in clusters."),
  },
  "akar": {
    "rimpang_jingga": ("Rimpang berdaging jingga terang.", "Bright orange fleshy rhizome."),
    "rimpang_krem": ("Rimpang krem bercabang, beraroma tajam.", "Branching cream rhizome with a sharp aroma."),
    "rimpang_kuning_besar": ("Rimpang besar berwarna kuning tua.", "Large deep-yellow rhizome."),
    "rimpang_kecil": ("Rimpang kecil cokelat muda yang harum.", "Small, light-brown fragrant rhizome."),
    "serabut_rumpun": ("Akar serabut berumpun, pangkal batang putih.", "Fibrous roots in a clump, white stem base."),
    "rimpang_merah": ("Rimpang besar kemerahan dengan cincin jelas.", "Large reddish rhizome with clear rings."),
    "serabut_halus": ("Akar serabut halus.", "Fine fibrous roots."),
    "kulit_batang": ("Kulit batang cokelat yang menggulung.", "Brown bark that curls into quills."),
  },
  "buah": {
    "polong_kecil": ("Buah polong kecil memanjang.", "Small elongated pods."),
    "bulat_kecil": ("Buah bulat kecil.", "Small round fruit."),
    "tak_tampak": ("Buah tidak terlihat.", "No fruit visible."),
    "buni_merah": ("Buah buni kecil kemerahan.", "Small reddish berries."),
  },
}

RECIPES = {
  "ramuan_penghangat": ("Ramuan Penghangat", "Warming Brew", "Kunyit, jahe, dan serai ditumbuk lalu diaduk.", "Turmeric, ginger and lemongrass, pounded then stirred."),
  "seduhan_penyejuk": ("Seduhan Penyejuk", "Cooling Infusion", "Temulawak, sambiloto, dan kumis kucing.", "Javanese turmeric, andrographis and cat's whiskers."),
  "tumbukan_perut_lega": ("Tumbukan Perut Lega", "Belly-Ease Paste", "Kencur, jahe, dan kayu manis ditumbuk halus.", "Aromatic ginger, ginger and cinnamon, pounded fine."),
  "jamu_pelega_napas": ("Jamu Pelega Napas", "Breath-Ease Tonic", "Daun sirih, kencur, dan kayu manis.", "Betel leaf, aromatic ginger and cinnamon."),
  "lulur_pelentur_sendi": ("Lulur Pelentur Sendi", "Joint-Loosening Rub", "Lengkuas, kunyit, dan serai.", "Galangal, turmeric and lemongrass."),
  "air_tenang_kepala": ("Air Tenang Kepala", "Calm-Head Water", "Serai, daun sirih, kumis kucing, dan temulawak.", "Lemongrass, betel leaf, cat's whiskers and Javanese turmeric."),
  "bilasan_mata_segar": ("Bilasan Mata Segar", "Fresh Eye Rinse", "Daun sirih, sambiloto, dan kencur.", "Betel leaf, andrographis and aromatic ginger."),
}

SKILLS = {"diagnosis": ("Diagnosis", "Diagnosis"), "akupunktur": ("Akupunktur", "Acupuncture"),
          "pengetahuan_herbal": ("Pengetahuan Herbal", "Herbal Knowledge"), "peracikan": ("Peracikan", "Compounding"),
          "identifikasi_tanaman": ("Identifikasi Tanaman", "Plant Identification")}
GRADES = {"s": ("Sempurna", "Perfect"), "a": ("Sangat Bagus", "Excellent"), "b": ("Bagus", "Good"), "c": ("Cukup", "Fair"), "d": ("Gagal", "Failed")}
STAGES = {"diagnosis": ("Diagnosis", "Diagnosis"), "metode": ("Pilih metode", "Choose method"), "akupunktur": ("Akupunktur", "Acupuncture"),
          "ramuan": ("Racik ramuan", "Brew remedy"), "hasil": ("Hasil", "Results"), "selesai": ("Selesai", "Done")}
OUTCOMES = {"sembuh": ("Sembuh", "Cured"), "membaik": ("Membaik", "Improving"), "gagal": ("Belum membaik", "Not improved")}
PROMPTS = {
  "garden_plot_1": ("Amati tanaman di petak 1", "Examine the plant in plot 1"),
  "garden_plot_2": ("Amati tanaman di petak 2", "Examine the plant in plot 2"),
  "garden_plot_3": ("Amati tanaman di petak 3", "Examine the plant in plot 3"),
  "garden_plot_4": ("Amati tanaman di petak 4", "Examine the plant in plot 4"),
  "wild_plant_kolam": ("Amati tanaman liar di tepi kolam", "Examine the wild plant by the pond"),
  "wild_plant_sumur": ("Amati tanaman liar dekat sumur", "Examine the wild plant near the well"),
  "wild_plant_barat": ("Amati tanaman liar di jalan barat", "Examine the wild plant on the west road"),
}


def register(add):
    for k, (ni, ne, di, de) in AILMENTS.items():
        add(f"ailment.{k}.name", ni, ne)
        add(f"ailment.{k}.desc", di, de)
    for k, (i, e) in AREAS.items():
        add(f"area.{k}", i, e)
    for area, vals in FINDINGS.items():
        for k, (i, e) in vals.items():
            add(f"finding.{area}.{k}", i, e)
    for k, (i, e) in POINTS.items():
        add(f"point.{k}", i, e)
    for k, (i, e) in TAGS.items():
        add(f"tag.{k}", i, e)
    for k, (i, e) in REGIONS.items():
        add(f"region.{k}", i, e)
    for k, (i, e) in HERBS.items():
        add(f"herb.{k}", i, e)
    for k, (i, e) in PARTS.items():
        add(f"part.{k}", i, e)
    for part, vals in TRAITS.items():
        for k, (i, e) in vals.items():
            add(f"trait.{part}.{k}", i, e)
    for k, (ni, ne, di, de) in RECIPES.items():
        add(f"recipe.{k}.name", ni, ne)
        add(f"recipe.{k}.desc", di, de)
    for k, (i, e) in SKILLS.items():
        add(f"skill.{k}", i, e)
    for k, (i, e) in GRADES.items():
        add(f"grade.{k}", i, e)
    for k, (i, e) in STAGES.items():
        add(f"stage.{k}", i, e)
    for k, (i, e) in OUTCOMES.items():
        add(f"outcome.{k}", i, e)
    for k, (i, e) in PROMPTS.items():
        add(f"prompt.{k}", i, e)
    register_ui(add)


UI = {
    # umum
    "ui.postpone": ("Tunda", "Later"),
    "ui.cancel": ("Batal", "Cancel"),
    "ui.confirm": ("Konfirmasi", "Confirm"),
    "ui.close": ("Tutup", "Close"),
    "ui.book": ("Buku", "Book"),
    "ui.money": ("Koin: {money}   Reputasi: {rep}", "Coins: {money}   Reputation: {rep}"),
    "ui.new_day": ("Hari {day} dimulai. Bahan klinik diisi ulang.", "Day {day} begins. Clinic herbs restocked."),
    "minigame.title.diagnosis": ("Diagnosis", "Diagnosis"),
    "minigame.title.akupunktur": ("Akupunktur", "Acupuncture"),
    "minigame.title.peracikan": ("Peracikan Ramuan", "Herbal Compounding"),
    "minigame.title.identifikasi": ("Identifikasi Tanaman", "Plant Identification"),
    "minigame.score": ("Skor {score}", "Score {score}"),
    "minigame.level_up": ("{skill} naik ke tingkat {level}!", "{skill} reached level {level}!"),
    # komponen penilaian
    "comp.ketepatan": ("Ketepatan", "Accuracy"),
    "comp.relevansi": ("Relevansi", "Relevance"),
    "comp.kelengkapan": ("Kelengkapan", "Completeness"),
    "comp.waktu": ("Waktu", "Time"),
    "comp.urutan": ("Urutan", "Order"),
    "comp.kesalahan": ("Bebas salah", "Few mistakes"),
    "comp.komposisi": ("Komposisi", "Composition"),
    "comp.takaran": ("Takaran", "Measuring"),
    "comp.tumbuk": ("Menumbuk", "Pounding"),
    "comp.aduk": ("Mengaduk", "Stirring"),
    "comp.pengamatan": ("Pengamatan", "Observation"),
    "rhythm.perfect": ("Pas!", "Perfect!"),
    "rhythm.good": ("Bagus", "Good"),
    "rhythm.miss": ("Meleset", "Miss"),
    # diagnosis
    "diag.complaint": ("Keluhan", "Complaint"),
    "diag.energy": ("Tenaga periksa", "Exam energy"),
    "diag.notes": ("Catatan temuan", "Findings"),
    "diag.observe": ("Amati gejala", "Observe"),
    "diag.to_verdict": ("Tetapkan diagnosis", "Decide"),
    "diag.back": ("Kembali periksa", "Back to exam"),
    "diag.confirm": ("Pilih ini", "Choose"),
    "diag.pulse_tap": ("KETUK", "TAP"),
    "diag.pulse_help": ("Rasakan denyut: ketuk mengikuti iramanya, lalu lanjutkan sendiri saat tanda menghilang.", "Feel the pulse: tap along with its rhythm, then keep it going when the cues vanish."),
    "diag.pulse_keep": ("Pertahankan irama…", "Keep the rhythm…"),
    "diag.pulse_count": ("Denyut {n}/{total}", "Beat {n}/{total}"),
    "diag.pulse_unclear": ("Denyut kurang jelas. Coba lagi bila tenaga cukup.", "The pulse was unclear. Try again if you have energy."),
    "diag.found": ("{area}: {value}", "{area}: {value}"),
    "diag.observed": ("Terlihat — {area}: {value}", "Noticed — {area}: {value}"),
    "diag.already": ("{area} sudah diperiksa.", "{area} already examined."),
    "diag.no_energy": ("Tenaga periksa habis. Tetapkan diagnosis.", "No exam energy left. Make your diagnosis."),
    "diag.verdict_help": ("Cocokkan temuanmu dengan tiap kemungkinan. Hijau = cocok, merah = bertentangan.", "Compare your findings with each possibility. Green = matches, red = contradicts."),
    "diag.ruled_out": ("Disingkirkan", "Ruled out"),
    "diag.wrong_try": ("{name} kurang tepat. Pikirkan lagi temuanmu.", "{name} doesn't fit. Reconsider your findings."),
    "diag.verdict_ok": ("Diagnosismu tepat: {name}", "Your diagnosis was right: {name}"),
    "diag.verdict_wrong": ("Diagnosismu kurang tepat: {name}", "Your diagnosis was off: {name}"),
    # akupunktur
    "acu.select_help": ("Pilih titik yang sesuai dengan diagnosis. Urutan pemilihan adalah urutan penusukan.", "Choose the points that fit the diagnosis. Selection order is insertion order."),
    "acu.need_title": ("Petunjuk", "Hints"),
    "acu.chosen": ("Dipilih {n}/{max}", "Chosen {n}/{max}"),
    "acu.undo": ("Batalkan", "Undo"),
    "acu.start": ("Mulai menusuk", "Start needling"),
    "acu.aim_help": ("Geser di panel bidik untuk mengarahkan jarum, tahan tombol JARUM untuk menekan, lepas saat kedalaman pas.", "Drag on the aim pad to steer the needle, hold NEEDLE to press, release at the right depth."),
    "acu.needle": ("JARUM", "NEEDLE"),
    "acu.depth": ("Kedalaman", "Depth"),
    "acu.finish": ("Selesaikan sesi", "Finish session"),
    "acu.flash_perfect": ("Sempurna!", "Perfect!"),
    "acu.flash_good": ("Bagus", "Good"),
    "acu.flash_close": ("Agak meleset", "A bit off"),
    "acu.flash_miss": ("Meleset", "Missed"),
    "acu.flash_wrong": ("Titik kurang cocok", "Not the right point"),
    # peracikan
    "craft.recipe": ("Resep", "Recipe"),
    "craft.stage_pick": ("Pilih", "Pick"),
    "craft.stage_measure": ("Takar", "Measure"),
    "craft.stage_pound": ("Tumbuk", "Pound"),
    "craft.stage_stir": ("Aduk", "Stir"),
    "craft.picked": ("diambil {n}/{need}", "taken {n}/{need}"),
    "craft.shortage": ("Bahan kurang!", "Missing herbs!"),
    "craft.bowl": ("Mangkuk", "Bowl"),
    "craft.undo": ("Kembalikan", "Put back"),
    "craft.to_measure": ("Lanjut menakar", "Go measure"),
    "craft.pick_help": ("Ketuk bahan di rak untuk mengambilnya sesuai urutan resep.", "Tap herbs on the shelf to take them in recipe order."),
    "craft.too_many": ("Terlalu banyak {herb}!", "Too much {herb}!"),
    "craft.out_of_stock": ("{herb} habis.", "Out of {herb}."),
    "craft.measure_title": ("Takar {herb}: {grams} g  ({n}/{total})", "Measure {herb}: {grams} g  ({n}/{total})"),
    "craft.measure_help": ("Tahan TUANG untuk mengisi, lepas tepat di garis emas.", "Hold POUR to fill, release right at the gold line."),
    "craft.pour": ("TUANG (tahan)", "POUR (hold)"),
    "craft.measure_good": ("Takaran pas: {grams} g", "Spot on: {grams} g"),
    "craft.measure_ok": ("Cukup dekat: {grams} g", "Close enough: {grams} g"),
    "craft.measure_bad": ("Takaran meleset: {grams} g", "Off target: {grams} g"),
    "craft.pound_help": ("Ketuk saat cincin menyusut menyentuh lingkaran emas, ikuti irama.", "Tap when the shrinking ring meets the gold circle. Follow the rhythm."),
    "craft.pound_tap": ("TUMBUK", "POUND"),
    "craft.pound_count": ("Ketukan {n}/{total}", "Beat {n}/{total}"),
    "craft.stir_help": ("Putar jarimu mengelilingi mangkuk dengan kecepatan stabil dalam pita hijau.", "Circle your finger around the bowl at a steady speed inside the green band."),
    "craft.speed": ("Kecepatan", "Speed"),
    # identifikasi tanaman
    "plant.help": ("Sentuh bagian tanaman untuk diamati, lalu pilih identitasnya.", "Tap a plant part to observe it, then choose its identity."),
    "plant.pick_part": ("Pilih bagian yang ingin diamati.", "Pick a part to observe."),
    "plant.hidden": ("{part} tertutup, tidak bisa diamati.", "The {part} is hidden and can't be observed."),
    "plant.observed": ("Diamati {n}/{total} bagian", "Observed {n}/{total} parts"),
    "plant.tries": ("Sisa tebakan: {n}", "Guesses left: {n}"),
    "plant.enough": ("Bukti sudah cukup untuk membedakan.", "Enough evidence to tell them apart."),
    "plant.wrong_try": ("Bukan itu. Amati lagi.", "Not that one. Observe again."),
    "plant.result_ok": ("Itu {name}!", "It is {name}!"),
    "plant.result_fail": ("Gagal mengenali; ternyata {name}.", "Failed to identify; it was {name}."),
    "plant.learned": ("Pengetahuan baru: {name} tercatat di Buku.", "New knowledge: {name} recorded in the Book."),
    "plant.harvest": ("Panen {n} {name}.", "Harvested {n} {name}."),
    "plant.done_today": ("Sudah diamati hari ini. Kembali besok.", "Already observed today. Come back tomorrow."),
    "plant.disabled": ("[Placeholder] Identifikasi tanaman dimatikan.", "[Placeholder] Plant identification is disabled."),
    "spot.garden_plot_1": ("Petak Kebun 1", "Garden Plot 1"),
    "spot.garden_plot_2": ("Petak Kebun 2", "Garden Plot 2"),
    "spot.garden_plot_3": ("Petak Kebun 3", "Garden Plot 3"),
    "spot.garden_plot_4": ("Petak Kebun 4", "Garden Plot 4"),
    "spot.wild_plant_kolam": ("Tepi Kolam", "Pond Edge"),
    "spot.wild_plant_sumur": ("Dekat Sumur", "Near the Well"),
    "spot.wild_plant_barat": ("Semak Barat", "West Thicket"),
    # metode & resep
    "method.title": ("Pilih Metode Pengobatan", "Choose Treatment"),
    "method.help": ("Pilih satu atau dua metode untuk {name}.", "Choose one or two methods for {name}."),
    "method.akupunktur": ("Akupunktur", "Acupuncture"),
    "method.akupunktur.desc": ("Tusuk titik yang tepat dengan jarum. Butuh bidikan teliti.", "Needle the right points. Needs a careful aim."),
    "method.herbal": ("Ramuan Herbal", "Herbal Remedy"),
    "method.herbal.desc": ("Racik ramuan dari bahan klinik: takar, tumbuk, aduk.", "Compound a remedy from clinic herbs: measure, pound, stir."),
    "recipe.choose_title": ("Pilih Resep", "Choose Recipe"),
    "recipe.choose_help": ("Ramuan apa yang cocok untuk {name}?", "Which remedy suits {name}?"),
    # ringkasan
    "summary.title": ("Ringkasan Kunjungan", "Visit Summary"),
    "summary.patient": ("Pasien: {name}", "Patient: {name}"),
    "summary.ailment": ("Keluhan sebenarnya: {name}", "Actual ailment: {name}"),
    "summary.diagnosed": ("Diagnosismu: {name} ({ok})", "Your diagnosis: {name} ({ok})"),
    "summary.right": ("tepat", "right"),
    "summary.wrong": ("kurang tepat", "off"),
    "summary.outcome": ("Hasil: {outcome}", "Result: {outcome}"),
    "summary.quality": ("Kualitas pengobatan {q}%  ·  Kepuasan {sat}%", "Treatment quality {q}%  ·  Satisfaction {sat}%"),
    "summary.pay": ("Bayaran +{fee} koin   Reputasi {rep}", "Fee +{fee} coins   Reputation {rep}"),
    "summary.totals": ("Total koin {money}  ·  Reputasi {rep}", "Total coins {money}  ·  Reputation {rep}"),
    "summary.done": ("Pasien pulang", "Patient leaves"),
    # buku tabib
    "book.title": ("Buku Tabib", "Healer's Book"),
    "book.clinic": ("Koin {money}  ·  Reputasi {rep}  ·  Pasien {treated}  ·  Sembuh {cured}", "Coins {money}  ·  Reputation {rep}  ·  Patients {treated}  ·  Cured {cured}"),
    "book.level": ("Tingkat", "Level"),
    "book.max": ("maks", "max"),
    "book.herbs": ("Bahan: {list}", "Herbs: {list}"),
    "book.plants": ("Tanaman dikenal {n}/{total}: {list}", "Plants known {n}/{total}: {list}"),
}


def register_ui(add):
    for k, (i, e) in UI.items():
        add(k, i, e)
