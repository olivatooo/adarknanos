-- Door configuration data
DoorToNexus = {
  sm = "nanos-world::SM_Bed",
  custom_texture = nil,
  custom_color = Color(1, 1, 1),
  spawn_function = nil,
  unlocked = false,
  dimension = 1,
  name = "Nexus",
  ost = "1.ogg",
  SkyConfig = {
    Hour = 3,
    MoonAngle = 90,
    Fog = 10,
    MoonGlowIntensity = 0.5,
    MoonLightIntensity = 0.5,
    MoonPhase = 0,
    NightBrightness = 1,
    OverallIntensity = 1,
    VolumetricCloudColor = Color(100, 1, 1),
    SkyMode = SkyMode.VolumetricClouds,
    MoonScale = 1.0, -- Will be dynamically updated based on game progress (1-50)
  }
}

DoorToWilderness = {
  sm = "nanos-world::SM_Portapotty_Door",
  custom_texture = nil,
  custom_color = Color(9, 0.33, 0.97), -- Hot pink
  spawn_function = nil,
  unlocked = false,
  dimension = 2,
  name = "Wilderness",
  ost = "2.ogg",
  SkyConfig = {
    Hour = 12,
    MoonAngle = 0,
    Fog = 0,
    MoonGlowIntensity = 0,
    MoonLightIntensity = 0,
    MoonPhase = 0,
    NightBrightness = 0,
    OverallIntensity = 0,
    VolumetricCloudColor = Color(1, 1, 1),
    SkyMode = SkyMode.VolumetricClouds,
    MoonScale = 1.0,
  }
}

DoorToBaloonWorld = {
  sm = "nanos-world::SM_Portapotty_Door",
  custom_texture = nil,
  custom_color = Color(0, 1, 0.85), -- Cyan
  spawn_function = nil,
  unlocked = false,
  dimension = 3,
  name = "Baloon World",
  ost = "3.ogg",
  SkyConfig = {
    Hour = 12,
    MoonAngle = 0,
    Fog = 0,
    MoonGlowIntensity = 0,
    MoonLightIntensity = 0,
    MoonPhase = 0,
    NightBrightness = 0,
    OverallIntensity = 0,
    VolumetricCloudColor = Color(1, 1, 1),
    SkyMode = SkyMode.VolumetricClouds,
    MoonScale = 1.0,
  }
}

DoorToRoundMaze = {
  sm = "nanos-world::SM_Cube",
  custom_texture = nil,
  custom_color = Color(0.53, 0.12, 0.92), -- Deep purple
  spawn_function = nil,
  unlocked = false,
  dimension = 4,
  name = "Round Maze",
  ost = "4.ogg",
  SkyConfig = {
    Hour = 20,
    MoonAngle = 45,
    Fog = 0.3,
    MoonGlowIntensity = 0.5,
    MoonLightIntensity = 0.3,
    MoonPhase = 0.5,
    NightBrightness = 0.5,
    OverallIntensity = 0.7,
    VolumetricCloudColor = Color(0.53, 0.12, 0.92), -- Match door color
    SkyMode = SkyMode.VolumetricClouds,
    MoonScale = 1.0,
  }
}

DoorToShack = {
  sm = "nanos-world::SM_Portapotty_Door",
  custom_texture = nil,
  custom_color = Color(0.98, 0.69, 0.91), -- Light pink
  spawn_function = nil,
  unlocked = false,
  dimension = 5,
  name = "Shack",
  ost = "5.ogg",
  SkyConfig = {
    Hour = 12,
    MoonAngle = 0,
    Fog = 0,
    MoonGlowIntensity = 0,
    MoonLightIntensity = 0,
    MoonPhase = 0,
    NightBrightness = 0,
    OverallIntensity = 0,
    VolumetricCloudColor = Color(1, 1, 1),
    SkyMode = SkyMode.VolumetricClouds,
    MoonScale = 1.0,
  }
}

DoorToConstructionHell = {
  sm = "nanos-world::SM_OilDrum",
  custom_texture = nil,
  custom_color = Color(0.13, 0.84, 0.94), -- Electric blue
  spawn_function = nil,
  unlocked = false,
  dimension = 6,
  name = "Construction",
  ost = "6.ogg",
  SkyConfig = {
    Hour = 3,
    MoonAngle = 90,
    Fog = 20,
    MoonGlowIntensity = 10,
    MoonLightIntensity = 10,
    MoonPhase = 0,
    NightBrightness = 0,
    OverallIntensity = 0,
    VolumetricCloudColor = Color(100, 1, 1),
    SkyMode = SkyMode.VolumetricClouds,
    MoonScale = 1.0,
    Weather = WeatherType.Snow
  }
}

DoorToCrateWorld = {
  sm = "nanos-world::SM_Portapotty_Door",
  custom_texture = nil,
  custom_color = Color(0.94, 0.23, 0.55), -- Neon pink
  spawn_function = nil,
  unlocked = false,
  dimension = 7,
  name = "Crate",
  ost = "7.ogg",
  SkyConfig = {
    Hour = 12,
    MoonAngle = 0,
    Fog = 0,
    MoonGlowIntensity = 0,
    MoonLightIntensity = 0,
    MoonPhase = 0,
    NightBrightness = 0,
    OverallIntensity = 0,
    VolumetricCloudColor = Color(1, 1, 1),
    SkyMode = SkyMode.VolumetricClouds,
    MoonScale = 1.0,
  }
}

DoorToBamboo = {
  sm = "nanos-world::SM_Portapotty_Door",
  custom_texture = nil,
  custom_color = Color(0.49, 0.98, 0.83), -- Turquoise
  spawn_function = nil,
  unlocked = false,
  dimension = 8,
  name = "Bamboo",
  ost = "8.ogg",
  SkyConfig = {
    Hour = 12,
    MoonAngle = 0,
    Fog = 0,
    MoonGlowIntensity = 0,
    MoonLightIntensity = 0,
    MoonPhase = 0,
    NightBrightness = 0,
    OverallIntensity = 0,
    VolumetricCloudColor = Color(1, 1, 1),
    SkyMode = SkyMode.VolumetricClouds,
    MoonScale = 1.0,
  }
}

DoorToSpiral = {
  sm = "nanos-world::SM_Sphere",
  custom_texture = nil,
  custom_color = Color(96, 76, 5), -- Golden yellow
  spawn_function = nil,
  unlocked = false,
  dimension = 9,
  name = "Uzumaki",
  ost = "9.ogg",
  SkyConfig = {
    Hour = 3,
    MoonAngle = 90,
    Fog = 0,
    MoonGlowIntensity = 0,
    MoonLightIntensity = 0,
    MoonPhase = 0,
    NightBrightness = 0,
    OverallIntensity = 0,
    VolumetricCloudColor = Color(1, 1, 1),
    SkyMode = SkyMode.VolumetricClouds,
    MoonScale = 1.0,
    MoonTexture = "package://adarknanos/Client/uzumaki.jpg"
  },
}

DoorToFood = {
  sm = "nanos-world::SM_Portapotty_Door",
  custom_texture = nil,
  custom_color = Color(0.58, 0.44, 0.86), -- Lavender
  spawn_function = nil,
  unlocked = false,
  dimension = 10,
  name = "Food"
}

DoorToEmojiWorld = {
  sm = "nanos-world::SM_Portapotty_Door",
  custom_texture = nil,
  custom_color = Color(0.95, 0.55, 0.92), -- Bubblegum pink
  spawn_function = nil,
  unlocked = false,
  dimension = 11,
  name = "Emoji"
}

Doors = {
  DoorToWilderness,
  DoorToBaloonWorld,
  DoorToRoundMaze,
  DoorToShack,
  DoorToConstructionHell,
  DoorToCrateWorld,
  DoorToBamboo,
  DoorToSpiral,
  DoorToFood,
  DoorToEmojiWorld,
}
