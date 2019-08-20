require 'utils'
require 'statemgr'
require 'assetmgr'
require 'connection'

LevelUp = {}
statemgr.makePopup(LevelUp)

function LevelUp:handleClickOrTouch(x, y, eventType)
	
	x, y = self.layer:wndToWorld(x,y)
	
	for _, btn in ipairs(self.buttons) do
		btn:input(x, y, eventType)
	end
	
end

function LevelUp:onLoad()
	self.viewport, self.screenBottom = createViewport(Env.screenWidth, Env.screenHeight)
	
	self.layer = MOAILayer2D.new ()
	self.layer:setViewport ( self.viewport )
	
	self.layerTable = {{self.layer}}
	
	self.assets = AssetMgr.load('assets.csv', 'levelup', self.screenBottom)
	self.assets['ok_btn']['prop']:setClickFunction(LevelUp.okClicked, LevelUp)
	self.assets['ok_btn']['prop'].enabled = true
	self.assets['tl_btn']['prop']:setClickFunction(LevelUp.tlClicked, LevelUp)
	self.assets['tl_btn']['prop'].enabled = true
	
	AssetMgr.addPropsToLayer(self.layer, {'bg', 'ok_btn', 'tl_btn'}, self.assets)
	
	self.leader = getLeaderProp(Env.player['nation'], Env.player['age']['number'])
	self.leader:setScl(0.7)
	self.leader:setLoc(-80, -70)
	self.layer:insertProp(self.leader)
	
	self.textbox = addTextbox("<c:ff0>YOU HAVE LEVELED UP!<c>", 350, 50, nil, FONT)
	self.textbox:setLoc(0, -50)
	self.layer:insertProp(self.textbox)
	
	self.buttons = { self.assets['ok_btn']['prop'], self.assets['tl_btn']['prop'] }
	
end

function LevelUp:okClicked()
	statemgr.pop()
end

function LevelUp:tlClicked()
	statemgr.push(CODE_PATH .. CODE_PATH .. 'timeline.lua')
end

function LevelUp:onFocus()

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

return LevelUp

