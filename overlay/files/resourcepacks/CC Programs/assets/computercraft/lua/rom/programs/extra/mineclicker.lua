-- Mine Clicker: launcher from the "CC Programs" resource pack. See "help mineclicker".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "mineclicker", entry = "mineclicker.lua", title = "Mine Clicker",
    mode = "copy", cwd = "program", size = 46427,
    needs = { "advanced" },
}, ...)
