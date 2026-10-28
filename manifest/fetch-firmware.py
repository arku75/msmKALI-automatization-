#!/usr/bin/env python3
"""Check the presence of separately supplied kit files; never download or flash."""
import argparse
from pathlib import Path
NEEDED = ["firmware/out/system.img", "firmware/out/vendor.img",
          "firmware/out/boot.img",
          "nethunter/kali-nethunter-rootfs-full-arm64.tar.xz",
          "herramientas/edl-tool/edl.py", "firmware/out/prog_firehose_ddr.elf",
          "recovery/moddedtwrp.img", "uefi/guacamole-uefi.img"]
ap = argparse.ArgumentParser()
ap.add_argument("--src", required=True)
ap.add_argument("--check", action="store_true", help="compatibility flag; this tool only checks files")
a = ap.parse_args()
src = Path(a.src).expanduser()
missing = False
for p in NEEDED:
    f = src / p
    exists = f.is_file()
    missing = missing or not exists
    print(f"{'OK  ' if exists else 'FALTA'} {p}")
print("Presence check only: verify compatibility and trusted checksums separately.")
raise SystemExit(2 if missing else 0)
