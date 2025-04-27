local HRadialMenu = ISBaseObject:derive("HRadialMenu")
local HCommand = ISBaseObject:derive("HCommand")

activeMenu = nil

local ticks = 0
local wasVisible = false

function HCommand:new(menu, item, text, action)
    local o = ISBaseObject.new(self)
    o.menu = menu
    o.item = item
    o.text = text
    o.action = action
    return o
end

function HCommand:fillMenu(menu)
    menu:addSlice(self.text, self.item:getTexture(), self.invoke, self)
end

function checkIfBothHands(item)
    if item:isRequiresEquippedBothHands() and item:isTwoHandWeapon() then
        return true
    elseif not item:isRequiresEquippedBothHands() and item:isTwoHandWeapon() then
        return false
    else
        return false
    end
end

function HCommand:invoke()
    if self.action == 1 then
        player:setPrimaryHandItem(nil)

        if checkIfBothHands(player:getSecondaryHandItem()) then
            player:setSecondaryHandItem(nil)
        end

        player:setPrimaryHandItem(self.item)
    elseif self.action == 2 then
        player:setSecondaryHandItem(nil)

        if checkIfBothHands(player:getPrimaryHandItem()) then
            player:setPrimaryHandItem(nil)
        end

        player:setSecondaryHandItem(self.item)
    else
        player:setPrimaryHandItem(nil)
        player:setSecondaryHandItem(nil)
        player:setPrimaryHandItem(self.item)
        player:setSecondaryHandItem(self.item)
    end
end

function HRadialMenu:fillMenu()
    local menu = getPlayerRadialMenu(self.playerNum)
    menu:clear()

    local commands = {}

    local inv = player:getInventory():getItems();
    for i = 0, inv:size()-1 do
        local item = inv:get(i);
        if item:getAttachedSlot() > -1 then
            if item:isRequiresEquippedBothHands() and item:isTwoHandWeapon() then -- Check if the item requires both hands and is a two-handed weapon
                table.insert(commands, HCommand:new(self, item, "[" .. item:getAttachedSlot() .. "] \n" .. "Equip \n" .. tostring(item:getName()) .. "\nin both hands", 0))
            
            elseif not item:isRequiresEquippedBothHands() and item:isTwoHandWeapon() then -- Check if the item is a two-handed weapon but does not require both hands
                table.insert(commands, HCommand:new(self, item, "[" .. item:getAttachedSlot() .. "] \n" .. "Equip \n" .. tostring(item:getName()) .. "\nin both hands", 0))
                table.insert(commands, HCommand:new(self, item, "[" .. item:getAttachedSlot() .. "] \n" .. "Equip \n" .. tostring(item:getName()) .. "\nin right hand", 1))
                table.insert(commands, HCommand:new(self, item, "[" .. item:getAttachedSlot() .. "] \n" .. "Equip \n" .. tostring(item:getName()) .. "\nin left hand", 2))
                
            else -- All other items
                table.insert(commands, HCommand:new(self, item, "[" .. item:getAttachedSlot() .. "] \n" .. "Equip \n" .. tostring(item:getName()) .. "\nin right hand", 1))
                table.insert(commands, HCommand:new(self, item, "[" .. item:getAttachedSlot() .. "] \n" .. "Equip \n" .. tostring(item:getName()) .. "\nin left hand", 2))
                
            end

            self.hasCommands = true
        end
    end

    for _,command in ipairs(commands) do
        local count = #menu.slices
        command:fillMenu(menu)
        if count == #menu.slices then
            menu:addSlice(nil, nil, nil)
        end
    end
end

function HRadialMenu:display()
    self:fillMenu()

    if not self.hasCommands then return end

    local menu = getPlayerRadialMenu(self.playerNum)
    menu:center()
    menu:addToUIManager()
    if JoypadState.players[self.playerNum+1] then
        menu:setHideWhenButtonReleased(Joypad.DPadUp)
        setJoypadFocus(self.playerNum, menu)
        self.player:setJoypadIgnoreAimUntilCentered(true)
    end
end

function HRadialMenu:new(player)
    local o = ISBaseObject.new(self)
    o.player = player
    o.playerNum = player:getPlayerNum()
    return o
end

function HRadialMenu.checkKey(key)
    if key ~= getCore():getKey("HRM") then
        return false
    end
    
    if ModKey and ModKey.isKeyDown() then 
        return false
    end

    local player = getSpecificPlayer(0)
    if not player or player:isDead() then
        return false
    end

    if getCell():getDrag(0) then
        return false
    end

    return true
end

function HRadialMenu.showRadialMenu(player)
    if not player or player:isDead() then
        return
    end
    
    local menu = HRadialMenu:new(player)
    menu:display()
end

if not SpiffUI then
    local _ISDPadWheels_onDisplayUp = ISDPadWheels.onDisplayUp
    function ISDPadWheels.onDisplayUp(joypadData)
        local player = getSpecificPlayer(joypadData.player)
        if not player:getVehicle() and not ISVehicleMenu.getVehicleToInteractWith(player) then
            HRadialMenu.showRadialMenu(player)
        else
            _ISDPadWheels_onDisplayUp(joypadData)
        end
    end
end

function HRadialMenu.onKeyPress(key)

    if not HRadialMenu.checkKey(key) then
        return 
    end

    local radialMenu = getPlayerRadialMenu(0)

    if radialMenu:isReallyVisible() and getCore():getOptionRadialMenuKeyToggle() then
        wasVisible = true
        radialMenu:removeFromUIManager()
        setJoypadFocus(activeMenu.playerNum, nil)
        activeMenu = nil
        return
    end
    ticks = getTimestampMs()
    wasVisible = false
end

function HRadialMenu.onKeyHold(key)
    if not HRadialMenu.checkKey(key) then
        return
    end
    if wasVisible then
        return
    end

    local radialMenu = getPlayerRadialMenu(0)
    local delay = 500
    if HRMconfig.delay then
        delay = 0
    end
    if (getTimestampMs() - ticks >= delay) and not radialMenu:isReallyVisible() then
        local menu = HRadialMenu:new(getSpecificPlayer(0))
        menu:display()
        activeMenu = menu
    end

end

Events.OnGameStart.Add(function()
    Events.OnKeyStartPressed.Add(HRadialMenu.onKeyPress)
    Events.OnKeyKeepPressed.Add(HRadialMenu.onKeyHold)
end)

return HRadialMenu