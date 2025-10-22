Events.SubscribeRemote("BloodhoundSFX", function(sound_name, location, spatial, volume, pitch)
  local radio = Sound(
    location or Vector(),                                    -- Location (if a 3D sound)
    "package://adarknanos/Client/Bloodhound/" .. sound_name, -- Asset Path
    true,                                                    -- Is 2D Sound
    true,                                                    -- Auto Destroy (if to destroy after finished playing)
    SoundType.SFX,
    volume or 1,                                             -- Volume
    pitch or 1,                                              -- Pitch
    nil,
    nil,
    nil,
    nil,
    SoundLoopMode.Never
  )
end)
