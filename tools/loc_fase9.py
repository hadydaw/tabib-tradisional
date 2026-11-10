"""Teks Fase 9 (wilayah baru Rawa dan Gua Kapur, penemuan langka, teka-teki, peti, quest eksplorasi).
Dipanggil dari gen_localization.py: register(add). Semua tokoh dan tempat fiktif.
Bahan langka tidak punya efek pengobatan nyata: hanya koleksi, quest, dan kunci akses."""

RARE = {
  "akar_rawa": (("Akar Rawa", "Marsh Root"),
                ("Tumbuh di tepi air keruh. Akarnya berbau tanah basah.", "Grows at the edge of murky water. Its root smells of wet earth.")),
  "benih_kemuning": (("Benih Kemuning", "Kemuning Seed"),
                     ("Benih pohon kemuning yang jatuh dari ranting di rawa.", "Seed of a kemuning tree that drops from the marsh branches.")),
  "benih_cendana": (("Benih Cendana", "Sandalwood Seed"),
                    ("Benih keras berwarna cokelat. Hanya tumbuh di tanah rawa dalam.", "A hard brown seed. Only grows in the deep marsh soil.")),
  "jamur_gua": (("Jamur Gua", "Cave Mushroom"),
                ("Jamur pucat yang tumbuh di lembap gua kapur.", "A pale mushroom that grows in the damp of the limestone cave.")),
  "batu_kompas": (("Batu Kompas", "Compass Stone"),
                  ("Batu hitam yang selalu menunjuk satu arah. Sebabnya belum diketahui.", "A black stone that always points one way. Its reason is unknown.")),
  "kristal_tetes": (("Kristal Tetes", "Drop Crystal"),
                    ("Kristal kecil bening, terbentuk dari tetesan air di rawa dalam dan gua.", "A small clear crystal formed from dripping water in the deep marsh and cave.")),
}

NODE_PROMPT = ("Periksa rumpun", "Examine patch")

PUZZLES = {
  "penjaga_rawa": (("Penjaga Rawa", "Marsh Guardian"),
                   ("Batu bertulis tiga simbol di depan kabut. Susun urutan yang benar: ketuk simbol satu per satu.",
                    "A stone with three symbols in front of the mist. Arrange them in the right order by tapping one at a time.")),
  "tablet_gua": (("Tablet Batu", "Stone Tablet"),
                 ("Tablet kuno dengan empat simbol. Urutannya dibaca dari tanah ke air.",
                  "An old tablet with four symbols. Read the order from earth to water.")),
  "tuas_gua": (("Tuas Batu", "Stone Lever"),
               ("Tuas di aula gua. Dua tarikan dengan simbol yang tepat akan membuka celah.",
                "A lever in the cave hall. Two pulls with the right symbols will open the crack.")),
}

SYMBOLS = {"api": ("Api", "Fire"), "air": ("Air", "Water"), "angin": ("Angin", "Wind"), "tanah": ("Tanah", "Earth")}

QUESTS = {
  "q_lastri_rawa": {
    "title": ("Bekal dari Rawa", "Supplies from the Marsh"),
    "offer": ("Tabib, kabarnya rawa di barat menyimpan bahan yang jarang ada. Tolong cari 3 penemuan di sana untukku.",
              "Healer, I hear the marsh to the west holds rare finds. Please gather 3 discoveries there for me."),
    "accepted": ("Terima kasih. Catat setiap yang kamu temukan, ya.", "Thank you. Record every find, please."),
    "wait": ("Belum cukup penemuan dari rawa. Sabar.", "Not enough finds from the marsh yet. Be patient."),
    "turn": ("Sudah dapat? Bagaimana bekal ini akan dibagi?", "Got them? How shall we share these finds?"),
    "done": ("Terima kasih, Tabib. Rawa itu kini milik kita bersama.", "Thank you, Healer. The marsh is now shared by us all."),
    "opt": {
      "bagi_hasil": ("Bagi rata dengan desa.", "Share them evenly with the village."),
      "simpan_sendiri": ("Simpan sebagian untuk diri sendiri.", "Keep some for yourself."),
    },
  },
  "q_joko_gua": {
    "title": ("Gua yang Tertutup", "The Sealed Cave"),
    "offer": ("Ada gua kapur di pegunungan. Pintunya tertutup batu. Kalau kamu bisa membukanya dan membawa isinya, kabari aku.",
              "There's a limestone cave in the mountains, sealed with stone. If you can open it and bring back what's inside, tell me."),
    "accepted": ("Hm. Jangan sampai terjebak di dalam.", "Hm. Don't get trapped inside."),
    "wait": ("Gua itu belum kamu selesaikan.", "You haven't finished the cave yet."),
    "turn": ("Kamu sudah masuk? Apa isinya?", "You went inside? What was there?"),
    "done": ("...Baik. Itu cukup.", "...Good. That's enough."),
    "opt": {
      "jujur": ("Laporkan apa adanya.", "Report exactly what you found."),
      "minta_bagian": ("Minta bagian dari isi peti.", "Ask for a share of the chest's contents."),
    },
  },
}

PUZZLE_EXTRA = {
  "fog_lifted": ("Kabut menipis. Rawa dalam kini terbuka.", "The mist thins. The deep marsh is now open."),
  "door_open": ("Pintu batu ke ruang dalam terbuka.", "The stone door to the inner chamber opens."),
  "crack_open": ("Celah ke ceruk di utara aula terbuka.", "The crack to the alcove north of the hall opens."),
}


def register(add):
    for rid, ((name_id, name_en), (hab_id, hab_en)) in RARE.items():
        add("rare.%s.name" % rid, name_id, name_en)
        add("rare.%s.habitat" % rid, hab_id, hab_en)

    for pid, ((title_id, title_en), (hint_id, hint_en)) in PUZZLES.items():
        add("fr.puzzle.%s.title" % pid, title_id, title_en)
        add("fr.puzzle.%s.hint" % pid, hint_id, hint_en)

    for sid, (id_, en) in SYMBOLS.items():
        add("fr.sym.%s" % sid, id_, en)

    add("fr.node_title", "Penemuan Langka", "Rare Discovery")
    add("fr.rare_got", "Kamu menemukan {name}.", "You found {name}.")
    add("fr.rare_first", "Penemuan pertama! Dicatat di Buku Tabib. +{coin} koin.",
        "First discovery! Recorded in the Healer's Book. +{coin} coins.")
    add("fr.node_prompt", NODE_PROMPT[0], NODE_PROMPT[1])
    add("fr.node_resting", "Rumpun ini belum tumbuh lagi. Kembali nanti.", "This patch hasn't regrown yet. Come back later.")
    add("fr.puzzle_prompt", "Periksa teka-teki", "Examine puzzle")
    add("fr.puzzle_undo", "Hapus", "Undo")
    add("fr.puzzle_wrong", "Urutan belum tepat. Coba lagi.", "Not the right order. Try again.")
    add("fr.puzzle_solved", "Teka-teki terpecahkan!", "Puzzle solved!")
    add("fr.reward", "Hadiah: +{coin} koin dan {name}.", "Reward: +{coin} coins and {name}.")
    add("fr.puzzle_done", "Teka-teki ini sudah terpecahkan.", "This puzzle is already solved.")
    for key, (id_, en) in PUZZLE_EXTRA.items():
        add("fr.%s" % key, id_, en)
    add("fr.chest_title", "Peti Gua", "Cave Chest")
    add("fr.chest_prompt", "Buka peti", "Open chest")
    add("fr.chest_open", "Peti dibuka: +{coin} koin, {name} ×{n}.", "Chest opened: +{coin} coins, {name} ×{n}.")
    add("fr.chest_empty", "Peti sudah kosong.", "The chest is already empty.")
    add("fr.gate_gua", "Gua Kapur masih tertutup. Temukan {n} jenis penemuan langka dulu.",
        "The Limestone Cave is still sealed. Find {n} kinds of rare discoveries first.")
    add("fr.unavailable", "Belum tersedia.", "Not available yet.")
    add("fr.book_rare", "Penemuan langka: {kinds} dari {total} jenis. {list}",
        "Rare discoveries: {kinds} of {total} kinds. {list}")
    add("fr.book_puzzles", "Teka-teki terpecahkan: {solved} dari {total}", "Puzzles solved: {solved} of {total}")

    for qid, q in QUESTS.items():
        add("sq.%s.title" % qid, *q["title"])
        add("sq.%s.offer" % qid, *q["offer"])
        add("sq.%s.accepted" % qid, *q["accepted"])
        add("sq.%s.wait" % qid, *q["wait"])
        add("sq.%s.turn" % qid, *q["turn"])
        add("sq.%s.done" % qid, *q["done"])
        for oid, (id_, en) in q["opt"].items():
            add("sq.%s.opt.%s" % (qid, oid), id_, en)

    add("ledger.langka", "Penemuan langka: {item}", "Rare find: {item}")
    add("ledger.teka", "Teka-teki: {item}", "Puzzle: {item}")
    add("ledger.peti", "Peti gua", "Cave chest")
