-- LuaIDE: launcher from the "CC Programs" resource pack. See "help luaide".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "luaide", entry = "luaide.lua", title = "LuaIDE",
    mode = "rom", cwd = "user", size = 59899,
    needs = { "advanced" },
}, ...)
