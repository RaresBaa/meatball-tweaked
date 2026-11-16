-- Tetracraft: launcher from the "CC Programs" resource pack. See "help tetracraft".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "tetracraft", entry = "tetracraft.lua", title = "Tetracraft",
    mode = "copy", cwd = "program", size = 25573,
    needs = { "advanced" },
}, ...)
