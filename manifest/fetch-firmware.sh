#!/usr/bin/env bash
# Check a separately supplied kit. No download, installation or device access.
set -euo pipefail
MSMKALI_MANIFEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$MSMKALI_MANIFEST_DIR/fetch-firmware.py" "$@"
