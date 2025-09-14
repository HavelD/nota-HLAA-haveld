moduleInfo = {
	name = "pathDebugWidget",
	desc = "Path debug lines",
	author = "haveld",
	date = "2025-09-15",
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
	widgetHandler:RegisterGlobal('path_show', Update)
end

function widget:GameFrame(n)
end

function widget:DrawWorld()
	for instanceKey, instanceData in pairs(instances) do		
        if (instanceData.pathData ~= nil) then
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
			
            local path = instanceData.pathData.path
            if (path ~= nil) then			
                glColor(1, 0, 0, 0.2)
                
                for i = 1, #path - 1 do
                    local p1 = path[i]
                    local p2 = path[i + 1]
                    DrawLine({p1.x,p1.y,p1.z}, {p2.x,p2.y,p2.z})
                end
            end

            local dev = instanceData.pathData.developer
            if (dev ~= nil) then
                glColor(1, 0, 0, 0.2)
                
                local square = {
                    Vec3(-10, 0, -10),
                    Vec3(10, 0, -10),
                    Vec3(10, 0, 10),
                    Vec3(-10, 0, 10),
                    Vec3(-10, 0, -10),
                }

                local function DrawSquare(center)
                    for i = 1, #square - 1 do
                        local p1 = square[i] + center
                        local p2 = square[i + 1] + center
                        DrawLine( {p1.x, p1.y, p1.z}, {p2.x, p2.y, p2.z} )
                    end
                end
                
                glColor(1, 0, 0, 0.7)
                DrawSquare(dev.startPosition)
                DrawSquare(dev.endPosition)
                glColor(1, 1, 0, 0.7)
                DrawSquare(dev.safeStart)
                DrawSquare(dev.safeEnd)  
            end
        end
    end
	glColor(1, 0, 0, 1)
end

--- Upravovanim tohto suboru sa menili veci v hre - Farba