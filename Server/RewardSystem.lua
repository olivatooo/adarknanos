--[[
    GLOBAL REWARD SYSTEM FOR OBJECTIVE COMPLETION

    This system tracks global objectives and applies rewards to characters.
    When any player completes an objective, ALL players progress together.

    HOW TO USE:

    1. Define your reward functions in the RewardSystem.RewardFunctions table below.
       Each function receives (character, objectives_completed) as parameters.

    2. Rewards are automatically applied when:
       - A character spawns (via SpawnCharacter in Index.lua)
       - A character returns to nexus after completing an objective (via Dimension:ReturnAllPlayers)

    3. Objectives automatically increment when any Dimension completes its objective.

    EXAMPLE REWARD FUNCTIONS:

    -- Health boost based on objectives completed
    function(character, objectives_completed)
        if objectives_completed >= 1 then
            local newMaxHealth = 100 + (objectives_completed * 10)
            character:SetMaxHealth(newMaxHealth)
            character:SetHealth(newMaxHealth)
        end
    end

    -- Speed boost (multiplicative)
    function(character, objectives_completed)
        if objectives_completed >= 2 then
            local speedMultiplier = 1 + (objectives_completed * 0.1)
            character:SetSpeedMultiplier(speedMultiplier)
        end
    end

    -- Give weapon at certain milestones
    function(character, objectives_completed)
        if objectives_completed == 5 then
            local weapon = Weapon(Vector(), Rotator(), "nanos-world::SK_AK47")
            character:PickUp(weapon)
        end
    end

    TESTING COMMANDS:
    - RewardSystem.SetGlobalObjectives(10)  -- Set objectives to 10
    - RewardSystem.ResetGlobalObjectives()  -- Reset to 0
    - RewardSystem.GetGlobalObjectivesCompleted()  -- Get current count

    UI INTEGRATION:
    - The UI automatically displays objective progress as dots in the top-right corner
    - Completed objectives are shown as glowing golden dots
    - Incomplete objectives are shown as faded dots
--]]

RewardSystem = {}

-- Global objective counter (shared by all players)
RewardSystem.GlobalObjectivesCompleted = 0

-- List of reward functions that will be called when applying rewards
-- Each function receives (character, objectives_completed) as parameters
-- Define your custom reward functions here!
RewardSystem.RewardFunctions = {
    -- Example reward function 1: Health boost
    function(character, objectives_completed)
        if objectives_completed >= 1 then
            character:SetMaxHealth(100 + (objectives_completed * 10))
            character:SetHealth(character:GetMaxHealth())
            Console.Log("Applied health reward: " .. character:GetMaxHealth())
        end
    end,
    function(character, objectives_completed)
        if objectives_completed >= 2 then
            local weapon = M1Garand(Vector(), Rotator())
            weapon:SetAmmoBag(100 + (objectives_completed * 10))
            character:PickUp(weapon)
        end
    end,
    function(character, objectives_completed)
        if objectives_completed >= 2 then
            local weapon = M1Garand(Vector(), Rotator())
            character:PickUp(weapon)
        end
    end,

    -- Example reward function 2: Speed boost
    -- function(character, objectives_completed)
    --     if objectives_completed >= 2 then
    --         character:SetSpeedMultiplier(1 + (objectives_completed * 0.1))
    --         Console.Log("Applied speed reward: " .. character:GetSpeedMultiplier())
    --     end
    -- end,

    -- Add your custom reward functions here!
}

--- Gets the global number of objectives completed
-- @return number - Number of objectives completed globally
function RewardSystem.GetGlobalObjectivesCompleted()
    return RewardSystem.GlobalObjectivesCompleted
end

--- Increments the global objective counter
-- Called when any dimension/objective is completed
function RewardSystem.IncrementGlobalObjectives()
    RewardSystem.GlobalObjectivesCompleted = RewardSystem.GlobalObjectivesCompleted + 1

    Console.Log("=== GLOBAL OBJECTIVE COMPLETED ===")
    Console.Log("Total objectives completed: " .. RewardSystem.GlobalObjectivesCompleted)

    -- Sync the new objective count to all clients for UI update
    RewardSystem.SyncObjectivesToAllClients()

    -- Check if all objectives are completed (assuming 10 objectives total)
    if RewardSystem.GlobalObjectivesCompleted >= 1 then
        Console.Log("ALL OBJECTIVES COMPLETED - Triggering EndGame sequence")
        -- Delay EndGame slightly to allow UI to update
        Timer.SetTimeout(function()
            EndGame()
        end, 3000) -- 3 second delay for dramatic effect
    end
end

--- Applies all reward functions to a character based on global objectives completed
-- @param character Character - The character to apply rewards to
function RewardSystem.ApplyRewards(character)
    if not character or not character:IsValid() then
        Console.Warn("Cannot apply rewards: invalid character")
        return
    end
    for i, reward_func in ipairs(RewardSystem.RewardFunctions) do
        local success, error_msg = pcall(function()
            reward_func(character, RewardSystem.GlobalObjectivesCompleted)
        end)

        if not success then
            Console.Error("Error in reward function #" .. tostring(i) .. ": " .. tostring(error_msg))
        end
    end
end

--- Syncs the global objective count to all clients
function RewardSystem.SyncObjectivesToAllClients()
    Events.BroadcastRemote("UpdateObjectivesCompleted", RewardSystem.GlobalObjectivesCompleted)
end

--- Syncs the objective count to a specific player (for new joins)
-- @param player Player - The player to sync to
function RewardSystem.SyncObjectivesToPlayer(player)
    Events.CallRemote("UpdateObjectivesCompleted", player, RewardSystem.GlobalObjectivesCompleted)
end

--- Resets the global objective counter (useful for testing or server resets)
function RewardSystem.ResetGlobalObjectives()
    RewardSystem.GlobalObjectivesCompleted = 0
    Console.Log("Global objectives reset to 0")
    RewardSystem.SyncObjectivesToAllClients()
end

--- Manually sets the global objective count (useful for testing)
-- @param count number - The objective count to set
function RewardSystem.SetGlobalObjectives(count)
    RewardSystem.GlobalObjectivesCompleted = count
    Console.Log("Global objectives set to: " .. count)
    RewardSystem.SyncObjectivesToAllClients()
end

Console.Log("RewardSystem loaded! Global objectives: " .. RewardSystem.GlobalObjectivesCompleted)

return RewardSystem
