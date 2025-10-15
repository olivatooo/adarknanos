Package.Require("Debug.lua")

function SpawnCharacter(pos, player)
  local character = Character(pos, Rotator(), "nanos-world::SK_Mannequin")
  character:SetInvulnerable(true)
  character:SetMaxHealth(100000000)
  character:SetHealth(100000000)
  character:SetSpeedMultiplier(10)
  Character.Subscribe("Interact", function(self, prop)
    return false
  end)
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
end)

Package.Subscribe("Load", function()
  for k, v in pairs(Player.GetAll()) do
    SpawnCharacter(Vector(0, 0, 100), v)
  end
end)

Package.Require("Maps/Nexus.lua")
