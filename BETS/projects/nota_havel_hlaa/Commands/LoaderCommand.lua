local sensorInfo = {
	name = "LoaderCommanding",
	desc = "Set Loader to load or unload unit - with shift-preventing unload",
	author = "haveld",
	date = "2025-09-12",
	license = "notAlicense",
}


function getInfo()
	return {
		onNoUnits = SUCCESS, -- instant success
		tooltip = "Command loader units to load or unload target units",
		parameterDefs = {
			{
				name = "fleet", -- loader units
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "{}",
			},
			{ 
				name = "targetUnitID",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "",
			},
			{ 
				name = "load",
				variableType = "expression",
				componentType = "editBox",
				defaultValue = "true",
			}
		}
	}
end

-- speed-ups
local SpringGetUnitPosition = Spring.GetUnitPosition
local SpringGiveOrderToUnit = Spring.GiveOrderToUnit

-- constants
local THRESHOLD_DIST = 25

local function ClearState(self)
end

function Run(self, units, parameter)
	local targetUnitID = parameter.targetUnitID -- can be single ID or array of IDs
	local load = parameter.load -- boolean
	local fleet = parameter.fleet -- array of loader unit IDs, if empty use all selected units

	-- convert single targetUnitID to array for uniform handling
	local targetUnitIDs = {}
	if type(targetUnitID) == "table" then
		targetUnitIDs = targetUnitID
	else
		targetUnitIDs = {targetUnitID}
	end

	if (fleet and #fleet > 0) then
		Spring.Echo("LoaderCommand: Using specified fleet of size " .. #fleet)
	else
		Spring.Echo("LoaderCommand: No fleet specified, using all selected units")
	end

	local loaderUnits = (fleet and #fleet > 0) and fleet or units
	local loaderUnits = Sensors.FilterUnitsByCategory(loaderUnits, Categories.Common.transports)
	
	-- check if we have matching counts
	if #targetUnitIDs > 1 and #targetUnitIDs ~= #loaderUnits then
		Logger.warn("LoaderCommand", "Number of target units [" .. #targetUnitIDs .. "] must match number of loader units [" .. #loaderUnits .. "] when using multiple targets")
		return FAILURE
	end

	-- check if target units exist
	for i = 1, #targetUnitIDs do
		if not targetUnitIDs[i] or targetUnitIDs[i] == "" then
			Logger.warn("LoaderCommand", "Invalid target unit ID at position " .. i)
			return FAILURE
		end
	end
	
	-- process each loader unit
	for i = 1, #loaderUnits do
		local loaderID = loaderUnits[i]
		local targetID = targetUnitIDs[i]
		
		Spring.Echo("LoaderCommand: Commanding loader unit " .. loaderID .. " to " .. (load and "load" or "unload") .. " target unit " .. targetID)
		-- give appropriate command
		if load then
			SpringGiveOrderToUnit(loaderID, CMD.LOAD_UNITS, {targetID}, {"shift"})
		else
			SpringGiveOrderToUnit(loaderID, CMD.UNLOAD_UNITS, {targetID}, {"shift"}) --  {"shift", "alt"}) -- alt to prevent shift-unload ???
		end
	end
	
	-- return immediate success since we just give commands
	return RUNNING
end


function Reset(self)
	ClearState(self)
end
