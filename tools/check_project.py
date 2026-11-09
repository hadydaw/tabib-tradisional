#!/usr/bin/env python3
"""Pemeriksaan statis project.godot dan scene (tanpa Godot). Hanya pustaka standar.

Memeriksa: config_version, main_scene ada, orientasi landscape, viewport landscape,
renderer, semua path res:// pada scene/preset ada, dan export_presets.cfg punya preset Android.
Keluar dengan kode 1 jika ada kegagalan.
"""
import re
import sys
from pathlib import Path

GAME = Path(sys.argv[1] if len(sys.argv) > 1 else "game")
LANDSCAPE_ORIENTATIONS = {0, 2, 4}  # landscape, reverse landscape, sensor landscape

errors: list[str] = []
checks = 0


def check(cond: bool, msg: str) -> None:
    global checks
    checks += 1
    print(("  OK    " if cond else "  GAGAL ") + msg)
    if not cond:
        errors.append(msg)


def parse_cfg(path: Path) -> dict[str, dict[str, str]]:
    data: dict[str, dict[str, str]] = {"": {}}
    section = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith(";"):
            continue
        m = re.fullmatch(r"\[(.+)\]", line)
        if m:
            section = m.group(1)
            data.setdefault(section, {})
            continue
        if "=" in line:
            k, v = line.split("=", 1)
            data.setdefault(section, {})[k.strip()] = v.strip()
    return data


def res_to_path(res: str) -> Path:
    return GAME / res.removeprefix("res://")


pg = GAME / "project.godot"
check(pg.is_file(), "project.godot ada")
cfg = parse_cfg(pg)
root = cfg[""]
app = cfg.get("application", {})
disp = cfg.get("display", {})
rend = cfg.get("rendering", {})

check(root.get("config_version") == "5", "config_version = 5 (Godot 4.x)")
check(bool(app.get("config/name")), "application/config/name terisi")
main_scene = app.get("run/main_scene", "").strip('"')
check(main_scene.startswith("res://") and res_to_path(main_scene).is_file(), f"main_scene ada ({main_scene})")
icon = app.get("config/icon", "").strip('"')
check(not icon or res_to_path(icon).is_file(), f"ikon ada ({icon or 'tidak diatur'})")

orient = disp.get("window/handheld/orientation", "")
check(orient.isdigit() and int(orient) in LANDSCAPE_ORIENTATIONS, f"orientasi landscape (nilai {orient})")
w = disp.get("window/size/viewport_width", "0")
h = disp.get("window/size/viewport_height", "0")
check(w.isdigit() and h.isdigit() and int(w) > int(h) > 0, f"viewport landscape ({w}x{h})")
check(rend.get("renderer/rendering_method", "").strip('"') in {"gl_compatibility", "mobile"}, "renderer valid")
check(rend.get("textures/vram_compression/import_etc2_astc") == "true", "kompresi ETC2/ASTC aktif (wajib untuk ekspor Android)")

# Semua ext_resource di scene menunjuk berkas yang ada
for scene in sorted(GAME.rglob("*.tscn")):
    text = scene.read_text(encoding="utf-8")
    for res in re.findall(r'path="(res://[^"]+)"', text):
        check(res_to_path(res).is_file(), f"{scene.relative_to(GAME)} -> {res}")

# Preset ekspor
ep = GAME / "export_presets.cfg"
check(ep.is_file(), "export_presets.cfg ada")
if ep.is_file():
    ecfg = parse_cfg(ep)
    presets = [s for s in ecfg if re.fullmatch(r"preset\.\d+", s)]
    android = [s for s in presets if ecfg[s].get("platform", "").strip('"') == "Android"]
    check(bool(android), "ada preset Android")
    for s in android:
        opts = ecfg.get(s + ".options", {})
        check(opts.get("architectures/arm64-v8a") == "true", f"{s}: arm64-v8a aktif")
        check(bool(opts.get("package/unique_name", "").strip('"')), f"{s}: package/unique_name terisi")

print(f"\nPemeriksaan: {checks}, gagal: {len(errors)}")
sys.exit(1 if errors else 0)
