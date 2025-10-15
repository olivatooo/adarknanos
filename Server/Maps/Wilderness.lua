Package.Require("Dimension.lua")

WildernessTrees = {
    "nanos-world::SM_Tree_Acacia_01",
    "nanos-world::SM_Tree_Acacia_02",
}

WildernessGround = {
    "nanos-world::SM_Rock_03",
    "nanos-world::SM_Rock_04",
    "nanos-world::SM_Rock_05",
    "nanos-world::SM_Rock_06",
    "nanos-world::SM_Rock_07",
    "nanos-world::SM_Bush_01",
}

ShouldSpawnBots = true
MaxBots = 25
NumberOfKilledBots = 0


-- Spawn function for the Wilderness dimension
local function SpawnWildernessContent(dimension)
    -- Spawn 100 random trees
    for i = 1, 300 do
        -- Pick a random tree from the list
        local randomTree = WildernessTrees[math.random(#WildernessTrees)]

        -- Random position within 10000 unit radius
        local randomX = math.random(-50000, 50000)
        local randomY = math.random(-50000, 50000)

        -- Random rotation
        local randomRotation = Rotator(0, math.random(0, 360), 0)

        -- Random scale
        local randomScale = Vector(0.8 + math.random() * 1.5)

        -- Spawn the tree in the wilderness dimension
        local tree = StaticMesh(Vector(randomX, randomY, 0), randomRotation, randomTree)
        tree:SetScale(randomScale)
        tree:SetDimension(dimension.id)

        -- Track the tree for cleanup
        dimension:TrackEntity(tree)
    end

    -- Spawn 100 random trees
    for i = 1, 300 do
        -- Pick a random tree from the list
        local randomTree = WildernessGround[math.random(#WildernessGround)]

        -- Random position within 10000 unit radius
        local randomX = math.random(-50000, 50000)
        local randomY = math.random(-50000, 50000)

        -- Random rotation
        local randomRotation = Rotator(0, math.random(0, 360), 0)

        -- Random scale
        local randomScale = Vector(1.0 + math.random() * 5)

        -- Spawn the tree in the wilderness dimension
        local tree = StaticMesh(Vector(randomX, randomY, 0), randomRotation, randomTree)
        tree:SetScale(randomScale)
        tree:SetDimension(dimension.id)

        -- Track the tree for cleanup
        dimension:TrackEntity(tree)
    end

    for i = 1, 15 do
        local vehicle = Offroad(Vector(math.random(-50000, 50000), math.random(-50000, 50000), 100), Rotator())
        vehicle:SetDimension(dimension.id)
        dimension:TrackEntity(vehicle)
    end

    for i = 1, 25 do
        local awp = AWP(Vector(math.random(-50000, 50000), math.random(-50000, 50000), 100), Rotator())
        awp:SetDimension(dimension.id)
        dimension:TrackEntity(awp)
    end

    for i = 1, 25 do
        local bot = Character(Vector(math.random(-50000, 50000), math.random(-50000, 50000), 1000), Rotator())
        bot:SetFallDamageTaken(0)
        bot:SetDimension(dimension.id)
        bot:SetMaterialColorParameter("Tint", Color.RED)
        bot:SetHealth(1)
        bot:Subscribe("Death", function(self)
            NumberOfKilledBots = NumberOfKilledBots + 1
        end)
    end


    -- Spawn ground plane
    local sm = StaticMesh(Vector(0, 0, 1), Rotator(), "nanos-world::SM_Plane", CollisionType.Normal)
    sm:SetScale(Vector(1000, 1000, 1))
    sm:SetPhysicalMaterial("nanos-world::PM_Grass")
    sm:SetMaterialTextureParameter("Texture", "package://adarknanos/Client/grass.jpg")
    sm:SetMaterialScalarParameter("Metallic", 0)
    sm:SetMaterialScalarParameter("Specular ", 0)
    sm:SetDimension(dimension.id)

    Console.Log("Spawned " .. #dimension.spawned_entities .. " trees in Wilderness dimension")

    for i = 1, 15 do
        local vehicle = Offroad(Vector(math.random(-50000, 50000), math.random(-50000, 50000), 100), Rotator())
        vehicle:SetDimension(dimension.id)
        dimension:TrackEntity(vehicle)
    end

    -- Create door using the DimensionDoor class
    local door = DimensionDoor.new(
        Vector(0, 0, 0),
        Rotator(0, 0, 0),
        1,
        "Nexus",
        Color(1, 0, 0),
        "nanos-world::SM_Portapotty_Door",
        nil,
        2
    )
end

local function WildernessObjective(dimension)
    Console.Log("Wilderness objective: " .. NumberOfKilledBots .. " bots killed")
    if NumberOfKilledBots == 1 then
        return true
    end
    return false
end

local function WildernessCleanup(dimension)
    Console.Log("Wilderness dimension cleaned up!")
end

WildernessDimension = Dimension.new(
    2,                      -- Dimension ID
    "Wilderness",           -- Name
    SpawnWildernessContent, -- Spawn function
    WildernessObjective,    -- Objective function (optional)
    WildernessCleanup       -- Cleanup function (optional)
)

-- Spawn the dimension immediately
WildernessDimension:Spawn()

