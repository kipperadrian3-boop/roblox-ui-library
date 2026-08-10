--[[
    Rokopia - Custom Script Suite (rokopia.lua)
    Features: 
      - Troll Tab: "Build Random Holes" (Picks existing visual blocks around player and digs shaft holes)
      - Anti-Cheat Bypass: Uses Workspace raycast / part names ("Block_x,y,z") to only target existing blocks
      - Strict Anti-Cheat Safe (Respects ACTION_COOLDOWN 0.12s, SELECTION_MAX_BLOCKS = 1, ACTION_MAX_DISTANCE = 22)
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
    HoleRadius = 15,
    HoleDepth = 15,
    CooldownSpeed = 0.13 -- Safe delay above server's 0.1s ACTION_COOLDOWN
}

-- Fetch BreakBlock Remote Function
local function getBreakBlockRemote()
    local remoteFuncFolder = ReplicatedStorage:FindFirstChild("RemoteFunction")
    if remoteFuncFolder then
        return remoteFuncFolder:FindFirstChild("BreakBlock")
    end
    return nil
end

-- Find all existing Block parts around the player
local function findNearbyBlocks(hrp, maxRadiusStuds)
    local blocks = {}
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Include
    overlapParams.FilterDescendantsInstances = { Workspace }

    local parts = Workspace:GetPartBoundsInRadius(hrp.Position, maxRadiusStuds, overlapParams)
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") and string.sub(part.Name, 1, 6) == "Block_" then
            table.insert(blocks, part)
        end
    end
    return blocks
end

-- --------------------------------------------------------------------
-- BUILD RANDOM HOLES LOOP (Anti-Cheat Safe: 1 Block per 0.13s)
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

                -- Max distance allowed by server is 22 studs (~5 blocks)
                local maxStudDistance = math.min(Config.HoleRadius * 4.2, 21)
                local nearbyBlocks = findNearbyBlocks(hrp, maxStudDistance)

                if #nearbyBlocks > 0 then
                    -- Pick a random block from existing world blocks
                    local randomBlockPart = nearbyBlocks[math.random(1, #nearbyBlocks)]
                    local blockKey = string.sub(randomBlockPart.Name, 7)

                    if blockKey and blockKey ~= "" then
                        -- Double check distance to ensure zero kick risk
                        local dist = (hrp.Position - randomBlockPart.Position).Magnitude
                        if dist <= 21.5 then
                            -- Send exactly 1 block key per request (SELECTION_MAX_BLOCKS = 1)
                            breakRemote:InvokeServer({ blockKey })
                            
                            -- Enforce strict cooldown > ACTION_COOLDOWN (0.13s)
                            task.wait(Config.CooldownSpeed)
                        end
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

trollTab:CreateSlider("Hole Radius (Blocks)", 1, 5, 4, function(val)
    Config.HoleRadius = val
end)

trollTab:CreateSlider("Cooldown Delay (ms)", 120, 350, 130, function(val)
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

print("[Rokopia Suite] Updated with Part Bounds Block Key Detection!")
