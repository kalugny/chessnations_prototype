require 'utils'
require 'statemgr'
require 'assetmgr'
require 'connection'

Menu = {}

function Menu:addGameButton(game, list)
	local btn = MOAIProp2D.new()
	btn:setDeck(self.assets['blank']['gfx'])
	btn:setPriority(100)
	
	btn.game = game

	btn.profilePic = MOAIProp2D.new()
	btn.profilePic:setParent(btn)
	btn.profilePic:setDeck(self.assets['empty_user']['gfx'])
	btn.profilePic:setPiv(0, tonumber(self.assets['empty_user']['Height']) / 2)
	btn.profilePic:setLoc(tonumber(self.assets['empty_user']['X']), tonumber(self.assets['empty_user']['Y']))
	btn.profilePic:setPriority(101)
	if game['opponent']['image_path'] ~= '' then
		setProfilePic(game['opponent']['image_path'], btn.profilePic, self.assets['profile_template'])
	end
	
	btn.frame = MOAIProp2D.new()
	btn.frame:setParent(btn)
	btn.frame:setDeck(self.assets['frame']['gfx'])
	btn.frame:setPiv(0, tonumber(self.assets['frame']['Height']) / 2)
	btn.frame:setLoc(tonumber(self.assets['frame']['X']), tonumber(self.assets['frame']['Y']))
	btn.frame:setPriority(103)
	
	local opponent_name = game['opponent']['name']
	if opponent_name == '' then
		opponent_name = game['opponent']['username']
	end
	
	btn.gameText = addTextbox(opponent_name, 300, 50, MOAITextBox.LEFT_JUSTIFY, self.font)
	btn.gameText:setParent(btn)
	btn.gameText:setLoc(280, 100)
	btn.gameText:setPriority(101)	
		
	btn.lastMoveText = addTextbox(game['last_move_on'], 100, 50, MOAITextBox.LEFT_JUSTIFY, self.font)
	btn.lastMoveText:setParent(btn)
	btn.lastMoveText:setLoc(360, 100)
	btn.lastMoveText:setPriority(101)

	btn.nationText = addTextbox('<c:ff0>' .. game['opponent']['nation'] .. '<c>', 300, 50, MOAITextBox.LEFT_JUSTIFY, self.font)
	btn.nationText:setParent(btn)
	btn.nationText:setLoc(280, 70)
	btn.nationText:setPriority(101)
	
	btn.divider = MOAIProp2D.new()
	btn.divider:setParent(btn)
	btn.divider:setDeck(self.assets['divider']['gfx'])
	btn.divider:setLoc(0,0)
	btn.gameText:setPriority(101)
	
	self.layer:insertProp(btn)
	self.layer:insertProp(btn.profilePic)
	self.layer:insertProp(btn.frame)
	self.layer:insertProp(btn.gameText)
	self.layer:insertProp(btn.lastMoveText)
	self.layer:insertProp(btn.nationText)
	self.layer:insertProp(btn.divider)
	
	btn.enabled = true
	
	btn.onDown = function(btn, y)
		btn:setDeck(self.assets['selected']['gfx'])
		btn.isDown = true
		self.selectedBtn = btn
		self.selectedBtnLoc = btn:getLoc()
		self.pointerY = y
	end
	
	btn.onUp = function(btn)
		btn:setDeck(self.assets['blank']['gfx'])
		btn.isDown = false
		self.selectedBtn = nil
		self.selectedBtnY = nil
		self.pointerY = nil
	end
	
	btn.onClick = function(btn)
		playSound('button_click.ogg')
		statemgr.push(CODE_PATH .. 'game.lua', btn.game['game_id'])
		btn:onUp()
	end
		
	btn.input = function(btn, x, y, eventType)
		if not btn.enabled then
			return
		end	
		if eventType == MOAITouchSensor.TOUCH_UP or eventType == 'MouseUp' then
			if self.scrolling then
				self.scrolling = false
				btn:onUp()
			elseif btn:inside(x, y) and y < list.top + 110 and self.selectedBtn == btn then
				btn:onClick()
			elseif btn.isDown then
				btn:onUp()
			end
		elseif (eventType == MOAITouchSensor.TOUCH_DOWN or eventType == 'MouseDown') and btn:inside(x, y) and y < list.top + 110 then
			btn:onDown(y)
		end
		
	end
	
	table.insert(list, btn)
	return btn
		
end

function Menu:removeBtn(btn)

	self.layer:removeProp(btn)
	self.layer:removeProp(btn.profilePic)
	self.layer:removeProp(btn.frame)
	self.layer:removeProp(btn.gameText)
	self.layer:removeProp(btn.lastMoveText)
	self.layer:removeProp(btn.nationText)
	self.layer:removeProp(btn.divider)
	
	return btn
		
end

function Menu:updateList()

	function menu(task, status)
	
		if status == 200 then
			local games = MOAIJsonParser.decode(task:getString())
			Env.username = games['username']
			self.games_my_move = games['games_my_move']
			self.games_not_my_move = games['games_not_my_move']
			Env.player = games['player']
			print(table.tostring(Env.player))
			if not self.portrait_set then
				Env.nation = games['player']['nation']
				local icon = self.assets[Env.nation]['prop']
				icon:setPriority(801)
				self.layer:insertProp(icon)
				self.portrait_set = true
			end
			self:createGameLists(self.games_my_move, self.games_not_my_move)
		end
	end

	self:resetLists()
	getWithCookie(SERVER_ADDRESS .. '/game/json/', menu, true)

end

function Menu:resetLists()
	for i, btn in ipairs(self.my_list) do
		self:removeBtn(btn)
	end
	self.my_list = {}	
	self.my_list.top = 90
	self.my_list.height = 0

	for i, btn in ipairs(self.opponent_list) do
		self:removeBtn(btn)
	end
	self.opponent_list = {}	
	self.opponent_list.top = 90
	self.opponent_list.height = 0
	
	self.loadingTextLeft:setVisible(true)
	self.loadingTextRight:setVisible(true)

	
end

function Menu:createGameLists(my_games, opponent_games)

	self.loadingTextLeft:setVisible(false)
	self.loadingTextRight:setVisible(false)

	for i, game in ipairs(my_games) do
		local btn = self:addGameButton(game, self.my_list)
		btn:setLoc(-640, self.my_list.top - (i - 1) * 110)
		self.my_list.height = self.my_list.height + 110
	end	
	
	for i, game in ipairs(opponent_games) do
		local btn = self:addGameButton(game, self.opponent_list)
		btn:setLoc(640 - 434, self.opponent_list.top - (i - 1) * 110)
		self.opponent_list.height = self.opponent_list.height + 110
	end	
		
end

function Menu:handleClickOrTouch(x, y, eventType)
	
	x, y = self.layer:wndToWorld(x,y)
	
	for i, btn in ipairs(self.menuBar.buttons) do
		btn:input(x, y, eventType)
	end
	
	for i, btn in ipairs(self.my_list) do
		btn:input(x, y, eventType)
	end
	
	for i, btn in ipairs(self.opponent_list) do
		btn:input(x, y, eventType)
	end
	
	if (eventType == MOAITouchSensor.TOUCH_MOVE or eventType == "MouseMove") and self.selectedBtn then
		-- scroll the list
		self.scrolling = true
		local listToScroll = self.my_list
		if not table.contains(self.my_list, self.selectedBtn) then
			listToScroll = self.opponent_list
		end
		
		local mouseDist = y - self.pointerY
		self.pointerY = y
		local firstBtnX, firstBtnY = listToScroll[1]:getLoc()
		local lastBtnX, lastBtnY = listToScroll[#listToScroll]:getLoc()
		if listToScroll.height > math.abs(self.screenBottom	- listToScroll.top)								-- If the list is larger than the screen
		   and lastBtnY + mouseDist <= self.screenBottom and firstBtnY + mouseDist >= listToScroll.top 		-- and stops when reaches the ends
		   then
			for i, btn in ipairs(listToScroll) do	
				local btnX, btnY = btn:getLoc()
				btnY = btnY + mouseDist
				btn:setLoc(btnX, btnY)
			end
		end
	end
	
end

function Menu:onLoad()
	self.viewport, self.screenBottom = createViewport(Env.screenWidth, Env.screenHeight)
	
	self.layer = MOAILayer2D.new ()
	self.layer:setViewport ( self.viewport )
	
	self.layerTable = {{self.layer}}
	
	self.my_list = {}
	self.opponent_list = {}
	
	self.assets = AssetMgr.load('assets.csv', 'lobby', self.screenBottom)
	AssetMgr.addPropsToLayer(self.layer, {'background', 'scroll_hider', 'progress_fill', 'progress_frame'}, self.assets)
	self.assets['scroll_hider']['prop']:setPriority(800)

	self.font = FONT
	
	self.loadingTextLeft = addTextbox("Loading...", 444, 110, nil, self.font)
	self.loadingTextLeft:setLoc(-640 + 222, 90)
	self.layer:insertProp(self.loadingTextLeft)
	self.loadingTextRight = addTextbox("Loading...", 444, 110, nil, self.font)
	self.loadingTextRight:setLoc(640 - 222, 90)
	self.layer:insertProp(self.loadingTextRight)
	
	self.portrait_set = false
	
	self.menuBar = addMenuBar(self.layer)
end

function Menu:onFocus()

	pauseMusic()

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
	self:updateList()

end

return Menu

