#!/usr/bin/env python3
"""Uji susunan lapisan pakaian (8 arah): badan dasar + baju atas + celana bawah.

Anchor (kanvas 420x560, telapak kaki di y=520):
- Badan dasar: kaki di y=520, pusat x=210.
- Celana: potong di batas cuff (sebelum sepatu), ujung atas di y=312 (menumpuk di bawah baju),
  ujung bawah di y=500 (pergelangan).
- Baju: skala 0.78, bagian bawah di y=340 agar menutupi celana dalam putih.
Urutan gambar: badan -> celana -> baju.
Keluaran: contoh tumpukan 4 kombinasi x 8 arah dalam satu lembar uji.
"""
import numpy as np
from PIL import Image
from scipy import ndimage

BASE = '/mnt/user-data/attachments/de80c5e6-a210-580e-8b80-171dbb6653e2/'
SHEETS = {
    'badan': BASE + '499412d3-image.png',
    'baju': BASE + '538d4805-image.png',
    'celana': BASE + '39fd5aca-image.png',
}
CANVAS = (420, 560)
FEET_Y = 520
PANTS_CUT = 0.62       # fraksi tinggi celana sebelum sepatu (batas cuff)
PANTS_TOP = 300
PANTS_BOTTOM = 500
SHIRT_SCALE = 0.78
SHIRT_BOTTOM = 352


def cells(path):
    a = np.asarray(Image.open(path).convert('RGB')).astype(int)
    fg = ~((a[..., 0] > 200) & (a[..., 1] < 90) & (a[..., 2] > 200))
    cols = fg.any(axis=0)
    groups, s = [], None
    for x, v in enumerate(cols):
        if v and s is None:
            s = x
        if not v and s is not None:
            groups.append((s, x))
            s = None
    out = []
    for x0, x1 in groups:
        x0, x1 = max(0, x0 - 4), min(a.shape[1], x1 + 4)
        rgb = a[:, x0:x1].astype(np.uint8)
        mask = fg[:, x0:x1]
        # Buang sisa magenta di tepi: tepi dalam 2 px dipakai sebagai sumber warna.
        inside = ndimage.binary_erosion(mask, iterations=2)
        idx = ndimage.distance_transform_edt(~inside, return_distances=False, return_indices=True)
        rgb = rgb[idx[0], idx[1]]
        rgba = np.dstack([rgb, (inside * 255).astype(np.uint8)])
        im = Image.fromarray(rgba, 'RGBA')
        ys = np.where(rgba[..., 3].any(axis=1))[0]
        out.append(im.crop((0, ys.min(), im.width, ys.max() + 1)))
    return out


def place(canvas, img, cx, top, bottom=None, scale=1.0):
    w = max(1, int(round(img.width * scale)))
    h = max(1, int(round(img.height * scale)))
    im = img.resize((w, h), Image.LANCZOS)
    if bottom is not None:
        top = bottom - h
    canvas.alpha_composite(im, (int(cx - w // 2), int(top)))


def compose(body, shirt, pants, use_shirt=True, use_pants=True):
    cv = Image.new('RGBA', CANVAS, (40, 40, 40, 255))
    place(cv, body, CANVAS[0] // 2, 0, bottom=FEET_Y)
    if use_pants:
        cut = pants.crop((0, 0, pants.width, int(pants.height * PANTS_CUT)))
        place(cv, cut, CANVAS[0] // 2, PANTS_TOP, bottom=PANTS_BOTTOM + (PANTS_TOP - PANTS_TOP), scale=1.0)
    if use_shirt:
        place(cv, shirt, CANVAS[0] // 2, 0, bottom=SHIRT_BOTTOM, scale=SHIRT_SCALE)
    return cv


def main():
    body = cells(SHEETS['badan'])
    shirt = cells(SHEETS['baju'])
    pants = cells(SHEETS['celana'])
    dirs = len(body)
    combos = [('dasar', False, False), ('+baju', True, False), ('+celana', False, True), ('+keduanya', True, True)]
    cw, ch = 210, 280
    sheet = Image.new('RGB', (cw * dirs, ch * len(combos)), (40, 40, 40))
    for r, (_, sh, pn) in enumerate(combos):
        for d in range(dirs):
            cv = compose(body[d], shirt[d], pants[d], sh, pn)
            cv = cv.resize((cw, ch), Image.LANCZOS)
            sheet.paste(cv.convert('RGB'), (d * cw, r * ch))
    out = '/tmp/layers/uji_8arah.png'
    sheet.save(out)
    print('tulis', out, sheet.size)


if __name__ == '__main__':
    main()
