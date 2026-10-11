#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#   fix-mirrors.sh — perbaiki mirror CachyOS yang .sig-nya hilang
#   Gejala: pacman gagal "failed retrieving file 'X.pkg.tar.zst.sig'
#   ... : Maximum file size exceeded" (mirror menyajikan halaman 404).
#   Verifikasi: banyak mirror cachyos-*-v4 TIDAK meng-hosting .sig
#   untuk beberapa paket (mis. vtk, kstatusnotifieritem). Satu-satunya
#   yang melayani lengkap pada saat tes: https://mirror.bali0531.hu
#
#   Jalankan:  bash fix-mirrors.sh
#   Lalu:      bash deploy.sh   (ulangi; idempotent)
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

C_GREEN=$'\033[0;32m'; C_YELLOW=$'\033[0;33m'; C_RED=$'\033[0;31m'; C_RESET=$'\033[0m'
ok()   { printf "%s[✓]%s %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf "%s[!]%s %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
fatal(){ printf "%s[✗]%s %s\n" "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# Mirror yang terbukti menyimpan .sig (GET 200) untuk vtk & kstatusnotifieritem.
GOOD_V4="https://mirror.bali0531.hu/repo/\$arch_v4/\$repo"
GOOD_V3="https://mirror.bali0531.hu/repo/\$arch_v3/\$repo"
GOOD_V="https://mirror.bali0531.hu/repo/\$arch/\$repo"

FILES=(
    /etc/pacman.d/cachyos-mirrorlist
    /etc/pacman.d/cachyos-v3-mirrorlist
    /etc/pacman.d/cachyos-v4-mirrorlist
)

[[ $EUID -ne 0 ]] || fatal "Jangan jalankan sebagai root — sudo dipanggil di dalam script."
sudo -v || fatal "Autentikasi sudo gagal."

for f in "${FILES[@]}"; do
    [[ -f "$f" ]] || { warn "Skip $f (tidak ada)."; continue; }
    case "$f" in
        *v4*) line="$GOOD_V4" ;;
        *v3*) line="$GOOD_V3" ;;
        *)    line="$GOOD_V" ;;
    esac

    bak="${f}.bak-$(date +%Y%m%d-%H%M%S)"
    sudo cp -a "$f" "$bak"
    ok "Backup → $bak"

    tmp="$(mktemp)"
    { echo "$line"; cat "$f"; } > "$tmp"
    sudo cp -a "$tmp" "$f"
    rm -f "$tmp"
    ok "Prepended '$line' → $f"
done

echo
echo "Menyegarkan database paket…"
sudo pacman -Syy

echo
echo "Verifikasi: mirror yang sekarang teratas harus melayani .sig:"
top_mirror=$(grep -m1 '^Server' /etc/pacman.d/cachyos-v4-mirrorlist | sed 's|Server = ||')
url="${top_mirror/\$arch_v4/x86_64_v4}"
url="${url/\$repo/cachyos-extra-v4}"
code=$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 15 \
       "$url/vtk-9.6.2-7.1-x86_64_v4.pkg.tar.zst.sig" 2>/dev/null || true)
if [[ "$code" == "200" ]]; then
    ok "Teratas: $top_mirror → vtk .sig $code (OK)"
    echo
    echo "Lanjutkan dengan:  bash /home/ibnu/Projects/Unit-3-berserk/deploy.sh"
else
    warn "Teratas: $top_mirror → vtk .sig $code (BUKAN 200)"
    echo "File mirrorlist tidak seperti yang diharapkan — periksa kembali."
fi