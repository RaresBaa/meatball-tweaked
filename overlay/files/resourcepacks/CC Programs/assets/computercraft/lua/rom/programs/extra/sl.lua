-- sl: launcher from the "CC Programs" resource pack. See "help sl".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "sl", entry = "sl.lua", title = "sl",
    mode = "rom", cwd = "program", size = 6972,
    needs = {  },
}, ...)
