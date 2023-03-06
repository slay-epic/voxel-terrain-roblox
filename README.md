# Roblox Voxel Terrain Generation
This repository includes the script that handles the terrain generation using perlin noise. Other features are also added such as tree and ore generation.

# Requirements
You should have your own "Block Dictionary" for the script to use. You can do so by creating a module script and make this as a reference for scripting it

```lua
local dictionary = {}

dictionary.blocks = {
	["Grass"] = {
		["object"] = Blocks:WaitForChild("Grass"),
	}
}

return dictionary
```
