-- PineJam Racing: launcher from the "CC Programs" resource pack. See "help racer".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "racer", entry = "racer.lua", title = "PineJam Racing",
    mode = "copy", cwd = "program", size = 494371,
    needs = { "advanced" },
}, ...)
