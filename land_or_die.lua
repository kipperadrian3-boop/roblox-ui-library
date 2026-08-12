--[[
	Land or Die - Official Script Suite (land_or_die.lua)
	Complete Land or Die Automation Suite
	Features:
	  - Auto Farm / Class Upgrade / Leveling System
	  - Auto Fuel / Generator / Energy Management
	  - Auto Repair & Base Maintenance
	  - Miles & Claim Rewards Automation
	  - Player Movement & Fly Suite
	  - Glassmorphic UI via UI Library Framework (lib.lua) with JSON Auto-Save
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework with Cache Buster & Universal JSON Config Engine
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Land or Die Error] Could not load UI Library from GitHub!")
    return
end

-- Create Interface with Cyber Theme
local int = lib:CreateInterface("Land or Die Suite", "Complete Survival & Farm Automation", "https://discord.gg/ZNTHTWx7KE", "bottom left", "cyber", 0.25)

-- Tabs
local mainTab = int:CreateTab("Automation", "Auto Farm & Maintenance", "op", true)
local playerTab = int:CreateTab("Player", "Movement & Character", "player")
local espTab = int:CreateTab("ESP & Visuals", "World Trackers", "eye")
local settingsTab = int:CreateTab("Settings", "UI & Config", "misc")

-- State Configuration
local Config = {
    AutoFarm = false,
    AutoFuel = false,
    AutoRepair = false,
    AutoClaimMiles = false,
    FarmSpeedMs = 10,
    FarmRange = 35,
    WalkSpeed = 16,
    JumpPower = 50,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
    EspBase = false,
    EspGenerator = false,
    EspPlayers = false
}

-- --------------------------------------------------------------------
-- HELPER FUNCTIONS FOR LAND OR DIE GAMEPLAY
-- --------------------------------------------------------------------

local function safeFireRemote(remoteName, ...)
    pcall(function()
        local rem = ReplicatedStorage:FindFirstChild(remoteName, true)
        if rem and rem:IsA("RemoteEvent") then
            rem:FireServer(...)
        elseif rem and rem:IsA("RemoteFunction") then
            rem:InvokeServer(...)
        end
    end)
end

local function fireNearestPrompt(targetKeywords, maxDistance)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local actionText = obj.ActionText:lower()
            local objectText = obj.ObjectText:lower()
            local match = false
            for _, kw in ipairs(targetKeywords) do
                if actionText:find(kw) or objectText:find(kw) or obj.Name:lower():find(kw) then
                    match = true
                    break
                end
            end
            if match and obj.Parent and obj.Parent:IsA("BasePart") then
                local dist = (hrp.Position - obj.Parent.Position).Magnitude
                if dist <= (maxDistance or 40) then
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(obj)
                        else
                            obj:InputHoldBegin()
                            task.wait(obj.HoldDuration or 0.1)
                            obj:InputHoldEnd()
                        end
                    end)
                end
            end
        end
    end
end

-- --------------------------------------------------------------------
-- 1. AUTOMATION LOOP (FARM, FUEL, REPAIR, REWARDS)
-- --------------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(Config.FarmSpeedMs / 1000)

        -- Auto Farm / Build / Collect
        if Config.AutoFarm then
            pcall(function()
                fireNearestPrompt({"farm", "harvest", "collect", "chop", "mine", "land", "claim", "build"}, Config.FarmRange)
                safeFireRemote("FarmRemote")
                safeFireRemote("CollectResource")
            end)
        end

        -- Auto Fuel / Generator
        if Config.AutoFuel then
            pcall(function()
                fireNearestPrompt({"fuel", "generator", "energy", "power", "refuel", "gas"}, Config.FarmRange + 10)
                safeFireRemote("RefuelGenerator")
            end)
        end

        -- Auto Repair Base
        if Config.AutoRepair then
            pcall(function()
                fireNearestPrompt({"repair", "fix", "upgrade", "restore", "build"}, Config.FarmRange + 10)
                safeFireRemote("RepairStructure")
            end)
        end

        -- Auto Claim Miles / Daily Rewards
        if Config.AutoClaimMiles then
            pcall(function()
                safeFireRemote("ClaimMiles")
                safeFireRemote("ClaimDaily")
                safeFireRemote("ClaimReward")
            end)
        end
    end
end)

-- --------------------------------------------------------------------
-- 2. MOVEMENT & NOCLIP & FLY
-- --------------------------------------------------------------------

RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Fly BodyGyro & BodyVelocity setup
local flyGyro, flyVel

local function startFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    flyGyro = Instance.new("BodyGyro")
    flyGyro.P = 9e4
    flyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.cframe = hrp.CFrame
    flyGyro.Parent = hrp

    flyVel = Instance.new("BodyVelocity")
    flyVel.velocity = Vector3.new(0, 0.1, 0)
    flyVel.maxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVel.Parent = hrp
end

local function stopFly()
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
    if flyVel then flyVel:Destroy() flyVel = nil end
end

RunService.RenderStepped:Connect(function()
    if Config.Fly and flyVel and flyGyro and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local cam = Workspace.CurrentCamera
        if hrp and cam then
            flyGyro.cframe = cam.CFrame
            local dir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end

            flyVel.velocity = dir * Config.FlySpeed
        end
    end
end)

-- --------------------------------------------------------------------
-- 3. ESP HIGHLIGHT SUITE
-- --------------------------------------------------------------------

local activeHighlights = {}

local function applyHighlight(obj, color, tag)
    if not obj or activeHighlights[obj] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "LandOrDieESP_" .. tag
    hl.Adornee = obj
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.25
    hl.OutlineTransparency = 1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    activeHighlights[obj] = hl
end

local function clearHighlights(tag)
    for obj, hl in pairs(activeHighlights) do
        if hl and hl.Name == "LandOrDieESP_" .. tag then
            pcall(function() hl:Destroy() end)
            activeHighlights[obj] = nil
        end
    end
end

-- --------------------------------------------------------------------
-- UI ELEMENTS SETUP
-- --------------------------------------------------------------------

-- MAIN TAB (AUTOMATION)
mainTab:CreateComment("--- Land or Die Auto Farm & Maintenance ---")

mainTab:CreateToggleSwitch("Auto Farm / Harvest / Collect", false, function(val)
    Config.AutoFarm = val
    if val then lib:Notify("Land or Die", "Auto Farm Activated!", 2.0) end
end)

mainTab:CreateToggleSwitch("Auto Refuel Generator", false, function(val)
    Config.AutoFuel = val
    if val then lib:Notify("Land or Die", "Auto Refuel Activated!", 2.0) end
end)

mainTab:CreateToggleSwitch("Auto Repair Base Structures", false, function(val)
    Config.AutoRepair = val
    if val then lib:Notify("Land or Die", "Auto Repair Activated!", 2.0) end
end)

mainTab:CreateToggleSwitch("Auto Claim Miles & Rewards", false, function(val)
    Config.AutoClaimMiles = val
    if val then lib:Notify("Land or Die", "Auto Claim Rewards Active!", 2.0) end
end)

mainTab:CreateSlider("Farm Speed Delay (ms)", 10, 500, 10, function(val)
    Config.FarmSpeedMs = val
end)

mainTab:CreateSlider("Auto Range (Studs)", 10, 100, 35, function(val)
    Config.FarmRange = val
end)

-- PLAYER TAB
playerTab:CreateComment("--- Movement & Speed Suite ---")

playerTab:CreateSlider("WalkSpeed", 16, 250, 16, function(val)
    Config.WalkSpeed = val
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
        end
    end)
end)

playerTab:CreateSlider("JumpPower", 50, 300, 50, function(val)
    Config.JumpPower = val
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
        end
    end)
end)

playerTab:CreateToggleSwitch("Noclip (Walk Through Walls)", false, function(val)
    Config.Noclip = val
    if val then lib:Notify("Player", "Noclip Enabled!", 2.0) end
end)

playerTab:CreateToggleSwitch("WASD Flight System", false, function(val)
    Config.Fly = val
    if val then
        startFly()
        lib:Notify("Player", "Flight Mode Enabled! Use WASD + Q/E", 2.5)
    else
        stopFly()
        lib:Notify("Player", "Flight Mode Disabled.", 1.5)
    end
end)

playerTab:CreateSlider("Fly Speed", 10, 250, 50, function(val)
    Config.FlySpeed = val
end)

-- ESP TAB
espTab:CreateComment("--- World Object Trackers ---")

espTab:CreateToggleSwitch("Generator & Fuel ESP (ORANGE)", false, function(val)
    Config.EspGenerator = val
    if val then
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            local name = descendant.Name:lower()
            if name:find("generator") or name:find("fuel") or name:find("power") or name:find("gas") then
                applyHighlight(descendant, Color3.fromRGB(255, 140, 0), "Gen")
            end
        end
    else
        clearHighlights("Gen")
    end
end)

espTab:CreateToggleSwitch("Player ESP (GREEN)", false, function(val)
    Config.EspPlayers = val
    if val then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                applyHighlight(p.Character, Color3.fromRGB(0, 255, 128), "Plr")
            end
        end
    else
        clearHighlights("Plr")
    end
end)

-- SETTINGS TAB
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)
local themesList = {"cyber", "emerald", "royal", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

print("[Land or Die Suite] Official Land or Die Script Loaded Successfully!")
