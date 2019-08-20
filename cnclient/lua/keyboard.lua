--utility function
function distance ( x1, y1, x2, y2 )
        return math.sqrt ((( x2 - x1 ) ^ 2 ) + (( y2 - y1 ) ^ 2 ))
end

k = {}

local kboard = nil
local keysWide = 1
local keySize = 5
local boardHeight = keySize
local left = 50 - keySize/2
local top = 100
local xpos = left
local ypos = top
local rowCount = 0
local speed = 1000
local textbox = nil

--release all gui objects
k.destroyKeyboard = function (self, gui)
        if kboard ~= nil then
                for k, v in pairs(kboard) do
                        gui:destroyWindow(v)
                end
                kboard = nil
        end
end

--setup a new keyboard, starting with only 1 row
k.createKeyboard = function (self, gui, charsWide)
        if kboard ~= nil then destroyKeyboard(gui) end
        kboard = {}
        keysWide = charsWide
        boardHeight = keySize
        left = 50 - keySize*charsWide/2
        xpos = left
        top = 100
        ypos = top
        rowCount = 0
end

 

local function keyClick(event, data)
        --give focus to selected textbox so that it receives the keypress
        if textbox ~= nil then data.g:setFocus(textbox) end
        --pass keypress to gui
        data.g:injectKeyDown(data.character)
        data.g:injectKeyUp(data.character)
end

 

k.addKey = function (self, gui, char)
        if kboard == nil then return end
        --empty string indicates skipping a key slot
        if char ~= "" then
                kboard[char] = gui:createButton()
                kboard[char]:setPos(xpos, ypos)
                kboard[char]:setDim(keySize, keySize)
                kboard[char]:setText(char)
                data = {}

                data.g = gui
                if char == "<" then
                        data.character = 8 --backspace
                else
                        data.character = string.byte(char) --ascii value of character
                end

                kboard[char]:registerEventHandler(kboard[char].EVENT_BUTTON_CLICK, nil, keyClick, data)
        end
        --increment to next key in row
        rowCount = rowCount + 1
        xpos = xpos + keySize
        if rowCount >= keysWide then
                --new row
                xpos = left
                ypos = ypos + keySize
                boardHeight = boardHeight + keySize
                rowCount = 0
        end
end

 

--moves the key to its place at the bottom of the screen (or off the screen if show=false).
--NOTE: only returns once the move has finished
local function moveKey(key, show)
        local x, y = key:getPos()
        --move onto the screen
        local newy = y - boardHeight
        --move off the screen
        if not show then newy = y + boardHeight end
        --not really the best way of getting the target location, but the easiest/quickest solution
        key:setPos(x, newy)
        local tx, ty = key._rootProp:getLoc()
        key:setPos(x,y)
        --calculate a travel time relevant to the distance being traveled
        local travelTime = distance(x, y, x, newy) / speed

        MOAIThread.blockOnAction(key._rootProp:seekLoc(tx, ty, travelTime, MOAIEaseType.LINEAR))
        --the seekLoc only moves the prop, the prop container is not aware of the move, so tell it.
        key:setPos(x, newy)
end

 

--moves all keys to the desired location
k.showKeyboard = function (self, gui, show)
        if kboard == nil then return end
        --only need to pass in show when you want to hide the keyboard
        if show == nil then show = true end
        for k, v in pairs(kboard) do
                --move keys in separate threads
                MOAIThread.new():run(moveKey, v, show)
        end
end

 

k.hideKeyboard = function (self, gui)
        self:showKeyboard(gui, false)
end

k.setTextbox = function(self, tbox)
        textbox = tbox
end

return k