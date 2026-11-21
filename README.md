# omarchy-sinners-theme

An [Omarchy](https://omarchy.org/) theme based on the key art for *Sinners* (2025, dir. Ryan Coogler).
Single dark theme: warm near-black, with the poster sun's gold, orange and red as the accent colors.
The one cool color in the art, the teaser's steel blue, is used for blue and cyan.

## Install

Copy or link this directory into Omarchy's theme folder, then apply it:

    ln -s "$PWD" ~/.config/omarchy/themes/sinners
    omarchy theme set sinners

Then the extras, which are separate from the theme and optional:

    bin/extras install          # everything: the unlock picker command, its menu row, and the font
    bin/extras install font     # or only the ones you name (command, menu, font)
    bin/extras status           # what is installed
    bin/extras uninstall        # undo everything; the font goes back to what it was

| Extra | What it does |
| --- | --- |
| `command` | Links `omarchy-sinners-unlock` into `~/.local/bin`: the picker for the theme's unlock screens (see below). |
| `menu` | Adds Appearance > Sinners Unlock to the Omarchy menu, shown only while Sinners is the active theme. It adds one marked block to your `~/.config/omarchy/extensions/omarchy-menu.jsonc` and backs the file up first. |
| `font` | Switches the system monospace font to iA Writer Mono S with `omarchy font set`, and remembers the font it replaces. If the font is missing it installs `ttf-ia-writer` with `omarchy pkg add`, which asks for sudo. |

A font is a system-wide Omarchy setting, not part of a theme, so the theme can only recommend one. Open terminals
need a restart to show a new font. `uninstall` puts the previous font back only if the font is still iA Writer Mono S,
and it never removes a package. Every check for every extra you select runs before anything is changed.

## What is in it

- `colors.toml`: the palette. Terminals, btop, Neovim, VS Code, the shell, the lock screen and Hyprland
  borders are all generated from it by Omarchy.
- `backgrounds/1-sinners-sun.webp`: an original wallpaper made by `tools/make-wallpaper.sh` (needs ImageMagick).
  The sun follows the one on the poster, measured from it. Its color runs gold at the top, through orange, to a
  red-orange below the middle, which is what lets a yellow title read on it. The yellow does not run to the edge:
  above the horizon the rim is a thin orange-to-red ring with a dark outer glow, as on the poster. Its glow is
  warm and strong beside the lower half and almost absent above the center line. It carries a faint seeded grain
  with a little mottle. It does not use studio artwork.
  `make-wallpaper.sh out.png` writes a PNG; convert it with `magick out.png -quality 92 backgrounds/1-sinners-sun.webp`.
  Earlier versions are kept in `research/wallpapers/` (v1: symmetric red glow and a smooth gold-centered sun; v2: poster colors;
  v3, the version before the limb ring, is not kept, since it only differs by that ring).
- `icons.theme`: GTK icon theme (`Yaru-red`).
- `hyprland.lua`: the window borders (the gradient from `colors.toml`) and a faint orange glow on the focused window,
  made with Hyprland's window shadow: 18px at about 9% of the sun's orange, and none on unfocused windows.
  Omarchy normally generates this file, but not when a theme ships its own, so the border lines repeat
  `colors.toml`; `tools/check-hyprland.sh` checks that they match. Omarchy drops every `.lua` from a theme installed
  from a git repo (your own symlinked copy is exempt), so a theme installed from GitHub gets the plain generated
  border and no glow. One side effect: Omarchy gives floating workspaces their own shadows only while shadows are
  off, so with the glow on, a floating workspace follows `hyprland.lua` instead: the focused window glows and the
  others have no shadow. For a faint dark shadow on unfocused windows, set `color_inactive = "rgba(00000035)"`.
- `unlock.png`, `preview-unlock.png`: the disk-unlock (Plymouth) wordmark and its switcher preview. Omarchy's
  stock wordmark filled with the sun gradient (gold, orange, red), built by `tools/make-unlock.sh`.
- `unlock-embers.png`, `preview-unlock-embers.png`: an alternate unlock logo, the same wordmark with a faint red
  halo and rising pixel embers (`tools/embers.py`). Omarchy reads `unlock.png`, so the alternates are opt-in; see below.
- `unlock-eyes.png`, `preview-unlock-eyes.png`: an alternate unlock logo inspired by the red-eyed face on the
  illustrated poster: two glowing eyes over a dimmed wordmark (`tools/eyes.py`). Drawn from scratch; only the
  poster's measurements (eye color, glow falloff) were used, none of its pixels.
- `unlock-sinners-sun.png`, `preview-unlock-sinners-sun.png`: an alternate unlock screen with the wallpaper's sun
  behind a Sinners-style title. Built for one screen size (1920x1200 here): see "The sun unlock screen" below.
- `bin/omarchy-sinners-unlock`: the command that picks among the unlock screens above (see below).
- `bin/extras`: installs, removes and reports the optional extras: the command, its menu row, and the font (see Install).
- `tools/`: the generators: `make-wallpaper.sh`, `make-unlock.sh`, `embers.py`, `eyes.py`, and for the sun screen
  `make-unlock-sun.sh`, `sun-unlock.py`, `lettering.py` and `verify-sun.py`; and `check-hyprland.sh`, which checks
  `hyprland.lua`.
- `research/`: how the theme was made. Omarchy does not read it. `palette.toml` is the first palette notes, superseded
  by `colors.toml`; `images/` has the swatch sheet and comparison mock-ups; `wallpapers/` has earlier wallpapers.
  A `poster-comparisons/` folder holds images that crop the poster. It stays on the machine it was made on and is
  ignored by git, so no studio artwork is committed.

## Unlock screen variants

`omarchy plymouth set by theme sinners` (and Appearance > Unlock) use `unlock.png`. The theme also ships three
alternates. Pick among all four with the theme's own command, which opens Omarchy's image picker (the same
one as Appearance > Unlock) over this theme's unlock screens, then applies the choice in a floating terminal
because it needs `sudo`:

    bin/extras install command menu   # once: the command, and Appearance > Sinners Unlock (plain `install` does these too)
    omarchy-sinners-unlock            # open the picker (or use Appearance > Sinners Unlock in the Omarchy menu)

The menu row shows only while the Sinners theme is active. `bin/extras uninstall command menu` removes both
changes, and the menu file is backed up before every edit. The command also works without the installer, run by its
path (`bin/omarchy-sinners-unlock`); once installed, these work from anywhere:

    omarchy-sinners-unlock list              # sun, embers, eyes, sinners-sun
    omarchy-sinners-unlock current           # which one is installed ("none" if it is not one of these)
    omarchy-sinners-unlock set eyes          # apply one directly, asking for sudo in this terminal
    omarchy-sinners-unlock set eyes --dry-run  # print the omarchy-plymouth-set command instead

It is a standalone command, not `omarchy sinners unlock`, because the `omarchy` dispatcher only scans
Omarchy's own packaged commands. Variants are found from the files: any `unlock-<name>.png` with a matching
`preview-unlock-<name>.png` appears in the picker, and `unlock.png` is called `sun`.

The embers canvas is 1000x408 and the eyes canvas is 800x400, so Plymouth places the password field about 110px
and 106px lower than with the sun wordmark. Omarchy centers the logo and puts the field 40px below it, so keep
any logo to about 400px tall or less. `omarchy plymouth set by theme sinners` returns to the default, and
`omarchy plymouth reset` restores Omarchy's stock screen. `tools/make-unlock.sh` rebuilds the first three
screens and their previews from `colors.toml` and is byte-reproducible.

### The sun unlock screen

`sinners-sun` puts the wallpaper's own sun behind the title, in the same place, size and colors, so the sun does not
move when the unlock screen gives way to the desktop. Plymouth draws the logo at its own pixel size, centered on
the screen, while Omarchy scales the wallpaper to cover the screen and center-crops it. So this screen is built for
one screen size, and it is only correct on that one: the default is 1920x1200 (`hyprctl monitors` shows yours).

    tools/make-unlock-sun.sh               # 1920x1200
    tools/make-unlock-sun.sh 2560x1600     # or your screen's size
    tools/verify-sun.py [WxH]              # checks the alignment against the wallpaper, about two minutes

The sun's size and position are read from `make-wallpaper.sh`, so the two cannot drift apart; rebuild the unlock
screen after changing the wallpaper. The title spans 92% of the sun's width, as on the poster (measured there), and
is centered on the sun: on the poster it sits a little low only because it is part of a text block that is itself
centered. Its lemon on the sun measures 3.1:1, the poster's own contrast. The logo is 1600x960 on a 1920x1200 screen, which puts the password field
at y=1120. The sun's grain is seeded, so the logo's sun has exactly the wallpaper's pixels. Where it differs: the
halo fades out in an oval before the logo ends, so it is shorter than the wallpaper's, and the logo's halo and the dark
tail of its limb ring add to the wallpaper's where the two overlap; the sky glow and the wallpaper's overall film
grain are not in the logo.

## Palette provenance

Colors were sampled by k-means clustering of the press-kit main art and teaser art
(https://www.sinnersmovie.com/toolkit/). The art has no green, cyan or magenta, so those slots are
derived and marked `[derived]` in `colors.toml`. Green is provisional.

Not included: `preview.png` (theme-switcher thumbnail, needs a screenshot of the applied theme).
