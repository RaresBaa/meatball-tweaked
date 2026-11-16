-- Pixel Tank: launcher from the "CC Programs" resource pack. See "help pixeltank".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "pixeltank", entry = "tank.lua", title = "Pixel Tank",
    mode = "copy", cwd = "program", size = 97043,
    needs = { "advanced" },
}, ...)
