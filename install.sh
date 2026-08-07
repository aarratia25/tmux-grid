#!/usr/bin/env bash
# install.sh — install tmux-grid on any Linux system.
#
# Usage:
#   ./install.sh              install the launcher + desktop entry
#   ./install.sh --persist    ALSO set up crash/reboot session persistence:
#                             tmux-resurrect + tmux-continuum with autosave
#                             every 5 min and auto-restore when tmux starts.
#                             This installs two tmux plugins under
#                             ~/.tmux/plugins, appends a marked block to
#                             ~/.tmux.conf, and adds a headless login autostart.
#
# The launcher is SYMLINKED into ~/.local/bin so the repo checkout stays the
# single source of truth: editing the script in the repo (or `git pull`ing it)
# takes effect immediately, with no reinstall.
#
# Requirements: tmux and Ptyxis (GNOME's terminal, ptyxis(1)). Install with
# your package manager, e.g.  sudo apt install tmux ptyxis

set -euo pipefail

PERSIST=0
[ "${1:-}" = "--persist" ] && PERSIST=1

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

if [ "$PERSIST" = "1" ]; then
    echo "setting up session persistence (tmux-resurrect + tmux-continuum)…"

    # 1) Plugins (manual install, no TPM).
    mkdir -p "$HOME/.tmux/plugins"
    for p in tmux-resurrect tmux-continuum; do
        d="$HOME/.tmux/plugins/$p"
        if [ -d "$d/.git" ]; then
            git -C "$d" pull --ff-only -q || true
            echo "  updated $p"
        else
            git clone --depth 1 -q "https://github.com/tmux-plugins/$p" "$d"
            echo "  cloned  $p"
        fi
    done

    # 2) ~/.tmux.conf: append a marked block, never overwrite existing config.
    CONF="$HOME/.tmux.conf"
    if grep -qF '# >>> tmux-grid persistence >>>' "$CONF" 2>/dev/null; then
        echo "  persistence block already present in $CONF"
    else
        if [ -s "$CONF" ]; then printf '\n' >> "$CONF"; fi
        cat >> "$CONF" <<'TMUXCONF'
# >>> tmux-grid persistence >>>
# Crash/reboot recovery via tmux-resurrect + tmux-continuum.
# Options must precede the run-shell lines so the plugins read them on load.
set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-save-interval '5'
set -g @continuum-restore 'on'
run-shell ~/.tmux/plugins/tmux-resurrect/resurrect.tmux
run-shell ~/.tmux/plugins/tmux-continuum/continuum.tmux
# <<< tmux-grid persistence <<<
TMUXCONF
        echo "  added persistence block to $CONF"
    fi

    # 3) Headless login autostart: start the tmux server so continuum restores.
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/tmux-grid-restore.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=tmux session restore
Comment=Start the tmux server at login so tmux-continuum restores saved sessions (crash/reboot recovery). Headless — opens no window.
Exec=bash -lc "tmux start-server"
Terminal=false
X-GNOME-Autostart-enabled=true
NoDisplay=true
DESK
    echo "  login autostart installed"
    echo "  persistence ready: autosave every 5 min, auto-restore on tmux start"
fi

case ":$PATH:" in
    *":$BIN:"*) ;;
    *) echo "NOTE: $BIN is not on your PATH — add it to your shell rc:"
       echo '      export PATH="$HOME/.local/bin:$PATH"' ;;
esac

command -v tmux   >/dev/null || echo "WARNING: tmux not found — install it (e.g. sudo apt install tmux)"
command -v ptyxis >/dev/null || echo "WARNING: ptyxis not found — install it (e.g. sudo apt install ptyxis)"
