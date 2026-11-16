-- Lightspeed Alpha: launcher from the "CC Programs" resource pack. See "help lightspeed".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "lightspeed", entry = "Lightspeed", title = "Lightspeed Alpha",
    mode = "copy", cwd = "program", size = 42796,
    needs = { "advanced" },
}, ...)
