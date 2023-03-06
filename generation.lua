-- Services
local ServerStorage = game:GetService("ServerStorage")
	local Configuration = ServerStorage:WaitForChild("Configuration")
	local Events = ServerStorage:WaitForChild("Events")
		local Reload = Events:WaitForChild("Reload")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Dictionaries = ReplicatedStorage:WaitForChild("Dictionaries")
		local BlockDict = require(Dictionaries:WaitForChild("Block"))

local RunService = game:GetService("RunService")

-- Variables
local ores = {
	["Coal"] = BlockDict.blocks.CoalOre
}

local oreData = {
	["Coal"] = {
		["density"] = .15,
		["minVein"] = 2,
		["maxVein"] = 4
	}
}

local loadedOres = {}

local blockTable = BlockDict.blocks

local Parts = workspace:WaitForChild("Parts")

-- CONFIG
local X = Configuration:WaitForChild("X").Value
local Z = Configuration:WaitForChild("Z").Value

local PartSize = Configuration:WaitForChild("PartSize").Value

local intensity = Configuration:WaitForChild("intensity").Value
local bottomPos = Configuration:WaitForChild("bottomPos").Value
local origin_pos = Configuration:WaitForChild("origin_pos").Value
local tree_density = Configuration:WaitForChild("tree_density").Value
local tree_min_height = Configuration:WaitForChild("tree_min_height").Value
local tree_max_height = Configuration:WaitForChild("tree_max_height").Value
local tree_distance = Configuration:WaitForChild("tree_distance").Value

local grid = {}
local structures = {
	Trees = {},
	Ores = {}
}
local stones = {}

local isLoading = false

local function getBlockFromPos(pos:Vector3)
	local b = nil
	for _,block:Model in ipairs(Parts:GetChildren()) do
		if (block.PrimaryPart==nil) then continue end
		local prim = block.PrimaryPart
		local p = prim.Position
		local x, y, z = p.X, p.Y, p.Z
		if (x==pos.X and y==pos.Y and z==pos.Z) then b=block break end
	end
end

local function replaceBlock(blockA:Model,blockB:Model) 
	local pos = blockA.PrimaryPart.Position
	
	local CFramePos = CFrame.new(pos)
	blockB:PivotTo(CFramePos)
	blockB.Parent = blockA.Parent
	
	blockA:Destroy()
end

local function trees()
	-- Simple tree generation
	
	for x=1, X do
		for z=1, Z do
			local xPos = origin_pos.X+(x*PartSize)
			local yPos = origin_pos.Y+math.round((grid[x][z])/PartSize)*PartSize
			local zPos = origin_pos.Z+(z*PartSize)
			
			if (math.random()<tree_density) then
				local structure = {}
				local woods = {}
				
				local height = math.floor(math.random(tree_min_height,tree_max_height))
				local lowestHeight = Vector3.new(xPos,yPos+PartSize,zPos)
				
				-- Looking for nearest trees
				local cancelLoop = false
				
				for _,tree in ipairs(structures.Trees) do
					for _,block:Model in ipairs(tree) do
						local lowestPoint:Model = block
						if (lowestPoint.Name~="lowest") then continue end

						local xDiff = math.abs(lowestPoint.PrimaryPart.Position.X-lowestHeight.X)/3
						local zDiff = math.abs(lowestPoint.PrimaryPart.Position.Z-lowestHeight.Z)/3

						if (xDiff<math.random(5,15) and zDiff<math.random(5,15)) then cancelLoop = true break end
					end
				end
				
				if (cancelLoop==true) then continue end
				
				local currY = yPos+PartSize
				
				for i=1,height do
					local wood = blockTable.Wood.object:Clone()
					if (i==1) then wood.Name = "lowest" end
					if (i==height) then wood.Name = "highest" end
					wood.Parent = Parts
					wood:PivotTo(CFrame.new(
						Vector3.new(
							xPos,
							currY,
							zPos
						)	
					))
					table.insert(structure,wood)
					table.insert(woods,wood)
					currY+=PartSize
					task.wait()
				end
				
				for _,block:Model in ipairs(woods) do
					local pX = block.PrimaryPart.Position.X
					local pY = block.PrimaryPart.Position.Y
					local pZ = block.PrimaryPart.Position.Z
					
					if (block.Name=="highest") then
						local leaf = blockTable.Leaf.object:Clone()
						leaf:PivotTo(CFrame.new(Vector3.new(pX,pY+PartSize,pZ)))
						leaf.Parent = Parts
						table.insert(structure,leaf)
					end
					
					if (math.abs(yPos-pY)>math.round(height*1.4)) then
						local leaf1 = blockTable.Leaf.object:Clone()
						local leaf2 = blockTable.Leaf.object:Clone()
						local leaf3 = blockTable.Leaf.object:Clone()
						local leaf4 = blockTable.Leaf.object:Clone()
						
						leaf1:PivotTo(CFrame.new(Vector3.new(pX-PartSize,pY,pZ)))
						leaf2:PivotTo(CFrame.new(Vector3.new(pX+PartSize,pY,pZ)))
						leaf3:PivotTo(CFrame.new(Vector3.new(pX,pY,pZ-PartSize)))
						leaf4:PivotTo(CFrame.new(Vector3.new(pX,pY,pZ+PartSize)))
						
						leaf1.Parent = Parts
						leaf2.Parent = Parts
						leaf3.Parent = Parts
						leaf4.Parent = Parts
						
						table.insert(structure,leaf1)
						table.insert(structure,leaf2)
						table.insert(structure,leaf3)
						table.insert(structure,leaf4)
					end
					task.wait()
				end
				
				table.insert(structures.Trees,structure)
			end
		end
	end
	
	for _,tree in ipairs(structures.Trees) do
		for _,block in ipairs(tree) do
			block.Name = blockTable.Wood.object.Name
		end
	end
end

local function generateOres()
	-- Generating ores in veins of 1,2 or 3 etc.
	local cords = {"X","Y","Z"}
	
	for _,stone:Model in ipairs(stones) do
		if (not stone) then continue end
		
		local prim = stone.PrimaryPart
		local yPos = prim.Position.Y
		
		if ((yPos)<(bottomPos*.3)) then continue end
		
		if ((yPos)>(bottomPos*.45)) then
			if (math.random()>oreData.Coal.density) then continue end
			
			if (loadedOres["coal"]) then
				loadedOres["coal"] = loadedOres["coal"]+1
			else
				loadedOres["coal"] = 1
			end
			
			local coal = ores.Coal.object:Clone()
			replaceBlock(stone,coal)
			
			local vein = math.random(oreData.Coal.minVein,oreData.Coal.maxVein)
			
			local lastDeposit = coal
			
			for v=1,vein do
				local newCoal = ores.Coal.object:Clone()
				local cord = cords[math.floor(math.random(1,3))]
				local pos = lastDeposit.PrimaryPart.Position
				
				local x = pos.X
				local y = pos.Y
				local z = pos.Z
				
				if (cord=="x") then
					x = x+math.floor(math.random(-1,1)*PartSize)
				elseif (cord=="y") then
					y = y+math.floor(math.random(-1,1)*PartSize)
				elseif (cord=="z") then
					z = z+math.floor(math.random(-1,1)*PartSize)
				end
				
				local block = getBlockFromPos(Vector3.new(x,y,z))
				if (not block) then continue end
				replaceBlock(block,newCoal)
				lastDeposit = block
			end
		end
		task.wait()
	end
end

local function colorPart(pos:Vector3)
	-- Repainting the part depending on their height
	if ((pos.Y)>(bottomPos*.15)) then
		local block = blockTable.Dirt.object:Clone()
		block.Parent = Parts
		block:PivotTo(CFrame.new(pos))
		return
	elseif ((pos.Y)>(bottomPos*.85)) then
		local block = blockTable.Stone.object:Clone()
		block.Parent = Parts
		block:PivotTo(CFrame.new(pos))
		table.insert(stones,block)
		return
	end
	
	local block = blockTable.Rock.object:Clone()
	block.Parent = Parts
	block:PivotTo(CFrame.new(pos))
end

local function generate(_seed)
	if (isLoading==true) then return warn("Terrain is currently loading, please try again later!") end
	isLoading = true
		
	local seed = math.floor(_seed or tick()/math.random(1,50000))
	
	-- generates the first layer into an array
	for x=1, X do
		grid[x] = {}

		for z=1, Z do
			grid[x][z] = math.noise(
				seed/10000,
				(X/100) + x/intensity,
				(Z/100) + z/intensity
			) * intensity
		end
	end
	
	-- stats
	local startTime = tick()
	local totalBlocks = 0
	local bottomBlocks = 0
	local loadedBBlocks = 0
	
	-- loads the terrain
	for x = 1, X do
		for z = 1, Z do
			totalBlocks+=1	
			
			local xPos = origin_pos.X+(x*PartSize)
			local yPos = origin_pos.Y+math.round((grid[x][z])/PartSize)*PartSize
			local zPos = origin_pos.Z+(z*PartSize)
			
			local part = blockTable.Grass.object:Clone()
			part:PivotTo(CFrame.new(Vector3.new(xPos,yPos,zPos)))
			part.Parent = Parts
			
			local currY = part.PrimaryPart.Position.Y
			task.spawn(function()
				if (bottomPos==0) then return end
				bottomBlocks+=1
				task.wait(1)
				
				repeat
					-- Generate blocks until it hits the "bedrock" position
					local waitTime = 1
					
					currY = currY-PartSize
					if (currY<=bottomPos) then break end
					
					if ((currY)<(bottomPos*.75)) then
						waitTime=7
					elseif ((currY)<(bottomPos*.5)) then
						waitTime=5
					elseif ((currY)<(bottomPos*.25)) then
						waitTime=2
					end
					
					totalBlocks+=1
					
					colorPart(Vector3.new(xPos,currY,zPos))
					
					task.wait(waitTime)
					if (currY<=bottomPos) then break end
				until currY<=bottomPos
				loadedBBlocks+=1
			end)
		end
		task.wait()
	end
	
	repeat task.wait(0.5) until loadedBBlocks>=bottomBlocks
	
	trees(seed)
	
	print("Successfully loaded terrain!")
	print("SEED:",seed)
	print("BLOCKS:",totalBlocks)
	print("TIME TOOK:",tick()-startTime)
	print("GRID (X-Z):",tostring(X).."x"..tostring(Z))
	
	isLoading = false
end
