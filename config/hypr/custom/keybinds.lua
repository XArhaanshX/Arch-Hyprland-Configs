hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- wisp overlay
if is_file_exists(HOME .. "/.config/hypr/custom/wisp.lua") then require("custom.wisp") end
