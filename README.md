# claude-grid

Open a single terminal window split into a **2×2 grid of 4 independent
shells** with one command — instead of arranging four separate windows by
hand every time.

Built for **Wayland/GNOME**, where scripting the position of real windows is
not possible: `claude-grid` puts four [tmux](https://github.com/tmux/tmux)
panes inside one [Ptyxis](https://gitlab.gnome.org/chergert/ptyxis) window, so
the layout is deterministic and survives closing the launching terminal.

All four panes start in `~/proj` (edit `START_DIR` in the script to change
that); you `cd` into whatever you want and run whatever you want per pane.

## Requirements

- `tmux`
- `ptyxis` (GNOME's terminal — the `Terminal` app on GNOME 46+)

```sh
sudo apt install tmux ptyxis   # Debian/Ubuntu
```

## Install

```sh
git clone https://github.com/aarratia25/claude-grid.git
cd claude-grid
./install.sh
```

This copies `claude-grid` into `~/.local/bin` and adds a "Claude Grid"
launcher to your applications menu. Make sure `~/.local/bin` is on your
`PATH`.

## Usage

```
claude-grid              open the default grid (or re-attach to it)
claude-grid NAME         open a SEPARATE grid named NAME — its own window and
                         tmux session, so you can run several grids at once
                         (e.g. one per monitor). Run it again to re-attach.
claude-grid ls           list every open grid and how to re-attach to each
claude-grid add  [NAME]  re-add missing panes back up to a full 2×2 grid
                         (use after you `exit` a pane by accident)
claude-grid fix  [NAME]  redraw every pane, for a clipped/offset TUI
claude-grid layout [NAME] restore the even 2×2 grid after panes drifted
```

### Notes

- **Persistence.** Closing the Ptyxis window does **not** kill the grid — the
  tmux session keeps running in the background. Re-run the same command to
  re-attach with everything intact. To remove one for good:
  `tmux kill-session -t claude-grid[-NAME]`.
- **Equal panes on resize.** As you stretch the window the four panes
  re-tile to stay equal, via a session-scoped `client-resized` hook.
- **Multiple grids.** Each `NAME` is an independent tmux session
  (`claude-grid-NAME`). On Wayland, drag each window to its monitor by hand.
- All tmux options are set **session-scoped only** — your global tmux config
  is never touched.

## License

MIT — see [LICENSE](LICENSE).
