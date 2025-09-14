local sensorInfo = {
	name = "FollowPath-OLD",
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
				name = "selectedUnits", -- relative formation
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "{}",
			},
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
local THRESHOLD_STEP = 25
local THRESHOLD_DEFAULT = 50

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit

local getHeight = Spring.GetGroundHeight

local function ClearState(self)
	self.threshold = THRESHOLD_DEFAULT
	self.currentWaypointIndex = 1
	self.unitWaypoints = {} -- track current waypoint for each unit
end

function Run(self, units, parameter)
	-->>-------------DEBUG
	-- local path = parameter.pathArray
	
	-- for _, unitID in ipairs(units) do
	-- 	Spring.Echo("Unit ID:", unitID)
	-- end

	-- Spring.Echo("Path Points size:", #path)
	-- for _, pos in ipairs(path) do
	-- 	Spring.Echo("Path Point:", pos.x, pos.y, pos.z)
	-- end
	--<<-------------DEBUG

	-->>-------------TEMP
	self.threshold = THRESHOLD_DEFAULT
	--<<*------------TEMP

	local path = parameter.pathArray -- array of Vec3
	local useSelected = false
	if (parameter.selectedUnits ~= nil and type(parameter.selectedUnits) == "table" and #parameter.selectedUnits > 0) then
		Spring.Echo("FollowPath: Using selected units for path following.")
		useSelected = true
	else
		Spring.Echo("FollowPath: Using all command units for path following.")
	end
	local selectedUnits = useSelected and parameter.selectedUnits or units-- array of unit IDs

	-->>-------------FIXING Y coordinate
	for i, pos in ipairs(path) do
		pos.y = getHeight(pos.x, pos.z)
	end
	--<<-------------FIXING Y coordinate

	
	-- validation
	if not path or #path == 0 then
		Logger.warn("FollowPath", "No path provided or path is empty")
		return FAILURE
	end
	
	-- initialize unit waypoint tracking if not exists
	if not self.unitWaypoints then
		self.unitWaypoints = {}
	end
	
	-- pick the spring command implementing the move
	local cmdID = CMD.MOVE
	
	local allUnitsFinished = true

	-- process each unit individually
	for u = 1, #selectedUnits do
		local unitID = selectedUnits[u]
		
		-- initialize waypoint index for this unit if not exists
		if not self.unitWaypoints[unitID] then
			self.unitWaypoints[unitID] = 1
		end

		local currentWaypointIndex = self.unitWaypoints[unitID]

		-- check if unit has finished the path
		if currentWaypointIndex <= #path then
			-- if unit has a path still to follow and is not finished
		
			allUnitsFinished = false
			
			-- get current unit position
			local unitX, unitY, unitZ = SpringGetUnitPosition(unitID)
			if unitX ~= nil then
				-- unit still exists (does live) -- maybe Spring.ValidUnitID ??

				local unitPosition = Vec3(unitX, unitY, unitZ)
				local targetWaypoint = path[currentWaypointIndex]
				
				-- check if unit reached current waypoint
				-- local distance = unitPosition:Distance(targetWaypoint)
				local distance = math.sqrt((unitPosition.x - targetWaypoint.x)^2 + (unitPosition.z - targetWaypoint.z)^2) -- Ignoring Height
				Spring.Echo("FollowPath: Unit " .. unitID .. " distance to waypoint " .. currentWaypointIndex .. " is " .. distance)
				if distance < self.threshold then
					-- move to next waypoint
					self.unitWaypoints[unitID] = currentWaypointIndex + 1
					
					-- check if there's a next waypoint
					if self.unitWaypoints[unitID] <= #path then
						local nextWaypoint = path[self.unitWaypoints[unitID]]
						SpringGiveOrderToUnit(unitID, cmdID, nextWaypoint:AsSpringVector(), {})
					end
				else
					-- still moving to current waypoint, make sure order is given
					SpringGiveOrderToUnit(unitID, cmdID, targetWaypoint:AsSpringVector(), {})
				end
			end
		end
	end
	
	-- return SUCCESS if all units finished their paths
	if allUnitsFinished then
		return SUCCESS
	else
		return RUNNING
	end
	return SUCCESS
end


function Reset(self)
	ClearState(self)
end
