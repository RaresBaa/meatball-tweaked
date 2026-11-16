-- Plethora: Laser drill: launcher from the "CC Programs" resource pack. See "help laserdrill".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "plethora-laserdrill", entry = "laser-drill.lua", title = "Plethora: Laser drill",
    mode = "rom", cwd = "user", size = 1123,
    needs = { "neural" },
}, ...)
