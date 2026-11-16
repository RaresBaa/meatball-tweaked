-- CC: Minecraft: launcher from the "CC Programs" resource pack. See "help ccminecraft".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "ccminecraft", entry = "Minecraft.lua", title = "CC: Minecraft",
    mode = "copy", cwd = "program", size = 120585,
    needs = { "advanced" },
}, ...)
