require 'config'

function storeCookie(cookie)
	local path = 'cookiejar'
	if MOAIEnvironment.documentDirectory then
		path = MOAIEnvironment.documentDirectory .. DIR_SEP .. path
	end
	local cookiejar = io.open(path, 'w')
	cookiejar:write(cookie)
	cookiejar:close()
end

function loadCookie()
	local path = 'cookiejar'
	if MOAIEnvironment.documentDirectory then
		path = MOAIEnvironment.documentDirectory .. DIR_SEP .. path
	end
	local cookiejar = io.open(path, 'r')
	if not cookiejar then
		return
	end
	local cookie = cookiejar:read()
	cookiejar:close()
	return cookie
end
  
function getWithCookie(url, callback, async)

	if not Env.cookie then
		Env.cookie = loadCookie()
		if not Env.cookie then
			return
		end
	end

	local task = MOAIHttpTask.new()
	task:setUrl(url)
	task:setVerb(MOAIHttpTask.HTTP_GET)
	task:setVerbose(DEBUG)
	task:setCallback(callback)
	task:setHeader('Cookie', Env.cookie)
	if async then
		task:performAsync()
	else
		task:performSync()
	end

	task = nil
	collectgarbage()

end

function login_with_password(username, password)

	print('login start')

	local cookie = nil

	function saveCookie(task, status)
		print(task:getResponseHeader('Location'), status)
		if status >= 200 and status < 400 then
			cookie = task:getResponseHeader('Set-Cookie')
			Env.cookie = cookie
			storeCookie(cookie)
			print('login - Logged it as ' .. username)
			Env.username = username
			Env.is_guest = false
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

function logout()

	print('logout start')

	local reponse = nil

	function deleteCookie(task, status)
		if status >= 200 and status < 400 then
			Env.cookie = nil
			storeCookie('') 			-- effectively deleting the old cookie
			Env.username = nil
			response = 'LOGGED_OUT'
			return 
		end
		response = {status, task:getString()}
	end

	local task = MOAIHttpTask.new()

	task:setUrl(SERVER_ADDRESS .. '/logout/')
	task:setVerb(MOAIHttpTask.HTTP_GET)
	task:setVerbose(DEBUG)
	task:setCallback(deleteCookie)
	task:performSync()

	if MOAIFacebookAndroid then
		MOAIFacebookAndroid.logout()
	end
	print('logout complete')
	
	task = nil
	collectgarbage()
	
	return response
	
end

function startNewGame(opponent)
	
	local game_id = nil
	
	function callback(task, status)
		if status == 302 then
			local newUrl = task:getResponseHeader('Location')
			game_id = newUrl:match('(%d+)/?$') -- hope this won't fuck me up. Gotta be a better way to return the id
		end
	end
	
	if opponent then
		getWithCookie(SERVER_ADDRESS .. '/game/new/?opponent=' .. opponent, callback)
	else
		getWithCookie(SERVER_ADDRESS .. '/game/new/', callback)
	end		
	
	return game_id
	
end

function profilePicPathToFilename(picturePath)
	return picturePath:gsub('/', '_')
end

function loadProfilePictureIntoProp(picture, prop, attrs)

	local tex = MOAITexture.new()
	tex:load(picture, MOAITexture.TRUECOLOR)
	
	local width, height = tex:getSize()
	local aspectRatio = width / height
	local isPortrait = height > width
	
	local cellWidth = tonumber(attrs['Width'])
	local cellHeight = tonumber(attrs['Height'])
	
	if isPortrait then
		cellWidth = cellHeight * aspectRatio
	else
		cellHeight = cellWidth / aspectRatio
	end
	
	local gfx = MOAIGfxQuad2D.new()
	gfx:setTexture(tex)
	gfx:setRect(0, 0, cellWidth, cellHeight)
	prop:setDeck(gfx)
	prop:setPiv(cellWidth / 2, cellHeight / 2)
	prop:setLoc(tonumber(attrs['X']), tonumber(attrs['Y']))
end

function setProfilePic(path, pictureProp, attrs)

	local localPath = profilePicPathToFilename(path)
	if MOAIEnvironment.documentDirectory then
		localPath = MOAIEnvironment.documentDirectory .. DIR_SEP .. localPath
	end

	function callback(task, status)
		if status == 200 then
			local pictureData = task:getString()	
			
			local pictureFile = io.open(localPath, 'wb')
			pictureFile:write(pictureData)
			pictureFile:close()
			
			loadProfilePictureIntoProp(localPath, pictureProp, attrs)
			
		end
	end
	
	if fileExists(localPath) then
		loadProfilePictureIntoProp(localPath, pictureProp, attrs)
		return
	end
	
	local task = MOAIHttpTask.new()
	task:setUrl(SERVER_ADDRESS .. path)
	task:setVerb(MOAIHttpTask.HTTP_GET)
	task:setVerbose(DEBUG)
	task:setCallback(callback)
	task:performAsync()

end

function setNation(nation)

	local response = nil

	function callback(task, status)
		if status == 200 then
			response = 'OK'
		end
	end

	getWithCookie(SERVER_ADDRESS .. '/game/nation/' .. nation .. '/', callback)
	
	return response

end

function getTimelineData()

	local response = nil

	function callback(task, status)
		if status == 200 then
			response = MOAIJsonParser.decode(task:getString())
		end
	end

	getWithCookie(SERVER_ADDRESS .. '/game/timeline/', callback)
	
	return response
	
end