-- Minecraft Clock: launcher from the "CC Programs" resource pack. See "help clock".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "clock", entry = "Clock.lua", title = "Minecraft Clock",
    mode = "rom", cwd = "user", size = 1479,
    needs = {  },
}, ...)
