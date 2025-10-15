Package.Require("Dimension.lua")

ObjectiveCubeFound = false

-- Helper function to generate random pastel colors
local function RandomColor()
    return Color(
        math.random(50, 255) / 255,
        math.random(50, 255) / 255,
        math.random(50, 255) / 255
    )
end

-- Helper function to convert HSV to RGB
local function hsv_to_rgb(h, s, v)
    local r, g, b
    
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    local remainder = i % 6
    if remainder == 0 then
        r, g, b = v, t, p
    elseif remainder == 1 then
        r, g, b = q, v, p
    elseif remainder == 2 then
        r, g, b = p, v, t
    elseif remainder == 3 then
        r, g, b = p, q, v
    elseif remainder == 4 then
        r, g, b = t, p, v
    else
        r, g, b = v, p, q
    end
    
    return r, g, b
end

-- Spawn function for the Round Maze dimension
local function SpawnRoundMazeContent(dimension)
    ObjectiveCubeFound = false

    -- Maze parameters
    local maze_radius = 20000      -- How far the maze extends
    local sphere_diameter = 100
    local sphere_spacing = 500     -- Space between sphere centers
    local clear_zone_radius = 1000 -- Clear area around spawn (0,0,0)

    -- Create a grid-based maze with spheres
    local maze_spheres = {}

    -- Generate maze walls in a grid pattern with some randomness
    for x = -maze_radius, maze_radius, sphere_spacing do
        for y = -maze_radius, maze_radius, sphere_spacing do
            -- Calculate distance from center
            local distance_from_center = math.sqrt(x * x + y * y)

            -- Skip if within clear zone
            if distance_from_center > clear_zone_radius then
                -- Create maze pattern: random walls with corridors
                -- Use a probability system to create maze-like structure
                local should_spawn = false

                -- Create grid pattern with some randomness
                if math.random() > 0.6 then
                    should_spawn = true
                end

                -- Ensure outer boundary exists
                if distance_from_center > maze_radius - 500 then
                    should_spawn = true
                end

                if should_spawn then
                    -- Random height variation
                    local height = math.random(0, 4) * sphere_diameter

                    -- Random scale for variety (0.5 to 10.0)
                    local scale_factor = 0.5 + math.random() * 3.5

                    local sphere = StaticMesh(
                        Vector(x, y, height + 100),
                        Rotator(0, 0, 0),
                        "nanos-world::SM_Sphere",
                        CollisionType.Normal
                    )

                    sphere:SetScale(Vector(scale_factor, scale_factor, scale_factor))
                    sphere:SetDimension(dimension.id)

                    -- Set random color
                    sphere:SetMaterialColorParameter("Tint", RandomColor())

                    -- Track for cleanup
                    dimension:TrackEntity(sphere)
                    table.insert(maze_spheres, sphere)
                end
            end
        end
    end

    Console.Log("Spawned " .. #maze_spheres .. " spheres in Round Maze dimension")

    -- Place the objective cube at a random location in the maze
    local cube_placed = false
    local attempts = 0
    local max_attempts = 100

    while not cube_placed and attempts < max_attempts do
        attempts = attempts + 1

        -- Random position outside clear zone but inside maze
        local angle = math.random() * 2 * math.pi
        local distance = clear_zone_radius + math.random() * (maze_radius - clear_zone_radius - 1000)
        local cube_x = math.cos(angle) * distance
        local cube_y = math.sin(angle) * distance

        -- Place cube at a visible height
        local objective_cube = Prop(
            Vector(cube_x, cube_y, 200),
            Rotator(0, math.random(0, 360), 0),
            "nanos-world::SM_Cube",
            CollisionType.Normal,
            false,
            GrabMode.Enabled
        )

        objective_cube:SetDimension(dimension.id)
        objective_cube:SetScale(Vector(2, 2, 2))                            -- Make it noticeable
        objective_cube:SetMaterialColorParameter("Tint", Color(1, 0.84, 0)) -- Gold color

        -- Add interaction to complete objective
        objective_cube:Subscribe("Interact", function(self, character)
            ObjectiveCubeFound = true
            Chat.BroadcastMessage("Objective cube found! Maze complete!")
            
            -- Send cryptic lore message for maze completion
            local maze_completion_messages = {
                "The maze's heart beats one last time...",
                "The labyrinth reveals its secret... but at what cost?",
                "The geometric nightmare ends... or does it?",
                "The cube dissolves... reality shifts...",
                "The maze remembers the path... but forgets the way out...",
                "The puzzle solves itself... the dream grows darker...",
                "The cube was never the goal... it was the trap...",
                "The maze collapses... but what rises in its place?"
            }
            local random_msg = maze_completion_messages[math.random(#maze_completion_messages)]
            Chat.BroadcastMessage(random_msg)
            
            Console.Log("Round Maze objective cube interacted!")

            -- Visual feedback - destroy the cube
            Timer.SetTimeout(function()
                if self:IsValid() then
                    self:Destroy()
                end
            end, 500)

            return false
        end)

        dimension:TrackEntity(objective_cube)
        cube_placed = true

        Console.Log("Objective cube placed at (" .. cube_x .. ", " .. cube_y .. ", 200)")
    end

    -- Spawn ground plane
    local ground = StaticMesh(Vector(0, 0, 1), Rotator(), "nanos-world::SM_Plane", CollisionType.Normal)
    ground:SetScale(Vector(1000, 1000, 1))
    ground:SetScale(Vector(50000, 50000, 1))
    ground:SetMaterialColorParameter("Tint", Color(0.2, 0.2, 0.3))
    ground:SetDimension(dimension.id)
    dimension:TrackEntity(ground)
    
    -- Add hue rotation timer for the ground
    local hue_rotation_timer = Timer.SetInterval(function()
        -- Get current time for smooth hue rotation
        local time = os.clock()
        local hue = (time * 0.1) % 1  -- Slow rotation, cycles every 10 seconds
        
        -- Convert HSV to RGB (hue, saturation=0.3, value=0.25)
        local r, g, b = hsv_to_rgb(hue, 0.3, 0.25)
        
        -- Apply the new color to the ground
        ground:SetMaterialColorParameter("Tint", Color(r, g, b))
    end, 100) -- Update every 100ms for smooth animation
    
    -- Track the timer for cleanup
    dimension:TrackTimer(hue_rotation_timer)

    -- Create door back to Nexus
    local door = DimensionDoor.new(
        Vector(0, 0, 0),
        Rotator(0, 0, 0),
        1,
        "Nexus",
        Color(1, 1, 1),
        "nanos-world::SM_Portapotty_Door",
        nil,
        4
    )

    -- Add some lights for visibility
    for i = 1, 8 do
        local angle = (i - 1) * (2 * math.pi / 8)
        local light_distance = 10000
        local light_x = math.cos(angle) * light_distance
        local light_y = math.sin(angle) * light_distance

        local light = Light(
            Vector(light_x, light_y, 2500),
            Rotator(0, 0, 0),
            RandomColor(),
            LightType.Point,
            10000,
            5000,
            0,
            0,
            50000,
            true,
            true,
            true
        )
        light:SetDimension(dimension.id)
        dimension:TrackEntity(light)
    end
end

-- Objective function - complete when cube is found
local function RoundMazeObjective(dimension)
    return ObjectiveCubeFound
end

-- Cleanup function
local function RoundMazeCleanup(dimension)
    Console.Log("Round Maze dimension cleaned up!")
    ObjectiveCubeFound = false
end

-- Create the Round Maze dimension
RoundMazeDimension = Dimension.new(
    4,                     -- Dimension ID
    "Round Maze",          -- Name
    SpawnRoundMazeContent, -- Spawn function
    RoundMazeObjective,    -- Objective function
    RoundMazeCleanup       -- Cleanup function
)

-- Spawn the dimension immediately
RoundMazeDimension:Spawn()
