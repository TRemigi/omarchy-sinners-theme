-- Sinners theme: the window borders, and a faint glow on the focused window.
--
-- Omarchy generates this file from colors.toml, but not when the theme ships its own, so the border lines
-- below repeat hyprland_active_border and hyprland_inactive_border from colors.toml. Keep them in step;
-- tools/check-hyprland.sh checks that they are. Omarchy drops every *.lua from a theme installed from a git
-- repo (a symlink to your own working copy is exempt), so on such an install the generated plain border is
-- used instead and there is no glow. Nothing breaks.

local active_border_color = { colors = { "rgba(F9BD06ee)", "rgba(FB7407ee)", "rgba(E91A02ee)" }, angle = 45 }
local inactive_border_color = "rgba(5A1F0Faa)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },

  decoration = {
    -- The glow is Hyprland's window shadow: the sun's orange, spread over 18px, at about 9% so that it
    -- reads as warmth around the border and not as a shadow. Unfocused windows get none.
    -- Omarchy keeps shadows off, and turns them on for floating workspaces only while they are off. With
    -- this on, a floating workspace follows these settings: the focused window glows and the rest have no
    -- shadow. To give unfocused windows a faint dark shadow again, set color_inactive = "rgba(00000035)".
    shadow = {
      enabled = true,
      range = 18,
      render_power = 3,
      color = "rgba(FB740718)",
      color_inactive = "rgba(00000000)",
    },
  },
})
