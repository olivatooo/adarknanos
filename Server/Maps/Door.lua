-- DimensionDoor Class
DimensionDoor = {}
DimensionDoor.__index = DimensionDoor

--- Creates a new DimensionDoor instance
-- @param location Vector - Position to spawn the door
-- @param rotation Rotator - Rotation of the door
-- @param dimension number - Dimension ID to teleport to
-- @param name string - Display name of the dimension
-- @param color Color - Color tint for the door
-- @param mesh_asset string - Optional custom mesh asset (defaults to portapotty door)
-- @param on_interact function - Optional custom interaction callback
function DimensionDoor.new(location, rotation, dimension, name, color, mesh_asset, on_interact, from_dimension)
    local self = setmetatable({}, DimensionDoor)

    -- Store parameters
    self.location = location
    self.rotation = rotation
    self.dimension = dimension
    self.name = name
    self.color = color or Color(1, 1, 1)
    self.mesh_asset = mesh_asset or "nanos-world::SM_Portapotty_Door"
    self.custom_interact = on_interact


    local clean = Trigger(location, rotation, Vector(500), TriggerType.Sphere, true)

    clean:Subscribe("BeginOverlap", function(self, entity)
        if entity:IsA(StaticMesh) then
            Console.Log("Destroying " .. entity:GetMesh())
            if entity:GetMesh() ~= "nanos-world::SM_Plane" then
                entity:Destroy()
            end
        end
    end)
    clean:SetDimension(dimension or 1)

    local clean2 = Trigger(location, rotation, Vector(500), TriggerType.Sphere, true)

    clean2:Subscribe("BeginOverlap", function(self, entity)
        if entity:IsA(StaticMesh) then
            if entity:GetMesh() ~= "nanos-world::SM_Plane" then
                Console.Log("Destroying " .. entity:GetMesh())
                entity:Destroy()
            end
        end
    end)
    clean2:SetDimension(from_dimension or 1)

    Timer.SetTimeout(function()
        clean:Destroy()
        clean2:Destroy()
    end, 5000)

    -- Create the physical door
    self.prop = Prop(location, rotation, self.mesh_asset, CollisionType.NoCollision, false, GrabMode.Enabled)
    self.prop:SetDimension(from_dimension or 1)
    self.prop:SetMaterialColorParameter("Tint", self.color)

    -- Setup interaction
    self.prop:Subscribe("Interact", function(prop, character)
        return self:OnInteract(character)
    end)

    return self
end

--- Default interaction behavior (teleport player to dimension)
function DimensionDoor:OnInteract(character)
    if self.custom_interact then
        return self.custom_interact(self, character)
    end

    local player = character:GetPlayer()
    if player then
        Chat.BroadcastMessage(player:GetName() .. " dreamed about " .. self.name)
        
        -- Send cryptic lore message for door entry
        local door_lore_messages = {
            "The threshold beckons... what dreams await beyond?",
            "Through the door, the dreamscape shifts...",
            "Another fragment of the mind's labyrinth opens...",
            "The boundary between worlds dissolves...",
            "Step through... the moon watches from above...",
            "Beyond this door lies another piece of the puzzle...",
            "The dream calls... will you answer?",
            "Through the veil of consciousness we pass..."
        }
        local random_lore = door_lore_messages[math.random(#door_lore_messages)]
        Chat.BroadcastMessage(random_lore)
        
        player:SetDimension(self.dimension)
        character:SetDimension(self.dimension)
        Events.CallRemote("DimensionDoorInteracted", player, self.dimension)
    end
    return false
end

--- Destroys the door
function DimensionDoor:Destroy()
    if self.prop and self.prop:IsValid() then
        self.prop:Destroy()
    end
end

--- Changes the door's color
function DimensionDoor:SetColor(color)
    self.color = color
    if self.prop and self.prop:IsValid() then
        self.prop:SetMaterialColorParameter("Tint", color)
    end
end

--- Gets the door's prop entity
function DimensionDoor:GetProp()
    return self.prop
end

