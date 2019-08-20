require 'assetmgr'
require 'config'

OSFManager = {}

function OSFManager:init(bottom, asset_filename)
	
	if not asset_filename then
		asset_filename = 'assets.csv'
	end
	
	self.assets = AssetMgr.load(asset_filename, 'osf', bottom)
	
	self.bg = self.assets['bg']['prop']
	self.bg:setPriority(1100)
	self.panelWidth = tonumber(self.assets['bg']['Width'])
	
	self.bgCurve = MOAIAnimCurve.new ()
	self.bgCurve:reserveKeys ( 4 )
	self.bgCurve:setKey ( 1, 0, -self.panelWidth - RESOLUTION_X / 2 )
	self.bgCurve:setKey ( 2, 0.5, -RESOLUTION_X / 2 )
	self.bgCurve:setKey ( 3, 1.5, -RESOLUTION_X / 2 )
	self.bgCurve:setKey ( 4, 2, self.panelWidth )

	self.bg:setAttrLink(MOAIProp2D.ATTR_X_LOC, self.bgCurve, MOAIAnimCurve.ATTR_VALUE)

	self.timer = MOAITimer.new ()
	self.timer:setSpan ( 0, self.bgCurve:getLength ())
	
	self.bgCurve:setAttrLink ( MOAIAnimCurve.ATTR_TIME, self.timer, MOAITimer.ATTR_TIME )

end

function OSFManager:innerShow(layer, osf_name)
	local prop = self.assets[osf_name]['prop']
	prop:setPriority(1101)
	
	layer:insertProp(self.bg)
	layer:insertProp(prop)
	
	local propCurve = MOAIAnimCurve.new ()
	propCurve:reserveKeys ( 4 )
	propCurve:setKey ( 1, 0.2, -self.panelWidth - RESOLUTION_X / 2 )
	propCurve:setKey ( 2, 0.7, -RESOLUTION_X / 2 )
	propCurve:setKey ( 3, 1.3, -RESOLUTION_X / 2 )
	propCurve:setKey ( 4, 1.8, self.panelWidth )

	prop:setAttrLink(MOAIProp2D.ATTR_X_LOC, propCurve, MOAIAnimCurve.ATTR_VALUE)
	
	propCurve:setAttrLink ( MOAIAnimCurve.ATTR_TIME, self.timer, MOAITimer.ATTR_TIME )

	function timerEnd()
		layer:removeProp(self.bg)
		layer:removeProp(prop)
	end
	
	self.timer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, timerEnd)
	
	self.timer:start()
	
	return self.timer
end

function OSFManager:show(layer, osf_name)

	local soundFilename = osf_name .. '.ogg'
	
	if fileExists(SOUND_PATH .. soundFilename) then
		playSound(soundFilename)
	end

	wait(OSFManager:innerShow(layer, osf_name))
	
	
end