#!/usr/bin/env python3
"""msmkali.py — dispatcher multiplataforma (ES/EN) para msmKALI.

No duplica la logica del .sh: lo llama. Aporta:
  --lang es|en, --check (solo diagnostico), --list, comandos directos.
Uso:
  python3 scripts/msmkali.py --lang es
  python3 scripts/msmkali.py --check
  python3 scripts/msmkali.py rescue --slot ambos --image /ruta/boot.img
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
I18N = ROOT / "i18n"
SCRIPTS = ROOT / "scripts"


def t(lang: str) -> dict:
    fp = I18N / f"{lang}.json"
    if not fp.exists():
        fp = I18N / "es.json"
    return json.loads(fp.read_text(encoding="utf-8"))


def sh(cmd: list[str], check=False) -> int:
    print(f"$ {' '.join(cmd)}")
    try:
        r = subprocess.run(cmd)
        return r.returncode
    except FileNotFoundError:
        print(f"missing: {cmd[0]}")
        return 127


def do_check(lang: str) -> int:
    s = t(lang)
    print(f"== {s['menu_title']} ==")
    tools = ["adb", "fastboot", "python3", "lsusb"]
    ok_all = True
    for tool in tools:
        found = shutil.which(tool) is not None
        print(f"  {'OK ' if found else 'FALTA/MISSING '} {tool}")
        ok_all = ok_all and found
    kit = os.environ.get("MSMKALI_KIT_DIR")
    edl = Path(kit) / "herramientas" / "edl-tool" / "edl.py" if kit else None
    if not kit:
        print("  (..) MSMKALI_KIT_DIR is not configured; device actions require your own local kit.")
    if edl is None or not edl.is_file():
        print(f"  (..) {s['msg_no_edl']}")
    print(f"  (..) {s['msg_need_linux']}")
    return 0 if ok_all else 2


def menu(lang: str) -> int:
    s = t(lang)
    print(f"\n{s['menu_title']}\n{s['menu_subtitle']}")
    print(f"  [!] {s['warn_irreversible']}\n")
    opts = [
        ("1", s["opt_status"]),
        ("2", s["opt_backup"]),
        ("3", s["opt_verify"]),
        ("4", s["opt_edl"]),
        ("5", s["opt_rescue"]),
        ("6", s["opt_flash"]),
        ("7", s["opt_doctor"]),
        ("8", s["opt_usb"]),
        ("9", s["opt_graph"]),
        ("0", s["msg_bye"]),
    ]
    for k, v in opts:
        print(f"   {k}) {v}")
    try:
        c = input(f"\n{s['prompt_choice']} [0-9]: ").strip()
    except (EOFError, KeyboardInterrupt):
        print(f"\n{s['msg_bye']}")
        return 0
    main_sh = SCRIPTS / "msmkali.sh"
    if c == "0":
        print(s["msg_bye"])
        return 0
    if c == "5":
        rescue = SCRIPTS / "rescate_edl.sh"
        return sh(["bash", str(rescue)])
    if c == "9":
        gen = ROOT / "grapo-lite" / "generate_graph.py"
        target = ROOT
        return sh([sys.executable, str(gen), str(target)])
    if c in {"1", "2", "3", "4", "6", "7", "8"}:
        bash_option = {"1": "1", "2": "2", "3": "3", "4": "4", "6": "6", "7": "19", "8": "21"}[c]
        print(f"-> delegando al menu bash ({main_sh}). Elige alli la opcion {bash_option}.")
        return sh(["bash", str(main_sh)])
    print(s["msg_bye"])
    return 1


def main() -> int:
    ap = argparse.ArgumentParser(description="msmKALI dispatcher (es/en)")
    ap.add_argument("--lang", default="es", choices=["es", "en"])
    ap.add_argument("--check", action="store_true", help="solo diagnostico")
    ap.add_argument("--list", action="store_true", help="lista scripts incluidos")
    ap.add_argument("cmd", nargs="?", default="menu",
                    choices=["menu", "check", "rescue", "graph", "doctor"])
    ap.add_argument("--slot", default="ambos", choices=["a", "b", "ambos"])
    ap.add_argument("--image", default="")
    a = ap.parse_args()
    if a.list:
        for p in sorted(SCRIPTS.glob("*.sh")) + sorted(SCRIPTS.glob("*.py")):
            print(p.name)
        return 0
    if a.check or a.cmd == "check":
        return do_check(a.lang)
    if a.cmd == "rescue":
        cmd = ["bash", str(SCRIPTS / "rescate_edl.sh")]
        if a.image:
            cmd += [a.image, a.slot]
        return sh(cmd)
    if a.cmd == "graph":
        return sh([sys.executable, str(ROOT / "grapo-lite" / "generate_graph.py"), str(ROOT)])
    if a.cmd == "doctor":
        print("The NetHunter helpers run inside your own Android/NetHunter environment, not on this PC.")
        print("Read docs/PUBLIC_SOURCE_GUIDE.md before installing or running scripts/nh-doctor.")
        return 2
    return menu(a.lang)


if __name__ == "__main__":
    raise SystemExit(main())
