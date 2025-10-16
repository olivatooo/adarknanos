-- Bloodhound - A terrifying stalker entity that extends Character
-- Erratic, unpredictable, and nightmare-inducing

-- Extend the Character class
Bloodhound = {}
Bloodhound.__index = Bloodhound
setmetatable(Bloodhound, { __index = Character })

-- Available animations to randomly play
local BloodhoundAnimations = {
    "nanos-world::AM_Mannequin_Rifle_Idle",
    "nanos-world::AM_Mannequin_Crouched_Idle",
    "nanos-world::AM_Mannequin_Prone_Idle",
    "nanos-world::A_MannequinCharacter_Throw",
    "nanos-world::AM_Mannequin_Crouch_Moving",
}

-- Props that can randomly spawn
local RandomProps = {
    "nanos-world::SM_Cube",
    "nanos-world::SM_Sphere",
    "nanos-world::SM_Cylinder",
    "nanos-world::SM_Cone",
    "nanos-world::SM_WoodenCrate",
    "nanos-world::SM_WoodenCrate_02",
}

-- Create a new Bloodhound instance
function Bloodhound.new(location, dimension_id)
    -- Spawn the base character
    local character = Character(
        location,
        Rotator(0, math.random(0, 360), 0),
        "nanos-world::SK_Mannequin",
        CollisionType.Normal,
        true,
        1 -- Only 1 health
    )

    local self = setmetatable({}, Bloodhound)
    self.character = character
    self.dimension_id = dimension_id
    self.target_player = nil
    self.is_active = true
    self.spawned_props = {}
    self.timers = {}

    -- Set dimension
    character:SetDimension(dimension_id)

    -- Make it creepy
    character:SetMaterialColorParameter("Tint", Color(0.1, 0.1, 0.1)) -- Dark

    -- Start all the random behaviors
    self:StartRandomScale()
    self:StartRandomFlicker()
    self:StartRandomSpeed()
    self:StartRandomAnimation()
    self:StartRandomPropSpawning()
    self:StartRandomMovement()
    self:StartPlayerTracking()
    self:StartRandomTeleport()

    -- Subscribe to death
    character:Subscribe("Death", function()
        self:Destroy()
    end)

    return self
end

-- Random scale changes (separate X, Y, Z)
function Bloodhound:StartRandomScale()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end

        local scale_x = math.random(50, 200) / 100 -- 0.5 to 2.0
        local scale_y = math.random(50, 200) / 100
        local scale_z = math.random(50, 300) / 100 -- Can be very tall

        self.character:SetScale(Vector(scale_x, scale_y, scale_z))
    end, math.random(1000, 3000))

    table.insert(self.timers, timer)
end

-- Random position flickering
function Bloodhound:StartRandomFlicker()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end

        local current_pos = self.character:GetLocation()
        local flicker_offset = Vector(
            math.random(-50, 50),
            math.random(-50, 50),
            math.random(-20, 20)
        )

        self.character:SetLocation(current_pos + flicker_offset)

        -- Flicker back after a brief moment
        Timer.SetTimeout(function()
            if self.is_active and self.character:IsValid() then
                self.character:SetLocation(current_pos)
            end
        end, math.random(50, 150))
    end, math.random(1000, 3000))

    table.insert(self.timers, timer)
end

-- Random speed multiplier changes
function Bloodhound:StartRandomSpeed()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end

        local speed = math.random(50, 300) / 100 -- 0.5 to 3.0
        self.character:SetSpeedMultiplier(speed)
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
            CollisionType.Normal,
            true
        )

        prop:SetDimension(self.dimension_id)
        prop:SetScale(Vector(
            math.random(50, 300) / 100,
            math.random(50, 300) / 100,
            math.random(50, 300) / 100
        ))
        prop:SetMaterialColorParameter("Tint", Color(math.random(0, 100) / 100, 0, 0)) -- Red tint

        table.insert(self.spawned_props, prop)

        -- Destroy prop after a while
        Timer.SetTimeout(function()
            if prop:IsValid() then
                prop:Destroy()
            end
        end, math.random(2000, 5000))
    end, math.random(3000, 7000))

    table.insert(self.timers, timer)
end

-- Random movement (MoveTo, TranslateTo, SetLocation)
function Bloodhound:StartRandomMovement()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end

        local movement_type = math.random(1, 3)
        local char_pos = self.character:GetLocation()

        if movement_type == 1 then
            -- MoveTo random position
            local target_pos = char_pos + Vector(
                math.random(-500, 500),
                math.random(-500, 500),
                0
            )
            self.character:MoveTo(target_pos, 1)
        elseif movement_type == 2 then
            -- TranslateTo random position
            local target_pos = char_pos + Vector(
                math.random(-300, 300),
                math.random(-300, 300),
                math.random(-50, 50)
            )
            self.character:TranslateTo(target_pos, math.random(1, 3))
        else
            -- Instant SetLocation (teleport)
            local target_pos = char_pos + Vector(
                math.random(-200, 200),
                math.random(-200, 200),
                0
            )
            self.character:SetLocation(target_pos)
        end
    end, math.random(2000, 5000))

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

                -- Check for jumpscare distance (very close)
                if nearest_distance < 300 then
                    Events.CallRemote("TriggerJumpscare", nearest_player)

                    -- Attack the player
                    player_char:ApplyDamage(25, "head", nil, self.character)
                end

                -- Sometimes move toward player
                if math.random() > 0.5 then
                    self.character:MoveTo(player_pos, 1)
                end
            end
        end
    end, 500) -- Check frequently for responsive tracking

    table.insert(self.timers, timer)
end

-- Random teleportation behind player
function Bloodhound:StartRandomTeleport()
    local timer = Timer.SetInterval(function()
        if not self.is_active or not self.character:IsValid() then return end

        if self.target_player then
            local player_char = self.target_player:GetControlledCharacter()
            if player_char and player_char:IsValid() then
                -- Teleport behind player
                local player_pos = player_char:GetLocation()
                local player_rot = player_char:GetRotation()

                -- Calculate position behind player
                local behind_distance = math.random(200, 500)
                local behind_offset = Vector(
                    -behind_distance * math.cos(math.rad(player_rot.Yaw)),
                    -behind_distance * math.sin(math.rad(player_rot.Yaw)),
                    0
                )

                self.character:SetLocation(player_pos + behind_offset)

                -- Face the player
                local direction = (player_pos - self.character:GetLocation()):Normalize()
                local yaw = math.deg(math.atan2(direction.Y, direction.X))
                self.character:SetRotation(Rotator(0, yaw, 0))

                -- Sometimes attack immediately after teleport
                if math.random() > 0.7 then
                    Timer.SetTimeout(function()
                        if player_char:IsValid() then
                            player_char:ApplyDamage(15, "head", nil, self.character)
                        end
                    end, 200)
                end
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
