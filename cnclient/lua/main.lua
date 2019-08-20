--------------------------------------------------------------------------------------
---- INCLUDES ------------------------------------------------------------------------
--------------------------------------------------------------------------------------
require 'config'
require 'utils'
require 'statemgr'

-------------------------------------------------------------------------

function onBackButtonPressed ()
	print ( "onBackButtonPressed: " )

	return true
	
	-- The back button functionality is disabled until we make it better
--    if statemgr.stackSize() == 1 then
--    	return false
--    end
    
--    statemgr.pop()

	-- Return true if you want to override the back button press and prevent the system from handling it.
--    return true
end

--------------------------------------------------------------------------------------
---- Main ----------------------------------------------------------------------------
--------------------------------------------------------------------------------------

MOAISim.setTraceback(debug.traceback)

initSound()

if MOAIApp ~= nil then
    -- Android or iOS
    MOAIApp.setListener ( MOAIApp.BACK_BUTTON_PRESSED, onBackButtonPressed )
	
	--MOAICrittercism.init(CRITTERCISM_APPID, CRITTERCISM_APIKEY, '')
else
	MOAIInputMgr.device.keyboard:setCallback(function(key, down) if down then onBackButtonPressed() end end)
end

Env.screenWidth = RESOLUTION_X
Env.screenHeight = RESOLUTION_Y

if FIT_TO_DEVICE and MOAIEnvironment.horizontalResolution then
	Env.screenWidth = MOAIEnvironment.horizontalResolution
	Env.screenHeight = MOAIEnvironment.verticalResolution
	if Env.screenWidth < Env.screenHeight then
		-- Width should be the bigger one, as we are running in landscape
		Env.screenWidth, Env.screenHeight = Env.screenHeight, Env.screenWidth
	end
end
print('Screen resolution: ' .. Env.screenWidth .. 'x' .. Env.screenHeight)

MOAISim.openWindow ("Chess Nations", Env.screenWidth, Env.screenHeight)

loadMusic('music1.ogg')
statemgr.push(CODE_PATH .. 'facebook_login.lua')
statemgr.begin()
