--- Backport of CC:Tweaked's `cc.strings` module (added in 1.95) for 1.89.2.
-- @module cc.strings

local expect = require "cc.expect".expect

--- Wraps a block of text, so that each line fits within the given width.
local function wrap(text, width)
    expect(1, text, "string")
    expect(2, width, "number", "nil")
    width = width or term.getSize()

    local lines, lines_n, current_line = {}, 0, ""
    local function push_line()
        lines_n = lines_n + 1
        lines[lines_n] = current_line
        current_line = ""
    end

    local pos, length = 1, #text
    local sub, match = string.sub, string.match
    while pos <= length do
        local head = sub(text, pos, pos)
        if head == " " or head == "\t" then
            local whitespace = match(text, "^[ \t]+", pos)
            current_line = current_line .. whitespace
            pos = pos + #whitespace
        elseif head == "\n" then
            push_line()
            pos = pos + 1
        else
            local word = match(text, "^[^ \t\n]+", pos)
            pos = pos + #word
            if #word > width then
                -- Word is longer than a line: split it across several.
                while #word > 0 do
                    local space_remaining = width - #current_line - 1
                    if space_remaining <= 0 then
                        push_line()
                        space_remaining = width
                    end
                    current_line = current_line .. sub(word, 1, space_remaining)
                    word = sub(word, space_remaining + 1)
                end
            else
                if width - #current_line < #word then push_line() end
                current_line = current_line .. word
            end
        end
    end
    push_line()

    -- Trim whitespace longer than width.
    for k, line in pairs(lines) do
        line = line:sub(1, width)
        lines[k] = line
    end

    return lines
end

--- Makes the input string a fixed width, padding with spaces or truncating.
local function ensure_width(line, width)
    expect(1, line, "string")
    expect(2, width, "number", "nil")
    width = width or term.getSize()

    line = line:sub(1, width)
    if #line < width then
        line = line .. (" "):rep(width - #line)
    end

    return line
end

--- Split a string into parts, each separated by a deliminator.
local function split(str, deliminator, plain, limit)
    expect(1, str, "string")
    expect(2, deliminator, "string")
    expect(3, plain, "boolean", "nil")
    expect(4, limit, "number", "nil")

    local out, out_n, pos = {}, 0, 1
    while not limit or out_n < limit - 1 do
        local start, finish = str:find(deliminator, pos, plain)
        if not start then break end

        out_n = out_n + 1
        out[out_n] = str:sub(pos, start - 1)

        -- Require us to advance by at least one character.
        if finish < start then error("separator is empty", 2) end

        pos = finish + 1
    end

    if pos == 1 then return { str } end

    out[out_n + 1] = str:sub(pos)
    return out
end

return {
    wrap = wrap,
    ensure_width = ensure_width,
    split = split,
}
