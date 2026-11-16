-- Pong: launcher from the "CC Programs" resource pack. See "help pong".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "pong", entry = "pong.lua", title = "Pong",
    mode = "rom", cwd = "program", size = 4422,
    needs = {  },
}, ...)
