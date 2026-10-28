#!/usr/bin/env bash
# check-size.sh — bloquea lo que GitHub bloquearia.
# Limites GitHub 2026: aviso >50MB, bloqueo >100MB/archivo, push max 2GiB,
# repo ideal <1GB (<5GB fuertemente recomendado).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WARN=$((50*1024*1024)); HARD=$((100*1024*1024)); REPO_WARN=$((800*1024*1024))
fail=0
echo "== check-size: $ROOT =="
while IFS= read -r -d '' f; do
  sz=$(stat -c%s "$f"); rel=${f#"$ROOT"/}
  if [ "$sz" -ge "$HARD" ]; then echo "BLOQUEO >100MB: $rel ($sz)"; fail=1;
  elif [ "$sz" -ge "$WARN" ]; then echo "AVISO >50MB: $rel ($sz)"; fi
done < <(find "$ROOT" -path "$ROOT/.git" -prune -o -type f -print0)
total=$(du -sb "$ROOT" | cut -f1)
echo "Total repo (sin .git): $total bytes"
[ "$total" -ge "$REPO_WARN" ] && { echo "AVISO: repo >800MB, GitHub recomienda <1GB"; }
[ "$fail" -eq 0 ] && echo "OK: ningun archivo supera 100MB" || { echo "FAIL: hay archivos bloqueados por GitHub"; exit 1; }
