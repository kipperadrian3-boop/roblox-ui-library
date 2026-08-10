--[[
    Rokopia - Custom Script Suite (rokopia.lua)
    Features: 
      - Troll Tab: "Build Random Holes" (Picks random surface blocks and digs vertical shaft holes downwards)
      - Customizable Hole Radius & Depth Sliders
    Powered by Custom UI Framework (lib.lua)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua"))()
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
    HoleRadius = 20,
    HoleDepth = 15,
    DigSpeed = 0.15
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
-- BUILD RANDOM HOLES LOOP
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(Config.DigSpeed)
        if Config.RandomHoles then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local breakRemote = getBreakBlockRemote()
                if not breakRemote then return end

                -- Get player block position
                local playerPos = hrp.Position
                local pX = math.floor(playerPos.X)
                local pY = math.floor(playerPos.Y)
                local pZ = math.floor(playerPos.Z)

                -- Select random column within HoleRadius
                local randOffsetX = math.random(-Config.HoleRadius, Config.HoleRadius)
                local randOffsetZ = math.random(-Config.HoleRadius, Config.HoleRadius)
                local targetX = pX + randOffsetX
                local targetZ = pZ + randOffsetZ

                -- Dig vertically downwards from top to bottom
                local startY = pY + 2
                local endY = math.max(pY - Config.HoleDepth, -64)

                local blockKeysToBreak = {}
                for y = startY, endY, -1 do
                    local key = string.format("%d,%d,%d", targetX, y, targetZ)
                    table.insert(blockKeysToBreak, key)

                    -- Break in small batches to respect SELECTION_MAX_BLOCKS
                    if #blockKeysToBreak >= 5 then
                        breakRemote:InvokeServer(blockKeysToBreak)
                        blockKeysToBreak = {}
                        task.wait(0.05)
                    end
                end

                if #blockKeysToBreak > 0 then
                    breakRemote:InvokeServer(blockKeysToBreak)
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
        lib:Notify("Rokopia Troll", "Build Random Holes Started!", 1.5)
    else
        lib:Notify("Rokopia Troll", "Build Random Holes Stopped.", 1.5)
    end
end)

trollTab:CreateSlider("Hole Radius (Blocks)", 5, 40, 20, function(val)
    Config.HoleRadius = val
end)

trollTab:CreateSlider("Hole Depth (Blocks)", 5, 30, 15, function(val)
    Config.HoleDepth = val
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

print("[Rokopia Suite] Loaded Successfully!")
