-- SpriteMog: launcher from the "CC Programs" resource pack. See "help spritemog".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "spritemog", entry = "spritemog.lua", title = "SpriteMog",
    mode = "rom", cwd = "user", size = 21967,
    needs = { "advanced" },
}, ...)
