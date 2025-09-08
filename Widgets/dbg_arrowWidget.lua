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
            
            -- TODO Change color to blue arrow - dynamic color and opacity based on wind strength
			glColor(0, 0, 1, 0.5)

            -- TODO Create arrow instead of line - Maybe number of arrows with fading color based on the strength
			
            local length = 100 + instanceData.windStrength * 10 -- length based on wind strength
            
            local relativeEndPos = Vec3(
                length * math.cos(instanceData.windAzimuth),
                0,
                length * math.sin(instanceData.windAzimuth)
            )

            DrawLine(
				{
					instanceData.unitPos.x,
					instanceData.unitPos.y,
					instanceData.unitPos.z
				}, 
				{
					instanceData.unitPos.x + relativeEndPos.x,
					instanceData.unitPos.y + relativeEndPos.y,
					instanceData.unitPos.z + relativeEndPos.z
				}
			)
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