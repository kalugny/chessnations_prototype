require 'config'

MapLoader = {}

function MapLoader:loadTilesets()
	self.map.tileset
	
					gfx = MOAITileDeck2D.new()
				gfx:setSize(tonumber(asset_attrs['Tiles in row']), tonumber(asset_attrs['Tile rows']))
			end
			gfx:setTexture(IMAGE_PATH .. dir .. DIR_SEP .. asset_attrs['Filename'], MOAITexture.TRUECOLOR)
			gfx:setRect(0, 0, tonumber(asset_attrs['Width']), tonumber(asset_attrs['Height']))
end

function MapLoader:load(filename, dir)

	dir = dir or ''

	local path = MAP_PATH .. dir .. DIR_SEP .. filename
	self.map = dofile(path)

end

return MapLoader