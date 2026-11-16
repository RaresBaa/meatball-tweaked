-- Mandelplot: launcher from the "CC Programs" resource pack. See "help mandelplot".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "mandelplot", entry = "mandelplot.lua", title = "Mandelplot",
    mode = "rom", cwd = "program", size = 57405,
    needs = { "advanced" },
}, ...)
