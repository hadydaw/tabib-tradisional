#!/usr/bin/env python3
"""Periksa kompatibilitas APK terhadap profil perangkat uji utama (hanya pustaka standar).

Perangkat utama: nubia Neo 2 5G (Z2352N), Android 13 (API 33), Unisoc T820 (arm64), landscape.
Ini pemeriksaan STATIS pada manifest dan isi APK. Hasil lolos TIDAK berarti aplikasi sudah
berjalan benar di perangkat; itu hanya bisa dibuktikan dengan uji di perangkat.

Pemakaian:
  check_apk_compat.py <apk> <path aapt2>   periksa APK (butuh aapt2 dari Android build-tools)
  check_apk_compat.py --selftest           uji parser dengan contoh keluaran aapt2
"""
import json
import re
import subprocess
import sys

DEVICE = {
    "name": "nubia Neo 2 5G (Z2352N)",
    "api": 33,  # Android 13
    "abi": ["arm64-v8a"],
    "min_gles": 0x30000,
}
LANDSCAPE = {0: "landscape", 6: "sensorLandscape", 8: "reverseLandscape", 11: "userLandscape"}
# Izin yang umum ada pada template Godot; selain ini ditandai untuk ditinjau (bukan gagal).
EXPECTED_PERMISSIONS = {"android.permission.INTERNET"}


def parse(badging: str, xmltree: str) -> dict:
    def first_int(pattern: str, text: str):
        m = re.search(pattern, text)
        return int(m.group(1)) if m else None

    native = re.search(r"native-code: ((?:'[^']+'\s*)+)", badging)
    gles = re.search(r"glEsVersion[^=]*=0x([0-9a-fA-F]+)", xmltree)
    return {
        "package": (re.search(r"package: name='([^']+)'", badging) or [None, None])[1],
        "version_code": first_int(r"versionCode='(\d+)'", badging),
        "min_sdk": first_int(r"minSdkVersion:'(\d+)'", badging),
        "target_sdk": first_int(r"targetSdkVersion:'(\d+)'", badging),
        "abis": re.findall(r"'([^']+)'", native.group(1)) if native else [],
        "orientation": first_int(r"screenOrientation\(0x[0-9a-fA-F]+\)=(\d+)", xmltree),
        "gles": int(gles.group(1), 16) if gles else None,
        "permissions": sorted(set(re.findall(r"uses-permission: name='([^']+)'", badging))),
    }


def evaluate(info: dict) -> tuple[list[tuple[bool, str]], list[str]]:
    checks: list[tuple[bool, str]] = []
    warnings: list[str] = []
    mn, tg = info["min_sdk"], info["target_sdk"]
    checks.append((mn is not None and mn <= DEVICE["api"], f"minSdk {mn} <= API perangkat {DEVICE['api']} (Android 13)"))
    checks.append((tg is not None and tg >= DEVICE["api"], f"targetSdk {tg} >= API perangkat {DEVICE['api']}"))
    checks.append((info["abis"] == DEVICE["abi"], f"ABI {info['abis']} sama dengan {DEVICE['abi']} (arm64 saja)"))
    ori = info["orientation"]
    checks.append((ori in LANDSCAPE, f"orientasi manifest = {ori} ({LANDSCAPE.get(ori, 'BUKAN landscape')})"))
    gl = info["gles"]
    checks.append((gl is not None and gl >= DEVICE["min_gles"], f"glEsVersion {hex(gl) if gl else None} >= 0x30000 (OpenGL ES 3.0)"))
    for p in info["permissions"]:
        if p not in EXPECTED_PERMISSIONS:
            warnings.append(f"izin tidak terduga: {p}")
    return checks, warnings


SAMPLE_BADGING = """package: name='com.hadydaw.tabibtradisional.debug' versionCode='8' versionName='0.1.0-fase1' compileSdkVersion='36'
minSdkVersion:'24'
targetSdkVersion:'36'
uses-permission: name='android.permission.INTERNET'
application-label:'Tabib Tradisional (debug)'
native-code: 'arm64-v8a'
"""
SAMPLE_XML = """        A: http://schemas.android.com/apk/res/android:glEsVersion(0x01010281)=0x00030000
            A: http://schemas.android.com/apk/res/android:screenOrientation(0x0101001e)=11
"""


def selftest() -> int:
    info = parse(SAMPLE_BADGING, SAMPLE_XML)
    expected = {"package": "com.hadydaw.tabibtradisional.debug", "version_code": 8, "min_sdk": 24,
                "target_sdk": 36, "abis": ["arm64-v8a"], "orientation": 11, "gles": 0x30000,
                "permissions": ["android.permission.INTERNET"]}
    ok = info == expected
    checks, warnings = evaluate(info)
    ok = ok and all(c for c, _ in checks) and not warnings
    bad = parse(SAMPLE_BADGING.replace("'arm64-v8a'", "'arm64-v8a' 'x86_64'"), SAMPLE_XML.replace("=11", "=1"))
    bad_checks, _ = evaluate(bad)
    ok = ok and sum(1 for c, _ in bad_checks if not c) == 2  # ABI dan orientasi harus gagal
    print("selftest:", "LOLOS" if ok else "GAGAL", info if not ok else "")
    return 0 if ok else 1


def run(aapt2: str, *args: str) -> str:
    return subprocess.run([aapt2, *args], capture_output=True, text=True).stdout


def main() -> int:
    if len(sys.argv) == 2 and sys.argv[1] == "--selftest":
        return selftest()
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    apk, aapt2 = sys.argv[1], sys.argv[2]
    badging = run(aapt2, "dump", "badging", apk)
    xmltree = run(aapt2, "dump", "xmltree", "--file", "AndroidManifest.xml", apk)
    info = parse(badging, xmltree)
    checks, warnings = evaluate(info)
    print(f"Profil perangkat uji: {DEVICE['name']}, API {DEVICE['api']}, {', '.join(DEVICE['abi'])}")
    print(f"APK: {info['package']} versionCode {info['version_code']}")
    for ok, msg in checks:
        print(("  OK    " if ok else "  GAGAL ") + msg)
    for w in warnings:
        print("  PERINGATAN " + w)
    print("  Izin:", ", ".join(info["permissions"]) or "(tidak ada)")
    failed = [m for ok, m in checks if not ok]
    print(f"\nKompatibilitas statis: {'LOLOS' if not failed else 'GAGAL'} ({len(checks) - len(failed)}/{len(checks)}). "
          "Ini BUKAN uji di perangkat.")
    try:
        with open("build/logs/compat.json", "w", encoding="utf-8") as f:
            json.dump({"device": DEVICE, "apk": info, "failed": failed, "warnings": warnings}, f, indent=2)
    except OSError:
        pass
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
