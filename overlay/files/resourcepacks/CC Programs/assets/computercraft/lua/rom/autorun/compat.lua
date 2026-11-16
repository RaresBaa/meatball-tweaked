-- Backports of small CC:Tweaked APIs from newer versions, so programs written for
-- CC:T 1.95+ also run on 1.89.2 (Minecraft 1.12.2).

-- fs.combine: newer versions accept any number of path segments (including just one).
if not pcall(fs.combine, "a") then
    local combine = fs.combine
    fs.combine = function(path, ...)
        local n = select("#", ...)
        if n == 0 then return combine(path, "") end
        for i = 1, n do path = combine(path, (select(i, ...))) end
        return path
    end
end

-- File handles: ComputerCraft 1.79 and older accepted `handle:write(x)` as well as
-- `handle.write(x)`. On 1.89 the colon form silently writes "{}" (or errors for
-- readLine), which corrupts saves made by older programs. Accept both forms again.
local function colonSafe(handle)
    for name, fn in pairs(handle) do
        if type(fn) == "function" then
            handle[name] = function(self, ...)
                if self == handle then return fn(...) end
                return fn(self, ...)
            end
        end
    end
    return handle
end
local open = fs.open
fs.open = function(...)
    local handle, err = open(...)
    if type(handle) ~= "table" then return handle, err end
    return colonSafe(handle), err
end
