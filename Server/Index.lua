Package.Require("Debug.lua")
Package.Require("Bloodhound.lua")
Server.LoadPackage("default-vehicles")
Server.LoadPackage("default-weapons")

-- Moon Scale tracking (1-50, represents game progress)
MoonScale = 1

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

function SpawnCharacter(pos, player)
  local character = Character(pos, Rotator(), "nanos-world::SK_Mannequin")
  character:SetInvulnerable(true)
  character:SetMaxHealth(100000000)
  character:SetHealth(100000000)
  character:SetSpeedMultiplier(10)
  Character.Subscribe("Interact", function(self, prop)
    if prop:IsA(Prop) then
      return false
    end
  end)
  Timer.SetInterval(function(_char)
    if _char:GetLocation().Z < -400 then
      _char:SetLocation(Vector(0, 0, 100))
    end
  end, 1000, character)
  player:Possess(character)
end

Player.Subscribe("Destroy", function(player)
  local character = player:GetControlledCharacter()
  if (character) then
    character:Destroy()
  end
end)

Player.Subscribe("Spawn", function(player)
  SpawnCharacter(Vector(0, 0, 100), player)
  -- Sync moon scale to the new player
  SyncMoonScaleToPlayer(player)
end)

Package.Subscribe("Load", function()
  for k, v in pairs(Player.GetAll()) do
    SpawnCharacter(Vector(0, 0, 100), v)
    -- Sync moon scale to all players on package load
    SyncMoonScaleToPlayer(v)
  end
  
  -- Start periodic lore messages every 3 minutes (180 seconds)
  Timer.SetInterval(function()
    SendLoreMessage("periodic")
  end, 180000)
end)

Package.Require("Maps/Nexus.lua")

Player.Subscribe("DimensionChange", function(self, old_dimension, new_dimension)
  Console.Log("Dimension changed from " .. old_dimension .. " to " .. new_dimension)
  Events.CallRemote("DimensionChange", self, old_dimension, new_dimension)
end)
