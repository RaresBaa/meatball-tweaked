-- Use terminal instead of monitor
local mon = term
mon.setTextScale = function(_) end  -- dummy for compatibility

-- Helper functions
local function clear()
    mon.setBackgroundColor(colors.black)
    mon.setTextColor(colors.white)
    mon.clear()
end

local function center(text, y, color)
    local w, _ = mon.getSize()
    local x = math.floor((w - #text) / 2) + 1
    mon.setCursorPos(x, y)
    mon.setTextColor(color or colors.white)
    mon.write(text)
end

-- Time and logic
local function getTimeInfo()
    local t = os.time()
    local h = math.floor(t)
    local m = math.floor((t - h) * 60)
    local ampm = (h >= 12) and "PM" or "AM"
    local h12 = h % 12
    if h12 == 0 then h12 = 12 end
    local timeStr = string.format("%02d:%02d %s", h12, m, ampm)

    local isDay = t >= 6 and t < 18
    local state = isDay and "Day" or "Night"

    return timeStr, state
end

-- UI draw
local function drawUI()
    clear()
    local w, h = mon.getSize()

    -- Get current time
    local timeStr, dayState = getTimeInfo()
    local dayNum = os.day()

    -- Build UI lines
    center("== Minecraft Clock ==", 2, colors.orange)
    center("Time: " .. timeStr, 4, colors.cyan)
    center("State: " .. (dayState == "Day" and "?? DAYTIME" or "?? NIGHTTIME"), 6,
        dayState == "Day" and colors.yellow or colors.blue)
    center("Day #: " .. tostring(dayNum), 8, colors.gray)
end

-- Auto-refresh loop (refreshes every second)
while true do
    drawUI()
    sleep(1)
end