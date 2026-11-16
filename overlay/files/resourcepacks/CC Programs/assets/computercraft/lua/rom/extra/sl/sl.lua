-- sl command for ComputerCraft (Tweaked)
-- Ported from C ncurses version

-- Constants
local D51HEIGHT = 10
local D51FUNNEL = 7
local D51LENGTH = 83
local D51PATTERNS = 6
local ANIMATION_SPEED = 0.05

-- Train string patterns
local D51STR1 = "      ====        ________                ___________ "
local D51STR2 = "  _D _|  |_______/        \\__I_I_____===__|_________| "
local D51STR3 = "   |(_)---  |   H\\________/ |   |        =|___ ___|   "
local D51STR4 = "   /     |  |   H  |  |     |   |         ||_| |_||   "
local D51STR5 = "  |      |  |   H  |__--------------------| [___] |   "
local D51STR6 = "  | ________|___H__/__|_____/[][]~\\_______|       |   "
local D51STR7 = "  |/ |   |-----------I_____I [][] []  D   |=======|__ "

local D51WHL11 = "__/ =| o |=-~~\\  /~~\\  /~~\\  /~~\\ ____Y___________|__ "
local D51WHL12 = " |/-=|___|=    ||    ||    ||    |_____/~\\___/        "
local D51WHL13 = "  \\_/      \\O=====O=====O=====O_/      \\_/            "

local D51WHL21 = "__/ =| o |=-~~\\  /~~\\  /~~\\  /~~\\ ____Y___________|__ "
local D51WHL22 = " |/-=|___|=O=====O=====O=====O   |_____/~\\___/        "
local D51WHL23 = "  \\_/      \\__/  \\__/  \\__/  \\__/      \\_/            "

local D51WHL31 = "__/ =| o |=-O=====O=====O=====O \\ ____Y___________|__ "
local D51WHL32 = " |/-=|___|=    ||    ||    ||    |_____/~\\___/        "
local D51WHL33 = "  \\_/      \\__/  \\__/  \\__/  \\__/      \\_/            "

local D51WHL41 = "__/ =| o |=-~O=====O=====O=====O\\ ____Y___________|__ "
local D51WHL42 = " |/-=|___|=    ||    ||    ||    |_____/~\\___/        "
local D51WHL43 = "  \\_/      \\__/  \\__/  \\__/  \\__/      \\_/            "

local D51WHL51 = "__/ =| o |=-~~\\  /~~\\  /~~\\  /~~\\ ____Y___________|__ "
local D51WHL52 = " |/-=|___|=   O=====O=====O=====O|_____/~\\___/        "
local D51WHL53 = "  \\_/      \\__/  \\__/  \\__/  \\__/      \\_/            "

local D51WHL61 = "__/ =| o |=-~~\\  /~~\\  /~~\\  /~~\\ ____Y___________|__ "
local D51WHL62 = " |/-=|___|=    ||    ||    ||    |_____/~\\___/        "
local D51WHL63 = "  \\_/      \\_O=====O=====O=====O/      \\_/            "

local D51DEL = "                                                      "

local COAL01 = "                              "
local COAL02 = "                              "
local COAL03 = "    _________________         "
local COAL04 = "   _|                \\_____A  "
local COAL05 = " =|                        |  "
local COAL06 = " -|                        |  "
local COAL07 = "__|________________________|_ "
local COAL08 = "|__________________________|_ "
local COAL09 = "   |_D__D__D_|  |_D__D__D_|   "
local COAL10 = "    \\_/   \\_/    \\_/   \\_/    "

local COALDEL = "                              "

-- Smoke patterns
local SMOKEPTNS = 16

-- Initialize arrays

-- D51 train array
local d51 = {}
for i = 1, D51PATTERNS do
    d51[i] = {}
end

-- Initialize d51 array for each pattern
d51[1] = {D51STR1, D51STR2, D51STR3, D51STR4, D51STR5, D51STR6, D51STR7, D51WHL11, D51WHL12, D51WHL13, D51DEL}
d51[2] = {D51STR1, D51STR2, D51STR3, D51STR4, D51STR5, D51STR6, D51STR7, D51WHL21, D51WHL22, D51WHL23, D51DEL}
d51[3] = {D51STR1, D51STR2, D51STR3, D51STR4, D51STR5, D51STR6, D51STR7, D51WHL31, D51WHL32, D51WHL33, D51DEL}
d51[4] = {D51STR1, D51STR2, D51STR3, D51STR4, D51STR5, D51STR6, D51STR7, D51WHL41, D51WHL42, D51WHL43, D51DEL}
d51[5] = {D51STR1, D51STR2, D51STR3, D51STR4, D51STR5, D51STR6, D51STR7, D51WHL51, D51WHL52, D51WHL53, D51DEL}
d51[6] = {D51STR1, D51STR2, D51STR3, D51STR4, D51STR5, D51STR6, D51STR7, D51WHL61, D51WHL62, D51WHL63, D51DEL}

-- Coal car array
local coal = {COAL01, COAL02, COAL03, COAL04, COAL05, COAL06, COAL07, COAL08, COAL09, COAL10, COALDEL}

-- Smoke arrays
local smoke = {}
smoke[1] = {"(   )", "(    )", "(    )", "(   )", "(  )", "(  )", "( )", "( )", "()", "()", "O", "O", "O", "O", "O", " "}
smoke[2] = {"(@@@)", "(@@@@)", "(@@@@)", "(@@@)", "(@@)", "(@@)", "(@)", "(@)", "@@", "@@", "@", "@", "@", "@", "@", " "}

local eraser = {"     ", "      ", "      ", "     ", "    ", "    ", "   ", "   ", "  ", "  ", " ", " ", " ", " ", " ", " "}
local dy = {2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local dx = {-2, -1, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3}

-- Smoke storage
local S = {}
local sum = 0

-- Choo choo
local speakers = {peripheral.find("speaker")}
local choo_sound = "create:whistle_train"
local choo_volume = 3.0

-- Helper functions
function my_mvaddstr(y, x, str)
    if not str then return end
    local width, height = term.getSize()
    if y < 1 or y > height then return end

    -- Calculate visible part of string
    local startPos = 1
    local endPos = #str

    -- Adjust if x is negative
    if x < 1 then
        startPos = startPos + (1 - x)
        x = 1
    end

    -- Adjust if string extends beyond screen
    if x + endPos - startPos > width then
        endPos = startPos + width - x
    end

    -- Only draw if there's something to draw
    if startPos <= endPos then
        term.setCursorPos(x, y)
        term.write(string.sub(str, startPos, endPos))
    end
end

function add_smoke(y, x)
    if x % 4 == 0 then
        for i = 1, sum do
            my_mvaddstr(S[i].y, S[i].x, eraser[S[i].ptrn])
            S[i].y = S[i].y - dy[S[i].ptrn]
            S[i].x = S[i].x + dx[S[i].ptrn]
            S[i].ptrn = S[i].ptrn < SMOKEPTNS and S[i].ptrn + 1 or S[i].ptrn
            my_mvaddstr(S[i].y, S[i].x, smoke[S[i].kind][S[i].ptrn])
        end
        my_mvaddstr(y, x, smoke[(sum % 2) + 1][1])
        sum = sum + 1
        S[sum] = {y = y, x = x, ptrn = 1, kind = (sum % 2) + 1}
    end
end

function add_D51(x)
    if x < -D51LENGTH then return false end

    local width, height = term.getSize()
    local y = height - D51HEIGHT -- bottom of the screen

    -- Draw the train parts
    for i = 1, D51HEIGHT + 1 do
        -- Calculate the pattern index correctly
        local patternIdx = math.floor((D51LENGTH + x) % D51PATTERNS) + 1
        my_mvaddstr(y + i - 1, x, d51[patternIdx][i])
        my_mvaddstr(y + i - 1, x + 53, coal[i])
    end

    add_smoke(y - 1, x + D51FUNNEL)
    return true
end

function choo(speaker)
    pcall(function() -- Ignore errors, sound may not exist
        speaker.playSound(choo_sound, choo_volume)
        sleep(1)
        speaker.playSound(choo_sound, choo_volume)
    end)
end

function choo_choo()
    local tasks = {}
    
    for _, speaker in pairs(speakers) do
        table.insert(tasks, function() choo(speaker) end)
    end
    
    parallel.waitForAll(table.unpack(tasks))
end

function main()
    term.clear()
    term.setCursorBlink(false)

    local width, height = term.getSize()
    local x = width

    -- Ignore termination signals
    os.pullEvent = os.pullEventRaw

    while true do
        if not add_D51(x) then
            break
        end

        x = x - 1
        os.sleep(ANIMATION_SPEED)
    end

    term.setCursorPos(1, height)
end

parallel.waitForAll(main, choo_choo)
