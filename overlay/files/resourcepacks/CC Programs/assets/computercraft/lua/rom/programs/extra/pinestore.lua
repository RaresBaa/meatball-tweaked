-- PineStore client: launcher from the "CC Programs" resource pack. See "help pinestore".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "pinestore", entry = "pinestore.lua", title = "PineStore client",
    mode = "rom", cwd = "user", size = 3346,
    needs = { "http" },
}, ...)
