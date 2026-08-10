--[[
    Rokopia - Custom Script Suite (rokopia.lua)
    Features: 
      - Items Tab: Item Spawner (Spawns any item/block into player hand using EquipAdmin)
      - Troll Tab: Progressive Shaft & Expand Hole (1x1 Shaft -> 3x3 Expand -> 5x5 Expand -> TP to Next Hole)
      - Multi-Hit Block Breaking (Repeats hits up to Block Durability, e.g. 7 hits for stone)
      - Lowest Cooldown Support (10ms minimum delay)
      - Auto Teleport & Anchor above hole center to prevent falling
    Powered by Custom UI Framework (lib.lua)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with cache buster)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Rokopia Suite Error] Could not load UI Library from GitHub!")
    return
end

local int = lib:CreateInterface("Rokopia Suite", "Voxel World, Item Spawner & Troll Suite", "", "bottom left", "royal", 0.25)

local itemsTab = int:CreateTab("Items", "Item & Block Spawner Hub", "item", true)
local trollTab = int:CreateTab("Troll", "Map Manipulation & Pitfalls", "item")
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Configuration State
local Config = {
    RandomHoles = false,
    HoleRadius = 15,
    HoleDepth = 15,
    HitsPerBlock = 7, -- Repeat hits per block for durability (Dirt=4, Stone=7, Altar=14)
    CooldownSpeed = 0.01 -- 10ms lowest delay
}

-- Fetch Remotes
local function getBreakBlockRemote()
    local remoteFuncFolder = ReplicatedStorage:FindFirstChild("RemoteFunction")
    if remoteFuncFolder then
        return remoteFuncFolder:FindFirstChild("BreakBlock")
    end
    return nil
end

local function getEquipAdminRemote()
    local remoteEventFolder = ReplicatedStorage:FindFirstChild("RemoteEvent")
    local invFolder = remoteEventFolder and remoteEventFolder:FindFirstChild("Inventory")
    if invFolder then
        return invFolder:FindFirstChild("EquipAdmin")
    end
    return nil
end

-- Helper to Spawn Item into Hand
local function spawnItemIntoHand(itemId)
    local remote = getEquipAdminRemote()
    if remote then
        remote:FireServer(itemId)
        lib:Notify("Item Spawner", "Spawned item: " .. tostring(itemId), 1.5)
    else
        lib:Notify("Item Error", "Could not find EquipAdmin remote!", 2.0)
    end
end


-- Helper function to break a single block safely with anti-cheat checks & multi-hit durability support
local function breakSingleBlock(targetX, y, targetZ)
    if not Config.RandomHoles then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local breakRemote = getBreakBlockRemote()

    if not hrp or not breakRemote then return false end

    local blockWorldPos = Vector3.new(targetX * 4.2, y * 4.2, targetZ * 4.2)
    local key = string.format("%d,%d,%d", targetX, y, targetZ)

    -- Repeat hits for multi-durability blocks (e.g., Grass=2, Dirt=4, Stone=7)
    for hit = 1, Config.HitsPerBlock do
        if not Config.RandomHoles then break end

        local currentHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not currentHrp then break end

        local dist = (currentHrp.Position - blockWorldPos).Magnitude
        if dist > 20 then break end

        -- Send 1 damage hit (SELECTION_MAX_BLOCKS = 1)
        local res = breakRemote:InvokeServer({ key })

        -- Wait cooldown between hits (10ms)
        task.wait(Config.CooldownSpeed)

        -- If server returns false (block fully broken / non-existent / empty), stop hitting this block
        if res == false then
            break
        end
    end

    return true
end

-- Teleport & Anchor Player above center of hole
local function positionAndAnchorPlayer(centerX, startY, centerZ)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local targetWorldPos = Vector3.new(centerX * 4.2, (startY + 2) * 4.2, centerZ * 4.2)
        hrp.CFrame = CFrame.new(targetWorldPos)
        hrp.Anchored = true
        task.wait(0.05)
    end
end

-- Unanchor Player
local function unanchorPlayer()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
    end
end

-- --------------------------------------------------------------------
-- PROGRESSIVE HOLE DIGGER (1x1 Shaft -> 3x3 Expand -> 5x5 Expand -> Next)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.05)
        if Config.RandomHoles then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                -- 1. Select random target center block within HoleRadius
                local playerPos = hrp.Position
                local pX = math.floor(playerPos.X / 4.2)
                local pY = math.floor(playerPos.Y / 4.2)
                local pZ = math.floor(playerPos.Z / 4.2)

                local maxRadiusBlocks = math.clamp(math.floor(Config.HoleRadius / 4.2), 1, 4)
                local randOffsetX = math.random(-maxRadiusBlocks, maxRadiusBlocks)
                local randOffsetZ = math.random(-maxRadiusBlocks, maxRadiusBlocks)
                local centerX = pX + randOffsetX
                local centerZ = pZ + randOffsetZ

                local startY = pY + 1
                local endY = math.max(pY - Config.HoleDepth, -64)

                -- 2. Teleport & Anchor above target hole center
                positionAndAnchorPlayer(centerX, startY, centerZ)

                -- PHASE 1: Dig initial 1x1 vertical shaft downwards (Top to Bottom)
                for y = startY, endY, -1 do
                    if not Config.RandomHoles then break end
                    breakSingleBlock(centerX, y, centerZ)
                end

                -- PHASE 2: Expand to 3x3 around the shaft (dx, dz in -1..1, excluding 0,0)
                if Config.RandomHoles then
                    for dx = -1, 1 do
                        for dz = -1, 1 do
                            if not Config.RandomHoles then break end
                            if not (dx == 0 and dz == 0) then
                                local targetX = centerX + dx
                                local targetZ = centerZ + dz
                                for y = startY, endY, -1 do
                                    if not Config.RandomHoles then break end
                                    breakSingleBlock(targetX, y, targetZ)
                                end
                            end
                        end
                    end
                end

                -- PHASE 3: Expand to 5x5 around the shaft (outer ring dx, dz in -2..2)
                if Config.RandomHoles then
                    for dx = -2, 2 do
                        for dz = -2, 2 do
                            if not Config.RandomHoles then break end
                            -- Only dig the outer 5x5 ring (where abs(dx) == 2 or abs(dz) == 2)
                            if math.abs(dx) == 2 or math.abs(dz) == 2 then
                                local targetX = centerX + dx
                                local targetZ = centerZ + dz
                                for y = startY, endY, -1 do
                                    if not Config.RandomHoles then break end
                                    breakSingleBlock(targetX, y, targetZ)
                                end
                            end
                        end
                    end
                end

                -- Unanchor after finishing one hole location
                unanchorPlayer()
                task.wait(0.1)
            end)
        else
            unanchorPlayer()
        end
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: ITEM SPAWNER HUB
-- --------------------------------------------------------------------
itemsTab:CreateComment("--- Quick Item Spawner ---")

local itemDropdown = itemsTab:CreateDropDown("Select Item To Spawn", function() end)

local itemList = {
    { name = "Grass Block", id = "block.grass" },
    { name = "Dirt Block", id = "block.dirt" },
    { name = "Stone Block", id = "block.stone" },
    { name = "Altar Stone", id = "block.altar_stone" },
    { name = "Wood Block", id = "block.wood" },
    { name = "Water Source Block", id = "block.water_source" },
    { name = "Wooden Chair", id = "furniture.seat.wooden_chair" },
    { name = "Wooden Torch", id = "environment.light.floor_and_wall.wooden_torch" },
    { name = "High Grass Bush", id = "plant.grass_bush.high" },
    { name = "Low Grass Bush", id = "plant.grass_bush.low" },
    { name = "Big Brown Mushroom", id = "mushroom.big_brown" },
    { name = "Flat White Mushroom", id = "mushroom.flat_white" },
    { name = "High Yellow Mushroom", id = "mushroom.high_yellow" },
    { name = "Carrot", id = "plant.vegetable.carrot" },
    { name = "Modern Battery Block", id = "electronic.battery.block_modern" },
    { name = "Antique Battery Block", id = "electronic.battery.block_antique" },
    { name = "Large Voltaic Pile", id = "electronic.battery.voltaic_pile_large" },
    { name = "Small Voltaic Pile", id = "electronic.battery.voltaic_pile_small" },
    { name = "Light Bulb", id = "electronic.light.bulb" }
}

for _, itemData in ipairs(itemList) do
    itemDropdown:AddButton("Spawn " .. itemData.name, function()
        spawnItemIntoHand(itemData.id)
    end)
end

itemsTab:CreateComment("--- Popular Quick Buttons ---")

itemsTab:CreateButton("Spawn Grass Block", function()
    spawnItemIntoHand("block.grass")
end)

itemsTab:CreateButton("Spawn Stone Block", function()
    spawnItemIntoHand("block.stone")
end)

itemsTab:CreateButton("Spawn Altar Stone", function()
    spawnItemIntoHand("block.altar_stone")
end)

itemsTab:CreateButton("Spawn Water Source", function()
    spawnItemIntoHand("block.water_source")
end)

itemsTab:CreateButton("Spawn Wooden Torch", function()
    spawnItemIntoHand("environment.light.floor_and_wall.wooden_torch")
end)

itemsTab:CreateButton("Spawn Battery Block", function()
    spawnItemIntoHand("electronic.battery.block_modern")
end)

itemsTab:CreateTextbox("Custom Item ID Spawner", "e.g. block.stone", "", function(customId)
    if customId and customId ~= "" then
        spawnItemIntoHand(customId)
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 2: TROLL CONTROLS
-- --------------------------------------------------------------------
trollTab:CreateToggleSwitch("Build Random Holes", false, function(val)
    Config.RandomHoles = val
    if val then
        lib:Notify("Rokopia Troll", "Fast Progressive Digger Active (10ms Cooldown)!", 2.0)
    else
        unanchorPlayer()
        lib:Notify("Rokopia Troll", "Build Random Holes Stopped.", 1.5)
    end
end)

trollTab:CreateSlider("Cooldown Delay (ms)", 10, 400, 10, function(val)
    Config.CooldownSpeed = val / 1000
end)

trollTab:CreateSlider("Max Hits Per Block", 1, 14, 7, function(val)
    Config.HitsPerBlock = val
end)

trollTab:CreateSlider("Hole Search Radius (Studs)", 5, 20, 15, function(val)
    Config.HoleRadius = val
end)

trollTab:CreateSlider("Hole Depth (Blocks)", 5, 25, 12, function(val)
    Config.HoleDepth = val
end)


-- --------------------------------------------------------------------
-- UI TAB 3: UI SETTINGS & TRANSPARENCY
-- --------------------------------------------------------------------
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)
local themesList = {"royal", "cyber", "emerald", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

print("[Rokopia Suite] Item Spawner Hub Loaded!")
