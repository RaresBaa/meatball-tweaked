-- drmon (Draconic reactor): launcher from the "CC Programs" resource pack. See "help drmon".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "drmon", entry = "drmon.lua", title = "drmon (Draconic reactor)",
    mode = "copy", cwd = "program", size = 12335,
    needs = { "advanced", "monitor" },
}, ...)
