--[[
    Blade Ball - Anti-Bypass Safe Parry Suite (blade_ball.lua)
    Optimized for zero anti-cheat detection & humanized timing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

local int = lib:CreateInterface("Blade Ball Safe Suite", "Undetectable Parry & Combat Tools", "https://discord.gg/ZNTHTWx7KE", "bottom left", "royal")

local parryTab = int:CreateTab("Safe Parry", "Humanized Parry & Auto Deflect", "item", true)
local spamTab = int:CreateTab("Safe Clash", "Controlled Rapid Deflect", "op")
local visualTab = int:CreateTab("Visuals", "Ball Highlighter & Info", "visuals")

-- Config
local Config = {
    AutoParry = false,
    ParryDistance = 25,
    HumanizeDelay = 0.05,
    SpamParry = false,
    SpamDistance = 12,
    BallHighlight = false,
    LastParryTime = 0
}

-- Anti-Cheat Safe Remote & Input Handler
local function getSafeParryRemote()
    -- Blade Ball Anti-Cheat monitors rapid direct RemoteEvent spam without proper camera/client context
    local remote = ReplicatedStorage:FindFirstChild("ParryButtonPress", true)
        or ReplicatedStorage:FindFirstChild("ParryAttempt", true)
        or ReplicatedStorage:FindFirstChild("Parry", true)
    return remote
end

local function fireSafeParry()
    -- Throttle parry calls to mimic human click speed and prevent AC kick
    local currentTime = tick()
    if currentTime - Config.LastParryTime < 0.12 then
        return
    end
    Config.LastParryTime = currentTime

    pcall(function()
        local remote = getSafeParryRemote()
        if remote and remote:IsA("RemoteEvent") then
            -- Pass Camera CFrame / Target Vector expected by Blade Ball AC
            local camera = Workspace.CurrentCamera
            local camCF = camera and camera.CFrame or CFrame.new()
            remote:FireServer(0.5, camCF, {}, {Vector2.new(0, 0)})
        end
    end)
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
-- 1. HUMANIZE SAFE AUTO PARRY
-- --------------------------------------------------------------------
parryTab:CreateCheckbox("Enable Safe Auto Parry", function(state)
    Config.AutoParry = state
end)

parryTab:CreateSlider("Safe Parry Distance", 60, 25, function(val)
    Config.ParryDistance = val
end)

parryTab:CreateSlider("Human Reaction Delay (ms)", 100, 30, function(val)
    Config.HumanizeDelay = val / 1000
end)

RunService.RenderStepped:Connect(function()
    if not Config.AutoParry then return end
    pcall(function()
        local ball = getActiveBall()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if ball and hrp then
            local distance = (ball.Position - hrp.Position).Magnitude
            local velocity = ball.AssemblyLinearVelocity.Magnitude
            local targetPlayerName = ball:GetAttribute("target")

            local isTargetingMe = (targetPlayerName == LocalPlayer.Name)

            if isTargetingMe then
                local timeToReach = distance / math.max(velocity, 1)
                -- Add human reaction time delay so anti-cheat doesn't flag impossible 0ms reaction
                if timeToReach <= (0.2 + Config.HumanizeDelay) or distance <= Config.ParryDistance then
                    task.wait(Config.HumanizeDelay)
                    fireSafeParry()
                end
            end
        end
    end)
end)


-- --------------------------------------------------------------------
-- 2. SAFE CLASH / SPAM PARRY
-- --------------------------------------------------------------------
spamTab:CreateCheckbox("Enable Safe Clash Mode", function(state)
    Config.SpamParry = state
end)

spamTab:CreateSlider("Clash Distance", 30, 12, function(val)
    Config.SpamDistance = val
end)

task.spawn(function()
    while true do
        task.wait(0.08) -- 80ms throttle to avoid server kick for remote rate limiting
        if Config.SpamParry then
            pcall(function()
                local ball = getActiveBall()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if ball and hrp then
                    local distance = (ball.Position - hrp.Position).Magnitude
                    local targetPlayerName = ball:GetAttribute("target")
                    if targetPlayerName == LocalPlayer.Name and distance <= Config.SpamDistance then
                        fireSafeParry()
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- 3. VISUAL BALL HIGHLIGHTER
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
                if ball and not ball:FindFirstChild("SafeBallHighlight") then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "SafeBallHighlight"
                    highlight.FillColor = Color3.fromRGB(0, 220, 130)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.4
                    highlight.Parent = ball
                end
            end)
        end
    end
end)

print("[Blade Ball Safe Suite] Loaded Successfully!")
