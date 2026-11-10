"""Teks Fase 6 (simpan, ekonomi, upgrade klinik). Dipanggil dari gen_localization.py: register(add)."""

UPGRADES = {
  "lentera": ("Lentera Periksa", "Examination Lantern", "Diagnosis: +1 energi periksa per tingkat.", "Diagnosis: +1 examination energy per level."),
  "jarum_perak": ("Set Jarum Perak", "Silver Needle Set", "Akupunktur: lingkaran bidik titik +0,02 (sekitar 8%) per tingkat.", "Acupuncture: point aim circle +0.02 (about 8%) per level."),
  "lumpang": ("Lumpang Batu", "Stone Mortar", "Peracikan: toleransi takaran bahan +10% per tingkat.", "Compounding: herb-measure tolerance +10% per level."),
  "rak_besar": ("Rak Herbal Besar", "Large Herb Rack", "Stok harian minimal tiap bahan +1 per tingkat.", "Daily minimum stock of every herb +1 per level."),
  "ruang_tunggu": ("Ruang Tunggu Nyaman", "Cozy Waiting Room", "Penalti kepuasan karena menunggu berkurang 30% per tingkat.", "Waiting-time satisfaction penalty reduced by 30% per level."),
  "kebun": ("Pupuk & Pagar Kebun", "Garden Fertiliser & Fence", "Identifikasi: hasil panen +1 per tingkat.", "Identification: harvest +1 per level."),
}

MILESTONES = {
  "pasien_1": ("Pasien pertama", "First patient"),
  "sembuh_1": ("Kesembuhan pertama", "First cure"),
  "pasien_10": ("10 pasien ditangani", "10 patients treated"),
  "reputasi_40": ("Reputasi 40", "Reputation 40"),
  "pasien_30": ("30 pasien ditangani", "30 patients treated"),
  "reputasi_70": ("Reputasi 70", "Reputation 70"),
}

UI = {
  "ui.new_day_cost": ("Hari {day} dimulai. Biaya operasional kemarin: -{cost} koin. Bahan diisi ulang.", "Day {day} begins. Yesterday's running cost: -{cost} coins. Herbs restocked."),
  "ui.coin_gain": ("+{n} koin ({why})", "+{n} coins ({why})"),
  "ui.coin_loss": ("-{n} koin ({why})", "-{n} coins ({why})"),
  "ui.loaded": ("Kemajuan dimuat. Hari {day}.", "Progress loaded. Day {day}."),
  "ui.load_backup": ("Simpanan utama rusak; dimuat dari cadangan. Hari {day}.", "Main save was damaged; loaded from backup. Day {day}."),
  "ui.load_corrupt": ("Simpanan rusak dan tidak ada cadangan; memulai permainan baru.", "Save is damaged with no backup; starting a new game."),
  # pasar bahan
  "shop.title": ("Pasar Bahan Herbal", "Herb Market"),
  "shop.coins": ("Koin: {money}", "Coins: {money}"),
  "shop.help": ("Beli bahan untuk ramuan. Menjual surplus hanya laku {pct}% dari harga beli.", "Buy herbs for remedies. Selling surplus only fetches {pct}% of the buy price."),
  "shop.buy": ("Beli {p}", "Buy {p}"),
  "shop.sell": ("Jual {p}", "Sell {p}"),
  "shop.stock": ("Stok: {n}", "Stock: {n}"),
  "shop.bought": ("Membeli {name}: -{cost} koin", "Bought {name}: -{cost} coins"),
  "shop.sold": ("Menjual {name}: +{gain} koin", "Sold {name}: +{gain} coins"),
  "shop.no_money": ("Koin tidak cukup.", "Not enough coins."),
  "shop.no_stock": ("Stok bahan habis.", "Out of stock."),
  # upgrade
  "upgrade.title": ("Upgrade Klinik", "Clinic Upgrades"),
  "upgrade.help": ("Biaya operasional klinik {cost} koin per hari dan naik seiring fasilitas.", "Clinic running cost is {cost} coins per day and rises with facilities."),
  "upgrade.buy": ("Beli", "Buy"),
  "upgrade.max_btn": ("Maks", "Max"),
  "upgrade.max": ("Tingkat maksimum", "Maximum level"),
  "upgrade.ready": ("Biaya {cost} koin", "Cost {cost} coins"),
  "upgrade.req_rep": ("Biaya {cost} · butuh reputasi {rep}", "Cost {cost} · needs reputation {rep}"),
  "upgrade.req_skill": ("Biaya {cost} · butuh {skill} tingkat {lv}", "Cost {cost} · needs {skill} level {lv}"),
  "upgrade.req_money": ("Biaya {cost} · koin belum cukup", "Cost {cost} · not enough coins"),
  "upgrade.bought": ("{name} ditingkatkan: -{cost} koin", "{name} upgraded: -{cost} coins"),
  # buku kas
  "ledger.pasien": ("Bayaran pasien", "Patient fee"),
  "ledger.jual": ("Jual {item}", "Sold {item}"),
  "ledger.beli": ("Beli {item}", "Bought {item}"),
  "ledger.upgrade": ("Upgrade {item}", "Upgrade {item}"),
  "ledger.operasional": ("Biaya operasional", "Running cost"),
  "ledger.naik_tingkat": ("Naik tingkat {item}", "Level up {item}"),
  "ledger.capaian": ("Capaian: {item}", "Milestone: {item}"),
  "summary.milestone": ("Capaian baru: {name}", "New milestone: {name}"),
  "book.upgrades": ("Fasilitas: {list} (biaya harian {cost})", "Facilities: {list} (daily cost {cost})"),
  "book.ledger": ("Transaksi terakhir:", "Latest transactions:"),
  "book.save": ("Simpan", "Save"),
  "book.saved": ("Tersimpan ✓", "Saved ✓"),
  "book.save_fail": ("Gagal menyimpan", "Save failed"),
}


def register(add):
    for k, (i, e) in UI.items():
        add(k, i, e)
    for uid, (ni, ne, ei, ee) in UPGRADES.items():
        add(f"upgrade.{uid}.name", ni, ne)
        add(f"upgrade.{uid}.effect", ei, ee)
    for mid, (i, e) in MILESTONES.items():
        add(f"milestone.{mid}", i, e)
