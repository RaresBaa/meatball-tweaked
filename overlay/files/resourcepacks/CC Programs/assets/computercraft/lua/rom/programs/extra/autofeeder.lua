-- Plethora: Auto feeder: launcher from the "CC Programs" resource pack. See "help autofeeder".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "plethora-autofeeder", entry = "auto-feeder.lua", title = "Plethora: Auto feeder",
    mode = "rom", cwd = "user", size = 3016,
    needs = { "neural" },
}, ...)
