#!/usr/bin/env python3
"""check-size.py — espejo Python de check-size.sh (para Windows sin bash)."""
from pathlib import Path
WARN = 50*1024*1024; HARD = 100*1024*1024
root = Path(__file__).resolve().parent.parent
fail = False
for f in root.rglob("*"):
    if ".git" in f.parts or not f.is_file():
        continue
    sz = f.stat().st_size
    rel = f.relative_to(root)
    if sz >= HARD:
        print(f"BLOQUEO >100MB: {rel} ({sz})"); fail = True
    elif sz >= WARN:
        print(f"AVISO >50MB: {rel} ({sz})")
print("FAIL" if fail else "OK: ningun archivo supera 100MB")
raise SystemExit(1 if fail else 0)
