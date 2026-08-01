--[[
    Blade Ball - Exact MoonSec Auto Parry & Combat Suite (blade_ball.lua)
    Dynamic Ping & Velocity Compensated Auto Parry (Keyless)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Framework
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua"))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Blade Ball Error] Could not load UI Library from GitHub!")
    return
end

local int = lib:CreateInterface("Blade Ball Suite", "MoonSec Auto Parry & Combat", "https://discord.gg/ZNTHTWx7KE", "bottom left", "royal")

local parryTab = int:CreateTab("Auto Parry", "Dynamic Ping & Velocity Deflect", "item", true)
local spamTab = int:CreateTab("Spam Parry", "Clash & Duel Rapid Parry", "op")
local abilityTab = int:CreateTab("Auto Ability", "Instant Ability Activation", "player")
local visualTab = int:CreateTab("Visuals", "Ball ESP & Highlight", "visuals")

-- Config
local Config = {
    AutoParry = true,
    ParryOffset = 15,
    SpamParry = false,
    SpamDistance = 20,
    AutoAbility = false,
    AbilityDistance = 30,
    BallHighlight = true,
    LastParry = 0
}

-- Fetch Local Player Ping in seconds
local function getPing()
    local pingValue = 0.05
    pcall(function()
        local item = Stats.Network.ServerStatsItem["Data Ping"]
        if item then
            pingValue = (item:GetValue() / 1000)
        end
    end)
    return math.clamp(pingValue, 0.02, 0.3)
end

-- Find Active Real Ball in Workspace
local function getActiveBall()
    local ballsFolder = Workspace:FindFirstChild("Balls")
    if ballsFolder then
        for _, ball in ipairs(ballsFolder:GetChildren()) do
            if ball:IsA("BasePart") and (ball:GetAttribute("realBall") == true or ball:GetAttribute("target") ~= nil) then
                return ball
            end
        end
        for _, ball in ipairs(ballsFolder:GetChildren()) do
            if ball:IsA("BasePart") then return ball end
        end
    end

    -- Fallback search in Workspace root
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") and (obj.Name == "Ball" or obj:GetAttribute("realBall") == true) then
            return obj
        end
    end

    return nil
end

-- Parry Remote & VIM Execution
local function getParryRemote()
    return ReplicatedStorage:FindFirstChild("ParryButtonPress", true)
        or ReplicatedStorage:FindFirstChild("ParryAttempt", true)
        or ReplicatedStorage:FindFirstChild("Parry", true)
end

local function fireParry()
    local currentTime = tick()
    if currentTime - Config.LastParry < 0.05 then return end
    Config.LastParry = currentTime

    -- 1. Fire RemoteEvent with Camera/Vector data
    pcall(function()
        local remote = getParryRemote()
        if remote and remote:IsA("RemoteEvent") then
            local cam = Workspace.CurrentCamera
            local camCF = cam and cam.CFrame or CFrame.new()
            remote:FireServer(0.5, camCF, {}, {Vector2.new(0, 0)})
        end
    end)

    -- 2. Trigger Keypress F via VirtualInputManager
    pcall(function()
        VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, true, game)
        task.wait(0.005)
        VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, false, game)
    end)

    -- 3. Firesignal UI Button Fallback
    pcall(function()
        if type(firesignal) == "function" then
            local pgui = LocalPlayer:FindFirstChild("PlayerGui")
            local blockBtn = pgui and pgui:FindFirstChild("Block", true)
            if blockBtn then
                if blockBtn:FindFirstChild("MouseButton1Click") then
                    firesignal(blockBtn.MouseButton1Click)
                elseif blockBtn:FindFirstChild("Activated") then
                    firesignal(blockBtn.Activated)
                end
            end
        end
    end)
end

local function fireAbility()
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("AbilityButtonPress", true)
            or ReplicatedStorage:FindFirstChild("UseAbility", true)
        if remote and remote:IsA("RemoteEvent") then
            remote:FireServer()
        end
        VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.Q, true, game)
        task.wait(0.005)
        VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.Q, false, game)
    end)
end


-- --------------------------------------------------------------------
-- 1. DYNAMIC PING & VELOCITY AUTO PARRY (Exact MoonSec Logic)
-- --------------------------------------------------------------------
parryTab:CreateCheckbox("Auto Parry (Dynamic Ping)", function(state)
    Config.AutoParry = state
end)

parryTab:CreateSlider("Parry Distance Offset", 50, 15, function(val)
    Config.ParryOffset = val
end)

RunService.PreRender:Connect(function()
    if not Config.AutoParry then return end

    pcall(function()
        local ball = getActiveBall()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if ball and hrp then
            local targetName = ball:GetAttribute("target")
            local distance = (ball.Position - hrp.Position).Magnitude
            local speed = ball.AssemblyLinearVelocity.Magnitude
            local ping = getPing()

            -- Calculate exact required parry distance based on ball speed & network ping
            local requiredDistance = (speed * (ping + 0.12)) + Config.ParryOffset

            local isTargetingMe = (targetName == LocalPlayer.Name)

            if isTargetingMe and distance <= requiredDistance then
                fireParry()
            end
        end
    end)
end)


-- --------------------------------------------------------------------
-- 2. SPAM PARRY (DUEL / CLASH MODE)
-- --------------------------------------------------------------------
spamTab:CreateCheckbox("Auto Spam Parry (Clash)", function(state)
    Config.SpamParry = state
end)

spamTab:CreateSlider("Clash Distance Trigger", 50, 20, function(val)
    Config.SpamDistance = val
end)

RunService.RenderStepped:Connect(function()
    if not Config.SpamParry then return end
    pcall(function()
        local ball = getActiveBall()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if ball and hrp then
            local distance = (ball.Position - hrp.Position).Magnitude
            local targetName = ball:GetAttribute("target")

            if targetName == LocalPlayer.Name and distance <= Config.SpamDistance then
                fireParry()
            end
        end
    end)
end)


-- --------------------------------------------------------------------
-- 3. AUTO ABILITY
-- --------------------------------------------------------------------
abilityTab:CreateCheckbox("Auto Activate Ability on Target", function(state)
    Config.AutoAbility = state
end)

abilityTab:CreateSlider("Ability Distance Trigger", 80, 30, function(val)
    Config.AbilityDistance = val
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        if Config.AutoAbility then
            pcall(function()
                local ball = getActiveBall()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if ball and hrp then
                    local distance = (ball.Position - hrp.Position).Magnitude
                    local targetName = ball:GetAttribute("target")
                    if targetName == LocalPlayer.Name and distance <= Config.AbilityDistance then
                        fireAbility()
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- 4. BALL ESP & HIGHLIGHT
-- --------------------------------------------------------------------
visualTab:CreateCheckbox("Highlight Ball (Green/Red Target)", function(state)
    Config.BallHighlight = state
end)

task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.BallHighlight then
            pcall(function()
                local ball = getActiveBall()
                if ball then
                    local highlight = ball:FindFirstChild("MoonSecBallHighlight")
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "MoonSecBallHighlight"
                        highlight.FillTransparency = 0.3
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.Parent = ball
                    end

                    local targetName = ball:GetAttribute("target")
                    if targetName == LocalPlayer.Name then
                        highlight.FillColor = Color3.fromRGB(255, 30, 30) -- Red when targeting player
                    else
                        highlight.FillColor = Color3.fromRGB(30, 255, 100) -- Green when targeting someone else
                    end
                end
            end)
        end
    end
end)

print("[Blade Ball MoonSec Suite] Auto Parry Engine Active!")
