-- Neovim: the theme's own colorscheme, sinners.nvim. A local checkout at ~/dev/sinners.nvim is
-- used when there is one (for working on it); otherwise lazy.nvim installs it from GitHub.
-- Omarchy does not stage .lua files from a theme installed with `omarchy theme install`, so in
-- that case this file is skipped; add the first spec below to your own Neovim config instead.
local local_dir = vim.fn.expand("~/dev/sinners.nvim")
local spec = { "TRemigi/sinners.nvim", name = "sinners", lazy = false, priority = 1000 }
if vim.fn.isdirectory(local_dir) == 1 then
  spec.dir = local_dir -- lazy.nvim uses dir over the GitHub URL; [1] stays for Omarchy's hot reload
end

return {
  spec,
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "sinners",
    },
  },
}
