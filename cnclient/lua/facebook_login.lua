
require 'statemgr'
require 'config'
require 'assetmgr'
require 'utils'
require 'connection'

Login = {}

function Login:login(access_token, guest_login)

	print('login start. guest = ' .. tostring(guest_login))

	local reponse = nil

	function saveCookie(task, status)
		if status >= 200 and status < 400 then
			local res = MOAIJsonParser.decode(task:getString())
			print(task:getString())
			if res['status'] == 'OK' then
				cookie = task:getResponseHeader('Set-Cookie')
				Env.cookie = cookie
				storeCookie(cookie)
				print('login - Logged it as ' .. res['username'])
				Env.username = res['username']
				Env.user_profile = res['profile']
				Env.is_guest = guest_login
				response = 'LOGGED_IN'
				return 
			end
		end
		response = task:getString()
		return
	end

	local task = MOAIHttpTask.new()

	if guest_login then
		task:setUrl(SERVER_ADDRESS .. '/login/guest/')
	else
		task:setBody('access_token=' .. access_token)
		task:setUrl(SERVER_ADDRESS .. '/login/fb/?connect_facebook=1')
	end
	task:setVerb(MOAIHttpTask.HTTP_POST)
	task:setVerbose(DEBUG)
	task:setCallback(saveCookie)
	task:performSync()

	print('login complete')
	
	task = nil
	collectgarbage()
	
	return response
	
end

function Login:testCookie()
	
	local response = nil
	
	function callback(task, status)
		response = status >= 200 and status < 400
		if status >= 200 and status < 400 then
			local res = MOAIJsonParser.decode(task:getString())
			
			if res['username'] then
				Env.username = res['username']
			end
			if res['is_guest'] then
				Env.is_guest = res['is_guest']
			end
		end
	end
	
	getWithCookie(SERVER_ADDRESS .. '/game/json/', callback)
	
	return response
end

function Login:onLoad()

	self.viewport, self.screenBottom = createViewport(Env.screenWidth, Env.screenHeight)
	
	self.layer = MOAILayer2D.new ()
	self.layer:setViewport ( self.viewport )
	
	self.layerTable = {{self.layer}}
	
	self.assets = AssetMgr.load('assets.csv', 'login', self.screenBottom)
	self.assets['fb_button']['prop']:setClickFunction(Login.fbButtonClick, Login)
	self.assets['fb_button']['prop'].enabled = true
	self.assets['guest_button']['prop']:setClickFunction(Login.guestButtonClick, Login)
	self.assets['guest_button']['prop'].enabled = true
	self.buttons = {self.assets['fb_button']['prop'], self.assets['guest_button']['prop']}
	AssetMgr.addPropsToLayer(self.layer, {'backgroud', 'fb_button', 'guest_button'}, self.assets)
	
	playMusic()
	
end

function Login:fbButtonClick()
	
	local FB = MOAIFacebookAndroid or MOAIFacebookIOS
	
	if FB == nil and DEBUG then
		login_with_password('kalugny', 'y1u1v')
		statemgr.swap(CODE_PATH .. 'menu.lua')
		return
	end
	
	FB.init(FACEBOOK_APP_ID)
	
	function loginSuccess()
		local token = FB.getToken()
		print('token = ' .. tostring(token))
		
		local login_response = self:login(token) 
		if login_response == 'LOGGED_IN' then
			--MOAICrittercismAndroid.setUser(Env['username'])
			if Env.user_profile['nation'] == 'None' then
				statemgr.swap(CODE_PATH .. 'choosenation.lua')
			else
				statemgr.swap(CODE_PATH .. 'menu.lua')
			end
			return
		end
		
		print(login_response)
		
	end
	
	function loginFail()
		print('FB login failed!')
	end
	
	FB.setListener(FB.SESSION_DID_LOGIN, loginSuccess)
	FB.setListener(FB.SESSION_DID_NOT_LOGIN, loginFail)
	FB.login({'email'})
	
end

function Login:guestButtonClick()
	
	local login_response = self:login(nil, true) 
	if login_response == 'LOGGED_IN' then
		--MOAICrittercismAndroid.setUser(Env['username'])
		statemgr.swap(CODE_PATH .. 'choosenation.lua')
		return
	end
	
	print(login_response)
	
end

function Login:handleClickOrTouch(x, y, eventType)
	
	local x, y = self.layer:wndToWorld(x,y)

	for i, btn in ipairs(self.buttons) do
		btn:input(x, y, eventType)
	end
end

function Login:onFocus()

	-- Register the callbacks for input
	if MOAIInputMgr.device.pointer then
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

	local cookieWorks = self:testCookie()
	if cookieWorks then
		--MOAICrittercismAndroid.setUser(Env['username'])
		statemgr.swap(CODE_PATH .. 'menu.lua')
	end
	
	playSound('Welcome.ogg')
end

return Login