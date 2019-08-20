--------------------------------------------------------------------------------------
---- INCLUDES ------------------------------------------------------------------------
--------------------------------------------------------------------------------------

require 'c0_chess'
require 'utils'
require 'config'
require 'connection'
require 'osf'

--------------------------------------------------------------------------------------
---- COSTS ---------------------------------------------------------------------------
--------------------------------------------------------------------------------------

SUBMIT_ENABLED = true

GRID_SIZE = 64

ERROR_MARGIN = 3 -- number of px that are the error of movement

local PIECE_TILES = {}
PIECE_TILES['wp'] = 12
PIECE_TILES['wR'] = 9
PIECE_TILES['wN'] = 8
PIECE_TILES['wB'] = 7
PIECE_TILES['wQ'] = 11
PIECE_TILES['wK'] = 10
PIECE_TILES['bp'] = 2
PIECE_TILES['bR'] = 3
PIECE_TILES['bN'] = 1
PIECE_TILES['bB'] = 5
PIECE_TILES['bQ'] = 6
PIECE_TILES['bK'] = 4

local PORTRAITS = {}
PORTRAITS['rp'] = 7
PORTRAITS['rR'] = 12
PORTRAITS['rN'] = 10
PORTRAITS['rB'] = 11
PORTRAITS['rQ'] = 8
PORTRAITS['rK'] = 9
PORTRAITS['lp'] = 3
PORTRAITS['lR'] = 4
PORTRAITS['lN'] = 6
PORTRAITS['lB'] = 5
PORTRAITS['lQ'] = 2
PORTRAITS['lK'] = 1

local PIECE_NAMES = {}
PIECE_NAMES['p'] = 'PAWN'
PIECE_NAMES['R'] = 'ROOK'
PIECE_NAMES['N'] = 'KNIGHT'
PIECE_NAMES['B'] = 'BISHOP'
PIECE_NAMES['Q'] = 'QUEEN'
PIECE_NAMES['K'] = 'KING'

PIECE_SPEED = 250 -- In pixels per second

--------------------------------------------------------------------------------------
---- UTILITY FUCTIONS ----------------------------------------------------------------
--------------------------------------------------------------------------------------

local function print_board()
	for v = 1, 8, 1 do
		for h = 1, 8, 1 do
			pc = c0_LuaChess.c0_D_what_at( c0_LuaChess.c0_convE2( v, h ) );
			if #pc == 0 then
				pc = '__'
			end
			printf(pc)
		end
		print(' ')
	end
end

local function get_board_from_fen(fen)
	-- it's just everything up to the first space
	return fen:sub(0, fen:find(' ') - 1)

end

--------------------------------------------------------------------------------------
---- Game ----------------------------------------------------------------------------
--------------------------------------------------------------------------------------

----- Progress Bar -------------------------------------------------------------------
local function addProgressBar(layer, x, y, progress, max_progress)
	local progressbar = {}
	
	progressbar.backgroudGfx = MOAIGfxQuad2D.new()
	progressbar.backgroudGfx:setTexture(IMAGE_PATH .. 'progress bar_base.png', MOAITexture.TRUECOLOR)
	progressbar.backgroudGfx:setRect(0, 0, 230, 42)
	
	progressbar.background = MOAIProp2D.new()
	progressbar.background:setDeck(progressbar.backgroudGfx)
	progressbar.background:setLoc(x, y)
	layer:insertProp(progressbar.background)
		
	progressbar.liquidGfx = MOAIGfxQuad2D.new()
	progressbar.liquidGfx:setTexture(IMAGE_PATH .. 'progress bar_liquid.png', MOAITexture.TRUECOLOR)
	progressbar.liquidGfx:setRect(0, 0, 230, 42)
	
	progressbar.liquid = MOAIProp2D.new()
	progressbar.liquid:setDeck(progressbar.liquidGfx)
	progressbar.liquid:setPiv(53, 21)
	progressbar.liquid:setLoc(x + 53, y + 21)
	progressbar.liquid:setScl(0, 1)
	layer:insertProp(progressbar.liquid)
		
	progressbar.coverGfx = MOAIGfxQuad2D.new()
	progressbar.coverGfx:setTexture(IMAGE_PATH .. 'progress bar_holder.png', MOAITexture.TRUECOLOR)
	progressbar.coverGfx:setRect(0, 0, 230, 42)
	
	progressbar.cover = MOAIProp2D.new()
	progressbar.cover:setDeck(progressbar.coverGfx)
	progressbar.cover:setLoc(x, y)
	layer:insertProp(progressbar.cover)
	
	progressbar.max_progress = max_progress
	progressbar.progress = progress
	
	progressbar.setProgress = function(progressbar, progress)
		progressbar.liquid:seekScl(progress / progressbar.max_progress, 1, 0.5)
		progressbar.progress = progress
	end
	
	progressbar.addPoints = function(progressbar, points)
		local newProgress = progressbar.progress + points
		if newProgress >= progressbar.max_progress then
			newProgress = 0
			statemgr.push(CODE_PATH .. 'levelup.lua')
		end
		progressbar:setProgress(newProgress)
	end

	return progressbar
end
--------------------------------------------------------------------------------------

Game = {}

function Game:init(screenWidth, screenHeight, nation)

	print('Game:init start')
	
	math.randomseed(os.time())
	
	self:reset()
	
	self.nation = nation
	
	self.viewport, self.screenBottom = createViewport(screenWidth, screenHeight)
	print('Screen bottom = ' .. self.screenBottom)
	
	self.layer = MOAILayer2D.new ()
	self.layer:setViewport ( self.viewport )
	self.layerTable = {{self.layer}}

	-- a font we'll use later
	CHARCODES = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?()&/-'
	self.font = MOAIFont.new()
	self.font:loadFromTTF (IMAGE_PATH .. 'fonts' .. DIR_SEP .. 'MyriadPro-Semibold.otf', CHARCODES, 7.5, 163 )
	
	self.grid = MOAIGrid.new()
	self.grid:initRectGrid(8, 8, GRID_SIZE, GRID_SIZE)

	for i = 1, 8 do
		for j = 1, 8 do
			self.grid:setTile(i, j, (i + j + 1) % 2 + 1)
		end
	end
	
	local age = 'age' .. Env.player['age']['number']
	
	-- backgroud image
	self.backgroud_image_gfx = MOAIGfxQuad2D.new()
	self.backgroud_image_gfx:setTexture(IMAGE_PATH .. 'tables' .. DIR_SEP .. age .. '.png', MOAITexture.TRUECOLOR)
	self.backgroud_image_gfx:setRect(0, 0, 1280, 800)
	self.backgroud_image = MOAIProp2D.new()
	self.backgroud_image:setDeck(self.backgroud_image_gfx)
	self.backgroud_image:setPiv(640, 400)
	self.layer:insertProp(self.backgroud_image)

	-- chess pieces
	self.piece_tiles = MOAITileDeck2D.new()
	self.piece_tiles:setTexture(IMAGE_PATH .. 'sets' .. DIR_SEP .. age .. '.png', MOAITexture.TRUECOLOR)
	self.piece_tiles:setSize(12, 1)
	self.piece_tiles:setRect(-32, -32, 32, 32)

	-- piece portraits
	self.portraits = {}
	self.portraits[nation] = MOAITileDeck2D.new()
	self.portraits[nation]:setTexture(IMAGE_PATH .. 'portraits' .. DIR_SEP .. nation .. DIR_SEP .. age .. '.png', MOAITexture.TRUECOLOR)
	self.portraits[nation]:setSize(3, 4)
	self.portraits[nation]:setRect(0, 0, 370, 380)
	
	self.portrait_left = MOAIProp2D.new()
	self.portrait_left:setIndex(1)
	self.portrait_left:setLoc(-640, self.screenBottom)
	self.portrait_left:setVisible(false)
	self.layer:insertProp(self.portrait_left)

	self.portrait_right = MOAIProp2D.new()
	self.portrait_right:setDeck(self.portraits[nation])
	self.portrait_right:setIndex(9)
	self.portrait_right:setLoc(640 - 370, self.screenBottom)
	self.portrait_right:setVisible(false)
	self.layer:insertProp(self.portrait_right)
	
	-- portrait name holder
	self.nameholderGfx = MOAIGfxQuad2D.new()
	self.nameholderGfx:setTexture(IMAGE_PATH .. 'character_name holder.png', MOAITexture.TRUECOLOR)
	self.nameholderGfx:setRect(0, 0, 240, 67)
	
	self.nameholderLeft = MOAIProp2D.new()
	self.nameholderLeft:setDeck(self.nameholderGfx)
	self.nameholderLeft:setLoc(-600, self.screenBottom)
	
	self.nameholderTextboxLeft = addTextbox('', 240, 67, nil, self.font)
	self.nameholderTextboxLeft:setTextSize(14, 163)
	self.nameholderTextboxLeft:setColor(0.25, 0.25, 0.25, 1)
	self.nameholderTextboxLeft:setParent(self.nameholderLeft)
	self.nameholderTextboxLeft:setLoc(120, 75)
	
	self.layer:insertProp(self.nameholderLeft)
	self.layer:insertProp(self.nameholderTextboxLeft)
	
	self.nameholderRight = MOAIProp2D.new()
	self.nameholderRight:setDeck(self.nameholderGfx)
	self.nameholderRight:setLoc(600 - 240, self.screenBottom)
	
	self.nameholderTextboxRight = addTextbox('', 240, 67, nil, self.font)
	self.nameholderTextboxRight:setTextSize(14, 163)
	self.nameholderTextboxRight:setColor(0.25, 0.25, 0.25, 1)
	self.nameholderTextboxRight:setParent(self.nameholderRight)
	self.nameholderTextboxRight:setLoc(120, 75)
	
	self.layer:insertProp(self.nameholderRight)
	self.layer:insertProp(self.nameholderTextboxRight)

	-- board bg
	self.board_bg_gfx = MOAIGfxQuad2D.new()
	self.board_bg_gfx:setTexture(IMAGE_PATH .. 'board.png', MOAITexture.TRUECOLOR)
	self.board_bg_gfx:setRect(0, 0, 570, 567)
	self.board_bg = MOAIProp2D.new()
	self.board_bg:setDeck(self.board_bg_gfx)
	self.board_bg:setPiv(285, 285)
	self.layer:insertProp(self.board_bg)
	
	
	-- board tiles and board
	self.board_tiles = MOAITileDeck2D.new()
	self.board_tiles:setTexture( IMAGE_PATH .. "tiles.png", MOAITexture.TRUECOLOR )
	self.board_tiles:setSize(4, 1)

	self.board = MOAIProp2D.new()
	self.board:setDeck(self.board_tiles)
	self.board:setGrid(self.grid)
	local w, h = self.board:getDims() -- why is the height negative?
	self.board:setPiv(w / 2, -h / 2) 
	self.layer:insertProp(self.board)
	
	-- Buttons below the screen
	self.buttons = {}
	
	self.bragBtn = addButton('brag button_idle.png', 'brag button_pressed.png', 95, 43, 
		function() 
			print 'Brag clicked' 
		end
	)
	self.bragBtn:setLoc(310 - 95, -340)
	self.layer:insertProp(self.bragBtn)
	table.insert(self.buttons, self.bragBtn)

	self.submitBtn = addButton('submit button_idle.png', 'submit button_pressed.png', 83, 42, 
		function() 
			self.waiting_for_submit = false
			self.submitBtn:disable()
			self.undoBtn:disable()
			table.insert(self.movesQueue, 'submit')
		end)
	self.submitBtn:setLoc(310 - 95 - 10 - 83, -340)
	self.submitBtn:disable()
	self.layer:insertProp(self.submitBtn)
	table.insert(self.buttons, self.submitBtn)

	self.hintBtn = addButton('hint button_idle.png', 'hint button_pressed.png', 79, 41, function() print 'Hint clicked' end)
	self.hintBtn:setLoc(310 - 95 - 10 - 83 - 10 - 79, -340)
	self.layer:insertProp(self.hintBtn)
	table.insert(self.buttons, self.hintBtn)

	self.undoBtn = addButton('undo button_idle.png', 'undo button_pressed.png', 95, 43, 
		function() 
			self.waiting_for_submit = false
			self.submitBtn:disable()
			self.undoBtn:disable()
			table.insert(self.movesQueue, 'undo')
		end)
	self.undoBtn:setLoc(-310, -340)
	self.undoBtn:disable()
	self.layer:insertProp(self.undoBtn)
	table.insert(self.buttons, self.undoBtn)
	
	-- the mini progress bar
	self.progressBar = addProgressBar(self.layer, -310 + 95 + 10, -340, 0, 100)
	
	-- clock widgets
	self.clockPlaceholderGfx = MOAIGfxQuad2D.new()
	self.clockPlaceholderGfx:setTexture(IMAGE_PATH .. "dropdown timer_holder.png", MOAITexture.TRUECOLOR )
	self.clockPlaceholderGfx:setRect(0, 0, 215, 96)
	
	self.clockPlaceholderLeft = MOAIProp2D.new()
	self.clockPlaceholderLeft:setDeck(self.clockPlaceholderGfx)
	self.clockPlaceholderLeft:setLoc(-600, 210)
	
	self.clockLeft = addTextbox('', 215, 96, nil, self.font)
	self.clockLeft:setTextSize(14, 163)
	self.clockLeft:setColor(0.25, 0.25, 0.25, 1)
	self.clockLeft:setParent(self.clockPlaceholderLeft)
	self.clockLeft:setLoc(100, 130)
	
	self.layer:insertProp(self.clockPlaceholderLeft)
	self.layer:insertProp(self.clockLeft)
	
	self.clockPlaceholderRight = MOAIProp2D.new()
	self.clockPlaceholderRight:setDeck(self.clockPlaceholderGfx)
	self.clockPlaceholderRight:setLoc(600 - 215, 210)
	
	self.clockRight = addTextbox('', 215, 96, nil, self.font)
	self.clockRight:setTextSize(14, 163)
	self.clockRight:setColor(0.25, 0.25, 0.25, 1)
	self.clockRight:setParent(self.clockPlaceholderRight)
	self.clockRight:setLoc(100, 130)
	
	self.layer:insertProp(self.clockPlaceholderRight)
	self.layer:insertProp(self.clockRight)
	-- the app's menu bar
	self.menuBar = addMenuBar(self.layer, true)
	
	OSFManager:init(self.bottom)
	
	self.loadingText = addTextbox("Loading...", 444, 110, nil, self.font)
	self.loadingText:setLoc(0, 64)
	self.layer:insertProp(self.loadingText)
	self.loaded = false
	
	print('Game:init complete')
end

function Game:reset()
	self.currentBoard = nil
	self.pieces = nil
	self.pieceSpeed = PIECE_SPEED * 3
	self.movesQueue = {}
	
	self.game_is_finished = false
	self.running = true
end

function Game:updateClocks(my_clock, opponent_clock)
	self.clockRight:setString(string.format('%2d:%02d', my_clock / 60, my_clock % 60))
	if opponent_clock then
		self.clockLeft:setString(string.format('%2d:%02d', opponent_clock / 60, opponent_clock % 60))
	end
end

function Game:highlightTile(x, y, color)
	if color == nil then
		color = 4
	end
	self.grid:setTile(x, y, color)
end

function Game:dehighlightTile(x, y)
	self.grid:setTile(x, y, (x + y + 1) % 2 + 1)
end

function Game:unselectTiles(keep_portrait)
	if self.selectedTile then
		self:dehighlightTile(unpack(self.selectedTile))
	end
	self.selectedTile = nil
	
	if not keep_portrait then
		self.portrait_right:setVisible(false)
		self.nameholderRight:setVisible(false)
		self.nameholderTextboxRight:setVisible(false)
	end
end

function Game:setPortrait(side, piece)

	local pieceNoColor = piece[2]
	if side == 'r' then
		self.portrait_right:setIndex(PORTRAITS['r' .. pieceNoColor])
		self.portrait_right:setVisible(true)
		self.nameholderRight:setVisible(true)
		self.nameholderTextboxRight:setVisible(true)
		self.nameholderTextboxRight:setString(PIECE_NAMES[pieceNoColor])
	else
		self.portrait_left:setIndex(PORTRAITS['l' .. pieceNoColor])
		self.portrait_left:setVisible(true)
		self.nameholderTextboxLeft:setString(PIECE_NAMES[pieceNoColor])
	end

end

function Game:selectTile(i, j, piece)

	self:unselectTiles()

	self.selectedTile = {i, j}
	self:highlightTile(i, j, 3)
	
	self:setPortrait('r', piece)
	
end

function Game:coordToC0(i, j)
	return c0_LuaChess.c0_convE2( self:switchIfBlack(i, j) )
end

function Game:findPiece(fromX, fromY, piece)
	local fromXWorld, fromYWorld = self.grid:getTileLoc(fromX, fromY)
	
	if piece == nil then
		piece = c0_LuaChess.c0_D_what_at( self:coordToC0(fromX, fromY) ) 
	end

	for i, p in pairs(self.pieces) do
		local x, y = p:getLoc()
		if x > fromXWorld - ERROR_MARGIN and x < fromXWorld + ERROR_MARGIN and y > fromYWorld - ERROR_MARGIN and y < fromYWorld + ERROR_MARGIN then
			-- This might be our piece
			if PIECE_TILES[piece] == p:getIndex() then
				return p, i
			end
		end
	end
	return nil
end

function Game:movePieceGraphically(fromX, fromY, toX, toY, opponents_move)
	local fromXWorld, fromYWorld = self.grid:getTileLoc(fromX, fromY)
	local toXWorld, toYWorld = self.grid:getTileLoc(toX, toY)
	
	local movingPiece = self:findPiece(fromX, fromY)
	if movingPiece == nil then
		print('ERROR: Did not find piece')
		return
	end
	
	local xDelta, yDelta = toXWorld - fromXWorld, toYWorld - fromYWorld
	local distance = math.sqrt(math.pow(xDelta, 2) + math.pow(yDelta, 2))
	wait(movingPiece:moveLoc(xDelta, yDelta, distance / self.pieceSpeed, MOAIEaseType.SOFT_SMOOTH))
	playSound('piece_move.ogg')
	self:eatPieceGraphically(toX, toY)
	
end

function Game:eatPieceGraphically(x, y)
	local pieceAtCoords = c0_LuaChess.c0_D_what_at( self:coordToC0(x, y) ) 
	if #pieceAtCoords ~= 0 then
		-- we are eating an enemy piece
		print('eating ' .. pieceAtCoords)
		local enemyPiece, enemyIndex = self:findPiece(x, y, pieceAtCoords)
		self.layer:removeProp(enemyPiece)
		table.remove(self.pieces, enemyIndex)
	end
end
	
function Game:promoteGraphically(x, y, piece, promotion)

	playSound('Promotion.ogg')

	local pieceProp = self:findPiece(x, y, piece)
	
	self.layer:removeProp(pieceProp)
	local promotedPiece = self:createPiece(promotion)
	promotedPiece:setParent(self.board)
	x, y = self.grid:getTileLoc(x, y)
	promotedPiece:setLoc(x, y)
	table.insert(self.pieces, promotedPiece)

end
	
function Game:movePiece(fromX, fromY, toX, toY, dont_transmit_move, hide_move, hide_points, dont_switch)

	local opponents_move = not self.is_my_turn

	local thisPiece = c0_LuaChess.c0_D_what_at(self:coordToC0(fromX, fromY))
	local portraitSide = 'r'
	if opponents_move then
		portraitSide = 'l'
	end
	self:setPortrait(portraitSide, thisPiece) 
	
	local success = false
	local awards = {}
	self.currentMove = {fromX, fromY, toX, toY}
	if self.is_my_turn then
		self:unselectTiles(true)
		if not dont_transmit_move then
			success, awards = self:sendMove(fromX, fromY, toX, toY)
			if not success then
				return
			end
		end
	end

	if not hide_move then
		self:movePieceGraphically(fromX, fromY, toX, toY, opponents_move)
		
		-- if the king moved two or three spots horizontally, this must mean we are castling.
		-- let's move the rook
		if thisPiece[2] == 'K' and math.abs(toX - fromX) == 2 then
			self:castling(toX, toY, opponents_move)
		end
	elseif not dont_transmit_move or (SUBMIT_ENABLED and dont_switch) then
		-- This means that it's a move the player made now, but using drag and drop
		-- TODO: Refactor all of this so as to be less confusing
		self:eatPieceGraphically(toX, toY)
	end
	
	if not hide_points then
		self:postAwards(awards)
	end
	
	print('Before move: ' .. get_board_from_fen(c0_LuaChess.c0_get_FEN()))
	c0_LuaChess.c0_move_to(self:coordToC0(fromX, fromY), self:coordToC0(toX, toY))

	if c0_LuaChess.c0_D_is_mate_to_king('w') or c0_LuaChess.c0_D_is_mate_to_king('b') then
		self.game_is_finished = true
		self.running = false
		OSFManager:show(self.layer, 'checkmate')
		if self.is_my_turn then
			OSFManager:show(self.layer, 'victory')
		else
			OSFManager:show(self.layer, 'defeat')
		end
		
		return
	elseif (c0_LuaChess.c0_D_is_check_to_king('w') or c0_LuaChess.c0_D_is_check_to_king('b')) and not hide_move then
		OSFManager:show(self.layer, 'check')
	end
	if c0_LuaChess.c0_become ~= '' and c0_LuaChess.c0_become ~= '0' and (not hide_move or not dont_transmit_move or (SUBMIT_ENABLED and dont_switch)) then
		-- There was a promotion
		local promotedPiece = thisPiece[1] .. c0_LuaChess.c0_become
		self:promoteGraphically(toX, toY, thisPiece, promotedPiece)
	end
	
	self.currentBoard = get_board_from_fen(c0_LuaChess.c0_get_FEN())
	print('After move: ' .. self.currentBoard)
	if not dont_switch then
		self.is_my_turn = not self.is_my_turn
		if self.is_my_turn and not hide_move then
			OSFManager:show(self.layer, 'your_move')
		end
	else
		self.waiting_for_submit = true
	end
	print('my turn: ' .. tostring(self.is_my_turn))
	

	
end

function Game:undoLastMove()
		
	c0_LuaChess.c0_take_back()
	self:createPieces()
	
end

function Game:submitMove()
	local success = false
	local awards = {}
	success, awards = self:sendMove(unpack(self.currentMove))
	if not success then
		self:undoLastMove()
	else
		self:postAwards(awards)
		self.is_my_turn = false
	end
	

	
end
	
function Game:handleClickOrTouch(x, y, eventType)
	
	x, y = self.layer:wndToWorld(x, y)
	
	if self.playback then
		return
	end
	
	for i, btn in ipairs(self.buttons) do 
		btn:input(x, y, eventType)
	end
	
	for i, btn in ipairs(self.menuBar.buttons) do
		btn:input(x, y, eventType)
	end
	
	local i, j = self.grid:locToCoord(self.board:worldToModel(x, y))
	if i < 1 or j < 1 or i > 8 or j > 8 then
		return
	end
	local pieceAtCoords = c0_LuaChess.c0_D_what_at( self:coordToC0(i, j) ) 
	
	if eventType == MOAITouchSensor.TOUCH_DOWN or eventType == 'MouseDown' then
		print('Game:handleClickOrTouch - clicked on ' .. tostring(i) .. ', ' .. tostring(j) .. ': ' .. pieceAtCoords)
		if #pieceAtCoords ~= 0 and pieceAtCoords:startswith(self:myColor()) then
			self:selectTile(i, j, pieceAtCoords)
		elseif self.is_my_turn and self.selectedTile and not self.waiting_for_submit and not self.game_is_finished  then
			if c0_LuaChess.c0_D_can_be_moved(self:coordToC0(self.selectedTile[1], self.selectedTile[2]), self:coordToC0(i, j)) then
				print('Moving from ' .. self.selectedTile[1] .. ', ' .. self.selectedTile[2] .. ' to ' .. i .. ', ' .. j)
				table.insert(self.movesQueue, {self.selectedTile[1], self.selectedTile[2], i, j, SUBMIT_ENABLED, false, false, true})
				if SUBMIT_ENABLED then
					self.submitBtn:enable()
					self.undoBtn:enable()
				end
			else
				self:unselectTiles()
			end
		else
			self:unselectTiles()
		end
	elseif eventType == MOAITouchSensor.TOUCH_MOVE and self.selectedTile and self.is_my_turn and not self.waiting_for_submit and not self.game_is_finished then
		-- Drag the piece
		if not self.draggedPiece then
			self.draggedPiece = self:findPiece(unpack(self.selectedTile))
		end
		self.draggedPiece:setLoc(self.board:worldToModel(x, y))
		
		if c0_LuaChess.c0_D_can_be_moved(self:coordToC0(unpack(self.selectedTile)), self:coordToC0(i, j)) then
			if self.highlightedTile then
				self:dehighlightTile(unpack(self.highlightedTile))
			end
			self.highlightedTile = {i, j}
			self:highlightTile(i, j)
		else
			if self.highlightedTile then
				self:dehighlightTile(unpack(self.highlightedTile))
			end
		end
	elseif eventType == MOAITouchSensor.TOUCH_UP then
		if self.draggedPiece then
			if c0_LuaChess.c0_D_can_be_moved(self:coordToC0(self.selectedTile[1], self.selectedTile[2]), self:coordToC0(i, j)) and not self.waiting_for_submit and not self.game_is_finished then
				print('Moving from ' .. self.selectedTile[1] .. ', ' .. self.selectedTile[2] .. ' to ' .. i .. ', ' .. j)
				self.draggedPiece:setLoc(self.grid:getTileLoc(i, j))
				playSound('piece_move.ogg')
				self.draggedPiece = nil
				if self.highlightedTile then
					self:dehighlightTile(unpack(self.highlightedTile))
				end
				table.insert(self.movesQueue, {self.selectedTile[1], self.selectedTile[2], i, j, SUBMIT_ENABLED, true, false, true})
				if SUBMIT_ENABLED then
					self.submitBtn:enable()
					self.undoBtn:enable()
				end
			else
				self.draggedPiece:setLoc(self.grid:getTileLoc(unpack(self.selectedTile)))
				self.draggedPiece = nil
				if self.highlightedTile then
					self:dehighlightTile(unpack(self.highlightedTile))
				end
			end
		end
	end
			
	
end

function Game:animateText(text, x, y)
	local height = 40
	local width = 300
	local textBox = addTextbox(text, width, height, nil, self.font)
	textBox:setLoc(x, y + GRID_SIZE / 2)
	self.layer:insertProp(textBox)
	
	wait(textBox:moveLoc(0, 10, 0, 1))
	self.layer:removeProp(textBox)
end

function Game:postAwards(awards)

	for i, award in ipairs(awards) do
		local x, y = 0, 0
		if award['location'] ~= nil then
			x = string.byte(award['location'], 1) - 96
			y = tonumber(award['location'][2])
			y, x = self:switchIfBlack(x, y)
			x, y = self.board:modelToWorld(self.grid:getTileLoc(x, y))
		end
		print('<c:' .. award['points_color'] .. '>+' .. award['points'] ..'<c>\n<c:' .. award['text_color'] .. '>' .. award['name'] .. '<c>', x, y)
		self:animateText('<c:' .. award['points_color'] .. '>+' .. award['points'] ..'<c>\n<c:' .. award['text_color'] .. '>' .. award['name'] .. '<c>', x, y)
		self.progressBar:addPoints(award['points'])
	end

end

function Game:sendClockUpdate()
	print('Game:sendClockUpdate start')

	local success = false
	function parse(task, status)
		if (status == 200) then
			local state = MOAIJsonParser.decode(task:getString())
			if state['status'] == 'OK' then
				success = true
			end
		end		
	end
	
	getWithCookie(SERVER_ADDRESS .. '/game/' .. self.game_id .. '/clock/' .. tostring(math.ceil(self.time_remaining_start - self.time_remaining)) .. '/', parse)
	
	print('Game:sendClockUpdate complete')
	
	return success
end

function Game:sendMove(fromX, fromY, toX, toY)
	print('Game:sendMove start')

	local startpos = self:coordToC0(fromX, fromY)
	local endpos = self:coordToC0(toX, toY)

	local success = false
	local awards = nil
	function parse(task, status)
		if (status == 200) then
			local state = MOAIJsonParser.decode(task:getString())
			if state['status'] == 'Game ended' then
				print('Game ended!')
				success = true
			elseif state['status'] == 'OK' then
				print('Move ' .. startpos .. ' ' .. endpos .. ' registered on server.')
				success = true
				awards = state['awards']
			end
		end
		
	end
	
	getWithCookie(SERVER_ADDRESS .. '/game/' .. self.game_id .. '/move/?start=' .. startpos .. '&end=' .. endpos .. '&time_elapsed=' .. tostring(math.ceil(self.time_remaining_start - self.time_remaining)), parse)
	
	print('Game:sendMove complete')
	
	return success, awards
end

function Game:castling(kingsX, kingsY, opponents_move)

	kingsY, kingsX = self:switchIfBlack(kingsX, kingsY)

	-- how to compute the rook's position from the king's position?
	-- (7, 1) -> (8,1)-(6,1)
	-- (3, 1) -> (1,1)-(4,1)
	-- (7, 8) -> (8,8)-(6,8)
	-- (3, 8) -> (1,8)-(4,8)
	-- Therefore, y remains the same, and the following equations determine x
	local startX = 1.75 * kingsX - 4.25
	local endX = 0.5 * kingsX + 2.5
	
	print('Castling: ' .. startX .. ', ' .. kingsY .. ' to ' .. endX .. ', ' .. kingsY)
	
	adjustedStartY, adjustedStartX = self:switchIfBlack(startX, kingsY)
	adjustedEndY, adjustedEndX = self:switchIfBlack(endX, kingsY)
	
	playSound('Castling.ogg')
	
	self:movePieceGraphically(adjustedStartX, adjustedStartY, adjustedEndX, adjustedEndY, opponents_move)
end

function Game:indexOfLastMove()
	local i = #self.mlist - 3
	if self.mlist[i + 1] == '[' then
		-- The last move was a castling or a promotion
		i = i - 3
	end
	return i
end

function Game:queueOneMove(i, dont_transmit_move, hide_move)
	
	if #self.mlist < 4 then
		-- There are no valid moves.
		return
	end
	
	if i == nil then
		i = self:indexOfLastMove()
	end	
	print('all moves: ' .. self.mlist)
	print('moves remaining: ' .. string.sub(self.mlist, i, #self.mlist))
	
	local startX = string.byte(self.mlist, i) - 96
	local startY = tonumber(self.mlist[i + 1])
	local endX = string.byte(self.mlist, i + 2) - 96
	local endY = tonumber(self.mlist[i + 3])
	
	print('Moving ' .. startX .. ', ' .. startY .. ' to ' .. endX .. ', ' .. endY)
	
	adjustedStartY, adjustedStartX = self:switchIfBlack(startX, startY)
	adjustedEndY, adjustedEndX = self:switchIfBlack(endX, endY)
	
	table.insert(self.movesQueue, { adjustedStartX, adjustedStartY, adjustedEndX, adjustedEndY, dont_transmit_move, hide_move, hide_move })
	i = i + 4
	
	--take care of the special case of Castling
	if i < #self.mlist and self.mlist[i] == '[' then
		i = i + 3
	end
	
	return i
	
end

function Game:queueAllMovesButTheLast(show_moves)
	
	c0_LuaChess.c0_set_start_position("")
	
	self.is_my_turn = self.play_as_white
	
	local i = 1
	while i < self:indexOfLastMove()  do
		i = self:queueOneMove(i, true, not show_moves)
	end
	
end

function Game:getGameState(async)

	print('Game:getGameState start')
	
	function parse(task, status)
		
		self.lastConnectionToServer = os.time()
		
		if (status == 200) then
			print('Game:getGameState - got game state')
			local state = MOAIJsonParser.decode(task:getString())

			-- make sure this is a game by this player
			if state['white']['username'] == Env.username then
				self.opponents_username = state['black']['username']
			elseif state['black']['username'] == Env.username then
				self.opponents_username = state['white']['username']
			else
				print('This is not a game where ' .. Env.username .. ' is participating!')
				return
			end
			
			local state_board = get_board_from_fen(state['fen'])
			if state_board ~= self.currentBoard then
				-- something changed. 

				-- Note that the first time we get here (on the first focus, for example) currentBoard == nil so we get here anyway.
				-- This means that anything we do here should be stateless
				self.pgn = string.gsub(table.concat(state['moves'], ' '), '[\r\n]', '')
				self.mlist = c0_LuaChess.c0_get_moves_from_PGN(self.pgn)

				local player_state = state['white']
				local enemy_state = state['black']
				if not self.play_as_white then
					player_state = state['black']
					enemy_state = state['white']
				end

				if self.currentBoard then
					-- This is not the first time we're running this, so let's only update
					self:queueOneMove()
				else
					self.play_as_white = state['white']['username'] == Env.username
					self.nameholderTextboxLeft:setString(self.opponents_username)
					self.nameholderTextboxRight:setString(Env.username)
					self.loaded = true
				end
				self.currentBoard = state_board
				
				local enemy_nation = enemy_state['nation']
				local enemy_age = 'age' .. enemy_state['age']['number']
				
				if enemy_nation == 'None' then
					enemy_nation = 'Rome'
				end
				
				if not self.portraits[enemy_nation] then
					self.portraits[enemy_nation] = MOAITileDeck2D.new()
					self.portraits[enemy_nation]:setTexture(IMAGE_PATH .. 'portraits' .. DIR_SEP .. enemy_nation .. '_' .. enemy_age .. '.png', MOAITexture.TRUECOLOR)
					self.portraits[enemy_nation]:setSize(3, 4)
					self.portraits[enemy_nation]:setRect(0, 0, 370, 380)
				end
				self.portrait_left:setDeck(self.portraits[enemy_nation])
				self.portrait_left:setIndex(1)
				self.portrait_right:setVisible(true)
				self.portrait_left:setVisible(true)
				
				self.time_remaining = state['white_clock']
				local opponent_clock = state['black_clock']
				if not self.play_as_white then
					self.time_remaining = state['black_clock']
					opponent_clock = state['white_clock']
				end
				self.time_remaining_start = self.time_remaining
				self:updateClocks(self.time_remaining, opponent_clock)

				local levelPoints = tonumber(player_state['level']['points'])
				self.progressBar.max_progress = tonumber(player_state['level']['next_level_points']) - levelPoints
				self.progressBar:setProgress(tonumber(player_state['progress_points']) - levelPoints)
				
			end
		end
	end
	
	getWithCookie(SERVER_ADDRESS .. '/game/' .. self.game_id .. '/status/', parse, async)
	
	print('Game:getGameState complete')

end	

function Game:createPiece(pc)
	local piece = MOAIProp2D.new()
	piece:setDeck(self.piece_tiles)
	piece:setIndex(PIECE_TILES[pc])
	self.layer:insertProp(piece)
	return piece
end

function Game:switchIfBlack(h, v)
	if not self.play_as_white then
		v = 9 - v
		h = 9 - h
	end
	return v, h
end

function Game:myColor()
	if self.play_as_white then
		return 'w'
	end
	return 'b'
end

function Game:createPieces()
	
	print('Game:createPieces start')

	if self.pieces then
		for i, p in pairs(self.pieces) do
			self.layer:removeProp(p)
		end
	end
	self.pieces = {}

	for v = 1, 8, 1 do
		for h = 1, 8, 1 do
			pc = c0_LuaChess.c0_D_what_at(self:coordToC0(h, v))
			if #pc ~= 0 then
			
				local x, y = self.grid:getTileLoc(h, v)
				piece = self:createPiece(pc)
				piece:setParent(self.board)
				piece:setLoc(x, y)
				table.insert(self.pieces, piece)
			end
		end
	end
	
	print('Game:createPieces complete')
end

function Game:executeMove()
	local nextMove = table.remove(self.movesQueue, 1)
	if nextMove then
		if nextMove == 'submit' then
			self:submitMove()
		elseif nextMove == 'undo' then
			self:undoLastMove()
		else
			self:movePiece(unpack(nextMove))
		end
	end
end

function Game:gameLoop()
	print('gameloop - started')
	
	self:reset()
	self.playback = true
	
	self:getGameState(true)
	while not self.loaded do
		coroutine.yield()
	end
	self.loadingText:setVisible(false)
	self:queueAllMovesButTheLast()

	while self.playback and #self.movesQueue > 0 do
		self:executeMove()
	end
	
	-- We have one move move
	if self.is_my_turn then
		self:queueOneMove(nil, true, true)
		self:executeMove()
		self:createPieces()
	else
		self:createPieces()
		self:queueOneMove(nil, true)
		self:executeMove()
	end
	
	self.playback = false
	self.waiting_for_submit = false
	
	local start_time = MOAISim.getElapsedTime()
	
	while self.running do
		if self.is_my_turn then
			
			local time_elapsed = MOAISim.getElapsedTime() - start_time
			start_time = MOAISim.getElapsedTime()
			self.time_remaining = self.time_remaining - time_elapsed
			self:updateClocks(self.time_remaining)
		end
		while #self.movesQueue > 0 do
			self:executeMove()
		end
		
		if (not self.is_my_turn) and os.time() - self.lastConnectionToServer > 5 and not self.game_is_finished then
			self:getGameState()
		end
		
		coroutine.yield()
	end

	-- This is when we're quiting the game loop - update time clocks
	self:sendClockUpdate()
	
	print('gameloop - ended')
end

function Game:startPlaying()
	thread = MOAICoroutine.new()
	thread:run(self.gameLoop, self)
end

function Game:stopPlaying()
	self.running = false
end

--------------------------------------------------------------------------------------
---- STATE FUCTIONS ------------------------------------------------------------------
--------------------------------------------------------------------------------------

-- This is in practice the entry point of this state
function Game:onLoad(game_id, nation)
	self.game_id = game_id
	self:init(Env.screenWidth, Env.screenHeight, Env.nation)
	
end

function Game:onFocus()

	pauseMusic()

	if MOAIInputMgr.device.pointer then
		MOAIInputMgr.device.mouseLeft:setCallback(
			function (isMouseDown)
				local mouseEvent = 'MouseDown'
				if not isMouseDown then
					mouseEvent = 'MouseUp'
				end
				local x, y = MOAIInputMgr.device.pointer:getLoc()
				self:handleClickOrTouch(x, y, mouseEvent)
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


	self:startPlaying()
end

function Game:onLoseFocus()
	self:stopPlaying()
end

return Game