# Wallpaper-reactive theming

Your illogical-impulse dots already recolour the GUI from the wallpaper
(Hyprland, hyprlock, fuzzel, GTK3/4, KDE, quickshell). This adds the
terminal side, so `switchwall` now retints *everything*.

## How the colours reach each app

There are two mechanisms, and it matters which one an app uses.

**1. Palette remapping (no regeneration needed).**
`quickshell/ii/scripts/colors/terminal/kitty-theme.conf` overwrites ANSI
palette slots 232–255 with Material colours:

| slot | colour           | slot | colour              |
|------|------------------|------|---------------------|
| 243  | primary          | 251  | tertiary            |
| 244  | error            | 252  | secondaryContainer  |
| 245  | outlineVariant   | 253  | secondary           |
| 250  | tertiaryContainer| 255  | primary             |

Anything that draws with `\e[38;5;N` therefore follows the wallpaper for
free. `starship.toml` already relies on this, and so does the fastfetch
config. **Don't hardcode hex in these — use the slot numbers.**

**2. matugen templates (regenerated on every wallpaper switch).**
For apps that demand real hex values. Templates live in
`~/.config/matugen/templates/`, outputs are listed in `config.toml`.

| app     | template                        | output                              |
|---------|---------------------------------|-------------------------------------|
| btop    | `btop/matugen.theme`            | `~/.config/btop/themes/matugen.theme` |
| cava    | `cava/config`                   | `~/.config/cava/config`             |
| fzf     | `fzf/fzf-matugen.fish`          | `~/.config/fish/conf.d/fzf-matugen.fish` |
| bat     | `bat/matugen.tmTheme`           | `~/.config/bat/themes/matugen.tmTheme` |
| yazi    | `yazi/theme.toml`               | `~/.config/yazi/theme.toml`         |
| lazygit | `lazygit/config.yml`            | `~/.config/lazygit/config.yml`      |
| glow    | `glow/matugen.json`             | `~/.config/glow/matugen.json`       |

**Edit the template, never the output** — the output is overwritten on the
next wallpaper change.

Two templates have `post_hook`s so the change lands without a restart:
cava gets `SIGUSR1`, bat rebuilds its theme cache.

## Regenerating by hand

```fish
matugen --source-color-index 0 image (cat ~/.local/state/quickshell/user/generated/wallpaper/path.txt) --mode dark
```

The `--source-color-index 0` is required: matugen refuses to pick between
multiple candidate source colours non-interactively without it.

## Gotchas hit while setting this up

- **fastfetch key alignment.** Icons from the BMP private-use area
  (U+E000–U+F8FF) and the `nf-md-*` range (U+F0000+) are measured as
  different display widths, so mixing them breaks column alignment. All
  keys are deliberately `nf-md-*`.
- **fastfetch and ``.** Its JSON parser rejects escaped control
  characters in strings. Use fastfetch's own `{#38;5;245}` syntax instead.
- **yazi ≥ 26.x** renamed the filetype rule key `name` → `url`. Using
  `name` makes yazi fall back to preset settings with a parse error.
- **glow** style JSON supports `{{.text}}` placeholders, which collide
  with matugen's own `{{ }}` templating. Avoid them in that template.
- **btop** `theme_background = False` is what lets kitty's 0.80 opacity
  show through; setting a `main_bg` in the theme does not override it.

## If a dots update reverts this

`~/.config/matugen/config.toml` is shipped by illogical-impulse, so an
update may overwrite it and drop the template entries. The templates
themselves are in directories upstream doesn't own, so they'll survive —
re-append the block under `# Terminal-side apps (added)`.

A pre-change backup is at `config.toml.bak-preclaude`.
