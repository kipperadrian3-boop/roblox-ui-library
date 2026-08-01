--[[
    Blade Ball - Inferno Ultra Auto Parry & Auto Spam Engine (blade_ball.lua)
    PreSimulation Physics Execution, Zoomies Velocity, getconnections UI Trigger & 7-Stud Auto Spam
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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

local int = lib:CreateInterface("Blade Ball Suite", "PreSimulation Parry & Auto Spam Engine", "https://discord.gg/ZNTHTWx7KE", "bottom left", "royal", 0.25)

local parryTab = int:CreateTab("Auto Parry", "PreSimulation Target Deflect", "item", true)
local spamTab = int:CreateTab("Auto Spam", "7-Stud Close Proximity Clash", "op")
local chatTab = int:CreateTab("Auto Chat", "Auto GG & Chat Responses", "player")
local visualTab = int:CreateTab("Visuals", "Ball Highlighter & Info", "visuals")
local settingsTab = int:CreateTab("UI Settings", "Themes, Transparency & Controls", "misc")

-- Configuration State
local Config = {
    AutoParry = true,
    ParryThreshold = 0.55,
    AutoSpam = false,
    SpamDistance = 7, -- Default 7 studs
    AutoGG = false,
    AutoResponse = false,
    BallHighlight = true
}

local Parried = false
local Connection = nil
local focusedBall = nil

-- Remotes & Chat Setup
local responses = {"lol what", "??", "wdym", "bru what", "mad cuz bad", "skill issue", "cry"}
local gameEndResponses = {"ggs", "gg :3", "good game", "ggs yall", "wp", "ggs man"}
local keywords = {"auto parry", "auto", "cheating", "hacking"}
local ggdebounce = false
local responsedebounce = false

-- Get Active Ball with "realBall" Attribute
local function getBall()
    local ballsFolder = Workspace:FindFirstChild("Balls")
    if ballsFolder then
        for _, ball in ipairs(ballsFolder:GetChildren()) do
            if ball:GetAttribute("realBall") == true then
                return ball
            end
        end
        for _, ball in ipairs(ballsFolder:GetChildren()) do
            if ball:GetAttribute("target") ~= nil then
                return ball
            end
        end
    end
    return nil
end

-- Reset Ball Target Changed Connection
local function resetConnection()
    if Connection then
        Connection:Disconnect()
        Connection = nil
    end
end

-- Fire Block Button Connections (getconnections & firesignal fallback)
local function triggerBlock()
    local blockSuccess = false

    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local hotbar = playerGui and playerGui:FindFirstChild("Hotbar")
        local blockButton = hotbar and hotbar:FindFirstChild("Block")

        if blockButton then
            if type(getconnections) == "function" then
                if blockButton:FindFirstChild("Activated") then
                    for _, conn in pairs(getconnections(blockButton.Activated)) do
                        conn:Fire()
                        blockSuccess = true
                    end
                end
                if blockButton:FindFirstChild("MouseButton1Click") then
                    for _, conn in pairs(getconnections(blockButton.MouseButton1Click)) do
                        conn:Fire()
                        blockSuccess = true
                    end
                end
                if blockButton:FindFirstChild("MouseButton1Down") then
                    for _, conn in pairs(getconnections(blockButton.MouseButton1Down)) do
                        conn:Fire()
                        blockSuccess = true
                    end
                end
            end

            if not blockSuccess and type(firesignal) == "function" then
                if blockButton:FindFirstChild("MouseButton1Click") then
                    firesignal(blockButton.MouseButton1Click)
                    blockSuccess = true
                elseif blockButton:FindFirstChild("Activated") then
                    firesignal(blockButton.Activated)
                    blockSuccess = true
                end
            end
        end
    end)

    -- RemoteEvent & Keypress Fallback if UI connections fail
    if not blockSuccess then
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local parryRemote = remotes and remotes:FindFirstChild("ParryButtonPress") or ReplicatedStorage:FindFirstChild("ParryButtonPress", true)
            if parryRemote and parryRemote:IsA("RemoteEvent") then
                local camera = Workspace.CurrentCamera
                parryRemote:FireServer(0.5, camera and camera.CFrame or CFrame.new(), {}, {Vector2.new(0, 0)})
            end
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, true, game)
            task.wait(0.005)
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, false, game)
        end)
    end
end

-- Monitor New Balls in Workspace
local ballsFolder = Workspace:WaitForChild("Balls")
ballsFolder.ChildAdded:Connect(function()
    local ball = getBall()
    if not ball then return end
    resetConnection()
    Connection = ball:GetAttributeChangedSignal("target"):Connect(function()
        Parried = false
    end)
end)

-- --------------------------------------------------------------------
-- 1. PRESIMULATION AUTO PARRY & AUTO SPAM ENGINE
-- --------------------------------------------------------------------
RunService.PreSimulation:Connect(function()
    local ball = getBall()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not ball or not hrp then return end

    -- Extract Speed from ball.zoomies or AssemblyLinearVelocity
    local speed = 0
    if ball:FindFirstChild("zoomies") and ball.zoomies:IsA("VectorVelocity") then
        speed = ball.zoomies.VectorVelocity.Magnitude
    elseif ball:IsA("BasePart") then
        speed = ball.AssemblyLinearVelocity.Magnitude
    end
    speed = math.max(speed, 1)

    local distance = (hrp.Position - ball.Position).Magnitude
    local isTargetingMe = (ball:GetAttribute("target") == LocalPlayer.Name)

    -- AUTO SPAM PARRY LOGIC:
    -- When AutoSpam is ON, ball targets us AND ball is within SpamDistance (default 7 studs), spam parry every frame!
    if Config.AutoSpam and isTargetingMe and distance <= Config.SpamDistance then
        triggerBlock()
        return
    end

    -- AUTO PARRY LOGIC:
    -- When AutoParry is ON, ball targets us, not parried yet, and Distance / Speed <= ParryThreshold (0.55)
    if Config.AutoParry and isTargetingMe and not Parried and (distance / speed) <= Config.ParryThreshold then
        triggerBlock()
        Parried = true
        task.spawn(function()
            task.wait(0.5)
            Parried = false
        end)
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: AUTO PARRY CONTROLS
-- --------------------------------------------------------------------
parryTab:CreateToggleSwitch("Enable PreSimulation Auto Parry", true, function(val)
    Config.AutoParry = val
    if val then
        lib:Notify("Auto Parry", "Auto Parry Engine Active!", 1.5)
    else
        lib:Notify("Auto Parry", "Auto Parry Disabled.", 1.5)
    end
end)

parryTab:CreateSlider("Time-To-Impact Threshold (ms)", 20, 100, 55, function(val)
    Config.ParryThreshold = val / 100
end)


-- --------------------------------------------------------------------
-- UI TAB 2: AUTO SPAM PARRY CONTROLS
-- --------------------------------------------------------------------
spamTab:CreateToggleSwitch("Enable 7-Stud Auto Spam Parry", false, function(val)
    Config.AutoSpam = val
    if val then
        lib:Notify("Auto Spam", "Auto Spam Parry Active (" .. Config.SpamDistance .. " Studs)!", 1.5)
    else
        lib:Notify("Auto Spam", "Auto Spam Parry Disabled.", 1.5)
    end
end)

spamTab:CreateSlider("Spam Parry Distance (Studs)", 5, 30, 7, function(val)
    Config.SpamDistance = val
end)

spamTab:CreateKeybind("Manual Spam Parry (Hold C)", Enum.KeyCode.C, function()
    triggerBlock()
end)


-- --------------------------------------------------------------------
-- UI TAB 3: AUTO CHAT & AUTO GG
-- --------------------------------------------------------------------
chatTab:CreateToggleSwitch("Auto GG on Match End", false, function(val)
    Config.AutoGG = val
end)

chatTab:CreateToggleSwitch("Auto Chat Response on Accusation", false, function(val)
    Config.AutoResponse = val
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

-- Auto Response Event
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


-- --------------------------------------------------------------------
-- UI TAB 4: BALL HIGHLIGHT & VISUALS
-- --------------------------------------------------------------------
visualTab:CreateToggleSwitch("Highlight Ball Target", true, function(val)
    Config.BallHighlight = val
end)

task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.BallHighlight then
            pcall(function()
                local ball = getBall()
                if ball then
                    local highlight = ball:FindFirstChild("PreSimHighlight")
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "PreSimHighlight"
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


-- --------------------------------------------------------------------
-- UI TAB 5: UI SETTINGS & TRANSPARENCY
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

print("[Blade Ball PreSimulation Engine] Loaded Successfully!")
