-- CCDoom: launcher from the "CC Programs" resource pack. See "help doom".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "doom", entry = "Doom.lua", title = "CCDoom",
    mode = "copy", cwd = "program", size = 99163,
    needs = { "advanced" },
}, ...)
