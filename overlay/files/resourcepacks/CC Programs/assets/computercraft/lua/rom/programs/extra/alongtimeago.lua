-- A Long Time Ago: launcher from the "CC Programs" resource pack. See "help alongtimeago".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "alongtimeago", entry = "alongtimeago.lua", title = "A Long Time Ago",
    mode = "rom", cwd = "program", size = 2189815,
    needs = {  },
}, ...)
