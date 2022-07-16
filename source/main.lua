import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"

import "sequence"
import "extensions"
import "utilities"
import "enemy"
import "actor"
--[[ 
	TODO

	Make action interesting (based on selection)
	Make enemy actions interesting

	Tween options if necessary (more than displayable)
	Mask option area

	SpinWrap - Can roll around top/bottom
	FixedEntry - Random starting point or a specific index
]]

--[[
	IDEAS TO TEST

	Randomize order of menus each iteration
	Multi select menus - Drill down, toggle an option on, drill up, go to another menu to execute
		This would mean terminal options are either executable or toggleable
		This could be shown by up menu options changing text or adding icons
	Multiple team members, queue up for attacks
	Fixed vs random entry into next menu 
		(or it depends on the menu: power level has to crank down)
]]

local gfx <const> = playdate.graphics
local tmr <const> = playdate.timer

local menuOptionWidth <const> = 92
local menuOptionHeight <const> = 27
local menuTop <const> = 120
local ticksPerRevolution <const> = 20
local timeBetweenEnemyAttacks <const> = 4

local partySprites = { }
local enemySprites = { }
-- TODO: This should move into the menu option somehow so we can retain
--    memory of last position (or potentially change the starting point)
local currentMenuSelections = { 1 }
local menuTreeRoot = { }
local currentMenu = menuTreeRoot
local menuOffsetX = 0
local menuTween = nil


local function drawHealthBar(actor)
	local fillRatio = actor.currentHP / actor.maxHP
	gfx.drawRect(actor.x - 15, actor.y + 18, 30, 5)
	gfx.fillRect(actor.x - 15, actor.y + 18, 30 * fillRatio, 5)
end

local function inflictDamage(actor, damage)
	actor.currentHP = math.clamp(actor.currentHP - damage, 0, actor.maxHP)
	if actor.currentHP == 0 then
		actor:remove()
		local idx = table.findIndex(enemySprites, actor)
		if idx ~= -1 then
			table.remove(enemySprites, idx)
		else
			-- TODO: Player's dead
			table.removeByValue(partySprites, actor)
			print("Player died")
		end
	end
end

local function createSprite(file, x, y, name, hp, turnSpeed)
	local image = gfx.image.new(file)
	local sprite = gfx.sprite.new(image)
	sprite:moveTo(x, y)
	sprite:add()
	sprite.name = name
	sprite.maxHP = hp
	sprite.currentHP = hp
	sprite.turnSpeed = turnSpeed
	sprite.attackTimer = math.random() * timeBetweenEnemyAttacks * 0.5
	sprite.tweens = { }
	return sprite
end

local function updateTweens(actor)
	for i, tween in pairs(actor.tweens) do
		if tween.key == "x" then
			actor:moveTo(tween.seq:get(), actor.y)
		elseif tween.key == "y" then
			actor:moveTo(actor.y, tween.seq:get())
		else
			actor[tween.key] = tween.seq:get()
		end
		if not tween.seq.isRunning then
			table.remove(actor.tweens, i)
		end
	end
end

local function animateAttack(actor, magnitude)
	local seq = sequence.new():from(actor.x):to(actor.x + magnitude, 0.05, "inQuad"):to(actor.x, 0.2, "outQuad"):start()
	actor.tweens[#actor.tweens] = { key="x", seq=seq }

	cameraShake(500, 4)
end

local function updateAttackTimer(actor, elapsed)
	actor.attackTimer += elapsed
	if actor.attackTimer >= timeBetweenEnemyAttacks then
		animateAttack(actor, -20)
		actor.attackTimer = 0
		-- TODO: Assuming there's only one player
		local knight = partySprites[1]
		inflictDamage(knight, 4)
	end

	local fillRatio = actor.attackTimer / timeBetweenEnemyAttacks
	gfx.drawArc(actor.x + 17, actor.y - 12, 5, 0, fillRatio * 360)
end

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

local function initialize()
	math.randomseed(playdate.getSecondsSinceEpoch())

	partySprites[1] = createSprite("images/knight", 100, 60, "Knight", 50, 10)
	enemySprites[1] = createSprite("images/rat", 350, 30, "Rat 1", 25, 10)
	enemySprites[2] = createSprite("images/rat", 280, 60, "Rat 2", 25, 10)
	enemySprites[3] = createSprite("images/rat", 330, 80, "Rat 3", 25, 10)

	populateTree()
	playdate.resetElapsedTime()
end

local function getCurrentMenuOption()
	return currentMenu[currentMenuSelections[#currentMenuSelections]]
end

-- TODO: This should probably be a method or property called isTerminal or whatever
local function menuOptionIsTerminal(option)
	return option.children == nil
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

initialize()

function playdate.update()
	local elapsed = playdate.getElapsedTime()
	playdate.resetElapsedTime()
	tmr.updateTimers()

	-- Input
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
			animateAttack(partySprites[1], 20)
			local targetIndex = math.random(#enemySprites)
			inflictDamage(enemySprites[targetIndex], 5)
			
			if #enemySprites == 0 then
				-- TODO: Player won
			else
				menuOffsetX = 0
				menuTween = nil
				resetMenu()
			end
		end
	end

	-- Render
	gfx.sprite.update()
	sequence.update()
	
	currentMenu = menuTreeRoot
	for i = 1, #currentMenuSelections, 1 do
		if i > 1 then
			currentMenu = currentMenu[currentMenuSelections[i-1]].children
		end
		drawMenu(currentMenu, i)
	end

	local originalColor = gfx.getColor()
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRect(0, 0, 400, menuTop + 10)
	gfx.setColor(originalColor)

	for i = 1, #partySprites, 1 do
		drawHealthBar(partySprites[i])
		updateTweens(partySprites[i])
	end
	for i = 1, #enemySprites, 1 do
		drawHealthBar(enemySprites[i])
		updateAttackTimer(enemySprites[i], elapsed)
		updateTweens(enemySprites[i])
	end
end
