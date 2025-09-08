moduleInfo = {
	name = "testingDrawDebugLines",
	desc = "testing local development",
	author = "haveld", -- original: "PepeAmpere"
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
	widgetHandler:RegisterGlobal('testDebug_update', Update)
end

function widget:GameFrame(n)
end

function widget:DrawWorld()
	for instanceKey, instanceData in pairs(instances) do		
		if (instanceData.startPos ~= nil and instanceData.endPos ~= nil) then
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
			
			glColor(1, 1, 0, 0.5)
			
			DrawLine(
				{
					instanceData.startPos.x,
					instanceData.startPos.y,
					instanceData.startPos.z
				}, 
				{
					instanceData.endPos.x,
					instanceData.endPos.y,
					instanceData.endPos.z
				}
			)
		end
	end
	glColor(1, 0, 0, 1)
end

--- Upravovanim tohto suboru sa menili veci v hre - Farba