import "actor"

local gfx <const> = playdate.graphics
local timeBetweenAttacks <const> = 4

Enemy = class(Actor, function(e, file, name, hp, turnSpeed)
	Actor.init(e, file, name, hp)
	e.turnSpeed = turnSpeed
	e.attackTimer = math.random() * timeBetweenAttacks * 0.5
end)

-- Use a callback
function Enemy:updateAttackTimer(elapsed, callback)
	self.attackTimer += elapsed
	if self.attackTimer >= timeBetweenAttacks then
		self:animateAttack(-20)
		self.attackTimer = 0
		callback(self)
	end

	local fillRatio = self.attackTimer / timeBetweenAttacks
	gfx.drawArc(self.x + 17, self.y - 12, 5, 0, fillRatio * 360)
end