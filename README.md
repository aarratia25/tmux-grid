# tmux-grid

Open a single terminal window split into a **2×2 grid of 4 independent
shells** with one command — instead of arranging four separate windows by
hand every time. Use the panes for anything: editors, logs, REPLs, agents,
whatever.

Built for **Wayland/GNOME**, where scripting the position of real windows is
not possible: `tmux-grid` puts four [tmux](https://github.com/tmux/tmux)
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
git clone https://github.com/aarratia25/tmux-grid.git
cd tmux-grid
./install.sh
```

`install.sh` **symlinks** `tmux-grid` into `~/.local/bin` and adds a "Tmux
Grid" launcher to your applications menu. Make sure `~/.local/bin` is on your
`PATH`.

## Single source of truth

The installed launcher is a **symlink into this repo**, so the repo is the
only source of truth — there is never a second copy that can drift:

- **Change it here:** edit the script in your clone; it is live immediately
  (no reinstall). Commit and `git push` to publish.
- **Pull changes made elsewhere:** run `tmux-grid update` — it `git pull`s the
  clone and re-runs `install.sh`, so the machine matches the repo exactly.

## Crash/reboot persistence (optional)

If your machine sometimes freezes or reboots on its own, install with
persistence so you don't lose your grids:

```sh
./install.sh --persist
```

This adds [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) +
[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum), configured to:

- **autosave every 5 minutes** (no manual action), including the visible text
  of every pane;
- **auto-restore** the saved state when the tmux server starts after a reboot;
- start the tmux server at login (a headless autostart) so the restore happens
  before you open the grid.

**What comes back:** the sessions, the 2×2 layout, each pane's working
directory, and the on-screen text of every pane. **What does not:** live
processes (a running build, etc.). A `claude` session comes back in its folder;
resume it with `claude --resume`.

It appends a small **marked block** to `~/.tmux.conf` (it never overwrites your
existing config) and installs the plugins under `~/.tmux/plugins`.

## Usage

```
tmux-grid              open the default grid (or re-attach to it)
tmux-grid NAME         open a SEPARATE grid named NAME — its own window and
                       tmux session, so you can run several grids at once
                       (e.g. one per monitor). Run it again to re-attach.
tmux-grid ls           list every open grid and how to re-attach to each
tmux-grid add  [NAME]  re-add missing panes back up to a full 2×2 grid
                       (use after you `exit` a pane by accident)
tmux-grid fix  [NAME]  redraw every pane, for a clipped/offset TUI
tmux-grid layout [NAME] restore the even 2×2 grid after panes drifted
tmux-grid update       pull the repo and re-install (see above)
```

### Notes

- **Persistence.** Closing the Ptyxis window does **not** kill the grid — the
  tmux session keeps running in the background. Re-run the same command to
  re-attach with everything intact. To remove one for good:
  `tmux kill-session -t tmux-grid[-NAME]`.
- **Equal panes on resize.** As you stretch the window the four panes
  re-tile to stay equal, via a session-scoped `client-resized` hook.
- **Multiple grids.** Each `NAME` is an independent tmux session
  (`tmux-grid-NAME`). On Wayland, drag each window to its monitor by hand.
- All tmux options are set **session-scoped only** — your global tmux config
  is never touched.

## License

MIT — see [LICENSE](LICENSE).
