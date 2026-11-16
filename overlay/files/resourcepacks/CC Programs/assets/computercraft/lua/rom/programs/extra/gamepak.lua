-- 3 Game Pak: launcher from the "CC Programs" resource pack. See "help gamepak".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "gamepak", entry = "3gamepak.lua", title = "3 Game Pak",
    mode = "copy", cwd = "program", size = 37194,
    needs = { "advanced" },
}, ...)
