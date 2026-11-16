-- ShrekWord: launcher from the "CC Programs" resource pack. See "help shrekword".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "shrekword", entry = "sword.lua", title = "ShrekWord",
    mode = "rom", cwd = "user", size = 53946,
    needs = {  },
}, ...)
