--[[
	Mega Man 3 Info
	Version 1.0 by zackthehuman
	
	Get the latest version at: https://github.com/zackthehuman/mm3info
	
	See the README for more info.
--]]

local objects = {}
local megaman = nil
local scroll_x = 0
local screen_num = 0

local show_info = true --show sprite info on startup
local show_cursor = true --set this to true when recording a video
local show_position = true --
local show_hitbox = true -- for later

local capturing_jump_info = false
local last_jump_indicator = 0

local enemies = {}

--[[
	Mega Man 3 RAM Map:
	
	$0012: Column of curson on stage select [0, 1, 2]. Y position of the sprite currently being drawn during gameplay
	$0013: Row of cursor on stage select [0, 3, 6]. X position of the sprite currently being drawn during gameplay
	$0200-$02FF: Sprite data for DMA
	$0300-$06FF: Game object data
		$0300-$031F: State index?
		$0320-$033F: Type
		$0340-$035F: Fractional X position
		$0360-$037F: Whole X position
		$0380-$039F: Screen number (which screen the object is in)
		$03A0-$03BF: Fractional Y position
		$03C0-$03DF: Whole Y position
		$03E0-$03FF: Mystery #1 (if set to a non-zero value then object does not spawn or will disappear if already spawned)
		$0400-$041F: Fractional X speed
		$0420-$043F: Whole X speed
		$0440-$045F: Fractional Y speed
		$0460-$047F: Whole Y speed
		$0480-$049F: Shield status. Shots bounce off when value = A1, but takes damage when value = C1
		$04A0-$04BF: Direction
		$04C0-$04DF: Mystery #2 / object number? on-screen number?
		$04E0-$04FF: Hit points
		$0500-$051F: Timer/counter 1
		$0520-$053F: Timer/counter 2
		$0540-$055F: Mystery #2 / seems like its not used
		$0560-$057F: Value #1 (Spark man's raising platforms use this as their "return to" Y value)
		$0580-$059F: Sprite direction? D0 = left, 90 = right
		$05A0-$05BF: Sprite index (within animation)? (can affect behavior if animation doesn't change)
		$05C0-$05DF: Animation sequence number (can affect behavior if animation doesn't change)
		$05E0-$05FF: Animation counter or something (can affect behavior if animation doesn't change)
	$0600-$XXXX: Tile data starts here
]]--

-- 0x00a2 = megaman's health
-- 0x00b0
-- 0x04a0 = object direction?
-- 0x04b0
-- 0x04e0 = object health

-- 0x0480 = object collision type / collision box or something
-- A1 = enemy takes damage
-- B1 = D1 = shots pass through object
-- C1 = E1 = shots bounce off object (like metool)
-- C7 = monkey hanging & swaying

-- 0x093 = object logic delay; if set to value other than 1, causes a counter 
-- 		(at 0081) to count down from the value at 0081 to 0 before advancing the 
-- 		logic one frame

--[[
	object #31's health is stored at
	04ff
	0cff
	14ff
	1cff
	
	it appears that value of 04ff is copied to the other places in memory
	
	id2 = 82 = protoman
]]--

function initializeObjectInfo()
	for i=0,31 do
		objects[i] = {
			a=0,
			dir=0,
			screen = 0,
			id=0,
			id2=0,
			x=0,
			xlo = 0,
			y=0,
			ylo = 0,
			sx = 0,
			sy = 0,
			hp=0,
		}
	end
	
	megaman = objects[0]
end

function updateObjectInfo()
	scroll_x = memory.readbyte(0xFC)
	screen_num = memory.readbyte(0xF9)
	
	for i=0,31 do
		objects[i].id = 	memory.readbyte(0x0300 + i)				-- state, object state, changes behavior depending on object type (id2)
		objects[i].id2 = 	memory.readbyte(0x0320 + i)				-- object/actor type	
		objects[i].xlo = 	memory.readbyte(0x0340 + i)				-- fractional x coordinate
		objects[i].x = 		memory.readbyte(0x0360 + i)				-- whole x coordinate
		objects[i].screen = memory.readbyte(0x0380 + i) 			-- screen number
		objects[i].ylo = 	memory.readbyte(0x03A0 + i)				-- fractional y coordinate
		objects[i].y = 		memory.readbyte(0x03C0 + i)				-- whole y coordinate
		objects[i].unkn1 = 	memory.readbyte(0x03E0 + i)				-- mystery #1
		objects[i].xspdlo = memory.readbyte(0x0400 + i)				-- fractional x speed
		objects[i].xspd = 	memory.readbyte(0x0420 + i)				-- x speed
		objects[i].yspdlo = memory.readbyte(0x0440 + i)				-- fractional y speed
		objects[i].yspd = 	memory.readbyte(0x0460 + i)				-- y speed
		objects[i].shield = memory.readbyte(0x0480 + i)				-- shots bounce off when value = A1, but takes damage when C1
		objects[i].dir = 	memory.readbyte(0x04A0 + i)				-- direction?
		objects[i].unkn2 = 	memory.readbyte(0x04C0 + i)				-- mystery #2 / object number? on-screen number?
		objects[i].hp = 	memory.readbyte(0x04E0 + i)				-- hit points
		objects[i].count1 = memory.readbyte(0x0500 + i)				-- timer/counter 1
		objects[i].count2 = memory.readbyte(0x0520 + i)				-- timer/counter 2
		objects[i].unkn3 =  memory.readbyte(0x0540 + i)				-- mystery #3 / seems like its not used
		objects[i].unkn4 =  memory.readbyte(0x0560 + i)				-- mystery #4 / seems like its not used
		objects[i].dir2 =  	memory.readbyte(0x0580 + i)				-- direction? sprite direction? D0 = left, 90 = right
		objects[i].sprite = memory.readbyte(0x05A0 + i)				-- something to do with sprite number or bank
		
		-- 0x05c0 sprite something else
		-- 0x05e0 sprite somehitng else again
		-- 0x0600 not sure
		-- 0x0620 
		-- 0x0640 
		-- 0x0660 
		-- 0x0680 
		-- 0x06a0 
		-- 0x06c0 tile memory starts here, it seems
		
		objects[i].sx = AND(objects[i].x + 255 - scroll_x, 255) 	-- screen x position
		objects[i].sy = objects[i].y								-- screen y position

		objects[i].a = (memory.readbyte(0x04E0 + i) >= 0x80)
	end
end

function drawObjectInfo(index)
	if(objects[index] ~= nil) then
		local obj = objects[index]
		
		if(isEnemy(obj.id)) then
			gui.text(obj.sx, obj.sy, "#" .. index .. " (" .. obj.x .. ", " .. obj.y .. ")\ndir: " .. obj.dir .. "\nid2: " .. obj.id2 .. "hp: " .. obj.hp .. "\nxv: " .. obj.xspd .. "\nxvl: " .. obj.xspdlo, nil, "clear")
		end
	end
end

function drawObjectInfoAt(index, screenX, screenY)
	if(objects[index] ~= nil) then
		local obj = objects[index]
		
		if(isEnemy(obj.id)) then
			gui.text(screenX, screenY, "#" .. index .. " (" .. obj.x .. ", " .. obj.y .. ")\ndir: " .. obj.dir .. "\nid2: " .. obj.id2 .. "hp: " .. obj.hp, nil, "clear")
		end
	end
end

function drawObjectPosition(index)
	if(objects[index] ~= nil) then
		local obj = objects[index]
		
		if(isEnemy(obj.id)) then
			gui.rect(obj.sx - 1, obj.sy - 1, obj.sx + 1, obj.sy + 1, "black", "black")
			gui.pixel(obj.sx, obj.sy, "green")
		end
	end
end

function isEnemy(index)
	if(index == 0) then
		return false
	end
	--if(objects[index].a) then
	--	local id = objects[index].id
	--	if(enemies[id]) then
	--		if(enemies[id].invincible) then
	--			return false
	--		end
	--	end
	--end
	return true
end

initializeObjectInfo()

--memory.register(0x03C0, function()
--	emu.print(memory.readbyte(0x03C0) .. "\t" .. memory.readbyte(0x03A0))
--end)

while true do
	updateObjectInfo()
	inp = input.get()
	joy = joypad.getdown(1)
	
	if(inp.middleclick) then --change mega man's coordinates
		local x = inp.xmouse + scroll_x
		memory.writebyte(0x0360, x)									-- set x
		memory.writebyte(0x03C0, inp.ymouse)						-- set y
		memory.writebyte(0x0480, 0xA1)
		--memory.writebyte(0x0440, 1)
		memory.writebyte(0x0380, screen_num + math.floor(x / 256))	-- set screen #
		--emu.print(memory.readbyte(0x0380))
		--emu.print(objects[0].screen)
	end
	--gui.text(megaman.sx, megaman.sy, "(" .. megaman.x .. ", " .. megaman.y .. ")")
	for i=0,31 do
		--local obj = objects[i]
		if(show_info) then
			drawObjectInfo(i)
		end
		if(show_position) then
			drawObjectPosition(i)
		end
	end

	--if(joy.right) then
	--	emu.print("right\txspd-hi:\t" .. memory.readbyte(0x0420) .. "\txspd-lo:\t" .. memory.readbyte(0x0400) .. "\tx-hi:\t" .. memory.readbyte(0x0360) .. "\tx-lo:\t" .. memory.readbyte(0x0340))
	--end

	--if(joy.left) then
	--	emu.print("left\txspd-hi:\t" .. memory.readbyte(0x0420) .. "\txspd-lo:\t" .. memory.readbyte(0x0400) .. "\tx-hi:\t" .. memory.readbyte(0x0360) .. "\tx-lo:\t" .. memory.readbyte(0x0340))
	--end
	
	if(joy.B) then
		--if(capturing_jump_info ~= true) then
		--	if(objects[0].yspd == 0xFF) then
				capturing_jump_info = true
		--		emu.print("- - - started jumping - - -")
		--	end
		--end
	else
		capturing_jump_info = false
	end
	
	if(capturing_jump_info) then
		emu.print("yspd-hi: " .. memory.readbytesigned(0x0460) .. "\tyspd-lo: " .. memory.readbyte(0x0440) .. "\ty-hi: \t" .. memory.readbytesigned(0x03C0) .. "\ty-lo: " .. memory.readbyte(0x03A0))
		--if(objects[0].yspd == 0xFF) then
		--	capturing_jump_info = false
		--	emu.print("- - - finished jumping - - -")
		--end
	end
	
	--if(joy.select) then
		--memory.writebyte(0x0440, memory.readbyte(0x0440) - 64)
		--emu.print(memory.readbytesigned(0x0460) .. "\t" .. memory.readbyte(0x0440))
	--	emu.print(memory.readbytesigned(0x0460) .. "\t" .. memory.readbyte(0x0440) .. "\t" .. memory.readbyte(0x03C0) .. "\t" .. memory.readbyte(0x03A0))
	--end

	drawObjectInfoAt(0, 10, 10)
	
	emu.frameadvance()
end