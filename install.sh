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
    echo "setting up session persistence (tmux-resurrect)…"

    # 1) Plugin (manual install, no TPM). Only tmux-resurrect: save/restore are
    #    driven explicitly (systemd timer + restore.sh); continuum is not used.
    mkdir -p "$HOME/.tmux/plugins"
    d="$HOME/.tmux/plugins/tmux-resurrect"
    if [ -d "$d/.git" ]; then
        git -C "$d" pull --ff-only -q || true
        echo "  updated tmux-resurrect"
    else
        git clone --depth 1 -q "https://github.com/tmux-plugins/tmux-resurrect" "$d"
        echo "  cloned  tmux-resurrect"
    fi

    # 2) ~/.tmux.conf: append a marked block, never overwrite existing config.
    CONF="$HOME/.tmux.conf"
    if grep -qF '# >>> tmux-grid persistence >>>' "$CONF" 2>/dev/null; then
        echo "  persistence block already present in $CONF"
    else
        if [ -s "$CONF" ]; then printf '\n' >> "$CONF"; fi
        cat >> "$CONF" <<'TMUXCONF'
# >>> tmux-grid persistence >>>
# Crash/reboot recovery via tmux-resurrect.
# Saving runs from a systemd user timer (see below); restoring is explicit
# (the login autostart and the tmux-grid launcher call restore.sh).
# tmux-continuum is intentionally not used: its autosave needs the status bar
# tmux-grid hides, and its auto-restore proved unreliable.
set -g @resurrect-capture-pane-contents 'on'
run-shell ~/.tmux/plugins/tmux-resurrect/resurrect.tmux
# <<< tmux-grid persistence <<<
TMUXCONF
        echo "  added persistence block to $CONF"
    fi

    # 3) Headless login autostart: if no tmux server is running, start one and
    #    restore the last saved sessions explicitly.
    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/tmux-grid-restore.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=tmux session restore
Comment=After login, if no tmux server is running, restore the last saved sessions (crash/reboot recovery). Headless — opens no window.
Exec=bash -lc 'tmux ls >/dev/null 2>&1 || { tmux new-session -d -s _tmuxgrid_restore && tmux source-file "$HOME/.tmux.conf" && tmux run-shell "$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh" && sleep 3 && tmux kill-session -t _tmuxgrid_restore 2>/dev/null; }'
Terminal=false
X-GNOME-Autostart-enabled=true
NoDisplay=true
DESK
    echo "  login autostart installed"

    # 4) systemd user timer: the real periodic save. Independent of the status
    # bar (which tmux-grid hides), unlike continuum's own autosave.
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/tmux-resurrect-save.service" <<'SVC'
[Unit]
Description=Save tmux sessions (tmux-resurrect) for crash recovery

[Service]
Type=oneshot
ExecStart=/bin/bash -lc 'tmux run-shell "$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh" 2>/dev/null || true'
SVC
    cat > "$HOME/.config/systemd/user/tmux-resurrect-save.timer" <<'TMR'
[Unit]
Description=Periodically save tmux sessions for crash recovery

[Timer]
OnActiveSec=1min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
TMR
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now tmux-resurrect-save.timer 2>/dev/null || true
    echo "  systemd save timer enabled (every 5 min)"

    echo "  persistence ready: save every 5 min (systemd), explicit restore on login/launcher"
fi

case ":$PATH:" in
    *":$BIN:"*) ;;
    *) echo "NOTE: $BIN is not on your PATH — add it to your shell rc:"
       echo '      export PATH="$HOME/.local/bin:$PATH"' ;;
esac

command -v tmux   >/dev/null || echo "WARNING: tmux not found — install it (e.g. sudo apt install tmux)"
command -v ptyxis >/dev/null || echo "WARNING: ptyxis not found — install it (e.g. sudo apt install ptyxis)"
