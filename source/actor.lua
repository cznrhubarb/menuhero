import "class"

local gfx <const> = playdate.graphics

Actor = class(function(actor, file, name, hp)
	local image = gfx.image.new(file)
	local sprite = gfx.sprite.new(image)
	sprite:add()
    actor.sprite = sprite

    actor.x = sprite.x
    actor.y = sprite.y
    actor.name = name
    actor.currentHP = hp
    actor.maxHP = hp
    actor.tweens = { }
end)

function Actor:isDead()
	return self.currentHP <= 0
end

function Actor:drawHealthBar()
	local fillRatio = self.currentHP / self.maxHP
	gfx.drawRect(self.x - 15, self.y + 18, 30, 5)
	gfx.fillRect(self.x - 15, self.y + 18, 30 * fillRatio, 5)
end

function Actor:inflictDamage(damage)
	self.currentHP = math.clamp(self.currentHP - damage, 0, self.maxHP)
	if self.currentHP == 0 then
		self.sprite:remove()
		-- local idx = table.findIndex(enemySprites, actor)
		-- if idx ~= -1 then
		-- 	table.remove(enemySprites, idx)
		-- else
		-- 	-- TODO: Player's dead
		-- 	table.removeByValue(partySprites, actor)
		-- 	print("Player died")
		-- end
	end
end

function Actor:update()
	for i, tween in pairs(self.tweens) do
        self[tween.key] = tween.seq:get()
		if not tween.seq.isRunning then
			table.remove(self.tweens, i)
		end
	end

    self.sprite:moveTo(self.x, self.y)
end

function Actor:animateAttack(magnitude)
	local seq = sequence.new():from(self.x):to(self.x + magnitude, 0.05, "inQuad"):to(self.x, 0.2, "outQuad"):start()
	self.tweens[#self.tweens] = { key="x", seq=seq }

	cameraShake(500, 4)
end
