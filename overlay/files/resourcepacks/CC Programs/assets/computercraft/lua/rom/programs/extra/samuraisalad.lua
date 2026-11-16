-- Samurai Salad: launcher from the "CC Programs" resource pack. See "help samuraisalad".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "samuraisalad", entry = "SamuraiSalad.lua", title = "Samurai Salad",
    mode = "copy", cwd = "program", size = 124386,
    needs = { "advanced" },
}, ...)
