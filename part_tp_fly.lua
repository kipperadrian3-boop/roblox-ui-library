--[[
	Part Teleport & Fly Suite (part_tp_fly.lua)
	Features:
	  - Interactive Part Selection (Click any 3D object in world to select & highlight in blue/cyan)
	  - Instant Teleportation to Selected Part with configurable height offset
	  - Auto Teleport Loop (ON/OFF Toggle & Speed Slider 0.1s to 2.0s)
	  - WASD Flight System with adjustable Fly Speed slider & Noclip
	  - Custom UI Library (lib.lua) with Cyber Blue theme & Universal JSON Auto-Save
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with dynamic cache buster & JSON auto-save engine)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Part TP Suite Error] Could not load UI Library from GitHub!")
    return
end

-- Create Interface with Standard Cyber Blue Theme
local int = lib:CreateInterface("Part Teleport & Fly Suite", "Interactive Part Picker & Flight Utility", "https://discord.gg/ZNTHTWx7KE", "bottom left", "cyber", 0.25)

-- Tabs
local tpTab = int:CreateTab("Part Teleport", "Click World Parts & Teleport", "op", true)
local moveTab = int:CreateTab("Movement & Fly", "Flight, WalkSpeed & Noclip", "player")
local settingsTab = int:CreateTab("Settings", "UI Customization & Config", "misc")

-- Configuration & State
local Config = {
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    ClickSelectEnabled = false,
    TeleportOffsetHeight = 3,
    AutoTpEnabled = false,
    AutoTpDelay = 0.5 -- In seconds (0.1 to 2.0)
}

local selectedPart = nil
local selectionHighlight = nil
local selectConnection = nil
local selectedPartLabel = nil

-- Helper to update Highlight on selected part
local function highlightSelectedPart(part)
    if selectionHighlight then
        pcall(function() selectionHighlight:Destroy() end)
        selectionHighlight = nil
    end

    if part and part:IsA("BasePart") then
        local hl = Instance.new("Highlight")
        hl.Name = "PartPickerHighlight"
        hl.Adornee = part
        hl.FillColor = Color3.fromRGB(0, 170, 255) -- Standard Blue
        hl.OutlineColor = Color3.fromRGB(0, 255, 255) -- Cyan Glow
        hl.FillTransparency = 0.3
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = part
        selectionHighlight = hl
    end
end

-- Helper to update UI label
local function updateSelectedPartUI()
    if selectedPartLabel then
        if selectedPart and selectedPart:IsA("BasePart") then
            local pos = selectedPart.Position
            selectedPartLabel.Text = string.format("Selected: %s | Pos: (%.1f, %.1f, %.1f)", selectedPart.Name, pos.X, pos.Y, pos.Z)
            selectedPartLabel.TextColor3 = Color3.fromRGB(0, 255, 180)
        else
            selectedPartLabel.Text = "Selected: None (Click 'Select Part Mode' & click any part in world)"
            selectedPartLabel.TextColor3 = Color3.fromRGB(180, 185, 210)
        end
    end
end

-- --------------------------------------------------------------------
-- 1. CLICK PART SELECTION SYSTEM
-- --------------------------------------------------------------------

local function enableClickPicker(enable)
    Config.ClickSelectEnabled = enable

    if selectConnection then
        selectConnection:Disconnect()
        selectConnection = nil
    end

    if enable then
        lib:Notify("Part Picker", "Click-Select Mode Active! Click on any part in the 3D world.", 3.0)
        selectConnection = Mouse.Button1Down:Connect(function()
            if not Config.ClickSelectEnabled then return end

            local target = Mouse.Target
            if target and target:IsA("BasePart") then
                selectedPart = target
                highlightSelectedPart(target)
                updateSelectedPartUI()
                lib:Notify("Part Selected", "Target: " .. target.Name .. " (" .. target.ClassName .. ")", 2.0)
            end
        end)
    else
        lib:Notify("Part Picker", "Click-Select Mode Deactivated.", 1.5)
    end
end


-- --------------------------------------------------------------------
-- 2. AUTO TELEPORT LOOP
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
-- 3. FLY & NOCLIP & MOVEMENT SUITE
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

-- Flight Render Loop
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

-- Noclip Loop
RunService.Stepped:Connect(function()
    if Config.NoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)


-- --------------------------------------------------------------------
-- UI ELEMENTS - PART TELEPORT TAB
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
        lib:Notify("Teleport Failed", "No part selected! Activate 'Click Part Selection Mode' and click a part first.", 3.0)
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        lib:Notify("Teleport Failed", "Character or HumanoidRootPart not found!", 2.5)
        return
    end

    local targetPos = selectedPart.Position + Vector3.new(0, Config.TeleportOffsetHeight or 3, 0)
    hrp.CFrame = CFrame.new(targetPos)
    lib:Notify("Teleport Success", "Teleported to " .. selectedPart.Name .. "!", 2.5)
end)

-- Auto Teleport Toggle & Interval Slider (0.1s to 2.0s)
tpTab:CreateToggleSwitch("Auto Teleport to Selected Part", false, function(val)
    Config.AutoTpEnabled = val
    if val then
        lib:Notify("Auto TP", "Auto Teleport Activated!", 2.0)
    else
        lib:Notify("Auto TP", "Auto Teleport Deactivated.", 1.5)
    end
end)

-- Slider from 1 to 20 representing 0.1s to 2.0s
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
    lib:Notify("Selection Cleared", "Cleared selected part.", 1.5)
end)


-- --------------------------------------------------------------------
-- UI ELEMENTS - MOVEMENT & FLY TAB
-- --------------------------------------------------------------------
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
    if val then
        lib:Notify("Noclip", "Noclip Enabled!", 2.0)
    else
        lib:Notify("Noclip", "Noclip Disabled.", 1.5)
    end
end)

moveTab:CreateSlider("WalkSpeed", 16, 250, 16, function(val)
    Config.WalkSpeed = val
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
        end
    end)
end)

moveTab:CreateSlider("JumpPower", 50, 300, 50, function(val)
    Config.JumpPower = val
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = val
        end
    end)
end)


-- --------------------------------------------------------------------
-- UI ELEMENTS - SETTINGS TAB
-- --------------------------------------------------------------------
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)
local themesList = {"cyber", "royal", "emerald", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

lib:Notify("Part Teleport & Fly", "Loaded successfully! Press 'K' to hide or show GUI.", 5.0)
print("[Part Teleport & Fly Suite] Updated with Auto-TP Loop Successfully!")
