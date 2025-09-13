moduleInfo = {
	name = "arrowWidgetDevelop",
	desc = "Air direction arrow widget",
	author = "Haveld", -- original: "PepeAmpere"
	date = "2025-09-08",
	license = "MIT",
	layer = -1,
	enabled = true
}

function widget:GetInfo()
	return moduleInfo
end


-- get madatory module operators
VFS.Include("modules.lua") -- modules table
VFS.Include(modules.attach.data.path .. modules.attach.data.head) -- attach lib module

-- get other madatory dependencies
attach.Module(modules, "stringExt")
Vec3 = attach.Module(modules, "vec3")

local spEcho = Spring.Echo
local spAssignMouseCursor = Spring.AssignMouseCursor
local spSetMouseCursor = Spring.SetMouseCursor
local spGetGroundHeight = Spring.GetGroundHeight
local spTraceScreenRay = Spring.TraceScreenRay
local spGetUnitPosition = Spring.GetUnitPosition
local glColor = gl.Color
local glRect = gl.Rect
local glTexture	= gl.Texture
local glDepthTest = gl.DepthTest
local glBeginEnd = gl.BeginEnd
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glText = gl.Text
local glLineWidth = gl.LineWidth
local glLineStipple = gl.LineStipple
local glVertex = gl.Vertex
local GL_LINE_STRIP = GL.LINE_STRIP
local max = math.max
local min = math.min

local instances = {}

local function Update(lineID, lineData)
	instances[lineID] = lineData
end

function widget:Initialize()
	widgetHandler:RegisterGlobal('wind_direction_debug', Update)
end

function widget:GameFrame(n)
end

function widget:DrawWorld()
	for instanceKey, instanceData in pairs(instances) do		
		if (instanceData.unitPos ~= nil and instanceData.windAzimuth ~= nil and instanceData.windStrength ~= nil) then
			local function Line(a, b)
				glVertex(a[1], a[2], a[3])
				glVertex(b[1], b[2], b[3])
			end
			
			local function DrawLine(a, b)
				glLineStipple(false)
				glLineWidth(5)
				glBeginEnd(GL_LINE_STRIP, Line, a, b)
				glLineStipple(false)
			end
            
			-- dynamic blue color and opacity based on wind strength
			local strength = instanceData.windStrength or 0
			local alpha = math.min(1, 0.3 + (strength / 10) * 0.7) -- map strength -> [0.3,1]
			-- glColor(0.2, 0.6, 1.0, alpha) -- skipped - setting color for each arrow separately

			-- Number of arrows: 1, 3 or 5 - based on wind strength 
			
			local arrowCount
			if strength < 3 then -- Magic numbers :D - Now i Know i can use [number Game.windMin, number Game.windMax]
				arrowCount = 1
			elseif strength < 7 then
				arrowCount = 3
			else
				arrowCount = 5
			end

			local length = 100 + strength * 10 -- body length based on wind strength

			-- direction unit on XZ plane
			local dirX = math.cos(instanceData.windAzimuth)
			local dirZ = math.sin(instanceData.windAzimuth)

			-- perpendicular unit (to offset left/right arrows)
			local perpX = -dirZ
			local perpZ = dirX

			-- lateral spacing between arrows (tweakable)
			local spacing = 50

			-- head parameters
			local headLen = math.min(length * 0.3, 40)
			local headAngleOffset = math.rad(30) -- makes 60° between head lines

			-- draw arrows centered on the unit position, shifted laterally
			for i = 1, arrowCount do
				local idx = i - (arrowCount + 1) / 2 -- -n .. 0 .. +n
				local offset = idx * spacing

				local scale = (1.0 - 0.5 * math.abs(idx) / ((arrowCount - 1) / 2))

				local startX = instanceData.unitPos.x + perpX * offset
				local startY = instanceData.unitPos.y
				local startZ = instanceData.unitPos.z + perpZ * offset

				local tipX = startX + dirX * length * scale -- arrows further from center are smaller
				local tipY = startY
				local tipZ = startZ + dirZ * length * scale -- arrows further from center are smaller
				
				glColor(0.2, 0.6, 1.0*scale, alpha * scale) -- arrows further from center are lighter in color

				-- body of arrow
				DrawLine({ startX, startY, startZ }, { tipX, tipY, tipZ })

				-- head of arrow
				local headAngle1 = instanceData.windAzimuth + math.pi + headAngleOffset
				local headAngle2 = instanceData.windAzimuth + math.pi - headAngleOffset

				local h1x = tipX + headLen * math.cos(headAngle1)
				local h1z = tipZ + headLen * math.sin(headAngle1)
				DrawLine({ tipX, tipY, tipZ }, { h1x, tipY, h1z })

				local h2x = tipX + headLen * math.cos(headAngle2)
				local h2z = tipZ + headLen * math.sin(headAngle2)
				DrawLine({ tipX, tipY, tipZ }, { h2x, tipY, h2z })
			end
		else
			Spring.Echo("Missing data for wind direction arrow:", instanceKey, instanceData.unitPos, instanceData.windAzimuth, instanceData.windStrength)
		end
	end
	glColor(1, 0, 0, 1) -- probably color reset
end



-- TODO skus:
-- zmen ModuleInfo
-- zmen senzor ID aby citalo tvoje data
-- urpav kresbu na modru sipku
-- V senzore vies upravit to, ze ked zadas celu skupinu, tak vies zistit druh jednotky - najdi commandera a zistis jeho poziciu (asi staci zistit ID commandera)
-- N:\nota_dev_pack_mff\000\SpringData\LuaUI\Widgets\arrowWidget.lua