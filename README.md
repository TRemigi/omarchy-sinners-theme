# omarchy-sinners-theme

An [Omarchy](https://omarchy.org/) theme based on the key art for *Sinners* (2025, dir. Ryan Coogler).
Single dark theme: warm near-black, with the poster sun's gold, orange and red as the accent colors.
The one cool color in the art, the teaser's steel blue, is used for blue and cyan.

## Install

Copy or link this directory into Omarchy's theme folder, then apply it:

    ln -s "$PWD" ~/.config/omarchy/themes/sinners
    omarchy theme set sinners

Then the extras, which are separate from the theme and optional:

    bin/extras install          # everything: the unlock picker command, its menu row, the font, and the embers
    bin/extras install font     # or only the ones you name (command, menu, font, embers)
    bin/extras status           # what is installed
    bin/extras uninstall        # undo everything; the font goes back to what it was
    bin/extras install toasts   # not part of "everything", because it replaces something: see Toasts that burn away

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
  warm and strong beside the lower half and almost absent above the center line. The upper sky has the poster's
  clouds, subtly: big soft, dark, ragged-topped masses, stretched wide, over a red-lit sky, with a faint orange light along
  their undersides where the sun reaches them. They pass behind the sun, so its rim stays sharp against a dark cloud, and
  they fade out toward the horizon haze. They are drawn from fractal noise at the sizes measured on the poster and are
  well under its strength; `SINNERS_CLOUDS=0` leaves them out. It carries a faint seeded grain
  with a little mottle. Below the sun it has the poster's horizon and ground: a red haze, smoky
  and uneven, along the horizon, which the sun's lower rim sinks into, and below it a dark maroon ground of fine, crisp grit,
  darkening toward the bottom. The horizon sits 3.6% of the sun's diameter below the
  sun's rim, as on the poster, and the ground is 27% of the height. The colours are the poster's own median colours
  at each distance from its horizon (the haze is the poster's; the ground's colours are spread over twice the distance near the horizon, so
  it comes out of the haze instead of stepping down from it, and reach the poster's darkness lower down). The texture is made like the poster's, which
  is isotropic grit with far more at 1-3px than at 20px, and with more of it, not less, toward the bottom: a layer of fine grit
  at the screen's own resolution, a softer layer of 1-2px specks, mottle and a few dark clods at larger scales, and fading in
  out of the haze. Its strength at each scale and depth was measured against the poster's (within about 20%; `make-wallpaper.sh`
  gives the numbers). Only the mottle and clods are in perspective, shrinking with distance without being stretched, which
  the poster's texture is not (it is the same size all the way down); a version in which they were flattened into streaks, and
  had nothing finer than a few pixels, looked like a game texture and was dropped. The
  comments in `make-wallpaper.sh` give the numbers and how they were measured. The poster's sparks over the ground are
  left to the Embers plugin. Standing alone on the plain, centred under the sun, is Bert and Joan's farmhouse from the
  film: a small wooden cabin about 12 m long with a wall 3 m high and a ridge 5.6 m high, so that its large corrugated-tin
  roof, a patchwork of sheets in very different tones with a few gone, is most of what you see; it overhangs a long
  front porch with six thin posts, over a door and a window set back in shadow, with a clapboard gable end at the right
  and a low foundation. It is drawn by the script from its architecture, not traced or cut from a still, which would be
  studio artwork; only the house, with none of the car, horse or cow around it. Its size and place come from real
  distances, set at the top of that section: at 200 yards, seen at a 40 degree view from 1.7 m above the ground, it is
  about 350px wide on the 3840px wallpaper, and the ground at its foot is about 49px below the horizon: close to it,
  but not on it. The sun is behind it, so it is dark: only the roof is faintly lit. It is rendered, not just filled: its
  brightness falls from the sky-light on top to gloom near the ground; the bright haze behind wraps a couple of pixels
  over its edges, and a thin warm rim of light runs along the ridge and gable where the sun reaches it; its edges are
  very slightly irregular; its colours are graded into the scene's red light, so that it is a darker version of the haze
  and not a brown object; the boards streak with rain; and the haze over it thickens toward the ground, where a band of
  dust crosses its foot. It casts a short shadow toward the viewer. `DIST_YD`, `FOV_DEG` and `EYE_M` in
  `make-wallpaper.sh` move it nearer or farther.
  It is made from measurements of the poster, and does not use studio artwork.
  `make-wallpaper.sh out.png` writes a PNG; convert it with `magick out.png -quality 92 backgrounds/1-sinners-sun.webp`.
  Earlier versions are kept in `research/wallpapers/` (v1: symmetric red glow and a smooth gold-centered sun; v2: poster colors;
  v3, the version before the limb ring, is not kept, since it only differs by that ring; v4: the limb ring, texture and
  title-ready colours, with a plain dark gradient where the ground now is; v5, the ground without the house, is not kept;
  a version with dark figures standing in the haze was tried and dropped).
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
- `bin/extras`: installs, removes and reports the optional extras: the command, its menu row, the font, and the
  embers (see Install).
- `plugins/sinners.embers/`: the Embers shell plugin, embers and smoke floating up over the wallpaper (see Embers and
  smoke, below).
- `plugins/sinners.notifications/`: Omarchy's notification plugin, copied and patched so that toasts burn away into ash
  (see Toasts that burn away, below). Opt-in.
- `tools/`: the generators: `make-wallpaper.sh`, `make-unlock.sh`, `embers.py`, `eyes.py`, and for the sun screen
  `make-unlock-sun.sh`, `sun-unlock.py`, `lettering.py` and `verify-sun.py`. Checks: `check-hyprland.sh` for
  `hyprland.lua`; `check-notifications-upstream.sh`, which tells you whether the notification fork has fallen behind
  Omarchy; and `check-burn-completes.sh`, which renders the burn's last frame for 25 seeds and four card sizes and
  requires that nothing is left. For looking at the shaders without a compositor: `preview-embers.sh`, `preview-burn.sh` and
  `shader-harness.c`, which they build (see Embers and smoke, and Toasts that burn away).
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
screen after changing the wallpaper's sun. It is the plain sun, without the haze, ground and farmhouse that stand over the
wallpaper's lower rim: the unlock screen is not meant to carry them, so it matches the wallpaper in the sun's place,
size and colours and not below it (`verify-sun.py` builds its reference wallpaper without them, `SINNERS_GROUND=0`). The title spans 92% of the sun's width, as on the poster (measured there), and
is centered on the sun: on the poster it sits a little low only because it is part of a text block that is itself
centered. Its lemon on the sun measures 3.1:1, the poster's own contrast. The logo is 1600x960 on a 1920x1200 screen, which puts the password field
at y=1120. The sun's grain is seeded, so the logo's sun has exactly the wallpaper's pixels. Where it differs: the
halo fades out in an oval before the logo ends, so it is shorter than the wallpaper's, and the logo's halo and the dark
tail of its limb ring add to the wallpaper's where the two overlap; the sky glow and the wallpaper's overall film
grain are not in the logo.

## Embers and smoke

`plugins/sinners.embers` is an Omarchy shell plugin that floats embers, and a little smoke behind them, up over the
wallpaper. It puts a click-through window on the layer between the wallpaper and your windows, on every screen,
and paints two fragment shaders on it, the smoke first and the embers over it.
It is hidden under a fullscreen window and does nothing at all on any theme but Sinners, so it is safe to leave
enabled. Install it with `bin/extras install embers`, which links it into `~/.config/omarchy/plugins` and runs
`omarchy plugin enable sinners.embers`. A plugin runs as code inside the shell, so read it first; it is two small
QML files and two shaders. `bin/extras uninstall embers` disables it and removes the link.

What the embers shader does, and why it should look real rather than like confetti:

- **Heat.** Each ember is lofted from just below the screen white-gold, and cools through orange and red to
  nothing while it shrinks and flickers. Many burn out before they reach the top, so they thin out as they rise.
- **One wind.** Every ember is carried by the same slowly changing lean and gusts, so neighbours move together, and
  each adds its own small flutter on top.
- **Three depths.** Many small sharp sparks far away, the main population, and a few large defocused ones close to
  the camera that move faster.
- **Light, not paint.** The cores are overexposed so a hot one blooms toward white, and its halo is cooler than its
  core. The output is an ordinary translucent layer (alpha covers the colour), with no blend tricks.

The smoke shader is meant to be only just there:

- **Dark.** Smoke takes light away, so it is a translucent brown-black that shows as silhouettes against the sun and
  the red glow, and it dims the sun a little where it crosses it.
- **Rising and curling.** It is thickest at the bottom of the screen and thins as it climbs. The noise is
  three-dimensional with time as the third axis, so it keeps changing shape and never loops, and it is warped by
  more noise to give folded, billowing edges.
- **Lit from behind.** Where the side of a wisp faces the sun it glows orange, more strongly the nearer the sun is.
  The sun's position comes from the wallpaper's geometry in `tools/make-wallpaper.sh`, fitted to the screen the way
  the desktop fits a wallpaper, so it follows the sun on any screen size.
- **Cheap.** It is soft, so it renders at 40% of the screen's size and is scaled up.

There are no particles to update: where each ember is, and how hot, is a function of the clock, so a frame costs
only the fifteen embers near each pixel. Settings are inline fields on the plugin's entry in
`~/.config/omarchy/shell.json` `plugins[]`, and apply when the file is saved: `embers` (false switches the embers off),
`smoke` (0-1, 0.32; 0 switches it off), `intensity` (0-1, 0.8, for the embers), `density` (0.1-1.5, 1), `speed` (0.25-3, 1), `fpsCap` (5-60, 60; the most frames a second the embers get, and the smoke is held to 30) and `renderScale` (0.5-1, 1;
lower is cheaper and softer). A new shader or QML file needs `omarchy restart shell`. The clock wraps every six
hours, because a 32-bit float clock is too coarse past that to place an ember to the pixel; at the wrap every ember
is re-lofted at once.

Edit `shaders/embers.frag` or `shaders/smoke.frag`, then run `plugins/sinners.embers/build-shaders.sh` (needs `qt6-shadertools`); the compiled
`.qsb` is committed, so installing needs no compiler. To look at the shader without a compositor,
`tools/preview-embers.sh out.png [time]` renders them on Mesa's software GL and composites them over the wallpaper
(`LAYERS=smoke` or `LAYERS=embers` draws one; `AMOUNT` sets the smoke; `TIMES="12 40 71"` makes a contact sheet; it needs `gcc`, `libEGL` and `libGLESv2`). That tests the shader, not the
QML: the plugin has been validated (`omarchy plugin validate`, `qmllint`) but the layer itself has to be seen in a
running shell.

## Toasts that burn away

Every way a notification toast leaves the screen is a burn instead of a fade: it expires, you click it, you press
its action button or its ×, you dismiss it from the keyboard, or you dismiss them all. The fire is lit at one point,
the middle of the card's bottom edge, and climbs and spreads from there as a ragged, wandering contour: a wide, rounded dome
that takes a moment to reach the top, then out and around, so the corners go last. It is not a wipe, and it differs from card to card. Just ahead of the fire the card
browns and warms. On the line itself the glow is white-gold in a thin core, orange and red beyond it, flaring and
dulling as it goes. Behind it the card is charcoal, not black: grey-brown, flaky, partly ash, with a network of
cracks that glow red for a moment and go dark. The char crumbles away raggedly. Around the card the fire lights what
is near it, short flames lick up from the line, a faint smoke rises, and ash lifts off in flakes of every size and
brightness, tumbling and glowing at first, with the heavier cinders falling; a few quick sparks go out fast. Nothing
is a particle: all of it is worked out from the clock, so it costs only a shader.

The fire takes 2.6 s to cross a card, and the smoke and ash settle for 1 s more. While a card burns it is a normal
card in the stack, which holds its place until it is gone, and it takes no clicks. The one exception is a card
nobody can see (one hidden behind the front card of a collapsed deck), which just goes. A notification from the app
that replaces a burning card gives it a fresh life, as it does one that is fading.

**This is a fork of Omarchy's notification daemon, and it is opt-in.** Toasts are drawn, and removed, by the
daemon's own card and scene code, and it has no hook for another way out, so the only way is to change that code.
`plugins/sinners.notifications` is Omarchy's notifications plugin as of the version named in its `UPSTREAM` file,
with a patch every part of which is marked "Sinners" in `Service.qml` and `Toast.qml` (and new files `Burn.qml` and
`shaders/`). While it is enabled it takes the place of the built-in daemon, as `omarchy plugin clone` does. It acts
only while Sinners is the active theme, and on any other theme it is Omarchy's own daemon. Because it replaces
something, a bare `bin/extras install` leaves it out; name it:

    bin/extras install toasts     # link it and enable it; if toasts look unchanged, omarchy restart shell
    bin/extras uninstall toasts   # disable it and remove the link: Omarchy's own daemon is back

Two things to weigh before you do:

- **A fork stops getting Omarchy's fixes to the daemon.** The daemon handles text that other programs send, and
  Omarchy changes it from time to time. Nothing carries those changes into this copy. After an Omarchy update, run
  `tools/check-notifications-upstream.sh`: it says whether the stock plugin has changed since the copy (and whether
  the fork has strayed from stock anywhere but its three files), and `--diff` shows the patch. When it has, copy the
  new stock files over and carry the patch across; it is small. The annihilation theme's notification fork is in the
  same position, and was made against an older Omarchy than the current one.
- **Only one plugin can be the daemon.** `bin/extras install toasts` refuses while another that replaces it (such as
  `annihilation.notifications`) is enabled. To go to that theme, `bin/extras uninstall toasts` first.

Settings are inline fields on the plugin's entry in `~/.config/omarchy/shell.json` `plugins[]`: `burn` (false is the
stock fade) and `burnSeconds` (0.8-6, 2.6). If notifications ever misbehave, `omarchy plugin disable
sinners.notifications` puts the stock daemon back at once.

How much of this has been checked: the two shaders (`shaders/burn.frag`, `ash.frag`) were rendered over a card on
Mesa's software GL and looked at (`tools/preview-burn.sh out.png` makes the contact sheet; `CARD=` and `BGIMG=` use
your own card and background, and `VIS_TOP=` and friends cut away what is off the screen). The QML that wires
them into the daemon has been parsed (`qmllint`) and the plugin validated, but it has not been run: it needs the
real shell. Edit a shader, then run `plugins/sinners.notifications/build-shaders.sh`; the compiled `.qsb` files are
committed. The fire's arrival field is written once, in `burn.frag`, and the build copies it into `ash.frag`, so the
ash and the light always come from where the fire really is.

## Palette provenance

Colors were sampled by k-means clustering of the press-kit main art and teaser art
(https://www.sinnersmovie.com/toolkit/). The art has no green, cyan or magenta, so those slots are
derived and marked `[derived]` in `colors.toml`. Green is provisional.

Not included: `preview.png` (theme-switcher thumbnail, needs a screenshot of the applied theme).
