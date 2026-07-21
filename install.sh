#!/usr/bin/env bash
# install.sh — install tmux-grid on any Linux system.
#
# Symlinks the launcher into ~/.local/bin so the repo checkout stays the
# single source of truth: editing the script in the repo (or `git pull`ing
# it) takes effect immediately, with no reinstall. Also writes a GNOME
# desktop entry into ~/.local/share/applications with the correct path.
#
# Requirements: tmux and Ptyxis (GNOME's terminal, ptyxis(1)). Install with
# your package manager, e.g.  sudo apt install tmux ptyxis

set -euo pipefail

BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
SRC="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$BIN" "$APPS"

# Symlink, not copy: the repo checkout is the single source of truth.
ln -sfn "$SRC/tmux-grid" "$BIN/tmux-grid"

# Write the desktop entry with an absolute Exec path (.desktop does not
# expand ~ or $HOME).
cat > "$APPS/tmux-grid.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Tmux Grid
Comment=Open a 2x2 tmux grid of terminals in Ptyxis
Exec=$BIN/tmux-grid
Icon=utilities-terminal
Terminal=false
Categories=Utility;TerminalEmulator;
EOF

echo "tmux-grid symlinked: $BIN/tmux-grid -> $SRC/tmux-grid"
echo "desktop entry written: $APPS/tmux-grid.desktop"

case ":$PATH:" in
    *":$BIN:"*) ;;
    *) echo "NOTE: $BIN is not on your PATH — add it to your shell rc:"
       echo '      export PATH="$HOME/.local/bin:$PATH"' ;;
esac

command -v tmux   >/dev/null || echo "WARNING: tmux not found — install it (e.g. sudo apt install tmux)"
command -v ptyxis >/dev/null || echo "WARNING: ptyxis not found — install it (e.g. sudo apt install ptyxis)"
