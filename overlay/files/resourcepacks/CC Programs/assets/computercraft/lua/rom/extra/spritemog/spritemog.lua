local camera = {x = 30,y = 30}
local selectedColour = 1
local width,height = term.getSize()
local palette = {}
local originalPalette = {}
local sprite = {}
local keysDown = {}
local colourSelected = colors.black
local backgroundColour = colors.purple
local spriteWindow = window.create(term.current(),1,4,width,height-3)
local guiWindow = window.create(term.current(),1,1,width,3)
local brightness = 1
term.clear()

local function writeAt(contents,x,y,text,background,win)
	win.setBackgroundColor(background)
	win.setTextColor(text)
	win.setCursorPos(x,y)
	win.write(contents)
end

local function clear(win,colour)
	win.setBackgroundColor(colour)
	win.clear()
end

local function loadPalette()
	
	if not fs.isDir(shell.resolve("palettes")) then
		fs.makeDir(shell.resolve("palettes"))
		fs.makeDir(shell.resolve("palettes/default"))
		fs.makeDir(shell.resolve("palettes/default/sprites"))
		file = fs.open(shell.resolve("palettes/default/default.plt"),"w")
		file.writeLine("{0xF0F0F0,0xF2B233,0xE57FD8,0x99B2F2,0xDEDE6C,0x7FCC19,0xF2B2CC,0x4C4C4C,0x999999,0x4C99B2,0xB266E5,0x3366CC,0x7F664C,0x57A64E,0xCC4C4C,0x111111}")
		file.close()
	end
	
	local function drawHeader()
		clear(paletteSelectionWindow,colors.white)
		writeAt("-SELECT PALETTE-",2,2,colors.gray,colors.white,paletteSelectionWindow)		
	end
	
	local paletteList = fs.list(shell.resolve("palettes"))
	
	paletteSelectionWindow = window.create(term.current(),3,3,18,#paletteList + 3)
	
	drawHeader()
	
	for i = 1,#paletteList do
		writeAt(paletteList[i],3,i+2,colors.blue,colors.white,paletteSelectionWindow)
	end

	while true do
		event,key,x,y = os.pullEvent()
		
		if event == "mouse_click" and key == 1 and x > 3 and x < 21 and y > 4 and y < #paletteList + 5 then
		
			drawHeader()
			
			for i = 1,#paletteList do
			
				if i + 4 == y then
					writeAt(paletteList[i],3,i+2,colors.blue,colors.white,paletteSelectionWindow)
				else
					writeAt(paletteList[i],3,i+2,colors.lightGray,colors.white,paletteSelectionWindow)
				end

			end
			
			sleep(0.15)
			
			file = fs.open(shell.resolve("palettes/"..paletteList[y-4].."/"..paletteList[y-4]..".plt"),"r")
			
			palette = textutils.unserialize(file.readLine(),{compact = true})
			palette.name = paletteList[y-4]
			file.close()
			-- Snapshot for dirty-checking
			originalPalette = {}
			for i = 1,16 do originalPalette[i] = palette[i] end
			paletteSelectionWindow.setBackgroundColor(colors.black)
			paletteSelectionWindow.reposition(3,3,18,16)
			
				for i = 0,15 do
					term.setPaletteColor(2^i,palette[i+1])	
				end
			
			break
		end
	end
end

local function loadSprite()
	
	local function drawHeader()
		clear(spriteSelectionWindow,colors.white)
		writeAt("-SELECT SPRITE-",2,2,colors.gray,colors.white,spriteSelectionWindow)
	end
	
	local spriteList = fs.list(shell.resolve("palettes/"..palette.name.."/sprites"))
	
	spriteList[#spriteList + 1] = "newSprite"
	
	spriteSelectionWindow = window.create(term.current(),3,3,40,#spriteList + 3)
	
	drawHeader()
	
	for i = 1,#spriteList do
		writeAt(spriteList[i],3,i+2,colors.blue,colors.white,spriteSelectionWindow)
	end

	while true do
		event,key,x,y = os.pullEvent()
		
		if event == "mouse_click" and key == 1 and x > 3 and x < 21 and y > 4 and y < #spriteList + 5 then
		
			drawHeader()
			
			for i = 1,#spriteList do
			
				if i + 4 == y then
					writeAt(spriteList[i],3,i+2,colors.blue,colors.white,spriteSelectionWindow)
				else
					writeAt(spriteList[i],3,i+2,colors.lightGray,colors.white,spriteSelectionWindow)
				end
				
			end
			
			sleep(0.15)
			
			if spriteList[y-4] == "newSprite" then
				sprite = {{1,1,colors.black},{16,1,colors.black},{1,16,colors.black},{16,16,colors.black}}
				sprite.name = "unnamedSprite"
			else
				file = fs.open(shell.resolve("palettes/"..palette.name.."/sprites/"..spriteList[y-4]),"r")
				sprite = textutils.unserialize(file.readLine(),{compact = true})
				sprite.name = spriteList[y-4]
				file.close()
			end
			break
		end
	end	
end

local function drawSprite()
	
	for i = 1,#sprite do

			for y = 1,2 do
				spriteWindow.setCursorPos	(		
									math.floor(sprite[i][1] * 3 + camera.x),
									math.floor(sprite[i][2] * 2 + camera.y) + y
									)
									
				spriteWindow.setBackgroundColor(sprite[i][3])
				if sprite[i][1] == 0 and sprite[i][2] == 0 and y == 2 then
					spriteWindow.write("--+")
				elseif sprite[i][1] == 0 then
					spriteWindow.write("  \124")
				elseif sprite[i][2] == 0 and y == 2 then
					spriteWindow.write("---")
				else
					spriteWindow.write("   ")
				end
			end

	end
end

local function drawHeader()

	clear(guiWindow,colors.white)
	writeAt("SpriteMog V1.2".."        Brightness: "..brightness,2,2,colors.black,colors.white,guiWindow)

	writeAt(":               :              :           :",width-43,1,colors.black,colors.white,guiWindow)
	writeAt(": COLOUR SELECT : PALETTE EDIT : SAVE/EXIT :",width-43,2,colors.black,colors.white,guiWindow)
	writeAt(":               :              :           :",width-43,3,colors.black,colors.white,guiWindow)

end

local function drawScreen()
	
	clear(spriteWindow,backgroundColour)
	drawHeader()
	
	for i = 1,width do
		writeAt("\124",2+camera.x,i,colors.white,backgroundColour,spriteWindow)
		writeAt("-",i,camera.y+2,colors.white,backgroundColour,spriteWindow)
	end
	
	writeAt("+",2+camera.x,camera.y+2,colors.white,backgroundColour,spriteWindow)
	drawSprite()
end

local function colourSelect()
	local colourSelectWindow = window.create(term.current(),width-43,1,17,36)

	for i = 1,35 do
		writeAt(":               :",1,i,colors.white,colors.lightGray,colourSelectWindow)
	end
	
	writeAt(": COLOUR SELECT :",1,2,colors.white,colors.lightGray,colourSelectWindow)
	writeAt("\96---------------'",1,36,colors.white,colors.lightGray,colourSelectWindow)

	
	for i = 0,15 do
		writeAt("               ",2,2*i+4,2^i,2^i,colourSelectWindow)
		writeAt("               ",2,2*i+5,2^i,2^i,colourSelectWindow)	
	end
	
	while true do
		local event,key,x,y = os.pullEvent()
		
		if event == "mouse_click" then
			if x > width - 43 and x < width - 43 + 16 and y > 3 and y < 36 then
				if key == 1 then
					colourSelected = 2^math.floor((y - 4) / 2)
				elseif key == 2 then
					backgroundColour = 2^math.floor((y - 4) / 2)
				end
			end
			break
		end
	end
	timer = os.startTimer(0.05)
end

local function paletteEdit()
	local listWinX = width - 27
	local listWinY = 1
	local listWinW = 16
	local listWinH = 36
	local paletteEditWindow = window.create(term.current(), listWinX, listWinY, listWinW, listWinH)
	local iW = listWinW - 2  -- 14 inner chars

	local function drawPaletteList()
		for i = 1, listWinH - 1 do
			writeAt(":              :", 1, i, colors.white, colors.lightGray, paletteEditWindow)
		end
		writeAt("\96--------------'", 1, listWinH, colors.white, colors.lightGray, paletteEditWindow)
		writeAt(": PALETTE EDIT :", 1, 2, colors.white, colors.lightGray, paletteEditWindow)
		for i = 0, 15 do
			writeAt("              ", 2, 2*i+4, 2^i, 2^i, paletteEditWindow)
			writeAt("              ", 2, 2*i+5, 2^i, 2^i, paletteEditWindow)
		end
	end

	local function openColourEditor(colorKey)
		local colourIndex = colorKey + 1
		local r, g, b

		local function loadRGB()
			local rf, gf, bf = colors.unpackRGB(palette[colourIndex])
			r = math.floor(0.5 + rf * 255)
			g = math.floor(0.5 + gf * 255)
			b = math.floor(0.5 + bf * 255)
		end

		local function applyRGB()
			palette[colourIndex] = colors.packRGB(r / 255, g / 255, b / 255)
			term.setPaletteColor(2^colorKey, palette[colourIndex])
		end

		local blank = string.rep(" ", iW)

		local function fmtVal(v)
			local s = tostring(v)
			return string.rep(" ", 3 - #s) .. s
		end

		local function drawEditor()
			-- Full border redraw
			for i = 1, listWinH - 1 do
				writeAt(":              :", 1, i, colors.white, colors.lightGray, paletteEditWindow)
			end
			writeAt("\96--------------'", 1, listWinH, colors.white, colors.lightGray, paletteEditWindow)
			writeAt(": PALETTE EDIT :", 1, 2, colors.white, colors.lightGray, paletteEditWindow)

			-- Rows 4-5: colour preview
			local pc = 2^colorKey
			writeAt(blank, 2, 4, pc, pc, paletteEditWindow)
			writeAt(blank, 2, 5, pc, pc, paletteEditWindow)

			-- Rows 7-9: UP button (3 tall), mid row = ^ labels
			writeAt(blank,              2,  7, colors.white, colors.gray, paletteEditWindow)
			writeAt("  ^    ^    ^ ", 2,  8, colors.white, colors.gray, paletteEditWindow)
			writeAt(blank,              2,  9, colors.white, colors.gray, paletteEditWindow)

			-- Row 10: R G B labels on lightGray, values in black text below them
			writeAt("  R    G    B ", 2, 10, colors.black, colors.lightGray, paletteEditWindow)

			-- Row 11: numeric values (lightGray bg, black text)
			local valStr = " " .. fmtVal(r) .. "  " .. fmtVal(g) .. "  " .. fmtVal(b)
			writeAt(valStr,             2, 11, colors.black, colors.lightGray, paletteEditWindow)

			-- Rows 12-14: DOWN button (3 tall), mid row = v labels
			writeAt(blank,              2, 12, colors.white, colors.gray, paletteEditWindow)
			writeAt("  v    v    v ", 2, 13, colors.white, colors.gray, paletteEditWindow)
			writeAt(blank,              2, 14, colors.white, colors.gray, paletteEditWindow)

			-- Rows 16-18: HEX button
			writeAt(blank,           2, 16, colors.white, colors.gray, paletteEditWindow)
			writeAt("  INPUT HEX   ", 2, 17, colors.white, colors.gray, paletteEditWindow)
			writeAt(blank,           2, 18, colors.white, colors.gray, paletteEditWindow)

			-- Rows 20-22: DONE button
			writeAt(blank,           2, 20, colors.white, colors.gray, paletteEditWindow)
			writeAt("     DONE     ", 2, 21, colors.white, colors.gray, paletteEditWindow)
			writeAt(blank,           2, 22, colors.white, colors.gray, paletteEditWindow)
		end

		loadRGB()
		drawEditor()

		local function inWinX(ax)
			local lx = ax - listWinX + 1
			return lx >= 2 and lx <= listWinW - 1
		end

		-- Divide inner 14 cols into thirds: cols 1-4=R, 5-10=G, 11-14=B
		local function channelCol(ax)
			local lx = ax - listWinX  -- 1 = first inner col
			if lx <= 5 then return "R"
			elseif lx <= 10 then return "G"
			else return "B"
			end
		end

		while true do
			local event, btn, ax, ay = os.pullEvent()

			if event == "mouse_click" and btn == 1 then
				local ly = ay - listWinY + 1

				if not inWinX(ax) then break end

				if ly >= 7 and ly <= 9 then
					-- UP button
					local ch = channelCol(ax)
					if     ch == "R" then r = math.min(r + 1, 255)
					elseif ch == "G" then g = math.min(g + 1, 255)
					else                   b = math.min(b + 1, 255)
					end
					applyRGB() ; drawEditor()

				elseif ly >= 12 and ly <= 14 then
					-- DOWN button
					local ch = channelCol(ax)
					if     ch == "R" then r = math.max(r - 1, 0)
					elseif ch == "G" then g = math.max(g - 1, 0)
					else                   b = math.max(b - 1, 0)
					end
					applyRGB() ; drawEditor()

				elseif ly >= 16 and ly <= 18 then
					-- HEX input: clear mid row to black for typing
					writeAt(blank, 2, 17, colors.white, colors.black, paletteEditWindow)
					term.setCursorPos(listWinX + 1, listWinY + 16)
					term.setBackgroundColor(colors.black)
					term.setTextColor(colors.white)
					local hex = read()
					if hex and #hex >= 6 then
						hex = hex:gsub("^#", "")
						local rv = tonumber(hex:sub(1,2), 16)
						local gv = tonumber(hex:sub(3,4), 16)
						local bv = tonumber(hex:sub(5,6), 16)
						if rv and gv and bv then
							r, g, b = rv, gv, bv
							applyRGB()
						end
					end
					drawEditor()

				elseif ly >= 20 and ly <= 22 then
					-- DONE
					break

				elseif ly >= 23 then
					break
				end
			end
		end
	end

	drawPaletteList()

	while true do
		local event, key, x, y = os.pullEvent()

		if event == "mouse_click" then
			if x >= listWinX and x < listWinX + listWinW and y >= 4 and y < listWinH then
				if key == 1 then
					local colorKey = math.floor((y - 4) / 2)
					if colorKey >= 0 and colorKey <= 15 then
						openColourEditor(colorKey)
						drawPaletteList()
					end
				end
			else
				break
			end
		end
	end

	timer = os.startTimer(0.05)
end

local function paletteModified()
	for i = 1, 16 do
		if palette[i] ~= originalPalette[i] then return true end
	end
	return false
end

local function savePalette(asNew)
	if asNew then
		-- Prompt for new palette name
		term.setCursorPos(1, height)
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		term.write("New palette name: ")
		local newName = read()
		if not newName or newName == "" then return end
		local dir = shell.resolve("palettes/" .. newName)
		fs.makeDir(dir)
		fs.makeDir(dir .. "/sprites")
		local file = fs.open(dir .. "/" .. newName .. ".plt", "w")
		local data = {}
		for i = 1, 16 do data[i] = palette[i] end
		file.writeLine(textutils.serialize(data, {compact = true}))
		file.close()
		palette.name = newName
	else
		local file = fs.open(shell.resolve("palettes/" .. palette.name .. "/" .. palette.name .. ".plt"), "w")
		local data = {}
		for i = 1, 16 do data[i] = palette[i] end
		file.writeLine(textutils.serialize(data, {compact = true}))
		file.close()
	end
	-- Update snapshot
	for i = 1, 16 do originalPalette[i] = palette[i] end
end

local function saveSprite(name)
	local path = shell.resolve("palettes/"..palette.name.."/sprites/"..name)
	local file = fs.open(path,"w")
	local spriteData = {}
	for i = 1,#sprite do
		spriteData[i] = sprite[i]
	end
	file.writeLine(textutils.serialize(spriteData,{compact = true}))
	file.close()
end

local function saveExit()
	-- Layout: row1 top-border, row2 title, row3 sep,
	--         rows 4-6 btn1, row7 sep,
	--         rows 8-10 btn2, row11 sep,
	--         rows 12-14 btn3, row15 closer
	-- winW=15: 1 left border + 13 inner + 1 right border
	-- Anchored so right edge = width (winX + winW - 1 = width)
	local winW = 15
	local innerW = winW - 2  -- 13 chars
	local winH = 15
	local winX = width - winW + 1
	local winY = 1
	local saveExitWindow = window.create(term.current(), winX, winY, winW, winH)

	local function drawWindow()
		-- Full border frame
		for i = 1, winH - 1 do
			writeAt(":"..string.rep(" ", innerW)..":", 1, i, colors.white, colors.lightGray, saveExitWindow)
		end
		writeAt("\96"..string.rep("-", innerW).."'", 1, winH, colors.white, colors.lightGray, saveExitWindow)

		-- Title on row 2 (": SAVE/EXIT :" = 13 chars, fits innerW exactly)
		writeAt(":  SAVE/EXIT  :", 1, 2, colors.white, colors.lightGray, saveExitWindow)

		-- Buttons: 3 rows tall, label centred on middle row, blank rows fill full innerW
		local btnBlank = string.rep(" ", innerW)
		local buttons = {
			{topY = 4,  midY = 5,  botY = 6,  label = "    SAVE     "},
			{topY = 8,  midY = 9,  botY = 10, label = "   SAVE AS   "},
			{topY = 12, midY = 13, botY = 14, label = " SAVE & EXIT "},
		}
		for _, btn in ipairs(buttons) do
			writeAt(btnBlank,  2, btn.topY, colors.white, colors.gray, saveExitWindow)
			writeAt(btn.label, 2, btn.midY, colors.white, colors.gray, saveExitWindow)
			writeAt(btnBlank,  2, btn.botY, colors.white, colors.gray, saveExitWindow)
		end
	end

	-- If palette was modified, ask what to do with it first
	local function promptSavePalette()
		-- Small popup: 2 buttons, anchored just left of the save/exit panel
		-- ": PALETTE MODIFIED :" = 20 chars + 2 borders = 22 wide
		local pW = 22
		local pH = 12
		local pX = winX - pW
		local pY = 1
		local pWin = window.create(term.current(), pX, pY, pW, pH)
		local piW = pW - 2

		for i = 1, pH - 1 do
			writeAt(":" .. string.rep(" ", piW) .. ":", 1, i, colors.white, colors.lightGray, pWin)
		end
		writeAt("\96" .. string.rep("-", piW) .. "'", 1, pH, colors.white, colors.lightGray, pWin)
		writeAt(": PALETTE MODIFIED :", 1, 2, colors.white, colors.lightGray, pWin)

		-- btn1: SAVE MODIFIED  rows 4-6
		-- btn2: CREATE NEW      rows 8-10
		local blank = string.rep(" ", piW)
		writeAt(blank,              2, 4,  colors.white, colors.gray, pWin)
		writeAt("   SAVE MODIFIED    ", 2, 5,  colors.white, colors.gray, pWin)
		writeAt(blank,              2, 6,  colors.white, colors.gray, pWin)
		writeAt(blank,              2, 8,  colors.white, colors.gray, pWin)
		writeAt("    CREATE NEW      ", 2, 9,  colors.white, colors.gray, pWin)
		writeAt(blank,              2, 10, colors.white, colors.gray, pWin)

		while true do
			local ev, mb, mx, my = os.pullEvent()
			if ev == "mouse_click" and mb == 1 then
				local lx = mx - pX + 1
				local ly = my - pY + 1
				if lx >= 2 and lx <= pW - 1 then
					if ly >= 4 and ly <= 6 then
						savePalette(false)
						break
					elseif ly >= 8 and ly <= 10 then
						savePalette(true)
						break
					end
				end
				-- Click outside = skip saving palette
				break
			end
		end

		-- Erase popup
		pWin.setBackgroundColor(colors.black)
		pWin.clear()
	end

	drawWindow()

	-- Hit detection: absolute screen coords ? button index
	local function getButtonIndex(ax, ay)
		local lx = ax - winX      -- 0-indexed local x
		local ly = ay - winY + 1  -- 1-indexed local y
		if lx >= 1 and lx <= innerW then
			if ly >= 4  and ly <= 6  then return 1 end
			if ly >= 8  and ly <= 10 then return 2 end
			if ly >= 12 and ly <= 14 then return 3 end
		end
		return nil
	end

	while true do
		local event, btn, x, y = os.pullEvent()

		if event == "mouse_click" and btn == 1 then
			local idx = getButtonIndex(x, y)

			if idx == 1 then
				-- Save
				if paletteModified() then promptSavePalette() end
				saveSprite(sprite.name)
				break

			elseif idx == 2 then
				-- Save As
				if paletteModified() then promptSavePalette() end
				local inputRow = winH - 1
				writeAt(string.rep(" ", innerW), 2, inputRow, colors.white, colors.black, saveExitWindow)
				term.setCursorPos(winX + 1, winY + inputRow - 1)
				term.setBackgroundColor(colors.black)
				term.setTextColor(colors.white)
				local newName = read()
				if newName and newName ~= "" then
					sprite.name = newName
					saveSprite(newName)
				end
				break

			elseif idx == 3 then
				-- Save and exit
				if paletteModified() then promptSavePalette() end
				saveSprite(sprite.name)
				programEnded = true
				break

			else
				-- Clicked outside buttons ? dismiss
				break
			end
		end
	end

	timer = os.startTimer(0.05)
end

local function brightnessModifier()
	local function rgbToHsv(r, g, b)
		local max = math.max(r, g, b)
		local min = math.min(r, g, b)
		local delta = max - min

		local h = 0
		if delta ~= 0 then
			if max == r then
				h = ((g - b) / delta) % 6
			elseif max == g then
				h = ((b - r) / delta) + 2
			else
				h = ((r - g) / delta) + 4
			end
			h = h / 6
		end

		local s = (max == 0) and 0 or (delta / max)
		local v = max

		return h, s, v
	end

	local function hsvToRgb(h, s, v)
		local i = math.floor(h * 6)
		local f = (h * 6) - i
		local p = v * (1 - s)
		local q = v * (1 - f * s)
		local t = v * (1 - (1 - f) * s)

		i = i % 6

		if i == 0 then return v, t, p
		elseif i == 1 then return q, v, p
		elseif i == 2 then return p, v, t
		elseif i == 3 then return p, q, v
		elseif i == 4 then return t, p, v
		else return v, p, q
		end
	end


	for i = 0,15 do
		if brightness > 1 then
			local r,g,b = colors.unpackRGB(palette[i+1])
			
			local nr = math.min(r + brightness - 1, 1)
			local ng = math.min(g + brightness - 1, 1)
			local nb = math.min(b + brightness - 1, 1)
			
			
			term.setPaletteColor(2^i, colors.packRGB(nr,ng,nb))
		else
			local r,g,b = colors.unpackRGB(palette[i+1])

			local h,s,v = rgbToHsv(r,g,b)

			v = math.min(v * brightness, 1)

			local nr,ng,nb = hsvToRgb(h,s,v)

			term.setPaletteColor(2^i, colors.packRGB(nr,ng,nb))
		end
	end		
end

local function keyCheck()
	timer = os.startTimer(0.05)

	local changed = false

	if keysDown[keys.s] then
		camera.y = camera.y - 1
		changed = true
	end
	if keysDown[keys.d] then
		camera.x = camera.x - 1.5
		changed = true
	end
	if keysDown[keys.w] then
		camera.y = camera.y + 1
		changed = true
	end
	if keysDown[keys.a] then
		camera.x = camera.x + 1.5
		changed = true
	end

	if keysDown[keys.up] then
		brightness = brightness + 0.01
		brightnessModifier()
		changed = true
	end

	if keysDown[keys.down] then
		brightness = brightness - 0.01
		brightnessModifier()
		changed = true
	end

	if changed then
		drawScreen()
	end

	if keysDown[keys.backspace] then
		programEnded = true
	end

end

local function mouseCheck(key,x,y)
	local spriteX = math.floor(((x - 1 - camera.x) / 3) + 0.5)
	local spriteY = math.floor(((y - 5 - camera.y) / 2) + 0.5)
	
	local function replacePixel(color)
		for y = 1,2 do
			spriteWindow.setCursorPos	(		
								math.floor(spriteX * 3 + camera.x),
								math.floor(spriteY * 2 + camera.y) + y
								)
								
			spriteWindow.setBackgroundColor(color)
			spriteWindow.write("   ")
		end
	end
	
	local function checkSpriteTable()
		for i = 1,#sprite do
			if sprite[i][1] == spriteX and sprite[i][2] == spriteY then
				table.remove(sprite,i)
				break
			end
		end	
	end
	
	if y > 3 then
		if key == 1 then
			checkSpriteTable()
			table.insert(sprite,{spriteX,spriteY,colourSelected})
			replacePixel(colourSelected)
		elseif key == 2 then
			checkSpriteTable()
			replacePixel(backgroundColour)
		end	
	else
		if x > width-43 and x < width-27 then
			colourSelect()
			drawScreen()
		elseif x > width - 27 and x < width - 12 then
			paletteEdit()
			drawScreen()
		elseif x >= width - 12 then
			saveExit()
			drawScreen()
		end
	end
end

local function getUserInput()

	local event, key,x,y = os.pullEvent()
	
    if event == "key" then keysDown[key] = true
    elseif event == "key_up" then keysDown[key] = nil
	elseif event == "mouse_click" or event == "mouse_drag" then
	
		mouseCheck(key,x,y)
		
    elseif event == "timer" and key == timer then
		
		keyCheck()
		
	end
end

loadPalette()
loadSprite()
drawScreen()

timer = os.startTimer(0.05)

while true do
	getUserInput()
	if programEnded == true then
		break
	end
end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
print("Program Ended.")