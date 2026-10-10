#!/usr/bin/env bash
# Terapkan tema berserk ke config Unit-3. Usage: ./retheme.sh [ink|blood|paper]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIANT="${1:-ink}"
python3 "$SCRIPT_DIR/retheme.py" "$VARIANT"
