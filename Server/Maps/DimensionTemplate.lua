--[[
    DIMENSION TEMPLATE
    Copy this file and customize it to create new dimensions for your gamemode.
    Replace "MyDimension" with your dimension name throughout.
--]]

Package.Require("Dimension.lua")

-- Configuration
local DIMENSION_ID = 100  -- CHANGE THIS: Must be unique! Use numbers 12+ (1-11 are reserved)
local DIMENSION_NAME = "My Dimension"  -- CHANGE THIS: Display name for your dimension

-- State variables (customize based on your objective)
local objective_progress = 0
local objective_target = 10

--[[
    SPAWN FUNCTION
    This is called when the dimension is first created.
    Spawn all your props, characters, and entities here.
    
    IMPORTANT: 
    - Set dimension ID on all entities: entity:SetDimension(dimension.id)
    - Track entities for auto-cleanup: dimension:TrackEntity(entity)
--]]
local function SpawnDimensionContent(dimension)
    Console.Log("Spawning " .. DIMENSION_NAME .. " content...")
    
    -- Example: Spawn some props
    for i = 1, 10 do
        local x = math.random(-1000, 1000)
        local y = math.random(-1000, 1000)
        
        local prop = Prop(
            Vector(x, y, 50),
            Rotator(0, math.random(0, 360), 0),
            "nanos-world::SM_Crate_07"
        )
        
        -- REQUIRED: Set dimension and track entity
        prop:SetDimension(dimension.id)
        dimension:TrackEntity(prop)
        
        -- Optional: Add interaction logic
        prop:Subscribe("Interact", function(self, character)
            objective_progress = objective_progress + 1
            Chat.BroadcastMessage("Progress: " .. objective_progress .. "/" .. objective_target)
            self:Destroy()
            return false
        end)
    end
    
    -- Example: Spawn ground plane
    local ground = StaticMesh(
        Vector(0, 0, 0),
        Rotator(),
        "nanos-world::SM_Plane",
        CollisionType.Normal
    )
    ground:SetScale(Vector(100, 100, 1))
    ground:SetDimension(dimension.id)
    dimension:TrackEntity(ground)
    
    Console.Log(DIMENSION_NAME .. " spawned successfully!")
end

--[[
    OBJECTIVE FUNCTION (Optional)
    This function is called every second to check if the objective is complete.
    Return true when the dimension objective is completed.
    
    When this returns true:
    - All players are returned to Nexus (Dimension 1)
    - All doors to this dimension are destroyed
    - Cleanup function is called
    
    If you don't want auto-completion, set this to nil and use dimension:ForceComplete() manually
--]]
local function CheckObjective(dimension)
    -- Example 1: Check if objective progress reached target
    if objective_progress >= objective_target then
        return true
    end
    
    -- Example 2: Check if all players left
    -- if dimension:GetPlayerCount() == 0 then
    --     return true
    -- end
    
    -- Example 3: Time limit
    -- local time_elapsed = os.time() - start_time
    -- if time_elapsed > 300 then  -- 5 minutes
    --     return true
    -- end
    
    return false
end

--[[
    CLEANUP FUNCTION (Optional)
    Called after objective completes or when dimension is manually cleaned up.
    Use this to reset state variables or do custom cleanup.
    
    Note: Tracked entities are automatically destroyed, you don't need to do that here.
--]]
local function CleanupDimension(dimension)
    Console.Log("Cleaning up " .. DIMENSION_NAME)
    
    -- Reset state variables
    objective_progress = 0
    
    -- Add any custom cleanup logic here
end

--[[
    CREATE AND SPAWN THE DIMENSION
--]]
MyDimension = Dimension.new(
    DIMENSION_ID,
    DIMENSION_NAME,
    SpawnDimensionContent,
    CheckObjective,      -- Set to nil if you don't want auto-completion
    CleanupDimension     -- Set to nil if you don't need custom cleanup
)

-- Spawn the dimension (creates all content)
MyDimension:Spawn()

Console.Log(DIMENSION_NAME .. " registered with ID: " .. DIMENSION_ID)

--[[
    USAGE FROM OTHER FILES:
    
    1. In your main Index.lua or wherever you load maps:
       Package.Require("MyDimension.lua")
    
    2. To create doors to this dimension (usually in Nexus.lua):
       local door = DimensionDoor.new(
           Vector(100, 200, 0),      -- location
           Rotator(0, 90, 0),        -- rotation
           DIMENSION_ID,             -- dimension ID (must match!)
           DIMENSION_NAME,           -- name
           Color(1, 0.5, 0),         -- color
           "nanos-world::SM_Portapotty_Door"  -- mesh (optional)
       )
       
       -- IMPORTANT: Register door with dimension
       MyDimension:AddDoor(door)
    
    3. Manual control:
       MyDimension:ForceComplete()   -- Force completion
       MyDimension:Reset()           -- Reset and respawn
       MyDimension:GetPlayerCount()  -- Get player count
       MyDimension:GetPlayers()      -- Get list of players
--]]

