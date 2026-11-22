# Sinners for Omarchy

A dark [Omarchy](https://omarchy.org/) theme inspired by Ryan Coogler's *Sinners* (2025).

![The Omarchy wordmark in the sun's gold, orange and red, from the theme's unlock screen](unlock.png)

**Contents**

- [The look](#the-look)
- [What you get](#what-you-get)
- [Quick start](#quick-start)
- [The plugins](#the-plugins)
- [More installation options](#more-installation-options)
- [Good to know](#good-to-know)
- [Under the hood](#under-the-hood)

## The look

The theme takes its look from the film's key art: a huge sun sinking into a red Mississippi haze, with a lone farmhouse on the
horizon. The background is warm and nearly black. The accents are the sun's gold, orange and red. The theme also puts the film's
juke joint into the desktop: weathered wooden boards, hand-painted lettering, embers rising in the dark.

Smoke gives the blues, Stack gives the rose that stands in for magenta, and the trees of the Delta give the green. Each color
has a source, so the palette holds together.

## What you get

**The theme**

- **A full color palette**, which Omarchy applies to your terminals, btop, VS Code, the lock screen and the window borders
- **Four original wallpapers**: the default is the sun as pixel art behind the Omarchy wordmark, matching the sinners-sun
  unlock screen; the second is the poster's sun, sky and farmhouse; the third is the pixel-art sun without the wordmark; the
  fourth is Club Juke at night in ASCII art, a cool moonlit counterpart to the others, with red eyes in the sky over the club
- **A warm glow** around the focused window*
- A complete custom **Neovim** theme using the theme's own colorscheme, [sinners.nvim](https://github.com/TRemigi/sinners.nvim)*
- **Five disk-unlock screens** to choose from: the sun-gold wordmark, rising embers, glowing red eyes, the wallpaper's sun
  as pixel art behind the Omarchy wordmark in the poster's neon lettering, or the same pixel-art sun without the wordmark

\* Omarchy leaves these out of themes installed from GitHub, so they come as the `glow` and `neovim` extras. See
[Quick start](#quick-start).

**Optional extras.** Each one is optional, and each one can be undone.

- **A bar of wooden boards.** The dark version is charred cypress with flaking oxblood paint, lit from behind by the low sun.
  The light version uses the grey wood of the film's Club Juke sign.
- **A painted workspace square, a gold clock in a flared display face, and a dimmed window title**, all made to sit on the
  boards
- **Embers and smoke** that drift up past the sun on the wallpaper
- **Notifications that burn away into ash** instead of fading
- **A settings panel** that you open from a small resonator guitar in the bar, for turning on and adjusting all of the above
- **The iA Writer Mono S font**, set as the system monospace font

Every extra stays switched off unless Sinners is your current theme, so you can switch to another theme and back without
breaking anything.

## Quick start

1. **Install the theme.**

       omarchy theme install https://github.com/TRemigi/omarchy-sinners-theme.git

   Omarchy downloads the theme to `~/.config/omarchy/themes/sinners` and switches to it.

2. **Add the window glow, the Neovim theme and the settings panel.** These are the only extras you install from the terminal
   (the panel needs `jq`):

       ~/.config/omarchy/themes/sinners/bin/extras install glow neovim settings

   Restart Neovim to see its new colors. The first start downloads sinners.nvim.

   **Want everything at once?** Run `bin/extras install --all` instead. It installs every extra: the glow, the Neovim
   theme, the font, the unlock-screen picker and all of the plugins, with the dark bar. Then skip to step 3 to adjust them.

3. **Open the panel.** Hover over the arrow at the right end of the bar to open the tray drawer, then click the guitar. If the
   guitar isn't there, run `omarchy restart shell`.

4. **Turn on what you want.** The panel has one tab for each part: Bar, Workspaces, Clock, Window title, Embers and
   Notifications. Click *Install* or *Turn on* in each tab you want, pick dark or light boards in the Bar tab, then click
   **Save**. Sliders and other settings take effect as soon as you change them.

## The plugins

You can turn on each plugin and change its settings in the settings panel. Changes to settings take effect immediately. A
plugin does nothing unless Sinners is your current theme.

<details>
<summary><strong>Bar</strong>: wooden boards behind the bar</summary>

<br>

This plugin replaces Omarchy's bar with three weathered wooden boards, one each for the left, middle and right sections. Each
board grows as you add widgets to it. There are two versions:

- **Dark boards:** charred cypress with patches of oxblood paint, backlit by the wallpaper's sun
- **Light boards:** the warm grey wood of the film's Club Juke sign, with dark lettering

The boards only appear on a top or bottom bar. Uninstalling switches you back to the bar you had before.
Extra: `bar` or `bar-light`.

| Setting | Default | Options | What it does |
| --- | --- | --- | --- |
| Position | Top | Top, Bottom, Left, Right | Where the bar sits. With Left or Right, the bar has no boards. |
| Background | Opaque | Opaque, Glassy, Clear | What shows behind the widgets in the gaps between the boards |

</details>

<details>
<summary><strong>Workspaces</strong>: a painted square for the current workspace</summary>

<br>

This plugin shows the number of the workspace you're on inside a hand-painted cream square, in a heavy serif font. It adjusts
its colors to match the dark or light boards. Extra: `workspaces`.

This plugin has no settings.

</details>

<details>
<summary><strong>Clock</strong>: a gold clock in a flared display face</summary>

<br>

This plugin draws the clock in capital letters, in the sun's gold, using Cinzel Decorative, a flared display font.
The font comes with the plugin, so there's nothing extra to install.
Extra: `clock`.

| Setting | Default | Options | What it does |
| --- | --- | --- | --- |
| Label | `dddd HH:mm` | A list of formats, or your own | How the time is written on the bar |
| Alternate label | `d MMMM 'W'ww yyyy` | A list of formats, or your own | What the clock shows when you right-click it |
| Week starts on | Follow the system | Any day of the week | The first column of the calendar that opens from the clock |
| Birth year | Off | Any year | Adds a second bar to the calendar that shows how much of a lifetime has passed |
| Life expectancy | 90 years | 1–150 years | The lifetime that the birth-year bar measures against |

</details>

<details>
<summary><strong>Window title</strong>: a dimmer title</summary>

<br>

This plugin draws the focused window's title slightly dimmer than the rest of the bar's text, so the workspaces and the clock
stand out more. Extra: `title`.

| Setting | Default | Options | What it does |
| --- | --- | --- | --- |
| Widest title | 280 px | 80–800 px | The width at which a long title is shortened with "…" |

</details>

<details>
<summary><strong>Embers</strong>: sparks and smoke rising over the wallpaper</summary>

<br>

This plugin sends embers up from the bottom of the screen and past the sun. They cool from gold to red as they rise. Dark smoke
drifts behind them, lit orange where the sun catches it. The effect appears between the wallpaper and your windows, ignores
clicks, and hides when a window is fullscreen. Extra: `embers`.

| Setting | Default | Options | What it does |
| --- | --- | --- | --- |
| Embers | On | On, Off | Shows or hides the sparks. Turning them off keeps the smoke. |
| Smoke | 32% | 0–100% | How much smoke rises behind the embers. 0% means no smoke. |
| Brightness | 80% | 0–100% | How bright the embers are |
| Amount | 1× | 0.1–1.5× | How many embers are in the air. 1× is about seventy on a 1920x1200 screen. |
| Speed | 1× | 0.25–3× | How fast everything moves |
| Frame rate limit | 60 fps | 5–60 fps | The highest frame rate the embers use. Smoke is always limited to 30 fps. |
| Sharpness | 100% | 50–100% | The resolution the embers are drawn at. A lower setting uses less power and looks softer. |

</details>

<details>
<summary><strong>Notifications</strong>: toasts that burn away</summary>

<br>

This plugin makes a notification burn away instead of fading out. A fire starts at the bottom edge, spreads across the card,
and leaves charred edges, glowing cracks and drifting ash. This happens whether the notification expires or you dismiss it.
It replaces Omarchy's notification system while it's on. Extra: `toasts`.

| Setting | Default | Options | What it does |
| --- | --- | --- | --- |
| Burn away | On | On, Off | Turns the burn on or off. Off uses Omarchy's normal fade. |
| Burn time | 2.6 s | 0.8–6 s | How long the fire takes to cross a notification. The ash settles for one more second. |

</details>

<details>
<summary><strong>Settings panel</strong>: the guitar in the tray</summary>

<br>

This plugin adds a small resonator guitar to the bar's tray drawer. Clicking it opens a panel with a tab for each plugin above,
where you install the plugins, turn them on or off, and change their settings. Some changes, such as installing a plugin or
switching bars, need the shell to restart. Those changes wait until you click **Save**, which applies them all and restarts
the shell once. Each tab also has a **Reset to defaults** button. Extra: `settings`.

This plugin has no settings.

</details>

## More installation options

### Install extras from the terminal

You can also install extras without the settings panel. Run these commands from the theme's folder,
`~/.config/omarchy/themes/sinners`:

    bin/extras install --all      # every extra, plugins included (with the dark bar)
    bin/extras install            # only the extras that add without replacing anything: see the table below
    bin/extras install bar clock  # or name the ones you want
    bin/extras status             # show what's installed
    bin/extras uninstall --all    # undo everything (the font goes back to the one you had before)

`bin/extras` with no arguments lists every extra.

| Extra | What it adds | In a plain `install` |
| --- | --- | --- |
| `glow` | The theme's window borders and the warm glow around the focused window | Yes |
| `neovim` | The Neovim colorscheme, [sinners.nvim](https://github.com/TRemigi/sinners.nvim) | Yes |
| `font` | iA Writer Mono S as the system monospace font (installs it if needed) | Yes |
| `command`, `menu` | The unlock-screen picker, and its item in the Omarchy menu | Yes |
| `embers` | The [Embers](#the-plugins) plugin | Yes |
| `settings` | The [settings panel](#the-plugins) | No |
| `bar` or `bar-light` | The dark or light [wooden bar](#the-plugins) | No |
| `workspaces`, `clock`, `title`, `toasts` | The other [plugins](#the-plugins) | No |

The extras marked "No" either replace a part of Omarchy or manage the others, so a plain `install` skips them and you name
them yourself. Uninstalling one puts Omarchy's original back.

### How the glow and Neovim extras work

Omarchy doesn't load Lua files from a theme installed from GitHub, which is where the glow and the Neovim theme live. The
`glow` and `neovim` extras keep a copy of each file and add a small Omarchy hook. Each time you switch to Sinners, the hook
puts the files back in place. When you switch to another theme, they don't load.

After you update the theme, run `bin/extras status`. It tells you if a file has changed, and running the install again picks
up the change. If your theme folder is your own copy (a clone you linked in yourself), Omarchy already loads these files, so
you don't need the extras.

### Choose an unlock screen

    bin/extras install command menu
    omarchy-sinners-unlock

The second command opens a picker with all five unlock screens. After the first command, the picker is also in the Omarchy menu
under **Appearance > Sinners Unlock**. Applying a screen asks for your password, because it changes the boot screen.

The **sinners-sun** screen matches the default pixel-sun wallpaper, and **sinners-sun-plain** matches the plain one: the same sun, centered on the screen, at the same size,
so when the desktop appears the picture stays put and only the password field goes away. That only works at one screen size,
which is 1920x1200 by default. For a different screen, rebuild it at your size
(this rebuilds the pixel-sun wallpaper too):

    tools/make-unlock-sun.sh 2560x1600

## Good to know

- **Two notification styles can't run at once.** The burning toasts replace Omarchy's notification system. If another theme
  also replaces it, uninstall one before turning on the other.
- **Omarchy updates.** The bar, clock, workspaces, window title and notifications are copies of Omarchy's own components with
  small changes. When Omarchy updates those components, the copies don't change with them. Running
  `plugins/sinners.bar/build.sh --check` or `tools/check-notifications-upstream.sh` tells you whether a copy has fallen behind.
- **If something looks wrong,** run `omarchy restart shell`. To turn off one extra right away, use
  `omarchy plugin disable <name>` or `bin/extras uninstall <name>`.

## Under the hood

The wallpapers, the unlock screens and the wooden boards are all made by scripts in `tools/`, so you can rebuild or change any
of them. Each script starts with comments explaining what it does and what it needs. The color sources and contrast ratios
are listed in `colors.toml`.

The colors were sampled from the film's official art and stills. The wallpaper, the boards and the unlock screens are original work: they were drawn from measurements of the film's art, and
no studio artwork is copied into this repo.
