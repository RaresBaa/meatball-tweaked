-- Rubik's Cube: launcher from the "CC Programs" resource pack. See "help rubikscube".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "rubikscube", entry = "Cube.lua", title = "Rubik's Cube",
    mode = "copy", cwd = "program", size = 78934,
    needs = { "advanced" },
}, ...)
