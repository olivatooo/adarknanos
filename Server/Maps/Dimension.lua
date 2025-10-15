-- Dimension Class
Dimension = {}
Dimension.__index = Dimension

-- Class variable to track all dimensions
Dimension.AllDimensions = {}

--- Creates a new Dimension instance
-- @param id number - Unique dimension ID
-- @param name string - Display name of the dimension
-- @param spawn_function function - Function to spawn/setup the dimension content
-- @param objective_function function - Optional function that returns true when objective is complete
-- @param cleanup_function function - Optional function to clean up dimension content
function Dimension.new(id, name, spawn_function, objective_function, cleanup_function)
    local self = setmetatable({}, Dimension)

    -- Store parameters
    self.id = id
    self.name = name
    self.spawn_function = spawn_function
    self.objective_function = objective_function
    self.cleanup_function = cleanup_function
    self.doors = {}            -- List of all doors leading to this dimension
    self.spawned_entities = {} -- Track spawned entities for cleanup
    self.is_spawned = false
    self.is_completed = false
    self.objective_check_timer = nil

    -- Register this dimension
    Dimension.AllDimensions[id] = self

    return self
end

--- Spawns the dimension content
function Dimension:Spawn()
    if self.is_spawned then
        Console.Warn("Dimension " .. self.name .. " is already spawned!")
        return
    end

    if self.spawn_function then
        Console.Log("Spawning dimension: " .. self.name)
        self.spawn_function(self)
        self.is_spawned = true

        -- Start checking objective if one exists
        if self.objective_function then
            self:StartObjectiveCheck()
        end
    end
end

--- Adds a door that leads to this dimension
function Dimension:AddDoor(door)
    table.insert(self.doors, door)
end

--- Tracks an entity spawned in this dimension for later cleanup
function Dimension:TrackEntity(entity)
    table.insert(self.spawned_entities, entity)
end

--- Starts periodic objective checking
function Dimension:StartObjectiveCheck()
    if self.objective_check_timer then
        return -- Already checking
    end

    self.objective_check_timer = Timer.SetInterval(function()
        if self.objective_function and self.objective_function(self) then
            self:CompleteObjective()
        end
    end, 1000) -- Check every second
end

--- Stops objective checking
function Dimension:StopObjectiveCheck()
    if self.objective_check_timer then
        Timer.ClearInterval(self.objective_check_timer)
        self.objective_check_timer = nil
    end
end

--- Called when the dimension objective is completed
function Dimension:CompleteObjective()
    if self.is_completed then
        return
    end

    self.is_completed = true
    self:StopObjectiveCheck()

    -- Broadcast completion message
    Chat.BroadcastMessage("Dream '" .. self.name .. "' is over...")

    -- Send all players back to dimension 1 (Nexus)
    self:ReturnAllPlayers()

    -- Destroy all doors leading to this dimension
    self:DestroyAllDoors()

    -- Cleanup dimension content
    self:Cleanup()
end

--- Returns all players in this dimension back to dimension 1
function Dimension:ReturnAllPlayers()
    local players = Player.GetAll()
    for _, player in pairs(players) do
        if player:GetDimension() == self.id then
            player:SetDimension(1) -- Return to Nexus
            Events.CallRemote("PlayOST", player, "1.ogg")

            -- Also move their character if they have one
            local character = player:GetControlledCharacter()
            if character then
                character:SetDimension(1)
                -- Optionally teleport them to a spawn point
                character:SetLocation(Vector(0, 0, 200)) -- Adjust as needed
            end
        end
    end
end

--- Destroys all doors leading to this dimension
function Dimension:DestroyAllDoors()
    Console.Log("Destroying " .. #self.doors .. " doors to " .. self.name)
    for _, door in ipairs(self.doors) do
        if door and door.Destroy then
            door:Destroy()
        end
    end
    self.doors = {}
end

--- Cleans up all entities spawned in this dimension
function Dimension:Cleanup()
    Console.Log("Cleaning up dimension: " .. self.name)

    -- Call custom cleanup function if provided
    if self.cleanup_function then
        self.cleanup_function(self)
    end

    -- Destroy tracked entities
    for _, entity in ipairs(self.spawned_entities) do
        if entity and entity.IsValid and entity:IsValid() then
            entity:Destroy()
        end
    end
    self.spawned_entities = {}

    self.is_spawned = false
end

--- Manually triggers objective completion (for testing or scripted events)
function Dimension:ForceComplete()
    self:CompleteObjective()
end

--- Resets the dimension (respawns it)
function Dimension:Reset()
    Console.Log("Resetting dimension: " .. self.name)
    self:Cleanup()
    self.is_completed = false
    self:Spawn()
end

--- Gets all players currently in this dimension
function Dimension:GetPlayers()
    local players_in_dimension = {}
    local all_players = Player.GetAll()

    for _, player in pairs(all_players) do
        if player:GetDimension() == self.id then
            table.insert(players_in_dimension, player)
        end
    end

    return players_in_dimension
end

--- Gets the number of players in this dimension
function Dimension:GetPlayerCount()
    return #self:GetPlayers()
end

--- Static method to get a dimension by ID
function Dimension.GetByID(id)
    return Dimension.AllDimensions[id]
end

--- Static method to complete all dimensions (useful for testing)
function Dimension.CompleteAll()
    for _, dimension in pairs(Dimension.AllDimensions) do
        dimension:ForceComplete()
    end
end

--[[ USAGE EXAMPLES:

-- Example 1: Create a simple dimension with spawn function
local function SpawnMyDimensionContent(dimension)
    -- Spawn some props
    for i = 1, 10 do
        local prop = Prop(Vector(i * 100, 0, 0), Rotator(), "nanos-world::SM_Crate_07")
        prop:SetDimension(dimension.id)
        dimension:TrackEntity(prop)  -- Important: track for auto-cleanup
    end
end

local MyDimension = Dimension.new(
    100,                        -- Unique dimension ID
    "My Test Dimension",        -- Name
    SpawnMyDimensionContent     -- Spawn function
)

MyDimension:Spawn()

-- Example 2: Dimension with objective (collect items example)
local items_collected = 0

local function SpawnCollectionDimension(dimension)
    -- Spawn collectible items
    for i = 1, 5 do
        local item = Prop(Vector(math.random(-1000, 1000), math.random(-1000, 1000), 50),
                         Rotator(), "nanos-world::SM_WoodenCrate_02")
        item:SetDimension(dimension.id)
        dimension:TrackEntity(item)

        -- Add collection logic
        item:Subscribe("Interact", function(self, character)
            items_collected = items_collected + 1
            Chat.BroadcastMessage("Item collected! " .. items_collected .. "/5")
            self:Destroy()
            return false
        end)
    end
end

local function CheckCollectionObjective(dimension)
    return items_collected >= 5  -- Complete when all items collected
end

local function CleanupCollectionDimension(dimension)
    items_collected = 0  -- Reset counter
end

local CollectionDimension = Dimension.new(
    101,
    "Collection Challenge",
    SpawnCollectionDimension,
    CheckCollectionObjective,
    CleanupCollectionDimension
)

CollectionDimension:Spawn()

-- Example 3: Boss fight dimension with time limit
local boss_defeated = false
local dimension_start_time = 0

local function SpawnBossDimension(dimension)
    dimension_start_time = os.time()

    -- Spawn a boss NPC
    local boss = Character(Vector(0, 0, 100), Rotator(), "nanos-world::SK_Male")
    boss:SetDimension(dimension.id)
    dimension:TrackEntity(boss)

    boss:Subscribe("Death", function()
        boss_defeated = true
    end)
end

local function CheckBossObjective(dimension)
    -- Win condition: defeat boss
    if boss_defeated then
        return true
    end

    -- Lose condition: time limit exceeded (5 minutes)
    if os.time() - dimension_start_time > 300 then
        Chat.BroadcastMessage("Time's up! Boss dimension failed!")
        return true
    end

    return false
end

local function CleanupBossDimension(dimension)
    boss_defeated = false
    dimension_start_time = 0
end

local BossDimension = Dimension.new(
    102,
    "Boss Arena",
    SpawnBossDimension,
    CheckBossObjective,
    CleanupBossDimension
)

BossDimension:Spawn()

-- Example 4: Manually control dimension lifecycle
local ManualDimension = Dimension.new(
    103,
    "Manual Dimension",
    function(dim)
        Console.Log("Manual dimension spawned!")
    end,
    nil,  -- No objective, manual completion only
    function(dim)
        Console.Log("Manual dimension cleaned up!")
    end
)

-- Spawn it when you want
ManualDimension:Spawn()

-- Complete it manually when ready
-- ManualDimension:ForceComplete()

-- Or reset and respawn
-- ManualDimension:Reset()

-- Example 5: Get dimension info
local players_in_dimension = MyDimension:GetPlayers()
local player_count = MyDimension:GetPlayerCount()

Console.Log("Players in " .. MyDimension.name .. ": " .. player_count)

-- Example 6: Testing - complete all dimensions at once
-- Dimension.CompleteAll()

--]]
