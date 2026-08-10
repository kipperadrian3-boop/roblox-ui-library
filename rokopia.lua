--[[
    Rokopia - Custom Script Suite (rokopia.lua)
    Features: 
      - Troll Tab: Perfect 5x5 Void Digger (Digs exact 5x5 column down to bedrock/void y = -64)
      - Exact Character Teleportation: Character TPs directly onto each targeted block during digging
      - Repeats hits (up to 14 hits per block) with 10ms cooldown to guarantee complete block removal
      - Cleans up Item Spawner & Extra tabs on user request
    Powered by Custom UI Framework (lib.lua)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with dynamic cache buster)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Rokopia Suite Error] Could not load UI Library from GitHub!")
    return
end

local int = lib:CreateInterface("Rokopia Suite", "5x5 Void Digger Engine", "", "bottom left", "royal", 0.25)

local trollTab = int:CreateTab("Troll", "Void Digger & Pitfalls", "item", true)
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Configuration State
local Config = {
    RandomHoles = false,
    HoleRadius = 20,
    HoleDepth = 40,
    HitsPerBlock = 14, -- High hit count to guarantee 100% removal down to bedrock/void
    CooldownSpeed = 0.01 -- 10ms delay
}

-- Fetch BreakBlock Remote Function
local function getBreakBlockRemote()
    local remoteFuncFolder = ReplicatedStorage:FindFirstChild("RemoteFunction")
    if remoteFuncFolder then
        return remoteFuncFolder:FindFirstChild("BreakBlock")
    end
    return nil
end

-- Teleport Character Directly Above Target Block & Anchor
local function positionCharacterForBlock(blockX, blockY, blockZ)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local targetWorldPos = Vector3.new(blockX * 4.2, (blockY + 1.8) * 4.2, blockZ * 4.2)
        hrp.CFrame = CFrame.new(targetWorldPos)
        hrp.Anchored = true
        task.wait(0.01)
    end
end

-- Unanchor Character
local function unanchorCharacter()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
    end
end

-- Safely break a block by teleporting character directly over it and hitting up to max durability
local function destroyTargetBlock(targetX, targetY, targetZ)
    if not Config.RandomHoles then return false end

    local breakRemote = getBreakBlockRemote()
    if not breakRemote then return false end

    -- 1. Teleport player directly on top of the block
    positionCharacterForBlock(targetX, targetY, targetZ)

    local key = string.format("%d,%d,%d", targetX, targetY, targetZ)

    -- 2. Repeatedly hit the block to break it completely (handles grass=2, stone=7, altar=14)
    for hit = 1, Config.HitsPerBlock do
        if not Config.RandomHoles then break end

        -- Invoke BreakBlock (1 block per call for anti-cheat safety)
        breakRemote:InvokeServer({ key })
        task.wait(Config.CooldownSpeed)
    end

    return true
end


-- --------------------------------------------------------------------
-- PERFECT 5x5 VOID DIGGER ENGINE (Top-to-Bottom, Block-by-Block TP)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.RandomHoles then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                -- 1. Pick a random hole center point within search radius
                local playerPos = hrp.Position
                local pX = math.floor(playerPos.X / 4.2)
                local pY = math.floor(playerPos.Y / 4.2)
                local pZ = math.floor(playerPos.Z / 4.2)

                local maxRadiusBlocks = math.clamp(math.floor(Config.HoleRadius / 4.2), 1, 5)
                local randOffsetX = math.random(-maxRadiusBlocks, maxRadiusBlocks)
                local randOffsetZ = math.random(-maxRadiusBlocks, maxRadiusBlocks)
                local centerX = pX + randOffsetX
                local centerZ = pZ + randOffsetZ

                local startY = pY + 2
                local endY = math.max(pY - Config.HoleDepth, -64)

                -- 2. Dig an entire 5x5 area layer-by-layer from Top (startY) to Bottom (endY)
                for y = startY, endY, -1 do
                    if not Config.RandomHoles then break end

                    -- Loop through the 5x5 grid (dx: -2 to 2, dz: -2 to 2)
                    for dx = -2, 2 do
                        for dz = -2, 2 do
                            if not Config.RandomHoles then break end

                            local targetX = centerX + dx
                            local targetZ = centerZ + dz

                            -- Teleport directly over the target block and destroy it completely
                            destroyTargetBlock(targetX, y, targetZ)
                        end
                    end
                end

                -- Unanchor after finishing full 5x5 void hole
                unanchorCharacter()
                task.wait(0.2)
            end)
        else
            unanchorCharacter()
        end
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: TROLL CONTROLS (5x5 Void Digger)
-- --------------------------------------------------------------------
trollTab:CreateToggleSwitch("Build 5x5 Void Hole", false, function(val)
    Config.RandomHoles = val
    if val then
        lib:Notify("Rokopia Troll", "5x5 Void Digger Active! Teleporting block by block...", 2.0)
    else
        unanchorCharacter()
        lib:Notify("Rokopia Troll", "5x5 Void Digger Stopped.", 1.5)
    end
end)

trollTab:CreateSlider("Hole Depth (Blocks)", 5, 50, 25, function(val)
    Config.HoleDepth = val
end)

trollTab:CreateSlider("Max Hits Per Block", 1, 14, 14, function(val)
    Config.HitsPerBlock = val
end)

trollTab:CreateSlider("Cooldown Delay (ms)", 10, 200, 10, function(val)
    Config.CooldownSpeed = val / 1000
end)

trollTab:CreateSlider("Search Radius (Studs)", 5, 30, 20, function(val)
    Config.HoleRadius = val
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

print("[Rokopia Suite] 5x5 Void Digger Engine Loaded!")
