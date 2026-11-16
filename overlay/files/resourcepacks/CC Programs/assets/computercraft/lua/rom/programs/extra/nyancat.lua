-- Nyan Cat: launcher from the "CC Programs" resource pack. See "help nyancat".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "nyancat", entry = "nyancat.lua", title = "Nyan Cat",
    mode = "rom", cwd = "program", size = 5367,
    needs = { "advanced" },
}, ...)
