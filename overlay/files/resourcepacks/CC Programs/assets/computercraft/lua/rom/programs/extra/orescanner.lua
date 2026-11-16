-- Plethora: Ore scanner: launcher from the "CC Programs" resource pack. See "help orescanner".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "plethora-orescanner", entry = "ore-scanner.lua", title = "Plethora: Ore scanner",
    mode = "rom", cwd = "user", size = 5776,
    needs = { "neural" },
}, ...)
