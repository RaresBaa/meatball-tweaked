local sx, sy = term.getSize()
local snakebody = {{5, 5}, {6, 5}, {7, 5}}
local snakehead = {snakebody[table.maxn(snakebody)][1], snakebody[table.maxn(snakebody)][2]}
local snakeface = "right"
local fed = false
local food = {10, 14}

local function tablecheck(tab, var)
	check = false

	for i, v in ipairs(tab) do
		if var == v then
			check = true
		end
	end

	return check
end

local function tabletablecheck(tab, var)
	check = false

	for i, v in ipairs(tab) do
		for i, v in ipairs(tab[i]) do
			if var == v then
				check = true
			end
		end
	end

	return check
end

local function poscheck(pos1, pos2)
	check = false

	if tabletablecheck(pos1, pos2[1]) and tabletablecheck(pos1, pos2[2]) then
		check = true
	end

	return check
end

local function snakeshow()
	term.setBackgroundColor(colors.white)
	term.clear()
	term.setBackgroundColor(colors.black)

	for a = 1, #snakebody do
		term.setCursorPos(snakebody[a][1], snakebody[a][2])
		term.blit(" ", "d", "d")
	end

	term.setCursorPos(food[1], food[2])
	term.blit(" ", "e", "e")
end

local function snakefeed()
	fed = true

	local cease = false

	while cease == false do
		food = {math.random(1, sx), math.random(1, sy)}

		if not poscheck(snakebody, food) then
			cease = true
		end
	end
end

local function snakemove()
	if fed == true then
		if snakeface == "up" then
			table.insert(snakebody, {snakehead[1], snakehead[2] - 1})
		elseif snakeface == "down" then
			table.insert(snakebody, {snakehead[1], snakehead[2] + 1})
		elseif snakeface == "right" then
			table.insert(snakebody, {snakehead[1] + 1, snakehead[2]})
		elseif snakeface == "left" then
			table.insert(snakebody, {snakehead[1] - 1, snakehead[2]})
		end

		fed = false
	elseif fed == false then
		if snakeface == "up" then
			table.insert(snakebody, {snakehead[1], snakehead[2] - 1})
			table.remove(snakebody, 1)
		elseif snakeface == "down" then
			table.insert(snakebody, {snakehead[1], snakehead[2] + 1})
			table.remove(snakebody, 1)
		elseif snakeface == "right" then
			table.insert(snakebody, {snakehead[1] + 1, snakehead[2]})
			table.remove(snakebody, 1)
		elseif snakeface == "left" then
			table.insert(snakebody, {snakehead[1] - 1, snakehead[2]})
			table.remove(snakebody, 1)
		end
	end

	snakehead = {snakebody[table.maxn(snakebody)][1], snakebody[table.maxn(snakebody)][2]}
end

local function snakelive()
	local check = true

	for a = 1, #snakebody - 1 do
        if snakehead[1] == snakebody[a][1] and snakehead[2] == snakebody[a][2] then
            check = false
        end
    end

	if snakehead[1] < 1 or snakehead[1] > sx or snakehead[2] < 1 or snakehead[2] > sy then
		check = false
	end

	return check
end

local function snaketime()
	local timer = os.startTimer(0.14)

	local face = snakeface

	while true do
		local event, par1 = os.pullEvent()

		if event == "timer" and par1 == timer then
			if face == "up" and snakeface ~= "down" then
				snakeface = face
			elseif face == "down" and snakeface ~= "up" then
				snakeface = face
			elseif face == "right" and snakeface ~= "left" then
				snakeface = face
			elseif face == "left" and snakeface ~= "right" then
				snakeface = face
			end

			snakemove()

			break
		elseif event == "key" and par1 == keys.up and face ~= "down" then
			face = "up"
		elseif event == "key" and par1 == keys.down and face ~= "up" then
			face = "down"
		elseif event == "key" and par1 == keys.right and face ~= "left" then
			face = "right"
		elseif event == "key" and par1 == keys.left and face ~= "right" then
			face = "left"
		end
	end
end

local function snakegame()
	while snakelive() == true do
		snakeshow()
		snaketime()

		if snakehead[1] == food[1] and snakehead[2] == food[2] then
			snakefeed()
		end
	end

	term.clear()
	term.setCursorPos(1, 1)

	print("Score : "..#snakebody - 3)

	sleep(1)
end

snakegame()