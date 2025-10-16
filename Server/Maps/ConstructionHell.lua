Package.Require("Dimension.lua")
    Timer.SetTimeout(function()
        local players = dimension:GetPlayers()
        for _, player in ipairs(players) do
            local character = player:GetControlledCharacter()
            if character and character:IsValid() then
                local glock = Weapon(
                    character:GetLocation(),
                    Rotator(),
                    "nanos-world::W_Glock"
                )
                glock:SetDimension(dimension.id)
                character:PickUp(glock)
                dimension:TrackEntity(glock)
            end
        end
    end, 500)

    -- Spawn ground plane
    local ground = StaticMesh(Vector(0, 0, 1), Rotator(), "nanos-world::SM_Plane", CollisionType.Normal)
    ground:SetScale(Vector(2000, 2000, 1))
    ground:SetMaterialColorParameter("Tint", Color(0.15, 0.15, 0.2))
    ground:SetDimension(dimension.id)
    dimension:TrackEntity(ground)

    -- Create 5 puzzle props scattered around in a circle (at light positions)
    local station_radius = 3100

    for i, prop_data in ipairs(PuzzleProps) do
        local angle = (i - 1) * (2 * math.pi / 5)
        local x = center.X + station_radius * math.cos(angle)
        local y = center.Y + station_radius * math.sin(angle)

        -- Create a pedestal using oil drums
        local pedestal = StaticMesh(
            Vector(x, y, 0),
            Rotator(0, 0, 0),
            "nanos-world::SM_OilDrum",
            CollisionType.Normal
        )
        pedestal:SetScale(Vector(2, 2, 1))
        pedestal:SetDimension(dimension.id)
        dimension:TrackEntity(pedestal)

        -- Create the interactable puzzle prop
        local puzzle_prop = Prop(
            Vector(x, y, 100),
            Rotator(0, math.random(0, 360), 0),
            prop_data.mesh,
            CollisionType.Normal,
            false,
            GrabMode.Enabled
        )
        puzzle_prop:SetDimension(dimension.id)
        puzzle_prop:SetScale(Vector(2, 2, 2))
        puzzle_prop:SetMaterialColorParameter("Tint", prop_data.color)

        -- Store the prop type index
        puzzle_prop.prop_type = i
        puzzle_prop.prop_name = prop_data.name
        puzzle_prop.original_color = prop_data.color

        -- Add interaction
        puzzle_prop:Subscribe("Interact", function(self, character)
            local current_step = ConstructionHellPuzzle.sequence_step + 1
            local expected_type = ConstructionHellPuzzle.correct_sequence[current_step]

            if self.prop_type == expected_type then
                -- Correct step
                ConstructionHellPuzzle.sequence_step = current_step
                Chat.BroadcastMessage("Step " ..
                current_step .. " of " .. ConstructionHellPuzzle.sequence_length .. ": " .. self.prop_name)
                Chat.BroadcastMessage(PuzzleMessages.correct_step[math.random(#PuzzleMessages.correct_step)])

                -- Visual feedback - change color to gold
                self:SetMaterialColorParameter("Tint", Color(1, 0.84, 0))

                -- Check if puzzle is complete
                if current_step == ConstructionHellPuzzle.sequence_length then
                    ConstructionHellPuzzle.puzzle_complete = true
                    Chat.BroadcastMessage(PuzzleMessages.completion[math.random(#PuzzleMessages.completion)])
                end
            else
                -- Wrong step - reset
                Chat.BroadcastMessage(PuzzleMessages.wrong_step[math.random(#PuzzleMessages.wrong_step)])
                ResetPuzzle()

                -- Reset all prop colors
                for _, p in ipairs(ConstructionHellPuzzle.puzzle_props) do
                    Console.Log(p)
                    if p:IsValid() then
                        p:SetMaterialColorParameter("Tint", p.original_color)
                    end
                end
            end

            return false
        end)

        dimension:TrackEntity(puzzle_prop)
        table.insert(ConstructionHellPuzzle.puzzle_props, puzzle_prop)

        -- Add label text above each prop
        local label_text = TextRender(
            Vector(x, y, 300),
            Rotator(),
            prop_data.name,
            Vector(3, 3, 3),
            Color(1, 1, 1),
            FontType.OpenSans,
            TextRenderAlignCamera.FaceCamera
        )
        label_text:SetDimension(dimension.id)
        dimension:TrackEntity(label_text)
    end

    -- Spawn 50 random decorative objects scattered around the area
    for i = 1, 50 do
        local random_angle = math.random() * 2 * math.pi
        local random_distance = math.random(300, radius - 100)
        local x = center.X + random_distance * math.cos(random_angle)
        local y = center.Y + random_distance * math.sin(random_angle)

        local mesh_asset = StaticMeshes[math.random(#StaticMeshes)]

        local decorative = StaticMesh(
            Vector(x, y, math.random(0, 50)),
            Rotator(0, math.random(0, 360), 0),
            mesh_asset,
            CollisionType.Normal
        )

        decorative:SetScale(Vector(
            0.5 + math.random() * 1.5,
            0.5 + math.random() * 1.5,
            0.5 + math.random() * 1.5
        ))
        decorative:SetDimension(dimension.id)
        dimension:TrackEntity(decorative)
    end

    -- Create cryptic hint texts scattered around in a 7000 radius
    local hint_radius = 7000
    local hint_positions = {
        { angle = 0,             text = "First: What holds the liquid of labor" },
        { angle = math.pi * 0.4, text = "Second: The wooden keeper of secrets" },
        { angle = math.pi * 0.8, text = "Third: The carrier of water and burden" },
        { angle = math.pi * 1.2, text = "Fourth: Where the meal is prepared" },
        { angle = math.pi * 1.6, text = "Fifth: The woven vessel of harvest" }
    }

    for _, hint_data in ipairs(hint_positions) do
        local hint_x = center.X + hint_radius * math.cos(hint_data.angle)
        local hint_y = center.Y + hint_radius * math.sin(hint_data.angle)

        local hint_text = TextRender(
            Vector(hint_x, hint_y, 200),
            Rotator(),
            hint_data.text,
            Vector(2, 2, 2),
            Color(0.8, 0.2, 0.2),
            FontType.OpenSans,
            TextRenderAlignCamera.FaceCamera
        )
        hint_text:SetDimension(dimension.id)
        dimension:TrackEntity(hint_text)

        -- Add a light at each hint position
        local hint_light = Light(
            Vector(hint_x, hint_y, 300),
            Rotator(0, 0, 0),
            Color(0.8, 0.2, 0.2),
            LightType.Point,
            2000,
            1500,
            0,
            0,
            50000,
            true,
            true,
            true
        )
        hint_light:SetDimension(dimension.id)
        dimension:TrackEntity(hint_light)
    end

    -- Add central cryptic message
    local central_message = TextRender(
        Vector(0, 0, 600),
        Rotator(),
        "",
        Vector(4, 4, 4),
        Color(1, 0, 0),
        FontType.OpenSans,
        TextRenderAlignCamera.FaceCamera
    )
    central_message:SetDimension(dimension.id)
    dimension:TrackEntity(central_message)

    -- Add instruction text
    local instruction_text = TextRender(
        Vector(0, 0, 450),
        Rotator(),
        "",
        Vector(2, 2, 2),
        Color(1, 1, 1),
        FontType.OpenSans,
        TextRenderAlignCamera.FaceCamera
    )
    instruction_text:SetDimension(dimension.id)
    dimension:TrackEntity(instruction_text)

    -- Spawn door back to Nexus
    local door = DimensionDoor.new(
        Vector(0, 0, 0),
        Rotator(0, 0, 0),
        1,
        "Nexus",
        Color(1, 1, 1),
        "nanos-world::SM_Portapotty_Door",
        nil,
        6
    )

    -- Add atmospheric lighting around the puzzle props
    for i = 1, 5 do
        local angle = (i - 1) * (2 * math.pi / 5)
        local light_distance = 3100
        local light_x = math.cos(angle) * light_distance
        local light_y = math.sin(angle) * light_distance

        local light = Light(
            Vector(light_x, light_y, 4000),
            Rotator(0, 0, 0),
            Color(0.8, 0.3, 0.1),
            LightType.Point,
            1000,
            1000,
            0,
            0,
            50000,
            true,
            true,
            true
        )
        light:SetDimension(dimension.id)
        dimension:TrackEntity(light)
    end
    
    -- Central ominous light
    local central_light = Light(
        Vector(0, 0, 800),
        Rotator(0, 0, 0),
        Color(1, 0, 0),
        LightType.Point,
        10000,
        2000,
        0,
        0,
        50000,
        true,
        true,
        true
    )
    central_light:SetDimension(dimension.id)
    dimension:TrackEntity(central_light)

    -- Broadcast start message
    Timer.SetTimeout(function()
        Chat.BroadcastMessage(PuzzleMessages.start[math.random(#PuzzleMessages.start)])
    end, 2000)

    Console.Log("Construction Hell dimension spawned with puzzle sequence")
end

-- Objective function - complete when puzzle is solved
local function ConstructionHellObjective(dimension)
    return ConstructionHellPuzzle.puzzle_complete
end

-- Cleanup function
local function ConstructionHellCleanup(dimension)
    Console.Log("Construction Hell dimension cleaned up!")
    ConstructionHellPuzzle.puzzle_complete = false
    ConstructionHellPuzzle.sequence_step = 0
    ConstructionHellPuzzle.puzzle_props = {}
    ConstructionHellPuzzle.correct_sequence = {}
end

-- Create the Construction Hell dimension
ConstructionHellDimension = Dimension.new(
    6,                            -- Dimension ID (matches DoorToConstructionHell)
    "Construction Hell",          -- Name
    SpawnConstructionHellContent, -- Spawn function
    ConstructionHellObjective,    -- Objective function
    ConstructionHellCleanup       -- Cleanup function
)

-- Spawn the dimension immediately
ConstructionHellDimension:Spawn()
