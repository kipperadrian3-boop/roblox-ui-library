--[[
    Blade Ball - Inferno Precision Auto Parry Engine (blade_ball.lua)
    Powered by Custom UI Library (lib.lua) with Glassmorphism & Theme Switcher
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

local int = lib:CreateInterface("Blade Ball Suite", "Inferno Auto Parry Engine", "https://discord.gg/ZNTHTWx7KE", "bottom left", "royal", 0.25)

local parryTab = int:CreateTab("Auto Parry", "Physics Impact & Deflect Controls", "item", true)
local spamTab = int:CreateTab("Spam Parry", "Close Fighting & Keybind Spam", "op")
local chatTab = int:CreateTab("Auto Chat", "Auto GG & Chat Responses", "player")
local visualTab = int:CreateTab("Visuals", "Future Impact Visualizer", "visuals")
local settingsTab = int:CreateTab("UI Settings", "Themes, Transparency & Controls", "misc")

-- Exact Threshold & Formula Constants
local BASE_THRESHOLD = 0.2
local VELOCITY_SCALING_FACTOR_FAST = 0.050
local VELOCITY_SCALING_FACTOR_SLOW = 0.1
local IMMEDIATE_PARRY_DISTANCE = 15

local responses = {"lol what", "??", "wdym", "bru what", "mad cuz bad", "skill issue", "cry"}
local gameEndResponses = {"ggs", "gg :3", "good game", "ggs yall", "wp", "ggs man"}
local keywords = {"auto parry", "auto", "cheating", "hacking"}

-- State Variables
local focusedBall = nil
local distanceVisualizer = nil
local isRunning = false
local UseRage = false
local sliderValue = 20
local notifyparried = false
local AutoGG = false
local AutoResponse = false
local ggdebounce = false
local responsedebounce = false

-- Workspace & Remotes Setup
local ballsFolder = Workspace:WaitForChild("Balls")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local parryButtonPress = remotesFolder:WaitForChild("ParryButtonPress")
local abilityButtonPress = remotesFolder:WaitForChild("AbilityButtonPress")

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

LocalPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
end)

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

-- Fire Event (Supports both RemoteEvent and BindableEvent)
local function triggerParry()
    pcall(function()
        if parryButtonPress:IsA("BindableEvent") then
            parryButtonPress:Fire()
        elseif parryButtonPress:IsA("RemoteEvent") then
            local camera = Workspace.CurrentCamera
            local camCF = camera and camera.CFrame or CFrame.new()
            parryButtonPress:FireServer(0.5, camCF, {}, {Vector2.new(0, 0)})
        else
            parryButtonPress:Fire()
        end
    end)
end

local function triggerAbility()
    pcall(function()
        if abilityButtonPress:IsA("BindableEvent") then
            abilityButtonPress:Fire()
        elseif abilityButtonPress:IsA("RemoteEvent") then
            abilityButtonPress:FireServer()
        else
            abilityButtonPress:Fire()
        end
    end)
end

-- Focused Ball Selection
local function chooseNewFocusedBall()
    local balls = ballsFolder:GetChildren()
    for _, ball in ipairs(balls) do
        if ball:GetAttribute("realBall") == true or ball:GetAttribute("target") ~= nil then
            focusedBall = ball
            return focusedBall
        end
    end
    for _, ball in ipairs(balls) do
        if ball:IsA("Part") or ball:IsA("MeshPart") then
            focusedBall = ball
            return focusedBall
        end
    end
    focusedBall = nil
    return nil
end

-- Dynamic Threshold Formula
local function getDynamicThreshold(ballVelocityMagnitude)
    if ballVelocityMagnitude > 60 then
        return math.max(0.20, BASE_THRESHOLD - (ballVelocityMagnitude * VELOCITY_SCALING_FACTOR_FAST))
    else
        return math.min(0.01, BASE_THRESHOLD + (ballVelocityMagnitude * VELOCITY_SCALING_FACTOR_SLOW))
    end
end

-- Exact Time Until Impact Formula
local function timeUntilImpact(ballVelocity, distanceToPlayer, playerVelocity)
    if not character or not character:FindFirstChild("HumanoidRootPart") or not focusedBall then return math.huge end
    local directionToPlayer = (character.HumanoidRootPart.Position - focusedBall.Position).Unit
    local velocityTowardsPlayer = ballVelocity:Dot(directionToPlayer) - playerVelocity:Dot(directionToPlayer)
    
    if velocityTowardsPlayer <= 0 then
        return math.huge
    end
    
    return (distanceToPlayer - sliderValue) / velocityTowardsPlayer
end

-- Check if Ball is targeting LocalPlayer
local function checkIfTarget()
    for _, v in pairs(ballsFolder:GetChildren()) do
        if v:IsA("Part") or v:IsA("MeshPart") then
            if v.BrickColor == BrickColor.new("Really red") or v:GetAttribute("target") == LocalPlayer.Name then
                return true
            end
        end
    end
    return false
end

-- Distance Visualizer Part
local function updateDistanceVisualizer()
    local charPos = character and character.PrimaryPart and character.PrimaryPart.Position
    if charPos and focusedBall and focusedBall.Parent then
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

        local timeToImpactValue = timeUntilImpact(focusedBall.Velocity, (focusedBall.Position - charPos).Magnitude, character.PrimaryPart.Velocity)
        if timeToImpactValue ~= math.huge then
            local ballFuturePosition = focusedBall.Position + (focusedBall.Velocity * timeToImpactValue)
            distanceVisualizer.Position = ballFuturePosition
        end
    elseif distanceVisualizer then
        distanceVisualizer:Destroy()
        distanceVisualizer = nil
    end
end

-- Primary Check Loop
local function checkBallDistance()
    if not character or not character:FindFirstChild("HumanoidRootPart") or not checkIfTarget() then return end

    local charPos = character.PrimaryPart.Position
    local charVel = character.PrimaryPart.Velocity

    if focusedBall and not focusedBall.Parent then
        chooseNewFocusedBall()
    end
    if not focusedBall then
        chooseNewFocusedBall()
    end
    if not focusedBall then return end

    local ball = focusedBall
    local distanceToPlayer = (ball.Position - charPos).Magnitude
    local ballVelocityTowardsPlayer = ball.Velocity:Dot((charPos - ball.Position).Unit)
    
    if distanceToPlayer < IMMEDIATE_PARRY_DISTANCE then
        triggerParry()
        task.wait()
    end

    local uigrad1, uigrad2 = getUIGradients()

    if timeUntilImpact(ball.Velocity, distanceToPlayer, charVel) < getDynamicThreshold(ballVelocityTowardsPlayer) then
        local hasRage = character:FindFirstChild("Abilities") and (character.Abilities:FindFirstChild("Raging Deflection") or character.Abilities:FindFirstChild("Rapture"))
        
        if hasRage and UseRage == true then
            if uigrad2 and not isCooldownInEffect(uigrad2) then
                triggerAbility()
            end

            if uigrad2 and isCooldownInEffect(uigrad2) and uigrad1 and not isCooldownInEffect(uigrad1) then
                triggerParry()
                if notifyparried then
                    lib:Notify("Auto Parry", "Manually Parried Ball (Ability on CD)", 0.5)
                end
            end
        elseif not uigrad1 or not isCooldownInEffect(uigrad1) then
            triggerParry()
            if notifyparried then
                lib:Notify("Auto Parry", "Automatically Parried Ball!", 0.5)
            end
            task.wait(0.3)
        end
    end
end

-- Auto Parry Loop Coroutine
local function autoParryCoroutine()
    while isRunning do
        checkBallDistance()
        updateDistanceVisualizer()
        task.wait()
    end
end

local function startAutoParry()
    chooseNewFocusedBall()
    isRunning = true
    local co = coroutine.create(autoParryCoroutine)
    coroutine.resume(co)
end

local function stopAutoParry()
    isRunning = false
    if distanceVisualizer then
        distanceVisualizer:Destroy()
        distanceVisualizer = nil
    end
end


-- --------------------------------------------------------------------
-- UI TAB 1: AUTO PARRY CONTROLS
-- --------------------------------------------------------------------
parryTab:CreateToggleSwitch("Enable Precision Auto Parry", false, function(val)
    if val then
        startAutoParry()
        lib:Notify("Auto Parry", "Auto Parry Engine Active!", 1.5)
    else
        stopAutoParry()
        lib:Notify("Auto Parry", "Auto Parry Disabled.", 1.5)
    end
end)

parryTab:CreateToggleSwitch("Auto Rage / Rapture Ability Parry", false, function(val)
    UseRage = val
    if val and not isRunning then
        startAutoParry()
    end
end)

parryTab:CreateSlider("Parry Distance Offset", 0, 100, 20, function(val)
    sliderValue = val
end)

parryTab:CreateToggleSwitch("Notify When Parried", false, function(val)
    notifyparried = val
end)


-- --------------------------------------------------------------------
-- UI TAB 2: SPAM PARRY & KEYBINDS
-- --------------------------------------------------------------------
spamTab:CreateKeybind("Spam Parry (Keybind C)", Enum.KeyCode.C, function()
    triggerParry()
end)

spamTab:CreateKeybind("+10 Range (Keybind X)", Enum.KeyCode.X, function()
    if sliderValue < 200 then
        sliderValue = sliderValue + 10
        lib:Notify("Range Increased", "New Range: " .. sliderValue, 1)
    end
end)

spamTab:CreateKeybind("-10 Range (Keybind Z)", Enum.KeyCode.Z, function()
    if sliderValue > 0 then
        sliderValue = sliderValue - 10
        lib:Notify("Range Decreased", "New Range: " .. sliderValue, 1)
    end
end)

spamTab:CreateKeybind("Set Distance to 30 (Keybind V)", Enum.KeyCode.V, function()
    sliderValue = 30
    lib:Notify("Range Set", "New Range: 30", 1)
end)

spamTab:CreateKeybind("Set Distance to 100 (Keybind B)", Enum.KeyCode.B, function()
    sliderValue = 100
    lib:Notify("Range Set", "New Range: 100", 1)
end)


-- --------------------------------------------------------------------
-- UI TAB 3: AUTO CHAT & AUTO GG
-- --------------------------------------------------------------------
chatTab:CreateToggleSwitch("Auto GG on Match End", false, function(val)
    AutoGG = val
end)

chatTab:CreateToggleSwitch("Auto Chat Response on Accusation", false, function(val)
    AutoResponse = val
end)

chatTab:CreateTextbox("Custom GG Message", "ggs yall", "ggs", function(text)
    if text and text ~= "" then
        table.insert(gameEndResponses, text)
        lib:Notify("Chat Customizer", "Added GG response: " .. text, 1.5)
    end
end)

-- Auto GG Event
local aliveFolder = Workspace:FindFirstChild("Alive")
if aliveFolder then
    aliveFolder.ChildRemoved:Connect(function()
        if AutoGG and #aliveFolder:GetChildren() <= 1 and not ggdebounce then
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

-- Auto Response Event
pcall(function()
    Players.PlayerChatted:Connect(function(chatType, player, message)
        if AutoResponse and player ~= LocalPlayer and not responsedebounce then
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


-- --------------------------------------------------------------------
-- UI TAB 4: UI SETTINGS & GLASS TRANSPARENCY
-- --------------------------------------------------------------------
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

print("[Blade Ball Suite] Fully powered by Custom Glassmorphic UI Library (lib.lua)!")
