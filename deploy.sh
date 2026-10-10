#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#   deploy.sh — Unit-3 "Berserk" local installer (no clone needed)
#   Paket dari repo (quickshell & awww sudah tersedia di repo CachyOS),
#   config di-deploy dari ./config (sudah di-retheme varian ink).
#   Jalankan dengan terminal biasa:  bash deploy.sh
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$ROOT/config"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.config-backup-berserk-$(date +%Y%m%d-%H%M%S)"
MANAGED_DIRS=(hypr quickshell waybar kitty)
PRESERVED_FILES=(hypr/user.lua quickshell/settings/Settings.qml)
PRESERVED_STASH=""

# ─── Logging ───────────────────────────────────────────────────────
C_GREEN=$'\033[0;32m'; C_YELLOW=$'\033[0;33m'; C_BLUE=$'\033[0;34m'
C_RED=$'\033[0;31m'; C_BOLD=$'\033[1m'; C_RESET=$'\033[0m'
log()  { printf "%s[*]%s %s\n" "$C_BLUE"  "$C_RESET" "$*"; }
ok()   { printf "%s[✓]%s %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf "%s[!]%s %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
err()  { printf "%s[✗]%s %s\n" "$C_RED"   "$C_RESET" "$*" >&2; }
fatal(){ err "$*"; exit 1; }

cleanup() { [[ -n "$PRESERVED_STASH" && -d "$PRESERVED_STASH" ]] && rm -rf "$PRESERVED_STASH"; }
trap cleanup EXIT

# ─── Pre-flight ────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] || fatal "Jangan jalankan sebagai root — jalankan sebagai user biasa (sudo dipanggil otomatis)."
command -v pacman >/dev/null || fatal "pacman tidak ditemukan — script khusus Arch/CachyOS."
command -v sudo   >/dev/null || fatal "sudo diperlukan."
log "Minta password sudo sekali di awal (untuk seluruh sesi)…"
sudo -v || fatal "Autentikasi sudo gagal."

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    warn "Anda sedang BERADA di dalam sesi Hyprland aktif!"
    warn "SEBAIKNYA: pindah dulu ke TTY (Ctrl+Alt+F2), login, baru jalankan\n  bash /home/ibnu/Projects/Unit-3-berserk/deploy.sh"
    warn "Config baru akan aktif setelah logout & login ulang ke Hyprland."
fi

# ─── 1. Paket ──────────────────────────────────────────────────────
install_packages() {
    log "Menginstall paket dari repo…"
    local pkgs
    mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$ROOT/packages/pacman.txt")
    # quickshell & awww sudah ada di repo CachyOS (tidak perlu build AUR lama)
    pkgs+=(quickshell awww)
    sudo pacman -S --needed --noconfirm "${pkgs[@]}"

    log "AUR: pamtester (dibutuhkan lockscreen qs-lock)…"
    local helper="" 
    command -v paru >/dev/null && helper=paru
    command -v yay  >/dev/null && helper=yay
    if [[ -n "$helper" ]]; then
        "$helper" -S --needed --noconfirm pamtester
    else
        warn "Tidak ada paru/yay — melewatkan pamtester (lockscreen akan gagal validasi password)."
    fi

    command -v qs >/dev/null || warn "/usr/bin/qs tidak ditemukan — cek paket quickshell."
    command -v awww >/dev/null || warn "awww tidak ditemukan — cek paket awww."
    ok "Paket selesai."
}

# ─── 2. Config ─────────────────────────────────────────────────────
stash_preserved() {
    PRESERVED_STASH=$(mktemp -d)
    for rel in "${PRESERVED_FILES[@]}"; do
        if [[ -f "$CONFIG_HOME/$rel" ]]; then
            local stash="$PRESERVED_STASH/$rel"
            mkdir -p "$(dirname "$stash")"
            cp -a "$CONFIG_HOME/$rel" "$stash"
            ok "Melindungi file user: $rel"
        fi
    done
}

restore_preserved() {
    for rel in "${PRESERVED_FILES[@]}"; do
        if [[ -f "$PRESERVED_STASH/$rel" ]]; then
            mkdir -p "$(dirname "$CONFIG_HOME/$rel")"
            cp -a "$PRESERVED_STASH/$rel" "$CONFIG_HOME/$rel"
            ok "Mengembalikan file user: $rel"
        fi
    done
}

deploy_configs() {
    mkdir -p "$CONFIG_HOME"
    stash_preserved

    for name in "${MANAGED_DIRS[@]}"; do
        local src="$CONFIG_SRC/$name"
        local dest="$CONFIG_HOME/$name"
        [[ -d "$src" ]] || { warn "Skipping $name (tidak ada di repo)."; continue; }
        if [[ -e "$dest" ]]; then
            mkdir -p "$BACKUP_DIR"
            log "Backup $dest → $BACKUP_DIR/$name"
            mv "$dest" "$BACKUP_DIR/$name"
        fi
        cp -r "$src" "$dest"
        ok "Deploy config: $name"
    done

    restore_preserved

    # user.lua template kalau belum ada (mis. bersih)
    if [[ ! -f "$CONFIG_HOME/hypr/user.lua" ]]; then
        cp "$CONFIG_SRC/hypr/user.lua" "$CONFIG_HOME/hypr/user.lua"
        ok "Buat hypr/user.lua (template override pribadi)."
    else
        ok "hypr/user.lua dipertahankan."
    fi

    # fish: conf.d fastfetch (opsional, hanya jika fastfetch terpasang)
    if [[ -d "$CONFIG_SRC/fish/conf.d" ]]; then
        mkdir -p "$CONFIG_HOME/fish/conf.d"
        cp -n "$CONFIG_SRC/fish/conf.d/"* "$CONFIG_HOME/fish/conf.d/" 2>/dev/null || true
        ok "fish conf.d ditambahkan (fastfetch, opsional)."
    fi

    log "chmod +x untuk script…"
    find "$CONFIG_HOME/hypr" "$CONFIG_HOME/quickshell" "$CONFIG_HOME/waybar" \
        -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true
    ok "Config berserk terpasang."
}

# ─── 3. PAM ────────────────────────────────────────────────────────
deploy_pam() {
    local pam_src="$CONFIG_SRC/system/pam.d"
    [[ -d "$pam_src" ]] || { warn "Tidak ada config system."; return; }
    for f in "$pam_src"/*; do
        [[ -f "$f" ]] || continue
        sudo install -D -m 644 "$f" "/etc/pam.d/$(basename "$f")"
        ok "PAM: /etc/pam.d/$(basename "$f")"
    done
}

# ─── 4. .bashrc ────────────────────────────────────────────────────
deploy_bashrc() {
    local src="$CONFIG_SRC/bash/.bashrc"
    [[ -f "$src" ]] || { warn "Tidak ada .bashrc di repo."; return; }
    if [[ -f "$HOME/.bashrc" ]] && ! grep -q "Unit-3 default .bashrc" "$HOME/.bashrc"; then
        mkdir -p "$BACKUP_DIR"
        cp "$HOME/.bashrc" "$BACKUP_DIR/.bashrc"
        log "Backup ~/.bashrc lama."
    fi
    cp "$src" "$HOME/.bashrc"
    ok ".bashrc terpasang (banner NieR + prompt berserk)."
    if [[ ! -f "$HOME/.bashrc.local" ]]; then
        cat > "$HOME/.bashrc.local" <<'OVR'
# Unit-3 user overrides — never touched by updates.
# Contoh:
#   alias ll='ls -la'
#   export EDITOR=nano
OVR
        ok "Buat ~/.bashrc.local kosong."
    fi
}

# ─── 5. Wallpaper & Screenshots ────────────────────────────────────
setup_dirs() {
    mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Screenshots"
    if [[ -d "$ROOT/assets/wallpapers" ]]; then
        cp -n "$ROOT/assets/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
        ok "Wallpaper default (4) → ~/Pictures/wallpapers"
    fi
}

# ─── 6. qshare symlink ─────────────────────────────────────────────
deploy_qshare() {
    local script="$CONFIG_HOME/quickshell/scripts/qshare.py"
    [[ -f "$script" ]] || { warn "qshare.py tidak ada."; return; }
    mkdir -p "$HOME/.local/bin"
    rm -f "$HOME/.local/bin/qshare"
    ln -s "$script" "$HOME/.local/bin/qshare"
    ok "qshare CLI → ~/.local/bin/qshare"
    if ! echo "$PATH" | tr ':' '\n' | grep -qFx "$HOME/.local/bin"; then
        warn "~/.local/bin belum di PATH — tambahkan di ~/.bashrc.local:"
        warn '  export PATH="$HOME/.local/bin:$PATH"'
    fi
}

# ─── 7. Services ───────────────────────────────────────────────────
enable_services() {
    log "Enable services…"
    sudo systemctl enable --now NetworkManager.service 2>/dev/null || warn "NetworkManager: skip."
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null \
        || warn "pipewire user service: skip (boleh di-start dari sesi)."
    ok "Services OK."
}

# ─── 8. Ringkasan ──────────────────────────────────────────────────
summary() {
    echo
    ok "${C_BOLD}Selesai!${C_RESET}"
    [[ -d "$BACKUP_DIR" ]] && echo "  Backup config lama: $BACKUP_DIR"
    echo
    echo "  ${C_BOLD}Langkah berikut:${C_RESET}"
    echo "  1. Logout Hyprland / reboot, lalu login ke Hyprland — config lua berserk akan aktif."
    echo "  2. Pilih wallpaper: SUPER + P (WallpaperPicker). "
    echo "  3. Override pribadi: ~/.config/hypr/user.lua dan ~/.bashrc.local"
    echo
    echo "  ${C_BOLD}Catatan quickshell:${C_RESET}"
    echo "  Base fork ini menjalankan qs dengan software GL (llvmpipe) di hyprland.lua baris 12."
    echo "  Punya GPU nyata? Ganti baris itu menjadi:"
    echo '    hl.exec_cmd("env QT_MEDIA_BACKEND=ffmpeg qs")'
    echo "  Kalau quickshell repo bermasalah, fallback: paru -S quickshell-git"
    echo
}

main() {
    log "Unit-3 Berserk deploy dimulai…"
    install_packages
    deploy_configs
    deploy_pam
    deploy_bashrc
    setup_dirs
    deploy_qshare
    enable_services
    summary
}

main "$@"