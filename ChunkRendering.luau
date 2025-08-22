--// made by binx & tom
--// handles chunk-based rendering for workspace objects

--// important note:
--// X and Y on a vector2
--//         =
--// X and Z on a vector3

repeat task.wait(1) until game:IsLoaded()

local LocalPlayer = game.Players.LocalPlayer
-- local DebugModule = require(LocalPlayer.PlayerGui:WaitForChild("DebugInfo").DebugModule)
local RunService = game:GetService("RunService")
local InsertService = game:GetService("InsertService")

-- measured in studs for both of these
local CHUNK_SIZE_X = 100
local CHUNK_SIZE_Y = 100

local CHUNK_HEIGHT = 1000

local MAP_SIZE_WIDTH = 10000
local MAP_SIZE_HEIGHT = 10000

local PARENTS_TO_SKIP = {workspace.Planes, workspace.MiscVehicles}
local SKIPPING_INSTANCES = {}

local renderDistance = 3

--[[
We have our own debugging tools. You can ignore this.
DebugModule.ProfilerTitle("Rendering")
local debugRenderDistance = DebugModule.ProfilerConstructor("renderDistance")
local debugRenderedChunk = DebugModule.ProfilerConstructor("currentChunk")
local debugRenderedChunk3D = DebugModule.ProfilerConstructor("currentChunk3D")
local debugChunksInRenderDistance = DebugModule.ProfilerConstructor("chunksInRenderDistance")
]]

-- Returns the start and end positions of the provided chunk.
local function GetChunkTransform(chunk: Vector2)
	local chunkX = {
		start = chunk.X * CHUNK_SIZE_X - (CHUNK_SIZE_X / 2),
		finish = chunk.X * CHUNK_SIZE_X + (CHUNK_SIZE_X / 2),
	}

	local chunkY = {
		start = chunk.Y * CHUNK_SIZE_Y - (CHUNK_SIZE_Y / 2),
		finish = chunk.Y * CHUNK_SIZE_Y + (CHUNK_SIZE_Y / 2),
	}
	
	return chunkX, chunkY
end

-- Returns parts in the provided chunk.
local function GetObjectsInChunk(chunk: Vector2): {BasePart}
	local bounds = Vector3.new(CHUNK_SIZE_X, CHUNK_SIZE_Y, CHUNK_HEIGHT)
	local chunkCenter = Vector3.new(chunk.X * CHUNK_SIZE_X, chunk.Y * CHUNK_SIZE_Y, CHUNK_HEIGHT)
	local objects = workspace:GetPartBoundsInBox(CFrame.new(chunkCenter), bounds)
	
	for i, inst: Instance in objects do
		if table.find(SKIPPING_INSTANCES, inst) then
			table.remove(objects, i)
		end
	end
	
	return objects
end

-- Returns specfic types of Instances in a chunk.
local function GetInstancesOfTypeInChunk(chunk: Vector2, instanceType: string): {Instance}
	local bounds = Vector3.new(CHUNK_SIZE_X, CHUNK_SIZE_Y, CHUNK_HEIGHT)
	local chunkCenter = Vector3.new(chunk.X * CHUNK_SIZE_X, chunk.Y * CHUNK_SIZE_Y, CHUNK_HEIGHT)
	local _objects = workspace:GetPartBoundsInBox(CFrame.new(chunkCenter), bounds)
	local objects = {}

	for index, object in _objects do
		if object:IsA(instanceType) and (not table.find(SKIPPING_INSTANCES, object)) then
			table.insert(objects, object)
		end
	end
	
	return objects
end

-- Gets the chunk at a certain point.
local function GetChunkFromPoint(point: Vector3): Vector2
	return Vector2.new(math.floor(point.X / 100), math.floor(point.Z / 100))
end

-- Gets the chunks in render distance of origin.
local function GetChunksInRenderDistance(origin: Vector3): {Vector2}
	local currentChunk = GetChunkFromPoint(origin)
	local chunks: {Vector2} = {}
	
	for x = currentChunk.X - (renderDistance / 2), currentChunk.X + (renderDistance / 2), 1 do
		for y = x - (renderDistance / 2), x + (renderDistance / 2), 1 do
			if not table.find(chunks, Vector2.new(x, y)) then
				table.insert(chunks, Vector2.new(x, y))
			end
		end
	end
	
	return chunks
end

-- Get all chunks
local function GetAllChunks(): {Vector2}
	local chunks = {}

	for x = -(MAP_SIZE_WIDTH / CHUNK_SIZE_X / 2), (MAP_SIZE_WIDTH / CHUNK_SIZE_X / 2), 1 do
		for y = x -(MAP_SIZE_HEIGHT / CHUNK_SIZE_Y / 2 ), x + (MAP_SIZE_HEIGHT / CHUNK_SIZE_Y / 2), 1 do
			if #GetObjectsInChunk(Vector2.new(x, y)) > 0 then
				table.insert(chunks, Vector2.new(x, y))
			end
		end
	end

	return chunks
end

-- Combines tables together.
local function zip(...)
	local tables: {{}} = {...}
	local t = {}

	for i, v in tables do
		if typeof(v) ~= "table" then
			warn("non-table object passed, ignoring")
			continue
		end

		for _, o in v do
			table.insert(t, o)
		end
	end

	return t
end

-- LateUpdate() is called every 0.25 seconds for all of your part-crunching needs.
local function LateUpdate()
	local playerChunk = GetChunkFromPoint(LocalPlayer.Character.HumanoidRootPart.Position)
	local chunks = GetChunksInRenderDistance(LocalPlayer.Character.HumanoidRootPart.Position)
	
	SKIPPING_INSTANCES = {}
	
	for _, i: Instance in PARENTS_TO_SKIP do
		for _, j in i:GetDescendants() do
			table.insert(SKIPPING_INSTANCES, j)
		end
	end

	local chunkCoords = Vector3.new(playerChunk.X * CHUNK_SIZE_X, LocalPlayer.Character.HumanoidRootPart.Position.Y, playerChunk.Y * CHUNK_SIZE_Y)

  --[[
  Read about this above
	debugRenderDistance:Update(renderDistance)
	debugRenderedChunk:Update(playerChunk)
	debugRenderedChunk3D:Update(chunkCoords)
	debugChunksInRenderDistance:Update(#chunks)
  ]]
	
	for _, chunk: Vector2 in GetAllChunks() do
		if table.find(chunks, chunk) then
			-- significant chunk, increase quality
			local Meshes: {MeshPart} = GetInstancesOfTypeInChunk(chunk, "MeshPart")
			local BaseParts: {BasePart} = GetInstancesOfTypeInChunk(chunk, "BasePart")
			local Unions: {UnionOperation} = GetInstancesOfTypeInChunk(chunk, "UnionOperation")
			local Lights = GetInstancesOfTypeInChunk(chunk, "Light")

			for _, Mesh: MeshPart in Meshes do

				if Mesh.RenderFidelity ~= Enum.RenderFidelity.Precise then
					local newMesh = InsertService:CreateMeshPartAsync(
						Mesh.MeshId, 
						Enum.CollisionFidelity.Hull, 
						Enum.RenderFidelity.Precise
					)
					
					newMesh.Name = Mesh.Name
					newMesh.Parent = Mesh.Parent
					newMesh.CFrame = Mesh.CFrame
					
					Mesh:Destroy()
				end	
			end

			for _, Light: Light in Lights do
				if Light:IsA("Light") then
					Light.Enabled = true
				end
			end
		else
			-- insignificant chunk, decrease quality
			local Meshes: {MeshPart} = GetInstancesOfTypeInChunk(chunk, "MeshPart")
			local BaseParts: {BasePart} = GetInstancesOfTypeInChunk(chunk, "BasePart")
			local Unions: {UnionOperation} = GetInstancesOfTypeInChunk(chunk, "UnionOperation")
			local Lights = GetInstancesOfTypeInChunk(chunk, "Light")
			
			for _, Mesh: MeshPart in Meshes do
				Mesh.Transparency = 1
        
				if Mesh.RenderFidelity ~= Enum.RenderFidelity.Performance then
					local newMesh = InsertService:CreateMeshPartAsync(
						Mesh.MeshId, 
						Enum.CollisionFidelity.Box, 
						Enum.RenderFidelity.Performance
					)

					newMesh.Name = Mesh.Name
					newMesh.Parent = Mesh.Parent
					newMesh.CFrame = Mesh.CFrame

					Mesh:Destroy()
				end	
			end

			for _, Light: Light in Lights do
				if Light:IsA("Light") then
					Light.Enabled = false
				end
			end
		end
	end
end

coroutine.wrap(function()
	repeat task.wait(1) until game:IsLoaded()
	
	while true do
		LateUpdate()
		task.wait(0.25)
	end
end)()
