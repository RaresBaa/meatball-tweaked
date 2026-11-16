-- nPaintPro: launcher from the "CC Programs" resource pack. See "help npaintpro".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "npaintpro", entry = "npaintpro.lua", title = "nPaintPro",
    mode = "rom", cwd = "user", size = 95045,
    needs = { "advanced" },
}, ...)
