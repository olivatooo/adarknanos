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
  Sky.SetTimeOfDay(3, 0)
  Sky.SetMoonAngle(0, 0)
  -- Sky.SetFog(35.0)
  -- Sky.SetMoonGlowIntensity(0)
  -- Sky.SetMoonLightIntensity(0)
  -- Sky.SetMoonPhase(0)
  -- Sky.SetMoonScale(0)
  -- Sky.SetNightBrightness(0)
  -- Sky.SetOverallIntensity(0)
  Sky.SetVolumetricCloudColor(Color(100, 0, 0))
  Sky.SetSkyMode(SkyMode.VolumetricClouds)
  Sky.SetMoonScale(50.0)
  Sky.Reconstruct()
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
                night_brightness, overall_intensity)
  Sky.SetTimeOfDay(hour, 0)
  Sky.SetMoonAngle(moon_angle, 0)
  Sky.SetFog(fog)
  Sky.SetMoonGlowIntensity(moon_glow_intensity)
  Sky.SetMoonLightIntensity(moon_light_intensity)
  Sky.SetMoonPhase(moon_phase)
  Sky.SetMoonScale(moon_scale)
  Sky.SetNightBrightness(night_brightness)
  Sky.SetOverallIntensity(overall_intensity)
end

Events.SubscribeRemote("SetSky", SetSky)

SpawnSky(true)


-- Loading a local file
local my_ui = WebUI(
    "Awesome UI",            -- Name
    "file://UI/index.html",  -- Path relative to this package (Client/)
    WidgetVisibility.Visible  -- Is Visible on Screen
)