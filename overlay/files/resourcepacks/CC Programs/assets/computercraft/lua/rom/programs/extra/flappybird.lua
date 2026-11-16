-- Flappy Bird: launcher from the "CC Programs" resource pack. See "help flappybird".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "flappybird", entry = "flappybird.lua", title = "Flappy Bird",
    mode = "rom", cwd = "program", size = 6050,
    needs = { "advanced" },
}, ...)
