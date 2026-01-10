#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Dotfiles dir: $DOTFILES_DIR"

# 1) Pacman packages (core rice)
if [[ -f "$DOTFILES_DIR/packages/core.txt" ]]; then
  echo "==> Installing pacman packages from packages/core.txt"
  sudo pacman -Syu --needed --noconfirm $(grep -vE '^\s*#|^\s*$' "$DOTFILES_DIR/packages/core.txt")
else
  echo "!! Missing packages/core.txt"
  exit 1
fi

# 2) AUR helper (yay) if needed
if [[ -f "$DOTFILES_DIR/packages/aur.txt" ]] && grep -qvE '^\s*#|^\s*$' "$DOTFILES_DIR/packages/aur.txt"; then
  if ! command -v yay >/dev/null 2>&1; then
    echo "==> yay not found. Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
  fi

  echo "==> Installing AUR packages from packages/aur.txt"
  yay -S --needed --noconfirm $(grep -vE '^\s*#|^\s*$' "$DOTFILES_DIR/packages/aur.txt")
fi

# 3) Symlinks with backup
backup_dir="$HOME/.config.backup.$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

echo "==> Symlinking .config"
mkdir -p "$HOME/.config"
for src in "$DOTFILES_DIR/.config/"*; do
  name="$(basename "$src")"
  dest="$HOME/.config/$name"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "   - Backing up existing $dest -> $backup_dir/"
    mv "$dest" "$backup_dir/"
  fi

  ln -sfn "$src" "$dest"
done

echo "==> Symlinking .local/bin"
mkdir -p "$HOME/.local/bin"
if compgen -G "$DOTFILES_DIR/.local/bin/*" > /dev/null; then
  for src in "$DOTFILES_DIR/.local/bin/"*; do
    ln -sfn "$src" "$HOME/.local/bin/$(basename "$src")"
  done
fi

echo "==> Done. Backup (if any): $backup_dir"
echo "==> You may want to reboot or relogin."
