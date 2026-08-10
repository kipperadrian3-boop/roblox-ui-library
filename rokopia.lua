--[[
    Rokopia - Custom Script Suite (rokopia.lua)
    Features: 
      - Troll Tab: "Build Random Holes" (Picks random surface blocks and digs vertical shaft holes downwards)
      - Anti-Cheat Safeguards: 1 block per call, 200ms safe cooldown, distance <= 20 studs
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

-- --------------------------------------------------------------------
-- BUILD RANDOM HOLES LOOP (Anti-Cheat Safe: 1 Block per 200ms)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.RandomHoles then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local breakRemote = getBreakBlockRemote()
                if not breakRemote then return end

                -- Get player grid block coordinates
                local playerPos = hrp.Position
                local pX = math.floor(playerPos.X / 4.2)
                local pY = math.floor(playerPos.Y / 4.2)
                local pZ = math.floor(playerPos.Z / 4.2)

                -- Select random column within HoleRadius (Max distance 22 studs = ~4 blocks)
                local maxRadiusBlocks = math.clamp(math.floor(Config.HoleRadius / 4.2), 1, 4)
                local randOffsetX = math.random(-maxRadiusBlocks, maxRadiusBlocks)
                local randOffsetZ = math.random(-maxRadiusBlocks, maxRadiusBlocks)
                local targetX = pX + randOffsetX
                local targetZ = pZ + randOffsetZ

                -- Dig vertically downwards from player level
                local startY = pY + 1
                local endY = math.max(pY - Config.HoleDepth, -64)

                for y = startY, endY, -1 do
                    if not Config.RandomHoles then break end

                    -- Re-check distance to ensure no kick (ACTION_MAX_DISTANCE = 22 studs)
                    local currentHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not currentHrp then break end

                    local blockWorldPos = Vector3.new(targetX * 4.2, y * 4.2, targetZ * 4.2)
                    local dist = (currentHrp.Position - blockWorldPos).Magnitude

                    if dist <= 20 then
                        local key = string.format("%d,%d,%d", targetX, y, targetZ)
                        
                        -- Send EXACT 1 block per invocation (SELECTION_MAX_BLOCKS = 1)
                        breakRemote:InvokeServer({ key })

                        -- Wait safe 200ms cooldown (above server's 100ms ACTION_COOLDOWN)
                        task.wait(Config.CooldownSpeed)
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: TROLL CONTROLS
-- --------------------------------------------------------------------
trollTab:CreateToggleSwitch("Build Random Holes", false, function(val)
    Config.RandomHoles = val
    if val then
        lib:Notify("Rokopia Troll", "Build Random Holes Active (Anti-Cheat Safe)!", 1.5)
    else
        lib:Notify("Rokopia Troll", "Build Random Holes Stopped.", 1.5)
    end
end)

trollTab:CreateSlider("Hole Radius (Studs)", 5, 20, 15, function(val)
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

print("[Rokopia Suite] Loaded with Cache Buster!")
