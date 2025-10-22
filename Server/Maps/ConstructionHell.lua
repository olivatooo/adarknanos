Package.Require("Dimension.lua")

-- Puzzle state tracking
ConstructionHellPuzzle = {
    sequence_step = 0,
    correct_sequence = {},
    puzzle_props = {},
    puzzle_complete = false,
    sequence_length = 5
}

-- Helper function to generate random pastel colors
local function RandomColor()
    return Color(
        math.random(50, 255) / 255,
        math.random(50, 255) / 255,
        math.random(50, 255) / 255
    )
end

-- Static mesh list for decorative objects
local StaticMeshes = {
    "nanos-world::SM_WoodenTable",
    "nanos-world::SM_WoodenChair",
    "nanos-world::SM_Stool",
    "nanos-world::SM_TeaPot_Interior",
    "nanos-world::SM_OilDrum",
    "nanos-world::SM_Bucket5Gallon",
    "nanos-world::SM_Crate_07",
    "nanos-world::SM_Crate_03",
    "nanos-world::SM_Crate_04",
    "nanos-world::SM_Pot_01",
    "nanos-world::SM_Pot_02",
    "nanos-world::SM_Plate_Interior",
    "nanos-world::SM_Barrel_02",
    "nanos-world::SM_Bamboo_Roof45_Right",
    "nanos-world::SM_MetalBucket_Interior_01",
    "nanos-world::SM_MetalBucket_Interior_02",
    "nanos-world::SM_Basket_01",
    "nanos-world::SM_Basket_02",
    "nanos-world::SM_Crate_01",
    "nanos-world::SM_Crate_02",
    "nanos-world::SM_Bamboo_Woodplank_01",
    "nanos-world::SM_Ladder_Interior"
}

-- Puzzle prop types with their meshes
local PuzzleProps = {
    { name = "Barrel", mesh = "nanos-world::SM_Barrel_02",     color = Color(0.6, 0.3, 0.1) },
    { name = "Crate",  mesh = "nanos-world::SM_Crate_07",      color = Color(0.8, 0.6, 0.3) },
    { name = "Bucket", mesh = "nanos-world::SM_Bucket5Gallon", color = Color(0.5, 0.5, 0.5) },
    { name = "Pot",    mesh = "nanos-world::SM_Pot_01",        color = Color(0.4, 0.2, 0.1) },
    { name = "Basket", mesh = "nanos-world::SM_Basket_01",     color = Color(0.7, 0.5, 0.2) }
}

-- Cryptic messages for different puzzle states
local PuzzleMessages = {
    start = {
        "The construction never ends... but it must be understood.",
        "Five objects. Five steps. One path to freedom.",
        "The order matters. The construction demands precision.",
        "Not all that is built is meant to stand.",
        "Touch them in the right order... or begin again."
    },
    correct_step = {
        "Yes... the pattern emerges...",
        "Another piece falls into place...",
        "The construction yields its secrets...",
        "Closer... you're getting closer...",
        "The foundation trembles with recognition..."
    },
    wrong_step = {
        "No... the structure rejects your choice.",
        "Wrong. Begin again from nothing.",
        "The construction collapses. Start over.",
        "Chaos. The pattern is broken.",
        "The foundation crumbles beneath false steps."
    },
    completion = {
        "The construction is complete... the nightmare ends.",
        "The pattern is whole. The dream releases you.",
        "Five steps taken. Five truths revealed.",
        "The foundation is solid. You may leave.",
    }
}

-- Function to reset the puzzle
local function ResetPuzzle()
    ConstructionHellPuzzle.sequence_step = 0
end

-- Function to check if puzzle is complete
local function CheckPuzzleComplete()
    return ConstructionHellPuzzle.puzzle_complete
end

-- Spawn function for Construction Hell dimension
local function SpawnConstructionHellContent(dimension)
    ConstructionHellPuzzle.puzzle_complete = false
    ConstructionHellPuzzle.sequence_step = 0
    ConstructionHellPuzzle.puzzle_props = {}

    local radius = 3100
    local center = Vector(0, 0, 0)

    -- The correct sequence: Barrel -> Crate -> Bucket -> Pot -> Basket
    ConstructionHellPuzzle.correct_sequence = { 1, 2, 3, 4, 5 }

    -- Debug: Print the sequence to console
    local sequence_names = {}
    for i, idx in ipairs(ConstructionHellPuzzle.correct_sequence) do
        table.insert(sequence_names, PuzzleProps[idx].name)
    end
    Console.Log("Correct sequence: " .. table.concat(sequence_names, " -> "))

    -- Give all players in this dimension a Glock
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
            Console.Log("Player " ..
                character:GetName() .. " interacted with " .. self.prop_name .. " at step " .. current_step)

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
                Bloodhound.new(Vector(math.random(-40000, 40000), math.random(-40000, 40000), 100), dimension.id)
                ResetPuzzle()

                -- Reset all prop colors
                for _, p in pairs(ConstructionHellPuzzle.puzzle_props) do
                    if p:IsValid() then
                        p:SetMaterialColorParameter("Tint", Color(1, 1, 1))
                    end
                end
            end

            return false
        end)

        dimension:TrackEntity(puzzle_prop)
        table.insert(ConstructionHellPuzzle.puzzle_props, puzzle_prop)
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
        { angle = 0,             text = "What holds the liquid of labor" },
        { angle = math.pi * 0.4, text = "The wooden keeper of secrets" },
        { angle = math.pi * 0.8, text = "The carrier of water and burden" },
        { angle = math.pi * 1.2, text = "Where the meal is prepared" },
        { angle = math.pi * 1.6, text = "The woven vessel of harvest" }
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
            Vector(hint_x, hint_y, 6000),
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
            Vector(light_x, light_y, 10000),
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
