--[[
	Mega Man 3 Info
	Version 1.0 by zackthehuman
	
	Get the latest version at: https://github.com/zackthehuman/mm3info
	
	See the README for more info.
--]]

local gameObjects = {}
local megaman = nil
local screenOffsetX = 0
local roomIndex = 0

local showObjectInfo = true
local showObjectPositions = true

function initializeObjectInfo()
	for i=0,31 do
		gameObjects[i] = {
			a = 0,
			dir = 0,
			screen = 0,
			id = 0,
			id2 = 0,
			x = 0,
			xlo = 0,
			y = 0,
			ylo = 0,
			sx = 0,
			sy = 0,
			hp = 0,
		}
	end
	
	megaman = gameObjects[0]
end

function updateObjectInfo()
	screenOffsetX = memory.readbyte(0xFC)
	roomIndex = memory.readbyte(0xF9)
	
	for i=0,31 do
		gameObjects[i].id = memory.readbyte(0x0300 + i)
		gameObjects[i].id2 = memory.readbyte(0x0320 + i)
		gameObjects[i].xlo = memory.readbyte(0x0340 + i)
		gameObjects[i].x = memory.readbyte(0x0360 + i)
		gameObjects[i].room = memory.readbyte(0x0380 + i)
		gameObjects[i].ylo = memory.readbyte(0x03A0 + i)
		gameObjects[i].y = memory.readbyte(0x03C0 + i)
		gameObjects[i].unkn1 = memory.readbyte(0x03E0 + i)
		gameObjects[i].xspdlo = memory.readbyte(0x0400 + i)
		gameObjects[i].xspd = memory.readbyte(0x0420 + i)
		gameObjects[i].yspdlo = memory.readbyte(0x0440 + i)
		gameObjects[i].yspd = memory.readbyte(0x0460 + i)
		gameObjects[i].shield = memory.readbyte(0x0480 + i)
		gameObjects[i].dir = memory.readbyte(0x04A0 + i)
		gameObjects[i].unkn2 = memory.readbyte(0x04C0 + i)
		gameObjects[i].hp = memory.readbyte(0x04E0 + i)
		gameObjects[i].count1 = memory.readbyte(0x0500 + i)
		gameObjects[i].count2 = memory.readbyte(0x0520 + i)
		gameObjects[i].unkn3 = memory.readbyte(0x0540 + i)
		gameObjects[i].unkn4 = memory.readbyte(0x0560 + i)
		gameObjects[i].dir2 = memory.readbyte(0x0580 + i)
		gameObjects[i].sprite = memory.readbyte(0x05A0 + i)
		
		gameObjects[i].sx = AND(gameObjects[i].x + 255 - screenOffsetX, 255) 	-- screen x position
		gameObjects[i].sy = gameObjects[i].y								-- screen y position
	end
end

function drawObjectInfo(index)
	if(gameObjects[index] ~= nil) then
		local obj = gameObjects[index]
		
		if(isEnemy(obj.id)) then
			gui.text(obj.sx, obj.sy, "#" .. index .. " (" .. obj.x .. ", " .. obj.y .. ")\ndir: " .. obj.dir .. "\nid2: " .. obj.id2 .. "hp: " .. obj.hp, nil, "clear")
		end
	end
end

function drawObjectPosition(index)
	if(gameObjects[index] ~= nil) then
		local obj = gameObjects[index]
		
		if(isEnemy(obj.id)) then
			gui.rect(obj.sx - 1, obj.sy - 1, obj.sx + 1, obj.sy + 1, "black", "black")
			gui.pixel(obj.sx, obj.sy, "green")
		end
	end
end

--[[
	Under construction.
--]]
function isEnemy(index)
	if(index == 0) then
		return false
	end
	
	return true
end

initializeObjectInfo()

while true do
	updateObjectInfo()
	inp = input.get()
	joy = joypad.getdown(1)
	
	if(inp.middleclick) then
		local x = inp.xmouse + screenOffsetX
		memory.writebyte(0x0360, x)									-- set x
		memory.writebyte(0x03C0, inp.ymouse)						-- set y
		memory.writebyte(0x0380, roomIndex + math.floor(x / 256))	-- set room #
	end

	for i=0,31 do
		if(showObjectInfo) then
			drawObjectInfo(i)
		end
		if(showObjectPositions) then
			drawObjectPosition(i)
		end
	end
	
	emu.frameadvance()
end