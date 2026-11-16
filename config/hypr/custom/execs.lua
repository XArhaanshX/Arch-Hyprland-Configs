hl.on("hyprland.start", function ()
    -- drifting mist over the wallpaper, unless it was switched off with `mist off`
    hl.exec_cmd("$HOME/.local/bin/mist autostart")
end)
