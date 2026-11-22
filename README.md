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
    bin/extras install bar      # likewise, because it replaces your bar: see A bar of boards
    bin/extras install bar-light   # the same bar on light boards; see The light bar
    bin/extras install workspaces  # likewise, because it replaces the workspaces widget: the painted square, see A bar of boards
    bin/extras install clock       # likewise, because it replaces the clock widget: the gold clock, see A bar of boards
    bin/extras install title       # likewise, because it replaces the window-title widget: the dimmer title, see A bar of boards
    bin/extras install settings    # the settings panel, a guitar in the bar's tray drawer; it replaces nothing: see The settings panel

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
- `plugins/sinners.bar/`: Omarchy's bar with a weathered wooden board behind each of its three sections (see A bar of
  boards, below). Opt-in.
- `plugins/sinners.bar-light/`: the same bar on light boards, the warm grey wood of the film's sign, with dark lettering (see The light
  bar, below). It is built from the dark bar's files and one patch of its own. Opt-in.
- `plugins/sinners.workspaces/`: Omarchy's workspaces widget, copied and patched to show the shown workspace as its number
  in a painted cream square (see A bar of boards, below). Opt-in.
- `plugins/sinners.clock/`: Omarchy's clock widget, copied, with its label patched to the sun's gold (see A bar of boards,
  below). Opt-in.
- `plugins/sinners.active-window/`: Omarchy's window-title widget, copied, with the title patched a step dimmer than the rest of the
  lettering (see A bar of boards, below). Opt-in.
- `tools/`: the generators: `make-wallpaper.sh`, `make-unlock.sh`, `embers.py`, `eyes.py`, `make-bar-wood.py` (with
  `woodlib.py`, which also draw the painted squares), `preview-wear.sh`, and for the sun screen
  `make-unlock-sun.sh`, `sun-unlock.py`, `lettering.py` and `verify-sun.py`. Checks: `check-hyprland.sh` for
  `hyprland.lua`; `check-notifications-upstream.sh`, which tells you whether the notification fork has fallen behind
  Omarchy; and `check-burn-completes.sh`, which renders the burn's last frame for 25 seeds and four card sizes and
  requires that nothing is left. For looking at the shaders without a compositor: `preview-embers.sh`, `preview-burn.sh` and
  `shader-harness.c`, which they build (see Embers and smoke, and Toasts that burn away). `preview-wear.sh` uses the same
  harness for the bar's chipped-paint shader.
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

## A bar of boards

`plugins/sinners.bar` is Omarchy's own bar with a weathered wooden board behind each of its three sections: the left
(menu, workspaces, window title), the middle (the clock and what hangs off it) and the right (tray and status). The
boards are charred, weathered cypress, like the buildings in the film, with some of their oxblood paint still on them in worn
patches along the grain (about 30% of a board; `PAINT_LEFT` in `tools/make-bar-wood.py`), with a ragged sawn end and two nail
heads at each end, hung a little way below the top of the screen with a shadow under them. Each board is as long as the widgets on it, so one grows when a widget is added. Between the
boards the wallpaper shows. A left or right bar looks stock, because only a horizontal bar has boards.

It replaces the bar you have, so it is opt-in. To use it, and to go back:

    bin/extras install bar      # link it into ~/.config/omarchy/plugins and switch to it
    bin/extras uninstall bar    # switch back to the bar you had, then remove the link
    bin/extras status bar

or by hand, which is all `install` does: `ln -s "$PWD/plugins/sinners.bar" ~/.config/omarchy/plugins/sinners.bar`, then
`omarchy bar use sinners.bar` (to go back: `omarchy bar reset`, or `omarchy bar use <the id you had>`). If the bar looks
unchanged, `omarchy restart shell`. Your widgets and their layout are not touched.

**The painted square.** In the stock bar the shown workspace is its layout glyph, with nothing round it. `plugins/sinners.workspaces`
is Omarchy's workspaces widget with this change (described here for the dark bar; the light bar's is above): the shown workspace is its number, in the theme's deep rust (`selection`, `#5A1F0F`,
which the theme uses for what is selected, so it is the selected workspace's colour; the shell's own tokens do not carry it, so the widget
has it as a default, and a theme can set `[bar] active-number` in its `shell.toml` to change it) and a heavy serif of its own (Noto Serif Black, so it is not the condensed sans of the rest of
the lettering), inside a painted square in the theme's cream (`foreground`, the same as the lettering, read from `colors.toml` by the
generator, so it follows the theme). The active state is therefore the inverse of everything else: dark on cream, where the rest is cream on
dark (7.4:1, against 3.8:1 for the red on bright cream it replaced). Near-black would have measured 11.9:1, but rust is warmer, in
keeping with the oxblood of the paint, and still clears the 7:1 mark. The square is one of two drawings from `tools/make-bar-wood.py`: a patch of
paint with the number on it (the default, and the easier to read), or four brush strokes round the number.
`filled` in `PaintedSquare.qml` chooses; it is not generated, so a `build.sh` run leaves it alone. The widget no longer shows the layout
glyph; pressing the shown workspace still cycles the layout. The square and the number are drawn by the widget like any other, so
the grain over the boards (see below) falls on them too. It is a clone, so enabling it replaces the
built-in and disabling it brings the built-in back, as with the toasts; it refuses while another clone of the
workspaces is enabled. It is its own extra and works on any bar, but is meant for this one:

    bin/extras install workspaces      # link it and enable it
    bin/extras uninstall workspaces    # Omarchy's own workspaces are back

by hand: `ln -s "$PWD/plugins/sinners.workspaces" ~/.config/omarchy/plugins/sinners.workspaces`, then
`omarchy plugin enable sinners.workspaces` (to go back: `omarchy plugin disable sinners.workspaces`). `build.sh` and
`--check` work as for the bar.

**The light bar.** There are two versions of the bar, and either can be used: `sinners.bar`, described here so far, with dark boards,
and `sinners.bar-light`, with light ones. Choose with `bin/extras install bar` or `bin/extras install bar-light` (or `omarchy bar use
sinners.bar-light`), and go from one to the other the same way; uninstall switches back to the bar you had before either. The light bar's
boards are the wood of the film's Club Juke sign: a light, warm grey, `#A89486` on average. The colours were measured from the sign (the
5th, 25th, 50th, 75th and 95th luminance percentiles of its wood, and the red of its lettering, `#BC362E`); only those numbers are used,
none of its picture, as the theme's palette was taken from the key art. `tools/make-bar-wood.py` draws both sets of boards; the dark
bar's are byte-for-byte what they were. The light bar's lettering is the theme's deep rust (`selection`, `#5A1F0F`; or `[bar] text-light`
in a theme's `shell.toml`). Its boards are 4.4:1 against that, where the sign's own red on its own wood is 2.0:1, too faint at this size.

It is Omarchy's bar plus the dark bar's board patch plus one patch of its own (the lettering colour and a gentler grain: 0.4 on the side
boards and 0.3 on the clock's, against 0.5 on every board of the dark bar, because dark lettering on a light board is broken up by the grain
that suits cream on dark). Its Bar.qml is built by its `build.sh` from the stock bar and those two patches, and the board and overlay files
are copies of the dark bar's, made by the same script, so there is one source of them.

The shown workspace and the clock are the same two widgets on either bar: they tell which bar they are on from the bar's text colour,
which is all a widget is told of the bar (dark text means light boards). On the light bar the shown workspace is a patch of the sign's red
with its number in the theme's lightest cream (`bright_foreground`, `#F8EFD9`; or `[bar] active-number-light`), and the clock is the
sign's red deepened to 55%, `#682016` (4.1:1 on the wood; or `[bar] clock-light`). The other widgets on the clock's board are the bar's
text colour, rust, not the clock's red: the bar colours its widgets alike, and the two are within a few levels of each other.
**The shown workspace's square on the light bar is a suggestion, to be decided.** Not decided: the stock widget dims an empty workspace
to half strength, which on light wood leaves its number faint.

**The sun.** The dark bar's boards are backlit: the sun is low in the middle of the wallpaper and the bar is at the top of the screen, so the
sun is behind the boards and below them. A backlit board's face stays in shadow, and its light escapes round the edges and through the gaps,
so each board has a thin warm rim (the theme's `accent`, the sun's orange) along its lower edge and its sawn ends, light glowing through its
cracks, a little light wrapping round the lower half of its face, and, where its drop shadow was, a warm glow round the silhouette. The clock's
board, straight above the sun, gets the most, and the side boards 80% of that; each side board's rim is strongest on the end that faces the
sun. The strength is 0.2 (`SUN_STRENGTH` in `tools/make-bar-wood.py`; `--sun 0.6` is plainly visible, `--sun 0.9` tips toward
neon, `--sun 0` is off). Because the faces are not lit, it costs the lettering almost nothing: where the lettering sits, its contrast moves by
0.1 or less (cream on the left board 6.9:1 to 6.9:1, on the right 6.4:1 to 6.3:1, the gold clock 6.0:1 to 6.0:1), and the three boards keep the same brightness (median
luminance 0.225, 0.230 and 0.230). An earlier version lit the faces from below, as a warm gradient with the grain relit, which cost 0.3 to 0.5 of
that contrast and read as a lamp shining up at the wood; it was replaced. Because the boards are fixed pictures, each gets one strength, not a
glow that follows the sun along its length. The light bar is not lit this way: its boards are the sign's own colours.

**The colours.** Each colour on the bar has one job, so the eye goes where it should: the *wood* is charred and dark, with *oxblood*
paint left on it in patches, and sits quietly under the sun; the *lettering* is the theme's cream (`foreground`), and so is the shown workspace's
square, with the theme's deep rust (`selection`) as its number, so the active state is dark on cream where everything else is
cream on dark; and *gold* (`yellow`, the sun) is only the clock, which is therefore the first thing you read. Nothing else on the bar is gold,
and the bar has no red of its own beyond the paint on the boards (none, at `PAINT_LEFT = 0`). The window title is a step dimmer than the rest of
the lettering, so the eye goes to the workspaces and the clock first (below).

**The window title.** `plugins/sinners.active-window` is Omarchy's window-title widget (65 lines, one file), with the title drawn in the theme's
dimmed cream on the dark bar: `light_foreground`, `#BF9F71` (or `[bar] title` in a theme's `shell.toml`), solid, which is 6.2:1 on the board
against 9.3:1 for the rest of the lettering. The stock widget draws it at 85% opacity over the bar's text colour, which gave 7.1:1, a step too small
to see; this replaces that opacity with the colour. On the light bar it is **left as the stock widget draws it**: the 85% opacity already
puts the title a step dimmer than the rust text there (3.4:1 against 4.2:1), and dimming it further would make it unreadable on light wood. It
tells which bar it is on the way the other widgets do. It is a clone, so enabling it replaces the built-in and disabling it brings the built-in
back; it refuses while another clone of the window title is enabled:

    bin/extras install title           # link it and enable it
    bin/extras uninstall title         # Omarchy's own window title is back

by hand: `ln -s "$PWD/plugins/sinners.active-window" ~/.config/omarchy/plugins/sinners.active-window`, then
`omarchy plugin enable sinners.active-window`. `build.sh` and `--check` work as for the others.

**The gold clock.** `plugins/sinners.clock` is Omarchy's clock widget, with the clock's label, on the dark bar, in the sun's gold (`#F9BD06`, the theme's
`yellow`; or `[bar] clock` in the theme's `shell.toml`, if a theme has one; on the light bar it is the deepened red described above) and in capitals in Cinzel Decorative Black, a flared, swashy
display face chosen for the spirit of the Club Juke sign's hand-lettering (the sign is painted in the film, and a search found no typeface
identified for it; this was picked by comparing about twenty free faces on the real board, and it was the one that kept its flares and swashes under the
wood-grain overlay, which shreds the thin ones). The font is bundled in `plugins/sinners.clock/fonts/`, with its licence (SIL Open Font
License 1.1, by Natanael Gama), and loaded from there by the plugin, so no package is installed and nothing is needed from the system. If it
cannot be loaded, or on a vertical bar, the clock is lettered as the stock clock is. The clock's board is calmer than the other
two (`LOOK` in `tools/make-bar-wood.py`: fewer cracks and a smoother surface), so the fine strokes of the lettering survive; all three boards of
the dark bar share one brightness (the side boards are lifted by 1.7x, the clock board by 1.3x, which puts their median luminance on the same
0.226, before the sun described above) and one grain strength (0.5). The side boards were first lifted without lowering their grain, from the 0.95 it was tuned at on the
darker boards, and the title and the right-hand icons were chewed up; 0.5 is where the lettering holds. The clock's board is also longer, since capitals in this face are wider. It is a clone like the workspaces: all four of the stock
widget's files are copied, because it loads its calendar popup and its model from beside itself, and only `BarWidget.qml` is patched. Enabling it replaces the built-in and disabling it brings the built-in back; it refuses while another clone of the clock is
enabled:

    bin/extras install clock           # link it and enable it
    bin/extras uninstall clock         # Omarchy's own clock is back

by hand: `ln -s "$PWD/plugins/sinners.clock" ~/.config/omarchy/plugins/sinners.clock`, then `omarchy plugin enable sinners.clock`.
`build.sh` and `--check` work as for the others.

**The lettering.** On a horizontal bar the widgets and their tooltips draw in Noto Sans Condensed Black (install
`noto-fonts`; without it Qt falls back to its default font and the lettering is merely plainer), a heavy condensed sans like a
sign painter's, whatever the system font is. The popups the widgets open keep the system font. The bar's font is one line of
the patch (`fontFamily`), so nothing is cloned. Over each board's widgets, `WornPaint.qml` draws the board's own picture again (`shaders/wear.frag`). On
bare board that is the board over itself, which changes nothing; over a letter it puts the board back, a little, where the wood is
grooved, which gives the lettering the wood's grain, so it looks painted on the board and not laid over it: wherever the board is
darker than the board a few pixels above and below it (the grain runs along the bar, so that is where grain lines, cracks and pits are),
the board is let through, a little, and the lettering gets the wood's dark lines across it while the cream between them stays bright.
`grain` in `WornPaint.qml` (0.5) sets how much; 0 is off. At the shipped settings about 46% of the lettering's
pixels are touched by grain (the lighter the board, the less the lettering bears: lower `grain` if it is too eaten), and bare board is not changed (both measured on software GL with `tools/preview-wear.sh`, which takes `GRAIN=` and
`STRENGTH=`). The same overlay can also chip the lettering: `strength` in `WornPaint.qml` puts the board back over small flakes, stretched
along the grain, where the paint would have worn off. It is off (0): at 0.4 it altered only about 3% more of the lettering than the grain
alone, and it made the clock's fine flourishes ragged. Nothing redraws or hides a widget, so the text and
icons are exactly as the shell draws them, clicks and hover never see the overlay (it takes no input), and if its shader cannot run it
draws nothing. `tools/preview-wear.sh out.png` renders the effect on software GL, the lettering without the flakes above and with
them below, and prints how much it altered.

An earlier version redrew the widgets themselves through the effect, which showed no flakes in the real shell and gave the icons
red and blue edges, so it was dropped.

**How it is made.** The wood is not drawn by the shell: `tools/make-bar-wood.py` draws every board once, as PNGs in
`plugins/sinners.bar/wood/`, and `WoodBoard.qml` cuts those pictures to each section's length. Each board is three
pictures (a long body and the two ends), because the length is not known until the widgets are. The ends are drawn as separate small pieces of wood, so
each is scaled to the tone of its board's body when it is drawn; without that, one end can come out several times darker than the board. The wood itself is
procedural (`tools/woodlib.py`): grain that flows round knots, grain lines that break up and fade, checks that run
along the grain with ragged edges and pale lips, paint that wicks along the grain and wears off the dark late-wood, the
edges and the ends, and nails with rust streaked down the grain below them. It is original work: no photograph or film
frame is sampled or traced. It needs numpy, scipy and Pillow, which Omarchy does not install, so the PNGs are committed
and only changing the look needs them: `python -m venv /tmp/wood && /tmp/wood/bin/pip install numpy scipy pillow`, then
`/tmp/wood/bin/python tools/make-bar-wood.py` (`--sun STRENGTH` sets how strongly the sun backlights the dark bar's boards).

**The bar itself.** `Bar.qml` and `BarModel.js` are generated by `plugins/sinners.bar/build.sh` from the bar installed
with Omarchy plus `patches/0001-boards.patch` (eight small hunks). They are committed so the plugin installs from this
repo alone; do not edit them, change the patch. The patch makes a horizontal bar's strip 36 px tall (a board is 30 of
that, and the shadow has to be inside the strip, because a layer surface cannot draw outside itself), paints nothing
behind the boards, and sets the left and right sections 17 px further in from the screen's edge (a board reaches 17 px past its widgets, to keep them clear of the nails). Widgets still size
themselves by the stock bar height and are centred on the board. `build.sh --check` says whether Omarchy has changed its
bar since the copy was made (`UPSTREAM` records which version, and hashes), and `build.sh` rebuilds it. As with the
toasts, this copy does not receive Omarchy's later fixes to the bar until you rebuild it.

**What has and has not been checked.** The manifest validates (`omarchy plugin validate`), Omarchy's catalog lists
`sinners.bar` as a bar option (the check `omarchy bar use` makes), the patched `Bar.qml` parses with Qt 6.12's
`qmllint` and gives no kind of warning the stock file does not, and `WoodBoard.qml` was rendered in real Qt, headless, at
two bar heights and looked at. `bin/extras` was run against a stub `omarchy` and temporary files, through install,
a second install, status and uninstall, including restoring a previous bar. **It has not been run in the live shell**, which needs a
compositor: whether the widgets sit squarely on the boards, how the popups and the tray drawer behave, and whether
Hyprland's blur leaves a halo round the boards' shadows are not known. The wear shader was run on software GL over the real board picture and lettering and looked at (`tools/preview-wear.sh`); how much of the
board it flakes was measured there. The QML around it (`WornPaint.qml`) has only been parsed, since it needs the real shell. Not
known: how it looks at your screen's scale. The cream is the stock widgets' own colour from the theme. The painted-square widget is checked the same way (validated, parsed, and its extra run against a stub), and the squares and
the font were compared on the real board; how it sits in the live bar is not known. The charred boards were assembled from the shipped
images over the real wallpaper and looked at, not seen in the shell. The gold clock was built, validated and parsed, and its extra run
against a stub (including the refusal on a second clock clone); that the colour takes in the live clock is not known.

## The settings panel

`plugins/sinners.settings` is one place for every setting of the theme, and for installing, turning on and turning off the
theme's other plugins, so none of it needs a command typed. It is a bar widget that goes in the **tray's drawer** (hover the
chevron at the right of the bar), drawn as a resonator guitar standing upright: headstock, a straight neck, and a waisted body
whose lower bout holds the round resonator, as a ring cut out of the wood with the cone's cap in the middle of it. It is drawn stout, with a thick neck and ring, and at about four fifths of the bar's height, because the bar's own icon button shrinks anything
to a dozen pixels and a true-to-life guitar came out a few pixels wide. It takes the
bar's lettering colour, so it is cream on the dark bar and rust on the light one. Click it and a panel opens under it.

    bin/extras install settings    # link it, and put it in the tray drawer
    bin/extras uninstall settings

The panel has a tab for each of the theme's other plugins: **Bar**, **Workspaces**, **Clock**, **Window title**, **Embers** and
**Notifications**. A dot on a tab says whether its plugin is on, and a filled one that it will be after Save. The top of each
tab is a card with the plugin's state (on, off, or not installed) and one button: *Install*, *Turn on* or *Turn off*. A plugin that
replaces one of Omarchy's own says so. The bar's tab has a choice of Omarchy's own bar, the dark boards and the light boards instead.
Below the card are the plugin's settings, greyed while it is off:

| Tab | Settings |
| --- | --- |
| Bar | position (top, bottom, left, right) and background (opaque, glassy, clear) |
| Workspaces | none yet; it dresses itself to suit the bar it sits on |
| Clock | the bar label and the alternate label (each a list of the formats, drawn as they would look now, or a format of your own), the first day of the week, birth year and life expectancy for the calendar's second bar |
| Window title | the widest the title may be, in pixels |
| Embers | embers on or off, smoke, brightness, amount, speed, frame rate limit and sharpness |
| Notifications | burning on or off, and how long a toast burns |

Sliders do not react to the mouse wheel: a wheel over one scrolls the tab, so scrolling a long tab never moves a setting by accident. Drag them,
or click on the track.

**What applies at once, and what waits for Save.** A setting that the plugin is already watching for is written to
`~/.config/omarchy/shell.json` as it is changed, a slider included while it is still being dragged, and the bar or the wallpaper
follows. That is every setting above. Anything that needs the shell restarted is **staged** instead: installing a plugin, turning one
on or off, and choosing a bar. The footer lists what is staged, and one **Save** button does all of it and restarts the shell once;
**Discard** drops it. When the shell is back the panel opens again with what happened (and, if a step failed, which one and why), and the
steps that did not fail are kept. Where a setting is at its default the panel removes the field from `shell.json` rather than writing the
default into it, so the file stays what you would have written yourself.

Every step goes through `plugins/sinners.settings/bin/sinners-settings`, which the panel runs, so each can be run from a terminal too:
`status` prints what is linked, on and set as JSON; `batch` writes settings; `apply` runs a plan of staged changes. Saving runs
`apply` detached from the shell, because it restarts the shell and the panel is part of it. Installing goes through `bin/extras install`,
so a plugin that is not linked yet is installed with the same checks and the same links (a clock is not installed while another plugin
replaces the clock), and the bar you had before is remembered as it is there.

Each tab ends with **Reset to defaults**, which asks first (the question defaults to Cancel). On yes it puts every setting of that tab
back to the plugin's own default, by removing the field from `shell.json` (for the bar, by setting position to top and background to
opaque), and the change shows at once like any other. It is greyed when nothing differs, or while the plugin is off. Whether a plugin is on,
and which bar is chosen, are not settings and a reset leaves them as they are. Fields the panel does not manage, such as the clock's
`verticalFormat`, are left alone.

A plugin that is not on has no entry in `shell.json`, and an entry is what turns a plugin on, so the panel never writes settings for
one; it greys them out until the plugin is on. Settings can only be changed for the Sinners plugins (the helper refuses any other id).

`tools/check-settings.sh` tests what can be tested without the shell: the logic that decides what Save does (under node), the helper
against a copy of `shell.json` and stand-ins for `omarchy` and `omarchy-shell` (reading, writing, a write refused, a plan run with one
step failing, the shell restarted once), the manifest, and the QML with Qt 6's `qmllint`. With `--render` it also starts a throwaway
quickshell on Qt's offscreen platform, puts the panel on screen with the real helper behind it, and writes a picture of each tab. **It has
not been run in the live shell**, which needs a compositor: the panel was rendered that way, with Omarchy's own controls, and a slider
change was seen to reach the file, but how the popup sits under the guitar, whether the drawer shows it at the right place at your
font size, how the dropdown lists open inside the popup, and the restart and reopen after Save have not been seen. The guitar was drawn
and looked at at several sizes, but not on the bar.

## Palette provenance

Colors were sampled by k-means clustering of the press-kit main art and teaser art
(https://www.sinnersmovie.com/toolkit/). The art has no green, cyan or magenta, so those slots are
derived and marked `[derived]` in `colors.toml`. Green is provisional.

Not included: `preview.png` (theme-switcher thumbnail, needs a screenshot of the applied theme).
