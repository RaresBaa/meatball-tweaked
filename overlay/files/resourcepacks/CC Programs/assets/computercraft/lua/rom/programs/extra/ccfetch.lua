-- ccfetch: launcher from the "CC Programs" resource pack. See "help ccfetch".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "ccfetch", entry = "ccfetch.lua", title = "ccfetch",
    mode = "rom", cwd = "user", size = 22840,
    needs = {  },
}, ...)
