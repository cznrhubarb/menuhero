import "actor"

local gfx <const> = playdate.graphics
local timeBetweenAttacks <const> = 4

Enemy = class(Actor, function(e, file, name, hp, turnSpeed)
	Actor.init(e, file, name, hp)  -- must init base!
	e.turnSpeed = turnSpeed
	e.attackTimer = math.random() * timeBetweenAttacks * 0.5
end)

-- Use a callback
function Enemy:updateAttackTimer(elapsed)
	self.attackTimer += elapsed
	if self.attackTimer >= timeBetweenEnemyAttacks then
		self:animateAttack(-20)
		self.attackTimer = 0
		-- -- TODO: Assuming there's only one player
		-- local knight = partySprites[1]
		-- inflictDamage(knight, 4)
	end

	local fillRatio = self.attackTimer / timeBetweenEnemyAttacks
	gfx.drawArc(self.x + 17, self.y - 12, 5, 0, fillRatio * 360)
end