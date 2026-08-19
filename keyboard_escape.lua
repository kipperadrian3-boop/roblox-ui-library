--[[
    Keyboard Escape - Custom Script Suite (keyboard_escape.lua)
    Features: 
      - Fast Summer Coins Auto Farm (0.1s Teleport, Anti-Death & Return-To-Start Position)
      - Secret Key Auto Farm (+2.2 Studs & Return-To-Start Position)
      - Interactive Part Teleport (Click any 3D part in world to select, highlight & teleport)
      - Auto Teleport to Selected Part (Configurable 0.1s - 2.0s loop & height offset)
      - Player Tab (WalkSpeed 0-500, JumpPower 0-500, Noclip)
      - WASD Flight System with FlySpeed Slider (0-300)
    Powered by Custom UI Framework (lib.lua)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Robust UI Library Fallback Loader
local Library = nil
local loadAttempts = {
    "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/lib.lua",
    "https://cdn.jsdelivr.net/gh/kipperadrian3-boop/roblox-ui-library@main/lib.lua"
}

for _, url in ipairs(loadAttempts) do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(url .. "?v=" .. tostring(math.random(1, 9999999))))()
    end)
    if ok and type(res) == "table" then
        Library = res
        break
    end
end

if not Library then
    warn("[Keyboard Escape Error] UI Library raw URL unreachable.")
    return
end

local int = Library:CreateInterface("Keyboard Escape", "Summer Coins, Secret Keys & Part TP Utilities", "", "bottom left", "royal", 0.25)

local farmTab = int:CreateTab("Farm", "Farming Utilities", "item", true)
local tpTab = int:CreateTab("Part Teleport", "Click World Parts & Teleport", "op")
local playerTab = int:CreateTab("Player", "Movement & Speed Controls", "player")
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Config State
local Config = {
    SummerCoinsFarm = false,
    SecretKeyFarm = false,
    ClickSelectEnabled = false,
    TeleportOffsetHeight = 3,
    AutoTpEnabled = false,
    AutoTpDelay = 0.5,
    WalkSpeed = 16,
    JumpPower = 50,
    ModifySpeed = false,
    ModifyJump = false,
    Noclip = false,
    Flying = false,
    FlySpeed = 50
}

-- Saved Start Positions for Return-To-Start Logic
local savedCoinStartCF = nil
local savedKeyStartCF = nil

-- Part Teleport State
local selectedPart = nil
local selectionHighlight = nil
local selectConnection = nil
local selectedPartLabel = nil

-- Fly Physics State
local flyBV = nil
local flyBG = nil
local renderConnection = nil

local function stopFly()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end

    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end
end

local function startFly()
    stopFly()

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local humanoid = char:WaitForChild("Humanoid", 5)

    if not hrp or not humanoid then return end

    humanoid.PlatformStand = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "FlyVelocity"
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.Name = "FlyGyro"
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp

    local camera = Workspace.CurrentCamera

    renderConnection = RunService.RenderStepped:Connect(function()
        if not Config.Flying or not hrp or not hrp.Parent then
            stopFly()
            return
        end

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        flyBG.CFrame = camera.CFrame
        if moveDir.Magnitude > 0 then
            flyBV.Velocity = moveDir.Unit * Config.FlySpeed
        else
            flyBV.Velocity = Vector3.zero
        end
    end)
end

-- Apply Player Speed & Jump Power Loop
local function applyPlayerModifiers(char)
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if Config.ModifySpeed then
            humanoid.WalkSpeed = Config.WalkSpeed
        end
        if Config.ModifyJump then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = Config.JumpPower
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    applyPlayerModifiers(newChar)

    if Config.Flying then
        task.wait(0.5)
        startFly()
    end

    local humanoid = newChar:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if Config.ModifySpeed then humanoid.WalkSpeed = Config.WalkSpeed end
        end)
        humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if Config.ModifyJump then humanoid.JumpPower = Config.JumpPower end
        end)
    end
end)

-- Noclip Stepped Loop
RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- --------------------------------------------------------------------
-- 1. FAST SUMMER COINS FARM LOOP (0.1s Teleport & Return-To-Start)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.SummerCoinsFarm then
            pcall(function()
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2))
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                
                if not hrp or not humanoid or humanoid.Health <= 0 then return end

                if not savedCoinStartCF then
                    savedCoinStartCF = hrp.CFrame
                end

                local coinsFolder = Workspace:FindFirstChild("SummerCoinsLocal")
                local coinsToCollect = {}
                if coinsFolder then
                    for _, item in ipairs(coinsFolder:GetChildren()) do
                        if item.Name == "SummerCoin" then
                            table.insert(coinsToCollect, item)
                        end
                    end
                end

                if #coinsToCollect > 0 then
                    for _, item in ipairs(coinsToCollect) do
                        if not Config.SummerCoinsFarm or humanoid.Health <= 0 then break end
                        local targetCF = item:IsA("Model") and item:GetPivot() or (item:IsA("BasePart") and item.CFrame)
                        if targetCF then
                            hrp.CFrame = targetCF + Vector3.new(0, 2, 0)
                            task.wait(0.1)
                        end
                    end
                    if savedCoinStartCF and Config.SummerCoinsFarm and humanoid.Health > 0 then
                        hrp.CFrame = savedCoinStartCF
                    end
                else
                    if savedCoinStartCF and (hrp.CFrame.Position - savedCoinStartCF.Position).Magnitude > 5 then
                        hrp.CFrame = savedCoinStartCF
                    end
                end
            end)
        else
            savedCoinStartCF = nil
        end
    end
end)

-- --------------------------------------------------------------------
-- 2. SECRET KEYS FARM LOOP (Teleports to Workspace.SpecialKeys & Return-To-Start)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.SecretKeyFarm then
            pcall(function()
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 2))
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")

                if not hrp or not humanoid or humanoid.Health <= 0 then return end

                if not savedKeyStartCF then
                    savedKeyStartCF = hrp.CFrame
                end

                local keysFolder = Workspace:FindFirstChild("SpecialKeys")
                local keysToCollect = {}
                if keysFolder then
                    for _, item in ipairs(keysFolder:GetChildren()) do
                        if string.find(item.Name:lower(), "key") then
                            table.insert(keysToCollect, item)
                        end
                    end
                end

                if #keysToCollect > 0 then
                    for _, item in ipairs(keysToCollect) do
                        if not Config.SecretKeyFarm or humanoid.Health <= 0 then break end
                        local targetCF = item:IsA("Model") and item:GetPivot() or (item:IsA("BasePart") and item.CFrame)
                        if targetCF then
                            hrp.CFrame = targetCF + Vector3.new(0, 2.2, 0)
                            task.wait(0.1)
                        end
                    end
                    if savedKeyStartCF and Config.SecretKeyFarm and humanoid.Health > 0 then
                        hrp.CFrame = savedKeyStartCF
                    end
                else
                    if savedKeyStartCF and (hrp.CFrame.Position - savedKeyStartCF.Position).Magnitude > 5 then
                        hrp.CFrame = savedKeyStartCF
                    end
                end
            end)
        else
            savedKeyStartCF = nil
        end
    end
end)

-- --------------------------------------------------------------------
-- 3. CLICK PART SELECTION & HIGHLIGHT SYSTEM
-- --------------------------------------------------------------------
local function highlightSelectedPart(part)
    if selectionHighlight then
        pcall(function() selectionHighlight:Destroy() end)
        selectionHighlight = nil
    end

    if part and part:IsA("BasePart") then
        local hl = Instance.new("Highlight")
        hl.Name = "PartPickerHighlight"
        hl.Adornee = part
        hl.FillColor = Color3.fromRGB(0, 170, 255)
        hl.OutlineColor = Color3.fromRGB(0, 255, 255)
        hl.FillTransparency = 0.3
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = part
        selectionHighlight = hl
    end
end

local function updateSelectedPartUI()
    if selectedPartLabel then
        if selectedPart and selectedPart:IsA("BasePart") then
            local pos = selectedPart.Position
            selectedPartLabel.Text = string.format("Selected: %s | Pos: (%.1f, %.1f, %.1f)", selectedPart.Name, pos.X, pos.Y, pos.Z)
            selectedPartLabel.TextColor3 = Color3.fromRGB(0, 255, 180)
        else
            selectedPartLabel.Text = "Selected: None (Click 'Click Part Selection Mode' & click any part in world)"
            selectedPartLabel.TextColor3 = Color3.fromRGB(180, 185, 210)
        end
    end
end

local function enableClickPicker(enable)
    Config.ClickSelectEnabled = enable

    if selectConnection then
        selectConnection:Disconnect()
        selectConnection = nil
    end

    if enable then
        Library:Notify("Part Picker", "Click-Select Mode Active! Click on any part in the 3D world.", 3.0)
        selectConnection = Mouse.Button1Down:Connect(function()
            if not Config.ClickSelectEnabled then return end

            local target = Mouse.Target
            if target and target:IsA("BasePart") then
                selectedPart = target
                highlightSelectedPart(target)
                updateSelectedPartUI()
                Library:Notify("Part Selected", "Target: " .. target.Name .. " (" .. target.ClassName .. ")", 2.0)
            end
        end)
    else
        Library:Notify("Part Picker", "Click-Select Mode Deactivated.", 1.5)
    end
end

-- --------------------------------------------------------------------
-- 4. AUTO TELEPORT LOOP (To Selected Part)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(Config.AutoTpDelay or 0.5)
        if Config.AutoTpEnabled then
            pcall(function()
                if selectedPart and selectedPart:IsA("BasePart") then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local targetPos = selectedPart.Position + Vector3.new(0, Config.TeleportOffsetHeight or 3, 0)
                        hrp.CFrame = CFrame.new(targetPos)
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: FARM CONTROLS
-- --------------------------------------------------------------------
farmTab:CreateToggleSwitch("Summer Coins Farm (0.1s Fast Teleport)", false, function(val)
    Config.SummerCoinsFarm = val
    if val then
        savedCoinStartCF = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.CFrame
        Library:Notify("Keyboard Escape", "Summer Coins Farm Active (Auto Return-To-Start)!", 1.5)
    else
        savedCoinStartCF = nil
        Library:Notify("Keyboard Escape", "Summer Coins Farm Stopped.", 1.5)
    end
end)

farmTab:CreateToggleSwitch("Secret Key Farm (0.1s Fast Teleport)", false, function(val)
    Config.SecretKeyFarm = val
    if val then
        savedKeyStartCF = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.CFrame
        Library:Notify("Keyboard Escape", "Secret Key Farm Active (Auto Return-To-Start)!", 1.5)
    else
        savedKeyStartCF = nil
        Library:Notify("Keyboard Escape", "Secret Key Farm Stopped.", 1.5)
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 2: PART TELEPORT TAB
-- --------------------------------------------------------------------
tpTab:CreateComment("--- Click Part Picker & Teleportation ---")

tpTab:CreateToggleSwitch("Click Part Selection Mode", false, function(val)
    enableClickPicker(val)
end)

-- Custom Status Label Frame for Selected Part
local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, 0, 0, 40)
infoCard.BackgroundColor3 = int.Theme and int.Theme.CardBg or Color3.fromRGB(24, 28, 42)
infoCard.BorderSizePixel = 0
infoCard.Parent = tpTab.TabContent

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 6)
cardCorner.Parent = infoCard

selectedPartLabel = Instance.new("TextLabel")
selectedPartLabel.Size = UDim2.new(1, -20, 1, 0)
selectedPartLabel.Position = UDim2.new(0, 10, 0, 0)
selectedPartLabel.BackgroundTransparency = 1
selectedPartLabel.Text = "Selected: None (Click 'Click Part Selection Mode' & click any part in world)"
selectedPartLabel.TextColor3 = Color3.fromRGB(180, 185, 210)
selectedPartLabel.TextSize = 12
selectedPartLabel.Font = Enum.Font.GothamMedium
selectedPartLabel.TextWrapped = true
selectedPartLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedPartLabel.Parent = infoCard

-- Manual Teleport Button
tpTab:CreateButton("TELEPORT TO SELECTED PART", function()
    if not selectedPart or not selectedPart:IsA("BasePart") then
        Library:Notify("Teleport Failed", "No part selected! Activate 'Click Part Selection Mode' and click a part first.", 3.0)
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Library:Notify("Teleport Failed", "Character or HumanoidRootPart not found!", 2.5)
        return
    end

    local targetPos = selectedPart.Position + Vector3.new(0, Config.TeleportOffsetHeight or 3, 0)
    hrp.CFrame = CFrame.new(targetPos)
    Library:Notify("Teleport Success", "Teleported to " .. selectedPart.Name .. "!", 2.5)
end)

-- Auto Teleport Toggle & Interval Slider (0.1s to 2.0s)
tpTab:CreateToggleSwitch("Auto Teleport to Selected Part", false, function(val)
    Config.AutoTpEnabled = val
    if val then
        Library:Notify("Auto TP", "Auto Teleport Activated!", 2.0)
    else
        Library:Notify("Auto TP", "Auto Teleport Deactivated.", 1.5)
    end
end)

tpTab:CreateSlider("Auto Teleport Speed (0.1s - 2.0s)", 1, 20, 5, function(val)
    Config.AutoTpDelay = math.clamp(val / 10, 0.1, 2.0)
end)

tpTab:CreateSlider("Teleport Height Offset (Studs)", 0, 20, 3, function(val)
    Config.TeleportOffsetHeight = val
end)

tpTab:CreateButton("Clear Selection", function()
    selectedPart = nil
    highlightSelectedPart(nil)
    updateSelectedPartUI()
    Library:Notify("Selection Cleared", "Cleared selected part.", 1.5)
end)


-- --------------------------------------------------------------------
-- UI TAB 3: PLAYER CONTROLS (WalkSpeed, JumpPower, Fly & Noclip)
-- --------------------------------------------------------------------
playerTab:CreateComment("--- WASD Flight & Speed Controls ---")

playerTab:CreateToggleSwitch("Enable Fly", false, function(val)
    Config.Flying = val
    if val then
        startFly()
        Library:Notify("Player", "Fly Activated! Use WASD + Space/Shift or Q/E to fly.", 2.5)
    else
        stopFly()
        Library:Notify("Player", "Fly Deactivated.", 1.5)
    end
end)

playerTab:CreateSlider("Fly Speed (0 - 300)", 0, 300, 50, function(val)
    Config.FlySpeed = val
end)

playerTab:CreateToggleSwitch("Noclip (Walk Through Walls)", false, function(val)
    Config.Noclip = val
    if val then
        Library:Notify("Noclip", "Noclip Enabled!", 2.0)
    else
        Library:Notify("Noclip", "Noclip Disabled.", 1.5)
    end
end)

playerTab:CreateToggleSwitch("Enable WalkSpeed Modifier", false, function(val)
    Config.ModifySpeed = val
    applyPlayerModifiers(LocalPlayer.Character)
end)

playerTab:CreateSlider("WalkSpeed (0 - 500)", 0, 500, 16, function(val)
    Config.WalkSpeed = val
    if Config.ModifySpeed then
        applyPlayerModifiers(LocalPlayer.Character)
    end
end)

playerTab:CreateToggleSwitch("Enable JumpPower Modifier", false, function(val)
    Config.ModifyJump = val
    applyPlayerModifiers(LocalPlayer.Character)
end)

playerTab:CreateSlider("JumpPower (0 - 500)", 0, 500, 50, function(val)
    Config.JumpPower = val
    if Config.ModifyJump then
        applyPlayerModifiers(LocalPlayer.Character)
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 4: UI SETTINGS & TRANSPARENCY
-- --------------------------------------------------------------------
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)
local themesList = {"royal", "cyber", "emerald", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

print("[Keyboard Escape Suite] Features initialized: Summer Coins, Secret Keys, Part Teleport & Flight!")
