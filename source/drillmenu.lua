import "class"

--[[
    What does a menu look like?

    menuRoot = {
        -- This is the inside of a submenu
        currentSelection: 2,
        1: { text="Option 1", children = {
            -- We are inside another submenu
            currentSelection: 1,
            { text="Option 1a", children = nil }
        }},
        2: { text="Option 2", children = {
            currentSelection: 1,
            { text="Option 2a", children = {
                currentSelection: 1,
                { text="Option 2aa", children = nil }
            }},
            { text="Option 2b", children = nil }
        }},
        3: { text="Option 3", children = nil }
    }

    So a SUBMENU is a numbered list of options, along with some metadata like current selection
    A MENUOPTION is the text and an optional submenu called children

    The main or root menu is still considered a SUBMENU
]]

SubMenu = class(function(sm, optionList)
    sm.currentSelection = 1
    sm.options = optionList
end)

MenuOption = class(function(mo, text, submenu)
    mo.text = text
    mo.submenu = submenu
end)

function MenuOption:isTerminal()
    return self.submenu == nil
end

---------------------------------------------------
-- Unported code below

local function populateTree()
	local attacks = { "Sword", "Punch", "Insult" }
	local elements = { "Fire", "Electric", "Water", "Air" }
	local strengths = { "Strong", "Mid", "Fast" }
	local heats = { "Mild", "Medium", "Hot", "Xtra Hot" }
	local menus = {
		attacks, elements, strengths, heats
	}

	local rCreateMenu
	rCreateMenu = function(depth)
		local thisMenuWords = menus[math.random(#menus)]
		local thisMenu = { }
		for i, word in pairs(thisMenuWords) do
			local opt = { text=word }
			if depth > 1 then
				opt.children = rCreateMenu(depth-1)
			end
			thisMenu[i] = opt
		end
		return thisMenu
	end

	menuTreeRoot = rCreateMenu(7)
end

local function getCurrentMenuOption()
	return currentMenu[currentMenuSelections[#currentMenuSelections]]
end

local function drawMenu(menu, menuIndex)
	local startX = (menuIndex - 1) * menuOptionWidth
	local yOffset = (currentMenuSelections[menuIndex] - 1) * menuOptionHeight
	if menuTween ~= nil then
		menuOffsetX = menuTween:get()
	end

	gfx.drawRect(menuOffsetX + startX, menuTop, menuOptionWidth, menuOptionHeight * #menu)
	gfx.fillRect(menuOffsetX + startX, menuTop + yOffset, menuOptionWidth, menuOptionHeight)

	for t = 1, #menu, 1 do
		yOffset = (t-1) * menuOptionHeight
		local drawMethod = gfx.drawText
		-- OPTIMIZE: These could be batched so we don't have to switch the
		--	draw context multiple times
		-- Eventually we'll switch to sprites anyway
		if t == currentMenuSelections[menuIndex] then
			drawMethod = gfx.drawInvertedText
		end

		drawMethod(menu[t].text, menuOffsetX + startX + 7, menuTop + yOffset + 6)
		if menuOptionIsTerminal(menu[t]) == false then
			drawMethod(">", menuOffsetX + startX + menuOptionWidth - 11,menuTop + yOffset + 5)
		end
	end
end

local function resetMenu()
	currentMenuSelections = { 1 }
	currentMenu = menuTreeRoot
end

-----------------------------------------------------------
local function inputCodeFromUpdateLoop()
    local ticks = playdate.getCrankTicks(ticksPerRevolution)
	currentMenuSelections[#currentMenuSelections] += ticks
	if currentMenuSelections[#currentMenuSelections] > #currentMenu then
		currentMenuSelections[#currentMenuSelections] = 1
	elseif currentMenuSelections[#currentMenuSelections] < 1 then
		currentMenuSelections[#currentMenuSelections] = #currentMenu
	end

	if playdate.buttonJustPressed(playdate.kButtonLeft) then
		if #currentMenuSelections > 1 then
			table.remove(currentMenuSelections)

			local fullWidth = #currentMenuSelections * menuOptionWidth
			local desiredOffset = math.min(400 - fullWidth, 0)
			if desiredOffset ~= menuOffsetX then
				menuTween = sequence.new():from(menuOffsetX):to(desiredOffset, 0.3, "outQuad"):start()
			end
		end
	elseif playdate.buttonJustPressed(playdate.kButtonRight) then
		if menuOptionIsTerminal(getCurrentMenuOption()) == false then
			local nextMenu = currentMenu[currentMenuSelections[#currentMenuSelections]].children
			table.insert(currentMenuSelections, math.random(#nextMenu))

			local fullWidth = #currentMenuSelections * menuOptionWidth
			if fullWidth > 400 then
				menuTween = sequence.new():from(menuOffsetX):to(400 - fullWidth, 0.3, "outQuad"):start()
			end
		end
	elseif playdate.buttonJustPressed(playdate.kButtonDown) then
		if menuOptionIsTerminal(getCurrentMenuOption()) then
			-- TODO: The Action should take into account the options selected
			partySprites[1]:animateAttack(20)
			local targetIndex = math.random(#enemySprites)
			enemySprites[targetIndex]:inflictDamage(5)
			
			if #enemySprites == 0 then
				-- TODO: Player won
			else
				menuOffsetX = 0
				menuTween = nil
				resetMenu()
			end
		end
	end
end

local function drawCodeFromUpdateLoop()
	currentMenu = menuTreeRoot
	for i = 1, #currentMenuSelections, 1 do
		if i > 1 then
			currentMenu = currentMenu[currentMenuSelections[i-1]].children
		end
		drawMenu(currentMenu, i)
	end
end