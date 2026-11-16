-- Tessera: launcher from the "CC Programs" resource pack. See "help tessera".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "tessera", entry = "Tessera.lua", title = "Tessera",
    mode = "rom", cwd = "program", size = 75957,
    needs = { "advanced" },
}, ...)
