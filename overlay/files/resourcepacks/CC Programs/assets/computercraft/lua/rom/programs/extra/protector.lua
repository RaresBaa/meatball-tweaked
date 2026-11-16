-- Protector: launcher from the "CC Programs" resource pack. See "help protector".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "protector", entry = "protector.lua", title = "Protector",
    mode = "copy", cwd = "program", size = 30829,
    needs = { "advanced" },
}, ...)
