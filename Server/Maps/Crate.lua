Package.Require("Dimension.lua")

-- Crate World state tracking
CrateWorldPuzzle = {
    crates_broken = 0,
    crates_needed = 100,
    active_breakable_crates = {},
    active_red_crates = {},
    max_breakable_crates = 15,
    max_red_crates = 15,
    puzzle_complete = false,
    spawn_timer = nil
}

-- Crate mesh list
local CrateMeshes = {
    "nanos-world::SM_Crate_07",
    "nanos-world::SM_Crate_03",
    "nanos-world::SM_Crate_04",
    "nanos-world::SM_Crate_01",
    "nanos-world::SM_Crate_02"
}

-- World and Arena boundaries
local WORLD_SIZE = 25000                -- World filled with crates
local ARENA_SIZE = 2500                 -- Clear arena space
local ARENA_CENTER = Vector(7500, 0, 0) -- Arena will be at origin
local ARENA_MIN = ARENA_CENTER.X - ARENA_SIZE / 2
local ARENA_MAX = ARENA_CENTER.X + ARENA_SIZE / 2
local WALL_HEIGHT = 1000
local CRATE_SCALE = 8 -- Make crates much bigger to reduce total count

-- Helper function to check if position is inside arena
local function IsInsideArena(x, y)
    return x >= ARENA_MIN and x <= ARENA_MAX and y >= ARENA_MIN and y <= ARENA_MAX
end

-- Helper function to get random position in arena
local function GetRandomArenaPosition()
    return Vector(
        math.random(ARENA_MIN + 100, ARENA_MAX - 100),
        math.random(ARENA_MIN + 100, ARENA_MAX - 100),
        100
    )
end

-- Helper function to get random position on arena edge (for crate spawning)
local function GetRandomArenaEdgePosition()
    local side = math.random(1, 4)
    local x, y

    if side == 1 then -- Top edge
        x = math.random(ARENA_MIN, ARENA_MAX)
        y = ARENA_MAX
    elseif side == 2 then -- Bottom edge
        x = math.random(ARENA_MIN, ARENA_MAX)
        y = ARENA_MIN
    elseif side == 3 then -- Left edge
        x = ARENA_MIN
        y = math.random(ARENA_MIN, ARENA_MAX)
    else -- Right edge
        x = ARENA_MAX
        y = math.random(ARENA_MIN, ARENA_MAX)
    end

    return Vector(x, y, 100)
end

-- Helper function to get opposite arena edge position
local function GetOppositeArenaEdgePosition(start_pos)
    -- Calculate which edge the start position is on
    local is_top = start_pos.Y >= ARENA_MAX - 10
    local is_bottom = start_pos.Y <= ARENA_MIN + 10
    local is_left = start_pos.X <= ARENA_MIN + 10
    local is_right = start_pos.X >= ARENA_MAX - 10

    local x, y

    if is_top then -- Go to bottom
        x = math.random(ARENA_MIN, ARENA_MAX)
        y = ARENA_MIN
    elseif is_bottom then -- Go to top
        x = math.random(ARENA_MIN, ARENA_MAX)
        y = ARENA_MAX
    elseif is_left then -- Go to right
        x = ARENA_MAX
        y = math.random(ARENA_MIN, ARENA_MAX)
    else -- Go to left
        x = ARENA_MIN
        y = math.random(ARENA_MIN, ARENA_MAX)
    end

    return Vector(x, y, 100)
end

-- Function to spawn a breakable crate
local function SpawnBreakableCrate(dimension)
    if #CrateWorldPuzzle.active_breakable_crates >= CrateWorldPuzzle.max_breakable_crates then
        return
    end

    local start_pos = GetRandomArenaEdgePosition()
    local end_pos = GetOppositeArenaEdgePosition(start_pos)
    local mesh = CrateMeshes[math.random(#CrateMeshes)]

    local crate = Prop(
        start_pos,
        Rotator(math.random(0, 360), math.random(0, 360), math.random(0, 360)),
        mesh,
        CollisionType.Normal,
        false,
        GrabMode.Enabled
    )

    crate:SetDimension(dimension.id)
    crate:SetScale(Vector(2, 2, 2))
    crate:SetMaterialColorParameter("Tint", Color(0.8, 0.6, 0.3)) -- Normal crate color

    -- Make crate move across the arena to opposite edge
    local move_time = math.random(5, 15) -- 5-15 seconds to cross arena
    crate:TranslateTo(end_pos, move_time)

    -- Track crate
    table.insert(CrateWorldPuzzle.active_breakable_crates, crate)
    dimension:TrackEntity(crate)

    -- Subscribe to damage/break
    crate:Subscribe("TakeDamage", function(self, damage, bone, type, from_direction, instigator, causer)
        -- Crate is being shot/damaged
        if self:IsValid() then
            CrateWorldPuzzle.crates_broken = CrateWorldPuzzle.crates_broken + 1

            Chat.BroadcastMessage("Crates broken: " ..
                CrateWorldPuzzle.crates_broken .. "/" .. CrateWorldPuzzle.crates_needed)

            -- Remove from active list
            for i, c in ipairs(CrateWorldPuzzle.active_breakable_crates) do
                if c == self then
                    table.remove(CrateWorldPuzzle.active_breakable_crates, i)
                    break
                end
            end

            -- Destroy crate
            self:Destroy()

            -- Check if puzzle complete
            if CrateWorldPuzzle.crates_broken >= CrateWorldPuzzle.crates_needed then
                CrateWorldPuzzle.puzzle_complete = true
                Chat.BroadcastMessage("All crates destroyed! Escaping Crate World...")
            end
        end

        return true
    end)

    -- Destroy crate when it reaches the end (fell off or completed path)
    Timer.SetTimeout(function()
        if crate:IsValid() then
            -- Remove from active list
            for i, c in ipairs(CrateWorldPuzzle.active_breakable_crates) do
                if c == crate then
                    table.remove(CrateWorldPuzzle.active_breakable_crates, i)
                    break
                end
            end
            crate:Destroy()
        end
    end, move_time + 1000)

    return crate
end

-- Function to spawn a red (deadly) crate
local function SpawnRedCrate(dimension)
    if #CrateWorldPuzzle.active_red_crates >= CrateWorldPuzzle.max_red_crates then
        return
    end

    local start_pos = GetRandomArenaEdgePosition()
    local end_pos = GetOppositeArenaEdgePosition(start_pos)
    local mesh = CrateMeshes[math.random(#CrateMeshes)]

    local crate = Prop(
        start_pos,
        Rotator(math.random(0, 360), math.random(0, 360), math.random(0, 360)),
        mesh,
        CollisionType.Normal,
        false,
        GrabMode.Enabled
    )

    crate:SetDimension(dimension.id)
    crate:SetScale(Vector(2.5, 2.5, 2.5))                   -- Slightly bigger
    crate:SetMaterialColorParameter("Tint", Color(1, 0, 0)) -- Red color

    -- Mark as deadly
    crate.is_deadly = true

    -- Make crate move across the arena to opposite edge (faster than regular crates)
    local move_time = math.random(3, 10) -- 3-10 seconds (faster)
    crate:TranslateTo(end_pos, move_time)

    -- Track crate
    table.insert(CrateWorldPuzzle.active_red_crates, crate)
    dimension:TrackEntity(crate)

    -- Destroy crate when it reaches the end
    Timer.SetTimeout(function()
        if crate:IsValid() then
            -- Remove from active list
            for i, c in ipairs(CrateWorldPuzzle.active_red_crates) do
                if c == crate then
                    table.remove(CrateWorldPuzzle.active_red_crates, i)
                    break
                end
            end
            crate:Destroy()
        end
    end, move_time * 1000)

    return crate
end

-- Function to continuously spawn crates
local function StartCrateSpawning(dimension)
    CrateWorldPuzzle.spawn_timer = Timer.SetInterval(function()
        if CrateWorldPuzzle.puzzle_complete then
            return
        end

        -- Spawn breakable crates
        local breakable_to_spawn = math.min(
            CrateWorldPuzzle.max_breakable_crates - #CrateWorldPuzzle.active_breakable_crates,
            math.random(1, 3)
        )

        for i = 1, breakable_to_spawn do
            SpawnBreakableCrate(dimension)
        end

        -- Spawn red crates (only after first crate is broken)
        if CrateWorldPuzzle.crates_broken > 0 then
            local red_to_spawn = math.min(
                CrateWorldPuzzle.max_red_crates - #CrateWorldPuzzle.active_red_crates,
                math.random(1, 2)
            )

            for i = 1, red_to_spawn do
                SpawnRedCrate(dimension)
            end
        end
    end, 500) -- Check every 0.5 seconds

    dimension:TrackTimer(CrateWorldPuzzle.spawn_timer)
end

-- Spawn function for Crate World dimension
local function SpawnCrateWorldContent(dimension)
    CrateWorldPuzzle.puzzle_complete = false
    CrateWorldPuzzle.crates_broken = 0
    CrateWorldPuzzle.active_breakable_crates = {}
    CrateWorldPuzzle.active_red_crates = {}

    local center = Vector(0, 0, 0)

    -- Give all players in this dimension a Glock
    Timer.SetTimeout(function()
        local players = dimension:GetPlayers()
        for _, player in ipairs(players) do
            local character = player:GetControlledCharacter()
            if character and character:IsValid() then
                local glock = Weapon(
                    character:GetLocation(),
                    Rotator(),
                    "nanos-world::W_Glock"
                )
                glock:SetDimension(dimension.id)
                character:PickUp(glock)
                dimension:TrackEntity(glock)
            end
        end
    end, 500)

    -- Spawn massive ground plane for the whole world
    local ground = StaticMesh(Vector(0, 0, 1), Rotator(), "nanos-world::SM_Plane", CollisionType.Normal)
    ground:SetMaterialTextureParameter("Texture", "package://adarknanos/Client/crate.jpg")
    ground:SetMaterialScalarParameter("VTiling", 1024)
    ground:SetMaterialScalarParameter("UTiling", 1024)
    ground:SetScale(Vector(WORLD_SIZE / 10, WORLD_SIZE / 10, 1))
    ground:SetMaterialColorParameter("Tint", Color(0.2, 0.2, 0.25))
    ground:SetDimension(dimension.id)
    dimension:TrackEntity(ground)

    -- Fill the world with LARGE crates (much fewer, much bigger)
    local world_crate_spacing = 750 -- Larger spacing
    local world_min = -WORLD_SIZE / 2
    local world_max = WORLD_SIZE / 2

    Console.Log("Spawning crate world with large crates...")

    for x = world_min, world_max, world_crate_spacing do
        for y = world_min, world_max, world_crate_spacing do
            -- Skip if inside arena
            if not IsInsideArena(x, y) then
                -- Spawn 1-2 layers of large crates
                local height_layers = math.random(0, 1)
                for z_layer = 0, height_layers do
                    local world_crate = StaticMesh(
                        Vector(x, y, z_layer * 500),
                        Rotator(0, math.random(0, 360), 0),
                        CrateMeshes[math.random(#CrateMeshes)],
                        CollisionType.Normal
                    )
                    world_crate:SetScale(Vector(CRATE_SCALE, CRATE_SCALE, CRATE_SCALE))
                    world_crate:SetDimension(dimension.id)
                    dimension:TrackEntity(world_crate)
                end
            end
        end
    end

    Console.Log("Creating maze path through crate world...")

    -- Create a maze path using a moving trigger that clears crates
    -- Generate maze path waypoints
    local maze_waypoints = {}
    local current_x = world_min
    local current_y = world_min
    table.insert(maze_waypoints, Vector(current_x, current_y, 200))

    -- Create a winding path to the arena
    local path_segment_length = 800
    local turns = 15 -- Number of turns in the maze

    for i = 1, turns do
        -- Randomly choose horizontal or vertical movement
        if math.random() > 0.5 then
            -- Move horizontally
            local target_x = current_x + (math.random() > 0.5 and path_segment_length or -path_segment_length)
            target_x = math.max(world_min, math.min(world_max, target_x))
            if target_x ~= current_x then
                current_x = target_x
                table.insert(maze_waypoints, Vector(current_x, current_y, 200))
            end
        else
            -- Move vertically
            local target_y = current_y + (math.random() > 0.5 and path_segment_length or -path_segment_length)
            target_y = math.max(world_min, math.min(world_max, target_y))
            if target_y ~= current_y then
                current_y = target_y
                table.insert(maze_waypoints, Vector(current_x, current_y, 200))
            end
        end
    end

    -- Add final path to arena center
    table.insert(maze_waypoints, Vector(ARENA_CENTER.X, ARENA_CENTER.Y, 200))

    -- Create arena walls using crates
    local wall_crate_spacing = 100


    -- Add central instruction text
    local instruction_text = TextRender(
        Vector(0, 0, 400),
        Rotator(),
        "",
        Vector(3, 3, 3),
        Color(1, 1, 1),
        FontType.OpenSans,
        TextRenderAlignCamera.FaceCamera
    )
    instruction_text:SetDimension(dimension.id)
    dimension:TrackEntity(instruction_text)

    -- Add warning text
    local warning_text = TextRender(
        Vector(0, 0, 300),
        Rotator(),
        "",
        Vector(2.5, 2.5, 2.5),
        Color(1, 0, 0),
        FontType.OpenSans,
        TextRenderAlignCamera.FaceCamera
    )
    warning_text:SetDimension(dimension.id)
    dimension:TrackEntity(warning_text)

    -- Add progress text that updates
    local progress_text = TextRender(
        Vector(0, 0, 200),
        Rotator(),
        "0 / 100",
        Vector(2, 2, 2),
        Color(0, 1, 0),
        FontType.OpenSans,
        TextRenderAlignCamera.FaceCamera
    )
    progress_text:SetDimension(dimension.id)
    dimension:TrackEntity(progress_text)

    -- Update progress text
    local progress_timer = Timer.SetInterval(function()
        if progress_text:IsValid() then
            progress_text:SetText(CrateWorldPuzzle.crates_broken .. " / " .. CrateWorldPuzzle.crates_needed)
        end
    end, 500)
    dimension:TrackTimer(progress_timer)

    -- Spawn door back to Nexus
    local door = DimensionDoor.new(
        Vector(0, 0, 0),
        Rotator(0, 0, 0),
        1,
        "Nexus",
        Color(1, 1, 1),
        "nanos-world::SM_Portapotty_Door",
        nil,
        7
    )

    -- Central bright light
    local central_light = Light(
        Vector(0, 0, 10000),
        Rotator(0, 0, 0),
        Color(1, 1, 1),
        LightType.Point,
        5000,
        1000,
        0,
        0,
        50000,
        true,
        true,
        true
    )
    central_light:SetDimension(dimension.id)
    dimension:TrackEntity(central_light)

    -- Spawn the first crate in the center
    local first_crate = Prop(
        Vector(0, 0, 100),
        Rotator(0, 0, 0),
        CrateMeshes[1],
        CollisionType.Normal,
        false,
        GrabMode.Enabled
    )
    first_crate:SetDimension(dimension.id)
    first_crate:SetScale(Vector(3, 3, 3))
    first_crate:SetMaterialColorParameter("Tint", Color(1, 0.84, 0)) -- Gold color
    dimension:TrackEntity(first_crate)
    table.insert(CrateWorldPuzzle.active_breakable_crates, first_crate)

    first_crate:Subscribe("TakeDamage", function(self, damage, bone, type, from_direction, instigator, causer)
        if self:IsValid() then
            CrateWorldPuzzle.crates_broken = CrateWorldPuzzle.crates_broken + 1
            Chat.BroadcastMessage("The chaos begins... Crates incoming!")
            Chat.BroadcastMessage("Crates broken: " ..
                CrateWorldPuzzle.crates_broken .. "/" .. CrateWorldPuzzle.crates_needed)

            -- Remove from active list
            for i, c in ipairs(CrateWorldPuzzle.active_breakable_crates) do
                if c == self then
                    table.remove(CrateWorldPuzzle.active_breakable_crates, i)
                    break
                end
            end

            self:Destroy()

            -- Start spawning crates
            StartCrateSpawning(dimension)
        end
        return true
    end)

    Console.Log("Crate World dimension spawned")
end

-- Objective function - complete when 100 crates are broken
local function CrateWorldObjective(dimension)
    return CrateWorldPuzzle.puzzle_complete
end

-- Cleanup function
local function CrateWorldCleanup(dimension)
    Console.Log("Crate World dimension cleaned up!")
    CrateWorldPuzzle.puzzle_complete = false
    CrateWorldPuzzle.crates_broken = 0
    CrateWorldPuzzle.active_breakable_crates = {}
    CrateWorldPuzzle.active_red_crates = {}

    if CrateWorldPuzzle.spawn_timer then
        Timer.ClearInterval(CrateWorldPuzzle.spawn_timer)
        CrateWorldPuzzle.spawn_timer = nil
    end
end

-- Create the Crate World dimension
CrateWorldDimension = Dimension.new(
    7,                      -- Dimension ID (matches DoorToCrateWorld)
    "Crate World",          -- Name
    SpawnCrateWorldContent, -- Spawn function
    CrateWorldObjective,    -- Objective function
    CrateWorldCleanup       -- Cleanup function
)

-- Spawn the dimension immediately
CrateWorldDimension:Spawn()
