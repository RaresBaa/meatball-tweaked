-- Plethora: Fly: launcher from the "CC Programs" resource pack. See "help fly".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "plethora-fly", entry = "fly.lua", title = "Plethora: Fly",
    mode = "rom", cwd = "user", size = 3698,
    needs = { "neural" },
}, ...)
