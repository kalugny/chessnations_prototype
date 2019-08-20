
module(..., package.seeall)

local pai = require "pai"

M = {}

---------------------------------------------------------------------------------------------
--- @type Puzzle																		-----
---------------------------------------------------------------------------------------------

local Puzzle = pl.class()
M.Puzzle = Puzzle

Puzzle.PIECE_LAYOUT_IN_TILESET = { pai.BlackKnight, pai.BlackPawn, pai.BlackRook, pai.BlackKing, pai.BlackBishop, pai.BlackQueen,
								   pai.WhiteBishop, pai.WhiteKnight, pai.WhiteRook, pai.WhiteKing, pai.WhiteQueen, pai.WhitePawn }

-- Find the piece's location in board coords (1,1 is bottom-left)
function Puzzle:getBoardTileForPiece(pieceObject)
	local x, y = self:getTileForPiece(pieceObject)
	
	return x - self.boardLeft + 1, self.boardHeight - y + self.boardTop

end

-- Find the piece object by tile coords.
-- NOTE: The pieces are initialized (and so should remain) to be on the bottom-left corner of the tile
function Puzzle:getPieceOnBoardTile(i, j, search_radius)
	
	search_radius = search_radius or 5 -- pixels
	
	i = self.boardLeft + i - 1
	j = self.boardHeight - j + self.boardTop 
	
	local x = (i - 1) * self.tileMap.tileWidth
	local y = j * self.tileMap.tileHeight
	
	for piece in pl.seq.list(self.pieces) do
		local pieceX, pieceY = piece:getLoc()
		if pieceX > x - search_radius and pieceX < x + search_radius and pieceY > y - search_radius and pieceY < y + search_radius then
			return piece
		end
	end
	
	pl.utils.printf("Couldn't find piece in (%d, %d)\n", i, j)
	return ''
		
end

function Puzzle:getTileForPiece(pieceObject)
	local x, y = pieceObject:getLoc()
	
	return x / self.tileMap.tileWidth + 1, y / self.tileMap.tileHeight
	
end

function Puzzle:_init(mapfile, rules)
	
	self.rules = rules

    self.layer = flower.Layer()
    self.layer:setScene(scene)
    self.layer:setTouchEnabled(true)
	
	self.tileMap = tiled.TileMap()
	self.tileMap:addEventListener(tiled.TileMap.EVENT_LOADED_DATA, self.initBoardAndPieces, self)
    self.tileMap:loadLueFile(mapfile)
    self.tileMap:setLayer(self.layer)

end

function Puzzle:initBoardAndPieces()

	self.boardLayer = self.tileMap:findMapLayerByName('board')
	self.piecesLayer = self.tileMap:findMapLayerByName('pieces')
	
	self.mapWidth = self.tileMap.mapWidth
	self.mapHeight = self.tileMap.mapHeight

	self.boardLeft = 0
	self.boardTop = 0
	self.boardWidth = 0
	self.boardHeight = 0

	-- Find where the board starts inside the layer
	for i = 1, #self.boardLayer.tiles do
		if self.boardLayer.tiles[i] ~= 0 then
			self.boardLeft = i % self.mapWidth
			self.boardTop = math.floor(i / self.mapWidth) + 1
			break
		end
	end
	
	-- Find where the board ends
	for i = #self.boardLayer.tiles, 1, -1 do
		if self.boardLayer.tiles[i] ~= 0 then
			self.boardWidth = i % self.mapWidth - self.boardLeft + 1
			self.boardHeight = math.floor(i / self.mapWidth) + 1 - self.boardTop + 1
			break
		end
	end
	
	--print(self.boardLeft, self.boardTop, self.boardWidth, self.boardHeight)
	
	self.board = pl.array2d.new(self.boardWidth, self.boardHeight, '')
	self.pieces = self.piecesLayer:getObjects()
	for piece in pl.seq.list(self.pieces) do
		local x, y = self:getBoardTileForPiece(piece)
		self.board[x][y] = Puzzle.PIECE_LAYOUT_IN_TILESET[piece.renderer:getIndex()]
	end
	
	self.rules.BOARD_WIDTH = self.boardWidth
	self.rules.BOARD_HEIGHT = self.boardHeight
	self.rules.INITIAL_POSITIONS = self.board
	
	self.game = pai.Game(self.rules)
	
	-- pl.pretty.dump(self.board)

end

-------------------------------------
---- Event Handlers -----------------
-------------------------------------

function onCreate(e)
    puzzle1 = Puzzle("maps/puzzle1.lue", pai.CapturePuzzleRules)
    flower.InputMgr:addEventListener("keyDown", onKeyDown)
	
	print(puzzle1.game)
end

function onStart(e)

end

function move(line)
	local moves = line:split()
	if #moves ~= 2 then
		print("Don't understand input")
		return
	end
	local fromStr, toStr = moves[1], moves[2]
	if #fromStr ~= #toStr or #fromStr ~= 2 then
		print("Don't understand input")
		return
	end
	
	local from = {0, 0}
	local to = {0, 0}
	
	if not fromStr:isdigit() then
		from[1] = string.byte(fromStr:at(1)) - string.byte('a') + 1
	else
		from[1] = tonumber(fromStr:at(1))
	end
	from[2] = tonumber(fromStr:at(2))
	
	if not toStr:isdigit() then
		to[1] = string.byte(toStr:at(1)) - string.byte('a') + 1
	else
		to[1] = tonumber(toStr:at(1))
	end
	to[2] = tonumber(toStr:at(2))
		
	print('(' .. from[1] .. ', ' .. from[2] .. ') to (' ..  to[1] .. ', ' .. to[2] .. ')')
	local ok, status = puzzle1.game:move(from[1], from[2], to[1], to[2])	
	if ok then
		print(puzzle1.game)
	end
	if status then
		print(status)
	end
		
	

end


local inputs = ''
function onKeyDown(e)
		
	if e.key < 256 then
	
		local c = string.char(e.key)
	
		if e.key == 13 then
			io.write('\n')
			print('"' .. inputs .. '"')
			move(inputs)
			inputs = ''
		elseif e.key == 8 then
			-- Backspace
			inputs = string.sub(inputs, 1, #inputs - 1)
			io.write(c)
			io.write(' ')
		else
			inputs = inputs .. c
		end	
		io.write(c)

	end

end

function tileMap_OnTouchUp(e)

end

function tileMap_OnTouchMove(e)
 
end