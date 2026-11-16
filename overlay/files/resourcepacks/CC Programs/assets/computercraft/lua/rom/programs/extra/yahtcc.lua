-- YahtCC: launcher from the "CC Programs" resource pack. See "help yahtcc".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "yahtcc", entry = "yahtcc.lua", title = "YahtCC",
    mode = "rom", cwd = "program", size = 22764,
    needs = { "advanced" },
}, ...)
