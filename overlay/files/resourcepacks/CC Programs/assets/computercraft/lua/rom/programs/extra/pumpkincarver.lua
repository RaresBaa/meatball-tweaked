-- Pumpkin Carver: launcher from the "CC Programs" resource pack. See "help pumpkincarver".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "pumpkincarver", entry = "pumpkincarver.lua", title = "Pumpkin Carver",
    mode = "copy", cwd = "program", size = 116687,
    needs = { "advanced" },
}, ...)
