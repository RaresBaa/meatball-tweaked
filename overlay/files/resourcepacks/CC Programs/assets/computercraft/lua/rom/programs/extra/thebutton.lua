-- The Button: launcher from the "CC Programs" resource pack. See "help thebutton".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "thebutton", entry = "Button.lua", title = "The Button",
    mode = "copy", cwd = "program", size = 109941,
    needs = { "advanced", "http" },
}, ...)
