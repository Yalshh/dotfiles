#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf "\n==> %s\n" "$*"; }
warn() { printf "\n!! %s\n" "$*" >&2; }

log "Dotfiles dir: $DOTFILES_DIR"

# 0) sanity
if [[ ! -d "$DOTFILES_DIR/.config" ]]; then
  warn "Missing $DOTFILES_DIR/.config"
  exit 1
fi

# 1) pacman packages
if [[ -f "$DOTFILES_DIR/packages/core.txt" ]]; then
  log "Installing pacman packages from packages/core.txt"
  sudo pacman -Syu --needed --noconfirm $(grep -vE '^\s*#|^\s*$' "$DOTFILES_DIR/packages/core.txt")
else
  warn "Missing packages/core.txt"
  exit 1
fi

# 2) yay + AUR (optional)
if [[ -f "$DOTFILES_DIR/packages/aur.txt" ]] && grep -qvE '^\s*#|^\s*$' "$DOTFILES_DIR/packages/aur.txt"; then
  if ! command -v yay >/dev/null 2>&1; then
    log "yay not found. Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
  fi

  log "Installing AUR packages from packages/aur.txt"
  yay -S --needed --noconfirm $(grep -vE '^\s*#|^\s*$' "$DOTFILES_DIR/packages/aur.txt")
fi

# 3) backup + symlinks
backup_dir="$HOME/.config.backup.$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

log "Symlinking ~/.config/*"
mkdir -p "$HOME/.config"
for src in "$DOTFILES_DIR/.config/"*; do
  name="$(basename "$src")"
  dest="$HOME/.config/$name"

  # if there's a real dir/file already, back it up
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    log "Backing up existing $dest -> $backup_dir/"
    mv "$dest" "$backup_dir/"
  fi

  ln -sfn "$src" "$dest"
done

log "Symlinking ~/.local/bin/*"
mkdir -p "$HOME/.local/bin"
if compgen -G "$DOTFILES_DIR/.local/bin/*" > /dev/null; then
  for src in "$DOTFILES_DIR/.local/bin/"*; do
    ln -sfn "$src" "$HOME/.local/bin/$(basename "$src")"
  done
fi

log "Done. Backup (if any): $backup_dir"
log "Next: run ./postinstall.sh and relog/reboot"