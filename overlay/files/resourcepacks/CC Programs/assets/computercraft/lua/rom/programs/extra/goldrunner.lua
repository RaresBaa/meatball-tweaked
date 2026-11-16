-- Gold Runner: launcher from the "CC Programs" resource pack. See "help goldrunner".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "goldrunner", entry = "goldrunner.lua", title = "Gold Runner",
    mode = "rom", cwd = "program", size = 47836,
    needs = { "advanced" },
}, ...)
