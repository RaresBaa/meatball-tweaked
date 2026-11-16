-- nyancat: a pop-tart cat flying through space, trailing a rainbow.
-- Usage: nyancat [monitor side/name]   (any key or a monitor touch to quit)

local args = { ... }
local target = term.current()
if args[1] then
    local mon = peripheral.wrap(args[1])
    if not mon or peripheral.getType(args[1]) ~= "monitor" then
        printError("No monitor called " .. args[1])
        return
    end
    mon.setTextScale(0.5)
    target = mon
end
if not target.isColour() then
    printError("nyancat needs an advanced computer or monitor")
    return
end

local W, H = target.getSize()
local SKY = "b"

-- Sprite pixels, one character per cell (blit colour codes, "." = transparent).
-- Legs, tail and head are drawn per frame so the cat can move.
local BODY = {
    ".fffffffffffffffff.",
    "f11111111111111111f",
    "f11666666626666611f",
    "f16626666666626661f",
    "f16666666666666661f",
    "f16662666662666661f",
    "f16666666666662661f",
    "f16266666666666661f",
    "f11666666666666611f",
    "f11111111111111111f",
    ".fffffffffffffffff.",
}
local HEAD = {
    ".ff.....ff.",
    "f88f...f88f",
    "f888fff888f",
    "f888888888f",
    "f88f888f88f",
    "f80f888f08f",
    "f688888886f",
    "f88f8f8f88f",
    ".f8888888f.",
    "..fffffff..",
}
local TAIL = {
    { "ff....", "f88ff.", ".f888f", "..ffff" },
    { "......", "ffff..", "f888ff", ".fffff" },
}
local LEG = { "f88f", ".ff." }
local RAINBOW = { "e", "1", "4", "5", "3", "a" }

local scale = math.max(1, math.min(math.floor(W / 44), math.floor(H / 20)))
local catW, catH = 30 * scale, 14 * scale

-- Off-screen buffer of background colours, one string row per line.
local buf
local function clear()
    buf = {}
    for y = 1, H do buf[y] = {} for x = 1, W do buf[y][x] = SKY end end
end
local function plot(x, y, c)
    for dy = 0, scale - 1 do
        local row = buf[y + dy]
        if row then
            for dx = 0, scale - 1 do
                if x + dx >= 1 and x + dx <= W then row[x + dx] = c end
            end
        end
    end
end
local function sprite(rows, ox, oy)
    for y, row in ipairs(rows) do
        for x = 1, #row do
            local c = row:sub(x, x)
            if c ~= "." then plot(ox + (x - 1) * scale, oy + (y - 1) * scale, c) end
        end
    end
end

local stars = {}
local function newStar(x)
    return { x = x or W + math.random(0, 10), y = math.random(1, H), phase = math.random(0, 3) }
end
for i = 1, math.max(4, math.floor(W * H / 120)) do stars[i] = newStar(math.random(1, W)) end

local function drawStar(s)
    local x, y = math.floor(s.x), s.y
    local p = s.phase % 4
    if p == 0 then plot(x, y, "0")
    elseif p == 1 then plot(x - scale, y, "0") plot(x + scale, y, "0") plot(x, y - scale, "0") plot(x, y + scale, "0")
    elseif p == 2 then plot(x, y, "0") plot(x - 2 * scale, y, "0") plot(x + 2 * scale, y, "0") plot(x, y - 2 * scale, "0") plot(x, y + 2 * scale, "0")
    else plot(x - 2 * scale, y, "0") plot(x + 2 * scale, y, "0") plot(x, y - 2 * scale, "0") plot(x, y + 2 * scale, "0") end
end

local function frame(n)
    clear()
    for _, s in ipairs(stars) do drawStar(s) end

    local bob = (math.floor(n / 2) % 2) * scale
    local cx = math.floor((W - catW) / 2) + 6 * scale
    local cy = math.floor((H - catH) / 2) + 1 + bob

    -- Rainbow: six bands from the left edge to the cat, waving in 8-pixel segments.
    local band = math.max(1, math.floor(9 * scale / 6))
    local top = cy + scale
    for x = 1, cx + 2 * scale do
        local wave = ((math.floor((cx - x) / (8 * scale)) + math.floor(n / 2)) % 2) * scale
        for i, colour in ipairs(RAINBOW) do
            for j = 0, band - 1 do
                local y = top + (i - 1) * band + j + wave - bob
                if buf[y] then buf[y][x] = colour end
            end
        end
    end

    local legShift = (n % 2 == 0) and 0 or scale
    sprite(TAIL[n % 2 + 1], cx - 5 * scale, cy + 5 * scale)
    for _, lx in ipairs({ 1, 4, 12, 15 }) do sprite(LEG, cx + lx * scale - legShift, cy + 10 * scale) end
    sprite(BODY, cx, cy)
    sprite(HEAD, cx + 12 * scale + legShift, cy + 2 * scale)
end

local function present(seconds)
    local blank = (" "):rep(W)
    for y = 1, H do
        local row = table.concat(buf[y])
        target.setCursorPos(1, y)
        target.blit(blank, row, row)
    end
    local msg = ("You have nyaned for %.1f seconds!"):format(seconds)
    if #msg <= W then
        target.setCursorPos(math.floor((W - #msg) / 2) + 1, H)
        target.setBackgroundColour(colours.blue)
        target.setTextColour(colours.white)
        target.write(msg)
    end
end

local start = os.clock()
local n = 0
local timer = os.startTimer(0)
while true do
    local event = os.pullEventRaw()
    if event == "timer" then
        frame(n)
        present(os.clock() - start)
        n = n + 1
        for i, s in ipairs(stars) do
            s.x = s.x - 3 * scale
            s.phase = s.phase + 1
            if s.x < -3 * scale then stars[i] = newStar() end
        end
        timer = os.startTimer(0.07)
    elseif event == "key" or event == "monitor_touch" or event == "terminate" then
        break
    end
end

target.setBackgroundColour(colours.black)
target.setTextColour(colours.white)
target.clear()
target.setCursorPos(1, 1)
if target ~= term.current() then print("Nyaned for " .. math.floor(os.clock() - start) .. " seconds.") end
