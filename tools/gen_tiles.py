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
    # Permukaan tenang: variasi frekuensi rendah, tanpa bintik halus yang ramai.
    n = fbm(rng, 3, 2)
    img = mix((112, 150, 86), (96, 136, 74), clamp01((n - 0.45) * 1.6))
    img = mix(img, (130, 166, 98), clamp01((n - 0.55) * 1.2))
    tuft = fbm(rng, 8, 1)
    img = mix(img, (88, 120, 66), clamp01((tuft - 0.7) * 3.0) * 0.5)
    return img


def dirt(rng):
    n = fbm(rng, 3, 2)
    img = mix((180, 142, 102), (160, 124, 88), clamp01((n - 0.45) * 1.8))
    img = mix(img, (192, 156, 116), clamp01((n - 0.6) * 1.5))
    yy, xx = np.ogrid[:SIZE, :SIZE]
    pebbles = np.zeros((SIZE, SIZE))
    for _ in range(6):
        cx, cy = rng.integers(0, SIZE, 2)
        r = 2.5
        for oy in (-SIZE, 0, SIZE):
            for ox in (-SIZE, 0, SIZE):
                dist = np.sqrt((xx - cx - ox) ** 2 + (yy - cy - oy) ** 2)
                pebbles = np.maximum(pebbles, clamp01(1 - dist / r))
    img = mix(img, (150, 116, 80), pebbles * 0.4)
    return img


def stone(rng):
    # Empat lempengan persegi dengan tepi terang-gelap, sambungan tipis, cahaya dari kiri atas.
    half = SIZE // 2
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    img = np.zeros((SIZE, SIZE, 3))
    for (sx, sy) in [(0, 0), (half, 0), (0, half), (half, half)]:
        tone = rng.uniform(-6, 6)
        lx = xx - sx
        ly = yy - sy
        inside = (lx >= 0) & (lx < half) & (ly >= 0) & (ly < half)
        slab = np.broadcast_to(np.array([150, 155, 162], dtype=float) + tone, (SIZE, SIZE, 3))
        img = np.where(inside[..., None], slab, img)
        edge_top = inside & ((lx < 3) | (ly < 3))
        edge_bot = inside & ((lx >= half - 3) | (ly >= half - 3))
        img = np.where(edge_top[..., None], np.array([172, 176, 182]), img)
        img = np.where(edge_bot[..., None], np.array([124, 128, 134]), img)
    seam = (xx % half < 2) | (yy % half < 2)
    img = np.where(seam[..., None], np.array([118, 122, 128], dtype=float), img)
    return img


def water(rng):
    n = fbm(rng, 2, 1)
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    ripple = 0.5 + 0.5 * np.sin((xx + yy) * 2 * np.pi / SIZE)
    img = mix((82, 144, 184), (98, 160, 196), clamp01((n - 0.4) * 1.4))
    img = mix(img, (116, 176, 210), clamp01((ripple - 0.75) * 1.6) * 0.5)
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
