-- Bloodhound - A terrifying stalker entity that extends Character
-- Erratic, unpredictable, and nightmare-inducing

-- Extend the Character class
Bloodhound = {}
Bloodhound.__index = Bloodhound
setmetatable(Bloodhound, { __index = Character })

-- Available animations to randomly play
local BloodhoundAnimations = {
    "nanos-world::AM_Mannequin_CoffinDance",
    "nanos-world::AM_Mannequin_Torch_Attack",
    "nanos-world::AM_Mannequin_Melee_Bayonet_Stab_Attack",
    "nanos-world::AM_Mannequin_Melee_Slash_Attack",
    "nanos-world::A_Zombie_Chase_Loop",
    "nanos-world::A_Zombie_Attack_Loop",
}

-- Props that can randomly spawn
local RandomProps = {
    "nanos-world::SM_Rock_03",
    "nanos-world::SM_Rock_04",
    "nanos-world::SM_Rock_05",
    "nanos-world::SM_Rock_06",
    "nanos-world::SM_Rock_07",
}

-- Create a new Bloodhound instance
function Bloodhound.new(location, dimension_id, difficulty)
    local character = Character(
        location,
        Rotator(0, math.random(0, 360), 0),
        "nanos-world::SK_Mannequin",
        CollisionType.Normal,
        true,
        5 * difficulty
    )

    local self = setmetatable({}, Bloodhound)
    self.character = character
    self.dimension_id = dimension_id
    self.target_player = nil
    self.is_active = true
    self.spawned_props = {}
    self.timers = {}
    self.difficulty = difficulty or 1

    -- Set dimension
    character:SetDimension(dimension_id)

    -- Make it creepy
    character:SetMaterialColorParameter("Tint", Color(0.0, 0.0, 0.0)) -- Dark

    -- Start all the random behaviors
    self:StartRandomScale()
    self:StartRandomFlicker()
    self:StartRandomSpeed()
    character:PlayAnimation("nanos-world::A_Zombie_HyperChase_Loop", AnimationSlotType.FullBody, true, nil, nil, 2.0)
    self:StartRandomAnimation()
    self:StartPlayerTracking()
    self:StartRandomTeleport()
    self:StartRandomPropSpawning()
    -- Subscribe to death
    character:Subscribe("Death", function(self)
        Events.BroadcastRemoteDimension(self:GetDimension(), "BloodhoundSFX", "inv_wosh.ogg")
        self:Destroy()
    end)

    Console.Log("Bloodhound spawned at " ..
        tostring(character:GetLocation()) .. " in dimension " .. tostring(character:GetDimension()))
    return self
end

-- Random scale changes (separate X, Y, Z)
function Bloodhound:StartRandomScale()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end
        local scale_x = math.random(50, 200) / 100  -- 0.5 to 2.0
        local scale_y = math.random(50, 200) / 100
        local scale_z = math.random(50, 1000) / 100 -- Can be very tall
        self.character:SetScale(Vector(scale_x, scale_y, scale_z))
    end, math.random(20000 / self.difficulty, 30000))

    table.insert(self.timers, timer)
end

-- Random position flickering
function Bloodhound:StartRandomFlicker()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end

        local current_pos = self.character:GetLocation()
        local flicker_offset = Vector(
            math.random(-100, 100),
            math.random(-100, 100),
            0
        )

        self.character:SetLocation(current_pos + flicker_offset)

        -- Flicker back after a brief moment
        Timer.SetTimeout(function()
            if self.is_active and self.character:IsValid() then
                self.character:SetLocation(current_pos)
            end
        end, math.random(50, 150))
    end, math.random(100, 500))

    table.insert(self.timers, timer)
end

-- Random speed multiplier changes
function Bloodhound:StartRandomSpeed()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end
        self.character:SetSpeedMultiplier(math.random(5, 20))
    end, math.random(1000, 3000))

    table.insert(self.timers, timer)
end

-- Random animation playing
function Bloodhound:StartRandomAnimation()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end

        local anim = BloodhoundAnimations[math.random(#BloodhoundAnimations)]
        self.character:PlayAnimation(anim, AnimationSlotType.FullBody, false, 1.0)
    end, math.random(2000, 5000))

    table.insert(self.timers, timer)
end

-- Random prop spawning
function Bloodhound:StartRandomPropSpawning()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end

        local char_pos = self.character:GetLocation()
        local prop_mesh = RandomProps[math.random(#RandomProps)]

        local prop = Prop(
            char_pos + Vector(math.random(-200, 200), math.random(-200, 200), math.random(50, 200)),
            Rotator(math.random(0, 360), math.random(0, 360), math.random(0, 360)),
            prop_mesh,
            CollisionType.NoCollision,
            true
        )

        local trigger = Trigger(prop:GetLocation(), Rotator(0, 0, 0), Vector(100), TriggerType.Sphere, false,
            Color(0, 1, 0), { "Character" })
        trigger:AttachTo(prop, nil, nil, 0)
        trigger:Subscribe("BeginOverlap", function(trigger, actor)
            local g = Grenade(
                trigger:GetLocation(),
                Rotator(0, 90, 90),
                "nanos-world::SM_None",
                "nanos-world::P_Grenade_Special",
                "nanos-world::A_Explosion_Large"
            )
            g:SetDimension(self.dimension_id)
            g:Explode()
            trigger:Destroy()
        end)


        prop:SetDimension(self.dimension_id)
        trigger:SetDimension(self.dimension_id)
        prop:SetMaterialColorParameter("Tint", Color(100, 0, 0))
        prop:TranslateTo(char_pos + Vector(math.random(-2000, 2000), math.random(-2000, 2000), math.random(-200, 200)), 1,
            2)

        table.insert(self.spawned_props, prop)

        -- Destroy prop after a while
        Timer.SetTimeout(function()
            if prop:IsValid() then
                prop:Destroy()
            end
        end, math.random(200, 5000))
    end, math.random(300, 7000))

    table.insert(self.timers, timer)
end

-- Random movement (MoveTo, TranslateTo, SetLocation)
function Bloodhound:StartRandomMovement()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end

        local movement_type = math.random(1, 3)
        local char_pos = self.character:GetLocation()

        if movement_type == 1 then
            local target_pos = char_pos + Vector(
                math.random(-5000, 5000),
                math.random(-5000, 5000),
                0
            )
            self.character:MoveTo(target_pos, 1)
        elseif movement_type == 2 then
            local target_pos = char_pos + Vector(
                math.random(-300, 300),
                math.random(-300, 300),
                math.random(-50, 50)
            )
            self.character:SetLocation(target_pos)
        else
            local target_pos = char_pos + Vector(
                math.random(-200, 200),
                math.random(-200, 200),
                Vector(1)
            )
            self.character:SetLocation(target_pos)
        end
    end, math.random(200, 30000))

    table.insert(self.timers, timer)
end

-- Player tracking and chasing
function Bloodhound:StartPlayerTracking()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end

        -- Find nearest player in same dimension
        local players = Player.GetAll()
        local nearest_player = nil
        local nearest_distance = math.huge
        local char_pos = self.character:GetLocation()

        for _, player in pairs(players) do
            if player:GetDimension() == self.dimension_id then
                local player_char = player:GetControlledCharacter()
                if player_char and player_char:IsValid() then
                    local player_pos = player_char:GetLocation()
                    local distance = (player_pos - char_pos):Size()

                    if distance < nearest_distance then
                        nearest_distance = distance
                        nearest_player = player
                    end
                end
            end
        end

        if nearest_player then
            self.target_player = nearest_player
            local player_char = nearest_player:GetControlledCharacter()

            if player_char and player_char:IsValid() then
                local player_pos = player_char:GetLocation()
                self.character:MoveTo(player_pos)

                -- Check for jumpscare distance (very close)
                if nearest_distance < 300 then
                    Events.CallRemote("TriggerJumpscare", nearest_player)
                    Events.BroadcastRemoteDimension(self.dimension_id, "BloodhoundSFX",
                        "painful_" .. tostring(math.random(1, 105)) .. ".ogg")
                    player_char:ApplyDamage(3 * self.difficulty)
                    if math.random() > 0.5 then
                        self:Destroy()
                    end
                end

                -- Sometimes move toward player
                if math.random() > 0.5 then
                    if character and character:IsValid() then
                        self.character:MoveTo(player_pos, 1)
                    end
                    return false
                else
                end
            end
        end
    end, math.random(100, 200))

    table.insert(self.timers, timer)
end

-- Random teleportation behind player
function Bloodhound:StartRandomTeleport()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then
            self.target_player = nil
            self:Destroy()
            return
        end

        if self.target_player and math.random() > 0.75 then
            local player_char = self.target_player:GetControlledCharacter()
            if player_char and player_char:IsValid() then
                -- Teleport behind player
                local player_pos = player_char:GetLocation()
                local player_rot = player_char:GetRotation()

                -- Calculate position behind player
                local behind_distance = math.random(0, 500)
                local behind_offset = Vector(
                    -behind_distance * math.cos(math.rad(player_rot.Yaw)),
                    -behind_distance * math.sin(math.rad(player_rot.Yaw)),
                    0
                )

                self.character:SetLocation(player_pos + behind_offset)
            end
        end
    end, math.random(5000, 10000))

    table.insert(self.timers, timer)
end

-- Get the underlying character entity
function Bloodhound:GetCharacter()
    return self.character
end

-- Check if bloodhound is valid
function Bloodhound:IsValid()
    return self.is_active and self.character and self.character:IsValid()
end

-- Destroy the bloodhound
function Bloodhound:Destroy()
    self.is_active = false

    -- Clear all timers
    for _, timer in ipairs(self.timers) do
        Timer.ClearInterval(timer)
    end

    -- Destroy spawned props
    for _, prop in ipairs(self.spawned_props) do
        if prop:IsValid() then
            prop:Destroy()
        end
    end

    -- Destroy character
    if self.character and self.character:IsValid() then
        self.character:Destroy()
    end

    Console.Log("Bloodhound destroyed")
end

Console.Log("Bloodhound class loaded")
