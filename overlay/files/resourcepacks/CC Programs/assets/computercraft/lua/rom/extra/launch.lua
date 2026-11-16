-- Shared launcher for the "CC Programs" resource pack.
-- Programs live read-only in /rom/extra/<id>. Ones that save data are copied to
-- /extra/<id> on first run and run from there.

local function need(info, kind)
    for _, n in ipairs(info.needs) do if n == kind then return true end end
    return false
end

local function copyMissing(from, to)
    if fs.isDir(from) then
        if not fs.exists(to) then fs.makeDir(to) end
        for _, name in ipairs(fs.list(from)) do copyMissing(fs.combine(from, name), fs.combine(to, name)) end
    elseif not fs.exists(to) then
        fs.copy(from, to)
    end
end

-- Most of these programs expect to be installed in the root folder and open their
-- assets as "models/x" or "lib/f". While one runs, a relative path that exists in the
-- program's own folder resolves there; everything else is left alone.
local MAPPED = { "open", "exists", "isDir", "list", "getSize", "isReadOnly", "getDrive" }

local function runInFolder(dir, fn, ...)
    local original = {}
    local exists = fs.exists
    local function map(path)
        if type(path) ~= "string" or path:find("^[/\\]") then return path end
        local inDir = fs.combine(dir, path)
        if exists(inDir) then return inDir end
        return path
    end
    for _, name in ipairs(MAPPED) do
        local native = fs[name]
        original[name] = native
        fs[name] = function(path, ...) return native(map(path), ...) end
    end
    local result = fn(...)
    for name, native in pairs(original) do fs[name] = native end
    return result
end

return function(shell, info, ...)
    if need(info, "advanced") and not term.isColour() then
        printError(info.title .. " needs an advanced computer.")
        return false
    end
    if need(info, "http") and not http then
        printError(info.title .. " needs the HTTP API, which is disabled.")
        return false
    end
    if need(info, "turtle") and not turtle then
        printError(info.title .. " only runs on a turtle.")
        return false
    end

    local dir = "/rom/extra/" .. info.id
    if info.mode == "copy" then
        local dest = "/extra/" .. info.id
        if not fs.exists(fs.combine(dest, info.entry)) then
            local free = fs.getFreeSpace("/")
            if free < info.size + 2048 then
                printError(("Not enough disk space for %s: it needs %d KB, %d KB free."):format(
                    info.title, math.ceil(info.size / 1024), math.floor(free / 1024)))
                print("Delete unused programs (for example other folders in /extra) and try again.")
                return false
            end
            print(("Installing %s to %s ..."):format(info.title, dest))
            copyMissing(dir, dest)
        end
        dir = dest
    end

    local path = "/" .. fs.combine(dir, info.entry)
    if info.cwd ~= "program" then return shell.execute(path, ...) end

    local oldDir = shell.dir()
    shell.setDir(dir)
    local ok = runInFolder(dir, shell.execute, path, ...)
    shell.setDir(oldDir)
    return ok
end
