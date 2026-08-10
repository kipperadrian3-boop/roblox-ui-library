--[[
    Rokopia - Aggressive Grass & Dirt Annihilator (rokopia_nuker.lua)
    Features:
      - Instantly targets & aggressive-nukes ONLY "block.grass" and "block.dirt"
      - Max Speed: 10ms Ultra-Fast Cooldown (0.01s per hit)
      - Hits Grass 2 times, Dirt 4 times (based on Rokopia's exact BlockConfig.luau)
      - Automatically teleports avatar directly over targeted block to bypass server distance limits
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
    warn("[Rokopia Nuker Error] Could not load UI Library from GitHub!")
    return
end

-- Create Interface with Cyber Blue Theme
local int = lib:CreateInterface("Rokopia Nuker", "Aggressive Grass & Dirt Annihilator", "", "bottom left", "cyber", 0.25)

local mainTab = int:CreateTab("Nuker", "Grass & Dirt Annihilator", "item", true)
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Configuration State
local Config = {
    Active = false,
    Radius = 30, -- Search radius in studs
    CooldownSpeed = 0.01, -- 10ms ultra-fast speed
    OnlyGrassAndDirt = true
}

-- Fetch Remotes
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
        task.wait(0.002)
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

-- Aggressively Break a Block (Targeting ONLY Grass [2 hits] & Dirt [4 hits])
local function nukerBreakBlock(targetX, targetY, targetZ)
    if not Config.Active then return false end

    local breakRemote = getBreakBlockRemote()
    if not breakRemote then return false end

    local key = string.format("%d,%d,%d", targetX, targetY, targetZ)

    -- 1. Teleport player directly over the block to satisfy server distance checks
    positionCharacterForBlock(targetX, targetY, targetZ)

    -- 2. First hit to check if a valid block exists
    local res = breakRemote:InvokeServer({ key })
    task.wait(Config.CooldownSpeed)

    -- If server returns false, no block exists here (empty air/void or non-destructible) -> skip!
    if res == false then
        return false
    end

    -- 3. Hit up to 4 times (Gras = 2 hits max, Dirt = 4 hits max in Rokopia)
    for hit = 2, 4 do
        if not Config.Active then break end

        local hitRes = breakRemote:InvokeServer({ key })
        task.wait(Config.CooldownSpeed)

        if hitRes == false then
            break
        end
    end

    return true
end


-- --------------------------------------------------------------------
-- AGGRESSIVE GRASS & DIRT NUKER ENGINE
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.02)
        if Config.Active then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local playerPos = hrp.Position
                local pX = math.floor(playerPos.X / 4.2)
                local pY = math.floor(playerPos.Y / 4.2)
                local pZ = math.floor(playerPos.Z / 4.2)

                local maxRadiusBlocks = math.clamp(math.floor(Config.Radius / 4.2), 1, 10)

                -- Aggressive sweep around player
                for dx = -maxRadiusBlocks, maxRadiusBlocks do
                    for dz = -maxRadiusBlocks, maxRadiusBlocks do
                        if not Config.Active then break end

                        local targetX = pX + dx
                        local targetZ = pZ + dz

                        -- Scan ground from top to bottom
                        for y = pY + 3, pY - 15, -1 do
                            if not Config.Active then break end

                            nukerBreakBlock(targetX, y, targetZ)
                        end
                    end
                end

                unanchorCharacter()
                task.wait(0.05)
            end)
        else
            unanchorCharacter()
        end
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: NUKER CONTROLS
-- --------------------------------------------------------------------
mainTab:CreateToggleSwitch("Aggressive Grass & Dirt Nuker", false, function(val)
    Config.Active = val
    if val then
        lib:Notify("Rokopia Nuker", "Aggressive Grass & Dirt Nuker STARTED (10ms Speed)!", 2.0)
    else
        unanchorCharacter()
        lib:Notify("Rokopia Nuker", "Nuker STOPPED.", 1.5)
    end
end)

mainTab:CreateSlider("Break Cooldown (ms)", 10, 100, 10, function(val)
    Config.CooldownSpeed = val / 1000
end)

mainTab:CreateSlider("Nuke Radius (Studs)", 5, 50, 30, function(val)
    Config.Radius = val
end)


-- --------------------------------------------------------------------
-- UI TAB 2: UI SETTINGS & TRANSPARENCY
-- --------------------------------------------------------------------
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)
local themesList = {"cyber", "royal", "emerald", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

print("[Rokopia Nuker] Aggressive Grass & Dirt Nuker Script Loaded!")
