-- Fireworks 3D: launcher from the "CC Programs" resource pack. See "help fireworks".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "fireworks", entry = "fireworks.lua", title = "Fireworks 3D",
    mode = "rom", cwd = "program", size = 70384,
    needs = { "advanced" },
}, ...)
