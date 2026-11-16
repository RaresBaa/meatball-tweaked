-- Tic-Tac-Toe: launcher from the "CC Programs" resource pack. See "help tictactoe".
return dofile("/rom/extra/launch.lua")(shell, {
    id = "tictactoe", entry = "tictactoe.lua", title = "Tic-Tac-Toe",
    mode = "rom", cwd = "program", size = 13377,
    needs = {  },
}, ...)
