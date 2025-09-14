local sensorInfo = {
	name = "SafePath",
	desc = "Find a safe path between two positions",
	author = "haveld",
	date = "2025-09-13",
	license = "notAlicense",
}

local EVAL_PERIOD_DEFAULT = 0 -- acutal, no caching

function getInfo()
	return {
		period = EVAL_PERIOD_DEFAULT 
	}
end

-- speedups
local getHeight = Spring.GetGroundHeight

local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ

local sizingFix = 2
local checkPerSquare = 2

-- speedups
local SpringGetUnitPosition = Spring.GetUnitPosition

-- maxheight = core.MissionInfo().areaHeight

--- @description return a safe path between two positions
--- @param startpos table|number The starting position as a Vec3 or a unit ID.
--- @param endpos table|number The ending position as a Vec3 or a unit ID.
--- @return table A table representing the calculated path. Returns an empty table if the input is invalid.
return function(startPosition, endPosition)
    local startpos = startPosition
    local endpos = endPosition

    if type(startpos) == "number" then
        local x,y,z = SpringGetUnitPosition(startpos)
        startpos = Vec3(x,y,z)
    elseif type(startpos) ~= "table" then
        Spring.Echo("FindSafePath: Invalid start position type:", type(startpos))
    end

    if type(endpos) == "number" then
        local x,y,z = SpringGetUnitPosition(endpos)
        endpos = Vec3(x,y,z)
    elseif type(endpos) ~= "table" then
        Spring.Echo("FindSafePath: Invalid end position type:", type(endpos))   
    end

    if startpos == nil or endpos == nil then
        Logger.warn("FindSafePath", "Start or end position is nil.")
        return {}
    end

    local path = {startpos, endpos} -- temp straight line
	return path
end
