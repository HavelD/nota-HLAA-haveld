moduleInfo = {
	name = "hillsDebugWidget",
	desc = "Hills debug widget - showing all points of mesh - highlighting Above-Threshold hills and showing selected peaks",
	author = "Haveld",
	date = "2025-09-10",
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

local function Update(lineID, hillsData)
	instances[lineID] = hillsData
end

function widget:Initialize()
	widgetHandler:RegisterGlobal('hills_show', Update)
end

function widget:GameFrame(n)
end

function widget:DrawWorld()
	for instanceKey, instanceData in pairs(instances) do		
		if (instanceData.pointsData ~= nil) then
			local function Line(a, b)

				glVertex(a[1], a[2], a[3])
				glVertex(b[1], b[2], b[3])
			end
			
			local function DrawLine(a, b)
				glLineStipple(false)
				glLineWidth(20)
				glBeginEnd(GL_LINE_STRIP, Line, a, b)
				glLineStipple(false)
			end

			local function DrawDot(a)
				local v = Vec3(5, 0, 5)
				local h = Vec3(0, 0, 0) --Vec3(0, 20, 0)
				local start = a + h - v
				local endPos = a + h + v
				DrawLine({start.x, start.y, start.z}, {endPos.x, endPos.y, endPos.z})
            end
            
            for i = 1, #instanceData.pointsData do
				local point = instanceData.pointsData[i]
				local pos = point.position
				local pointType = point.pointType

				if pos == nil or pointType == nil then
					Spring.Echo("Missing data for hill point:", i, pos, pointType)
					break
				end

				if pointType == "base" then
					glColor(1, 1, 1, 0.3) -- white
				elseif pointType == "threshold" then
					glColor(0.5, 0.5, 1, 0.6) -- lightBlue
				elseif pointType == "max" then
					glColor(1, 0.5, 0, 0.8) -- orange
				elseif pointType == "peak" then
					glColor(1, 0, 0, 1) -- red
				end
				DrawDot(pos)
			end
		else
			Spring.Echo("Missing data for hill positions:", instanceKey, instanceData.pointsData)
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