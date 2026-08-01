--[[
    Keyboard Escape - Custom Script Suite (keyboard_escape.lua)
    Features: 
      - Fast Summer Coins Auto Farm (0.1s Teleport, Anti-Death & Return-To-Start Position)
      - Secret Key Auto Farm (+2.2 Studs & Return-To-Start Position)
      - Player Tab (WalkSpeed 0-500, JumpPower 0-500)
      - Fly System with FlySpeed Slider (0-300)
    Powered by Custom UI Framework (lib.lua)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Robust UI Library Fallback Loader
local Library = nil
local loadAttempts = {
    "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/lib.lua",
    "https://cdn.jsdelivr.net/gh/kipperadrian3-boop/roblox-ui-library@main/lib.lua"
}

for _, url in ipairs(loadAttempts) do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(url))()
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

local int = Library:CreateInterface("Keyboard Escape", "Summer Coins, Secret Keys & Fly Utilities", "", "bottom left", "royal", 0.25)

local farmTab = int:CreateTab("Farm", "Farming Utilities", "item", true)
local playerTab = int:CreateTab("Player", "Movement & Speed Controls", "player")
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Config State
local Config = {
    SummerCoinsFarm = false,
    SecretKeyFarm = false,
    WalkSpeed = 16,
    JumpPower = 50,
    ModifySpeed = false,
    ModifyJump = false,
    Flying = false,
    FlySpeed = 50
}

-- Saved Start Positions for Return-To-Start Logic
local savedCoinStartCF = nil
local savedKeyStartCF = nil

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
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
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
-- UI TAB 2: PLAYER CONTROLS (WalkSpeed, JumpPower & Fly)
-- --------------------------------------------------------------------
playerTab:CreateToggleSwitch("Enable Fly", false, function(val)
    Config.Flying = val
    if val then
        startFly()
        Library:Notify("Player", "Fly Activated! Use WASD + Space/Shift to fly.", 2)
    else
        stopFly()
        Library:Notify("Player", "Fly Deactivated.", 1.5)
    end
end)

playerTab:CreateSlider("Fly Speed (0 - 300)", 0, 300, 50, function(val)
    Config.FlySpeed = val
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
-- UI TAB 3: UI SETTINGS & TRANSPARENCY
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

print("[Keyboard Escape Suite] Return-To-Start Feature Active!")
