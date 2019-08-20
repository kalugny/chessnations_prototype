
require 'statemgr'
require 'config'

package.path = '../moaigui/?.lua;' .. package.path

require "gui/support/class"

local gui = require "gui/gui"
local resources = require "gui/support/resources"
local filesystem = require "gui/support/filesystem"
local inputconstants = require "gui/support/inputconstants"
local layermgr = require "layermgr"

Login = {}

function Login:login(username, password)

	print('login start')

	local cookie = nil

	function saveCookie(task, status)
		if status >= 200 and status < 400 then
			cookie = task:getResponseHeader('Set-Cookie')
			Env.cookie = cookie
			print('login - Logged it as ' .. username)
			Env.username = username
		end
	end

	local task = MOAIHttpTask.new()

	print('username = ' .. username .. ', password = ' .. password)
	task:setBody('username=' .. username .. '&password=' .. password)
	task:setUrl(SERVER_ADDRESS .. '/login/')
	task:setVerb(MOAIHttpTask.HTTP_POST)
	task:setVerbose(DEBUG)
	task:setCallback(saveCookie)
	task:performSync()

	print('login complete')
	
	task = nil
	collectgarbage()
	
	return cookie
	
end

function Login:onLoad()

	self.g = gui.GUI(Env.screenWidth, Env.screenHeight)

	-- Resource paths - search through these for specified resources
	self.g:addToResourcePath(filesystem.pathJoin("../moaigui/resources", "fonts"))
	self.g:addToResourcePath(filesystem.pathJoin("../moaigui/resources", "gui"))
	self.g:addToResourcePath(filesystem.pathJoin("../moaigui/resources", "media"))
	self.g:addToResourcePath(filesystem.pathJoin("../moaigui/resources", "themes"))

	self.layerTable = {{self.g:layer()}}
	
	self.g:setTheme("basetheme.lua")

	-- The font used for text
	self.g:setCurrTextStyle("default")
	
	function buttonClick(event, data)
		print('Button clicked')
		local username = self.userEdit:getText()
		local pass = self.passEdit:getText()
		
		local cookie = self:login(username, pass)
		
		if cookie == nil then
			self.userEdit:setText("")
			self.passEdit:setText("")
		else
			print('cookie = ' .. cookie)
			statemgr.push(CODE_PATH .. 'menu.lua')
		end
	end

	
	local focusedEdit = nil
	
	function onInput(start, length, text)
		if focusedEdit then
			focusedEdit:setText(text)
		end
	end
	
	function onReturn()
		if focusedEdit == self.userEdit then
			self.g:setFocus(self.passEdit)
		elseif focusedEdit == self.passEdit then
			buttonClick()
		end
	end
	
	MOAIKeyboardAndroid.setListener ( MOAIKeyboardAndroid.EVENT_INPUT, onInput )
	MOAIKeyboardAndroid.setListener ( MOAIKeyboardAndroid.EVENT_RETURN, onReturn )
	

	local function handleEditBoxGainFocus(self, event)
		self._cursorPos = #self._internalText + 1
		self:_addCursor()
		focusedEdit = self
		MOAIKeyboardAndroid.showKeyboard ()
		return self:_baseHandleGainFocus(event)
	end

	self.userLabel = self.g:createLabel()
	self.userLabel:setPos(5, 20)
	self.userLabel:setDim(30, 5)
	self.userLabel:setText("Username:")

	self.userEdit = self.g:createEditBox()
	self.userEdit:setPos(35, 20)
	self.userEdit:setDim(50, 5)
	self.userEdit._onHandleGainFocus = handleEditBoxGainFocus

	self.passLabel = self.g:createLabel()
	self.passLabel:setPos(5, 40)
	self.passLabel:setDim(30, 5)
	self.passLabel:setText("Password:")

	self.passEdit = self.g:createEditBox()
	self.passEdit:setPos(35, 40)
	self.passEdit:setDim(50, 5)
	self.passEdit:setPasswordChar('*')
	self.passEdit._onHandleGainFocus = handleEditBoxGainFocus
	
	self.button = self.g:createButton()
	self.button:setPos(35, 50)
	self.button:setDim(30, 10)
	self.button:setText("Go!")

	self.button:registerEventHandler(self.button.EVENT_BUTTON_CLICK, nil, buttonClick)

end

function Login:handleClickOrTouch(x, y, isMouseDown)
	self.g:injectMouseMove(x, y)
	if isMouseDown then
		self.g:injectMouseButtonDown(inputconstants.LEFT_MOUSE_BUTTON)
	else
		self.g:injectMouseButtonUp(inputconstants.LEFT_MOUSE_BUTTON)
	end
end

function Login:onFocus()

	-- Register the callbacks for input
	if MOAIInputMgr.device.pointer then
		MOAIInputMgr.device.mouseLeft:setCallback(
			function (isMouseDown)
				x,y = MOAIInputMgr.device.pointer:getLoc()
				self:handleClickOrTouch(x, y, isMouseDown)
			end
		)
	else
	-- If it isn't a mouse, its a touch screen... or some really weird device.
		MOAIInputMgr.device.touch:setCallback (
			function ( eventType, idx, x, y, tapCount )
				if (tapCount > 1) then
					-- nothing
				else
					local touchDown = eventType == MOAITouchSensor.TOUCH_DOWN
					self:handleClickOrTouch(x, y, touchDown)
				end
			end
		)
	end

end

return Login