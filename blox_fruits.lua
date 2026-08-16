--[[
	Blox Fruits - Ultimate Auto Farm & Kill Aura Suite (blox_fruits.lua)
	Enhanced & Fixed Version:
	  - ⚡ Kill Aura & Hitbox Extender: Brings mob hitboxes directly into attack range so 15-stud distance hits every mob instantly!
	  - 🖱️ Mouse-Lock & Frame Freeze Fix: Removed VirtualUser mouse capture (No more cursor sticking or frame lag!)
	  - 📏 15 Studs Default Distance: Safe 15-stud farming distance prevents mobs from hitting/killing player.
	  - 📜 Quest-Strict Targeting: ONLY attacks mobs belonging to active quest.
	  - ⚔️ Seamless Weapon Selector: Fists/Melee, Blox Fruit, Sword & Gun.
	  - 💾 Universal JSON Auto-Save via lib.lua Framework.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with dynamic cache buster & JSON auto-save engine)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Blox Fruits Error] Could not load UI Library from GitHub!")
    return
end

-- Create Interface with Cyber Blue Theme
local int = lib:CreateInterface("Blox Fruits Suite", "Ultimate Level Farm & Kill Aura Engine", "", "bottom left", "cyber", 0.25)

-- Tabs
local farmTab = int:CreateTab("Auto Farm", "Level Farm, Quests & Kill Aura", "op", true)
local configTab = int:CreateTab("Farm Settings", "Tween Position & Weapon Selector", "item")
local moveTab = int:CreateTab("Movement & Fly", "Flight, WalkSpeed & Noclip", "player")
local settingsTab = int:CreateTab("Settings", "UI Customization & Config", "misc")

-- Configuration State
local Config = {
    AutoLevelFarm = false,
    WeaponMode = "Melee", -- "Melee", "Blox Fruit", "Sword", "Gun"
    TweenPositionMode = "Above", -- "Above", "Under", "Behind", "Front"
    TweenSpeed = 250,
    FarmDistanceOffset = 15, -- Default 15 studs distance
    KillAura = true,
    BringMobs = true,
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50
}

-- UI Status Label Reference
local currentFarmStatusLabel = nil

-- Remotes
local CommF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")

-- --------------------------------------------------------------------
-- 1. BLOX FRUITS QUEST & MOB DATA ENGINE
-- --------------------------------------------------------------------

local QuestData = {
    -- First Sea (Level 1 - 700)
    { MinLevel = 1, MaxLevel = 14, MobName = "Bandit", QuestName = "BanditQuest1", QuestLevel = 1, NpcCFrame = CFrame.new(1059, 17, 1546), MobCFrame = CFrame.new(1145, 17, 1634) },
    { MinLevel = 15, MaxLevel = 29, MobName = "Monkey", QuestName = "JungleQuest", QuestLevel = 1, NpcCFrame = CFrame.new(-1598, 37, 153), MobCFrame = CFrame.new(-1448, 50, 63) },
    { MinLevel = 30, MaxLevel = 39, MobName = "Gorilla", QuestName = "JungleQuest", QuestLevel = 2, NpcCFrame = CFrame.new(-1598, 37, 153), MobCFrame = CFrame.new(-1237, 6, -486) },
    { MinLevel = 40, MaxLevel = 59, MobName = "Pirate", QuestName = "BuggyQuest1", QuestLevel = 1, NpcCFrame = CFrame.new(-1141, 4, 3832), MobCFrame = CFrame.new(-1214, 4, 3922) },
    { MinLevel = 60, MaxLevel = 89, MobName = "Brute", QuestName = "BuggyQuest1", QuestLevel = 2, NpcCFrame = CFrame.new(-1141, 4, 3832), MobCFrame = CFrame.new(-1144, 15, 4325) },
    { MinLevel = 90, MaxLevel = 99, MobName = "Desert Bandit", QuestName = "DesertQuest", QuestLevel = 1, NpcCFrame = CFrame.new(894, 7, 4388), MobCFrame = CFrame.new(996, 7, 4426) },
    { MinLevel = 100, MaxLevel = 119, MobName = "Desert Officer", QuestName = "DesertQuest", QuestLevel = 2, NpcCFrame = CFrame.new(894, 7, 4388), MobCFrame = CFrame.new(1582, 14, 4374) },
    { MinLevel = 120, MaxLevel = 149, MobName = "Snow Bandit", QuestName = "SnowQuest", QuestLevel = 1, NpcCFrame = CFrame.new(1385, 87, -1298), MobCFrame = CFrame.new(1288, 106, -1435) },
    { MinLevel = 150, MaxLevel = 189, MobName = "Yeti", QuestName = "SnowQuest", QuestLevel = 3, NpcCFrame = CFrame.new(1385, 87, -1298), MobCFrame = CFrame.new(1185, 106, -1515) },
    { MinLevel = 190, MaxLevel = 209, MobName = "Chief Petty Officer", QuestName = "MarineQuest2", QuestLevel = 1, NpcCFrame = CFrame.new(-2701, 21, 2100), MobCFrame = CFrame.new(-2840, 73, 2040) },
    { MinLevel = 210, MaxLevel = 249, MobName = "Vice Admiral", QuestName = "MarineQuest2", QuestLevel = 2, NpcCFrame = CFrame.new(-2701, 21, 2100), MobCFrame = CFrame.new(-2840, 73, 2040) },
    { MinLevel = 250, MaxLevel = 299, MobName = "Toga Warrior", QuestName = "ColosseumQuest", QuestLevel = 1, NpcCFrame = CFrame.new(-1580, 7, -2980), MobCFrame = CFrame.new(-1800, 50, -2700) },
    { MinLevel = 300, MaxLevel = 374, MobName = "Military Soldier", QuestName = "MagmaQuest", QuestLevel = 1, NpcCFrame = CFrame.new(-5313, 12, 8515), MobCFrame = CFrame.new(-5400, 50, 8800) },
    { MinLevel = 375, MaxLevel = 449, MobName = "Fishman Warrior", QuestName = "FishmanQuest", QuestLevel = 1, NpcCFrame = CFrame.new(61122, 18, 1569), MobCFrame = CFrame.new(60800, 50, 1500) },
    { MinLevel = 450, MaxLevel = 524, MobName = "God's Guard", QuestName = "SkyExp1Quest", QuestLevel = 1, NpcCFrame = CFrame.new(-4720, 845, -1950), MobCFrame = CFrame.new(-4600, 860, -1850) },
    { MinLevel = 525, MaxLevel = 624, MobName = "Shandora Warrior", QuestName = "SkyExp2Quest", QuestLevel = 1, NpcCFrame = CFrame.new(-7860, 5545, -380), MobCFrame = CFrame.new(-7700, 5560, -450) },
    { MinLevel = 625, MaxLevel = 700, MobName = "Galley Pirate", QuestName = "FountainQuest", QuestLevel = 1, NpcCFrame = CFrame.new(5258, 39, 4050), MobCFrame = CFrame.new(5500, 50, 4000) }
}

local function getPlayerLevel()
    local levelVal = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("Level")
    if levelVal then
        return levelVal.Value
    end
    return 1
end

local function getCurrentQuestInfo()
    local level = getPlayerLevel()
    for _, q in ipairs(QuestData) do
        if level >= q.MinLevel and level <= q.MaxLevel then
            return q
        end
    end
    return QuestData[1]
end

local function hasActiveQuest()
    local mainGui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Main")
    local questFrame = mainGui and mainGui:FindFirstChild("Quest")
    return questFrame and questFrame.Visible
end


-- --------------------------------------------------------------------
-- 2. TWEEN MOVEMENT & SAFE POSITIONING ENGINE (15 STUDS DEFAULT)
-- --------------------------------------------------------------------

local currentTween = nil

local function stopTween()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
end

local function calculateTweenCFrame(targetCFrame)
    local offset = Config.FarmDistanceOffset or 15
    local mode = Config.TweenPositionMode
    local mobPos = targetCFrame.Position
    local destPos = mobPos

    if mode == "Above" then
        destPos = mobPos + Vector3.new(0, offset, 0)
    elseif mode == "Under" then
        destPos = mobPos - Vector3.new(0, offset, 0)
    elseif mode == "Behind" then
        destPos = mobPos + (targetCFrame.LookVector * -offset) + Vector3.new(0, 3, 0)
    elseif mode == "Front" then
        destPos = mobPos + (targetCFrame.LookVector * offset) + Vector3.new(0, 3, 0)
    else
        destPos = mobPos + Vector3.new(0, offset, 0)
    end

    -- Return CFrame looking directly at mob position
    return CFrame.lookAt(destPos, mobPos)
end

local function tweenTo(targetCFrame)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local destCFrame = calculateTweenCFrame(targetCFrame)
    local dist = (hrp.Position - destCFrame.Position).Magnitude
    local speed = Config.TweenSpeed or 250
    local duration = dist / speed

    stopTween()

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = destCFrame})
    currentTween:Play()
    return currentTween
end

-- Automatic Noclip & Anti-Fall BodyVelocity during Auto Farm
local farmBodyVel = nil

RunService.Stepped:Connect(function()
    if (Config.AutoLevelFarm or Config.NoclipEnabled) and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and Config.AutoLevelFarm then
            if not farmBodyVel or farmBodyVel.Parent ~= hrp then
                if farmBodyVel then farmBodyVel:Destroy() end
                farmBodyVel = Instance.new("BodyVelocity")
                farmBodyVel.velocity = Vector3.new(0, 0, 0)
                farmBodyVel.maxForce = Vector3.new(9e9, 9e9, 9e9)
                farmBodyVel.Parent = hrp
            end
        else
            if farmBodyVel then farmBodyVel:Destroy() farmBodyVel = nil end
        end
    else
        if farmBodyVel then farmBodyVel:Destroy() farmBodyVel = nil end
    end
end)


-- --------------------------------------------------------------------
-- 3. WEAPON SELECTOR ENGINE (MELEE / FRUIT / SWORD / GUN)
-- --------------------------------------------------------------------

local function isMeleeTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local name = tool.Name:lower()
    local tooltip = (tool:GetAttribute("ToolTip") or tool.ToolTip or ""):lower()

    if tooltip:find("melee") or name:find("combat") or name:find("black leg") or name:find("step")
       or name:find("karate") or name:find("claw") or name:find("dragon") or name:find("superhuman")
       or name:find("godhuman") or name:find("sanguine") or name:find("electro") or name:find("fist") then
        return true
    end
    return false
end

local function isFruitTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local name = tool.Name:lower()
    local tooltip = (tool:GetAttribute("ToolTip") or tool.ToolTip or ""):lower()
    return tooltip:find("blox fruit") or name:find("fruit") or name:find("power")
end

local function isSwordTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local name = tool.Name:lower()
    local tooltip = (tool:GetAttribute("ToolTip") or tool.ToolTip or ""):lower()
    return tooltip:find("sword") or name:find("katana") or name:find("cutlass") or name:find("blade") or name:find("saber") or name:find("sword")
end

local function isGunTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local name = tool.Name:lower()
    local tooltip = (tool:GetAttribute("ToolTip") or tool.ToolTip or ""):lower()
    return tooltip:find("gun") or name:find("musket") or name:find("slingshot") or name:find("rifle") or name:find("cannon") or name:find("flintlock")
end

local function equipSelectedWeapon()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not char or not bp then return end

    local mode = Config.WeaponMode

    -- Check currently equipped tool first
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool then
        if mode == "Melee" and isMeleeTool(currentTool) then return currentTool end
        if mode == "Blox Fruit" and isFruitTool(currentTool) then return currentTool end
        if mode == "Sword" and isSwordTool(currentTool) then return currentTool end
        if mode == "Gun" and isGunTool(currentTool) then return currentTool end
        -- Unequip wrong tool to Backpack
        currentTool.Parent = bp
    end

    -- Search Backpack for target weapon mode
    for _, tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            local match = false
            if mode == "Melee" and isMeleeTool(tool) then match = true
            elseif mode == "Blox Fruit" and isFruitTool(tool) then match = true
            elseif mode == "Sword" and isSwordTool(tool) then match = true
            elseif mode == "Gun" and isGunTool(tool) then match = true
            end

            if match then
                char.Humanoid:EquipTool(tool)
                return tool
            end
        end
    end

    -- Fallback for Melee: equip any non-fruit/sword/gun tool
    for _, tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            if mode == "Melee" and not isFruitTool(tool) and not isSwordTool(tool) and not isGunTool(tool) then
                char.Humanoid:EquipTool(tool)
                return tool
            end
        end
    end

    local fallback = bp:FindFirstChildOfClass("Tool")
    if fallback then
        char.Humanoid:EquipTool(fallback)
        return fallback
    end
end


-- --------------------------------------------------------------------
-- 4. KILL AURA & ATTACK ENGINE (NO MOUSE FREEZE / MOUSE LOCK)
-- --------------------------------------------------------------------

local function attackTarget(tool)
    if not tool then return end
    pcall(function()
        -- Activate tool directly without VirtualUser mouse capture (Prevents frame freeze!)
        tool:Activate()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end

-- Find matching target mob for current quest ONLY
local function findTargetMob(mobName)
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace
    for _, child in ipairs(enemiesFolder:GetChildren()) do
        if child.Name:lower():find(mobName:lower()) and child:FindFirstChildOfClass("Humanoid") and child:FindFirstChildOfClass("Humanoid").Health > 0 then
            return child
        end
    end
    return nil
end

-- KILL AURA: Bring mob hitboxes directly into attack range right in front of player
local function bringMobsKillAura(mainMob, mobName)
    local char = LocalPlayer.Character
    local playerHrp = char and char:FindFirstChild("HumanoidRootPart")
    if not playerHrp or not mainMob or not mainMob:FindFirstChild("HumanoidRootPart") then return end

    local attackHitboxPoint = playerHrp.CFrame * CFrame.new(0, -3, -3)
    local enemiesFolder = Workspace:FindFirstChild("Enemies") or Workspace

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy.Name:lower():find(mobName:lower()) then
            local eHrp = enemy:FindFirstChild("HumanoidRootPart")
            local eHum = enemy:FindFirstChildOfClass("Humanoid")
            if eHrp and eHum and eHum.Health > 0 then
                if (eHrp.Position - playerHrp.Position).Magnitude < 300 then
                    eHrp.CFrame = attackHitboxPoint
                    eHrp.CanCollide = false
                    eHrp.Size = Vector3.new(12, 12, 12)
                end
            end
        end
    end
end


-- --------------------------------------------------------------------
-- 5. MAIN QUEST-STRICT AUTO LEVEL FARM LOOP
-- --------------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(0.08)
        if Config.AutoLevelFarm then
            pcall(function()
                local qInfo = getCurrentQuestInfo()

                -- Step 1: Check Quest Status
                if not hasActiveQuest() then
                    if currentFarmStatusLabel then
                        currentFarmStatusLabel.Text = string.format("Accepting Quest: %s...", qInfo.MobName)
                    end

                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (hrp.Position - qInfo.NpcCFrame.Position).Magnitude
                        if dist > 15 then
                            tweenTo(qInfo.NpcCFrame)
                        else
                            stopTween()
                            if CommF then
                                CommF:InvokeServer("StartQuest", qInfo.QuestName, qInfo.QuestLevel)
                            end
                            task.wait(0.4)
                        end
                    end
                else
                    -- Step 2: Quest is active -> Farm ONLY quest mobs
                    local mob = findTargetMob(qInfo.MobName)

                    if currentFarmStatusLabel then
                        currentFarmStatusLabel.Text = string.format("Level %d | Quest Active: %s (%s)", getPlayerLevel(), qInfo.MobName, Config.WeaponMode)
                    end

                    if mob and mob:FindFirstChild("HumanoidRootPart") then
                        local mobHrp = mob.HumanoidRootPart
                        local mobHum = mob:FindFirstChildOfClass("Humanoid")

                        -- Safe Tween to Mob (15 studs default offset)
                        tweenTo(mobHrp.CFrame)

                        -- Equip selected weapon type
                        local equippedTool = equipSelectedWeapon()

                        -- Kill Aura & Bring Mobs to Attack Hitbox
                        if Config.KillAura or Config.BringMobs then
                            bringMobsKillAura(mob, qInfo.MobName)
                        end

                        -- Attack
                        if mobHum and mobHum.Health > 0 then
                            attackTarget(equippedTool)
                        end
                    else
                        -- If mob not spawned yet, wait at safe mob spawn CFrame
                        tweenTo(qInfo.MobCFrame)
                    end
                end
            end)
        else
            stopTween()
        end
    end
end)


-- --------------------------------------------------------------------
-- 6. MOVEMENT & WASD FLIGHT SUITE
-- --------------------------------------------------------------------

local flyGyro, flyVel

local function startFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flyGyro then flyGyro:Destroy() end
    if flyVel then flyVel:Destroy() end

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
    if Config.FlyEnabled and flyVel and flyGyro and LocalPlayer.Character then
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
-- UI INTERFACE CREATION (LIB.LUA FRAMEWORK)
-- --------------------------------------------------------------------

-- TAB 1: AUTO FARM
farmTab:CreateComment("--- Auto Quest & Level Farm ---")

farmTab:CreateToggleSwitch("Auto Level Farm (Quest Strict + Mobs)", false, function(val)
    Config.AutoLevelFarm = val
    if val then
        lib:Notify("Auto Farm", "Quest-Strict Level Farm & Kill Aura Activated!", 2.0)
    else
        stopTween()
        lib:Notify("Auto Farm", "Auto Level Farm Deactivated.", 1.5)
    end
end)

farmTab:CreateToggleSwitch("Kill Aura & Hitbox Extender", true, function(val)
    Config.KillAura = val
end)

farmTab:CreateToggleSwitch("Bring Mobs", true, function(val)
    Config.BringMobs = val
end)

-- Status Card
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 42)
statusCard.BackgroundColor3 = int.Theme and int.Theme.CardBg or Color3.fromRGB(24, 28, 42)
statusCard.BorderSizePixel = 0
statusCard.Parent = farmTab.TabContent

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 6)
cardCorner.Parent = statusCard

currentFarmStatusLabel = Instance.new("TextLabel")
currentFarmStatusLabel.Size = UDim2.new(1, -20, 1, 0)
currentFarmStatusLabel.Position = UDim2.new(0, 10, 0, 0)
currentFarmStatusLabel.BackgroundTransparency = 1
currentFarmStatusLabel.Text = "Status: Idle (Toggle 'Auto Level Farm' to start)"
currentFarmStatusLabel.TextColor3 = Color3.fromRGB(180, 185, 210)
currentFarmStatusLabel.TextSize = 13
currentFarmStatusLabel.Font = Enum.Font.GothamBold
currentFarmStatusLabel.TextWrapped = true
currentFarmStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
currentFarmStatusLabel.Parent = statusCard


-- TAB 2: FARM SETTINGS (WEAPON & TWEEN POSITION)
configTab:CreateComment("--- Weapon Selection Mode ---")
local weaponDrop = configTab:CreateDropDown("Select Weapon Mode", function() end)
local weaponTypes = {"Melee", "Blox Fruit", "Sword", "Gun"}
for _, wName in ipairs(weaponTypes) do
    weaponDrop:AddButton("Weapon: " .. wName, function()
        Config.WeaponMode = wName
        equipSelectedWeapon()
        lib:Notify("Weapon Mode", "Selected Weapon: " .. wName, 1.5)
    end)
end

configTab:CreateComment("--- Tween Position Mode & Settings ---")
local tweenPosDrop = configTab:CreateDropDown("Select Tween Position Mode", function() end)
local posModes = {"Above", "Under", "Behind", "Front"}
for _, pMode in ipairs(posModes) do
    tweenPosDrop:AddButton("Position: " .. pMode, function()
        Config.TweenPositionMode = pMode
        lib:Notify("Tween Mode", "Selected Position: " .. pMode, 1.5)
    end)
end

configTab:CreateSlider("Tween Speed (Studs/sec)", 100, 350, 250, function(val)
    Config.TweenSpeed = val
end)

configTab:CreateSlider("Farm Distance Offset (Studs)", 3, 30, 15, function(val)
    Config.FarmDistanceOffset = val
end)


-- TAB 3: MOVEMENT & FLY
moveTab:CreateComment("--- WASD Flight & Speed Controls ---")

moveTab:CreateToggleSwitch("WASD Flight System", false, function(val)
    Config.FlyEnabled = val
    if val then
        startFly()
        lib:Notify("Flight", "Flight Mode Active! Use WASD + Q/E to fly.", 2.5)
    else
        stopFly()
        lib:Notify("Flight", "Flight Mode Deactivated.", 1.5)
    end
end)

moveTab:CreateSlider("Fly Speed", 10, 300, 50, function(val)
    Config.FlySpeed = val
end)

moveTab:CreateToggleSwitch("Noclip (Walk Through Walls)", false, function(val)
    Config.NoclipEnabled = val
end)

moveTab:CreateSlider("WalkSpeed", 16, 250, 16, function(val)
    Config.WalkSpeed = val
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
        end
    end)
end)


-- TAB 4: SETTINGS
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)
local themesList = {"blood", "cyber", "royal", "emerald", "dark", "midnight", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

lib:Notify("Blox Fruits Suite", "Loaded successfully! Press 'K' to hide or show GUI.", 5.0)
print("[Blox Fruits Suite] Ultimate Blox Fruits Auto Farm Suite Loaded Successfully!")
