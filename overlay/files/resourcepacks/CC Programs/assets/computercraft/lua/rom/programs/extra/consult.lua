-- CONSULT: launcher from the "CC Programs" resource pack. See "help consult".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "consult", entry = "cosu.lua", title = "CONSULT",
    mode = "rom", cwd = "user", size = 49190,
    needs = {  },
}, ...)
