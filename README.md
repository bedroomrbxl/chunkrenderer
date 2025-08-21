# ChunkRenderer
This rendering system is used in [OpenFlight](https://www.roblox.com/games/79799490063452) to increase performance slightly over Roblox's provided Streaming system. This rendering system is best used on large maps where you need to customize how far you can see dynamically or through a user's Settings panel.

We use this in OpenFlight to decrease the quality of 10,000+ trees that may be out of your render distance and do not need to be rendered in full quality.

You can customize the rendering and appearance of just about any Instance that can be collided with.

![alt](https://github.com/user-attachments/assets/d119a2ef-a488-41b7-842e-602a86e6d65d)

## Usage
Drop the script into any client folder (we use StarterPlayerScripts) and customize the settings.
```luau
-- The X and Y size of chunks (in studs). In 3D, these would be the X and Z axis, but chunks are referenced using Vector2.
local CHUNK_SIZE_X = 100
local CHUNK_SIZE_Y = 100

-- The height of each chunk in studs.
local CHUNK_HEIGHT = 1000

-- You can limit how far chunk rendering will modify chunks. We recommend setting this a little larger than or equal to your map size.
local MAP_SIZE_WIDTH = 10000
local MAP_SIZE_HEIGHT = 10000
```
