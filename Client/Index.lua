Package.Require("Bloodhound/Index.lua")

Input.Register("SpawnMenu", "Q")
Sky.Spawn(true)

Input.Subscribe("KeyDown", function(key_name)
  if key_name == "P" then
    Events.CallRemote("ReloadPackages")
    SpawnSky(true)
  end
  if key_name == "9" then
    Events.CallRemote("ReloadPackages")
    SpawnSky(true)
  end
end)


function SpawnSky(lock_timer)
  if lock_timer then
    LockTimer = Timer.SetInterval(function()
      local ret_01, ret_02, ret_03 = Sky.GetTimeOfDay()
      Sky.SetTimeOfDay(ret_01, ret_02)
    end)
  else
    LockTimer.Pause()
  end
end

function SetSky(hour, moon_angle, fog, moon_glow_intensity, moon_light_intensity, moon_phase, moon_scale,
                night_brightness, overall_intensity, moon_texture, weather)
  Sky.SetTimeOfDay(hour, 0)
  Sky.SetMoonAngle(moon_angle, 0)
  Sky.SetFog(fog)
  Sky.SetMoonGlowIntensity(moon_glow_intensity)
  Sky.SetMoonLightIntensity(moon_light_intensity)
  Sky.SetMoonPhase(moon_phase)
  Sky.SetMoonScale(moon_scale)
  Sky.SetNightBrightness(night_brightness)
  Sky.SetOverallIntensity(overall_intensity)
  -- Sky.SetMoonTexture(moon_texture)
  if weather ~= nil then
    Sky.ChangeWeather(weather, 0)
  end
  Sky.Reconstruct()
end

function SetSkyConfig(sky_config)
  Console.Log("Applying new sky config")
  SetSky(sky_config.Hour, sky_config.MoonAngle, sky_config.Fog, sky_config.MoonGlowIntensity,
    sky_config.MoonLightIntensity, sky_config.MoonPhase, sky_config.MoonScale, sky_config.NightBrightness,
    sky_config.OverallIntensity, sky_config.MoonTexture, sky_config.Weather)
end

Events.SubscribeRemote("SetSky", SetSky)

-- Moon scale tracking (synced from server)
CurrentMoonScale = 1

-- Event to receive moon scale updates from server
Events.SubscribeRemote("UpdateMoonScale", function(new_moon_scale)
  CurrentMoonScale = new_moon_scale
  Console.Log("Moon Scale updated to: " .. CurrentMoonScale)
  Sky.SetMoonScale(CurrentMoonScale)
  Sky.Reconstruct()
end)

SpawnSky(true)
SetSkyConfig(DoorToNexus.SkyConfig)

-- Apply current moon scale after initial sky setup
Timer.SetTimeout(function()
  Sky.SetMoonScale(CurrentMoonScale)
  Sky.Reconstruct()
end, 100) -- Small delay to ensure sky is fully initialized


-- Loading a local file
local my_ui = WebUI(
  "Awesome UI",            -- Name
  "file://UI/index.html",  -- Path relative to this package (Client/)
  WidgetVisibility.Visible -- Is Visible on Screen
)

-- Objectives tracking (synced from server)
CurrentObjectivesCompleted = 0

-- Event to receive objectives updates from server
Events.SubscribeRemote("UpdateObjectivesCompleted", function(objectives_completed)
  CurrentObjectivesCompleted = objectives_completed
  Console.Log("Objectives completed updated to: " .. CurrentObjectivesCompleted)

  -- Update the UI
  my_ui:CallEvent("UpdateObjectivesUI", objectives_completed)
end)

-- Subscribe to jumpscare trigger from server
Events.SubscribeRemote("TriggerJumpscare", function()
  Console.Log("Jumpscare received from server!")
  my_ui:CallEvent("TriggerJumpscare")

  -- Camera shake effect
  local my_char = Client.GetLocalPlayer():GetControlledCharacter()
  if my_char and my_char:IsValid() then
    -- Reset camera shake after jumpscare
  end
end)

Package.Require("Dimensions.lua")

-- ===== ENDGAME SEQUENCE HANDLERS =====

-- Handler: Set Sky to clear
Events.SubscribeRemote("EndGameSetSky", function()
  Console.Log("EndGame: Setting sky to clear")
  Sky.SetFog(0)
  Sky.SetOverallIntensity(1.0)
  Sky.Reconstruct()
end)

-- Handler: Set Weather to clear
Events.SubscribeRemote("EndGameSetWeather", function()
  Console.Log("EndGame: Setting weather to clear")
  Sky.ChangeWeather(WeatherType.Clear, 2)
end)

-- Handler: Set Moon to specified angle
Events.SubscribeRemote("EndGameSetMoon", function(angle)
  Console.Log("EndGame: Setting moon angle to " .. tostring(angle))
  Sky.SetMoonAngle(angle, 0)
  Sky.SetMoonScale(30)
  Sky.Reconstruct()
end)

-- Handler: Disable player input
Events.SubscribeRemote("EndGameDisableInput", function()
  Console.Log("EndGame: Disabling input")
  Input.SetInputEnabled(false)
  Input.SetMouseEnabled(false)
end)

-- Handler: Translate camera to the moon
Events.SubscribeRemote("EndGameTranslateCamera", function()
  Console.Log("EndGame: Translating camera to moon")

  local player = Client.GetLocalPlayer()
  if not player then return end

  -- Create a camera transition effect by manipulating the spectator camera
  -- The exact implementation depends on the nanos-world API capabilities
  -- This is a placeholder that attempts to look upward toward the moon

  local character = player:GetControlledCharacter()
  if character and character:IsValid() then
    -- Set camera to look up at the moon (pitch of -60 to look up at 60 degree moon)
    character:SetCameraRotation(Rotator(-60, 0, 0))
  end

  -- Smooth camera transition over 3 seconds
  Timer.SetTimeout(function()
    if character and character:IsValid() then
      character:SetCameraRotation(Rotator(-70, 0, 0))
    end
  end, 1000)

  Timer.SetTimeout(function()
    if character and character:IsValid() then
      character:SetCameraRotation(Rotator(-80, 0, 0))
    end
  end, 2000)
end)

-- Handler: Roll credits using the WebUI
Events.SubscribeRemote("EndGameRollCredits", function()
  Console.Log("EndGame: Rolling credits")
  my_ui:CallEvent("RollCredits")
end)

-- ===== PLAYER HUD SYSTEM =====
-- Based on nanos world documentation: https://docs.nanos-world.com/docs/getting-started/tutorials-and-examples/basic-hud-html

-- Event handler for lives update from server
Events.SubscribeRemote("UpdatePlayerLives", function(lives_remaining)
  Console.Log("Lives updated: " .. tostring(lives_remaining))
  my_ui:CallEvent("UpdateLives", lives_remaining)
end)

-- Function to update the Health's UI
function UpdateHealth(health, max_health)
  my_ui:CallEvent("UpdateHealth", health, max_health)
end

-- Function to update the Ammo's UI
function UpdateAmmo(ammo_clip, ammo_bag)
  my_ui:CallEvent("UpdateAmmo", ammo_clip, ammo_bag)
end

-- Function to set all needed events on local character (to update the UI when it takes damage or dies)
function UpdateLocalCharacter(character)
  -- Verifies if character is not nil (eg. when GetControlledCharacter() doesn't return a character)
  if (character == nil) then return end
  
  Console.Log("Setting up HUD for character")
  
  -- Updates the UI with the current character's health
  UpdateHealth(character:GetHealth(), character:GetMaxHealth())
  
  -- Sets on character an event to update the health's UI after it takes damage
  character:Subscribe("TakeDamage", function(charac, damage, bone, type, from_direction, instigator, causer)
    UpdateHealth(math.max(charac:GetHealth() - damage, 0), charac:GetMaxHealth())
  end)
  
  -- Sets on character an event to update the health's UI after it dies
  character:Subscribe("Death", function(charac)
    UpdateHealth(0, charac:GetMaxHealth())
  end)
  
  -- Try to get if the character is holding any weapon
  local current_picked_item = character:GetPicked()
  
  -- If so, update the UI
  if (current_picked_item and current_picked_item:IsA(Weapon)) then
    UpdateAmmo(current_picked_item:GetAmmoClip(), current_picked_item:GetAmmoBag())
  else
    UpdateAmmo(0, 0)
  end
  
  -- Sets on character an event to update his grabbing weapon (to show ammo on UI)
  character:Subscribe("PickUp", function(charac, object)
    if (object:IsA(Weapon)) then
      UpdateAmmo(object:GetAmmoClip(), object:GetAmmoBag())
    end
  end)
  
  -- Sets on character an event to remove the ammo ui when he drops it's weapon
  character:Subscribe("Drop", function(charac, object)
    if (object:IsA(Weapon)) then
      UpdateAmmo(0, 0)
    end
  end)
  
  -- Sets on character an event to update the UI when he fires
  character:Subscribe("Fire", function(charac, weapon)
    UpdateAmmo(weapon:GetAmmoClip(), weapon:GetAmmoBag())
  end)
  
  -- Sets on character an event to update the UI when he reloads the weapon
  character:Subscribe("Reload", function(charac, weapon, ammo_to_reload)
    UpdateAmmo(weapon:GetAmmoClip(), weapon:GetAmmoBag())
  end)
end

-- When LocalPlayer spawns, sets an event on it to trigger when we possess a new character, 
-- to store the local controlled character locally. This event is only called once, 
-- see Package:Subscribe("Load") to load it when reloading a package
Client.Subscribe("SpawnLocalPlayer", function(local_player)
  Console.Log("Local player spawned - subscribing to Possess event")
  local_player:Subscribe("Possess", function(player, character)
    Console.Log("Player possessed character - updating HUD")
    UpdateLocalCharacter(character)
  end)
end)

-- When package loads, verify if LocalPlayer already exists (eg. when reloading the package), 
-- then try to get and store its controlled character
Package.Subscribe("Load", function()
  Console.Log("Package loaded - checking for existing local player")
  local local_player = Client.GetLocalPlayer()
  if (local_player ~= nil) then
    Console.Log("Local player found - updating controlled character")
    UpdateLocalCharacter(local_player:GetControlledCharacter())
  end
end)

Console.Log("Player HUD system initialized on client (event-based)")
