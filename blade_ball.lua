--[[
    Blade Ball - ALL-SYSTEMS RACE Auto Parry Engine (blade_ball.lua)
    Powered by Custom UI Library (lib.lua)
    
    ALL detection systems run SIMULTANEOUSLY in parallel.
    The FIRST system that detects = fires the parry.
    After one fires, ALL systems are locked out until next ball/round.
    
    PARALLEL SYSTEMS:
      1. RunService.Heartbeat        (post-physics, accurate positions)
      2. RunService.RenderStepped    (pre-render, earliest frame)
      3. RunService.Stepped          (pre-physics simulation)
      4. Ball.Touched                (instant physical contact)
      5. Ball.Changed (CFrame)       (instant position change detection)
      6. Ball AttributeChanged       (target switch instant reaction)
      7. Predictive Trajectory       (future frame collision check)
      8. while-loop coroutine        (independent 0ms polling)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
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

local int = lib:CreateInterface("Blade Ball Suite", "All-Systems Race Parry Engine", "https://discord.gg/ZNTHTWx7KE", "bottom left", "royal", 0.25)

local parryTab = int:CreateTab("Auto Parry", "8-System Parallel Detection", "item", true)
local spamTab = int:CreateTab("Spam Parry", "Auto Spam & Close Combat", "op")
local chatTab = int:CreateTab("Auto Chat", "Auto GG & Chat Responses", "player")
local settingsTab = int:CreateTab("UI Settings", "Themes & Customization", "misc")

-- ====================================================================
-- CONFIGURATION
-- ====================================================================
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
}

local responses = {"lol what", "??", "wdym", "bru what", "mad cuz bad", "skill issue", "cry"}
local gameEndResponses = {"ggs", "gg :3", "good game", "ggs yall", "wp", "ggs man"}
local keywords = {"auto parry", "auto", "cheating", "hacking"}
local ggdebounce = false
local responsedebounce = false

-- ====================================================================
-- ATOMIC PARRY LOCK (First system wins, all others blocked)
-- ====================================================================
local PARRY_LOCKED = false      -- true = a system already fired this round
local LOCK_TICK = 0             -- tick() when lock was set
local LOCK_COOLDOWN = 0.35      -- seconds before lock auto-resets (safety)
local WINNER_SYSTEM = ""        -- which system won the race

local function resetLock()
    PARRY_LOCKED = false
    LOCK_TICK = 0
    WINNER_SYSTEM = ""
end

-- Auto-reset lock after cooldown (safety valve)
local function checkLockExpiry()
    if PARRY_LOCKED and (tick() - LOCK_TICK) > LOCK_COOLDOWN then
        resetLock()
    end
end

-- ====================================================================
-- BALL TRACKING STATE
-- ====================================================================
local trackedBall = nil
local posHistory = {}           -- {pos, t} ring buffer size 8
local histIdx = 0
local connections = {}          -- all event connections for cleanup
local distanceVisualizer = nil

-- Character reference
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
LocalPlayer.CharacterAdded:Connect(function(c)
    character = c
    resetLock()
end)

-- Workspace references
local ballsFolder = Workspace:WaitForChild("Balls")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local parryRemote = remotesFolder:FindFirstChild("ParryButtonPress") or remotesFolder:FindFirstChild("ParryAttempt")
local abilityRemote = remotesFolder:FindFirstChild("AbilityButtonPress") or remotesFolder:FindFirstChild("UseAbility")

-- ====================================================================
-- UTILITY FUNCTIONS
-- ====================================================================

local function getBlockCooldown()
    local ok, r = pcall(function()
        return LocalPlayer.PlayerGui.Hotbar.Block.border1.UIGradient.Offset.Y < 0.5
    end)
    return ok and r or false
end

local function getAbilityCooldown()
    local ok, r = pcall(function()
        return LocalPlayer.PlayerGui.Hotbar.Ability.border2.UIGradient.Offset.Y < 0.5
    end)
    return ok and r or false
end

local function getNetworkPing()
    local ping = 0.05
    pcall(function()
        ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    return math.clamp(ping, 0.02, 0.40)
end

-- ====================================================================
-- TRIPLE-METHOD PARRY FIRE
-- ====================================================================
local function fireParry()
    -- Method 1: Remote
    pcall(function()
        if parryRemote then
            if parryRemote:IsA("BindableEvent") then
                parryRemote:Fire()
            elseif parryRemote:IsA("RemoteEvent") then
                local cam = Workspace.CurrentCamera
                if cam then
                    parryRemote:FireServer(0.5, cam.CFrame, {}, {Vector2.new(0, 0)})
                end
            end
        end
    end)

    -- Method 2: VirtualInputManager
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyPressEvent(Enum.KeyCode.F, true, game)
        task.defer(function()
            pcall(function()
                vim:SendKeyPressEvent(Enum.KeyCode.F, false, game)
            end)
        end)
    end)

    -- Method 3: firesignal
    pcall(function()
        if type(firesignal) == "function" then
            local blockBtn = LocalPlayer.PlayerGui.Hotbar.Block
            if blockBtn and blockBtn.Activated then
                firesignal(blockBtn.Activated)
            end
        end
    end)
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
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyPressEvent(Enum.KeyCode.Q, true, game)
        task.defer(function()
            pcall(function() vim:SendKeyPressEvent(Enum.KeyCode.Q, false, game) end)
        end)
    end)
end

-- ====================================================================
-- ATOMIC PARRY ATTEMPT (Only the FIRST caller wins)
-- ====================================================================
local function attemptParry(systemName)
    checkLockExpiry()
    if PARRY_LOCKED then return false end -- Another system already fired
    if not Config.AutoParry and not Config.AutoSpam then return false end
    if getBlockCooldown() then return false end

    -- LOCK IT - this system wins the race
    PARRY_LOCKED = true
    LOCK_TICK = tick()
    WINNER_SYSTEM = systemName

    -- Check ability first
    local hasRage = character and character:FindFirstChild("Abilities") and
        (character.Abilities:FindFirstChild("Raging Deflection") or character.Abilities:FindFirstChild("Rapture"))

    if hasRage and Config.UseAbility and not getAbilityCooldown() then
        fireAbility()
    else
        fireParry()
    end

    if Config.NotifyParried then
        lib:Notify("Auto Parry", "Parried! [" .. systemName .. "]", 0.4)
    end

    return true
end

-- ====================================================================
-- BALL TRACKING
-- ====================================================================

local function findActiveBall()
    for _, b in ipairs(ballsFolder:GetChildren()) do
        if b:IsA("BasePart") and b:GetAttribute("target") == LocalPlayer.Name then return b end
    end
    for _, b in ipairs(ballsFolder:GetChildren()) do
        if b:IsA("BasePart") and b:GetAttribute("realBall") == true then return b end
    end
    for _, b in ipairs(ballsFolder:GetChildren()) do
        if b:IsA("BasePart") and b.BrickColor == BrickColor.new("Really red") then return b end
    end
    for _, b in ipairs(ballsFolder:GetChildren()) do
        if b:IsA("BasePart") then return b end
    end
    return nil
end

local function isTargetingMe(ball)
    if not ball then return false end
    if ball:GetAttribute("target") == LocalPlayer.Name then return true end
    if ball.BrickColor == BrickColor.new("Really red") then return true end
    return false
end

local function recordPos(ball)
    histIdx = (histIdx % 8) + 1
    posHistory[histIdx] = { pos = ball.Position, t = tick() }
end

local function getRealVelocity(ball)
    local pv = ball.AssemblyLinearVelocity
    if pv.Magnitude > 5 then return pv end
    -- Compute from position history
    if #posHistory >= 2 then
        local a = posHistory[((histIdx - 1) % math.max(#posHistory, 1)) + 1]
        local b = posHistory[((histIdx - 2) % math.max(#posHistory, 1)) + 1]
        if a and b and (a.t - b.t) > 0.001 then
            return (a.pos - b.pos) / (a.t - b.t)
        end
    end
    return pv
end

-- Cleanup old connections
local function cleanupConnections()
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
end

-- ====================================================================
-- SHOULD-PARRY CHECK (shared logic for all systems)
-- ====================================================================
local function shouldParry(ball, systemName)
    if not ball or not ball.Parent then return false end
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    if not isTargetingMe(ball) then return false end

    local hrpPos = character.HumanoidRootPart.Position
    local ballPos = ball.Position
    local distance = (ballPos - hrpPos).Magnitude
    local realVel = getRealVelocity(ball)
    local speed = realVel.Magnitude

    local dirToPlayer = (hrpPos - ballPos)
    local dirUnit = dirToPlayer.Magnitude > 0.1 and dirToPlayer.Unit or Vector3.zero
    local approachSpeed = realVel:Dot(dirUnit)

    -- Ball moving away and far = skip
    if approachSpeed < 0 and distance > 25 then return false end

    local ping = Config.PingCompensation and getNetworkPing() or 0

    -- ZONE A: EMERGENCY (< 15 studs, ball near us)
    if distance < 15 then
        return true
    end

    -- ZONE B: AUTO SPAM (within spam distance)
    if Config.AutoSpam and distance <= Config.SpamDistance then
        return true
    end

    -- ZONE C: TIME-TO-IMPACT PRECISION
    if approachSpeed > 1 then
        local tti = (distance - Config.ParryOffset) / approachSpeed
        local window = ping + 0.02

        if Config.CurvePrediction then
            local lateral = (realVel - (dirUnit * approachSpeed)).Magnitude
            if lateral > 15 then
                window = window + (lateral * 0.003)
            end
        end

        if tti <= window and tti >= -0.15 then
            return true
        end
    end

    -- ZONE D: SPEED-SCALED DISTANCE
    if speed > 10 then
        local triggerDist = Config.ParryOffset + (speed * (ping + 0.04)) + 6
        if Config.CurvePrediction then
            triggerDist = triggerDist + (speed * 0.03)
        end
        if distance <= triggerDist and approachSpeed > 0 then
            return true
        end
    end

    -- ZONE E: PREDICTIVE NEXT-FRAME
    if speed > 25 then
        local futurePos = ballPos + (realVel * 0.032) -- ~2 frames ahead
        local futureDist = (futurePos - hrpPos).Magnitude
        if futureDist < distance and futureDist < (Config.ParryOffset + 16) then
            return true
        end
    end

    return false
end

-- ====================================================================
-- SETUP ALL BALL EVENT CONNECTIONS
-- ====================================================================
local function setupBallWatchers(ball)
    cleanupConnections()
    if not ball then return end

    -- SYSTEM 4: Ball.Touched (instant physical contact)
    table.insert(connections, ball.Touched:Connect(function(hit)
        if not Config.AutoParry then return end
        if hit and character and hit:IsDescendantOf(character) then
            attemptParry("Touched")
        end
    end))

    -- SYSTEM 5: Ball CFrame/Position Changed (instant movement detection)
    pcall(function()
        table.insert(connections, ball:GetPropertyChangedSignal("CFrame"):Connect(function()
            if not Config.AutoParry then return end
            if PARRY_LOCKED then return end
            if shouldParry(ball, "CFrameChanged") then
                attemptParry("CFrameChanged")
            end
        end))
    end)

    -- SYSTEM 6: Ball AttributeChanged "target" (instant target switch)
    pcall(function()
        table.insert(connections, ball:GetAttributeChangedSignal("target"):Connect(function()
            if ball:GetAttribute("target") == LocalPlayer.Name then
                resetLock() -- New target = reset lock for fresh detection
                posHistory = {}
                histIdx = 0
            end
        end))
    end)
end

-- Track ball changes
local function updateTrackedBall()
    local ball = findActiveBall()
    if ball ~= trackedBall then
        trackedBall = ball
        posHistory = {}
        histIdx = 0
        resetLock()
        setupBallWatchers(ball)
    end
    return ball
end

-- ====================================================================
-- SYSTEM 1: HEARTBEAT (post-physics, most accurate ball positions)
-- ====================================================================
RunService.Heartbeat:Connect(function()
    if not Config.AutoParry and not Config.AutoSpam then return end

    local ball = updateTrackedBall()
    if not ball or not ball.Parent then return end

    recordPos(ball)
    checkLockExpiry()

    if PARRY_LOCKED then return end
    if shouldParry(ball, "Heartbeat") then
        attemptParry("Heartbeat")
    end
end)

-- ====================================================================
-- SYSTEM 2: RENDERSTEPPED (pre-render, earliest possible frame)
-- ====================================================================
RunService.RenderStepped:Connect(function()
    if not Config.AutoParry and not Config.AutoSpam then return end
    if PARRY_LOCKED then return end

    local ball = trackedBall
    if not ball or not ball.Parent then return end

    if shouldParry(ball, "RenderStepped") then
        attemptParry("RenderStepped")
    end

    -- Visualizer update
    pcall(function()
        if not Config.AutoParry then return end
        local hrpPos = character.HumanoidRootPart.Position
        local ballPos = ball.Position
        local dist = (ballPos - hrpPos).Magnitude

        if dist < 120 and isTargetingMe(ball) then
            if not distanceVisualizer or not distanceVisualizer.Parent then
                local v = Instance.new("Part")
                v.Name = "ParryVis"
                v.Size = Vector3.new(1.2, 1.2, 1.2)
                v.Shape = Enum.PartType.Ball
                v.Color = Color3.fromRGB(0, 255, 120)
                v.Material = Enum.Material.Neon
                v.Anchored = true
                v.CanCollide = false
                v.Parent = Workspace
                distanceVisualizer = v
            end
            local vel = getRealVelocity(ball)
            local spd = math.max(vel:Dot((hrpPos - ballPos).Unit), 1)
            distanceVisualizer.Position = ballPos + (vel * math.clamp(dist / spd, 0, 1.5))
        elseif distanceVisualizer then
            distanceVisualizer:Destroy()
            distanceVisualizer = nil
        end
    end)
end)

-- ====================================================================
-- SYSTEM 3: STEPPED (pre-physics simulation step)
-- ====================================================================
RunService.Stepped:Connect(function()
    if not Config.AutoParry and not Config.AutoSpam then return end
    if PARRY_LOCKED then return end

    local ball = trackedBall
    if not ball or not ball.Parent then return end

    if shouldParry(ball, "Stepped") then
        attemptParry("Stepped")
    end
end)

-- ====================================================================
-- SYSTEM 7: PREDICTIVE TRAJECTORY (extra coroutine check)
-- ====================================================================
-- Runs inside its own fast coroutine polling at ~120Hz
task.spawn(function()
    while true do
        task.wait(0.008) -- ~120 checks/sec independent of framerate

        if not Config.AutoParry and not Config.AutoSpam then continue end
        if PARRY_LOCKED then
            checkLockExpiry()
            continue
        end

        local ball = trackedBall
        if not ball or not ball.Parent then continue end
        if not character or not character:FindFirstChild("HumanoidRootPart") then continue end
        if not isTargetingMe(ball) then continue end

        local hrpPos = character.HumanoidRootPart.Position
        local ballPos = ball.Position
        local dist = (ballPos - hrpPos).Magnitude
        local vel = getRealVelocity(ball)
        local speed = vel.Magnitude

        if speed > 20 and dist < 50 then
            -- Check 3 future frames
            for i = 1, 3 do
                local futurePos = ballPos + (vel * (0.016 * i))
                local futureDist = (futurePos - hrpPos).Magnitude
                if futureDist < (Config.ParryOffset + 14) then
                    attemptParry("Predictive")
                    break
                end
            end
        end
    end
end)

-- ====================================================================
-- SYSTEM 8: INDEPENDENT WHILE-LOOP COROUTINE (0ms polling backup)
-- ====================================================================
task.spawn(function()
    while true do
        task.wait() -- yield once per frame minimum

        if not Config.AutoParry and not Config.AutoSpam then continue end
        if PARRY_LOCKED then continue end

        local ball = trackedBall
        if not ball or not ball.Parent then continue end

        if shouldParry(ball, "Coroutine") then
            attemptParry("Coroutine")
        end
    end
end)

-- ====================================================================
-- BALL FOLDER WATCHER (auto-detect new/removed balls)
-- ====================================================================
ballsFolder.ChildAdded:Connect(function(ball)
    if ball:IsA("BasePart") then
        task.wait(0.03)
        updateTrackedBall()
    end
end)

ballsFolder.ChildRemoved:Connect(function()
    resetLock()
    updateTrackedBall()
end)


-- ====================================================================
-- UI CONTROLS
-- ====================================================================

-- TAB 1: AUTO PARRY
parryTab:CreateToggleSwitch("Enable 8-System Auto Parry", true, function(val)
    Config.AutoParry = val
    if val then
        lib:Notify("Auto Parry", "8-System Race Engine Active!", 1.5)
    else
        lib:Notify("Auto Parry", "Auto Parry Disabled", 1.5)
        if distanceVisualizer then
            distanceVisualizer:Destroy()
            distanceVisualizer = nil
        end
    end
end)

parryTab:CreateToggleSwitch("Curve Ball Prediction", true, function(val)
    Config.CurvePrediction = val
end)

parryTab:CreateToggleSwitch("Ping Compensation", true, function(val)
    Config.PingCompensation = val
end)

parryTab:CreateToggleSwitch("Auto Rage / Rapture Ability", false, function(val)
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
        lib:Notify("Auto Spam", "Spam Active!", 1.5)
    else
        lib:Notify("Auto Spam", "Spam Disabled", 1.5)
    end
end)

spamTab:CreateSlider("Spam Distance (Studs)", 2, 30, 8, function(val)
    Config.SpamDistance = val
end)

spamTab:CreateKeybind("Manual Spam (C)", Enum.KeyCode.C, function()
    fireParry()
end)

spamTab:CreateKeybind("+5 Range (X)", Enum.KeyCode.X, function()
    Config.ParryOffset = math.min(Config.ParryOffset + 5, 50)
    lib:Notify("Range", "Offset: " .. Config.ParryOffset, 0.8)
end)

spamTab:CreateKeybind("-5 Range (Z)", Enum.KeyCode.Z, function()
    Config.ParryOffset = math.max(Config.ParryOffset - 5, 0)
    lib:Notify("Range", "Offset: " .. Config.ParryOffset, 0.8)
end)


-- TAB 3: AUTO CHAT
chatTab:CreateToggleSwitch("Auto GG", false, function(val)
    Config.AutoGG = val
end)

chatTab:CreateToggleSwitch("Auto Chat Response", false, function(val)
    Config.AutoResponse = val
end)

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


-- TAB 4: SETTINGS
local themeDrop = settingsTab:CreateDropDown("UI Theme", function() end)
for _, t in ipairs({"royal", "cyber", "emerald", "dark", "midnight", "blood", "gold", "neon"}) do
    themeDrop:AddButton(t:upper(), function()
        int:SetTheme(t)
        lib:Notify("Theme", t:upper(), 1)
    end)
end

settingsTab:CreateSlider("Glass Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

print("[Blade Ball] 8-System All-Race Parry Engine Active!")
print("[Blade Ball] Systems: Heartbeat | RenderStepped | Stepped | Touched | CFrame | AttrWatch | Predictive | Coroutine")
print("[Blade Ball] Rule: FIRST system to detect = fires parry, all others locked out")
