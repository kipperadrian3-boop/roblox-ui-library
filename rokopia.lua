--[[
    Rokopia - Custom Script Suite (rokopia.lua)
    Features: 
      - Troll Tab: Progressive Shaft & Expand Hole (1x1 Shaft -> 3x3 Expand -> 5x5 Expand -> TP to Next Hole)
      - Auto Teleport & Anchor above hole center to prevent falling
      - Anti-Cheat Safe: 1 block per call, 200ms safe cooldown, distance <= 20 studs
    Powered by Custom UI Framework (lib.lua)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with cache buster)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?t=" .. os.time()))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Rokopia Suite Error] Could not load UI Library from GitHub!")
    return
end

local int = lib:CreateInterface("Rokopia Suite", "Voxel World & Troll Utilities", "", "bottom left", "royal", 0.25)

local trollTab = int:CreateTab("Troll", "Map Manipulation & Pitfalls", "item", true)
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Configuration State
local Config = {
    RandomHoles = false,
    HoleRadius = 15,
    HoleDepth = 15,
    CooldownSpeed = 0.20 -- 200ms ultra-safe delay above server 0.1s ACTION_COOLDOWN
}

-- Fetch BreakBlock Remote Function
local function getBreakBlockRemote()
    local remoteFuncFolder = ReplicatedStorage:FindFirstChild("RemoteFunction")
    if remoteFuncFolder then
        return remoteFuncFolder:FindFirstChild("BreakBlock")
    end
    return nil
end

-- Helper function to break a single block safely with anti-cheat checks
local function breakSingleBlock(targetX, y, targetZ)
    if not Config.RandomHoles then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local breakRemote = getBreakBlockRemote()

    if not hrp or not breakRemote then return false end

    local blockWorldPos = Vector3.new(targetX * 4.2, y * 4.2, targetZ * 4.2)
    local dist = (hrp.Position - blockWorldPos).Magnitude

    if dist <= 20 then
        local key = string.format("%d,%d,%d", targetX, y, targetZ)
        breakRemote:InvokeServer({ key })
        task.wait(Config.CooldownSpeed)
        return true
    end
    return false
end

-- Teleport & Anchor Player above center of hole
local function positionAndAnchorPlayer(centerX, startY, centerZ)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local targetWorldPos = Vector3.new(centerX * 4.2, (startY + 2) * 4.2, centerZ * 4.2)
        hrp.CFrame = CFrame.new(targetWorldPos)
        hrp.Anchored = true
        task.wait(0.1)
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
        task.wait(0.1)
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
                task.wait(0.2)
            end)
        else
            unanchorPlayer()
        end
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: TROLL CONTROLS
-- --------------------------------------------------------------------
trollTab:CreateToggleSwitch("Build Random Holes", false, function(val)
    Config.RandomHoles = val
    if val then
        lib:Notify("Rokopia Troll", "Progressive Hole Digger Active (1x1 -> 3x3 -> 5x5)!", 2.0)
    else
        unanchorPlayer()
        lib:Notify("Rokopia Troll", "Build Random Holes Stopped.", 1.5)
    end
end)

trollTab:CreateSlider("Hole Search Radius (Studs)", 5, 20, 15, function(val)
    Config.HoleRadius = val
end)

trollTab:CreateSlider("Hole Depth (Blocks)", 5, 25, 12, function(val)
    Config.HoleDepth = val
end)

trollTab:CreateSlider("Cooldown Delay (ms)", 150, 400, 200, function(val)
    Config.CooldownSpeed = val / 1000
end)


-- --------------------------------------------------------------------
-- UI TAB 2: UI SETTINGS & TRANSPARENCY
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

print("[Rokopia Suite] Progressive 1x1 -> 3x3 -> 5x5 Digger Loaded!")
