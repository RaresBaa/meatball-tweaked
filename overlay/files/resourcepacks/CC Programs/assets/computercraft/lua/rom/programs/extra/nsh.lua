-- nsh (netshell): launcher from the "CC Programs" resource pack. See "help nsh".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "nsh", entry = "nsh.lua", title = "nsh (netshell)",
    mode = "rom", cwd = "user", size = 30856,
    needs = { "modem" },
}, ...)
