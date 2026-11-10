#!/usr/bin/env python3
"""Pembuat game/localization/id.json dan en.json dari satu sumber (id, en) per kunci.
Jalankan: python3 tools/gen_localization.py  (dari akar repo). Berkas JSON hasilnya yang dikomit."""
import json, os

T = {}
def add(key, id_, en): T[key] = (id_, en)

# --- UI umum ---
add("ui.talk", "Bicara: {name}", "Talk: {name}")
add("ui.next", "Lanjut", "Next")
add("ui.clock", "Hari {day}  {time}", "Day {day}  {time}")
add("ui.clinic_open", "Klinik buka", "Clinic open")
add("ui.clinic_closed", "Klinik tutup", "Clinic closed")
add("ui.queue", "Antrean: {n}", "Queue: {n}")
add("ui.request_active", "Permintaan: {title}", "Request: {title}")
add("ui.request_ready", "Permintaan siap dilaporkan: {title}", "Request ready to report: {title}")
add("ui.lang_name", "Bahasa: Indonesia", "Language: English")

# --- Dialog umum ---
add("dlg.choice.status", "Sedang apa?", "What are you up to?")
add("dlg.choice.about", "Ceritakan tentang desa ini", "Tell me about this village")
add("dlg.choice.help", "Ada yang bisa kubantu?", "Anything I can help with?")
add("dlg.choice.accept", "Baik, akan kubantu", "Sure, I'll help")
add("dlg.choice.decline", "Maaf, belum bisa", "Sorry, not right now")
add("dlg.choice.report", "Sudah kulakukan", "It's done")
add("dlg.choice.bye", "Sampai jumpa", "See you")
add("dlg.choice.more", "Ada lagi?", "Anything else?")
add("dlg.status", "Aku sedang {activity}.", "I'm {activity} right now.")
add("dlg.no_request", "Sementara tidak ada. Terima kasih sudah bertanya, Tabib.", "Nothing for now. Thanks for asking, Healer.")
add("dlg.request_declined", "Tidak apa-apa. Kalau sempat, kabari aku.", "That's fine. Let me know if you find the time.")
add("dlg.request_accepted", "Terima kasih, Tabib. Aku menunggu kabarmu.", "Thank you, Healer. I'll be waiting for your news.")
add("dlg.request_pending", "Bagaimana permintaanku tadi? Belum selesai, ya?", "How about my request? Not done yet?")
add("dlg.request_done", "Terima kasih sudah membantu, Tabib. Desa ini beruntung memilikimu.", "Thanks for helping, Healer. The village is lucky to have you.")
add("dlg.request_claim", "Sudah selesai? Terima kasih banyak, Tabib!", "All done? Thank you so much, Healer!")

# --- Aktivitas (kalimat "Aku sedang ...") ---
for k, (i, e) in {
    "di_rumah": ("beristirahat di rumah", "resting at home"),
    "berkebun": ("merawat kebun herbal", "tending the herb garden"),
    "mengambil_air": ("mengambil air di sumur", "fetching water at the well"),
    "bersantai": ("bersantai di alun-alun", "relaxing in the square"),
    "berdagang": ("berjualan di jalan desa", "selling goods along the road"),
    "memancing": ("memancing di kolam", "fishing at the pond"),
    "berjalan": ("berjalan-jalan keliling desa", "strolling around the village"),
    "mengantar_rempah": ("mengantar rempah ke klinik", "delivering spices to the clinic"),
    "bermain": ("bermain di dekat kolam", "playing near the pond"),
    "menunggu_giliran": ("menunggu giliran di klinik", "waiting for my turn at the clinic"),
    "berobat": ("berobat ke klinik", "heading to the clinic for treatment"),
    "diperiksa": ("diperiksa di klinik", "being examined at the clinic"),
}.items():
    add("activity." + k, i, e)

# --- Keluhan pasien (fiksi, ringan) ---
COMPLAINTS = {
    "demam_dingin": ("Badanku panas dingin sejak semalam dan kepala terasa berat.", "My body has been hot and cold since last night and my head feels heavy."),
    "pusing_berputar": ("Kepalaku terasa berputar setiap kali bangun dari duduk.", "My head spins every time I stand up."),
    "perut_kembung": ("Perutku kembung dan tidak enak sehabis makan.", "My stomach feels bloated and uneasy after meals."),
    "batuk_kering": ("Tenggorokanku gatal dan aku batuk kering terus.", "My throat itches and I keep coughing."),
    "sendi_kaku": ("Lutut dan pergelangan tanganku kaku di pagi hari.", "My knees and wrists are stiff in the morning."),
    "gatal_kulit": ("Kulit lenganku gatal dan memerah.", "The skin on my arms is itchy and red."),
    "lelah_berat": ("Aku cepat lelah dan sulit tidur nyenyak.", "I tire easily and cannot sleep soundly."),
    "mata_perih": ("Mataku perih dan berair sejak kemarin.", "My eyes have been stinging and watering since yesterday."),
}
for k, (i, e) in COMPLAINTS.items():
    add("complaint." + k, i, e)

# --- Pasien ---
add("dlg.patient.coming", "Aku mau berobat ke klinik. {complaint}", "I'm on my way to the clinic. {complaint}")
add("dlg.patient.waiting", "Aku menunggu giliran, Tabib. {complaint}", "I'm waiting my turn, Healer. {complaint}")
add("dlg.patient.called", "Sudah dipanggil? Baik, aku ke ruang periksa.", "Called already? Alright, I'm heading to the exam room.")
add("dlg.patient.exam", "Silakan periksa aku, Tabib. {complaint}", "Please examine me, Healer. {complaint}")
add("dlg.patient.leaving", "Terima kasih, Tabib. Aku pulang dulu.", "Thank you, Healer. I'm going home now.")
add("clinic.ticket_called", "Memanggil pasien: {name} (No. {ticket})", "Calling patient: {name} (No. {ticket})")
add("clinic.queue_status", "Antrean: {waiting} menunggu. Ruang periksa: {room}.", "Queue: {waiting} waiting. Exam room: {room}.")
add("clinic.room_free", "kosong", "free")
add("clinic.room_busy", "terisi", "occupied")
add("clinic.no_patient", "Tidak ada pasien yang menunggu.", "No patients are waiting.")
add("clinic.room_occupied", "Ruang periksa masih terisi.", "The exam room is still occupied.")
add("clinic.exam_done", "Pemeriksaan {name} selesai (sementara, belum ada diagnosis).", "Examination of {name} finished (placeholder, no diagnosis yet).")
add("clinic.exam_empty", "Tidak ada pasien di ruang periksa.", "No patient in the exam room.")
add("clinic.closed_notice", "Klinik sedang tutup (buka 08:00-16:00).", "The clinic is closed (open 08:00-16:00).")
add("clinic.patient_arrived", "Pasien datang: {name}", "A patient arrives: {name}")
add("clinic.patient_left_waiting", "{name} pulang karena menunggu terlalu lama.", "{name} went home after waiting too long.")
add("prompt.clinic_reception", "Meja Penerimaan", "Reception Desk")
add("prompt.clinic_exam_bed", "Tempat Periksa", "Examination Bed")

# --- Penduduk ---
NPCS = {
  "karto": dict(name=("Pak Karto","Mr. Karto"), role=("Petani herbal","Herb farmer"),
    greet=("Selamat datang, Tabib. Kebun herbal sedang subur-suburnya.","Welcome, Healer. The herb garden is thriving."),
    about=("Daun-daun di kebun itu kutanam sendiri. Kebun terbuka untukmu kapan saja.","I planted those leaves myself. The garden is open to you any time."),
    about2=("Pagi hari waktu terbaik merawat tanaman. Siangnya aku biasa duduk di alun-alun.","Morning is the best time to tend plants. At midday I rest in the square.")),
  "sari": dict(name=("Bu Sari","Mrs. Sari"), role=("Pedagang","Trader"),
    greet=("Tabib! Kebetulan sekali, mampir dulu.","Healer! What luck, do stop by."),
    about=("Aku berjualan di jalan desa pagi hari, lalu pindah ke alun-alun menjelang siang.","I sell along the village road in the morning, then move to the square before noon."),
    about2=("Banyak warga mulai mengeluh badan pegal. Mungkin klinikmu akan ramai.","Many villagers have started complaining of aches. Your clinic may get busy.")),
  "wiryo": dict(name=("Mbah Wiryo","Grandpa Wiryo"), role=("Tetua desa","Village elder"),
    greet=("Ah, tabib muda. Duduklah sebentar, Nak.","Ah, young healer. Sit a while, child."),
    about=("Desa ini sudah ada sejak sebelum aku lahir. Klinik itu dulu hanya gubuk kecil.","This village was here long before I was born. That clinic used to be a small hut."),
    about2=("Kalau bingung, tanyakan kabar warga. Setiap orang punya cerita.","If you are unsure, ask the villagers how they are. Everyone has a story.")),
  "dewi": dict(name=("Dewi","Dewi"), role=("Gadis desa","Village girl"),
    greet=("Halo, Kak Tabib!","Hello, Healer!"),
    about=("Aku suka bermain di dekat kolam. Airnya jernih dan sejuk.","I love playing near the pond. The water is clear and cool."),
    about2=("Kata ibu, tabib itu pandai mengenali daun obat. Benar, Kak?","Mother says healers know all the medicinal leaves. Is that true?")),
  "joko": dict(name=("Pak Joko","Mr. Joko"), role=("Pemancing","Angler"),
    greet=("Ssst, jangan keras-keras, nanti ikannya kabur.","Shh, not so loud, you'll scare the fish."),
    about=("Kolam di timur laut itu ikannya gemuk. Pagi hari paling bagus.","The pond in the north-east has plump fish. Mornings are best."),
    about2=("Siang aku ke sumur mengisi air, lalu kembali memancing.","At noon I fetch water at the well, then go back to fishing.")),
  "lastri": dict(name=("Bu Lastri","Mrs. Lastri"), role=("Ibu rumah tangga","Homemaker"),
    greet=("Selamat datang, Tabib. Baru dari mana?","Welcome, Healer. Where have you been?"),
    about=("Aku sering ke sumur pagi-pagi, lalu membantu di kebun herbal.","I go to the well early, then help out in the herb garden."),
    about2=("Anak-anak sering main di kolam. Aku selalu cemas kalau mereka lupa waktu.","The children play at the pond. I always worry when they lose track of time.")),
  "raka": dict(name=("Raka","Raka"), role=("Pemuda desa","Village youth"),
    greet=("Oh, Tabib! Ada yang perlu dibantu angkat-angkat?","Oh, Healer! Need help carrying anything?"),
    about=("Aku membantu Bapak di kebun, kadang berkeliling desa mencari kabar.","I help Father in the garden and sometimes roam the village for news."),
    about2=("Kalau sore aku suka ke kolam. Pemandangannya bagus.","In the evening I like going to the pond. The view is lovely.")),
  "ratih": dict(name=("Nyai Ratih","Madam Ratih"), role=("Penjual rempah","Spice seller"),
    greet=("Wah, Tabib. Rempahku segar-segar hari ini.","Why, Healer. My spices are fresh today."),
    about=("Tiap pagi kupetik rempah di kebun, lalu kuantar ke klinik menjelang siang.","Each morning I pick spices in the garden, then deliver them to the clinic before noon."),
    about2=("Antreannya biasanya ramai siang hari. Pastikan kau tidak telat membuka klinik.","The queue is usually busy in the afternoon. Be sure to open the clinic on time.")),
}
for nid, d in NPCS.items():
    add(f"npc.{nid}.name", *d["name"])
    add(f"npc.{nid}.role", *d["role"])
    add(f"dlg.{nid}.greet", *d["greet"])
    add(f"dlg.{nid}.about", *d["about"])
    add(f"dlg.{nid}.about2", *d["about2"])

# --- Permintaan sederhana ---
REQ = {
  "req_salam_wiryo": ("Sampaikan salam kepada Mbah Wiryo", "Pass greetings to Grandpa Wiryo",
     "Tolong sampaikan salamku kepada Mbah Wiryo. Sudah lama aku tidak sempat menjenguknya.", "Please pass my greetings to Grandpa Wiryo. I haven't had time to visit him in ages.",
     "Kau sudah bertemu Mbah Wiryo? Bagaimana kabar beliau?", "Did you meet Grandpa Wiryo? How is he?"),
  "req_lihat_kebun": ("Lihat keadaan kebun herbal", "Check on the herb garden",
     "Bisa kau lihat keadaan kebun herbal? Aku ingin tahu apakah tanamannya sehat.", "Could you check on the herb garden? I want to know if the plants are healthy.",
     "Sudah melihat kebun herbal? Bagaimana tanamannya?", "Have you seen the herb garden? How are the plants?"),
  "req_kabar_joko": ("Tanyakan kabar Pak Joko", "Ask after Mr. Joko",
     "Tolong tanyakan kabar Pak Joko di kolam. Katanya ikannya banyak hari ini.", "Please ask how Mr. Joko is doing at the pond. They say the fish are plentiful today.",
     "Sudah bertemu Pak Joko? Dapat ikan banyak, tidak?", "Did you meet Mr. Joko? Did he catch many fish?"),
  "req_lihat_resepsi": ("Lihat ruang tunggu klinik", "Look at the clinic waiting area",
     "Bisa kau lihat ruang tunggu klinik? Aku ingin tahu apakah bangkunya cukup nyaman.", "Could you look at the clinic waiting area? I'd like to know if the benches are comfortable enough.",
     "Sudah melihat ruang tunggu? Bagaimana menurutmu?", "Did you see the waiting area? What do you think?"),
}
for rid, (ti, te, oi, oe, ri, re) in REQ.items():
    add(f"{rid}.title", ti, te)
    add(f"{rid}.offer", oi, oe)
    add(f"{rid}.remind", ri, re)

import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import loc_fase5
loc_fase5.register(add)
import loc_fase6
loc_fase6.register(add)

if __name__ == "__main__":
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "localization")
    os.makedirs(root, exist_ok=True)
    for idx, lang in enumerate(["id", "en"]):
        with open(os.path.join(root, lang + ".json"), "w", encoding="utf-8") as f:
            json.dump({k: v[idx] for k, v in sorted(T.items())}, f, ensure_ascii=False, indent=1, sort_keys=True)
            f.write("\n")
    print("kunci:", len(T))
