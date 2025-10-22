local radio = Sound(
  Vector(),                                -- Location (if a 3D sound)
  "package://adarknanos/Client/ost/1.ogg", -- Asset Path
  true,                                    -- Is 2D Sound
  true,                                    -- Auto Destroy (if to destroy after finished playing)
  SoundType.Music,
  0.3,                                     -- Volume
  1,                                       -- Pitch
  nil,
  nil,
  nil,
  nil,
  1
)

function PlayOST(ost)
  Console.Log("Playing OST: " .. ost)
  radio:Stop()
  radio:Destroy()
  radio = Sound(
    Vector(),                                  -- Location (if a 3D sound)
    "package://adarknanos/Client/ost/" .. ost, -- Asset Path
    true,                                      -- Is 2D Sound
    true,                                      -- Auto Destroy (if to destroy after finished playing)
    SoundType.Music,
    0.3,                                       -- Volume
    1,                                         -- Pitch
    nil,
    nil,
    nil,
    nil,
    1
  )
  radio:FadeIn(1.0)
end

Events.SubscribeRemote("PlayOST", PlayOST)

function OnDimensionChanged(old_dimension, new_dimension)
  Console.Log("Dimension changed from " .. old_dimension .. " to " .. new_dimension)
  for k, v in pairs(Doors) do
    if v.dimension == new_dimension then
      local sky_config = v.SkyConfig
      if sky_config then
        SetSkyConfig(sky_config)

        -- If entering Nexus (dimension 1), override moon scale with current progress
        if new_dimension == 1 then
          Sky.SetMoonScale(CurrentMoonScale)
          Sky.Reconstruct()
        end
      end

      local ost = v.ost
      Console.Log("Playing OST: " .. ost)
      if ost then
        PlayOST(ost)
      end
    end
  end
end

Events.SubscribeRemote("DimensionChange", OnDimensionChanged)
