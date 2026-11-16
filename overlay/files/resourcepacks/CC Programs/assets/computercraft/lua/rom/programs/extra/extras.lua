-- Lists the games and programs from the "CC Programs" resource pack.
-- Usage: extras [category]
local catalog = dofile("/rom/extra/catalog.lua")
local filter = ...
local colour = term.isColour()
local w = term.getSize()

local function setColour(c) if colour then term.setTextColour(c) end end

local shown = false
for _, cat in ipairs(catalog) do
    if not filter or cat.name:lower():find(filter:lower(), 1, true) then
        shown = true
        setColour(colours.yellow)
        textutils.pagedPrint(cat.name)
        for _, p in ipairs(cat.programs) do
            local usable = colour or not (p.needs[1] == "advanced" or p.needs[2] == "advanced")
            setColour(usable and colours.lime or colours.grey)
            write(("%-14s"):format(p.cmd))
            setColour(usable and colours.white or colours.grey)
            local desc = p.desc
            if #desc > w - 15 then desc = desc:sub(1, w - 18) .. "..." end
            textutils.pagedPrint(desc)
        end
    end
end
setColour(colours.white)
if not shown then
    printError("No category matches '" .. filter .. "'.")
    local names = {}
    for _, cat in ipairs(catalog) do names[#names + 1] = cat.name end
    print("Categories: " .. table.concat(names, ", "))
else
    print('Type "help <program>" for details.')
end
