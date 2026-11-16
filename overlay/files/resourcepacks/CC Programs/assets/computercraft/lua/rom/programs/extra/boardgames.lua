-- CC-Checkerboard: launcher from the "CC Programs" resource pack. See "help boardgames".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "boardgames", entry = "gamelist.lua", title = "CC-Checkerboard",
    mode = "rom", cwd = "program", size = 55143,
    needs = {  },
}, ...)
