
module(..., package.seeall)

local M = {}

local Piece
local Pawn
local WhitePawn
local BlackPawn
local Knight
local WhiteKnight
local BlackKnight
local Bishop
local WhiteBishop
local BlackBishop
local Rook
local WhiteRook
local BlackRook
local Queen
local WhiteQueen
local BlackQueen
local King
local WhiteKing
local BlackKing
local Game

---------------------------------------------------------------------------------------------
--- @type Piece
---------------------------------------------------------------------------------------------

Piece = pl.class()
M.Piece = Piece

function Piece:_init(game, position, color)
	self.game = game
	self.x, self.y = position[1], position[2]
	self.color = color
end	

function Piece:__tostring()
	local str = ''
	if self.color then
		str = str .. self.color .. ' '
	end
	if self.name then
		str = str .. self.name .. ' '
	end
	if self.x and self.y then
		str = str .. '(' .. self.x .. ', ' .. self.y .. ')'
	end	
	return str
end

function Piece:direction()
	if self.game.rules.TWO_SIDES and pl.utils.choose(self.game.rules.WHITE_STARTS, self.color == 'black', self.color == 'white') then
		return -1
	end
	return 1
end

function Piece:canEat(otherPiece)
	if otherPiece == '' then
		return false
	end
	return self.game.rules.CAPTURE_ENABLED and (self.color ~= otherPiece.color or self.game.rules.CAN_CAPTURE_SAME_COLOR)
end

function Piece:removeFromBoard(board)
	for i, j, k in pl.array2d.iter(board, true) do
		if k == self then
			board[i][j] = ''
		end
	end
end

---------------------------------------------------------------------------------------------
--- @type Pawn
---------------------------------------------------------------------------------------------

Pawn = pl.class(Piece)
Pawn.name = 'Pawn'
M.Pawn = Pawn

function Pawn:_init(game, position, color)
	self:super(game, position, color)
	self.name = 'Pawn'
	self.dir = self:direction()
	self.homeRow = pl.utils.choose(self.dir == 1, self.game.rules.PAWN_HOME_ROW, self.game.boardHeight - self.game.rules.PAWN_HOME_ROW + 1)
	self.endRow = pl.utils.choose(self.dir == 1, self.game.boardHeight, 1)
end

function Pawn:canMoveTo(board, fromX, fromY, toX, toY)
	
	if board[fromX][fromY] ~= self then
		return false
	end
	
	local retVal = false
	local sideEffects = pl.List()
	
	if board[toX][toY] == '' and fromX == toX then
		-- dest is straight ahead and empty
		if toY == fromY + self.dir * 2 and self.homeRow == fromY then
			-- and you jump two spots from home row
			retVal = true
			sideEffects:append{ name = 'enPassant', value = pl.List{fromX, fromY + self.dir} }
		elseif toY == fromY + self.dir * 1 then
			-- and you move one row
			retVal = true
		end

	elseif math.abs(fromX - toX) == 1 and toY == fromY + self.dir then
		if self:canEat(board[toX][toY]) then 
			retVal = true
			sideEffects:append{name = 'capture', value = board[toX][toY]}
		elseif self.game.enPassant == pl.List{toX, toY} then
			retVal = true
			local capturedPawnX, capturedPawnY = self.game.enPassant[1], self.game.enPassant[2] - self.dir
			sideEffects:append{name = 'capture', value = board[capturedPawnX][capturedPawnY]}
		end
	end
	
	if retVal and toY == self.endRow then
		sideEffects:append{name = 'promotion', value = {toX, toY}}
	end		
		
	return retVal, sideEffects
end

WhitePawn = pl.class(Pawn)
WhitePawn.name = 'WhitePawn'
M.WhitePawn = WhitePawn
function WhitePawn:_init(game, position)
	self:super(game, position, 'white')
end
	
BlackPawn = pl.class(Pawn)
BlackPawn.name = 'BlackPawn'
M.BlackPawn = BlackPawn
function BlackPawn:_init(game, position)
	self:super(game, position, 'black')
end

---------------------------------------------------------------------------------------------
--- @type Knight
---------------------------------------------------------------------------------------------

Knight = pl.class(Piece)
Knight.name = 'Knight'
M.Knight = Knight

function Knight:_init(game, position, color)
	self:super(game, position, color)
	self.name = 'Knight'
end

function Knight:canMoveTo(board, fromX, fromY, toX, toY)

	if board[fromX][fromY] ~= self then
		return false
	end
	
	local retVal = false
	local sideEffects = pl.List()
	
	if math.abs(toX - fromX) + math.abs(toY - fromY) == 3 and fromX ~= toX and fromY ~= toY then
		if board[toX][toY] == '' then
			retVal = true
		elseif  self:canEat(board[toX][toY]) then	
			retVal = true
			sideEffects:append{name = 'capture', value = board[toX][toY]}
		end
	end
	
	return retVal, sideEffects
	
end

WhiteKnight = pl.class(Knight)
WhiteKnight.name = 'WhiteKnight'
M.WhiteKnight = WhiteKnight
function WhiteKnight:_init(game, position)
	self:super(game, position, 'white')
end
	
BlackKnight = pl.class(Knight)
BlackKnight.name = 'BlackKnight'
M.BlackKnight = BlackKnight
function BlackKnight:_init(game, position)
	self:super(game, position, 'black')
end

---------------------------------------------------------------------------------------------
--- @type Bishop
---------------------------------------------------------------------------------------------

Bishop = pl.class(Piece)
Bishop.name = 'Bishop'
M.Bishop = Bishop

function Bishop:_init(game, position, color)
	self:super(game, position, color)
	self.name = 'Bishop'
end

function Bishop:canMoveTo(board, fromX, fromY, toX, toY)

	if board[fromX][fromY] ~= self then
		return false
	end
	
	local retVal = false
	local sideEffects = pl.List()
			
	if math.abs(toX - fromX) == math.abs(toY - fromY) and
	  (board[toX][toY] == '' or self:canEat(board[toX][toY])) then	
		local xDir = pl.utils.choose(toX - fromX > 0, 1, -1)
		local yDir = pl.utils.choose(toY - fromY > 0, 1, -1)
		local blocking = false
		for i = 1, math.abs(toX - fromX) - 1 do
			if board[fromX + i*xDir][fromY + i*yDir] ~= '' then
				blocking = true
				break
			end
		end
		if not blocking then
			retVal = true
			if board[toX][toY] ~= '' then
				sideEffects:append{name = 'capture', value = board[toX][toY]}
			end
		end
	end
	
	return retVal, sideEffects
	
end

WhiteBishop = pl.class(Bishop)
WhiteBishop.name = 'WhiteBishop'
M.WhiteBishop = WhiteBishop
function WhiteBishop:_init(game, position)
	self:super(game, position, 'white')
end
	
BlackBishop = pl.class(Bishop)
BlackBishop.name = 'BlackBishop'
M.BlackBishop = BlackBishop
function BlackBishop:_init(game, position)
	self:super(game, position, 'black')
end

---------------------------------------------------------------------------------------------
--- @type Rook
---------------------------------------------------------------------------------------------

Rook = pl.class(Piece)
Rook.name = 'Rook'
M.Rook = Rook

function Rook:_init(game, position, color)
	self:super(game, position, color)
	self.name = 'Rook'
	self.moved = false
end

function Rook:canMoveTo(board, fromX, fromY, toX, toY)

	if board[fromX][fromY] ~= self then
		return false
	end
	
	local retVal = false
	local sideEffects = pl.List()
	
	if board[toX][toY] == '' or self:canEat(board[toX][toY]) then	
		local yDir = 0
		local xDir = 0
		if toX == fromX then
			yDir = pl.utils.choose(toY - fromY > 0, 1, -1)
		elseif toY == fromY then
			xDir = pl.utils.choose(toX - fromX > 0, 1, -1)
		end
		if yDir ~= 0 or xDir ~= 0 then
			local blocking = false
			for i = 1, math.max(math.abs(toX - fromX), math.abs(toY - fromY)) - 1 do
				if board[fromX + i*xDir][fromY + i*yDir] ~= '' then
					blocking = true
					break
				end
			end
			if not blocking then
				retVal = true
				if board[toX][toY] ~= '' then
					sideEffects:append{name = 'capture', value = board[toX][toY]}
				end
			end
		end
	end
	
	return retVal, sideEffects
	
end

WhiteRook = pl.class(Rook)
WhiteRook.name = 'WhiteRook'
M.WhiteRook = WhiteRook
function WhiteRook:_init(game, position)
	self:super(game, position, 'white')
end
	
BlackRook = pl.class(Rook)
BlackRook.name = 'BlackRook'
M.BlackRook = BlackRook
function BlackRook:_init(game, position)
	self:super(game, position, 'black')
end

---------------------------------------------------------------------------------------------
--- @type Queen
---------------------------------------------------------------------------------------------

Queen = pl.class(Piece)
Queen.name = 'Queen'
M.Queen = Queen

function Queen:_init(game, position, color)
	self:super(game, position, color)
	self.name = 'Queen'
end

function Queen:canMoveTo(board, fromX, fromY, toX, toY)

	if board[fromX][fromY] ~= self then
		return false
	end
	
	local retVal, sideEffects = Bishop.canMoveTo(self, board, fromX, fromY, toX, toY)
	if retVal then
		return retVal, sideEffects
	end
	return Rook.canMoveTo(self, board, fromX, fromY, toX, toY)
	
end

WhiteQueen = pl.class(Queen)
WhiteQueen.name = 'WhiteQueen'
M.WhiteQueen = WhiteQueen
function WhiteQueen:_init(game, position)
	self:super(game, position, 'white')
end
	
BlackQueen = pl.class(Queen)
BlackQueen.name = 'BlackQueen'
M.BlackQueen = BlackQueen
function BlackQueen:_init(game, position)
	self:super(game, position, 'black')
end

---------------------------------------------------------------------------------------------
--- @type King
---------------------------------------------------------------------------------------------

King = pl.class(Piece)
King.name = 'King'
M.King = King

function King:_init(game, position, color)
	self:super(game, position, color)
	self.name = 'King'
	self.moved = false
	self.homeRow = pl.utils.choose(self:direction() == 1, 1, self.game.boardHeight)
end

function King:canMoveTo(board, fromX, fromY, toX, toY)

	if board[fromX][fromY] ~= self then
		return false
	end
	
	local retVal = false
	local sideEffects = pl.List()
		
	if (math.abs(toX - fromX) <= 1 and math.abs(toY - fromY) <= 1) and
		(board[toX][toY] == '' or self:canEat(board[toX][toY])) then	
		retVal = true
		if board[toX][toY] ~= '' then
			sideEffects:append{name = 'capture', value = board[toX][toY]}
		end
	elseif math.abs(toX - fromX) == 2 and toY == self.homeRow and self.game.rules.CASTLING_ENABLED and not self.moved then
		local rooks = {[1] = board[self.game.boardWidth][self.homeRow], [-1] = board[1][self.homeRow] }
		local dir = pl.utils.choose(toX - fromX > 0, 1, -1)
		if rooks[dir] and rooks[dir].name == 'Rook' and not rooks[dir].moved then
			local blocked = false
			local i = fromX + dir
			while i > 1 and i < self.game.boardWidth - 1 do
				if board[i][self.homeRow] ~= '' then
					blocked = true
					break
				end
				i = i + dir
			end
			if not blocked then
				retVal = true
				sideEffects:append{name = 'castling', value = pl.List{toX - dir, toY, rooks[dir].x, rooks[dir].y} }
			end
		end
	end
	
	return retVal, sideEffects
	
end

WhiteKing = pl.class(King)
WhiteKing.name = 'WhiteKing'
M.WhiteKing = WhiteKing
function WhiteKing:_init(game, position)
	self:super(game, position, 'white')
end
	
BlackKing = pl.class(King)
BlackKing.name = 'BlackKing'
M.BlackKing = BlackKing
function BlackKing:_init(game, position)
	self:super(game, position, 'black')
end


---------------------------------------------------------------------------------------------
--- @type Chess Rules																	-----
---------------------------------------------------------------------------------------------

DefaultRules = 	{	
					CAN_CAPTURE_SAME_COLOR = false,			-- Can eat pieces of same color 
					CAN_ONLY_MOVE_BY_CAPTURING = false,		-- Can't move to squares that are not filled with captureable pieces
					CAPTURE_ENABLED = true,					-- Can we capture other pieces at all?
					PAWN_HOME_ROW = 2, 						-- and height-HOME_ROW for the opponent
					CASTLING_ENABLED = true,
					WHITE_STARTS = true,					-- if 'false' black starts
					TWO_SIDES = true,						-- otherwise, there is only the starting color
					PROMOTION_ENABLED = true,				
					AUTOMATIC_PROMOTION = false,			-- Promote automatically to DEFAULT_PROMOTION every pawn that reaches the last row
					DEFAULT_PROMOTION = Queen,				-- If not stated otherwise, promote to this 
					ENPASSANT_ENABLED = true,
					GOAL = 'checkmate',						-- other values might be: 'capture all' or a function
					CLOCK_ENABLED = false,
					WHITE_TIME = 0,
					BLACK_TIME = 0,
					BOARD_WIDTH = 8,
					BOARD_HEIGHT = 8,
					INITIAL_POSITIONS = {
											{	WhiteRook,		WhitePawn,	'',	'',	'',	'',	BlackPawn,	BlackRook	} ,
											{	WhiteKnight,	WhitePawn,	'',	'',	'',	'',	BlackPawn,	BlackKnight	} ,
											{	WhiteBishop,	WhitePawn,	'',	'',	'',	'', BlackPawn,	BlackBishop	} ,
											{	WhiteQueen,		WhitePawn,	'',	'',	'',	'', BlackPawn,	BlackQueen	} ,
											{	WhiteKing,		WhitePawn,	'',	'',	'',	'',	BlackPawn,	BlackKing	} ,
											{	WhiteBishop,	WhitePawn,	'',	'',	'',	'',	BlackPawn,	BlackBishop	} ,
											{	WhiteKnight,	WhitePawn,	'',	'',	'',	'',	BlackPawn,	BlackKnight	} ,
											{	WhiteRook,		WhitePawn,	'',	'',	'',	'',	BlackPawn,	BlackRook	} ,
					}
}
M.DefaultRules = DefaultRules

CapturePuzzleRules = {	
					CAN_CAPTURE_SAME_COLOR = true,			-- Can eat pieces of same color 
					CAN_ONLY_MOVE_BY_CAPTURING = true,		-- Can't move to squares that are not filled with captureable pieces
					CAPTURE_ENABLED = true,					-- Can we capture other pieces at all?
					PAWN_HOME_ROW = 2, 							-- and height-HOME_ROW for the opponent
					CASTLING_ENABLED = false,
					WHITE_STARTS = false,					-- if 'false' black starts
					TWO_SIDES = false,						-- otherwise, there is only the starting color
					PROMOTION_ENABLED = false,				
					AUTOMATIC_PROMOTION = false,			-- Promote automatically to DEFAULT_PROMOTION every pawn that reaches the last row
					DEFAULT_PROMOTION = Queen,				-- If not stated otherwise, promote to this 
					ENPASSANT_ENABLED = false,
					GOAL = 'capture all',						-- other values might be: 'capture all' or a function
					CLOCK_ENABLED = false,
					WHITE_TIME = 0,
					BLACK_TIME = 0,
					BOARD_WIDTH = 5,
					BOARD_HEIGHT = 5,
					INITIAL_POSITIONS = {
											{	BlackBishop,	'',				BlackRook,	'',	'',			} ,
											{	'',				'',				'',			'',	'',			} ,
											{	'',				BlackKnight,	'',			'',	BlackRook,	} ,
											{	BlackPawn,		'',				'',			'',	'',			} ,
											{	'',				'',				'',			'',	BlackQueen,	} ,
					}
}
M.CapturePuzzleRules = CapturePuzzleRules
				
---------------------------------------------------------------------------------------------
--- @type Game
---------------------------------------------------------------------------------------------
				
Game = pl.class()
M.Game = Game

function Game:_init(rules)
	self.rules = rules
	
	self.boardWidth, self.boardHeight = self.rules.BOARD_WIDTH, self.rules.BOARD_HEIGHT
	self.board = pl.array2d.new(self.boardWidth, self.boardHeight, '')
	
	self:fillBoard(self.rules.INITIAL_POSITIONS)
	
	if self.rules.ENPASSANT_ENABLED then
		self.enPassant = pl.List()
	end
	
	if self.rules.CAPTURE_ENABLED then
		self.captured = { white = pl.List(), black = pl.List()}
	end
	self.turn = pl.utils.choose(self.rules.WHITE_STARTS, 'white', 'black')
end

function Game:printBoard(board)
	board = board or self.board
	return pl.array2d.reduce2(	function (s1, s2) return s1 .. '\n\n' .. s2 end,
								'..',
								pl.array2d.map(
									string.center, 
									pl.array2d.map(
										function (s) return pl.utils.choose(s == '', '|________|', tostring(s.color):at(1) .. tostring(s.name)) end, 
										board), 
									10
								)
	)
end
	
function Game:printCaptures()
	if not self.rules.CAPTURE_ENABLED then
		return ''
	end
	local str = ''
	if #self.captured.white > 0 then
	str = str .. (", "):join(pl.tablex.map(tostring, self.captured.white)) .. ', '
	end
	if #self.captured.black > 0 then
		str = str .. (", "):join(pl.tablex.map(tostring,self.captured.black))
	end
	return pl.utils.choose(#str > 0, 'Captured: ' .. str, '')
end

function Game:printEnpassant()
	if not self.rules.ENPASSANT_ENABLED then
		return ''
	end
	if #self.enPassant > 0 then
		return 'Enpassant: ' .. (', '):join(self.enPassant)
	end
	return ''
end

function Game:__tostring()
	return 	self:printBoard()		.. '\n' .. 
			self:printEnpassant() 	--.. '\n' .. 
			--self:printCaptures()
end

function Game:numberOfPiecesOnBoard()
	local count = 0
	for p in pl.array2d.iter(self.board) do
		if p ~= '' then
			count = count + 1
		end
	end
	print('Pieces = ' .. count)
	return count
end

function Game:theOtherColor(color)
	return pl.utils.choose(color == 'white', 'black', 'white')
end

function Game:getKing(board, color)
	return self:getPieces(board, 'King', color)[1]
end

function Game:getPieces(board, pieceName, color)
	
	local found = pl.List()
	for i, j, piece in pl.array2d.iter(board, true) do
		if piece ~= '' and piece.name == pieceName and piece.color == color then
			found:append({piece = piece, x = i, y = j})
		end
	end
	return found
end

function Game:fillBoard(array)
	for i, j, v in pl.array2d.iter(array, true) do
		self.board[i][j] = ''
		if v ~= '' then
			self.board[i][j] = v(self, {i, j})
		end
	end
end

function Game:switchSides()
	if self.rules.TWO_SIDES then
		self.turn = self:theOtherColor(self.turn)
	end
end

function Game:copyBoard(board)
	local newBoard = pl.array2d.new(self.boardWidth, self.boardHeight, '')
	for i, j, k in pl.array2d.iter(board, true) do
		newBoard[i][j] = k
	end
	return newBoard
end

function Game:tryMove(board, fromX, fromY, toX, toY, promotion)
	
	if not (self:isInBoard(fromX, fromY) and self:isInBoard(toX, toY)) then
		return false, 'Coordinates not in board'
	end
	
	if fromX == toX and fromY == toY then
		return false, "Can't stay in place"
	end
	
	board = self:copyBoard(board)
	
	local piece = board[fromX][fromY]
	
	if piece == '' then
		return nil, 'No piece there'
	end

	local capturedPiece = nil
	local enPassant = pl.List()
	local rookPositions = pl.List()
	
	local canMove, sideEffects = piece:canMoveTo(board, fromX, fromY, toX, toY)
	if not canMove then
		return nil, "Can't move there"
	end
	
	for effect in pl.seq.list(sideEffects) do
		
		if effect.name == 'enPassant' and self.rules.ENPASSANT_ENABLED then
			enPassant = effect.value

		elseif effect.name == 'capture' then
			if not self.rules.CAPTURE_ENABLED then
				return nil, 'Capture disabled'
			end
			capturedPiece = effect.value
			capturedPiece:removeFromBoard(board)
		
		elseif effect.name == 'promotion' and self.rules.PROMOTION_ENABLED then
			if self.rules.AUTOMATIC_PROMOTION or promotion == nil then
				piece = self.rules.DEFAULT_PROMOTION(self, {toX, toY}, piece.color)
			else
				piece = promotion(self, {toX, toY}, piece.color)
			end
			
		elseif effect.name == 'castling' then
			if not self.rules.CASTLING_ENABLED then
				return nil, 'Castling disabled'
			end
			rookPositions = effect.value
		end
	end
	
	if self.rules.CAN_ONLY_MOVE_BY_CAPTURING and not capturedPiece then
		return false, 'Can only move by capturing'
	end
	
	board[toX][toY] = piece
	board[fromX][fromY] = ''
	
	if self.rules.GOAL == 'checkmate' then	
		if self:isInCheck(board, piece.color) then
			return nil, 'You are in check'
		end
	end

	return board, '', capturedPiece, enPassant, rookPositions
end

function Game:move(fromX, fromY, toX, toY, promotion)
	
	local board, msg, capturedPiece, enPassant, rookPositions = self:tryMove(self.board, fromX, fromY, toX, toY)

	if not board then
		return false, msg
	end
	
	local piece = self.board[fromX][fromY]
	
	if piece.color ~= self.turn then
		return false, 'Not ' .. piece.color .. "'s turn"
	end
	

	self.board = board
	piece.x = toX
	piece.y = toY
	
	if capturedPiece and self.rules.CAPTURE_ENABLED then
		self.captured[capturedPiece.color]:append(capturedPiece)
	end
	if self.rules.ENPASSANT_ENABLED then
		self.enPassant = enPassant
	end
	
	if self.rules.CASTLING_ENABLED then
		if piece.name == 'King' or piece.name == 'Rook' then
			piece.moved = true
		end
		if #rookPositions > 0 then
			local rook = self.board[rookPositions[3]][rookPositions[4]]
			rook.x = rookPositions[1]
			rook.y = rookPositions[2]
			self.board[rookPositions[1]][rookPositions[2]] = self.board[rookPositions[3]][rookPositions[4]]
			self.board[rookPositions[3]][rookPositions[4]] = ''
			
		end
	end
	
	if self.rules.GOAL == 'checkmate' then
		local otherColor = self:theOtherColor(self.turn)
		if self:isNoMoreMoves(self.board, otherColor) then
			if self:isInCheck(self.board, otherColor) then
				return true, 'Checkmate'
			else
				return true, 'Stalemate'
			end
		end
	elseif self.rules.GOAL == 'capture all' then
		if 	(self.rules.TWO_SIDES and self:numberOfPiecesOnBoard(self:theOtherColor(self.turn)) == 0) or 
			((not self.rules.TWO_SIDES) and self:numberOfPiecesOnBoard(self.turn) == 1) then
			return true, 'Captured all'
		end
	elseif type(self.rules.GOAL) == 'function' then
		local retVal, status = self.rulse.GOAL(self)
		if retVal then
			return true, status
		end
	end
	
	if self:isNoMoreMoves(self.board, self.turn) then
		return false, 'No more moves'
	end
	
	self:switchSides()
	
	return true
			
end

function Game:isInBoard(x, y)
	return not (x < 1 or x > self.boardWidth or y < 1 or y > self.boardHeight)
end

function Game:isInCheck(board, color)
	local king = self:getKing(board, color)
	if not king then
		-- Some captured it!
		return true
	end
	for i, j, piece in pl.array2d.iter(board, true) do
		if  piece ~= '' and
			piece.color ~= color and 
			self:tryMove(board, i, j, king.x, king.y) then
				return true
		end
	end
	return false
end

function Game:isNoMoreMoves(board, color)
	for x, y, piece in pl.array2d.iter(board, true) do
		if piece ~= '' and piece.color == color then
			for i, j, k in pl.array2d.iter(board, true) do
				if self:tryMove(board, x, y, i, j) then
					print('Available move: ', x, y, '->', i, j)
					return false
				end
			end
		end
	end
	return true
end

return M
