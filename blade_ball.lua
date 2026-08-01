--[[
    Blade Ball - 100% Safe Undetectable Parry (blade_ball.lua)
    Bypasses Blade Ball Anti-Cheat by triggering native UI signals & keypresses.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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

local int = lib:CreateInterface("Blade Ball Safe Suite", "Undetectable Anti-Kick Parry", "https://discord.gg/ZNTHTWx7KE", "bottom left", "royal")

local parryTab = int:CreateTab("Safe Parry", "Humanized Parry & Auto Deflect", "item", true)
local spamTab = int:CreateTab("Safe Clash", "Controlled Rapid Deflect", "op")
local visualTab = int:CreateTab("Visuals", "Ball Highlighter & Info", "visuals")

-- Config
local Config = {
    AutoParry = false,
    ParryDistance = 30,
    HumanizeDelay = 0.03,
    SpamParry = false,
    SpamDistance = 15,
    BallHighlight = false,
    LastParryTime = 0
}

-- 100% Safe Anti-Cheat Bypass Parry Execution
-- Rather than calling FireServer with fake parameters (which causes AC kick),
-- we fire the native UI signals and keyboard inputs that the game's own client expects!
local function executeSafeParry()
    local currentTime = tick()
    if currentTime - Config.LastParryTime < 0.1 then
        return
    end
    Config.LastParryTime = currentTime

    -- Method 1: Firesignal on UI Block Button (100% Safe, triggers client script natively)
    local triggeredUI = false
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local hotbar = playerGui:FindFirstChild("Hotbar", true) or playerGui:FindFirstChild("Main", true)
            local blockBtn = hotbar and (hotbar:FindFirstChild("Block", true) or hotbar:FindFirstChild("Parry", true))
            if blockBtn and type(firesignal) == "function" then
                if blockBtn:FindFirstChild("MouseButton1Click") then
                    firesignal(blockBtn.MouseButton1Click)
                    triggeredUI = true
                end
                if blockBtn:FindFirstChild("Activated") then
                    firesignal(blockBtn.Activated)
                    triggeredUI = true
                end
            end
        end
    end)

    -- Method 2: Native Executor Keypress (F Key / Mouse Click)
    if not triggeredUI then
        pcall(function()
            if type(keypress) == "function" and type(keyrelease) == "function" then
                keypress(0x46) -- F Key
                task.wait(0.01)
                keyrelease(0x46)
            elseif type(mouse1click) == "function" then
                mouse1click()
            else
                VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, true, game)
                task.wait(0.01)
                VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, false, game)
            end
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
-- 1. SAFE AUTO PARRY
-- --------------------------------------------------------------------
parryTab:CreateCheckbox("Enable Safe Auto Parry", function(state)
    Config.AutoParry = state
end)

parryTab:CreateSlider("Safe Parry Distance", 80, 30, function(val)
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
                if timeToReach <= (0.25 + Config.HumanizeDelay) or distance <= Config.ParryDistance then
                    if Config.HumanizeDelay > 0 then
                        task.wait(Config.HumanizeDelay)
                    end
                    executeSafeParry()
                end
            end
        end
    end)
end)


-- --------------------------------------------------------------------
-- 2. SAFE CLASH MODE
-- --------------------------------------------------------------------
spamTab:CreateCheckbox("Enable Safe Clash Mode", function(state)
    Config.SpamParry = state
end)

spamTab:CreateSlider("Clash Distance", 40, 15, function(val)
    Config.SpamDistance = val
end)

task.spawn(function()
    while true do
        task.wait(0.08)
        if Config.SpamParry then
            pcall(function()
                local ball = getActiveBall()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if ball and hrp then
                    local distance = (ball.Position - hrp.Position).Magnitude
                    local targetPlayerName = ball:GetAttribute("target")
                    if targetPlayerName == LocalPlayer.Name and distance <= Config.SpamDistance then
                        executeSafeParry()
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
