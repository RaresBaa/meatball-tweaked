local Plotter = (function ()
-- Plotter by cyberbit
-- MIT License
-- Version 0.0.2

local pixelbox2 = (function ()
    -- Pixelbox Lite v2 by 9551-Dev
    -- (v1: https://github.com/9551-Dev/apis/blob/main/pixelbox_lite.lua)

    local pixelbox   = {}
    local box_object = {}

    local t_cat  = table.concat

    -- local sampling_lookup = {
    --     {2,3,4,5,6},
    --     {4,1,6,3,5},
    --     {1,4,5,2,6},
    --     {2,6,3,5,1},
    --     {3,6,1,4,2},
    --     {4,5,2,3,1}
    -- }

    local sampling_lookup = {
        {3,5,2,4,6},
        {4,6,1,3,5},
        {1,5,2,4,6},
        {2,6,1,3,5},
        {1,3,6,4,2},
        {4,2,5,3,1}
    }

    local texel_character_lookup  = {}
    local texel_foreground_lookup = {}
    local texel_background_lookup = {}
    local to_blit = {}

    local factorial_1 = 1
    local factorial_2 = factorial_1 * 2
    local factorial_3 = factorial_2 * 3
    local factorial_4 = factorial_3 * 4
    local factorial_5 = factorial_4 * 5

    local function generate_identifier(s1,s2,s3,s4,s5,s6)
        return  s2 * factorial_1 +
                s3 * factorial_2 +
                s4 * factorial_3 +
                s5 * factorial_4 +
                s6 * factorial_5
    end

    local function calculate_texel(v1,v2,v3,v4,v5,v6)
        local texel_data = {v1,v2,v3,v4,v5,v6}

        local state_lookup = {}
        for i=1,6 do
            local subpixel_state = texel_data[i]
            local current_count = state_lookup[subpixel_state]

            state_lookup[subpixel_state] = current_count and current_count + 1 or 1
        end

        local sortable_states = {}
        for k,v in pairs(state_lookup) do
            sortable_states[#sortable_states+1] = {
                value = k,
                count = v
            }
        end

        table.sort(sortable_states,function(a,b)
            return a.count > b.count
        end)

        local texel_stream = {}
        for i=1,6 do
            local subpixel_state = texel_data[i]

            if subpixel_state == sortable_states[1].value then
                texel_stream[i] = 1
            elseif subpixel_state == sortable_states[2].value then
                texel_stream[i] = 0
            else
                local sample_points = sampling_lookup[i]
                for sample_index=1,5 do
                    local sample_subpixel_index = sample_points[sample_index]
                    local sample_state          = texel_data   [sample_subpixel_index]

                    local common_state_1 = sample_state == sortable_states[1].value
                    local common_state_2 = sample_state == sortable_states[2].value

                    if common_state_1 or common_state_2 then
                        texel_stream[i] = common_state_1 and 1 or 0

                        break
                    end
                end
            end
        end

        local char_num = 128
        local stream_6 = texel_stream[6]
        if texel_stream[1] ~= stream_6 then char_num = char_num + 1  end
        if texel_stream[2] ~= stream_6 then char_num = char_num + 2  end
        if texel_stream[3] ~= stream_6 then char_num = char_num + 4  end
        if texel_stream[4] ~= stream_6 then char_num = char_num + 8  end
        if texel_stream[5] ~= stream_6 then char_num = char_num + 16 end

        local state_1,state_2
        if #sortable_states > 1 then
            state_1 = sortable_states[  stream_6+1].value
            state_2 = sortable_states[2-stream_6  ].value
        else
            state_1 = sortable_states[1].value
            state_2 = sortable_states[1].value
        end

        return char_num,state_1,state_2
    end

    local function base_n_rshift(n,base,shift)
        return math.floor(n/(base^shift))
    end

    local real_entries = 0
    local function generate_lookups()
        for i = 0, 15 do
            to_blit[2^i] = ("%x"):format(i)
        end

        for encoded_pattern=0,6^6 do
            local subtexel_1 = base_n_rshift(encoded_pattern,6,0) % 6
            local subtexel_2 = base_n_rshift(encoded_pattern,6,1) % 6
            local subtexel_3 = base_n_rshift(encoded_pattern,6,2) % 6
            local subtexel_4 = base_n_rshift(encoded_pattern,6,3) % 6
            local subtexel_5 = base_n_rshift(encoded_pattern,6,4) % 6
            local subtexel_6 = base_n_rshift(encoded_pattern,6,5) % 6

            local pattern_lookup = {}
            pattern_lookup[subtexel_6] = 5
            pattern_lookup[subtexel_5] = 4
            pattern_lookup[subtexel_4] = 3
            pattern_lookup[subtexel_3] = 2
            pattern_lookup[subtexel_2] = 1
            pattern_lookup[subtexel_1] = 0

            local pattern_identifier = generate_identifier(
                pattern_lookup[subtexel_1],pattern_lookup[subtexel_2],
                pattern_lookup[subtexel_3],pattern_lookup[subtexel_4],
                pattern_lookup[subtexel_5],pattern_lookup[subtexel_6]
            )

            if not texel_character_lookup[pattern_identifier] then
                real_entries = real_entries + 1
                local character,sub_state_1,sub_state_2 = calculate_texel(
                    subtexel_1,subtexel_2,
                    subtexel_3,subtexel_4,
                    subtexel_5,subtexel_6
                )

                local color_1_location = pattern_lookup[sub_state_1] + 1
                local color_2_location = pattern_lookup[sub_state_2] + 1

                texel_foreground_lookup[pattern_identifier] = color_1_location
                texel_background_lookup[pattern_identifier] = color_2_location

                texel_character_lookup[pattern_identifier] = string.char(character)
            end
        end
    end

    function pixelbox.restore(box,color,keep_existing)
        if not keep_existing then
            local new_canvas = {}

            for y=1,box.height do
                for x=1,box.width do
                    if not new_canvas[y] then new_canvas[y] = {} end
                    new_canvas[y][x] = color
                end
            end

            box.canvas = new_canvas
        else
            local canvas = box.canvas

            for y=1,box.height do
                for x=1,box.width do
                    if not bc[y] then bc[y] = {} end

                    if not canvas[y][x] then
                        canvas[y][x] = color
                    end
                end
            end
        end
    end

    local color_lookup  = {}
    local texel_body    = {0,0,0,0,0,0}
    function box_object:render()
        local t = self.term
        local blit_line,set_cursor = t.blit,t.setCursorPos

        local canv = self.canvas

        local char_line,fg_line,bg_line = {},{},{}

        local width,height = self.width,self.height

        local sy = 0
        for y=1,height,3 do
            sy = sy + 1
            local layer_1 = canv[y]
            local layer_2 = canv[y+1]
            local layer_3 = canv[y+2]

            local n = 0
            for x=1,width,2 do
                local xp1 = x+1
                local b1,b2,b3,b4,b5,b6 =
                    layer_1[x],layer_1[xp1],
                    layer_2[x],layer_2[xp1],
                    layer_3[x],layer_3[xp1]

                local char,fg,bg = " ",1,b1

                local single_color = b2 == b1
                                and  b3 == b1
                                and  b4 == b1
                                and  b5 == b1
                                and  b6 == b1

                if not single_color then
                    color_lookup[b6] = 5
                    color_lookup[b5] = 4
                    color_lookup[b4] = 3
                    color_lookup[b3] = 2
                    color_lookup[b2] = 1
                    color_lookup[b1] = 0

                    local pattern_identifier =
                        color_lookup[b2]       +
                        color_lookup[b3] * 2   +
                        color_lookup[b4] * 6   +
                        color_lookup[b5] * 24  +
                        color_lookup[b6] * 120

                    local fg_location = texel_foreground_lookup[pattern_identifier]
                    local bg_location = texel_background_lookup[pattern_identifier]

                    texel_body[1] = b1
                    texel_body[2] = b2
                    texel_body[3] = b3
                    texel_body[4] = b4
                    texel_body[5] = b5
                    texel_body[6] = b6

                    fg = texel_body[fg_location]
                    bg = texel_body[bg_location]

                    char = texel_character_lookup[pattern_identifier]
                end

                n = n + 1
                char_line[n] = char
                fg_line  [n] = to_blit[fg]
                bg_line  [n] = to_blit[bg]
            end

            set_cursor(1,sy)
            blit_line(
                t_cat(char_line,""),
                t_cat(fg_line,  ""),
                t_cat(bg_line,  "")
            )
        end
    end

    function box_object:clear(color)
        pixelbox.restore(self,color)
    end

    function box_object:set_pixel(x,y,color)
        -- print('set_pixel',x,y,color)
        self.canvas[y][x] = color
    end

    function box_object:resize(w,h,color)
        self.term_width  = w
        self.term_height = h
        self.width  = w*2
        self.height = h*3

        pixelbox.restore(self,color or self.background,true)
    end

    local first_run = true

    function pixelbox.new(terminal,bg)
        local box = {}

        box.background = bg or terminal.getBackgroundColor() or colors.black

        local w,h = terminal.getSize()
        box.term  = terminal

        setmetatable(box,{__index = box_object})

        box.term_width  = w
        box.term_height = h
        box.width       = w*2
        box.height      = h*3

        pixelbox.restore(box,box.background)

        if first_run then
            generate_lookups()

            first_run = false
        end

        return box
    end

    return pixelbox
end)()

local Plotter = setmetatable({ _VERSION = '0.0.2' }, {
    __call = function (class, ...)
        local object = setmetatable({}, class)
        
        class.constructor(object, ...)
        
        return object
    end
})
Plotter.__index = Plotter

Plotter.math = {
    --- round a number to the nearest integer
    --- @param x number
    --- @return integer
    round = function (x)
        return math.floor(x + 0.5)
    end,

    --- scale s from smin and smax to tmin and tmax
    --- something t
    --- (via https://stats.stackexchange.com/a/281164)
    --- @param s number
    --- @param smin number
    --- @param smax number
    --- @param tmin number
    --- @param tmax number
    --- @return number
    scale = function (s, smin, smax, tmin, tmax)
        return ((s - smin) / (smax - smin)) * (tmax - tmin) + tmin
    end
}

--- make a new plotter, filling the provided window
--- @param win window
function Plotter:constructor(win)
    self.box = pixelbox2.new(win)
end

--- draw a line using canvas coordinates
---@param x1 integer start x
---@param y1 integer start y
---@param x2 integer end x
---@param y2 integer end y
---@param color colors drawing color
function Plotter:drawLine(x1, y1, x2, y2, color)
    self:drawLineSometimes(x1, y1, x2, y2, color, 1, 0)
end

--- draw a line using canvas coordinates, with specified on/off pattern. returns next pattern offset
---@param x1 integer start x
---@param y1 integer start y
---@param x2 integer end x
---@param y2 integer end y
---@param color colors drawing color
---@param onrate integer consecutive on pixels
---@param offrate? integer consecutive off pixels, defaults to onrate
---@param oncount? integer offset for on pixels, defaults to 0
---@param offcount? integer offset for off pixels, defaults to 0
---@return integer oncount next oncount
---@return integer offcount next offcount
function Plotter:drawLineSometimes(x1, y1, x2, y2, color, onrate, offrate, oncount, offcount)
    if not offrate then offrate = onrate end

    if not oncount then oncount = 0 end
    if not offcount then offcount = 0 end

    local dx = math.abs(x2 - x1)
    local dy = -math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx + dy

    while true do
        if onrate > 0 and offrate == 0 then
            self.box:set_pixel(x1, y1, color)
        else
            if oncount < onrate then
                self.box:set_pixel(x1, y1, color)

                oncount = oncount + 1
            elseif offcount < offrate then
                -- skip pixel
                offcount = offcount + 1
            else
                self.box:set_pixel(x1, y1, color)

                oncount = 1
                offcount = 0
            end
        end

        if x1 == x2 and y1 == y2 then
            break
        end

        local e2 = 2 * err

        if e2 > dy then
            err = err + dy
            x1 = x1 + sx
        end

        if e2 < dx then
            err = err + dx
            y1 = y1 + sy
        end
    end

    return oncount, offcount
end

--- draw a line using canvas coordinates, filling the vertical space
--- between the line and a baseline
---@param x1 integer start x
---@param y1 integer start y
---@param x2 integer end x
---@param y2 integer end y
---@param yfrom integer y level for area baseline. the space between this y level and the drawn line will be filled
---@param color colors drawing color
function Plotter:drawAreaLine(x1, y1, x2, y2, yfrom, color)
    self:drawAreaLineSometimes(x1, y1, x2, y2, yfrom, color, 1, 0)
end

--- draw a line using canvas coordinates, filling the vertical space
--- between the line and a baseline, with specified on/off pattern.
---@param x1 integer start x
---@param y1 integer start y
---@param x2 integer end x
---@param y2 integer end y
---@param yfrom integer y level for area baseline. the space between yfrom and the drawn line will be filled
---@param color colors drawing color
---@param onrate integer consecutive on pixels
---@param offrate? integer consecutive off pixels, defaults to onrate
---@param oncount? integer offset for on pixels, defaults to 0
---@param offcount? integer offset for off pixels, defaults to 0
---@return integer oncount next oncount
---@return integer offcount next offcount
function Plotter:drawAreaLineSometimes(x1, y1, x2, y2, yfrom, color, onrate, offrate, oncount, offcount)
    if not offrate then offrate = onrate end

    if not oncount then oncount = 0 end
    if not offcount then offcount = 0 end

    local dx = math.abs(x2 - x1)
    local dy = -math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx + dy

    while true do
        if onrate > 0 and offrate == 0 then
            self:drawLineSometimes(x1, y1, x1, yfrom, color, onrate, offrate)
        else
            if oncount < onrate then
                self:drawLineSometimes(x1, y1, x1, yfrom, color, onrate, offrate)

                oncount = oncount + 1
            elseif offcount < offrate then
                -- skip pixel
                offcount = offcount + 1
            else
                self:drawLineSometimes(x1, y1, x1, yfrom, color, onrate, offrate)

                oncount = 1
                offcount = 0
            end
        end

        if x1 == x2 and y1 == y2 then
            break
        end

        local e2 = 2 * err

        if e2 > dy then
            err = err + dy
            x1 = x1 + sx
        end

        if e2 < dx then
            err = err + dx
            y1 = y1 + sy
        end
    end

    return oncount, offcount
end

--- draw a box using canvas coordinates
---@param x1 integer start x
---@param y1 integer start y
---@param x2 integer end x
---@param y2 integer end y
---@param color colors drawing color
function Plotter:drawBox(x1, y1, x2, y2, color)
    self:drawBoxSometimes(x1, y1, x2, y2, color, 1, 0)
end

--- draw a box using canvas coordinates, with specified on/off pattern.
--- returns next pattern offset. lines are drawn in a circular fashion
---@param x1 integer start x
---@param y1 integer start y
---@param x2 integer end x
---@param y2 integer end y
---@param color colors drawing color
---@param onrate integer consecutive on pixels
---@param offrate? integer consecutive off pixels, defaults to onrate
---@param oncount? integer offset for on pixels, defaults to 0
---@param offcount? integer offset for off pixels, defaults to 0
function Plotter:drawBoxSometimes(x1, y1, x2, y2, color, onrate, offrate, oncount, offcount)
    if not offrate then offrate = onrate end

    if not oncount then oncount = 0 end
    if not offcount then offcount = 0 end

    oncount, offcount = self:drawLineSometimes(x1, y1, x2 - 1, y1, color, onrate, offrate, oncount, offcount)
    oncount, offcount = self:drawLineSometimes(x2, y1, x2, y2 - 1, color, onrate, offrate, oncount, offcount)
    oncount, offcount = self:drawLineSometimes(x2, y2, x1 + 1, y2, color, onrate, offrate, oncount, offcount)
    oncount, offcount = self:drawLineSometimes(x1, y2, x1, y1 + 1, color, onrate, offrate, oncount, offcount)
end

--- fill a box using canvas coordinates
---@param x1 integer start x
---@param y1 integer start y
---@param x2 integer end x
---@param y2 integer end y
---@param color colors drawing color
function Plotter:fillBox(x1, y1, x2, y2, color)
    for x = x1, x2 do
        for y = y1, y2 do
            self.box:set_pixel(x, y, color)
        end
    end
end

--- plot one-dimensional data as a line in scaled coordinates, where
--- the data index is used as the horizontal axis
--- @param data table data to plot. index = x, value = y
--- @param dataw integer number of data indexes to fit in the plot area (left to right)
--- @param miny number minimum of data values to fit in the plot area (bottom)
--- @param maxy number maximum of data values to fit in the plot area (top)
--- @param color colors drawing color
function Plotter:chartLine(data, dataw, miny, maxy, color)
    local boxminx = 1
    local boxmaxx = self.box.width
    local boxminy = 1
    local boxmaxy = self.box.height

    local lastx, lasty

    for x, y in ipairs(data) do
        local nextx = self.math.round(self.math.scale(x, 1, dataw, boxminx, boxmaxx))
        local nexty = 1 + boxmaxy - self.math.round(self.math.scale(y, miny, maxy, boxminy, boxmaxy))

        if nextx < boxminx or nexty < boxminy or nextx > boxmaxx or nexty > boxmaxy then
            -- do nothing for OOB points
        else
            if type(lastx) == 'nil' then
                lastx = nextx
                lasty = nexty
            else
                self:drawLine(lastx, lasty, nextx, nexty, color)

                lastx = nextx
                lasty = nexty
            end
        end
    end
end

--- plot one-dimensional data as a line in scaled coordinates, where
--- the data index is used as the horizontal axis. chart will scale
--- data indexes to fit all provided data.
--- @param data table data to plot. index = x, value = y
--- @param color colors drawing color
function Plotter:chartLineAuto(data, color)
    local dataw = #data

    local actualmin, actualmax = math.huge, -math.huge

    for _, v in ipairs(data) do
        if v < actualmin then actualmin = v end
        if v > actualmax then actualmax = v end
    end

    self:chartLine(data, dataw, actualmin, actualmax, color)

    return actualmin, actualmax
end

--- plot one-dimensional data as an area in scaled coordinates, where
--- the data index is used as the horizontal axis
--- @param data table data to plot. index = x, value = y
--- @param dataw integer number of data indexes to fit in the plot area (left to right)
--- @param miny number minimum of data values to fit in the plot area (bottom)
--- @param maxy number maximum of data values to fit in the plot area (top)
--- @param areay number data value to use as baseline for area fill. larger values will fill towards -y, smaller values will fill towards +y.
--- @param color colors drawing color
function Plotter:chartArea(data, dataw, miny, maxy, areay, color)
    local boxminx = 1
    local boxmaxx = self.box.width
    local boxminy = 1
    local boxmaxy = self.box.height

    local lastx, lasty

    for x, y in ipairs(data) do
        local nextx = self.math.round(self.math.scale(x, 1, dataw, boxminx, boxmaxx))
        local nexty = 1 + boxmaxy - self.math.round(self.math.scale(y, miny, maxy, boxminy, boxmaxy))
        local nextareay = 1 + boxmaxy - self.math.round(self.math.scale(areay, miny, maxy, boxminy, boxmaxy))

        if nextareay > boxmaxy then nextareay = boxmaxy end
        if nextareay < boxminy then nextareay = boxminy end

        if nextx < boxminx or nexty < boxminy or nextx > boxmaxx or nexty > boxmaxy then
            -- do nothing for OOB points
        else
            if type(lastx) == 'nil' then
                lastx = nextx
                lasty = nexty
            else
                self:drawAreaLine(lastx, lasty, nextx, nexty, nextareay, color)

                lastx = nextx
                lasty = nexty
            end
        end
    end
end

--- plot one-dimensional data as an area in scaled coordinates, where
--- the data index is used as the horizontal axis. chart will scale
--- data indexes to fit all provided data.
--- @param data table data to plot. index = x, value = y
--- @param areay number data value to use as baseline for area fill. larger values will fill towards -y, smaller values will fill towards +y.
--- @param color colors drawing color
function Plotter:chartAreaAuto(data, areay, color)
    local dataw = #data

    local actualmin, actualmax = math.huge, -math.huge

    for _, v in ipairs(data) do
        if v < actualmin then actualmin = v end
        if v > actualmax then actualmax = v end
    end

    self:chartArea(data, dataw, actualmin, actualmax, areay, color)

    return actualmin, actualmax
end

--- plot two-dimensional data as points in scaled coordinates, where
--- the data is a table of {x, y} pairs.
--- @param data table data to plot. at each index: {x, y}
--- @param minx number minimum of data values to fit in the plot area (left)
--- @param maxx number maximum of data values to fit in the plot area (right)
--- @param miny number minimum of data values to fit in the plot area (bottom)
--- @param maxy number maximum of data values to fit in the plot area (top)
--- @param color colors drawing color
function Plotter:chartXY(data, minx, maxx, miny, maxy, color)
    local boxminx = 1
    local boxmaxx = self.box.width
    local boxminy = 1
    local boxmaxy = self.box.height

    for _, v in ipairs(data) do
        local x, y = table.unpack(v)

        local nextx = self.math.round(self.math.scale(x, minx, maxx, boxminx, boxmaxx))
        local nexty = 1 + boxmaxy - self.math.round(self.math.scale(y, miny, maxy, boxminy, boxmaxy))

        if nextx < boxminx or nexty < boxminy or nextx > boxmaxx or nexty > boxmaxy then
            -- do nothing for OOB points
        else
            self:drawLine(nextx, nexty, nextx, nexty, color)
        end
    end
end

--- clear plot using specified color
--- @param color colors
function Plotter:clear(color)
    self.box:clear(color)
end

--- render plot
function Plotter:render()
    self.box:render()
end

return Plotter
end)()

-- palettes and color functions based on https://github.com/esimov/gobrot, MIT License
local palettes = (function ()
    local palettes = {
        SummerBeach = {
            {0.0, 0xff, 0xf0, 0x94},
            {0.3, 0xff, 0xb7, 0x2d},
            {0.6, 0xff, 0x8d, 0x00},
            {0.8, 0x2d, 0x69, 0xae},
            {1.0, 0x1e, 0x2c, 0x60}
        },
        AfternoonBlue = {
            {0.0, 0x93, 0xd2, 0xca},
            {0.2, 0x6c, 0x98, 0xb8},
            {0.5, 0x38, 0x68, 0x85},
            {0.8, 0x17, 0x4f, 0x72},
            {1.0, 0x08, 0x2a, 0x4f}
        },
        Biochimist = {
            {0.0, 0x51, 0x99, 0x25},
            {0.0, 0x50, 0xa6, 0x1c},
            {0.0, 0x4b, 0xb8, 0x0b},
            {0.0, 0x4d, 0xcd, 0x00},
            {0.0, 0x53, 0xdf, 0x00},
        },
        Fiesta = {
            {0.0, 0x03, 0x67, 0xa6},
            {0.0, 0x04, 0xad, 0xbf},
            {0.0, 0x93, 0xa6, 0x03},
            {0.0, 0xe5, 0xce, 0x1b},
            {0.0, 0xc8, 0x3f, 0x2a}
        },
        Hippi = {
            {0.0, 0x00, 0x04, 0x0f},
            {0.0, 0x03, 0x26, 0x28},
            {0.0, 0x07, 0x3e, 0x1e},
            {0.0, 0x18, 0x55, 0x08},
            {0.0, 0x5f, 0x6e, 0x0f},
            {0.0, 0x84, 0x50, 0x19},
            {0.0, 0x9b, 0x30, 0x22},
            {0.0, 0xb4, 0x92, 0x2f},
            {0.0, 0x94, 0xca, 0x3d},
            {0.0, 0x4f, 0xd5, 0x51},
            {0.0, 0x66, 0xff, 0xb3},
            {0.0, 0x82, 0xc9, 0xe5},
            {0.0, 0x9d, 0xa3, 0xeb},
            {0.0, 0xd7, 0xb5, 0xf3},
            {0.0, 0xfd, 0xd6, 0xf6},
            {0.0, 0xff, 0xf0, 0xf2},
        },
        Vivid = {
            {0.0, 0x02, 0x3b, 0x2b},
            {0.0, 0x36, 0x34, 0x48},
            {0.0, 0x04, 0x8b, 0x64},
            {0.0, 0x81, 0x6a, 0x6e},
            {0.0, 0x8d, 0x5e, 0x67},
            {0.0, 0x98, 0x52, 0x60},
            {0.0, 0xa4, 0x46, 0x59},
            {0.0, 0xd3, 0x17, 0x3d},
            {0.0, 0xe1, 0x08, 0x34},
            {0.0, 0xde, 0x17, 0x30},
            {0.0, 0xdc, 0x26, 0x2d},
            {0.0, 0xd9, 0x36, 0x2a},
            {0.0, 0xd7, 0x45, 0x27},
            {0.0, 0xd5, 0x55, 0x24},
            {0.0, 0xd2, 0x64, 0x21},
            {0.0, 0xd0, 0x74, 0x1e},
            {0.0, 0xce, 0x83, 0x1b},
            {0.0, 0xcb, 0x92, 0x18},
            {0.0, 0xc9, 0xa2, 0x15},
            {0.0, 0x11, 0x03, 0x12},
            {0.0, 0x33, 0x08, 0x35},
            {0.0, 0xf5, 0xca, 0xf7},
        },
        Plan9 = {
            {0.0, 0x00, 0x00, 0x00},
            {0.0, 0x00, 0x00, 0x44},
            {0.0, 0x00, 0x00, 0x88},
            {0.0, 0x00, 0x00, 0xcc},
            {0.0, 0x00, 0x44, 0x00},
            {0.0, 0x00, 0x44, 0x44},
            {0.0, 0x00, 0x44, 0x88},
            {0.0, 0x00, 0x44, 0xcc},
            {0.0, 0x00, 0x88, 0x00},
            {0.0, 0x00, 0x88, 0x44},
            {0.0, 0x00, 0x88, 0x88},
            {0.0, 0x00, 0x88, 0xcc},
            {0.0, 0x00, 0xcc, 0x00},
            {0.0, 0x00, 0xcc, 0x44},
            {0.0, 0x00, 0xcc, 0x88},
            {0.0, 0x00, 0xcc, 0xcc},
            {0.0, 0x00, 0xdd, 0xdd},
            {0.0, 0x11, 0x11, 0x11},
            {0.0, 0x00, 0x00, 0x55},
            {0.0, 0x00, 0x00, 0x99},
            {0.0, 0x00, 0x00, 0xdd},
            {0.0, 0x00, 0x55, 0x00},
            {0.0, 0x00, 0x55, 0x55},
            {0.0, 0x00, 0x4c, 0x99},
            {0.0, 0x00, 0x49, 0xdd},
            {0.0, 0x00, 0x99, 0x00},
            {0.0, 0x00, 0x99, 0x4c},
            {0.0, 0x00, 0x99, 0x99},
            {0.0, 0x00, 0x93, 0xdd},
            {0.0, 0x00, 0xdd, 0x00},
            {0.0, 0x00, 0xdd, 0x49},
            {0.0, 0x00, 0xdd, 0x93},
            {0.0, 0x00, 0xee, 0x9e},
            {0.0, 0x00, 0xee, 0xee},
            {0.0, 0x22, 0x22, 0x22},
            {0.0, 0x00, 0x00, 0x66},
            {0.0, 0x00, 0x00, 0xaa},
            {0.0, 0x00, 0x00, 0xee},
            {0.0, 0x00, 0x66, 0x00},
            {0.0, 0x00, 0x66, 0x66},
            {0.0, 0x00, 0x55, 0xaa},
            {0.0, 0x00, 0x4f, 0xee},
            {0.0, 0x00, 0xaa, 0x00},
            {0.0, 0x00, 0xaa, 0x55},
            {0.0, 0x00, 0xaa, 0xaa},
            {0.0, 0x00, 0x9e, 0xee},
            {0.0, 0x00, 0xee, 0x00},
            {0.0, 0x00, 0xee, 0x4f},
            {0.0, 0x00, 0xff, 0x55},
            {0.0, 0x00, 0xff, 0xaa},
            {0.0, 0x00, 0xff, 0xff},
            {0.0, 0x33, 0x33, 0x33},
            {0.0, 0x00, 0x00, 0x77},
            {0.0, 0x00, 0x00, 0xbb},
            {0.0, 0x00, 0x00, 0xff},
            {0.0, 0x00, 0x77, 0x00},
            {0.0, 0x00, 0x77, 0x77},
            {0.0, 0x00, 0x5d, 0xbb},
            {0.0, 0x00, 0x55, 0xff},
            {0.0, 0x00, 0xbb, 0x00},
            {0.0, 0x00, 0xbb, 0x5d},
            {0.0, 0x00, 0xbb, 0xbb},
            {0.0, 0x00, 0xaa, 0xff},
            {0.0, 0x00, 0xff, 0x00},
            {0.0, 0x44, 0x00, 0x44},
            {0.0, 0x44, 0x00, 0x88},
            {0.0, 0x44, 0x00, 0xcc},
            {0.0, 0x44, 0x44, 0x00},
            {0.0, 0x44, 0x44, 0x44},
            {0.0, 0x44, 0x44, 0x88},
            {0.0, 0x44, 0x44, 0xcc},
            {0.0, 0x44, 0x88, 0x00},
            {0.0, 0x44, 0x88, 0x44},
            {0.0, 0x44, 0x88, 0x88},
            {0.0, 0x44, 0x88, 0xcc},
            {0.0, 0x44, 0xcc, 0x00},
            {0.0, 0x44, 0xcc, 0x44},
            {0.0, 0x44, 0xcc, 0x88},
            {0.0, 0x44, 0xcc, 0xcc},
            {0.0, 0x44, 0x00, 0x00},
            {0.0, 0x55, 0x00, 0x00},
            {0.0, 0x55, 0x00, 0x55},
            {0.0, 0x4c, 0x00, 0x99},
            {0.0, 0x49, 0x00, 0xdd},
            {0.0, 0x55, 0x55, 0x00},
            {0.0, 0x55, 0x55, 0x55},
            {0.0, 0x4c, 0x4c, 0x99},
            {0.0, 0x49, 0x49, 0xdd},
            {0.0, 0x4c, 0x99, 0x00},
            {0.0, 0x4c, 0x99, 0x4c},
            {0.0, 0x4c, 0x99, 0x99},
            {0.0, 0x49, 0x93, 0xdd},
            {0.0, 0x49, 0xdd, 0x00},
            {0.0, 0x49, 0xdd, 0x49},
            {0.0, 0x49, 0xdd, 0x93},
            {0.0, 0x49, 0xdd, 0xdd},
            {0.0, 0x4f, 0xee, 0xee},
            {0.0, 0x66, 0x00, 0x00},
            {0.0, 0x66, 0x00, 0x66},
            {0.0, 0x55, 0x00, 0xaa},
            {0.0, 0x4f, 0x00, 0xee},
            {0.0, 0x66, 0x66, 0x00},
            {0.0, 0x66, 0x66, 0x66},
            {0.0, 0x55, 0x55, 0xaa},
            {0.0, 0x4f, 0x4f, 0xee},
            {0.0, 0x55, 0xaa, 0x00},
            {0.0, 0x55, 0xaa, 0x55},
            {0.0, 0x55, 0xaa, 0xaa},
            {0.0, 0x4f, 0x9e, 0xee},
            {0.0, 0x4f, 0xee, 0x00},
            {0.0, 0x4f, 0xee, 0x4f},
            {0.0, 0x4f, 0xee, 0x9e},
            {0.0, 0x55, 0xff, 0xaa},
            {0.0, 0x55, 0xff, 0xff},
            {0.0, 0x77, 0x00, 0x00},
            {0.0, 0x77, 0x00, 0x77},
            {0.0, 0x5d, 0x00, 0xbb},
            {0.0, 0x55, 0x00, 0xff},
            {0.0, 0x77, 0x77, 0x00},
            {0.0, 0x77, 0x77, 0x77},
            {0.0, 0x5d, 0x5d, 0xbb},
            {0.0, 0x55, 0x55, 0xff},
            {0.0, 0x5d, 0xbb, 0x00},
            {0.0, 0x5d, 0xbb, 0x5d},
            {0.0, 0x5d, 0xbb, 0xbb},
            {0.0, 0x55, 0xaa, 0xff},
            {0.0, 0x55, 0xff, 0x00},
            {0.0, 0x55, 0xff, 0x55},
            {0.0, 0x88, 0x00, 0x88},
            {0.0, 0x88, 0x00, 0xcc},
            {0.0, 0x88, 0x44, 0x00},
            {0.0, 0x88, 0x44, 0x44},
            {0.0, 0x88, 0x44, 0x88},
            {0.0, 0x88, 0x44, 0xcc},
            {0.0, 0x88, 0x88, 0x00},
            {0.0, 0x88, 0x88, 0x44},
            {0.0, 0x88, 0x88, 0x88},
            {0.0, 0x88, 0x88, 0xcc},
            {0.0, 0x88, 0xcc, 0x00},
            {0.0, 0x88, 0xcc, 0x44},
            {0.0, 0x88, 0xcc, 0x88},
            {0.0, 0x88, 0xcc, 0xcc},
            {0.0, 0x88, 0x00, 0x00},
            {0.0, 0x88, 0x00, 0x44},
            {0.0, 0x99, 0x00, 0x4c},
            {0.0, 0x99, 0x00, 0x99},
            {0.0, 0x93, 0x00, 0xdd},
            {0.0, 0x99, 0x4c, 0x00},
            {0.0, 0x99, 0x4c, 0x4c},
            {0.0, 0x99, 0x4c, 0x99},
            {0.0, 0x93, 0x49, 0xdd},
            {0.0, 0x99, 0x99, 0x00},
            {0.0, 0x99, 0x99, 0x4c},
            {0.0, 0x99, 0x99, 0x99},
            {0.0, 0x93, 0x93, 0xdd},
            {0.0, 0x93, 0xdd, 0x00},
            {0.0, 0x93, 0xdd, 0x49},
            {0.0, 0x93, 0xdd, 0x93},
            {0.0, 0x93, 0xdd, 0xdd},
            {0.0, 0x99, 0x00, 0x00},
            {0.0, 0xaa, 0x00, 0x00},
            {0.0, 0xaa, 0x00, 0x55},
            {0.0, 0xaa, 0x00, 0xaa},
            {0.0, 0x9e, 0x00, 0xee},
            {0.0, 0xaa, 0x55, 0x00},
            {0.0, 0xaa, 0x55, 0x55},
            {0.0, 0xaa, 0x55, 0xaa},
            {0.0, 0x9e, 0x4f, 0xee},
            {0.0, 0xaa, 0xaa, 0x00},
            {0.0, 0xaa, 0xaa, 0x55},
            {0.0, 0xaa, 0xaa, 0xaa},
            {0.0, 0x9e, 0x9e, 0xee},
            {0.0, 0x9e, 0xee, 0x00},
            {0.0, 0x9e, 0xee, 0x4f},
            {0.0, 0x9e, 0xee, 0x9e},
            {0.0, 0x9e, 0xee, 0xee},
            {0.0, 0xaa, 0xff, 0xff},
            {0.0, 0xbb, 0x00, 0x00},
            {0.0, 0xbb, 0x00, 0x5d},
            {0.0, 0xbb, 0x00, 0xbb},
            {0.0, 0xaa, 0x00, 0xff},
            {0.0, 0xbb, 0x5d, 0x00},
            {0.0, 0xbb, 0x5d, 0x5d},
            {0.0, 0xbb, 0x5d, 0xbb},
            {0.0, 0xaa, 0x55, 0xff},
            {0.0, 0xbb, 0xbb, 0x00},
            {0.0, 0xbb, 0xbb, 0x5d},
            {0.0, 0xbb, 0xbb, 0xbb},
            {0.0, 0xaa, 0xaa, 0xff},
            {0.0, 0xaa, 0xff, 0x00},
            {0.0, 0xaa, 0xff, 0x55},
            {0.0, 0xaa, 0xff, 0xaa},
            {0.0, 0xcc, 0x00, 0xcc},
            {0.0, 0xcc, 0x44, 0x00},
            {0.0, 0xcc, 0x44, 0x44},
            {0.0, 0xcc, 0x44, 0x88},
            {0.0, 0xcc, 0x44, 0xcc},
            {0.0, 0xcc, 0x88, 0x00},
            {0.0, 0xcc, 0x88, 0x44},
            {0.0, 0xcc, 0x88, 0x88},
            {0.0, 0xcc, 0x88, 0xcc},
            {0.0, 0xcc, 0xcc, 0x00},
            {0.0, 0xcc, 0xcc, 0x44},
            {0.0, 0xcc, 0xcc, 0x88},
            {0.0, 0xcc, 0xcc, 0xcc},
            {0.0, 0xcc, 0x00, 0x00},
            {0.0, 0xcc, 0x00, 0x44},
            {0.0, 0xcc, 0x00, 0x88},
            {0.0, 0xdd, 0x00, 0x93},
            {0.0, 0xdd, 0x00, 0xdd},
            {0.0, 0xdd, 0x49, 0x00},
            {0.0, 0xdd, 0x49, 0x49},
            {0.0, 0xdd, 0x49, 0x93},
            {0.0, 0xdd, 0x49, 0xdd},
            {0.0, 0xdd, 0x93, 0x00},
            {0.0, 0xdd, 0x93, 0x49},
            {0.0, 0xdd, 0x93, 0x93},
            {0.0, 0xdd, 0x93, 0xdd},
            {0.0, 0xdd, 0xdd, 0x00},
            {0.0, 0xdd, 0xdd, 0x49},
            {0.0, 0xdd, 0xdd, 0x93},
            {0.0, 0xdd, 0xdd, 0xdd},
            {0.0, 0xdd, 0x00, 0x00},
            {0.0, 0xdd, 0x00, 0x49},
            {0.0, 0xee, 0x00, 0x4f},
            {0.0, 0xee, 0x00, 0x9e},
            {0.0, 0xee, 0x00, 0xee},
            {0.0, 0xee, 0x4f, 0x00},
            {0.0, 0xee, 0x4f, 0x4f},
            {0.0, 0xee, 0x4f, 0x9e},
            {0.0, 0xee, 0x4f, 0xee},
            {0.0, 0xee, 0x9e, 0x00},
            {0.0, 0xee, 0x9e, 0x4f},
            {0.0, 0xee, 0x9e, 0x9e},
            {0.0, 0xee, 0x9e, 0xee},
            {0.0, 0xee, 0xee, 0x00},
            {0.0, 0xee, 0xee, 0x4f},
            {0.0, 0xee, 0xee, 0x9e},
            {0.0, 0xee, 0xee, 0xee},
            {0.0, 0xee, 0x00, 0x00},
            {0.0, 0xff, 0x00, 0x00},
            {0.0, 0xff, 0x00, 0x55},
            {0.0, 0xff, 0x00, 0xaa},
            {0.0, 0xff, 0x00, 0xff},
            {0.0, 0xff, 0x55, 0x00},
            {0.0, 0xff, 0x55, 0x55},
            {0.0, 0xff, 0x55, 0xaa},
            {0.0, 0xff, 0x55, 0xff},
            {0.0, 0xff, 0xaa, 0x00},
            {0.0, 0xff, 0xaa, 0x55},
            {0.0, 0xff, 0xaa, 0xaa},
            {0.0, 0xff, 0xaa, 0xff},
            {0.0, 0xff, 0xff, 0x00},
            {0.0, 0xff, 0xff, 0x55},
            {0.0, 0xff, 0xff, 0xaa},
            {0.0, 0xff, 0xff, 0xff}
        }
    }

    local function linearInterpolation(c1, c2, mu)
        return c1*(1-mu) + c2*mu
    end

    local function cosineInterpolation(c1, c2, mu)
        local mu2 = (1 - math.cos(mu * math.pi)) / 2

        return c1*(1-mu2) + c2*mu2
    end

    local function interpolateColors (paletteCode, numberOfColors)
        local factor
        local steps = {}
        local cols = {}
        local interpolated = {}
        local interpolatedColors = {}

        local _continue = false
    
        local palv = palettes[paletteCode]

        if not palv then
            error('bad palette code')
        end

        -- pprint(palv)

        factor = 1.0 / numberOfColors

        if not _continue then
            for index, col in ipairs(palv) do
                -- pprint(index)
                -- pprint(col)
                if col[1] == 0.0 and index ~= 1 then
                    local stepRatio = (index + 1) / #palv
                    local step = math.floor(stepRatio * 100) / 100 -- truncate to 2 decimal precision
                    table.insert(steps, step)
                else
                    table.insert(steps, col[1])
                end
    
                local r, g, b = col[2], col[3], col[4]
                -- print('rgb', r, g, b)
                -- pprint(r)
                -- pprint(g)
                -- pprint(b)
                -- r = r / 0xff
                -- g = g / 0xff
                -- b = b / 0xff
                -- print('rgb>>', r, g, b)
                -- local uintColor = math.floor(r * 2^24 + g * 2^16 + b * 2^8)
                -- print('uint', uintColor)
                table.insert(cols, {r, g, b})
            end

            -- print('steps')
            -- pprint(steps)
    
            local min, max, minColor, maxColor
            if not (#palv == #steps and #palv == #cols) then
                _continue = true
            end

            if not _continue then
                local _continue2 = false

                for i = 0, 1 - factor, factor do
                    -- print('i', i)
                    for j = 1, #palv do
                        -- print('j', j)
                        if not (i >= steps[j] and i < steps[j + 1]) then
                            _continue2 = true
                        end
                        
                        if not _continue2 then
                            min = steps[j]
                            max = steps[j + 1]
                            minColorR = cols[j][1]
                            maxColorR = cols[j + 1][1]
                            -- print('color stuff', min, max, minColor, maxColor)
                            local uintColorR = cosineInterpolation(maxColorR, minColorR, (i - min) / (max - min))
                            -- print('color uint', uintColor)
                            minColorG = cols[j][2]
                            maxColorG = cols[j + 1][2]
                            -- print('color stuff', min, max, minColor, maxColor)
                            local uintColorG = cosineInterpolation(maxColorG, minColorG, (i - min) / (max - min))
                            -- print('color uint', uintColor)
                            minColorB = cols[j][3]
                            maxColorB = cols[j + 1][3]
                            -- print('color stuff', min, max, minColor, maxColor)
                            local uintColorB = cosineInterpolation(maxColorB, minColorB, (i - min) / (max - min))
                            -- print('color uint', uintColor)
                            table.insert(interpolated, {math.floor(uintColorR), math.floor(uintColorG), math.floor(uintColorB)})
                        end

                        _continue2 = false
                    end
                end

                -- pprint(interpolated)
                -- error('larp')
        
                for _, pixelValue in ipairs(interpolated) do
                    -- print('pixelValue')
                    -- pprint(pixelValue)
                    -- print(('%x'):format(pixelValue))
                    local r = pixelValue[1] / 0xff
                    local g = pixelValue[2] / 0xff
                    local b = pixelValue[3] / 0xff
        
                    table.insert(interpolatedColors, {r, g, b})
                end
            end

            _continue = false
        end
    
        return interpolatedColors
    end

    return {
        palettes = palettes,
        cosineInterpolation = cosineInterpolation,
        linearInterpolation = linearInterpolation,
        interpolateColors = interpolateColors,

        get = function (win)
            local palette = {}

            for i = 0, 15 do
                palette[i] = {win.getPaletteColor(2^i)}
            end

            return palette
        end,

        set = function (win, palette)
            for i = 0, 15 do
                win.setPaletteColor(2^i, table.unpack(palette[i]))
            end
        end,

        apply = function (win, scheme)
            local lerpColors = interpolateColors(scheme, 13)

            -- pprint(textutils.serialize(lerpColors))
            -- error('check')

            for i = 0, 15 do
                if i == 0 or i >= 14 then
                    win.setPaletteColor(2^i, term.nativePaletteColor(2^i))
                else
                    -- win.setPaletteColor(2^i, lerpColors[i+1].R, lerpColors[i+1].G, lerpColors[i+1].B)
                    win.setPaletteColor(2^i, lerpColors[i][1], lerpColors[i][2], lerpColors[i][3])
                end
            end
        end,
    }
end)()


-- local mon = peripheral.wrap('left')

-- local monw,monh = mon.getSize()
-- local winMon = window.create(mon, 1, 1, monw, monh, true)

local termw, termh = term.getSize()
-- local minDimension = math.min(termw * 2, termh * 3)
-- local squarew, squareh = math.floor(minDimension / 2), math.floor(minDimension / 3)
local curt = term.current()
local winSelf = window.create(curt, 1, 1, termw, termh, true)

-- local lerpColors = palettes.interpolateColors('AfternoonBlue', 13)

-- pprint(lerpColors)

-- pprint(winSelf)

local paletteOrder = {
    "SummerBeach",
    "AfternoonBlue",
    "Biochimist",
    "Fiesta",
    "Hippi",
    "Vivid",
}
local paletteIndex = 1

local origPalette = palettes.get(winSelf)

palettes.apply(winSelf, paletteOrder[paletteIndex])
-- error('lerp')

-- term.redirect(winMon)

local plotter = Plotter(winSelf)

local maxmaxIterations = 2000
local minmaxIterations = 25

local maxIterations = 250
-- local minX, maxX, minY, maxY = -2.5, 2.5, -2.5, 2.5
local miX, mxX, miY, mxY
local hei, wid -- = plotter.box.height, plotter.box.width
local minDim -- = math.min(hei, wid)
local xRatio, yRatio -- = wid / minDim, hei / minDim
local minX, maxX, minY, maxY -- = -2.5 * xRatio, 2.5 * xRatio, -2.5 * yRatio, 2.5 * yRatio

local function initializeGraphicsViewport(resize)
    if resize then
        termw, termh = term.getSize()

        winSelf.reposition(1, 1, termw, termh)
    else
        minX, maxX, minY, maxY = -2.5, 2.5, -2.5, 2.5
    end

    -- local oldXRatio, oldYRatio = xRatio, yRatio
    local oldHei, oldWid = hei, wid

    plotter = Plotter(winSelf)
    
    -- local maxmaxIterations = 2000
    -- local minmaxIterations = 25
    
    -- local maxIterations = 250
    -- local miX, mxX, miY, mxY
    hei, wid = plotter.box.height, plotter.box.width
    minDim = math.min(hei, wid)
    xRatio, yRatio = wid / minDim, hei / minDim

    local centerX, centerY = (maxX + minX) / 2, (maxY + minY) / 2
    local xDiff, yDiff = (maxX - minX) / 2, (maxY - minY) / 2

    if resize then
        -- print('centerX', centerX)
        -- print('centerY', centerY)
        -- print('xDiff', xDiff)
        -- print('yDiff', yDiff)
        -- error('yer')
    end
    -- local maxDiff = 
    -- minX, maxX, minY, maxY = (centerX - xDiff) * xRatio, (centerX + xDiff) * xRatio, (centerY - yDiff) * yRatio, (centerY + yDiff) * yRatio
    -- local xAdjust, yAdjust = (oldWid - wid) / 2, (oldHei - hei) / 2
    -- minX, maxX, minY, maxY = (minX + xAdjust) * xRatio, (maxX + xAdjust) * xRatio, (minY + yAdjust) * yRatio, (maxY + yAdjust) * yRatio
    minX, maxX, minY, maxY = -2.5 * xRatio, 2.5 * xRatio, -2.5 * yRatio, 2.5 * yRatio
end

initializeGraphicsViewport()

local scaleFactor = 0
local scaleFactorBaseline = math.log(10^-13 / (math.abs(maxX - minX)), 10^13)

local function remap( x, t1, t2, s1, s2 )
    local f = ( x - t1 ) / ( t2 - t1 )
    local g = f * ( s2 - s1 ) + s1
    return g;
end
    
-- Mandelbrot set implementation modified from https://rosettacode.org/wiki/Mandelbrot_set
local function drawMandelbrot()
    local pts, a, as, za, b, bs, zb, cnt, clr = {}
    for j = 0, hei - 1 do
        for i = 0, wid - 1 do
            a = remap( i, 0, wid, minX, maxX )
            b = remap( j, 0, hei, minY, maxY )
            cnt = 0; za = a; zb = b
            while( cnt < maxIterations ) do
                as = a * a - b * b; bs = 2 * a * b
                a = za + as; b = zb + bs
                if math.abs( a ) + math.abs( b ) > 16 then break end
                cnt = cnt + 1
            end
            if cnt == maxIterations then clr = 0
            else clr = math.ceil(remap( cnt, 0, maxIterations, 1, 12 ))
            end

            plotter.box:set_pixel(i + 1, j + 1, 2^(13-clr))
        end
    end
end
local function startFractal()
    -- calculate scaleFactor
    scaleFactor = math.log(10^-13 / (math.abs(maxX - minX)), 10^13) - scaleFactorBaseline

    -- if scaleFactor > 0.5 then
    --     maxIterations = 25
    -- elseif scaleFactor > 0.1 then
    --     maxIterations = 50
    -- elseif scaleFactor > 0.05 then
    --     maxIterations = 100
    -- elseif scaleFactor > 0.01 then
    --     maxIterations = 200
    -- else
    --     maxIterations = maxmaxIterations
    -- end

    -- draw fractal
    plotter:clear(colors.black)
    drawMandelbrot()
    plotter:render()

    local scaleFactorPrefix
    if scaleFactor > 1 then
        winSelf.setTextColor(colors.white)
        winSelf.setBackgroundColor(colors.red)
        
        scaleFactorPrefix = '!! '
    else
        winSelf.setTextColor(colors.white)
        winSelf.setBackgroundColor(colors.black)
        
        scaleFactorPrefix = '   '
    end
    winSelf.setCursorPos(1,1)
    winSelf.write(scaleFactorPrefix .. ("%3.4g"):format(scaleFactor * 100) .. ' %')

    winSelf.setTextColor(colors.white)
    winSelf.setBackgroundColor(colors.black)

    winSelf.setCursorPos(1,2)
    winSelf.write(maxIterations .. ' iterations')
    -- winSelf.setCursorPos(1,2)
    -- winSelf.write(maxX)
    -- winSelf.setCursorPos(1,3)
    -- winSelf.write(minY)
    -- winSelf.setCursorPos(1,4)
    -- winSelf.write(maxY)
end

startFractal()

local sx1, sy1, sx2, sy2 = 1,1,10,10
local isSelecting = false
local isSelected = false

local xNatDiff, yNatDiff = 0, 0
local xDiff, yDiff = 0, 0

parallel.waitForAny(
    -- terminate cleanup
    function ()
        local event = {os.pullEventRaw('terminate')}

        plotter:clear(colors.black)
        plotter:render()

        winSelf.clear()
        winSelf.setCursorPos(1,1)
        term.setCursorPos(1,1)

        palettes.set(term, origPalette)
    end,

    -- overprint
    function ()
        while true do
            if isSelecting then
                winSelf.setVisible(false)
                startFractal()
                -- plotter:drawBoxSometimes(sx1 * 2 - 1, sy1 * 3 - 2, sx2 * 2, sy2 * 3, colors.black, 2)
                plotter:render()
                -- winSelf.setCursorPos(1,1)
                -- winSelf.write(xNatDiff)
                -- winSelf.setCursorPos(1,2)
                -- winSelf.write(xDiff)
                winSelf.setVisible(true)
            end

            sleep(0.1)
        end
    end,
    
    -- control listener
    function ()
        while true do
            local event = {os.pullEventRaw()}

            -- sleep(1)

            if event[1] == 'mouse_scroll' then
                isSelecting = false
                isSelected = false

                sx1, sy1 = event[3], event[4]

                local sx1nat = sx1 * 2
                local sy1nat = sy1 * 3 - 1

                local xAdj = event[2] * (maxX - minX) / 10
                local yAdj = event[2] * (maxY - minY) / 10

                local xRatio = (wid - sx1nat) / wid
                local yRatio = (hei - sy1nat) / hei

                minX = minX - xAdj * (1 - xRatio)
                maxX = maxX + xAdj * xRatio
                minY = minY - yAdj * (1 - yRatio)
                maxY = maxY + yAdj * yRatio

                -- miX = remap( sx1nat, 1, wid, minX, maxX )
                -- mxX = remap( sx2nat, 1, wid, minX, maxX )
                -- miY = remap( sy1nat, 1, hei, minY, maxY )
                -- mxY = remap( sy2nat, 1, hei, minY, maxY )
                -- minX = miX; maxX = mxX; minY = miY; maxY = mxY

                startFractal()
            end

            if event[1] == 'mouse_click' then
                -- if event[2] == 1 then
                    isSelecting = true
                    isSelected = false

                    sx1, sy1 = event[3], event[4]
                    sx2, sy2 = sx1, sy1
                -- end
            elseif event[1] == 'mouse_drag' then
                if isSelecting then
                    sx2, sy2 = event[3], event[4]
                    
                    local sx1nat = sx1 * 2
                    local sy1nat = sy1 * 3
                    local sx2nat = sx2 * 2
                    local sy2nat = sy2 * 3

                    xNatDiff = sx2nat - sx1nat
                    xDiff = (xNatDiff > 0 and 1 or -1) * (remap(math.abs(xNatDiff), 0, wid, minX, maxX ) - minX)
                    yNatDiff = sy2nat - sy1nat
                    yDiff = (yNatDiff > 0 and 1 or -1) * (remap(math.abs(yNatDiff), 0, hei, minY, maxY ) - minY)

                    -- local xRatio = (wid - sx1nat) / wid
                    -- local yRatio = (hei - sy1nat) / hei
    
                    minX = minX - xDiff
                    maxX = maxX - xDiff
                    minY = minY - yDiff
                    maxY = maxY - yDiff

                    sx1, sy1 = sx2, sy2
                end
            elseif event[1] == 'mouse_up' then
                isSelecting = false
                -- if isSelecting then
                --     isSelecting = false
                --     isSelected = true

                --     local sx1nat = sx1 * 2 - 1
                --     local sy1nat = sy1 * 3 - 2
                --     local sx2nat = sx2 * 2
                --     local sy2nat = sy2 * 3

                --     miX = remap( sx1nat, 1, wid, minX, maxX )
                --     mxX = remap( sx2nat, 1, wid, minX, maxX )
                --     miY = remap( sy1nat, 1, hei, minY, maxY )
                --     mxY = remap( sy2nat, 1, hei, minY, maxY )
                --     minX = miX; maxX = mxX; minY = miY; maxY = mxY

                --     startFractal()
                -- end
                startFractal()
            elseif event[1] == 'key' then
                if event[2] == keys.up then
                    xNatDiff = 0
                    xDiff = (xNatDiff > 0 and 1 or -1) * (remap(math.abs(xNatDiff), 0, wid, minX, maxX ) - minX)
                    yNatDiff = 5
                    yDiff = (yNatDiff > 0 and 1 or -1) * (remap(math.abs(yNatDiff), 0, hei, minY, maxY ) - minY)

                    -- local xRatio = (wid - sx1nat) / wid
                    -- local yRatio = (hei - sy1nat) / hei
    
                    minX = minX - xDiff
                    maxX = maxX - xDiff
                    minY = minY - yDiff
                    maxY = maxY - yDiff

                    sx1, sy1 = sx2, sy2
                elseif event[2] == keys.down then
                    xNatDiff = 0
                    xDiff = (xNatDiff > 0 and 1 or -1) * (remap(math.abs(xNatDiff), 0, wid, minX, maxX ) - minX)
                    yNatDiff = -5
                    yDiff = (yNatDiff > 0 and 1 or -1) * (remap(math.abs(yNatDiff), 0, hei, minY, maxY ) - minY)

                    -- local xRatio = (wid - sx1nat) / wid
                    -- local yRatio = (hei - sy1nat) / hei
    
                    minX = minX - xDiff
                    maxX = maxX - xDiff
                    minY = minY - yDiff
                    maxY = maxY - yDiff

                    sx1, sy1 = sx2, sy2
                elseif event[2] == keys.left then
                    xNatDiff = 5
                    xDiff = (xNatDiff > 0 and 1 or -1) * (remap(math.abs(xNatDiff), 0, wid, minX, maxX ) - minX)
                    yNatDiff = 0
                    yDiff = (yNatDiff > 0 and 1 or -1) * (remap(math.abs(yNatDiff), 0, hei, minY, maxY ) - minY)

                    -- local xRatio = (wid - sx1nat) / wid
                    -- local yRatio = (hei - sy1nat) / hei
    
                    minX = minX - xDiff
                    maxX = maxX - xDiff
                    minY = minY - yDiff
                    maxY = maxY - yDiff

                    sx1, sy1 = sx2, sy2
                elseif event[2] == keys.right then
                    xNatDiff = -5
                    xDiff = (xNatDiff > 0 and 1 or -1) * (remap(math.abs(xNatDiff), 0, wid, minX, maxX ) - minX)
                    yNatDiff = 0
                    yDiff = (yNatDiff > 0 and 1 or -1) * (remap(math.abs(yNatDiff), 0, hei, minY, maxY ) - minY)

                    -- local xRatio = (wid - sx1nat) / wid
                    -- local yRatio = (hei - sy1nat) / hei
    
                    minX = minX - xDiff
                    maxX = maxX - xDiff
                    minY = minY - yDiff
                    maxY = maxY - yDiff

                    sx1, sy1 = sx2, sy2
                elseif event[2] == keys.minus then
                    -- isSelecting = false
                    -- isSelected = false
    
                    sx1, sy1 = termw / 2, termh / 2
    
                    local sx1nat = sx1 * 2
                    local sy1nat = sy1 * 3 - 1
    
                    local xAdj = 1 * (maxX - minX) / 10
                    local yAdj = 1 * (maxY - minY) / 10
    
                    local xRatio = (wid - sx1nat) / wid
                    local yRatio = (hei - sy1nat) / hei
    
                    minX = minX - xAdj * (1 - xRatio)
                    maxX = maxX + xAdj * xRatio
                    minY = minY - yAdj * (1 - yRatio)
                    maxY = maxY + yAdj * yRatio
    
                    -- miX = remap( sx1nat, 1, wid, minX, maxX )
                    -- mxX = remap( sx2nat, 1, wid, minX, maxX )
                    -- miY = remap( sy1nat, 1, hei, minY, maxY )
                    -- mxY = remap( sy2nat, 1, hei, minY, maxY )
                    -- minX = miX; maxX = mxX; minY = miY; maxY = mxY
    
                    startFractal()
                elseif event[2] == keys.equals then
                    -- isSelecting = false
                    -- isSelected = false
    
                    sx1, sy1 = termw / 2, termh / 2
    
                    local sx1nat = sx1 * 2
                    local sy1nat = sy1 * 3 - 1
    
                    local xAdj = -1 * (maxX - minX) / 10
                    local yAdj = -1 * (maxY - minY) / 10
    
                    local xRatio = (wid - sx1nat) / wid
                    local yRatio = (hei - sy1nat) / hei
    
                    minX = minX - xAdj * (1 - xRatio)
                    maxX = maxX + xAdj * xRatio
                    minY = minY - yAdj * (1 - yRatio)
                    maxY = maxY + yAdj * yRatio
    
                    -- miX = remap( sx1nat, 1, wid, minX, maxX )
                    -- mxX = remap( sx2nat, 1, wid, minX, maxX )
                    -- miY = remap( sy1nat, 1, hei, minY, maxY )
                    -- mxY = remap( sy2nat, 1, hei, minY, maxY )
                    -- minX = miX; maxX = mxX; minY = miY; maxY = mxY
    
                    startFractal()
                elseif event[2] == keys.period then
                    maxIterations = math.min(maxIterations + 25, maxmaxIterations)
                elseif event[2] == keys.comma then
                    maxIterations = math.max(maxIterations - 25, minmaxIterations)
                elseif event[2] == keys.p then
                    paletteIndex = (paletteIndex % #paletteOrder) + 1

                    palettes.apply(winSelf, paletteOrder[paletteIndex])
                elseif event[2] == keys.r then
                    minX, maxX, minY, maxY = -2.5 * xRatio, 2.5 * xRatio, -2.5 * yRatio, 2.5 * yRatio

                    startFractal()

                    -- isSelecting = false
                elseif event[2] == keys.q then
                    os.queueEvent('terminate')
                end

                sleep(0.1)

                startFractal()
            elseif event[1] == 'monitor_touch' then
                isSelecting = false
                isSelected = false

                sx1, sy1 = event[3], event[4]

                local sx1nat = sx1 * 2
                local sy1nat = sy1 * 3 - 1

                local xAdj = -1 * (maxX - minX) / 10
                local yAdj = -1 * (maxY - minY) / 10

                local xRatio = (wid - sx1nat) / wid
                local yRatio = (hei - sy1nat) / hei

                minX = minX - xAdj * (1 - xRatio)
                maxX = maxX + xAdj * xRatio
                minY = minY - yAdj * (1 - yRatio)
                maxY = maxY + yAdj * yRatio

                -- miX = remap( sx1nat, 1, wid, minX, maxX )
                -- mxX = remap( sx2nat, 1, wid, minX, maxX )
                -- miY = remap( sy1nat, 1, hei, minY, maxY )
                -- mxY = remap( sy2nat, 1, hei, minY, maxY )
                -- minX = miX; maxX = mxX; minY = miY; maxY = mxY

                startFractal()
            elseif event[1] == 'term_resize' then
                initializeGraphicsViewport(true)
                startFractal()
            end
        end
    end
)