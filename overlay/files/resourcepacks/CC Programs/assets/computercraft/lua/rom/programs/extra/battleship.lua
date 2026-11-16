-- Battleship: launcher from the "CC Programs" resource pack. See "help battleship".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "battleship", entry = "battleship.lua", title = "Battleship",
    mode = "rom", cwd = "program", size = 23413,
    needs = { "advanced", "modem" },
}, ...)
