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
