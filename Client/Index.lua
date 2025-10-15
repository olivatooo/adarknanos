Input.Register("SpawnMenu", "Q")

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
  Sky.Spawn()
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
                night_brightness, overall_intensity, moon_texture)
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
  Sky.Reconstruct()
end

function SetSkyConfig(sky_config)
  Console.Log("Applying new sky config")
  SetSky(sky_config.Hour, sky_config.MoonAngle, sky_config.Fog, sky_config.MoonGlowIntensity,
    sky_config.MoonLightIntensity, sky_config.MoonPhase, sky_config.MoonScale, sky_config.NightBrightness,
    sky_config.OverallIntensity, sky_config.MoonTexture)
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

Package.Require("Dimensions.lua")
