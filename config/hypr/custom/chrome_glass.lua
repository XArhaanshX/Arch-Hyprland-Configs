-- See-through Chrome (Zen-style): the "Glass key" Chrome theme paints the tab strip,
-- toolbar and new-tab page exactly #0A141A, and Hypr-DarkWindow's chromakey shader
-- makes only pixels of that colour see-through, so the liquid glass shows there.
-- Text, images and videos are other colours and stay solid.
-- Switch with `chrome-glass on|off|status`. Without the plugin file this does nothing.

local plugin = HOME .. "/.local/lib/chrome-glass/hypr-darkwindow.so"
if is_file_exists(plugin) then
    hl.plugin.load(plugin) -- declarative: listed on every parse, like the glass plugin
end

-- Loading is asynchronous: this block applies on the reload the plugin triggers.
if hl.plugin.darkwindow ~= nil then
    hl.window_rule({
        -- not when fullscreen: a full-screen film stays fully solid
        match = { class = "^(google-chrome)$", fullscreen = false },
        ["darkwindow:shade"] = hl.plugin.darkwindow.build_rule_effect({
            shader = "chromakey",
            args = {
                bkg = { 10 / 255, 20 / 255, 26 / 255 }, -- the key colour, #0A141A
                similarity = 0.012,  -- about 3/255 per channel: only the theme's exact colour
                amount = 1.0,        -- soft edge inside that range
                targetOpacity = 0.30, -- 0 = clear glass, 1 = solid
            },
        }),
    })
end

-- Behind Chrome: the frosted "tahoe" glass of the launcher and sidebars, not the
-- clear "tahoe_clear" lens that windows get by default (too see-through for a browser)
hl.window_rule({ match = { class = "^(google-chrome)$" }, tag = "+hyprglass_preset_tahoe" })
