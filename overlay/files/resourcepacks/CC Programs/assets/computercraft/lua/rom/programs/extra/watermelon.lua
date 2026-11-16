-- Watermelon Game 3D: launcher from the "CC Programs" resource pack. See "help watermelon".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "watermelon", entry = "WatermelonGame.lua", title = "Watermelon Game 3D",
    mode = "copy", cwd = "program", size = 132949,
    needs = { "advanced" },
}, ...)
