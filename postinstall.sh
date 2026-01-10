#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

# 1) ensure ~/.local/bin in PATH (fish + bash)
log "Ensuring ~/.local/bin is in PATH"

mkdir -p "$HOME/.config/fish/conf.d"
cat > "$HOME/.config/fish/conf.d/10-local-bin.fish" <<'FISH'
if not contains -- ~/.local/bin $PATH
  set -gx PATH ~/.local/bin $PATH
end
FISH

# 2) wallpapers
if [[ -d "$HOME/dotfiles/wallpapers" ]]; then
  mkdir -p "$HOME/Pictures/Wallpapers"
  cp -n "$HOME/dotfiles/wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
fi

# 3) enable useful services (ignore errors if not present)
log "Enabling user services (best effort)"
systemctl --user daemon-reload || true
systemctl --user enable --now swayosd.service 2>/dev/null || true

log "Post-install done. Re-login recommended."
