--[[
    Blade Ball - High-Precision Sub-Frame Auto Parry Engine (blade_ball.lua)
    Powered by Custom UI Library (lib.lua) with Glassmorphism & Theme Switcher
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

-- Load Custom UI Library Framework (lib.lua)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua"))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Blade Ball Error] Could not load UI Library from GitHub!")
    return
end

local int = lib:CreateInterface("Blade Ball Suite", "Ultra-Precision Auto Parry Engine", "https://discord.gg/ZNTHTWx7KE", "bottom left", "royal", 0.25)

local parryTab = int:CreateTab("Auto Parry", "Sub-Frame & Curve Prediction", "item", true)
local spamTab = int:CreateTab("Spam Parry", "Auto Spam & Close Fighting", "op")
local chatTab = int:CreateTab("Auto Chat", "Auto GG & Chat Responses", "player")
local visualTab = int:CreateTab("Visuals", "Ball Predictor & Visualizer", "visuals")
local settingsTab = int:CreateTab("UI Settings", "Themes & Customization", "misc")

-- Config & State
local Config = {
    AutoParry = true,
    AutoSpam = false,
    SpamDistance = 8,
    ParryOffset = 5,
    CurvePrediction = true,
    PingCompensation = true,
    UseAbility = false,
    NotifyParried = false,
    AutoGG = false,
    AutoResponse = false,
    LastParryTick = 0
}

local responses = {"lol what", "??", "wdym", "bru what", "mad cuz bad", "skill issue", "cry"}
local gameEndResponses = {"ggs", "gg :3", "good game", "ggs yall", "wp", "ggs man"}
local keywords = {"auto parry", "auto", "cheating", "hacking"}
local ggdebounce = false
local responsedebounce = false

local focusedBall = nil
local distanceVisualizer = nil
local lastBallPosition = Vector3.new()
local ballVelocityVector = Vector3.new()

-- Remotes & Character
local ballsFolder = Workspace:WaitForChild("Balls")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local parryRemote = remotesFolder:FindFirstChild("ParryButtonPress") or remotesFolder:FindFirstChild("ParryAttempt")
local abilityRemote = remotesFolder:FindFirstChild("AbilityButtonPress") or remotesFolder:FindFirstChild("UseAbility")

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
LocalPlayer.CharacterAdded:Connect(function(c) character = c end)

-- UI Gradients for Cooldown Check
local function getUIGradients()
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local hotbar = pgui and pgui:FindFirstChild("Hotbar")
    if hotbar then
        local uigrad1 = hotbar:FindFirstChild("Block") and hotbar.Block:FindFirstChild("border1") and hotbar.Block.border1:FindFirstChild("UIGradient")
        local uigrad2 = hotbar:FindFirstChild("Ability") and hotbar.Ability:FindFirstChild("border2") and hotbar.Ability.border2:FindFirstChild("UIGradient")
        return uigrad1, uigrad2
    end
    return nil, nil
end

local function isCooldownInEffect(uigradient)
    if not uigradient then return false end
    return uigradient.Offset.Y < 0.5
end

-- Get Real Time Network Ping (in seconds)
local function getNetworkPing()
    local ping = 0.04
    pcall(function()
        local statsItem = Stats.Network.ServerStatsItem["Data Ping"]
        if statsItem then
            ping = statsItem:GetValue() / 1000
        end
    end)
    return math.clamp(ping, 0.015, 0.35)
end

-- Multi-Execution Parry Trigger (Guarantees zero missed inputs)
local function fireParry()
    local now = tick()
    if now - Config.LastParryTick < 0.04 then return end
    Config.LastParryTick = now

    -- 1. Direct Remote Call
    pcall(function()
        if parryRemote then
            if parryRemote:IsA("BindableEvent") then
                parryRemote:Fire()
            elseif parryRemote:IsA("RemoteEvent") then
                local cam = Workspace.CurrentCamera
                local camCF = cam and cam.CFrame or CFrame.new()
                parryRemote:FireServer(0.5, camCF, {}, {Vector2.new(0, 0)})
            end
        end
    end)

    -- 2. Virtual Input Manager (F Key Press)
    pcall(function()
        VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, true, game)
        task.wait(0.001)
        VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, false, game)
    end)

    -- 3. Firesignal UI Fallback
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

    if Config.NotifyParried then
        lib:Notify("Auto Parry", "Parried Ball Successfully!", 0.4)
    end
end

local function fireAbility()
    pcall(function()
        if abilityRemote then
            if abilityRemote:IsA("BindableEvent") then
                abilityRemote:Fire()
            elseif abilityRemote:IsA("RemoteEvent") then
                abilityRemote:FireServer()
            end
        end
        VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.Q, true, game)
        task.wait(0.001)
        VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.Q, false, game)
    end)
end

-- Find Active Ball
local function getTargetBall()
    for _, ball in ipairs(ballsFolder:GetChildren()) do
        if ball:IsA("BasePart") and (ball:GetAttribute("realBall") == true or ball:GetAttribute("target") ~= nil) then
            return ball
        end
    end
    for _, ball in ipairs(ballsFolder:GetChildren()) do
        if ball:IsA("BasePart") then return ball end
    end
    return nil
end

-- Check if Ball Targets LocalPlayer
local function isTargetingMe(ball)
    if not ball then return false end
    local targetAttr = ball:GetAttribute("target")
    if targetAttr == LocalPlayer.Name then return true end
    if ball.BrickColor == BrickColor.new("Really red") then return true end
    return false
end

-- --------------------------------------------------------------------
-- SUB-FRAME HIGH-PRECISION PREDICTION LOOP (PreRender Hook)
-- --------------------------------------------------------------------
RunService.PreRender:Connect(function(deltaTime)
    if not Config.AutoParry and not Config.AutoSpam then return end
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local ball = getTargetBall()
    if not ball or not ball.Parent then
        if distanceVisualizer then
            distanceVisualizer:Destroy()
            distanceVisualizer = nil
        end
        return
    end

    local hrp = character.HumanoidRootPart
    local hrpPos = hrp.Position
    local ballPos = ball.Position
    local distance = (ballPos - hrpPos).Magnitude

    -- Compute Instant Speed and Velocity
    local currentVel = ball.AssemblyLinearVelocity
    local speed = currentVel.Magnitude

    if speed < 1 then
        speed = (ballPos - lastBallPosition).Magnitude / math.max(deltaTime, 0.001)
    end
    lastBallPosition = ballPos

    local isTarget = isTargetingMe(ball)

    -- 1. Auto Spam Logic (Close Range Duel)
    if Config.AutoSpam and isTarget and distance <= Config.SpamDistance then
        fireParry()
        return
    end

    -- 2. Precision Auto Parry Logic
    if Config.AutoParry and isTarget then
        local ping = Config.PingCompensation and getNetworkPing() or 0
        local dirToPlayer = (hrpPos - ballPos).Unit
        local dotVelocity = currentVel:Dot(dirToPlayer)

        -- If ball is moving away from player, do not parry
        if dotVelocity < -5 then return end

        local effectiveSpeed = math.max(dotVelocity, speed, 1)

        -- Dynamic Parry Distance Equation with Ping & Curve Compensation
        -- Required Distance = (Speed * (Ping + ReactionTime)) + Offset
        local pingDistanceCompensation = (effectiveSpeed * (ping + 0.04))
        local curveCompensation = Config.CurvePrediction and (speed * 0.08) or 0
        local triggerDistance = pingDistanceCompensation + curveCompensation + Config.ParryOffset + 12

        -- Time to Impact Calculation (in seconds)
        local timeToImpact = (distance - Config.ParryOffset) / effectiveSpeed

        -- Check Ability Cooldowns
        local uigrad1, uigrad2 = getUIGradients()

        if distance <= triggerDistance or timeToImpact <= (ping + 0.14) then
            local hasRage = character:FindFirstChild("Abilities") and (character.Abilities:FindFirstChild("Raging Deflection") or character.Abilities:FindFirstChild("Rapture"))

            if hasRage and Config.UseAbility then
                if uigrad2 and not isCooldownInEffect(uigrad2) then
                    fireAbility()
                elseif not uigrad1 or not isCooldownInEffect(uigrad1) then
                    fireParry()
                end
            else
                if not uigrad1 or not isCooldownInEffect(uigrad1) then
                    fireParry()
                end
            end
        end

        -- Update Visualizer Position
        if Config.AutoParry then
            if not distanceVisualizer or not distanceVisualizer.Parent then
                distanceVisualizer = Instance.new("Part")
                distanceVisualizer.Name = "ParryImpactVisualizer"
                distanceVisualizer.Size = Vector3.new(1.5, 1.5, 1.5)
                distanceVisualizer.Shape = Enum.PartType.Ball
                distanceVisualizer.Color = Color3.fromRGB(0, 255, 150)
                distanceVisualizer.Material = Enum.Material.Neon
                distanceVisualizer.Anchored = true
                distanceVisualizer.CanCollide = false
                distanceVisualizer.Parent = Workspace
            end
            local predictedPos = ballPos + (currentVel * math.clamp(timeToImpact, 0, 1.5))
            distanceVisualizer.Position = predictedPos
        end
    elseif distanceVisualizer then
        distanceVisualizer:Destroy()
        distanceVisualizer = nil
    end
end)


-- --------------------------------------------------------------------
-- UI CONTROLS & BINDINGS
-- --------------------------------------------------------------------

-- TAB 1: AUTO PARRY
parryTab:CreateToggleSwitch("Enable Sub-Frame Auto Parry", true, function(val)
    Config.AutoParry = val
    if val then
        lib:Notify("Auto Parry", "Ultra-Precision Engine Active!", 1.5)
    else
        lib:Notify("Auto Parry", "Auto Parry Disabled", 1.5)
    end
end)

parryTab:CreateToggleSwitch("Enable Curve Ball Prediction", true, function(val)
    Config.CurvePrediction = val
end)

parryTab:CreateToggleSwitch("Enable Ping Compensation", true, function(val)
    Config.PingCompensation = val
end)

parryTab:CreateToggleSwitch("Auto Rage / Rapture Ability Parry", false, function(val)
    Config.UseAbility = val
end)

parryTab:CreateSlider("Parry Distance Offset", 0, 50, 5, function(val)
    Config.ParryOffset = val
end)

parryTab:CreateToggleSwitch("Notify When Parried", false, function(val)
    Config.NotifyParried = val
end)


-- TAB 2: SPAM PARRY
spamTab:CreateToggleSwitch("Enable Auto Spam Parry", false, function(val)
    Config.AutoSpam = val
    if val then
        lib:Notify("Auto Spam", "Auto Spam Active!", 1.5)
    else
        lib:Notify("Auto Spam", "Auto Spam Disabled", 1.5)
    end
end)

spamTab:CreateSlider("Auto Spam Distance (Studs)", 2, 30, 8, function(val)
    Config.SpamDistance = val
end)

spamTab:CreateKeybind("Spam Parry Manual (Keybind C)", Enum.KeyCode.C, function()
    fireParry()
end)

spamTab:CreateKeybind("+5 Range (Keybind X)", Enum.KeyCode.X, function()
    Config.ParryOffset = math.min(Config.ParryOffset + 5, 50)
    lib:Notify("Range Increased", "New Offset: " .. Config.ParryOffset, 1)
end)

spamTab:CreateKeybind("-5 Range (Keybind Z)", Enum.KeyCode.Z, function()
    Config.ParryOffset = math.max(Config.ParryOffset - 5, 0)
    lib:Notify("Range Decreased", "New Offset: " .. Config.ParryOffset, 1)
end)


-- TAB 3: AUTO CHAT
chatTab:CreateToggleSwitch("Auto GG on Match End", false, function(val)
    Config.AutoGG = val
end)

chatTab:CreateToggleSwitch("Auto Chat Response on Accusation", false, function(val)
    Config.AutoResponse = val
end)

-- Auto GG Listener
local aliveFolder = Workspace:FindFirstChild("Alive")
if aliveFolder then
    aliveFolder.ChildRemoved:Connect(function()
        if Config.AutoGG and #aliveFolder:GetChildren() <= 1 and not ggdebounce then
            ggdebounce = true
            local choice = gameEndResponses[math.random(1, #gameEndResponses)]
            task.wait(math.random(2, 3.5))
            pcall(function()
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(choice, "All")
            end)
            task.wait(2)
            ggdebounce = false
        end
    end)
end

-- Auto Response Listener
pcall(function()
    Players.PlayerChatted:Connect(function(chatType, player, message)
        if Config.AutoResponse and player ~= LocalPlayer and not responsedebounce then
            for _, kw in ipairs(keywords) do
                if string.find(message:lower(), kw) then
                    responsedebounce = true
                    local choice = responses[math.random(1, #responses)]
                    task.wait(math.random(1.5, 3))
                    pcall(function()
                        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(choice, "All")
                    end)
                    task.wait(2)
                    responsedebounce = false
                    break
                end
            end
        end
    end)
end)


-- TAB 4: SETTINGS & THEMES
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)

local themesList = {"royal", "cyber", "emerald", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
        lib:Notify("UI Theme", "Theme changed to " .. themeName:upper(), 1.5)
    end)
end

settingsTab:CreateSlider("Glass Window Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

print("[Blade Ball Suite] Sub-Frame Ultra Precision Parry Engine Active!")
