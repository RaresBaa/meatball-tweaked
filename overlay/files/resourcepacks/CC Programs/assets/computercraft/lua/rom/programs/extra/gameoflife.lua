-- Game of Life: launcher from the "CC Programs" resource pack. See "help gameoflife".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "gameoflife", entry = "gameoflife.lua", title = "Game of Life",
    mode = "rom", cwd = "program", size = 4382,
    needs = { "advanced" },
}, ...)
