local tmr <const> = playdate.timer

function cameraShake(duration, magnitude)
	local function setOffset()
		playdate.display.setOffset(math.random() * magnitude - magnitude/2, math.random() * magnitude - magnitude/2)
	end
	local shaker = tmr.keyRepeatTimerWithDelay(50, 50, setOffset)

	local function stopShake()
		shaker:remove()
		playdate.display.setOffset(0, 0)
	end
	tmr.new(duration, stopShake)
end
