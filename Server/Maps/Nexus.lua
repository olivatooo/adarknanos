Package.Require("Door.lua")
Package.Require("Wilderness.lua")
Package.Require("RoundMaze.lua")
Package.Require("ConstructionHell.lua")
Package.Require("Crate.lua")


function SpawnNexus(location, radius)
        -- Spawn a Bloodhound in dimension 1
    local bloodhound = Bloodhound.new(Vector(200, 200, 100), 1)

    local spawnedDoors = {}
    local doorCount = #Doors
    local doorIndex = 1

    for _, doorConfig in ipairs(Doors) do
        doorIndex = doorIndex + 1

        -- Calculate angle for this door (evenly distributed around the circle)
        local angle = (doorIndex - 1) * (2 * math.pi / doorCount)

        -- Calculate position on the circle
        local x = location.X + radius * math.cos(angle)
        local y = location.Y + radius * math.sin(angle)
        local doorPosition = Vector(x, y, location.Z)

        -- Calculate rotation to face the center
        -- The door should face toward the center, so we need to rotate it 180 degrees from the angle
        local rotationYaw = math.deg(angle + math.pi)
        local doorRotation = Rotator(0, rotationYaw, 0)

        -- Create door using the DimensionDoor class
        local door = DimensionDoor.new(
            doorPosition,
            doorRotation,
            doorConfig.dimension,
            doorConfig.name,
            doorConfig.custom_color,
            doorConfig.sm
        )

        -- Register the door with its dimension (if dimension exists)
        local dimension = Dimension.GetByID(doorConfig.dimension)
        if dimension then
            dimension:AddDoor(door)
        end

        table.insert(spawnedDoors, door)
    end

    -- Spawn ground plane
    local sm = StaticMesh(Vector(0, 0, 1), Rotator(), "nanos-world::SM_Plane", CollisionType.Normal)
    sm:SetScale(Vector(1000, 1000, 1))
    sm:SetPhysicalMaterial("nanos-world::PM_Grass")
    sm:SetMaterialTextureParameter("Texture", "package://adarknanos/Client/concrete.jpg")
    sm:SetMaterialScalarParameter("Metallic", 0)
    sm:SetMaterialScalarParameter("Specular ", 0)
    local my_light = Light(
        Vector(0, 0, 1000),
        Rotator(0, 90, 90), -- Relevant only for Rect and Spot light types
        Color(1, 1, 1),     -- Red Tint
        LightType.Point,    -- Point Light type
        1000,               -- Intensity
        5000,               -- Attenuation Radius
        44,                 -- Cone Angle (Relevant only for Spot light type)
        0,                  -- Inner Cone Angle Percent (Relevant only for Spot light type)
        50000,              -- Max Draw Distance (Good for performance - 0 for infinite)
        true,               -- Whether to use physically based inverse squared distance falloff, where Attenuation Radius is only clamping the light's contribution. (Spot and Point types only)
        true,               -- Cast Shadows?
        true                -- Enabled?
    )

    for i = 1, 25 do
        -- Create boundary triggers for world wrapping
        local box_trigger_north = Trigger(Vector(0, 45000, 0), Rotator(0, 0, 0), Vector(50000, 100, 1000),
            TriggerType.Box, true, Color(0, 1, 0))
        local box_trigger_south = Trigger(Vector(0, -45000, 0), Rotator(0, 0, 0), Vector(50000, 100, 1000),
            TriggerType.Box, true, Color(0, 1, 0))
        local box_trigger_east = Trigger(Vector(45000, 0, 0), Rotator(0, 0, 0), Vector(100, 50000, 1000), TriggerType
            .Box, true, Color(0, 1, 0))
        local box_trigger_west = Trigger(Vector(-45000, 0, 0), Rotator(0, 0, 0), Vector(100, 50000, 1000),
            TriggerType.Box, true, Color(0, 1, 0))

        -- Handle north/south wrapping
        box_trigger_north:Subscribe("BeginOverlap", function(trigger, actor)
            if actor:IsValid() then
                local pos = actor:GetLocation()
                actor:SetLocation(Vector(0, 0, 100)) -- Offset by 100 units south
            end
        end)

        box_trigger_south:Subscribe("BeginOverlap", function(trigger, actor)
            if actor:IsValid() then
                local pos = actor:GetLocation()
                actor:SetLocation(Vector(0, 0, 100)) -- Offset by 100 units north
            end
        end)

        -- Handle east/west wrapping
        box_trigger_east:Subscribe("BeginOverlap", function(trigger, actor)
            if actor:IsValid() then
                local pos = actor:GetLocation()
                actor:SetLocation(Vector(0, 0, 100)) -- Offset by 100 units west
            end
        end)

        box_trigger_west:Subscribe("BeginOverlap", function(trigger, actor)
            if actor:IsValid() then
                local pos = actor:GetLocation()
                actor:SetLocation(Vector(0, 0, 100)) -- Offset by 100 units east
            end
        end)
        box_trigger_east:SetDimension(i)
        box_trigger_west:SetDimension(i)
        box_trigger_north:SetDimension(i)
        box_trigger_south:SetDimension(i)
    end

    return spawnedDoors
end

-- Spawn the Wilderness dimension first (this registers it)
-- Then spawn the Nexus with doors
SpawnNexus(Vector(0, 0, 0), 1000)

--[[ DOOR USAGE EXAMPLES:

-- Example 1: Create a single door anywhere
local myDoor = DimensionDoor.new(
    Vector(1000, 500, 100),        -- location
    Rotator(0, 90, 0),             -- rotation
    5,                              -- dimension ID
    "Secret Room",                  -- name
    Color(1, 0, 0)                  -- color (red)
)

-- Example 2: Create a door with custom mesh
local fancyDoor = DimensionDoor.new(
    Vector(-500, -500, 50),
    Rotator(0, 180, 0),
    10,
    "VIP Area",
    Color(1, 0.84, 0),              -- gold color
    "nanos-world::SM_Door"          -- custom mesh asset
)

-- Example 3: Create a door with custom interaction
local customDoor = DimensionDoor.new(
    Vector(0, 1000, 0),
    Rotator(0, 0, 0),
    7,
    "Boss Arena",
    Color(0.5, 0, 0.5),
    nil,                            -- default mesh
    function(self, character)       -- custom interaction callback
        local player = character:GetPlayer()
        if player then
            Chat.BroadcastMessage(player:GetName() .. " entered the " .. self.name .. "!")
            player:SetDimension(self.dimension)
            character:SetDimension(self.dimension)
            -- Add custom logic here (check level, inventory, etc.)
        end
        return false
    end
)

-- Example 4: Modify a door after creation
myDoor:SetColor(Color(0, 1, 0))    -- Change color to green

-- Example 5: Clean up a door
-- customDoor:Destroy()

--]]

--[[ DIMENSION & DOOR INTEGRATION SYSTEM:

This gamemode uses a Dimension and DimensionDoor system that automatically manages:

1. DIMENSION CLASS (Dimension.lua):
   - Spawns dimension content
   - Tracks objectives
   - Manages cleanup when objectives are complete
   - Automatically returns players to Nexus (Dimension 1) on completion
   - Destroys all doors leading to that dimension on completion

2. DIMENSIONDOOR CLASS (Door.lua):
   - Creates interactive doors
   - Teleports players to dimensions
   - Can be destroyed automatically when dimension completes

3. AUTOMATIC INTEGRATION:
   When you create a dimension and doors to it:

   Step 1: Create your dimension
   ```lua
   local MyDimension = Dimension.new(
       50,                          -- Dimension ID
       "My Challenge",              -- Name
       function(dim)                -- Spawn function
           -- Spawn your content here
           local prop = Prop(Vector(0, 0, 0), Rotator(), "nanos-world::SM_Crate_07")
           prop:SetDimension(dim.id)
           dim:TrackEntity(prop)    -- Important for cleanup!
       end,
       function(dim)                -- Objective function (optional)
           -- Return true when objective is complete
           return dim:GetPlayerCount() == 0  -- Example: complete when empty
       end
   )
   MyDimension:Spawn()
   ```

   Step 2: Create doors to your dimension
   ```lua
   local door = DimensionDoor.new(
       Vector(100, 200, 0),
       Rotator(0, 0, 0),
       50,                          -- Must match dimension ID
       "My Challenge",
       Color(1, 0.5, 0)
   )

   -- Register door with dimension (important!)
   MyDimension:AddDoor(door)
   ```

   Step 3: When objective completes:
   - All players in that dimension are returned to Nexus (Dimension 1)
   - All doors to that dimension are destroyed
   - All tracked entities are cleaned up
   - Completion message is broadcast

4. CURRENT DIMENSIONS:
   - Dimension 1: Nexus (spawn/hub area)
   - Dimension 2: Wilderness (tree collection/exploration)
   - Dimensions 3-11: Available for other challenges

5. TESTING COMMANDS:
   - Dimension.GetByID(2):ForceComplete()  -- Force complete Wilderness
   - Dimension.CompleteAll()                -- Complete all dimensions
   - WildernessDimension:Reset()           -- Reset and respawn Wilderness

--]]
