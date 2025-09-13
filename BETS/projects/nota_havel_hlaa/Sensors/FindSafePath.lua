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

-- maxheight = core.MissionInfo().areaHeight

--- @description return a safe path between two positions
--- @param params table A table containing the parameters for the function:
---   @field startpos table|number The starting position as a Vec3 or a unit ID.
---   @field endpos table|number The ending position as a Vec3 or a unit ID.
--- @return table A table representing the calculated path. Returns an empty table if the input is invalid.
return function(params)
    if params == nil then
        params = {}
    end

    if params.startpos == nil or params.endpos == nil then
        Logger.warn("FindSafePath", "No startPos provided")
        return {}
    end

    local startPos = type(params.startPos) == "number" and Spring.GetUnitPosition(params.startPos) or params.startPos
    local endPos = type(params.endPos) == "number" and Spring.GetUnitPosition(params.endPos) or params.endPos

    local path = {startPos, endPos} -- temp straight line
	return path
end
