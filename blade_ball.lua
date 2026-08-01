--[[
    Blade Ball - Advanced Utility Suite (Deobfuscated & Keyless)
    Official Keyless Script Suite for Roblox Blade Ball
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua"))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Blade Ball Error] Could not load UI Library from GitHub!")
    return
end

local int = lib:CreateInterface("Blade Ball Suite", "Auto Parry & Combat Utilities", "https://discord.gg/ZNTHTWx7KE", "bottom left", "royal")

local parryTab = int:CreateTab("Auto Parry", "Deflect & Timing Controls", "item", true)
local spamTab = int:CreateTab("Spam Parry", "Clash & Duel Rapid Deflect", "op")
local abilityTab = int:CreateTab("Abilities", "Auto Ability Activation", "player")
local visualTab = int:CreateTab("Visuals", "Ball Highlighter & FOV", "visuals")
local perfTab = int:CreateTab("FPS Booster", "Performance & Lag Reduction", "misc")

-- Configuration State
local Config = {
    AutoParry = false,
    ParryDistance = 30,
    SpamParry = false,
    SpamDistance = 15,
    AutoAbility = false,
    AbilityDistance = 25,
    BallHighlight = false,
    ParryCircle = false,
    BoostFPS = false
}

-- Helpers & Remote Finder
local function getParryRemote()
    return ReplicatedStorage:FindFirstChild("ParryButtonPress", true)
        or ReplicatedStorage:FindFirstChild("ParryAttempt", true)
        or ReplicatedStorage:FindFirstChild("Parry", true)
        or ReplicatedStorage:FindFirstChild("Remotes", true) and ReplicatedStorage.Remotes:FindFirstChild("ParryButtonPress")
end

local function getAbilityRemote()
    return ReplicatedStorage:FindFirstChild("AbilityButtonPress", true)
        or ReplicatedStorage:FindFirstChild("UseAbility", true)
        or ReplicatedStorage:FindFirstChild("Ability", true)
end

local function fireParry()
    local remote = getParryRemote()
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer()
    else
        pcall(function()
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, true, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, false, game)
        end)
    end
end

local function fireAbility()
    local remote = getAbilityRemote()
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer()
    else
        pcall(function()
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.Q, true, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.Q, false, game)
        end)
    end
end

local function getActiveBall()
    local balls = Workspace:FindFirstChild("Balls") or Workspace
    for _, child in ipairs(balls:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("realBall") == true then
            return child
        elseif child.Name == "Ball" and child:IsA("BasePart") then
            return child
        end
    end
    return nil
end

-- --------------------------------------------------------------------
-- 1. AUTO PARRY & DEFLECT LOGIC
-- --------------------------------------------------------------------
parryTab:CreateCheckbox("Auto Parry (Auto Deflect)", function(state)
    Config.AutoParry = state
end)

parryTab:CreateSlider("Parry Distance Offset", 100, 30, function(val)
    Config.ParryDistance = val
end)

RunService.PreRender:Connect(function()
    if not Config.AutoParry then return end
    pcall(function()
        local ball = getActiveBall()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if ball and hrp then
            local distance = (ball.Position - hrp.Position).Magnitude
            local velocity = ball.AssemblyLinearVelocity.Magnitude
            local targetPlayerName = ball:GetAttribute("target") or (ball:FindFirstChild("Target") and ball.Target.Value)

            local isTargetingMe = (targetPlayerName == LocalPlayer.Name) or (distance / math.max(velocity, 1) < 0.35)

            if isTargetingMe and distance <= (Config.ParryDistance + (velocity * 0.15)) then
                fireParry()
            end
        end
    end)
end)


-- --------------------------------------------------------------------
-- 2. SPAM PARRY (CLASH MODE)
-- --------------------------------------------------------------------
spamTab:CreateCheckbox("Auto Spam Parry (Clash Mode)", function(state)
    Config.SpamParry = state
end)

spamTab:CreateSlider("Spam Trigger Distance", 50, 15, function(val)
    Config.SpamDistance = val
end)

task.spawn(function()
    while true do
        task.wait(0.02)
        if Config.SpamParry then
            pcall(function()
                local ball = getActiveBall()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if ball and hrp then
                    local distance = (ball.Position - hrp.Position).Magnitude
                    if distance <= Config.SpamDistance then
                        fireParry()
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- 3. AUTO ABILITY
-- --------------------------------------------------------------------
abilityTab:CreateCheckbox("Auto Use Ability on Target", function(state)
    Config.AutoAbility = state
end)

abilityTab:CreateSlider("Ability Activation Distance", 80, 25, function(val)
    Config.AbilityDistance = val
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.AutoAbility then
            pcall(function()
                local ball = getActiveBall()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if ball and hrp then
                    local distance = (ball.Position - hrp.Position).Magnitude
                    local targetPlayerName = ball:GetAttribute("target")
                    if targetPlayerName == LocalPlayer.Name and distance <= Config.AbilityDistance then
                        fireAbility()
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- 4. VISUAL TRACKER & HIGHLIGHTER
-- --------------------------------------------------------------------
visualTab:CreateCheckbox("Highlight Active Ball", function(state)
    Config.BallHighlight = state
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.BallHighlight then
            pcall(function()
                local ball = getActiveBall()
                if ball and not ball:FindFirstChild("BallHighlight") then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "BallHighlight"
                    highlight.FillColor = Color3.fromRGB(255, 50, 50)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.3
                    highlight.Parent = ball
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- 5. FPS BOOSTER
-- --------------------------------------------------------------------
perfTab:CreateCheckbox("Enable Combat FPS Booster", function(state)
    Config.BoostFPS = state
end)

task.spawn(function()
    while true do
        task.wait(2)
        if Config.BoostFPS then
            pcall(function()
                for _, desc in ipairs(Workspace:GetDescendants()) do
                    if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") or desc:IsA("Smoke") then
                        desc.Enabled = false
                    end
                end
            end)
        end
    end
end)

print("[Blade Ball Suite] Loaded Successfully (Keyless Execution)!")
