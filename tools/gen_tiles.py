#!/usr/bin/env python3
"""Generator tekstur lantai bergaya CGI stylized (Fase 10, standar visual isometrik).

Menghasilkan empat tekstur persegi 128x128 yang dapat diulang mulus (seamless) di dua arah:
rumput, tanah, batu, dan air. Cahaya dari kiri atas, palet natural dan lembut, detail
proporsional terhadap tile 64x32. Hasil ditulis ke game/assets/tiles/.

Pemakaian: python3 tools/gen_tiles.py
Deterministik: seed tetap, sehingga file yang sama dihasilkan setiap kali dijalankan.
"""
import os
import numpy as np
from PIL import Image

SIZE = 128
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "tiles")


def periodic_noise(rng, cells, size=SIZE):
    """Noise nilai periodik: bisa diulang mulus karena grid membungkus (wrap)."""
    grid = rng.random((cells, cells))
    xs = np.arange(size) * cells / size
    ys = np.arange(size) * cells / size
    x0 = np.floor(xs).astype(int)
    y0 = np.floor(ys).astype(int)
    fx = xs - x0
    fy = ys - y0
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    x1 = (x0 + 1) % cells
    y1 = (y0 + 1) % cells
    x0 %= cells
    y0 %= cells
    a = grid[np.ix_(y0, x0)]
    b = grid[np.ix_(y0, x1)]
    c = grid[np.ix_(y1, x0)]
    d = grid[np.ix_(y1, x1)]
    fxg = fx[None, :]
    fyg = fy[:, None]
    top = a * (1 - fxg) + b * fxg
    bot = c * (1 - fxg) + d * fxg
    return top * (1 - fyg) + bot * fyg


def fbm(rng, base_cells=4, octaves=3):
    total = np.zeros((SIZE, SIZE))
    amp = 1.0
    norm = 0.0
    cells = base_cells
    for _ in range(octaves):
        total += amp * periodic_noise(rng, cells)
        norm += amp
        amp *= 0.5
        cells *= 2
    return total / norm


def _rgb(c):
    if isinstance(c, np.ndarray) and c.ndim == 3:
        return c
    return np.asarray(c, dtype=float)[None, None, :]


def mix(base, tint, t):
    return _rgb(base) * (1 - t[..., None]) + _rgb(tint) * t[..., None]


def clamp01(a):
    return np.clip(a, 0.0, 1.0)


def grass(rng):
    n = fbm(rng, 4, 3)
    n2 = fbm(rng, 16, 2)
    img = mix((104, 140, 78), (84, 118, 64), clamp01((n - 0.45) * 2.2))
    img = mix(img, (132, 164, 96), clamp01((n2 - 0.5) * 1.6))
    # Helai rumput kecil yang lembut: pola garis pendek miring, bukan tekstur foto.
    tuft = fbm(rng, 32, 1)
    img = mix(img, (72, 100, 56), clamp01((tuft - 0.6) * 3.0) * 0.6)
    return img


def dirt(rng):
    n = fbm(rng, 4, 3)
    n2 = fbm(rng, 12, 2)
    img = mix((166, 130, 92), (140, 106, 72), clamp01((n - 0.42) * 2.4))
    img = mix(img, (184, 150, 108), clamp01((n2 - 0.5) * 1.8))
    # Kerikil besar dan jarang, sebagai bercak lembut berukuran proporsional.
    pebbles = np.zeros((SIZE, SIZE))
    for _ in range(9):
        cx, cy = rng.integers(0, SIZE, 2)
        r = rng.integers(3, 5)
        yy, xx = np.ogrid[:SIZE, :SIZE]
        for oy in (-SIZE, 0, SIZE):
            for ox in (-SIZE, 0, SIZE):
                dist = np.sqrt((xx - cx - ox) ** 2 + (yy - cy - oy) ** 2)
                pebbles = np.maximum(pebbles, clamp01(1 - dist / r))
    img = mix(img, (120, 92, 62), pebbles * 0.55)
    return img


def stone(rng):
    # Susunan batu persegi-tidak-beraturan dengan sambungan halus, dibentuk dari grid 2x2 periodik.
    img = np.zeros((SIZE, SIZE, 3))
    half = SIZE // 2
    slabs = [(0, 0), (half, 0), (0, half), (half, half)]
    for (sx, sy) in slabs:
        tone = rng.uniform(-10, 10)
        base = np.array([140, 144, 150]) + tone
        patch = fbm(rng, 4, 2)
        yy, xx = np.mgrid[sy:sy + half, sx:sx + half]
        local = patch[sy:sy + half, sx:sx + half]
        col = base[None, None, :] + (local[..., None] - 0.5) * 22
        # Sisi atas-kiri lebih terang (cahaya dari kiri atas), sisi bawah-kanan lebih gelap.
        edge_top = (yy - sy < 2) | (xx - sx < 2)
        edge_bot = (sy + half - yy <= 2) | (sx + half - xx <= 2)
        col = col + edge_top[..., None] * 16 - edge_bot[..., None] * 18
        img[sy:sy + half, sx:sx + half] = col
    # Sambungan (mortar) gelap tipis di garis tengah.
    img[half - 1:half + 1, :] = img[half - 1:half + 1, :] * 0.7
    img[:, half - 1:half + 1] = img[:, half - 1:half + 1] * 0.7
    return img


def water(rng):
    n = fbm(rng, 4, 2)
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    # Riak halus yang diulang periodik (sinus dengan periode penuh).
    ripple = 0.5 + 0.5 * np.sin((xx * 2 * np.pi / SIZE) * 2 + (yy * 2 * np.pi / SIZE) * 3)
    img = mix((70, 128, 166), (96, 154, 190), clamp01((n - 0.4) * 2.0))
    img = mix(img, (120, 176, 206), clamp01((ripple - 0.8) * 2.5) * 0.6)
    return img


def save(name, arr):
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    path = os.path.join(OUT_DIR, name)
    Image.fromarray(arr, "RGB").save(path, optimize=True)
    print("tulis", path, arr.shape)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    save("tile_rumput.png", grass(np.random.default_rng(101)))
    save("tile_tanah.png", dirt(np.random.default_rng(202)))
    save("tile_batu.png", stone(np.random.default_rng(303)))
    save("tile_air.png", water(np.random.default_rng(404)))


if __name__ == "__main__":
    main()
