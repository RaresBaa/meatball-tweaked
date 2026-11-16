local pixelbox = {initialized=false,shared_data={},internal={}}
 
pixelbox.url     = "https://pixels.devvie.cc"
pixelbox.license = [[MIT License
 
Copyright (c) 2024 9551Dev
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
 
local box_object = {}
 
local to_blit = {}
local t_cat   = table.concat
 
local function generate_lookups()
    for i = 0, 15 do
        to_blit[2^i] = ("%x"):format(i)
    end
end
 
pixelbox.internal.to_blit_lookup   = to_blit
pixelbox.internal.generate_lookups = generate_lookups
 
function pixelbox.make_canvas_scanline(y_coord)
    return setmetatable({},{__newindex=function(self,key,value)
        if type(key) == "number" and key%1 ~= 0 then
            error(("Tried to write a float pixel. x:%s y:%s"):format(key,y_coord),2)
        else rawset(self,key,value) end
    end})
end
 
function pixelbox.make_canvas(source_table)
    local dummy_OOB = pixelbox.make_canvas_scanline("NONE")
    local dummy_mt  = getmetatable(dummy_OOB)
 
    function dummy_mt.tostring() return "pixelbox_dummy_oob" end
 
    return setmetatable(source_table or {},{__index=function(_,key)
        if type(key) == "number" and key%1 ~= 0 then
            error(("Tried to write float scanline. y:%s"):format(key),2)
        end
 
        return dummy_OOB
    end})
end
 
function pixelbox.setup_canvas(box,canvas_blank,color,keep_existing)
    for y=1,box.height do
 
        local scanline
        if not rawget(canvas_blank,y) then
            scanline = pixelbox.make_canvas_scanline(y)
 
            rawset(canvas_blank,y,scanline)
        else
            scanline = canvas_blank[y]
        end
 
        for x=1,box.width do
            if not (scanline[x] and keep_existing) then
                scanline[x] = color
            end
        end
    end
 
    return canvas_blank
end
 
function pixelbox.restore(box,color,keep_existing)
    if not keep_existing then
        local new_canvas = pixelbox.setup_canvas(box,pixelbox.make_canvas(),color)
 
        box.canvas = new_canvas
        box.CANVAS = new_canvas
    else
        pixelbox.setup_canvas(box,box.canvas,color,true)
    end
end
 
local string_rep = string.rep
function box_object:render()
    local term = self.term
    local blit_line,set_cursor = term.blit,term.setCursorPos
 
    local canv = self.canvas
 
    local fg_line_1,bg_line_1 = {},{}
    local fg_line_2,bg_line_2 = {},{}
 
    local width,height = self.width,self.height
 
    local even_char_line = string_rep("\131",width)
    local odd_char_line  = string_rep("\143",width)
 
    local sy = 0
    for y=1,height,3 do
        sy = sy + 2
        local layer_1 = canv[y]
        local layer_2 = canv[y+1]
        local layer_3 = canv[y+2]
 
        local n = 1
        for x=1,width do
            local color1 = layer_1[x]
            local color2 = layer_2[x]
            local color3 = layer_3[x]
 
            fg_line_1  [n] = to_blit[color1]
            bg_line_1  [n] = to_blit[color2]
            fg_line_2  [n] = to_blit[color2 or color2]
            bg_line_2  [n] = to_blit[color3 or color2]
 
            n = n + 1
        end
 
        set_cursor(1,sy-1)
        blit_line(odd_char_line,
            t_cat(fg_line_1,""),
            t_cat(bg_line_1,"")
        )
 
        set_cursor(1,sy)
        blit_line(even_char_line,
            t_cat(fg_line_2,""),
            t_cat(bg_line_2,"")
        )
    end
end
 
function box_object:clear(color)
    pixelbox.restore(self,to_blit[color or ""] and color or self.background,false)
end
 
function box_object:set_pixel(x,y,color)
    self.canvas[y][x] = color
end
 
function box_object:set_canvas(canvas)
    self.canvas = canvas
    self.CANVAS = canvas
end
 
function box_object:resize(w,h,color)
    self.term_width  = w
    self.term_height = h
    self.width  = w*2
    self.height = h*3
 
    pixelbox.restore(self,color or self.background,true)
end
 
function pixelbox.module_error(module,str,level,supress_error)
    level = level or 1
 
    if module.__contact and not supress_error then
        local _,err_msg = pcall(error,str,level+2)
        printError(err_msg)
        error((module.__report_msg or "\nReport module issue at:\n-> __contact"):gsub("[%w_]+",module),0)
    elseif not supress_error then
        error(str,level+1)
    end
end
 
function box_object:load_module(modules)
    for k,module in ipairs(modules or {}) do
        local module_data = {
            __author     = module.author,
            __name       = module.name,
            __contact    = module.contact,
            __report_msg = module.report_msg
        }
 
        local module_fields,magic_methods = module.init(self,module_data,pixelbox,pixelbox.shared_data,pixelbox.initialized,modules)
 
        magic_methods    = magic_methods or {}
        module_data.__fn = module_fields
 
 
        if self.modules[module.id] and not modules.force then
            pixelbox.module_error(module_data,("Module ID conflict: %q"):format(module.id),2,modules.supress)
        else
            self.modules[module.id] = module_data
            if magic_methods.verified_load then
                magic_methods.verified_load()
            end
        end
 
        for fn_name in pairs(module_fields) do
            if self.modules.module_functions[fn_name] and not modules.force then
                pixelbox.module_error(module_data,("Module %q tried to register already existing element: %q"):format(module.id,fn_name),2,modules.supress)
            else
                self.modules.module_functions[fn_name] = {
                    id   = module.id,
                    name = fn_name
                }
            end
        end
    end
end
 
function pixelbox.new(terminal,bg,modules)
    local box = {
        modules = {module_functions={}}
    }
 
    box.background = bg or terminal.getBackgroundColor()
 
    local w,h = terminal.getSize()
    box.term  = terminal
 
    setmetatable(box,{__index = function(self,key)
        local module_fn = rawget(box.modules.module_functions,key)
        if module_fn then
            return box.modules[module_fn.id].__fn[module_fn.name]
        end
 
        return rawget(box_object,key)
    end})
 
    box.__bixelbox_lite = true
 
    box.term_width  = w
    box.term_height = h
    box.width       = w
    box.height      = math.ceil(h * (3/2))
 
    pixelbox.restore(box,box.background)
 
    if type(modules) == "table" then
        box:load_module(modules)
    end
 
    if not pixelbox.initialized then
        generate_lookups()
 
        pixelbox.initialized = true
    end
 
    return box
end
 
 
 
local termWidth,termHeight = term.getSize()
local lockStart = nil
local lockDelay = 0.25 -- seconds
local keysDown = {}
local gameWindow = window.create(
                                    term.current(), 
                                    2, 
                                    3, 
                                    12, 
                                    18
                                )
local infoWindow = window.create(
                                                        term.current(), 
                                                        1, 
                                                        21, 
                                                        termWidth, 
                                                        50
                                                    )
local nextPieceWindow = window.create(
                                    term.current(), 
                                    16, 
                                    8, 
                                    4, 
                                    6
                                )
								
local heldPieceWindow = window.create(
                                    term.current(), 
                                    16, 
                                    15, 
                                    4, 
                                    3
                                )
local pieces =  {
                    straight = {
                                color = colors.cyan,
                                {{0,1},{1,1},{2,1},{3,1}},
                                {{2,0},{2,1},{2,2},{2,3}},
                                {{0,2},{1,2},{2,2},{3,2}},
                                {{1,0},{1,1},{1,2},{1,3}},
                                {{0,1},{1,1},{2,1},{3,1}}},
                                
                                
                    jShape = {
                                color = colors.blue,
                                {{0,0},{0,1},{1,1},{2,1}},
                                {{1,0},{2,0},{1,1},{1,2}},
                                {{0,1},{1,1},{2,1},{2,2}},
                                {{1,0},{1,1},{0,2},{1,2}},
                                {{0,0},{0,1},{1,1},{2,1}}},
                                
                    lShape = {
                                color = colors.orange,
                                {{2,0},{0,1},{1,1},{2,1}},
                                {{1,0},{1,1},{1,2},{2,2}},
                                {{0,1},{1,1},{2,1},{0,2}},
                                {{0,0},{1,0},{1,1},{1,2}},
                                {{2,0},{0,1},{1,1},{2,1}}},
                                
                    square = {
                                color = colors.yellow,
                                {{1,0},{2,0},{1,1},{2,1}},
                                {{1,0},{2,0},{1,1},{2,1}},
                                {{1,0},{2,0},{1,1},{2,1}},
                                {{1,0},{2,0},{1,1},{2,1}},
                                {{1,0},{2,0},{1,1},{2,1}}},
                                
                    sShape = {
                                color = colors.lime,
                                {{1,0},{2,0},{0,1},{1,1}},
                                {{1,0},{1,1},{2,1},{2,2}},
                                {{1,1},{2,1},{0,2},{1,2}},
                                {{0,0},{0,1},{1,1},{1,2}},
                                {{1,0},{2,0},{0,1},{1,1}}},
                                
                    tShape = {
                                color = colors.purple,
                                {{1,0},{0,1},{1,1},{2,1}},
                                {{1,0},{1,1},{2,1},{1,2}},
                                {{0,1},{1,1},{2,1},{1,2}},
                                {{1,0},{0,1},{1,1},{1,2}},
                                {{1,0},{0,1},{1,1},{2,1}}},
                    
                    zShape = {
                                color = colors.red,
                                {{0,0},{1,0},{1,1},{2,1}},
                                {{2,0},{1,1},{2,1},{1,2}},
                                {{0,1},{1,1},{1,2},{2,2}},
                                {{1,0},{0,1},{1,1},{0,2}},
                                {{0,0},{1,0},{1,1},{2,1}}},
                                
                }       
local wallKickLTable =  {
                            {{0,0},{-2,0},{1,0},{-2,1},{1,-2}},
                            {{0,0},{-1,0},{2,0},{-1,-2},{2,1}},
                            {{0,0},{2,0},{-1,0},{2,-1},{-1,2}},
                            {{0,0},{1,0},{-2,0},{1,2},{-2,-1}},
                            {{0,0},{-2,0},{1,0},{-2,1},{1,-2}}
                        }
local wallKickOther =   {
                            {{0,0},{-1,0},{-1,-1},{0,2},{-1,2}},
                            {{0,0},{1,0},{1,1},{0,-2},{1,-2}},
                            {{0,0},{1,0},{1,-1},{0,2},{1,2}},
                            {{0,0},{-1,0},{-1,1},{0,-2},{-1,-2}},
                            {{0,0},{-1,0},{-1,-1},{0,2},{-1,2}}
 
                        }
local player =  {
                x = 5, 
                y = 2, 
                rotation = 1, 
                score = 0, 
                currentPiece = "straight",
                frameCounter = 0,
                speed = 16,
                linesCleared = 0,
                gameEnded = false,
                level = 0,
				allowSwap = true
                }
local bag = {}
local bagInitialized = bagInitialized or false
 
local box = pixelbox.new(gameWindow)
local nextPieceBox = pixelbox.new(nextPieceWindow)
local heldPieceBox = pixelbox.new(heldPieceWindow)

local function printToInfo(msg)  
    infoWindow.setBackgroundColor(colors.black)
    infoWindow.setTextColor(colors.white)
    local terminal = term.current()
    term.redirect(infoWindow)
    print(msg)
    term.redirect(terminal)
end
 
function newCurrentPiece()
  -- All seven tetromino names
  local pieceTypes = {
    "straight", "square", "tShape",
    "jShape",    "lShape",   "sShape", "zShape"
  }
 
  -- Fisher?Yates shuffle
  local function shuffle(t)
    for i = #t, 2, -1 do
      local j = math.random(i)
      t[i], t[j] = t[j], t[i]
    end
  end
 
  -- Append one shuffled septet to bag
  local function refillBag()
    -- build a fresh septet
    local septet = {}
    for _, p in ipairs(pieceTypes) do
      septet[#septet + 1] = p
    end
    shuffle(septet)
    -- append it
    for _, p in ipairs(septet) do
      bag[#bag + 1] = p
    end
  end
 
  -- On first ever call, seed two septets (14 pieces total)
  if not bagInitialized then
    refillBag()
    refillBag()
    bagInitialized = true
  end
 
  -- Maintain at least a full septet in reserve
  if #bag <= 7 then
    refillBag()
  end
 
  -- Pull the next piece from the front, shifting all others down
  local nextPiece = bag[1]
  table.remove(bag, 1)
 
  return nextPiece
end
 
local function drawTetromino(x,y,name,rotation,arguments)
    if arguments == "clear" then
        for i = 1,4 do
            box:set_pixel(pieces[name][rotation][i][1] + x,pieces[name][rotation][i][2] + y,colors.black)
        end 
    elseif arguments == "ghost" then
        for i = 1,4 do
            box:set_pixel(pieces[name][rotation][i][1] + x,pieces[name][rotation][i][2] + y,colors.gray)
        end 
    elseif arguments == "collision" then
        local collides = false
        for i = 1,4 do
            if box.canvas[y + pieces[name][rotation][i][2]][x + pieces[name][rotation][i][1]] ~= colors.black then
                collides = true
            end
        end 
        
        return collides
        
    else
        for i = 1,4 do
            box:set_pixel(pieces[name][rotation][i][1] + x,pieces[name][rotation][i][2] + y,pieces[name].color)
        end         
    end
end
 
local function drawNextPieces(x,y,name)
 
    for i = 1,4 do
        nextPieceBox:set_pixel(pieces[name][1][i][1] + x,pieces[name][1][i][2] + y,pieces[name].color)
    end         
    
end

local function drawHeldPiece(x,y,name)
	if name then
		for i = 1,4 do
			heldPieceBox:set_pixel(pieces[name][1][i][1] + x,pieces[name][1][i][2] + y,pieces[name].color)
		end         
    end
end
 
local function rotatePiece(x,y,name,currentRotation)
    drawTetromino(player.x,player.y,player.currentPiece,player.rotation,"clear")
    
    if name == "straight" then
        for i = 1,5 do
            if drawTetromino(x + wallKickLTable[currentRotation][i][1],y + wallKickLTable[currentRotation][i][2],name,currentRotation + 1, "collision") == false then
                if player.rotation == 4 then
                    player.rotation = 1
                else
                    player.rotation = player.rotation + 1
                end
                
                if lockStart then lockStart = os.clock() end
                player.x = player.x + wallKickLTable[currentRotation][i][1]
                player.y = player.y + wallKickLTable[currentRotation][i][2]
                break
            end
        end
    else
        for i = 1,5 do
            if drawTetromino(x + wallKickOther[currentRotation][i][1],y + wallKickOther[currentRotation][i][2],name,currentRotation + 1, "collision") == false then
                if player.rotation == 4 then
                    player.rotation = 1
                else
                    player.rotation = player.rotation + 1
                end
                
                if lockStart then lockStart = os.clock() end
                player.x = player.x + wallKickOther[currentRotation][i][1]
                player.y = player.y + wallKickOther[currentRotation][i][2]
                break
            end
        end     
    end
end
 
local function moveLeft()
    if drawTetromino(player.x - 1,player.y,player.currentPiece,player.rotation, "collision") == false then
        player.x = player.x - 1
        if lockStart then lockStart = os.clock() end
    end
end
 
local function moveRight()
    if drawTetromino(player.x + 1,player.y,player.currentPiece,player.rotation, "collision") == false then
        player.x = player.x + 1
        if lockStart then lockStart = os.clock() end
    end 
end
 
local function clearCheck()
 
    -- Iterate bottom-up so collapsing doesn?t skip rows
    local y = 25
    local clearedLines = 0
    while y >= 2 do
        -- Check if row y is full
        local isFull = true
        for x = 2, 11 do
            if box.canvas[y][x] == colors.black then
                isFull = false
                break
            end
        end
 
        if isFull then
            player.linesCleared = player.linesCleared + 1
            clearedLines = clearedLines + 1
            -- Pull every row above y down by one
            for pullY = y, 2, -1 do
                for x = 2, 11 do
                    box.canvas[pullY][x] = box.canvas[pullY - 1][x]
                end
            end
 
            -- Clear the new top row
            for x = 2, 11 do
                box.canvas[1][x] = colors.black
            end
 
            -- Stay on this y to re-check the row that just shifted into place
        else
            y = y - 1
        end
    end
    
    if clearedLines == 1 then
        player.score = player.score + ((player.level + 1) * 40)
    elseif clearedLines == 2 then
        player.score = player.score + ((player.level + 1) * 100)
    elseif clearedLines == 3 then
        player.score = player.score + ((player.level + 1) * 300)
    elseif clearedLines == 4 then
        player.score = player.score + ((player.level + 1) * 1200)
    end
    
    if clearedLines > 0 then
        if math.floor(player.linesCleared / 10) > player.level then
            player.level = player.level + 1
            
            if player.level == 1 then
                player.speed = 15
            elseif player.level == 2 then
                player.speed = 13
            elseif player.level == 3 then
                player.speed = 11
            elseif player.level == 4 then
                player.speed = 9
            elseif player.level == 5 then
                player.speed = 8
            elseif player.level == 6 then
                player.speed = 6
            elseif player.level == 7 then
                player.speed = 4
            elseif player.level == 8 then
                player.speed = 3
            elseif player.level == 9 then
                player.speed = 3
            elseif player.level == 10 then
                player.speed = 2
            elseif player.level == 11 then
                player.speed = 2
            elseif player.level == 12 then
                player.speed = 1
            end
            
        end
    end
    
end
 
local function moveDown()
    if not drawTetromino(player.x, player.y + 1, player.currentPiece, player.rotation, "collision") then
		if player.frameCounter > player.speed or keysDown[keys.s] or keysDown[keys.down] then
            player.y = player.y + 1
            player.frameCounter = 0
        end
        
        lockStart = nil -- cancel lock delay if rising
        if keysDown[keys.s] or keysDown[keys.down] then
            player.score = player.score + 1
        end
    else
        if lockStart == nil then
            lockStart = os.clock()
        elseif os.clock() - lockStart >= lockDelay then
            -- Lock piece
            drawTetromino(player.x, player.y, player.currentPiece, player.rotation)
            player.x = 5
            player.y = 2
            player.rotation = 1
            player.currentPiece = newCurrentPiece()
            player.gameEnded = drawTetromino(player.x, player.y, player.currentPiece, player.rotation,"collision")
            lockStart = nil
            clearCheck()
			player.allowSwap = true
        end
    end
end
 
for x = 1,box.width do
    for y = 1,box.height do
        if (x+y) % 2 == 0 and (x < 2 or x > 11 or y > 25) and y ~= 27 then
            box:set_pixel(x,y,colors.lightGray)
        elseif (x < 2 or x > 11 or y > 25) and y ~= 27 then
            box:set_pixel(x,y,colors.gray)
        end
    end
end
 
local function getUserInput()
 
    local event, key = os.pullEvent()
    
    if event == "key" then keysDown[key] = true
    elseif event == "key_up" then keysDown[key] = false rollLock = true
    elseif event == "timer" and key == timer then
        timer = os.startTimer(0.05)
        player.frameCounter = player.frameCounter + 1
        drawTetromino(player.x,player.y,player.currentPiece,player.rotation,"clear")
 
        moveDown()

        if (keysDown[keys.w] or keysDown[keys.up]) and rollLock then
            rotatePiece(player.x,player.y,player.currentPiece,player.rotation)
            rollLock = false
        end
        if (keysDown[keys.d] or keysDown[keys.right]) then
            moveRight()
        end
        if (keysDown[keys.a] or keysDown[keys.left]) then
            moveLeft()
        end
		if keysDown[keys.space] and rollLock then
			rollLock = false
			local yUntilDrop = 0
			repeat
				yUntilDrop = yUntilDrop + 1
			until drawTetromino(player.x,player.y + yUntilDrop,player.currentPiece,player.rotation,"collision")
			player.y = player.y + yUntilDrop - 1
			player.score = player.score + (yUntilDrop-1)*2
		end
		if (keysDown[keys.e] or keysDown[keys.enter]) and player.allowSwap then
			player.allowSwap = false

			player.x, player.y, player.rotation = 5, 2, 1

			local temp = player.currentPiece
			if player.heldPiece then
				player.currentPiece = player.heldPiece
			else
				player.currentPiece = newCurrentPiece()
			end
			player.heldPiece = temp
		end
        
		local yUntilDrop = 0
		repeat
			yUntilDrop = yUntilDrop + 1
		until drawTetromino(player.x,player.y + yUntilDrop,player.currentPiece,player.rotation,"collision")
		
		drawTetromino(player.x,player.y + yUntilDrop - 1,player.currentPiece,player.rotation,"ghost")
        drawTetromino(player.x,player.y,player.currentPiece,player.rotation)
		
        box:render()
		drawTetromino(player.x,player.y + yUntilDrop - 1,player.currentPiece,player.rotation,"clear")
    end
end
 
highScore = 7384
 
local function start()
    term.setBackgroundColor(colors.black)
    term.clear()
	
    term.setCursorPos(5,1)
    term.write("LINES:     TOP SCORE:")
    term.setCursorPos(16,2)
    term.write(highScore)
    term.setCursorPos(18,4)
    term.write("SCORE")
    term.setCursorPos(16,7)
    term.write("NEXT:")
	term.setCursorPos(16,14)
	term.write("HELD:")
    term.setCursorPos(16,18)
    term.write("LEVEL:")
    
    timer = os.startTimer(0.05)
    player.currentPiece = newCurrentPiece()
    
    while true do
        
        if player.gameEnded == true then
            break
        end
        
        getUserInput()
        infoWindow.clear()
        infoWindow.setCursorPos(1,1)
        term.setCursorPos(7,2)
        term.write(player.linesCleared)
        term.setCursorPos(16,5)
        term.write(player.score)
        
        nextPieceBox:clear()
        drawNextPieces(1,1,bag[1])
        drawNextPieces(1,4,bag[2])
        drawNextPieces(1,7,bag[3])
        nextPieceBox:render()
		
		heldPieceBox:clear()
		drawHeldPiece(1,1,player.heldPiece)
		heldPieceBox:render()
        
        term.setCursorPos(16,19)
        term.write(player.level)
        
    end 
end 
 
start()
 
term.clear()
term.setCursorPos(1,1)
 
if player.score > highScore then
    local path = shell.resolve("tetris.lua")
    local file = fs.open(path, "r")
    local lines = {}
 
    while true do
        local line = file.readLine()
        if line == nil then break end
        table.insert(lines, line)
    end
    file.close()
 
    for i, line in ipairs(lines) do
        if line:match("^highScore%s*=%s*%d+") then
            lines[i] = "highScore = " .. tostring(player.score)
            break
        end
    end
 
    file = fs.open(path, "w")
    for _, line in ipairs(lines) do
        file.writeLine(line)
    end
    file.close()
    
    print("NEW HIGH SCORE:")
    print(highScore)
    
else
    print("YOUR SCORE:")
    print(player.score)
end