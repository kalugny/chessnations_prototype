require 'config'
require 'utils'

function fromCSVLine(s, fields)
	local fieldIndex = 1
	s = s .. ','        -- ending comma
	local t = {}        -- table to collect fields
	local fieldstart = 1
	repeat
		-- next field is quoted? (start with `"'?)
		if string.find(s, '^"', fieldstart) then
			local a, c
			local i  = fieldstart
			repeat
				-- find closing quote
				a, i, c = string.find(s, '"("?)', i+1)
			until c ~= '"'    -- quote not followed by quote?
			if not i then error('unmatched "') end
			local f = string.sub(s, fieldstart+1, i-1)
			if fields then
				t[fields[fieldIndex]] = string.gsub(f, '""', '"')
				fieldIndex = fieldIndex + 1
			else
				table.insert(t, (string.gsub(f, '""', '"')))
			end
			fieldstart = string.find(s, ',', i) + 1
		else                -- unquoted; find next comma
			local nexti = string.find(s, ',', fieldstart)
			if fields then
				t[fields[fieldIndex]] = string.sub(s, fieldstart, nexti-1)
				fieldIndex = fieldIndex + 1
			else
				table.insert(t, string.sub(s, fieldstart, nexti-1))
			end
			fieldstart = nexti + 1
		end
	until fieldstart > string.len(s)
	return t
end

AssetMgr = {}

function AssetMgr.load(filename, dir, bottom)
	dir = dir or ''
	bottom = bottom or -RESOLUTION_Y / 2
	
	local path = IMAGE_PATH .. dir .. DIR_SEP .. filename
	local csvFile = MOAIFileStream.new()
	local success = csvFile:open(path)
	if not success then
		print("Can't load " .. path)
		return
	end
	-- The fields are in the first line
	local csvContent, size = csvFile:read(MAX_CSV_FILE_SIZE)
	local csvLines = csvContent:split('\n')
	local fields = fromCSVLine(csvLines[1])
	table.remove(csvLines, 1)
	local assets = {}
	for _, line in ipairs(csvLines) do
		local t = fromCSVLine(line, fields)
		assets[t['Name']] = t
	end
	for asset_name, asset_attrs in pairs(assets) do
		local gfx = nil
		local prop = nil
		if asset_attrs['Type']  == 'button' then
			prop = addButton(dir .. DIR_SEP .. asset_attrs['Filename'],
							 dir .. DIR_SEP .. asset_attrs['Click image'], 
							 tonumber(asset_attrs['Width']), 
							 tonumber(asset_attrs['Height']), 
							 nil, 
							 false)
		else
			if asset_attrs['Type'] == 'graphic' then
				gfx = MOAIGfxQuad2D.new()
			elseif asset_attrs['Type'] == 'tile' then
				gfx = MOAITileDeck2D.new()
				gfx:setSize(tonumber(asset_attrs['Tiles in row']), tonumber(asset_attrs['Tile rows']))
			end
			gfx:setTexture(IMAGE_PATH .. dir .. DIR_SEP .. asset_attrs['Filename'], MOAITexture.TRUECOLOR)
			gfx:setRect(0, 0, tonumber(asset_attrs['Width']), tonumber(asset_attrs['Height']))
			asset_attrs['gfx'] = gfx
			if asset_attrs['Create prop'] == '1' then
				prop = MOAIProp2D.new()
				prop:setDeck(gfx)			
			end
		end
		
		if asset_attrs['Create prop'] == '1' then
			asset_attrs['prop'] = prop
			
			local width = RESOLUTION_X
			local height = RESOLUTION_Y
			
			if asset_attrs['Relative to'] ~= 'screen' then
				prop:setParent(assets[asset_attrs['Relative to']]['prop'])
				width = tonumber(assets[asset_attrs['Relative to']]['Width'])
				height = tonumber(assets[asset_attrs['Relative to']]['Height'])
			end
			local x = tonumber(asset_attrs['X'])
			local y = tonumber(asset_attrs['Y'])
			if asset_attrs['Relation point'] == 'top-left' then
				x = x - width / 2
				y = y + height / 2
			elseif asset_attrs['Relation point'] == 'bottom-left' then
				x = x - width / 2
				y = bottom + y
			end
			prop:setLoc(x, y)
		end
	end
	
	return assets

end

function AssetMgr.addPropsToLayer(layer, props, assets)
	for i, name in ipairs(props) do
		layer:insertProp(assets[name]['prop'])
	end
end

