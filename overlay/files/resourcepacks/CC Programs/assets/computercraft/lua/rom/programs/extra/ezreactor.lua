-- EZ-NUKE (Extreme Reactors): launcher from the "CC Programs" resource pack. See "help ezreactor".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "ezreactor", entry = "reactor.lua", title = "EZ-NUKE (Extreme Reactors)",
    mode = "copy", cwd = "program", size = 100151,
    needs = { "advanced", "bigreactor" },
}, ...)
