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
    bin/extras install workspaces  # likewise, because it replaces the workspaces widget: the gold plate, see A bar of boards

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
  with a little mottle. Below the sun it has the poster's horizon and ground, without the figures: a red haze, smoky
  and uneven, along the horizon, which the sun's lower rim sinks into, and below it a dark maroon ground, gritty and
  streaked sideways near the horizon, darkening to near black. The horizon sits 3.6% of the sun's diameter below the
  sun's rim, as on the poster, and the ground is 27% of the height. The colours are the poster's own median colours
  at each distance from its horizon (the haze is the poster's; the ground's colours are spread over twice the distance, so
  it comes out of the haze instead of stepping down from it). The texture is drawn in perspective, as ground seen at
  a grazing angle is: fine grit at the horizon, flattened into streaks, growing into broad clods and patches of soil near
  the viewer, and fading in out of the haze. Its overall strength is the poster's (about 20% variation in brightness);
  its change of scale with depth is not, since on the poster the texture is the same size all the way down. The
  comments in `make-wallpaper.sh` give the numbers and how they were measured. The poster's sparks over the ground are left to the Embers plugin.
  It is made from measurements of the poster, and does not use studio artwork.
  `make-wallpaper.sh out.png` writes a PNG; convert it with `magick out.png -quality 92 backgrounds/1-sinners-sun.webp`.
  Earlier versions are kept in `research/wallpapers/` (v1: symmetric red glow and a smooth gold-centered sun; v2: poster colors;
  v3, the version before the limb ring, is not kept, since it only differs by that ring; v4: the limb ring, texture and
  title-ready colours, with a plain dark gradient where the ground now is).
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
- `plugins/sinners.workspaces/`: Omarchy's workspaces widget, copied and patched to put the shown workspace on a gold
  plate (see A bar of boards, below). Opt-in.
- `tools/`: the generators: `make-wallpaper.sh`, `make-unlock.sh`, `embers.py`, `eyes.py`, `make-bar-wood.py` (with
  `woodlib.py`, which also draw the gold plate and the wear mask), `preview-wear.sh`, and for the sun screen
  `make-unlock-sun.sh`, `sun-unlock.py`, `lettering.py` and `verify-sun.py`. Checks: `check-hyprland.sh` for
  `hyprland.lua`; `check-notifications-upstream.sh`, which tells you whether the notification fork has fallen behind
  Omarchy; and `check-burn-completes.sh`, which renders the burn's last frame for 25 seeds and four card sizes and
  requires that nothing is left. For looking at the shaders without a compositor: `preview-embers.sh`, `preview-burn.sh` and
  `shader-harness.c`, which they build (see Embers and smoke, and Toasts that burn away). `preview-wear.sh` uses the same
  harness for the bar's worn-paint shader.
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
screen after changing the wallpaper, as the haze and the ground over the sun's lower rim are part of its colour (the sun's
bottom edge sinks into the haze on the unlock screen too). The title spans 92% of the sun's width, as on the poster (measured there), and
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
boards are the barn-red paint of the sawmill in the film's design drawings, worn through to grey wood along the grain
and at the edges, with a ragged sawn end and two nail heads at each end, hung a little way below the top of the screen
with a shadow under them. Each board is as long as the widgets on it, so one grows when a widget is added. Between the
boards the wallpaper shows. A left or right bar looks stock, because only a horizontal bar has boards.

It replaces the bar you have, so it is opt-in. To use it, and to go back:

    bin/extras install bar      # link it into ~/.config/omarchy/plugins and switch to it
    bin/extras uninstall bar    # switch back to the bar you had, then remove the link
    bin/extras status bar

or by hand, which is all `install` does: `ln -s "$PWD/plugins/sinners.bar" ~/.config/omarchy/plugins/sinners.bar`, then
`omarchy bar use sinners.bar` (to go back: `omarchy bar reset`, or `omarchy bar use <the id you had>`). If the bar looks
unchanged, `omarchy restart shell`. Your widgets and their layout are not touched.

**The gold plate.** In the stock bar the shown workspace is its layout glyph, with no plate. `plugins/sinners.workspaces`
is Omarchy's workspaces widget with one change: the shown workspace sits on a small board painted sign-gold
(`plate.png`, from the same generator), its glyph in dark paint on top. It is a clone, so enabling it replaces the
built-in and disabling it brings the built-in back, as with the toasts; it refuses while another clone of the
workspaces is enabled. It is its own extra and works on any bar, but is meant for this one:

    bin/extras install workspaces      # link it and enable it
    bin/extras uninstall workspaces    # Omarchy's own workspaces are back

by hand: `ln -s "$PWD/plugins/sinners.workspaces" ~/.config/omarchy/plugins/sinners.workspaces`, then
`omarchy plugin enable sinners.workspaces` (to go back: `omarchy plugin disable sinners.workspaces`). `build.sh` and
`--check` work as for the bar.

**The lettering.** On a horizontal bar the widgets and their tooltips draw in Noto Sans Condensed Black (install
`noto-fonts`; without it Qt falls back to its default font and the lettering is merely plainer), a heavy condensed sans like a
sign painter's, whatever the system font is. The popups the widgets open keep the system font. The bar's font is one line of
the patch (`fontFamily`), so nothing is cloned. Over it, `WornPaint.qml` wears the paint: it draws each section's lettering
again through `shaders/wear.frag`, which takes small flakes out of the letters along the grain, as chipped paint does (about 6%
of the lettering's pixels; `strength` in `WornPaint.qml` sets it, 0 is off). The flakes come from `wood/wear.png`, a tileable
mask drawn by `tools/make-bar-wood.py`. It is a fail-safe: the original is hidden only once the shader has compiled, so on
a machine where it cannot run, the lettering is the stock bar's, unworn. `tools/preview-wear.sh out.png` renders the effect
on software GL, the stock lettering above and the worn below.

**How it is made.** The wood is not drawn by the shell: `tools/make-bar-wood.py` draws every board once, as PNGs in
`plugins/sinners.bar/wood/`, and `WoodBoard.qml` cuts those pictures to each section's length. Each board is three
pictures (a long body and the two ends), because the length is not known until the widgets are. The wood itself is
procedural (`tools/woodlib.py`): grain that flows round knots, grain lines that break up and fade, checks that run
along the grain with ragged edges and pale lips, paint that wicks along the grain and wears off the dark late-wood, the
edges and the ends, and nails with rust streaked down the grain below them. It is original work: no photograph or film
frame is sampled or traced. It needs numpy, scipy and Pillow, which Omarchy does not install, so the PNGs are committed
and only changing the look needs them: `python -m venv /tmp/wood && /tmp/wood/bin/pip install numpy scipy pillow`, then
`/tmp/wood/bin/python tools/make-bar-wood.py`.

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
Hyprland's blur leaves a halo round the boards' shadows are not known. The wear shader was run on software GL on real lettering
and looked at (`tools/preview-wear.sh`), and `WornPaint.qml` was loaded in headless Qt, which cannot run shaders (so it only
showed that the fail-safe leaves the lettering visible). Not known: whether the effect runs in the live shell, whether clicks, hover
and dragging still reach a section whose lettering is hidden behind it (`hideSource` should only stop it being drawn), and how it
looks at your screen's scale. The cream is the stock widgets' own colour from the theme. The gold plate's widget is checked the same way (validated, parsed,
and its extra run against a stub); where the plate sits on the glyph, and whether the dark glyph colour takes, are not known.

## Palette provenance

Colors were sampled by k-means clustering of the press-kit main art and teaser art
(https://www.sinnersmovie.com/toolkit/). The art has no green, cyan or magenta, so those slots are
derived and marked `[derived]` in `colors.toml`. Green is provisional.

Not included: `preview.png` (theme-switcher thumbnail, needs a screenshot of the applied theme).
