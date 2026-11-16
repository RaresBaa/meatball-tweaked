-- cash: launcher from the "CC Programs" resource pack. See "help cash".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "cash", entry = "cash.lua", title = "cash",
    mode = "rom", cwd = "user", size = 54304,
    needs = {  },
}, ...)
