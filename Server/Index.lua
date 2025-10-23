Package.Require("Debug.lua")
Package.Require("Bloodhound.lua")
Package.Require("RewardSystem.lua")
Server.LoadPackage("default-vehicles")
Server.LoadPackage("default-weapons")

-- Moon Scale tracking (1-50, represents game progress)
MoonScale = 1

-- Lives System - Track lives per player (everyone starts with 9)
PlayerLives = {}
MAX_LIVES = 9

--- Initialize lives for a player
-- @param player Player - The player to initialize
function InitializePlayerLives(player)
  local steam_id = player:GetAccountID()
  PlayerLives[steam_id] = MAX_LIVES
  Console.Log("Initialized " .. MAX_LIVES .. " lives for player: " .. player:GetName())
  SyncPlayerLives(player)
end

--- Get remaining lives for a player
-- @param player Player - The player to check
-- @return number - Number of lives remaining
function GetPlayerLives(player)
  local steam_id = player:GetAccountID()
  return PlayerLives[steam_id] or MAX_LIVES
end

--- Decrement a player's lives
-- @param player Player - The player who lost a life
-- @return boolean - True if player still has lives, false if out of lives
function DecrementPlayerLives(player)
  local steam_id = player:GetAccountID()

  if not PlayerLives[steam_id] then
    PlayerLives[steam_id] = MAX_LIVES
  end

  if PlayerLives[steam_id] > 0 then
    PlayerLives[steam_id] = PlayerLives[steam_id] - 1
    Console.Log("Player " .. player:GetName() .. " lost a life. Lives remaining: " .. PlayerLives[steam_id])

    -- Sync to client
    SyncPlayerLives(player)

    -- Check if out of lives
    if PlayerLives[steam_id] <= 0 then
      Console.Log("Player " .. player:GetName() .. " can't dream anymore")
      player:Ban("Out of Lives - Game Over")
      return false
    end

    return true
  end

  return false
end

--- Sync player lives to their client
-- @param player Player - The player to sync to
function SyncPlayerLives(player)
  local lives = GetPlayerLives(player)
  Events.CallRemote("UpdatePlayerLives", player, lives)
end

-- Lore messages for different game events
local LoreMessages = {
  door_entries = {
    "The threshold beckons... what dreams await beyond?",
    "Through the door, the dreamscape shifts...",
    "Another fragment of the mind's labyrinth opens...",
    "The boundary between worlds dissolves...",
    "Step through... the moon watches from above...",
    "Beyond this door lies another piece of the puzzle...",
    "The dream calls... will you answer?",
    "Through the veil of consciousness we pass...",
    "The handle is cold... as if someone just let go.",
    "You hear the faint echo of footsteps that aren't yours...",
    "The air thickens—something on the other side already knows you're coming.",
    "For a moment, you swear the door *breathes*.",
    "An eye opens in the darkness... and blinks shut before you can scream.",
    "The door creaks, though no wind moves it.",
    "Behind you, the floorboards whisper a single word: 'Closer.'",
    "A shadow waits on the other side... patient, smiling.",
    "Do not look back before you cross. It's watching.",
    "The key turns itself, slowly, like a pulse beneath the wood.",
    "Something presses its ear to the other side... listening.",
    "You feel the gaze before you see the door move.",
    "The walls seem to lean in—eager to witness your next mistake.",
    "The door opens by itself, as if to say: *We've been expecting you.*",
    "The moon hangs lower tonight... as if it's trying to see through the door.",
    "The sky outside ripples—something vast is trying to get in.",
    "Your reflection in the knob moves a moment too late.",
    "Dreamlight spills through the cracks... whispering in a voice not your own.",
    "The horizon bends, pulled by a gravity that feels like hunger.",
    "Someone is already standing on the other side. They look exactly like you.",
    "The moon's face fills the window—its smile doesn't reach its eyes.",
    "Behind the door, you hear the sea of static breathing.",
    "The floor hums softly, as if tuning itself to another frequency.",
    "You open the door and the stars blink out, one by one.",
    "Something presses against the door from the outside—slow, deliberate, familiar.",
    "The moonlight bends around the frame... it's learning how to enter.",
    "The invasion doesn't begin with a sound. It begins with your name.",
    "A low vibration fills the air—like the dream itself is being rewritten.",
    "The door is heavier than before... as if the world beyond has grown thicker.",
    "Every time you blink, the moon seems closer.",
    "You dream of doors, and behind each one, something wakes up.",
    "The lock pulses like a heartbeat. It's not yours.",
    "You open the door and find the same room. Only... wrong.",
    "The dream no longer waits for you. It crosses through first.",
    "Something vast moves behind the sky. The moon is only its eye.",
    "The handle glows faintly—an invitation, or a warning.",
    "A voice whispers through the wood: 'Let us in. The sky is falling.'",
  },

  objective_completion = {
    "Another dream fragment fades into memory...",
    "The moon grows heavier... can you feel its weight?",
    "One step closer to the inevitable...",
    "The dreamscape trembles as another realm collapses...",
    "Time... it's running out...",
    "The moon's descent quickens...",
    "Another piece of the nightmare ends...",
    "The void between dreams grows smaller..."
  },

  moon_progress = {
    "The moon hangs lower in the sky...",
    "Gravity pulls stronger... the end draws near...",
    "Can you feel it? The world grows heavier...",
    "The moon's shadow lengthens across the dreamscape...",
    "Time itself bends under the moon's weight...",
    "The sky cracks... reality fractures...",
    "Gravity's embrace tightens...",
    "The moon descends... bringing finality..."
  },

  periodic = {
    "In the silence between dreams, the moon whispers...",
    "The dreamscape shifts... reality bends...",
    "Time flows differently here... or does it flow at all?",
    "The moon's gaze pierces through dimensions...",
    "In the space between thoughts, something stirs...",
    "The dream grows restless... can you hear it?",
    "Reality's edges blur... what is real anymore?",
    "The moon's light casts shadows that shouldn't exist...",
    "Between wakefulness and sleep, the nightmare persists...",
    "The dreamscape remembers... it always remembers..."
  }
}

-- Send random lore message
local function SendLoreMessage(message_type)
  local messages = LoreMessages[message_type]
  if messages then
    local random_msg = messages[math.random(#messages)]
    Chat.BroadcastMessage(random_msg)
  end
end

--- Increments the moon scale and syncs it with all clients
function IncrementMoonScale()
  if MoonScale < 50 then
    MoonScale = MoonScale + 1
    Console.Log("Moon Scale increased to: " .. MoonScale)
    SyncMoonScaleToAllClients()

    -- Send lore message based on moon scale
    SendLoreMessage("moon_progress")
  else
    Console.Log("Moon Scale is already at maximum (50)")
    Chat.BroadcastMessage("The moon has reached its final position... the end begins now...")
  end
end

--- Syncs the current moon scale to all clients
function SyncMoonScaleToAllClients()
  Events.BroadcastRemote("UpdateMoonScale", MoonScale)
end

--- Syncs the moon scale to a specific player (for new joins)
function SyncMoonScaleToPlayer(player)
  Events.BroadcastRemote("UpdateMoonScale", MoonScale)
end

SkeletalCharacters = {
  "nanos-world::SK_Adventure_01_Full_02",
  "nanos-world::SK_Adventure_02_Full_01",
  "nanos-world::SK_Adventure_02_Full_02",
  "nanos-world::SK_Adventure_02_Full_03",
  "nanos-world::SK_Adventure_03_Full_01",
  "nanos-world::SK_Adventure_03_Full_02",
  "nanos-world::SK_Adventure_04_Full_01",
  "nanos-world::SK_Adventure_04_Full_02",
  "nanos-world::SK_Adventure_05_Full_02",
}

function SpawnCharacter(pos, player)
  local bleg = SkeletalCharacters[math.random(#SkeletalCharacters)]
  Console.Log(bleg)
  Console.Log(bleg)
  Console.Log(bleg)
  Console.Log(bleg)
  Console.Log(bleg)
  Console.Log(bleg)
  Console.Log(bleg)
  Console.Log(bleg)
  Console.Log(bleg)
  local character = Character(pos, Rotator(), bleg)
  character:SetCameraMode(CameraMode.FPSOnly)
  local light = Light(Vector(), Rotator(), Color(0.97, 0.76, 0.46), LightType.Spot, 1, 6000, 30, 0.75, 15000, false, true,
    true, 100)
  light:AttachTo(character, AttachmentRule.SnapToTarget, "head")
  light:SetRelativeLocation(Vector(0, 50, 0))
  light:SetRelativeRotation(Rotator(0, 87, 0))


  Character.Subscribe("Interact", function(self, prop)
    if prop:IsA(Prop) then
      return false
    end
  end)

  character:Subscribe("Death",
    function(self, last_damage_taken, last_bone_damaged, damage_type_reason, hit_from_direction, instigator, causer)
      if instigator then
        Bloodhound.new(self:GetLocation(), self:GetDimension(), RewardSystem.GlobalObjectivesCompleted + 2)
      end
      local player = self:GetPlayer()

      -- Decrement lives on death
      local has_lives = DecrementPlayerLives(player)

      if not has_lives then
        -- Out of lives - kick the player
        Timer.SetTimeout(function()
          if player:IsValid() then
            player:Kick("Out of Lives - Game Over")
            Console.Log("Kicked player " .. player:GetName() .. " for running out of lives")
          end
        end, 3000) -- Give them 3 seconds to see the message
        return
      end

      player:SetDimension(1) -- Return to Nexus
      self:SetDimension(1)
      self:SetLocation(Vector(0, 0, 10000))
      Events.CallRemote("PlayOST", player, "1.ogg")
      Timer.SetTimeout(function(_char)
        _char:Respawn()
        RewardSystem.ApplyRewards(character)
      end, 5000, self)
    end)

  Timer.SetInterval(function(_char)
    if not _char:IsValid() then return false end
    if _char:GetLocation().Z < -400 then
      _char:SetLocation(Vector(0, 0, 100))
    end
  end, 1000, character)
  player:Possess(character)

  -- Apply rewards based on global objectives completed
  RewardSystem.ApplyRewards(character)
end

Player.Subscribe("Destroy", function(player)
  local character = player:GetControlledCharacter()
  if (character) then
    character:Destroy()
  end
  if #Player.GetAll() == 0 then
    for k, v in pairs(Server.GetPackages(true)) do
      Console.Log("The dream shambles")
      Server.ReloadPackage(v.name)
    end
  end
end)

Player.Subscribe("Spawn", function(player)
  -- Initialize lives for new player
  InitializePlayerLives(player)

  SpawnCharacter(Vector(0, 0, 100), player)
  -- Sync moon scale to the new player
  SyncMoonScaleToPlayer(player)
  -- Sync objectives to the new player
  RewardSystem.SyncObjectivesToPlayer(player)
end)

Package.Subscribe("Load", function()
  for k, v in pairs(Player.GetAll()) do
    -- Initialize lives for existing players
    InitializePlayerLives(v)

    SpawnCharacter(Vector(0, 0, 100), v)
    -- Sync moon scale to all players on package load
    SyncMoonScaleToPlayer(v)
    -- Sync objectives to all players on package load
    RewardSystem.SyncObjectivesToPlayer(v)
  end
end)

Package.Require("Maps/Nexus.lua")

Player.Subscribe("DimensionChange", function(self, old_dimension, new_dimension)
  Console.Log("Dimension changed from " .. old_dimension .. " to " .. new_dimension)
  Events.CallRemote("DimensionChange", self, old_dimension, new_dimension)
end)

--[[
    ENDGAME FUNCTION

    This function is automatically triggered when all 10 objectives are completed
    (see RewardSystem.IncrementGlobalObjectives for the trigger logic).

    SEQUENCE:
    1. Sets Sky to clear (removes fog, sets normal brightness)
    2. Sets Weather to clear (removes rain/storms)
    3. Sets Moon angle to 60 degrees (visible position)
    4. Unpossesses all players from their characters
    5. Disables player input (no movement/interaction)
    6. Translates camera to look up at the moon
    7. Rolls credits on the WebUI for 30 seconds
    8. Kicks all players with message "Thanks for Playing"

    MANUAL TRIGGER:
    To manually test/trigger the endgame sequence, run in console:
        EndGame()

    CUSTOMIZATION:
    - Change moon angle: modify the value passed to EndGameSetMoon (line 250)
    - Change credits duration: modify the timeout value (line 276)
    - Change kick message: modify the string in player:Kick() (line 281)
    - Edit credits content: see Client/UI/index.html (credits-content section)
    - Change sky settings: see Client/Index.lua (EndGameSetSky handler)
--]]
function EndGame()
  Console.Log("=== ENDGAME SEQUENCE INITIATED ===")

  -- Get all players before we start the sequence
  local all_players = Player.GetAll()

  if #all_players == 0 then
    Console.Warn("No players connected for EndGame sequence")
    return
  end

  -- 1. Set Sky to clear on all clients
  Events.BroadcastRemote("EndGameSetSky")

  -- 2. Set Weather to clear on all clients
  Events.BroadcastRemote("EndGameSetWeather")

  -- 3. Set moon to 60 degrees on all clients
  Events.BroadcastRemote("EndGameSetMoon", 60)

  -- 4. For each player: Unpossess, disable input, and prepare for credits
  for _, player in ipairs(all_players) do
    if player:IsValid() then
      local character = player:GetControlledCharacter()

      -- Unpossess the character
      if character and character:IsValid() then
        player:UnPossess()
      end

      -- Disable player input
      Events.CallRemote("EndGameDisableInput", player)

      -- Translate camera to the moon (client-side)
      Events.CallRemote("EndGameTranslateCamera", player)

      Console.Log("Prepared player " .. player:GetName() .. " for EndGame sequence")
    end
  end

  -- 5. Roll out credits on all clients (use the defined WebUI)
  Events.BroadcastRemote("EndGameRollCredits")

  -- 6. After credits are done (estimated 30 seconds), kick all players
  Timer.SetTimeout(function()
    Console.Log("Credits finished - Kicking all players")

    for _, player in ipairs(Player.GetAll()) do
      if player:IsValid() then
        player:Kick("Thanks for Playing")
        Console.Log("Kicked player: " .. player:GetName())
      end
    end

    Console.Log("=== ENDGAME SEQUENCE COMPLETED ===")
  end, 30000) -- 30 seconds for credits duration
end
