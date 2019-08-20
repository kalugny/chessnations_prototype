require 'utils'
require 'statemgr'
require 'assetmgr'

Timeline = {}

local LEFT = 99
local AGE_AT = 1700
local PP_TO_NEXT_AGE = 100
local PIXELS_PER_PP = (AGE_AT - LEFT) / PP_TO_NEXT_AGE
	
function Timeline:addBosses()
	
	self.bosses = {}
	
	for _, battle in pairs(self.battles) do
	
		local placeholder = MOAIProp2D.new()
		placeholder:setDeck(self.assets['boss_banner']['gfx'])
		
		placeholder:setLoc(LEFT + PIXELS_PER_PP * battle['unlocked_at'] - RESOLUTION_X / 2 - tonumber(self.assets['boss_banner']['Width']) / 2, self.screenBottom + 145)
		
		self.layer:insertProp(placeholder)
		
		placeholder.profilePic = MOAIProp2D.new()
		placeholder.profilePic:setParent(placeholder)
		placeholder.profilePic:setLoc(tonumber(self.assets['template']['X']), tonumber(self.assets['template']['Y']))
		setProfilePic(battle['boss']['image_path'], placeholder.profilePic, self.assets['template'])
		
		self.layer:insertProp(placeholder.profilePic)
		
		table.insert(self.bosses, placeholder)
	
	end
	
end

function Timeline:createBanners()
	
	self.banners = {}
	self.openingBanners = {}
	self.closingBanners = {}
	
	local DISTANCE_BETWEEN_WINDOWS = 1330
	
	local asset_attrs = self.assets['banner']
	local dir = IMAGE_PATH .. 'timeline'
	
	for i = 0, 1 do
		
		local banner = addButton(dir .. DIR_SEP .. asset_attrs['Filename'],
								 dir .. DIR_SEP .. asset_attrs['Click image'], 
								 tonumber(asset_attrs['Width']), 
								 tonumber(asset_attrs['Height']), 
								 nil, 
								 true)
		banner.otherGfx = self.assets['banner_open']['gfx']
		
		banner.openBanner = function(banner)
			table.insert(self.openingBanners, banner)
			banner.otherGfx, banner.btnGfx = banner.btnGfx, banner.otherGfx
			banner.enabled = false
			banner.panel.enabled = true
		end
		
		banner.closeBanner = function(banner)
			table.insert(self.closingBanners, banner)
			banner.otherGfx, banner.btnGfx = banner.btnGfx, banner.otherGfx
			banner:setDeck(banner.btnGfx)
			banner.enabled = true
			banner.panel.enabled = false
		end

		banner.panel = addButton(dir .. DIR_SEP .. self.assets['banner_panel']['Filename'],
								 dir .. DIR_SEP .. self.assets['banner_panel']['Filename'],
								 tonumber(self.assets['banner_panel']['Width']),
								 tonumber(self.assets['banner_panel']['Height']),
								 nil,
								 false)
		banner.panel:setParent(banner)
		banner.panel.height = tonumber(self.assets['banner_panel']['Height'])
		banner.panel.width = tonumber(self.assets['banner_panel']['Width'])
		banner.panel:setLoc(22, 24)
		banner.panel.scissorRect = MOAIScissorRect.new()
		
		banner:setClickFunction(banner.openBanner, banner)
		banner.panel:setClickFunction(banner.closeBanner, banner)
		banner:setLoc(tonumber(self.assets['banner']['X']) + i * DISTANCE_BETWEEN_WINDOWS - RESOLUTION_X / 2, tonumber(self.assets['banner']['Y']) + self.screenBottom)
		
		banner:setPriority(100)
		banner.panel:setPriority(99)
		
		self.layer:insertProp(banner.panel)
		self.layer:insertProp(banner)
		
		local panelX, panelY = banner:getLoc()
		banner.panel.scissorRect:setRect(panelX + 22, panelY + 24 - banner.panel.height, panelX + 22 + banner.panel.width, panelY + 24)
		banner.panel:setScissorRect(banner.panel.scissorRect)
	
		table.insert(self.banners, banner)
	end
	
end

function Timeline:setProgress(pp)

	-- This is now hard-coded for one age, at 100 points.
	
	if pp >= PP_TO_NEXT_AGE then
		self.age2Leader:setColor(1, 1, 1)
	end
	
	if self.lines then
		for _, line in ipairs(self.lines) do
			self.layer:removeProp(line)
		end
	end
	
	self.lines = {}
	
	local pixels = PIXELS_PER_PP * pp
	
	for i = 0, pixels - 1 do
		local line = MOAIProp2D.new()
		line:setDeck(self.assets['line']['gfx'])
		line:setLoc(LEFT + i - RESOLUTION_X / 2, self.screenBottom + 138)
		line:setPriority(10)
		self.layer:insertProp(line)
		table.insert(self.strip, line)
		table.insert(self.lines, line)
	end

end

function Timeline:handleClickOrTouch(x, y, eventType)
	
	x, y = self.layer:wndToWorld(x,y)
	
	for i, btn in ipairs(self.menuBar.buttons) do
		btn:input(x, y, eventType)
	end
	
	for i, btn in ipairs(self.banners) do
		btn:input(x, y, eventType)
		btn.panel:input(x, y, eventType)
	end
	
	if eventType == MOAITouchSensor.TOUCH_DOWN or eventType == "MouseDown" then
		if not self.scrolling then
			self.scrolling = true
			self.pointerX = x
		end
	elseif eventType == MOAITouchSensor.TOUCH_UP or eventType == "MouseUp" then
		self.scrolling = false
	elseif (eventType == MOAITouchSensor.TOUCH_MOVE or eventType == "MouseMove") and self.scrolling then
		-- scroll the strip
		
		local strip1X, stripY = self.strip[1]:getLoc()
		local stripWidth = 1280 * 9 + 1122
		
		local mouseDist = x - self.pointerX
		self.pointerX = x
		if strip1X + mouseDist <= -RESOLUTION_X / 2 and strip1X + mouseDist > RESOLUTION_X / 2 - stripWidth then
			for _, strip in ipairs(self.strip) do
				local stripX, stripY = strip:getLoc()
				stripX = stripX + mouseDist
				strip:setLoc(stripX, stripY)
			end
		end
	end
	
end

function Timeline:getData()

	local data = getTimelineData()

	Env.player = data['player']
	self.battles = data['battles']

end

function Timeline:onLoad()
	self:getData()
	self.viewport, self.screenBottom = createViewport(Env.screenWidth, Env.screenHeight)
	
	self.layer = MOAILayer2D.new ()
	self.layer:setViewport ( self.viewport )
	
	self.layerTable = {{self.layer}}
	
	self.assets = AssetMgr.load('assets.csv', 'timeline', self.screenBottom)
	AssetMgr.addPropsToLayer(self.layer, {'strip1', 'strip2', 'strip3', 'strip4', 'strip5', 'strip6', 'strip7', 'strip8', 'strip9', 'strip10', 'circle'}, self.assets)

	self.age1Leader = getLeaderProp(Env.player['nation'], '1')
	self.age1Leader:setLoc(-372, self.screenBottom + 385)
	self.age1Leader:setScl(0.9)
	self.layer:insertProp(self.age1Leader)
	self.age2Leader = getLeaderProp(Env.player['nation'], '2')
	self.age2Leader:setLoc(958, self.screenBottom + 385)
	self.age2Leader:setScl(0.9)
	self.age2Leader:setColor(0.5, 0.5, 0.5)
	self.layer:insertProp(self.age2Leader)
	
	self:createBanners()	
	self:addBosses()
	
	self.strip = { self.assets['strip1']['prop'], 
				   self.assets['strip2']['prop'],
				   self.assets['strip3']['prop'],
				   self.assets['strip4']['prop'],
				   self.assets['strip5']['prop'],
				   self.assets['strip6']['prop'],
				   self.assets['strip7']['prop'],
				   self.assets['strip8']['prop'],
				   self.assets['strip9']['prop'],
				   self.assets['strip10']['prop'],
				   self.assets['circle']['prop'], 
				   self.age1Leader,
				   self.age2Leader,}
				   
	for _, banner in ipairs(self.banners) do
		table.insert(self.strip, banner)
		table.insert(self.strip, banner.panel.scissorRect)
	end
		
	for _, boss in ipairs(self.bosses) do
		table.insert(self.strip, boss)
	end
		
	self.menuBar = addMenuBar(self.layer)
end

function Timeline:onFocus()

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
	
	self:getData()
	self:setProgress(Env.player['progress_points'])
end

function Timeline:onUpdate()

	while #self.openingBanners > 0 do
		print('opening banner')
		local banner = table.remove(self.openingBanners)
		banner.panel:moveLoc(0, -banner.panel.height, 1)
		
	end
	
	while #self.closingBanners > 0 do
		print('closing banner')
		local banner = table.remove(self.closingBanners)
		banner.panel:moveLoc(0, banner.panel.height, 1)
		
	end
end

return Timeline

