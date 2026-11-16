-- Plethora: Laser sentry: launcher from the "CC Programs" resource pack. See "help lasersentry".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "plethora-lasersentry", entry = "laser-sentry.lua", title = "Plethora: Laser sentry",
    mode = "rom", cwd = "user", size = 1807,
    needs = { "manipulator" },
}, ...)
