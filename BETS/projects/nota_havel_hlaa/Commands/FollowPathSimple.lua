local sensorInfo = {
	name = "FollowPath",
	desc = "Follow a path defined by a series of points",
	author = "haveld",
	date = "2025-09-12",
	license = "notAlicense",
}

function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Move to defined position following a path",
		parameterDefs = {
			{ 
				name = "pathArray", -- relative formation
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "",
			}
		}
	}
end

-- constants
local THRESHOLD_DEFAULT = 50

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit

local getHeight = Spring.GetGroundHeight
local isAlive = Spring.ValidUnitID

local function ClearState(self)
	self.path_set = false
end

function Run(self, units, parameter)
	local path = parameter.pathArray -- array of Vec3
	-->>-------------FIXING Y coordinate
	for i, pos in ipairs(path) do
		pos.y = getHeight(pos.x, pos.z)
	end
	--<<-------------FIXING Y coordinate
    local last_position = path[#path]

	-- validation
	if not path or #path == 0 then
		Logger.warn("FollowPath", "No path provided or path is empty")
		return FAILURE
	end
	
    -- pick the spring command implementing the move
	local cmdID = CMD.MOVE

    Spring.Echo("FollowPath: Start of function")

     -- set the path only once

    if self.path_set ~= nil or self.path_set == false then
        Spring.Echo("FollowPath: Setting path with " .. #path .. " waypoints for " .. #units .. " units.")
        self.path_set = true

        for u = 1, #units do
            for p=1, #path do
                local unitID = units[u]
                local waypoint = path[p]
                SpringGiveOrderToUnit(unitID, cmdID, {waypoint.x, waypoint.y, waypoint.z}, {"shift"})
            end
        end
    else
        Spring.Echo("FollowPath: Path already set, skipping setting it again.")
    end

    Spring.Echo("FollowPath: Checking if all units have reached the last waypoint.")

    for u = 1, #units do
        local unitID = units[u]
        if isAlive(unitID)then
             -- get current unit position
            local unitX, unitY, unitZ = SpringGetUnitPosition(unitID)
            local distSq = (unitX - last_position.x)^2 + (unitZ - last_position.z)^2
            if distSq > THRESHOLD_DEFAULT then
                -- unit not yet at the last waypoint
                Spring.Echo("FollowPath: Unit " .. unitID .. " is still moving towards the last waypoint.")
                return RUNNING
            end
        end
    end
    Spring.Echo("FollowPath: All units have reached the last waypoint.")
    return SUCCESS
end


function Reset(self)
	ClearState(self)
end
