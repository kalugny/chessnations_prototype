require 'utils'
require 'statemgr'
require 'assetmgr'
require 'connection'

ChooseNation = {}

function ChooseNation:calcDistanceFromAnchor(icon)
	local iconX, iconY = icon:getLoc()
	return math.abs(self.anchorX - iconX)
end

function ChooseNation:handleClickOrTouch(x, y, eventType)
	
	x, y = self.layer:wndToWorld(x,y)

	for _, arrow in ipairs(self.arrows) do
		arrow:input(x, y, eventType)
	end
	
	
	for _, btn in ipairs(self.buttons) do
		local btnX, btnY = btn:getLoc()
		if math.abs(btnX - self.anchorX) < 3 then
			btn:input(x, y, eventType)
			break
		end
	end

		
	if eventType == MOAITouchSensor.TOUCH_DOWN or eventType == "MouseDown" then
		self.moving = false
		if not self.scrolling then
			self.scrolling = true
			self.pointerX = x
		end
	elseif eventType == MOAITouchSensor.TOUCH_UP or eventType == "MouseUp" then
		self.scrolling = false
	elseif (eventType == MOAITouchSensor.TOUCH_MOVE or eventType == "MouseMove") and self.scrolling then
		
		-- scroll the buttons
		
		local listStartX, listY = self.buttons[1]:getLoc()
		local listEndX, listY = self.buttons[#self.buttons]:getLoc()
		
		local mouseDist = x - self.pointerX
		self.pointerX = x
		if listStartX + mouseDist <= self.anchorX + self.iconWidth and listEndX + mouseDist >= self.anchorX - self.iconWidth then
			for _, icon in ipairs(self.buttons) do
				local iconX, iconY = icon:getLoc()
				iconX = iconX + mouseDist
				icon:setLoc(iconX, listY)
			end
		end
	end
	
end

function ChooseNation:clickRome()
	print('Chose Rome')
	local response = setNation('Rome')
	
	if response == 'OK' then
		statemgr.swap('menu.lua')
	end
end

function ChooseNation:clickEngland()
	print('Chose England')
	local response = setNation('England')
	
	if response == 'OK' then
		statemgr.swap('menu.lua')
	end
end


function ChooseNation:onLoad()
	self.viewport, self.screenBottom = createViewport(Env.screenWidth, Env.screenHeight)
	
	self.layer = MOAILayer2D.new ()
	self.layer:setViewport ( self.viewport )
	
	self.layerTable = {{self.layer}}
	
	self.assets = AssetMgr.load('assets.csv', 'choosenation', self.screenBottom)
	self.assets['england']['prop']:setClickFunction(ChooseNation.clickEngland, ChooseNation)
	self.assets['england']['prop'].enabled = true
	self.assets['rome']['prop']:setClickFunction(ChooseNation.clickRome, ChooseNation)
	self.assets['rome']['prop'].enabled = true
	self.assets['india']['prop']:setColor(0.3, 0.3, 0.3)
	
	self.assets['right_arrow']['prop']:setClickFunction(ChooseNation.rightClicked, ChooseNation)
	self.assets['right_arrow']['prop'].enabled = true
	self.assets['left_arrow']['prop']:setClickFunction(ChooseNation.leftClicked, ChooseNation)
	self.assets['left_arrow']['prop']:setColor(0.5, 0.5, 0.5)
	AssetMgr.addPropsToLayer(self.layer, {'bg', 'england', 'rome', 'india', 'right_arrow', 'left_arrow'}, self.assets)
	
	self.arrows = { self.assets['right_arrow']['prop'], self.assets['left_arrow']['prop'] }
	self.actions = {}
	self.englandTextbox = addTextbox("THE SUN NEVER SETS ON THE BRITISH EMPIRE! LEAD THE MIGHTY NATION FROM ITS INFANCY TO GLORY.\n\n\n<c:ff0>+3 Naval<c>", 350, 350, nil, FONT)
	self.englandTextbox:setLoc(0, -10)
	self.layer:insertProp(self.englandTextbox)
	self.romeTextbox = addTextbox("FROM THE EARLY DAYS OF THE EMPIRE, THROUGH THE AWAKENING AGE OF REASON AND ART, THE ROMAN NATION SHAPED OUR WORLD.\n\n<c:ff0>+3 War<c>", 350, 350, nil, FONT)
	self.romeTextbox:setLoc(0, -10)
	self.romeTextbox:setColor(1, 1, 1, 0)
	self.layer:insertProp(self.romeTextbox)	
	self.indiaTextbox = addTextbox("THE INDIAN SUBCONTINENT IS IDENTIFIED FOR ITS COMMERCIAL AND CULTURAL WEALTH THAT RAN FOR MOST OF ITS LONG HISTORY.\n\n\n<c:ff0>-10% Cost<c>\n\n<c:000>THIS NATION IS NOT YET AVAILABLE<c>", 350, 350, nil, FONT)
	self.indiaTextbox:setLoc(0, -10)
	self.indiaTextbox:setColor(1, 1, 1, 0)
	self.layer:insertProp(self.indiaTextbox)
	
	self.textboxes = { self.englandTextbox, self.romeTextbox, self.indiaTextbox }
		
	self.buttons = { self.assets['england']['prop'], self.assets['rome']['prop'], self.assets['india']['prop'] }
	self.anchorX = tonumber(self.assets['england']['X']) - RESOLUTION_X / 2
	self.iconWidth = tonumber(self.assets['england']['Width'])
	
	playSound('Select Your Nation.ogg')
	
end

function ChooseNation:rightClicked()
	for i, icon in ipairs(self.buttons) do
		self.actions[i] = icon:moveLoc(-400, 0, 1)
	end
end

function ChooseNation:leftClicked()
	for i, icon in ipairs(self.buttons) do
		self.actions[i] = icon:moveLoc(400, 0, 1)
	end
end

function ChooseNation:onFocus()

	playMusic()

	-- Register the callbacks for input
	if MOAIInputMgr.device.pointer then
		
		MOAIInputMgr.device.pointer:setCallback(
			function()
				local x,y = MOAIInputMgr.device.pointer:getLoc()
				self:handleClickOrTouch(x, y, "MouseMove")
			end
		)
		MOAIInputMgr.device.mouseLeft:setCallback(
			function (isMouseDown)
				local x,y = MOAIInputMgr.device.pointer:getLoc()
				local eventType = 'MouseDown'
				if not isMouseDown then
					eventType = 'MouseUp'
				end
				self:handleClickOrTouch(x, y, eventType)
			end
		)
	else
	-- If it isn't a mouse, its a touch screen... or some really weird device.
		MOAIInputMgr.device.touch:setCallback (
			function ( eventType, idx, x, y, tapCount )
				if (tapCount > 1) then
					-- nothing
				else
					self:handleClickOrTouch(x, y, eventType)
				end
			end
		)
	end
end

function ChooseNation:onUpdate()
	
	local moving = false
	for _, action in ipairs(self.actions) do
		if not action:isDone() then
			moving = true
			break
		end
	end
	
	self.moving = moving
			
	local min_dist = 10*RESOLUTION_X
	local min_i = 0
	for i, icon in ipairs(self.buttons) do
		local dist = self:calcDistanceFromAnchor(icon)
		if dist < min_dist then
			min_i = i
			min_dist = dist
		end
		local colorScale = 1 - (dist / self.iconWidth) * 0.7
		if colorScale < 0.3 then
			colorScale = 0.3
		end
		if icon.enabled then
			icon:setColor(colorScale, colorScale, colorScale)
		end
		local textbox = self.textboxes[i]
		local alphaScale = 1 - (dist / self.iconWidth * 2)
		if alphaScale < 0 then
			alphaScale = 0
		end
		textbox:setColor(1, 1, 1, alphaScale)
	end
	
	self.assets['left_arrow']['prop']:toggle(min_i > 1)
	self.assets['right_arrow']['prop']:toggle(min_i < #self.buttons)
	
	local x, y = self.buttons[min_i]:getLoc()
	local move_dist = self.anchorX - x
	
	if not self.scrolling and not self.moving then
		if math.abs(move_dist) > 3 then
			self.moving = true
			for i, icon in ipairs(self.buttons) do
				local animTime = math.abs(move_dist) / 100.0 -- 100px per second
				if animTime > 1 then
					animTime = 1
				end
				self.actions[i] = icon:moveLoc(move_dist, 0, animTime)
			end
		end
	end
	

end

return ChooseNation

