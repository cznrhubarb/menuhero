
------------
-- Playdate
------------
local gfx <const> = playdate.graphics

function playdate.graphics.drawInvertedText(...)
	local originalDrawMode = gfx.getImageDrawMode()
	gfx.setImageDrawMode(gfx.kDrawModeInverted)
	gfx.drawText(...)
	gfx.setImageDrawMode(originalDrawMode)
end

------------
-- Math
------------

function math.clamp(a, min, max)
    if min > max then
        min, max = max, min
    end
    return math.max(min, math.min(max, a))
end

------------
-- Table
------------

function table.findIndex(tbl, value)
	for idx, v in pairs(tbl) do
		if v == value then
			return idx
		end
	end
	
	-- Returning -1 even though maybe 0 is more idiomatic in Lua?
	return -1
end

function table.removeByValue(tbl, value)
	table.remove(tbl, table.findIndex(tbl, value))
end

-- function table.random(tbl)
-- 	return tbl[math.random(#tbl)]
-- end
