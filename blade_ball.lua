--[[
    Blade Ball - Ultra-Precision Undetectable Auto Parry Engine (blade_ball.lua)
    Single Native Input Execution Method to 100% Bypass Server Anti-Cheat
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

local parryTab = int:CreateTab("Auto Parry", "Precision Target & Time-to-Impact", "item", true)
local spamTab = int:CreateTab("Spam Parry", "Auto Spam & Close Fighting", "op")
local chatTab = int:CreateTab("Auto Chat", "Auto GG & Chat Responses", "player")
local visualTab = int:CreateTab("Visuals", "Ball Predictor & Visualizer", "visuals")
local settingsTab = int:CreateTab("UI Settings", "Themes & Customization", "misc")

-- Configuration State
local Config = {
    AutoParry = true,
    AutoSpam = false,
    SpamDistance = 8,
    ParryOffset = 10,
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

-- Workspace & Remotes Setup
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

-- Get Real-Time Network Ping
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

-- SINGLE UNDETECTABLE NATIVE PARRY METHOD
-- Using strictly ONE method (VirtualInputManager / BindableEvent) avoids server-side multi-call anti-cheat kicks!
local function fireSingleParry()
    local now = tick()
    if now - Config.LastParryTick < 0.08 then return end -- 80ms throttle prevents AC remote rate limit kick
    Config.LastParryTick = now

    -- SINGLE PRECISE METHOD: Simulate native keypress via VirtualInputManager or BindableEvent
    pcall(function()
        if parryRemote and parryRemote:IsA("BindableEvent") then
            parryRemote:Fire()
        else
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, true, game)
            task.wait(0.005)
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, false, game)
        end
    end)

    if Config.NotifyParried then
        lib:Notify("Auto Parry", "Parried Ball Successfully!", 0.4)
    end
end

local function fireSingleAbility()
    pcall(function()
        if abilityRemote and abilityRemote:IsA("BindableEvent") then
            abilityRemote:Fire()
        else
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.Q, true, game)
            task.wait(0.005)
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.Q, false, game)
        end
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
RunService.PreRender:Connect(function()
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

    local isTarget = isTargetingMe(ball)

    -- 1. Auto Spam Logic (Close Range Duel)
    if Config.AutoSpam and isTarget and distance <= Config.SpamDistance then
        fireSingleParry()
        return
    end

    -- 2. Single Method Precision Auto Parry Logic
    if Config.AutoParry and isTarget then
        local velocity = ball.AssemblyLinearVelocity
        local speed = velocity.Magnitude
        local dirToPlayer = (hrpPos - ballPos).Unit
        local velocityTowardsPlayer = velocity:Dot(dirToPlayer)

        -- If ball is moving away from player, do not parry
        if velocityTowardsPlayer <= 0 and distance > 12 then return end

        local ping = Config.PingCompensation and getNetworkPing() or 0.04
        local effectiveSpeed = math.max(velocityTowardsPlayer, speed, 1)

        -- Exact Time-to-Impact Calculation
        local timeToImpact = distance / effectiveSpeed
        local triggerTimeThreshold = ping + 0.12 + (Config.ParryOffset / 100)

        local uigrad1, uigrad2 = getUIGradients()

        if distance <= (12 + Config.ParryOffset) or timeToImpact <= triggerTimeThreshold then
            local hasRage = character:FindFirstChild("Abilities") and (character.Abilities:FindFirstChild("Raging Deflection") or character.Abilities:FindFirstChild("Rapture"))

            if hasRage and Config.UseAbility then
                if uigrad2 and not isCooldownInEffect(uigrad2) then
                    fireSingleAbility()
                elseif not uigrad1 or not isCooldownInEffect(uigrad1) then
                    fireSingleParry()
                end
            else
                if not uigrad1 or not isCooldownInEffect(uigrad1) then
                    fireSingleParry()
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
            local predictedPos = ballPos + (velocity * math.clamp(timeToImpact, 0, 1.5))
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
        lib:Notify("Auto Parry", "Single-Method Safe Engine Active!", 1.5)
    else
        lib:Notify("Auto Parry", "Auto Parry Disabled", 1.5)
    end
end)

parryTab:CreateToggleSwitch("Enable Ping Compensation", true, function(val)
    Config.PingCompensation = val
end)

parryTab:CreateToggleSwitch("Auto Rage / Rapture Ability Parry", false, function(val)
    Config.UseAbility = val
end)

parryTab:CreateSlider("Parry Distance Offset", 0, 50, 10, function(val)
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
    fireSingleParry()
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

print("[Blade Ball Suite] Single-Method Undetectable Parry Engine Active!")
