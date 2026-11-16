

-- Drifting mist over the wallpaper (~/.config/quickshell/mist): fade in and out
-- instead of the theme's pop-in, and no blur or glass behind it
hl.layer_rule({ match = { namespace = "desktop-mist" }, animation = "fade" })
