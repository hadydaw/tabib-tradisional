"""Teks Fase 8 (hubungan NPC, cerita, quest, reputasi, event desa). Dipanggil dari gen_localization.py: register(add).
Semua tokoh dan kejadian fiktif. Setiap kunci punya teks Indonesia dan Inggris."""

# Sapaan per tingkat kepercayaan: tingkat 0 (belum akrab), 1 (mulai akrab), 2 (akrab).
GREET_TIERS = {
  "karto": (
    ("Selamat pagi, Tabib. Kebunku masih sederhana, tapi selalu kusiram tiap hari.",
     "Good morning, Healer. My garden is still modest, but I water it every day."),
    ("Ah, Tabib. Mau kutunjukkan daun-daun baru di kebunku?",
     "Ah, Healer. Shall I show you the new leaves in my garden?"),
    ("Tabib kesayanganku! Kalau tidak sibuk, duduk dulu di bawah pohon ini.",
     "My favourite Healer! If you're not busy, sit under this tree first."),
  ),
  "sari": (
    ("Halo, Tabib! Mau beli apa hari ini? Eh, maksudku... mau ngobrol dulu?",
     "Hello, Healer! Buying anything today? Or, um... just chatting first?"),
    ("Tabib! Aku baru dengar kabar dari pasar. Mau dengar?",
     "Healer! I just heard news from the market. Want to hear it?"),
    ("Tabib, kamu sudah seperti saudaraku sendiri. Ayo duduk, kutraktir teh.",
     "Healer, you're like my own sibling. Come sit, I'll treat you to tea."),
  ),
  "wiryo": (
    ("Oh, Tabib. Duduklah sebentar, kakiku sudah tak kuat berdiri lama.",
     "Oh, Healer. Sit a while, my legs can't stand for long anymore."),
    ("Tabib, kamu mulai mengerti cara hidup kami di sini, ya?",
     "Healer, you're starting to understand how we live here, aren't you?"),
    ("Anakku, aku senang kamu datang. Ada yang ingin kuceritakan sejak lama.",
     "My child, I'm glad you came. There's something I've wanted to tell you for a long time."),
  ),
  "dewi": (
    ("Tabib! Kamu pernah ke sungai belum? Aku penasaran sekali!",
     "Healer! Have you been to the river? I'm so curious!"),
    ("Tabib! Kemarin aku lihat ikan besar di kolam. Kamu percaya?",
     "Healer! Yesterday I saw a huge fish in the pond. Do you believe me?"),
    ("Tabib, kamu teman terbaikku! Aku punya rahasia kecil, mau dengar?",
     "Healer, you're my best friend! I have a little secret, want to hear it?"),
  ),
  "joko": (
    ("...Tabib. Ada perlu apa?",
     "...Healer. What do you need?"),
    ("Tabib. Hari ini air kolam tenang sekali.",
     "Healer. The pond water is very calm today."),
    ("Tabib, aku jarang bicara panjang. Tapi denganmu, aku senang bicara.",
     "Healer, I rarely talk at length. But with you, I enjoy talking."),
  ),
  "lastri": (
    ("Selamat siang, Tabib. Jangan lupa minum air, ya.",
     "Good afternoon, Healer. Don't forget to drink water."),
    ("Tabib, anak-anak sering bertanya tentangmu. Mereka kagum.",
     "Healer, the children keep asking about you. They're in awe."),
    ("Tabib, kalau butuh apa-apa, bilang saja. Kami semua ada untukmu.",
     "Healer, if you need anything, just say so. We're all here for you."),
  ),
  "raka": (
    ("Tabib! Aku baru selesai membantu di kebun. Capek, tapi seru!",
     "Healer! I just finished helping in the garden. Tiring, but fun!"),
    ("Tabib, aku ingin belajar mengenali tanaman seperti kamu. Boleh?",
     "Healer, I want to learn to recognise plants like you do. May I?"),
    ("Tabib, suatu hari aku ingin jadi tabib juga. Kamu mau jadi guruku?",
     "Healer, someday I want to be a healer too. Will you be my teacher?"),
  ),
  "ratih": (
    ("Tabib. Jangan terlambat membuka klinik lagi.",
     "Healer. Don't be late opening the clinic again."),
    ("Tabib, kerjamu bagus akhir-akhir ini. Teruskan.",
     "Healer, your work has been good lately. Keep it up."),
    ("Tabib, aku mengandalkanmu. Desa ini beruntung punya kamu, dan aku bangga.",
     "Healer, I rely on you. This village is lucky to have you, and I'm proud."),
  ),
}

# Bab cerita: ch1 (ambang kepercayaan 25) dan ch2 (ambang 60), masing-masing dengan lanjutan (_more).
CHAPTERS = {
  "karto": (
    ("Dulu aku pernah merantau jauh. Kebun ini yang membuatku kembali dan tinggal.",
     "Long ago I wandered far away. This garden is what brought me back to stay."),
    ("Istriku yang menanam kumis kucing pertama di sini. Sejak itu aku merawatnya seperti pesan terakhirnya.",
     "My late wife planted the first cat's whiskers here. Since then I've tended them as her last wish."),
    ("Di belakang kebun ada petak liar yang kubiarkan tumbuh. Dulu tanaman langka pernah tumbuh di sana.",
     "Behind the garden there's a wild patch I let grow. Rare plants once grew there."),
    ("Kalau sempat, coba kenali apa yang tumbuh di sana. Mungkin kamu bisa mengajariku sesuatu.",
     "If you have time, try identifying what grows there. Maybe you can teach me something."),
  ),
  "sari": (
    ("Aku berdagang sejak remaja. Ibuku dulu pedagang keliling yang keluar masuk hutan mencari bahan.",
     "I've traded since I was young. My mother was a travelling trader who went in and out of the forest for ingredients."),
    ("Dari beliau aku tahu harga setiap bahan, tapi tak pernah tahu cara memakainya. Makanya aku menghormati kalian para tabib.",
     "From her I learned every herb's price, but never how to use them. That's why I respect you healers."),
    ("Pasar sering dihantam kabar buruk: harga naik, bahan langka. Aku takut suatu hari desa kehabisan obat.",
     "Bad news often hits the market: prices rise, herbs run short. I'm afraid one day the village will run out of medicine."),
    ("Makanya aku senang kalau kamu membeli dan menyimpan bahan dengan bijak. Itu lebih berharga dari yang kamu kira.",
     "That's why I'm glad when you buy and store herbs wisely. It's worth more than you think."),
  ),
  "wiryo": (
    ("Dulu aku juga tabib di desa ini, sebelum kamu belajar melihat daun dengan matamu sendiri.",
     "I was a healer in this village once, before you learned to see leaves with your own eyes."),
    ("Ada tanaman yang menyembuhkan kalau dipakai tepat, dan mencelakai kalau sembarangan. Ingat itu baik-baik.",
     "Some plants heal when used correctly and harm when used carelessly. Remember that well."),
    ("Dulu ada seorang tabib perempuan yang mencatat setiap tanaman di buku tulis. Bukunya hilang saat banjir besar.",
     "Long ago a woman healer wrote down every plant in a notebook. It was lost in the great flood."),
    ("Aku masih ingat sebagian isinya. Kalau kamu mau, aku akan membantumu mengingat yang hilang.",
     "I still remember part of it. If you want, I'll help you recall what was lost."),
  ),
  "dewi": (
    ("Aku sering diam-diam ke sungai saat orang tuaku tidak melihat. Pernah kulihat bangau putih di sana.",
     "I often slipped off to the river when my parents weren't looking. Once I saw a white heron there."),
    ("Sejak itu aku ingin tahu semua tempat jauh di sekitar desa. Tapi aku takut pergi sendirian.",
     "Since then I've wanted to know every faraway place around the village. But I'm scared to go alone."),
    ("Aku pernah tersesat di hutan. Untung aku mengenali daun dari buku, jadi bisa pulang.",
     "I once got lost in the forest. Luckily I recognised a leaf from a book, so I could find my way home."),
    ("Sejak itu aku belajar mengenali tanaman sebisanya. Kalau kamu mau mengajariku, aku senang sekali.",
     "Since then I've learned to recognise plants as best I can. If you'd teach me, I'd be very happy."),
  ),
  "joko": (
    ("Aku memancing sejak kecil. Ayahku bilang, sabar itu separuh dari hasil tangkapan.",
     "I've fished since I was small. My father said patience is half of the catch."),
    ("Kolam ini dulunya sungai besar. Lalu alirannya berubah, dan aku belum terbiasa.",
     "This pond used to be a big river. Then its course changed, and I still haven't grown used to it."),
    ("Dulu istriku sakit lama dan tak ada tabib yang bisa menolong. Sejak itu aku menyimpan rasa tak percaya.",
     "My wife was sick for a long time and no healer could help. Since then I've kept my distrust."),
    ("Melihatmu bekerja, aku mulai berpikir mungkin sekarang ada yang berbeda. Tapi aku belum yakin.",
     "Watching you work, I've begun to think things may be different now. But I'm not sure yet."),
  ),
  "lastri": (
    ("Anakku tiga, dan dua di antaranya suka sekali berlari ke hutan. Aku selalu cemas.",
     "I have three children, and two of them love running into the forest. I'm always anxious."),
    ("Aku selalu menyuruh mereka membawa air dan bekal. Kebiasaan kecil itu sering menyelamatkan mereka.",
     "I always make them bring water and food. That small habit has saved them more than once."),
    ("Dulu, saat anak bungsuku demam tinggi, aku datang ke klinik tengah malam. Mungkin kamu tak ingat.",
     "Once, when my youngest had a high fever, I came to the clinic in the middle of the night. You may not remember."),
    ("Sejak itu aku ingin membalas budi. Kalau ada yang bisa kubantu di desa, bilang saja.",
     "Since then I've wanted to repay you. If there's anything I can do for the village, just tell me."),
  ),
  "raka": (
    ("Aku anak yatim dari seberang sungai. Aku tinggal di sini karena Paman Karto menampungku.",
     "I'm an orphan from across the river. I live here because Uncle Karto took me in."),
    ("Aku ingin berguna. Makanya aku sering membantu di kebun dan berkeliling desa.",
     "I want to be useful. That's why I help in the garden and go around the village."),
    ("Aku pernah nekat ke pegunungan sendirian untuk membuktikan diri. Hampir celaka di lereng licin.",
     "I once went to the mountains alone to prove myself. I nearly got hurt on a slippery slope."),
    ("Sejak itu aku belajar sabar. Kalau kamu pergi lagi, ajak aku. Aku janji akan mendengarkan.",
     "Since then I've learned patience. If you go out again, take me along. I promise I'll listen."),
  ),
  "ratih": (
    ("Dulu aku perawat di kota. Aku pindah kemari karena ingin tempat yang lebih tenang.",
     "I used to be a nurse in the city. I moved here for a quieter place."),
    ("Tapi di desa, orang sering menunda berobat sampai terlambat. Itu yang paling kutakutkan.",
     "But in this village, people often delay seeing a healer until it's too late. That's what I fear most."),
    ("Aku pernah kehilangan pasien karena terlambat dibawa ke tabib. Sejak itu aku tegas soal jadwal.",
     "I once lost a patient because they were brought to a healer too late. Since then I've been strict about schedules."),
    ("Maaf kalau aku keras. Aku hanya ingin kamu tidak mengulang kesalahan itu. Kamu sudah menunjukkan kepedulian.",
     "Sorry if I'm harsh. I only want you not to repeat that mistake. You've shown that you care."),
  ),
}

QUESTS = {
  "q_wiryo_ramuan": {
    "title": ("Ramuan untuk Mbah Wiryo", "Herbs for Grandpa Wiryo"),
    "offer": ("Tabib, tolong kumpulkan 3 bahan dari hutan untukku. Aku butuh untuk ramuan malam ini.",
              "Healer, please gather 3 herbs from the forest for me. I need them for tonight's remedy."),
    "accepted": ("Terima kasih, Tabib. Ingat, ambil hanya yang benar-benar kamu kenali.",
                 "Thank you, Healer. Remember, only take what you truly recognise."),
    "wait": ("Bahan dari hutan belum cukup. Sabar, ya.", "The forest herbs aren't enough yet. Be patient."),
    "turn": ("Sudah dapat? Mari kulihat. Bagaimana kamu akan mencatat bahan ini?",
             "Got them? Let me see. How will you record these herbs?"),
    "done": ("Baiklah. Desa ini akan mengingat caramu.", "Alright. The village will remember what you did."),
    "opt": {
      "jujur": ("Catat apa adanya, sebagian sudah layu.", "Record them exactly, some are already wilted."),
      "untung": ("Jual dengan harga pasar. Pelanggan tidak akan tahu bedanya.",
                 "Sell them at market price. The customers won't know the difference."),
    },
  },
  "q_dewi_sungai": {
    "title": ("Cerita dari Sungai", "A Story from the River"),
    "offer": ("Pergi ke sungai dan lihat sendiri. Lalu ceritakan padaku, ya!",
              "Go to the river and see for yourself. Then tell me about it!"),
    "accepted": ("Yey! Jangan lupa, ceritakan yang sebenarnya!", "Yay! Don't forget, tell me the real story!"),
    "wait": ("Kamu belum ke sungai, ya? Jalannya ada di sebelah timur desa.",
             "You haven't been to the river yet, have you? The path is east of the village."),
    "turn": ("Jadi, bagaimana sungainya? Ceritakan!", "So, what's the river like? Tell me!"),
    "done": ("Wah, seru sekali! Terima kasih, Tabib.", "Wow, how exciting! Thank you, Healer."),
    "opt": {
      "apa_adanya": ("Sungainya tenang, ada kayu hanyut di tepinya, dan bunga-bunga kecil.",
                     "The river is calm, with driftwood along the banks and small flowers."),
      "dilebihkan": ("Sungainya luas sekali, katanya ada buaya besar! Hampir celaka aku.",
                     "The river is huge, and there's supposedly a giant crocodile! I nearly got hurt."),
    },
  },
  "q_ratih_pasien": {
    "title": ("Pasien Pilihan", "Chosen Patients"),
    "offer": ("Kerjamu mulai rapi. Tangani tiga pasien dengan hasil baik, dan desa ikut diuntungkan.",
              "Your work is getting neat. Treat three patients with good results, and the village benefits too."),
    "accepted": ("Bagus. Aku menunggu laporanmu di sini.", "Good. I'll wait for your report here."),
    "wait": ("Tiga pasien dengan hasil baik belum selesai. Lanjutkan saja.",
             "Three patients with good results aren't done yet. Keep going."),
    "turn": ("Kamu sudah menangani pasien dengan baik. Bagaimana hasilnya akan dibagi?",
             "You've treated patients well. How will the reward be shared?"),
    "done": ("Begitulah tabib yang baik. Terus begini, ya.", "That's how a good healer does it. Keep it up."),
    "opt": {
      "upah": ("Aku ambil upahku sendiri, itu hakku.", "I'll take my own pay. That's my right."),
      "bagi": ("Bagi dengan para pembantu klinik dan ajak mereka belajar.",
               "Share it with the clinic helpers and teach them."),
    },
  },
  "q_karto_kebun": {
    "title": ("Tanaman Liar di Kebun Karto", "Wild Plants in Karto's Garden"),
    "offer": ("Di belakang kebunku ada tanaman yang tak kukenali. Bisa kamu kenali dua di antaranya?",
              "Behind my garden there are plants I don't recognise. Could you identify two of them?"),
    "accepted": ("Terima kasih. Perhatikan baik-baik, ya.", "Thank you. Look carefully, please."),
    "wait": ("Dua tanaman itu belum kamu kenali. Aku masih menunggu.",
             "You haven't identified those two plants yet. I'm still waiting."),
    "turn": ("Tanamannya sudah kamu kenali. Siapa yang harus kusebut berjasa?",
             "You've identified the plants. Who should I credit for it?"),
    "done": ("Baiklah. Semoga kebun ini makin berguna bagi desa.",
             "Alright. I hope this garden becomes more useful for the village."),
    "opt": {
      "bagi_jasa": ("Kita berdua, Pak Karto. Aku yang mengenali, kamu yang merawat.",
                    "Both of us, Uncle Karto. I identified them, you tended them."),
      "ambil_pujian": ("Aku yang mengenali, jadi jasa itu milikku saja.",
                       "I'm the one who identified them, so the credit is mine alone."),
    },
  },
}

EVENTS = {
  "pasar_desa": (("Pasar Desa", "Village Market"),
                 ("Pasar Desa ramai! +{n} koin", "The village market is busy! +{n} coins")),
  "malam_bakti": (("Malam Bakti", "Night of Service"),
                  ("Malam Bakti: warga makin percaya padamu", "Night of Service: the villagers trust you more")),
}


def register(add):
    # Dialog: pilihan dan sapaan
    add("dlg.choice.chapter", "Aku ingin mendengar ceritamu", "I'd like to hear your story")
    add("dlg.choice.more", "Ceritakan lebih banyak", "Tell me more")
    add("dlg.choice.later", "Nanti saja", "Maybe later")
    add("dlg.choice.quest", "Ada tugas untukku?", "Is there a task for me?")
    add("dlg.choice.quest_status", "Soal tugasmu...", "About your task...")
    add("dlg.choice.report_quest", "Tugasku sudah selesai", "My task is done")
    add("dlg.choice.gift", "Berikan bahan herbal", "Give an herb")
    add("dlg.chapter_later", "Baik, nanti saja kalau kamu sudah siap.", "Alright, another time when you're ready.")
    add("dlg.gift_thanks", "Wah, terima kasih, Tabib.", "Oh, thank you, Healer.")

    for nid, tiers in GREET_TIERS.items():
        for t, (id_, en) in enumerate(tiers):
            add("dlg.%s.t%d" % (nid, t), id_, en)

    for nid, chs in CHAPTERS.items():
        for suffix, (id_, en) in zip(["ch1", "ch1_more", "ch2", "ch2_more"], chs):
            add("dlg.%s.%s" % (nid, suffix), id_, en)

    # Quest cerita
    for qid, q in QUESTS.items():
        add("sq.%s.title" % qid, *q["title"])
        add("sq.%s.offer" % qid, *q["offer"])
        add("sq.%s.accepted" % qid, *q["accepted"])
        add("sq.%s.wait" % qid, *q["wait"])
        add("sq.%s.turn" % qid, *q["turn"])
        add("sq.%s.done" % qid, *q["done"])
        for oid, (id_, en) in q["opt"].items():
            add("sq.%s.opt.%s" % (qid, oid), id_, en)

    # Event desa
    for eid, (title, toast) in EVENTS.items():
        add("event.%s.title" % eid, *title)
        add("event.%s.toast" % eid, *toast)

    # UI
    add("ui.trust_gain", "Kepercayaan {name} +{n}", "{name} trust +{n}")
    add("ui.gift_done", "{name} menerima {herb}. Kepercayaan +{n}", "{name} received {herb}. Trust +{n}")
    add("ui.gift_none", "Tidak ada bahan yang bisa diberikan.", "You have no herbs to give.")
    add("ui.squest_taken", "Tugas diterima: {title}", "Task accepted: {title}")
    add("ui.squest_ready", "Tugas siap diserahkan: {title}", "Task ready to hand in: {title}")
    add("ui.squest_done", "Tugas selesai: {title}", "Task complete: {title}")
    add("ui.squest_line", "Tugas: {title}", "Task: {title}")
    add("ui.squest_line_ready", "Siap diserahkan: {title}", "Ready to hand in: {title}")
    add("ui.event_next", "Event berikutnya: {title}, hari {day}", "Next event: {title}, day {day}")

    # Buku Tabib
    add("book.trust", "Hubungan: {list}", "Relationships: {list}")
    add("book.quests", "Tugas selesai: {done}, sedang berjalan: {active}", "Tasks done: {done}, in progress: {active}")
    add("book.tier.0", "(belum akrab)", "(not close yet)")
    add("book.tier.1", "(mulai akrab)", "(getting close)")
    add("book.tier.2", "(akrab)", "(close)")

    # Teks alasan di buku kas
    add("ledger.tugas", "Tugas: {item}", "Task: {item}")
    add("ledger.event", "Event: {item}", "Event: {item}")
