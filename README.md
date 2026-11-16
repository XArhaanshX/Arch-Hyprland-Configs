# Arch + Hyprland Configs

Personal configuration for a CachyOS / Hyprland desktop, built on top of
[end-4's illogical-impulse](https://github.com/end-4/dots-hyprland) dots.

Everything here is **hand-written config**. Files that matugen generates are
deliberately not tracked — see [Tracked vs generated](#tracked-vs-generated).

**Machine:** CachyOS · Hyprland 0.57 (Wayland, Lua config) · Quickshell (`ii`) with
[Nothing Liquid](#nothing-liquid-liquid-glass) · kitty · fish · PipeWire · Intel Arc 130T/140T

---

## What's in here

| Area | What it does |
|---|---|
| **Wallpaper-reactive theming** | btop, cava, fzf, bat, yazi, lazygit, glow and GTK all recolour from the wallpaper |
| **Liquid glass** | [Nothing Liquid](#nothing-liquid-liquid-glass) on top of ii, [see-through Chrome](#see-through-chrome-chrome-glass) by chroma key, [spring-wobble workspaces](#motion) |
| **Shell scripts** | `donut`, `fx`, `theatre`, `btpair`, `bt-autoconnect`, `safe-update`, `nosleep`, `chrome-glass`, `nothing-liquid-rollback`, `dotsync` |
| **Audio** | LDAC tuning, EasyEffects crossfeed preset, Bluetooth auto-reconnect |
| **Fixes** | GTK4 accent override, Bluetooth device filtering, portal ScreenCast pinning |

---

## Theming: how colours reach each app

Two separate mechanisms, and it matters which one an app uses.

### 1. Palette remapping — no regeneration needed

The illogical-impulse dots overwrite ANSI palette slots 232–255 with Material
colours drawn from the wallpaper:

| slot | colour | slot | colour |
|------|--------|------|--------|
| 243 | primary | 251 | tertiary |
| 244 | error | 252 | secondaryContainer |
| 245 | outlineVariant | 253 | secondary |
| 250 | tertiaryContainer | 255 | primary |

Anything drawing with `\e[38;5;N` therefore follows the wallpaper for free.
`starship.toml` relies on this, and so do the fastfetch config and the donut.

> **Don't hardcode hex in these.** Use the slot numbers.

### 2. matugen templates — regenerated on every wallpaper switch

For apps that require real hex values. Templates live in
`config/matugen/templates/`, outputs are declared in `config/matugen/config.toml`.

| app | template | generated output (not tracked) |
|---|---|---|
| btop | `btop/matugen.theme` | `~/.config/btop/themes/matugen.theme` |
| cava | `cava/config` | `~/.config/cava/config` |
| fzf | `fzf/fzf-matugen.fish` | `~/.config/fish/conf.d/fzf-matugen.fish` |
| bat | `bat/matugen.tmTheme` | `~/.config/bat/themes/matugen.tmTheme` |
| yazi | `yazi/theme.toml` | `~/.config/yazi/theme.toml` |
| lazygit | `lazygit/config.yml` | `~/.config/lazygit/config.yml` |
| glow | `glow/matugen.json` | `~/.config/glow/matugen.json` |
| GTK 3/4 | `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css` | `~/.config/gtk-{3,4}.0/gtk.css` |

**Edit the template, never the output.** Outputs are overwritten on the next
wallpaper change.

Two templates carry `post_hook`s so changes land without a restart: cava gets
`SIGUSR1`, bat rebuilds its theme cache.

Regenerate by hand:

```fish
matugen --source-color-index 0 image (cat ~/.local/state/quickshell/user/generated/wallpaper/path.txt) --mode dark
```

`--source-color-index 0` is required — matugen refuses to pick between
multiple candidate source colours non-interactively without it.

---

## Scripts (`local/bin/`)

### `donut` — the rotating ASCII torus

Andy Sloane's `donut.c` in Python, coloured from the wallpaper palette.

```fish
donut              # spins full-screen, Ctrl-C to stop
donut --fetch      # spins beside live fastfetch output
donut --frame      # one frame (used as the fastfetch logo)
```

fastfetch renders once and exits, so its logo **cannot** animate. `--fetch`
captures fastfetch's output once, then redraws only the donut each frame.

### `fx` — EasyEffects toggle

```fish
fx          # toggle
fx on/off   # explicit
fx status   # state, preset, routing, active plugins
fx route    # re-point audio through EasyEffects
```

On/off uses EasyEffects' global bypass rather than moving the default sink, so
flipping is instant and never interrupts playback. Note EasyEffects 8 uses
`1` = bypass on, `2` = bypass off, `3` = query — **not** `0`/`1` like v7.

### `theatre` — distraction-free viewing

```fish
theatre                    # toggle
theatre run mpv film.mkv   # enter, play, auto-exit when done
```

Hides the bar, silences notifications, disables the night-light colour shift,
and inhibits idle lock / screen blank / suspend. Saves the real previous
values and restores them on exit.

### `btpair` / `bt-autoconnect` — Bluetooth

```fish
btpair            # scan until an "XM6" appears, then pair + trust + connect
btpair WH-1000 120
```

`bt-autoconnect` runs as a user service and watches D-Bus. It is
**event-driven, not polling** — it costs nothing idle and never wakes the
radio on its own.

### `safe-update` — guarded system update

```fish
safe-update            # pre-flight checks, repo + AUR upgrade, then "safe to reboot?" checks
safe-update --check    # only the boot checks, no updating
safe-update --no-aur
```

Pre-flight: pacman lock, charger or battery level, disk and ESP space, internet,
the last three weeks of Arch news. After the upgrade it checks every kernel
really reached the ESP (`vmlinuz` byte-identical to the module tree's,
initramfs newer than the kernel, a Limine entry) and ends with **SAFE** or
**DO NOT REBOOT**. Written after an update where pacman reported success, the
mkinitcpio hook never copied the new kernels, and neither kernel booted.

### `nosleep` — keep the laptop awake

```fish
nosleep               # toggle
nosleep on / off      # explicit
nosleep status
```

Holds a `systemd-inhibit` lock (idle, sleep, lid switch, sleep key) inside a
transient user unit, so nothing in the config changes and logging out or
rebooting turns it off. It cannot stop the critical-battery suspend.

### `dotsync` — push configs to this repo

```fish
dotsync             # copy + commit + push
dotsync --dry       # show what would change
dotsync --no-push
```

---

## Services (`config/systemd/user/`)

```fish
systemctl --user enable --now bt-autoconnect.service
systemctl --user enable --now easyeffects.service
```

`easyeffects.service` deliberately does **not** re-route the default sink at
login — see [Gotchas](#gotchas).

`wispd.service` is the daemon of [wisp](https://github.com/XArhaanshX/better-cluely),
a meeting-assistant overlay. It has no `[Install]` section on purpose: it never
starts at login, the `wisp` command starts it when needed. Its keybinds are in
`config/hypr/custom/wisp.lua`.

---

## Nothing Liquid (liquid glass)

Since November 2026 the desktop runs [Nothing Liquid](https://github.com/shlok-shinde/nothing-liquid)
on top of illogical-impulse: a fork of end-4's dots plus a fork of the
[hyprglass](https://github.com/hyprnux/hyprglass) plugin, which gives windows and
shell panels macOS Tahoe-style liquid glass (refraction through a glass slab,
not just blur).

- Installed from `~/.local/share/nothing-liquid/repo` with its own `install.sh`,
  which keeps every file it replaces in `~/.local/share/nothing-liquid/original`.
- The plugin is `~/.local/lib/nothing-liquid/hyprglass.so`. The theme's
  `hypr/hyprland/liquidglass.lua` loads it only if that file exists.
  `hyprctl hyprglass status` is the health check.
- Three of my own edits to upstream files survive on top of the fork, as
  [patches](#patches-patches): the 3-finger workspace swipe, the unnamed
  Bluetooth device filter and the do-not-disturb IPC.

```fish
nothing-liquid-rollback              # the theme's own uninstall: every replaced file back
nothing-liquid-rollback plugin-off   # keep the shell, drop the compositor glass (works from a TTY)
nothing-liquid-rollback plugin-on
nothing-liquid-rollback tarball      # last resort: restore the snapshot taken before the install
```

---

## See-through Chrome (`chrome-glass`)

Chrome paints every pixel opaque, so the liquid glass never shows through it,
and a window opacity rule would fade videos too. A chroma key does it instead:

1. The **Glass key** theme (`local/share/chrome-glass/theme/`, loaded unpacked
   from `chrome://extensions` in Developer mode) paints the tab strip, toolbar
   and new-tab page exactly `#0A141A`.
2. [Hypr-DarkWindow](https://github.com/micha4w/Hypr-DarkWindow)'s `chromakey`
   shader (`config/hypr/custom/chrome_glass.lua`) makes only pixels of that
   colour see-through. Text, images and video keep their own colours and stay
   solid, and fullscreen Chrome is left alone.
3. Chrome is tagged `hyprglass_preset_tahoe`: the frosted glass of the launcher
   and sidebars, not the clear lens windows get by default.

```fish
chrome-glass on        # build the plugin commit pinned for this Hyprland, then load it
chrome-glass off
chrome-glass rebuild   # after a Hyprland update
chrome-glass status
```

For see-through web pages too, set Dark Reader's background colour to
`#0A141A`. If the key colour ever changes, change it in the theme and in the
shader's `bkg` together.

---

## Motion

Nothing Liquid's curves overshoot once and settle. The workspace slide here is
a Hyprland 0.57 **spring** instead (`config/hypr/custom/general.lua`), so it
wobbles both ways like jelly: about 12% past the target, 1.5% back, one last
ripple, settled in ~0.56 s.

```lua
hl.curve("liquidWobble", { type = "spring", mass = 1, stiffness = 273, damping = 18 })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5.0, spring = "liquidWobble", style = "slide" })
```

A bezier can't do this: its overshoot passes the target once and never swings
back. Damping sets the amount of jelly: 19.8 gives about 9% then 1%, 16.5 about
15% then 2.3%.

---

## Patches (`patches/`)

Upstream files that are modified. Kept as diffs rather than whole files, so
dots updates don't get clobbered. With Nothing Liquid installed, `dotsync`
diffs against the fork's version of each file (the theme replaces them);
otherwise against the `.bak-preclaude` copy of end-4's original.

| patch | what it does |
|---|---|
| `BluetoothStatus.qml.patch` | hides unpaired devices with no name — nearby phones broadcast BLE with rotating random addresses, burying anything pairable |
| `Notifications.qml.patch` | adds an IPC handler for do-not-disturb, so scripts can reach it (`theatre` depends on this) |
| `general.lua.patch` | `hypr/hyprland/general.lua`: a 3-finger horizontal swipe switches workspaces instead of dragging the window. Gestures are additive, so this can't be done from `custom/` |

Paths inside the patches are relative to the home folder:

```fish
cd ~
patch -p0 < ~/Projects/Arch-Hyprland-Configs/patches/Notifications.qml.patch
```

---

## Tracked vs generated

Tracked: matugen **templates**, app configs, scripts, service units, Hyprland
user overrides (`config/hypr/custom/`), quickshell user settings.

Not tracked (see `.gitignore`): every matugen **output**. They change on every
wallpaper switch and would turn the history into noise. The templates are the
source of truth.

---

## Gotchas

Things that cost real debugging time here.

**GTK4 accent colours.** Apps linking libadwaita resolve `@accent_bg_color` at
runtime. Plain GTK4 apps (pavucontrol, most gtkmm software) use GTK's built-in
Adwaita theme, which ignores those names entirely — they stay Adwaita blue no
matter what the wallpaper is. They need explicit rule overrides, which is what
the bottom of `matugen/templates/gtk-4.0/gtk.css` does.

**EasyEffects can silence everything.** EasyEffects creates a virtual sink and
forwards to a real device. If the default sink is `easyeffects_sink` and the
forward target disappears (a Bluetooth headset powering off), audio goes into a
sink leading nowhere — speakers included. `fx off` always restores a real sink,
and `bt-autoconnect` does the same on disconnect.

**LDAC `hq` causes dropouts.** Fixed-rate 990 kbps can't back off when the link
dips, producing stutter at stream start. `auto` is set in
`51-bluez-ldac.conf`; the audible difference is marginal.

**`hyprctl keyword` doesn't work here.** These dots use Hyprland's Lua config
parser, which rejects it outright: *"keyword can't work with non-legacy
parsers"*. `hyprctl eval` with `hl.set` / `hl.cursor` isn't exposed either.

**fastfetch icon alignment.** Nerd Font icons from the BMP private-use area
(U+E000–U+F8FF) and the `nf-md-*` range (U+F0000+) are measured as different
display widths. Mixing them breaks column alignment — all keys are `nf-md-*`.

**fastfetch and ``.** Its JSON parser rejects escaped control characters
in strings; use fastfetch's own `{#38;5;245}` syntax.

**yazi ≥ 26.x** renamed the filetype rule key `name` → `url`. Using `name`
makes yazi fall back to preset settings with a parse error.

**glow** style JSON supports `{{.text}}` placeholders, which collide with
matugen's own `{{ }}` templating. Avoid them in that template.

**Bluetooth bonding.** A device can show `Paired: yes` / `Bonded: no` — trusted
but with no long-term key stored. Those pairings do not survive, and leave a
stale entry that blocks re-pairing. Fix: `bluetoothctl remove <MAC>`, then
re-pair.

**`bluetoothctl pairable on` / `agent on` don't persist.** They only hold for
the lifetime of that `bluetoothctl` process. Pairing has to happen inside a
single session — which is what `btpair` phase 2 does.

**Portal backends.** With `xdg-desktop-portal-{hyprland,gnome,kde,gtk}` all
installed, three of them declare `ScreenCast`. `hyprland-portals.conf` pins it
explicitly, otherwise the choice depends on backend ordering and screen sharing
silently breaks.

**Two shells after a restart.** `qs -c ii kill` doesn't always stop the shell
started at login. Two instances then fight over the notification server and the
polkit agent (and pop the conflict dialog twice). `qs list --all` shows them;
kill the old PID and start the shell once more.

**Rebuild after updates.** Hyprland plugins are tied to the exact Hyprland
build: after a Hyprland update rebuild both (`chrome-glass rebuild`, and the
glass plugin with Nothing Liquid's `install.sh`). The same goes for the
`illogical-impulse-quickshell-git` package after a Qt update; Quickshell warns
"built against Qt X but the system has updated to Qt Y" in its log.

---

## Notes if reusing this

- Absolute paths are hardcoded in a few places (`btop.conf` `color_theme`,
  `glow.yml` `style`). Adjust for a different username.
- `bt-autoconnect` defaults to a specific headphone MAC; override with
  `BT_AUTOCONNECT_MAC` or pass it as an argument.
- `config/matugen/config.toml` is shipped by illogical-impulse, so a dots
  update can drop the added template entries. Re-append the block under
  `# Terminal-side apps (added)`.
- `wispd.service` points at a virtualenv inside `~/Projects/better-cluely`.
  Adjust `ExecStart` if wisp lives elsewhere.
