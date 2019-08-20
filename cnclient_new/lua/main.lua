-- import
require "config"

-- Penlight lua libs
pl = require'pl.import_into'()
pl.stringx.import()
C = pl.comprehension.new()

-- Flower lua libs
flower = require "flower"
tiled = require "tiled"
widget = require "widget"
Resources = flower.Resources

-- Traceback setup
--MOAISim.setTraceback(debug.traceback)

-- Resources settings
Resources.addResourceDirectory(IMAGE_PATH)
Resources.addResourceDirectory(SOUND_PATH)

-- Screen settings
local screenWidth = MOAIEnvironment.horizontalResolution or WORLD_WIDTH
local screenHeight = MOAIEnvironment.verticalResolution or WORLD_HEIGHT
if screenWidth < screenHeight then
	-- Maintain Landscape
	screenWidth, screenHeight = screenHeight, screenWidth
end

local screenXOffset = 0
local screenYOffset = 0
 
local gameAspect = WORLD_WIDTH / WORLD_HEIGHT
local realAspect = screenWidth / screenHeight
 
if realAspect > gameAspect then
	local screenHeightFixed = math.floor(screenWidth * gameAspect)
	screenYOffset = math.floor((screenHeight - screenHeightFixed) * 0.5)
	screenHeight = screenHeightFixed
elseif realAspect < gameAspect then
	local screenWidthFixed = math.floor(screenHeight / gameAspect)
	screenXOffset = math.floor((screenWidth - screenWidthFixed) * 0.5)
	screenWidth = screenWidthFixed
end

-- services setup
if MOAIApp ~= nil then
    -- Android or iOS
    MOAIApp.setListener ( MOAIApp.BACK_BUTTON_PRESSED, onBackButtonPressed )
	MOAICrittercism.init(CRITTERCISM_APPID, CRITTERCISM_APIKEY, '')
else
	MOAIInputMgr.device.keyboard:setCallback(function(key, down) if down then onBackButtonPressed() end end)
end

-- open window
flower.openWindow("Chess Nations", screenWidth, screenHeight, WORLD_WIDTH, WORLD_HEIGHT, screenXOffset, screenYOffset)
flower.openScene("puzzle_proto")