-- Maze 2D: launcher from the "CC Programs" resource pack. See "help maze3d".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "maze3d", entry = "maze2d.lua", title = "Maze 2D",
    mode = "copy", cwd = "program", size = 24133,
    needs = {  },
}, ...)
