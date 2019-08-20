require 'config'
require 'statemgr'
require 'connection'

--------------------------------------------------------------------------------------
---- SINGLETONS ----------------------------------------------------------------------
--------------------------------------------------------------------------------------
CHARCODES = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?()&/-'
FONT = 	MOAIFont.new ()
FONT:loadFromTTF(IMAGE_PATH .. 'fonts' .. DIR_SEP .. 'MyriadPro-Semibold.otf', CHARCODES, 7.5, 163 )

--------------------------------------------------------------------------------------
---- UTILITY FUCTIONS ----------------------------------------------------------------
--------------------------------------------------------------------------------------

function printf ( ... )
	return io.stdout:write ( string.format ( ... ))
end 

function wait ( action )
	MOAIThread.blockOnAction(action)
end

function fileExists(path)
   local f = io.open(path, "r")
   if f~=nil then 
		io.close(f)
		return true 
	else 
		return false 
	end
end

--[[
	String and table utils
  ]]--

-- string indexing
getmetatable('').__index = function(str,i)
  if type(i) == 'number' then
    return string.sub(str,i,i)
  else
    return string[i]
  end
end

function string.startswith(String, Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function string:split(sSeparator, nMax, bRegexp)
	assert(sSeparator ~= '')
	assert(nMax == nil or nMax >= 1)

	local aRecord = {}

	if self:len() > 0 then
		local bPlain = not bRegexp
		nMax = nMax or -1

		local nField=1 nStart=1
		local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
		while nFirst and nMax ~= 0 do
			aRecord[nField] = self:sub(nStart, nFirst-1)
			nField = nField+1
			nStart = nLast+1
			nFirst,nLast = self:find(sSeparator, nStart, bPlain)
			nMax = nMax-1
		end
		aRecord[nField] = self:sub(nStart)
	end

	return aRecord
end

function table.key_to_str ( k )
    if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
        return k
    else
        return "[" .. table.val_to_str( k ) .. "]"
    end
end

function table.val_to_str ( v )
    if "string" == type( v ) then
        local new_v = string.gsub( v, "\n", "\\n" )
        if string.match( string.gsub(new_v,"[^'\"]",""), '^"+$' ) then
            return "'" .. new_v .. "'"
        end
        return '"' .. string.gsub(new_v,'"', '\\"' ) .. '"'
    else
        if "table" == type( v ) then
            return table.tostring( v )
        else
            return tostring(v)
        end
    end
end

function table.tostring(tbl)
    --Wtf lua, how am I supposed to debug stuff without this?
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
        table.insert( result, table.val_to_str( v ) )
        done[k] = true
    end
    for k, v in pairs(tbl) do
        if not done[ k ] then
            table.insert( result,
            table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
        end
    end
    return "{" .. table.concat( result, "," ) .. "}"
end

function table.contains(tbl, o)
	for _, v in ipairs(tbl) do
		if v == o then return true end
	end
	return false
end

--[[
    Sound utils
  ]]--

function initSound()

	if MOAIFmodEx then
		--MOAIFmodEx.init()
	elseif MOAIUntzSystem then
		MOAIUntzSystem.initialize()
	end

end
  
function loadMusic(filename)
	print('Loading ' .. SOUND_PATH ..  filename .. '...')
	
	if MOAIFmodExSound then
		local sound = MOAIFmodExSound.new()
		sound:load(SOUND_PATH .. filename, true, true)
		loaded_music = MOAIFmodExChannel.new()
		loaded_music:setLooping(true)
		loaded_music:setVolume(0.75)
		loaded_music:play(sound)
		loaded_music:setPaused(true)
	elseif MOAIUntzSound then
		loaded_music = MOAIUntzSound.new ()
		loaded_music:load ( SOUND_PATH .. filename )
		loaded_music:setVolume ( 0.75 )
		loaded_music:setLooping ( true )
	end
	
end

function playMusic()
	if loaded_music then
		if not loaded_music:isPlaying() then
			loaded_music:play()
		else
			loaded_music:setVolume(0.75, 1.5)
		end
	end
end

function pauseMusic()
	if loaded_music then
		loaded_music:setVolume(0.2, 1.5)
	end
end

function playSound(filename)
	print('Playing ' .. SOUND_PATH ..  filename .. '...')
	
	if MOAIFmodExSound then
		local sound = MOAIFmodExSound.new()
		sound:load(SOUND_PATH .. filename, true, true)
		channel = MOAIFmodExChannel.new()
		channel:setLooping(false)
		channel:setVolume(1)
		channel:play(sound)
	elseif MOAIUntzSound then
		sound = MOAIUntzSound.new ()
		sound:load ( SOUND_PATH .. filename )
		sound:setVolume ( 1 )
		sound:setLooping ( false )
		sound:play ()
	end
end

--[[ 
	GUI utils
  ]]--
function createViewport(screenWidth, screenHeight)
	local viewport = MOAIViewport.new ()
    viewport:setScale(RESOLUTION_X, RESOLUTION_Y)

    local yOffset = 0

	local screenHeightWithCorrectRatio = screenWidth * RESOLUTION_Y / RESOLUTION_X

	-- The screen coords are (screenWidth, screenHeight)
	-- The screen coords in the correct aspect ratio is (screenWidth, screenHeightWithCorrectRatio)
	-- Therefore the bottom of the screen in correct ration is screenHeight - screenHeightWithCorrectRatio below the middle
	-- and then we need to adjust it to world coords.
	local screenBottom = (screenHeightWithCorrectRatio / 2 - screenHeight) * (RESOLUTION_Y / screenHeightWithCorrectRatio)
	if screenHeightWithCorrectRatio < screenHeight then
        yOffset = (screenHeight - screenHeightWithCorrectRatio) / 2
		screenBottom = -RESOLUTION_Y / 2
	end

    viewport:setSize(0, yOffset, screenWidth, screenHeightWithCorrectRatio + yOffset)

	
	return viewport, screenBottom

end

function addTextbox(text, width, height, alignment, font)
	if not alignment then
		alignment = MOAITextBox.CENTER_JUSTIFY
	end
	
	local textbox = MOAITextBox.new ()
	textbox:setString ( text )
	textbox:setFont ( font )
	textbox:setTextSize ( 7.5, 163 )
	textbox:setRect ( -width / 2, height / 2, width / 2,  -height / 2 )
	textbox:setAlignment(alignment)
	textbox:setYFlip ( true )
	
	return textbox
end

function addButton(image, click_image, width, height, onClick, enabled)

	if enabled == nil then
		enabled = true
	end

	local btn = MOAIProp2D.new()
	
	btn.btnGfx = MOAIGfxQuad2D.new()
	btn.btnGfx:setTexture(IMAGE_PATH .. image, MOAITexture.TRUECOLOR)
	btn.btnGfx:setRect(0, 0, width, height)
	
	btn.btnClickGfx = MOAIGfxQuad2D.new()
	btn.btnClickGfx:setTexture(IMAGE_PATH .. click_image, MOAITexture.TRUECOLOR)
	btn.btnClickGfx:setRect(0, 0, width, height)
		
	btn:setDeck(btn.btnGfx)
	
	btn.click_func = onClick
	
	btn.onDown = function(btn)
		btn:setDeck(btn.btnClickGfx)
		btn.isDown = true
	end
	
	btn.onUp = function(btn)
		btn:setDeck(btn.btnGfx)
		btn.isDown = false
	end
	
	btn.onClick = function(btn)
		playSound('button_click.ogg')
		if btn.func_object then
			btn.click_func(btn.func_object)
		else
			btn.click_func()
		end
		btn:onUp()
	end
	
	btn.setClickFunction = function(btn, func, object)
		btn.click_func = func
		btn.func_object = object
	end
	
	btn.input = function(btn, x, y, eventType)
		if not btn.enabled then
			return
		end
		if eventType == MOAITouchSensor.TOUCH_UP or eventType == 'MouseUp' then
			if btn:inside(x, y) and btn.isDown then
				btn:onClick()
			else
				btn:onUp()
			end
		elseif (eventType == MOAITouchSensor.TOUCH_DOWN or eventType == 'MouseDown') and btn:inside(x, y) then
			btn:onDown()
		end
	end
	
	btn.enable = function(btn)
		if not btn.enabled then
			btn:seekColor(1, 1, 1, 1, 0.5)
			btn.enabled = true
		end
	end

	btn.disable = function(btn)
		if btn.enabled then
			btn.enabled = false
			btn:seekColor(0.5, 0.5, 0.5, 1, 0.5)
		end
	end
	
	btn.toggle = function(btn, isTrue)
		if isTrue then
			btn:enable()
		else
			btn:disable()
		end
	end
	
	btn.enabled = enabled
	return btn

end

--[[
	The menu bar on top
  ]]--
 function addMenuBar(layer, show_forfeit)
 
	local bar = {}
	bar.buttons = {}
	
	bar.backgroudGfx = MOAIGfxQuad2D.new()
	bar.backgroudGfx:setTexture(IMAGE_PATH .. 'menubar' .. DIR_SEP .. 'topheader_base.png', MOAITexture.TRUECOLOR)
	bar.backgroudGfx:setRect(0, 0, 1280, 114)
	
	bar.backgroud = MOAIProp2D.new()
	bar.backgroud:setDeck(bar.backgroudGfx)
	bar.backgroud:setLoc(-RESOLUTION_X / 2, RESOLUTION_Y / 2 - 114)
	bar.backgroud:setPriority(1000)
	layer:insertProp(bar.backgroud)
	
	-- Buttons on the left
	bar.gamesBtn = addButton('menubar' .. DIR_SEP .. 'topheader_navbuttons_games_idle.png', 'menubar' .. DIR_SEP .. 'topheader_navbuttons_games_pressed.png', 78, 78, 
		function()
			while statemgr.stackSize() > 0 do
				statemgr.pop(true)
			end
			statemgr.push('menu.lua')
		end)
	bar.gamesBtn:setParent(bar.backgroud)
	bar.gamesBtn:setLoc(25, 25)
	bar.gamesBtn:setPriority(1001)
	table.insert(bar.buttons, bar.gamesBtn)
	layer:insertProp(bar.gamesBtn)	

	bar.storeBtn = addButton('menubar' .. DIR_SEP .. 'topheader_navbuttons_store_idle.png', 'menubar' .. DIR_SEP .. 'topheader_navbuttons_store_pressed.png', 78, 78, function() print 'Store pressed' end)
	bar.storeBtn:setParent(bar.backgroud)
	bar.storeBtn:setLoc(110, 25)
	bar.storeBtn:setPriority(1001)	
	table.insert(bar.buttons, bar.storeBtn)
	layer:insertProp(bar.storeBtn)
	
	bar.historyBtn = addButton('menubar' .. DIR_SEP .. 'topheader_navbuttons_history_idle.png', 'menubar' .. DIR_SEP .. 'topheader_navbuttons_history_pressed.png', 78, 78, 
		function() 
			statemgr.push(CODE_PATH .. 'timeline.lua')
		end)
	bar.historyBtn:setParent(bar.backgroud)
	bar.historyBtn:setLoc(195, 25)
	bar.historyBtn:setPriority(1001)
	table.insert(bar.buttons, bar.historyBtn)
	layer:insertProp(bar.historyBtn)
	
	bar.discoveryBtn = addButton('menubar' .. DIR_SEP .. 'topheader_navbuttons_discovery_idle.png', 'menubar' .. DIR_SEP .. 'topheader_navbuttons_discovery_pressed.png', 78, 78, function() print 'discovery pressed' end)
	bar.discoveryBtn:setParent(bar.backgroud)
	bar.discoveryBtn:setLoc(278, 25)
	bar.discoveryBtn:setPriority(1001)
	table.insert(bar.buttons, bar.discoveryBtn)
	layer:insertProp(bar.discoveryBtn)
	
	-- Buttons on the right
	
	bar.settingsBtn = addButton('menubar' .. DIR_SEP .. 'topheader_navbuttons_settings_idle.png', 'menubar' .. DIR_SEP .. 'topheader_navbuttons_settings_pressed.png', 78, 78, 
		function() 
			logout()
			while statemgr.stackSize() > 0 do
				statemgr.pop(true)
			end
			statemgr.push('facebook_login.lua')
		end)
	bar.settingsBtn:setParent(bar.backgroud)
	bar.settingsBtn:setLoc(1190, 25)
	bar.settingsBtn:setPriority(1001)	
	table.insert(bar.buttons, bar.settingsBtn)
	layer:insertProp(bar.settingsBtn)
	
	bar.snapshotBtn = addButton('menubar' .. DIR_SEP .. 'plus_idle.png', 'menubar' .. DIR_SEP .. 'plus_pressed.png', 68, 68, 
		function() 
			local game_id = startNewGame()
			if game_id then
				statemgr.push(CODE_PATH .. 'game.lua', game_id)
			end
		end)
	bar.snapshotBtn:setParent(bar.backgroud)
	bar.snapshotBtn:setLoc(1118, 22)
	bar.snapshotBtn:setPriority(1001)	
	table.insert(bar.buttons, bar.snapshotBtn)
	layer:insertProp(bar.snapshotBtn)
	
	if show_forfeit then
		bar.forfeitBtn = addButton('menubar' .. DIR_SEP .. 'topheader_navbuttons_forfeit_idle.png', 'menubar' .. DIR_SEP .. 'topheader_navbuttons_forfeit_pressed.png', 50, 58, function() print 'forfeit pressed' end)
		bar.forfeitBtn:setParent(bar.backgroud)
		bar.forfeitBtn:setLoc(1045, 30)
		bar.forfeitBtn:setPriority(1001)	
		table.insert(bar.buttons, bar.forfeitBtn)
		layer:insertProp(bar.forfeitBtn)
	end
	
	-- small +
	bar.plusBtn = addButton('menubar' .. DIR_SEP .. 'topheader_navbuttons_moneyplus_idle.png', 'menubar' .. DIR_SEP .. 'topheader_navbuttons_moneyplus_pressed.png', 24, 24, function() print 'money plus pressed' end)
	bar.plusBtn:setParent(bar.backgroud)
	bar.plusBtn:setLoc(616, 53)
	bar.plusBtn:setPriority(1001)	
	table.insert(bar.buttons, bar.plusBtn)
	layer:insertProp(bar.plusBtn)

	
	return bar
 
 end
 
 function getLeaderProp(nation, age)
	local gfx = MOAIGfxQuad2D.new()
	gfx:setTexture(IMAGE_PATH .. 'leaders' .. DIR_SEP .. nation .. DIR_SEP .. 'age' .. age .. '.png')
	gfx:setRect(0,0,204,282)
 
	local prop = MOAIProp2D.new()
	prop:setDeck(gfx)
	return prop
	
 end