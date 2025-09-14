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

-- Helper functions for coordinate conversion
--- @description Convert world coordinates to grid indices
--- @param worldPos table Vec3 world position
--- @param stepSize number Grid step size from safegrid
--- @return table Grid indices {i, j} or nil if invalid
local function worldToGrid(worldPos, stepSize)
    if not worldPos or not stepSize or stepSize <= 0 then
        return nil
    end
    
    -- Convert world coordinates to grid indices
    -- Assuming grid starts at (0, 0) in world coordinates
    local gridI = math.floor(worldPos.z / stepSize) + 1  -- Z to I (row)
    local gridJ = math.floor(worldPos.x / stepSize) + 1  -- X to J (column)

    return {gridI, gridJ}
end

--- @description Convert grid indices to world coordinates
--- @param gridPos table Grid indices {i, j}
--- @param stepSize number Grid step size from safegrid
--- @return table Vec3 world position or nil if invalid
local function gridToWorld(gridPos, stepSize)
    if not gridPos or not stepSize or stepSize <= 0 then
        return nil
    end
    
    local gridI, gridJ = gridPos[1], gridPos[2]
    
    -- Convert grid indices back to world coordinates (center of grid cell)
    local worldX = (gridJ - 1) * stepSize + stepSize / 2
    local worldZ = (gridI - 1) * stepSize + stepSize / 2
    local worldY = getHeight(worldX, worldZ)
    
    return Vec3(worldX, worldY, worldZ)
end

--- @description Create binary grid from safegrid heightmap
--- @param safegrid table Safegrid with developer.gridHeightMap and developer.threshold
--- @return table 2D binary grid where true = safe, false = unsafe
local function createBinaryGrid(safegrid)
    if not safegrid or not safegrid.developer or 
       not safegrid.developer.gridHeightMap or 
       not safegrid.developer.threshold then
        Logger.warn("FindSafePath", "Invalid safegrid structure")
        return nil
    end
    
    local heightMap = safegrid.developer.gridHeightMap
    local threshold = safegrid.developer.threshold
    local binaryGrid = {}
    
    for i = 1, #heightMap do
        binaryGrid[i] = {}
        for j = 1, #heightMap[i] do
            -- Points below threshold are safe
            binaryGrid[i][j] = heightMap[i][j] < threshold
        end
    end
    
    return binaryGrid
end

--- @description Find the closest safe point to a given grid position using expanding circle search
--- @param gridPos table Grid position {i, j} to search from
--- @param binaryGrid table 2D binary grid where true = safe, false = unsafe
--- @param maxRadius number Maximum search radius (optional, defaults to max grid dimension)
--- @return table Closest safe grid position {i, j} or nil if none found
local function findClosestSafePoint(gridPos, binaryGrid, maxRadius)
    if not gridPos or not binaryGrid then
        return nil
    end
    
    local gridHeight = #binaryGrid
    local gridWidth = gridHeight > 0 and #binaryGrid[1] or 0
    
    if gridHeight == 0 or gridWidth == 0 then
        return nil
    end
    
    local startI, startJ = gridPos[1], gridPos[2]
    
    -- If the current position is already safe, return it
    if startI >= 1 and startI <= gridHeight and startJ >= 1 and startJ <= gridWidth and
       binaryGrid[startI][startJ] then
        return gridPos
    end
    
    -- Set maximum search radius
    maxRadius = maxRadius or math.max(gridHeight, gridWidth)
    
    -- Search in expanding circles
    for radius = 1, maxRadius do
        -- Check all points at the current radius
        for di = -radius, radius do
            for dj = -radius, radius do
                -- Only check points that are exactly at the current radius (on the circle perimeter)
                local distance = math.max(math.abs(di), math.abs(dj))
                if distance == radius then
                    local checkI = startI + di
                    local checkJ = startJ + dj
                    
                    -- Check if position is within bounds and safe
                    if checkI >= 1 and checkI <= gridHeight and 
                       checkJ >= 1 and checkJ <= gridWidth and
                       binaryGrid[checkI][checkJ] then
                        return {checkI, checkJ}
                    end
                end
            end
        end
    end
    
    -- No safe point found
    return nil
end

-- maxheight = core.MissionInfo().areaHeight

--- @description return a safe path between two positions using BFS
--- @param startPoint table The starting position as {i, j} indices in the grid.
--- @param endPoint table The ending position as {i, j} indices in the grid.
--- @param grid table A 2D binary grid representing safe (true) and unsafe (false) areas.
--- @return table A table representing the calculated path as grid indices. Returns an empty table if no path found.
function bfs(startPoint, endPoint, grid)
    if not grid or not startPoint or not endPoint then
        return {}
    end
    
    local gridHeight = #grid
    local gridWidth = gridHeight > 0 and #grid[1] or 0
    
    if gridHeight == 0 or gridWidth == 0 then
        return {}
    end
    
    local startI, startJ = startPoint[1], startPoint[2]
    local endI, endJ = endPoint[1], endPoint[2]
    
    -- Check bounds
    if startI < 1 or startI > gridHeight or startJ < 1 or startJ > gridWidth or
       endI < 1 or endI > gridHeight or endJ < 1 or endJ > gridWidth then
        return {}
    end
    
    -- Check if start and end are safe
    if not grid[startI][startJ] or not grid[endI][endJ] then
        return {}
    end
    
    -- If start equals end
    if startI == endI and startJ == endJ then
        return {startPoint}
    end
    
    -- BFS setup
    local queue = {{startI, startJ}}
    local visited = {}
    local parent = {}
    
    -- Initialize visited grid
    for i = 1, gridHeight do
        visited[i] = {}
        parent[i] = {}
        for j = 1, gridWidth do
            visited[i][j] = false
            parent[i][j] = nil
        end
    end
    
    visited[startI][startJ] = true
    
    -- Directions: up, down, left, right, and diagonals
    local directions = {
        {-1, 0}, {1, 0}, {0, -1}, {0, 1},  -- cardinal
        {-1, -1}, {-1, 1}, {1, -1}, {1, 1}  -- diagonal
    }
    
    local queueIndex = 1
    
    while queueIndex <= #queue do
        local current = queue[queueIndex]
        local curI, curJ = current[1], current[2]
        queueIndex = queueIndex + 1
        
        -- Check if we reached the target
        if curI == endI and curJ == endJ then
            -- Reconstruct path
            local path = {}
            local pathI, pathJ = endI, endJ
            
            while pathI and pathJ do
                table.insert(path, 1, {pathI, pathJ})
                local parentCell = parent[pathI][pathJ]
                if parentCell then
                    pathI, pathJ = parentCell[1], parentCell[2]
                else
                    break
                end
            end
            
            return path
        end
        
        -- Explore neighbors
        for _, dir in ipairs(directions) do
            local newI = curI + dir[1]
            local newJ = curJ + dir[2]
            
            -- Check bounds and if cell is safe and not visited
            if newI >= 1 and newI <= gridHeight and newJ >= 1 and newJ <= gridWidth and
               grid[newI][newJ] and not visited[newI][newJ] then
                
                visited[newI][newJ] = true
                parent[newI][newJ] = {curI, curJ}
                table.insert(queue, {newI, newJ})
            end
        end
    end
    
    -- No path found
    return {}
end


--- @description return a safe path between two positions
--- @param startpos table|number The starting position as a Vec3 or a unit ID.
--- @param endpos table|number The ending position as a Vec3 or a unit ID.
--- @param safegrid Peaks.lua output - specifically we will use "stepSize", "developer.gridHeightMap" and "developer.threshold"
--- @return table A table representing the calculated path. Returns an empty table if the input is invalid.
return function(startPosition, endPosition, safegrid)
    local startpos = startPosition
    local endpos = endPosition

    if safegrid == nil then
        Logger.warn("FindSafePath", "safegrid parameter is nil.")
        return {}
    end

    if type(startpos) == "number" then
        local x,y,z = SpringGetUnitPosition(startpos)
        startpos = Vec3(x,y,z)
    elseif type(startpos) ~= "table" then
        Spring.Echo("FindSafePath: Invalid start position type:", type(startpos))
        return {}
    end

    if type(endpos) == "number" then
        local x,y,z = SpringGetUnitPosition(endpos)
        endpos = Vec3(x,y,z)
    elseif type(endpos) ~= "table" then
        Spring.Echo("FindSafePath: Invalid end position type:", type(endpos))   
        return {}
    end

    if startpos == nil or endpos == nil then
        Logger.warn("FindSafePath", "Start or end position is nil.")
        return {}
    end

    -- Validate safegrid structure
    if not safegrid.stepSize or not safegrid.developer then
        Logger.warn("FindSafePath", "Invalid safegrid structure - missing stepSize or developer data")
        return {}
    end

    -- Step 1: Create binary grid from safegrid
    local binaryGrid = createBinaryGrid(safegrid)
    if not binaryGrid then
        Logger.warn("FindSafePath", "Failed to create binary grid")
        return {}
    end

    -- Step 2: Convert world positions to grid indices
    local startGridPos = worldToGrid(startpos, safegrid.stepSize)
    local endGridPos = worldToGrid(endpos, safegrid.stepSize)
    
    if not startGridPos or not endGridPos then
        Logger.warn("FindSafePath", "Failed to convert positions to grid coordinates")
        return {}
    end

    -- Step 3: Check if positions are within map bounds
    local gridHeight = #binaryGrid
    local gridWidth = gridHeight > 0 and #binaryGrid[1] or 0
    
    if startGridPos[1] < 1 or startGridPos[1] > gridHeight or 
       startGridPos[2] < 1 or startGridPos[2] > gridWidth or
       endGridPos[1] < 1 or endGridPos[1] > gridHeight or 
       endGridPos[2] < 1 or endGridPos[2] > gridWidth then
        Logger.warn("FindSafePath", "Start or end position is outside grid bounds")
        return {}
    end

    -- Step 4: Find safe positions for start and end points
    -- If start position is not safe, find closest safe point
    if not binaryGrid[startGridPos[1]][startGridPos[2]] then
        Spring.Echo("FindSafePath: Start position is not safe, searching for closest safe point")
        local safeStartPos = findClosestSafePoint(startGridPos, binaryGrid)
        if not safeStartPos then
            Logger.warn("FindSafePath", "No safe point found near start position")
            return {}
        end
        startGridPos = safeStartPos
        Spring.Echo(string.format("FindSafePath: Found safe start position at grid [%d, %d]", startGridPos[1], startGridPos[2]))
    end
    
    -- If end position is not safe, find closest safe point
    if not binaryGrid[endGridPos[1]][endGridPos[2]] then
        Spring.Echo("FindSafePath: End position is not safe, searching for closest safe point")
        local safeEndPos = findClosestSafePoint(endGridPos, binaryGrid)
        if not safeEndPos then
            Logger.warn("FindSafePath", "No safe point found near end position")
            return {}
        end
        endGridPos = safeEndPos
        Spring.Echo(string.format("FindSafePath: Found safe end position at grid [%d, %d]", endGridPos[1], endGridPos[2]))
    end

    -- Step 5: Call BFS to find path
    local gridPath = bfs(startGridPos, endGridPos, binaryGrid)
    
    if #gridPath == 0 then
        Logger.warn("FindSafePath", "No safe path found between positions")
        return {}
    end

    -- Step 6: Convert grid path back to world coordinates
    local worldPath = {}
    for i, gridPos in ipairs(gridPath) do
        local worldPos = gridToWorld(gridPos, safegrid.stepSize)
        if worldPos then
            table.insert(worldPath, worldPos)
        else
            Logger.warn("FindSafePath", "Failed to convert grid position back to world coordinates")
            return {}
        end
    end

    return {
        path = worldPath, 
        developer = {
            startPosition = startpos, 
            endPosition = endpos,
            safeStart = gridToWorld(startGridPos, safegrid.stepSize),
            safeEnd = gridToWorld(endGridPos, safegrid.stepSize)
        }
    }
end
