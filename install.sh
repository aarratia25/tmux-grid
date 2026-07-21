#!/usr/bin/env bash
# install.sh — install claude-grid on any Linux system.
#
# Copies the launcher into ~/.local/bin and writes a GNOME desktop entry
# into ~/.local/share/applications with the correct absolute path.
#
# Requirements: tmux and Ptyxis (GNOME's terminal, ptyxis(1)). Install with
# your package manager, e.g.  sudo apt install tmux ptyxis

set -euo pipefail

BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
SRC="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$BIN" "$APPS"
install -m 0755 "$SRC/claude-grid" "$BIN/claude-grid"

# Write the desktop entry with an absolute Exec path (.desktop does not
# expand ~ or $HOME).
cat > "$APPS/claude-grid.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Claude Grid
Comment=Open the 2x2 tmux grid of terminals in Ptyxis
Exec=$BIN/claude-grid
Icon=utilities-terminal
Terminal=false
Categories=Utility;TerminalEmulator;
EOF

echo "claude-grid installed to $BIN/claude-grid"
echo "desktop entry written to $APPS/claude-grid.desktop"

case ":$PATH:" in
    *":$BIN:"*) ;;
    *) echo "NOTE: $BIN is not on your PATH — add it to your shell rc:"
       echo '      export PATH="$HOME/.local/bin:$PATH"' ;;
esac

command -v tmux   >/dev/null || echo "WARNING: tmux not found — install it (e.g. sudo apt install tmux)"
command -v ptyxis >/dev/null || echo "WARNING: ptyxis not found — install it (e.g. sudo apt install ptyxis)"
