-- Snake: launcher from the "CC Programs" resource pack. See "help snake".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "snake", entry = "snake.lua", title = "Snake",
    mode = "rom", cwd = "program", size = 3979,
    needs = {  },
}, ...)
