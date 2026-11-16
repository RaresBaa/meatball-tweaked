-- GitHub Downloader: launcher from the "CC Programs" resource pack. See "help githubdw".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "githubdw", entry = "githubdw", title = "GitHub Downloader",
    mode = "rom", cwd = "user", size = 7894,
    needs = { "http" },
}, ...)
