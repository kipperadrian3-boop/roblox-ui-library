--[[
	TP Location Suite (tp_location.lua)
	Features:
	  - 📱 Sleek Right-Aligned Draggable GUI (Dark Cyber Glass Design)
	  - 📍 "Set Location": Saves current player CFrame & coordinates
	  - 🚀 "TP Location": Instantly teleports player to saved location (repeatable)
	  - ⚡ "Auto TP (0.1s)": ON/OFF Toggle loop teleporting every 0.1 seconds
	  - ⏩ "Forward TP [L]": Teleports forward X studs (customizable input, default 15)
	  - ⌨️ Keybinds: Press [K] to toggle GUI, Press [L] to TP Forward
	  - 🧹 Auto Clean: Automatically deletes old GUI instances on re-execution
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Safe UI Parent Helper (Compatible with Solara, Wave, Synapse, CoreGui, PlayerGui)
local function getGuiParent()
    local success, result = pcall(function()
        if gethui then
            return gethui()
        elseif syn and syn.protect_gui then
            local sg = Instance.new("Folder")
            syn.protect_gui(sg)
            sg.Parent = CoreGui
            return sg
        elseif CoreGui:FindFirstChild("RobloxGui") then
            return CoreGui
        end
    end)
    if success and result then
        return result
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Completely clean up any old GUI instances across all parents on re-execution
local function cleanupOldGuis()
    local targets = {CoreGui, LocalPlayer:FindFirstChild("PlayerGui")}
    pcall(function()
        if gethui then table.insert(targets, gethui()) end
    end)
    for _, target in ipairs(targets) do
        if target then
            for _, child in ipairs(target:GetChildren()) do
                if child.Name == "TpLocationGui" then
                    child:Destroy()
                end
            end
        end
    end
end
cleanupOldGuis()

-- Script State
local savedCFrame = nil
local autoTpActive = false
local autoTpThread = nil
local forwardDistance = 15

local parentGui = getGuiParent()

-- UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TpLocationGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

-- Main Frame (Right side default)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 230, 0, 330)
MainFrame.Position = UDim2.new(1, -245, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 180, 255)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.2
Stroke.Parent = MainFrame

-- Gradient background
local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 25, 38)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 22))
})
Gradient.Rotation = 45
Gradient.Parent = MainFrame

-- Top Drag Header Bar
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 36)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

-- Cover bottom rounded corners of header to merge seamlessly
local HeaderCover = Instance.new("Frame")
HeaderCover.Size = UDim2.new(1, 0, 0, 10)
HeaderCover.Position = UDim2.new(0, 0, 1, -10)
HeaderCover.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
HeaderCover.BorderSizePixel = 0
HeaderCover.Parent = Header

-- Title Text
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "📍 Location Manager"
Title.TextColor3 = Color3.fromRGB(240, 245, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(1, -30, 0.5, -12)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 45)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(180, 190, 210)
MinimizeBtn.TextSize = 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

-- Draggable Logic (Mouse & Touch input support)
local dragging = false
local dragInput, dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- Content Container
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -20, 1, -48)
Content.Position = UDim2.new(0, 10, 0, 42)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = Content

-- Helper function to build styled action buttons
local function createButton(order, text, icon, accentColor)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(24, 29, 42)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = Content

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = accentColor or Color3.fromRGB(60, 70, 95)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.5
    btnStroke.Parent = btn

    local btnLabel = Instance.new("TextLabel")
    btnLabel.Size = UDim2.new(1, 0, 1, 0)
    btnLabel.BackgroundTransparency = 1
    btnLabel.Text = icon .. " " .. text
    btnLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
    btnLabel.TextSize = 13
    btnLabel.Font = Enum.Font.GothamSemibold
    btnLabel.Parent = btn

    -- Hover animations
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(32, 39, 58)}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.1}):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(24, 29, 42)}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
    end)

    return btn, btnLabel, btnStroke
end

-- 1. SET LOCATION BUTTON (Top)
local setBtn, setLabel, setStroke = createButton(1, "Set Location", "📍", Color3.fromRGB(0, 170, 255))

-- Status Display Label for Saved Position
local StatusBox = Instance.new("Frame")
StatusBox.LayoutOrder = 2
StatusBox.Size = UDim2.new(1, 0, 0, 32)
StatusBox.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
StatusBox.BorderSizePixel = 0
StatusBox.Parent = Content

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusBox

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -12, 1, 0)
StatusText.Position = UDim2.new(0, 6, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Keine Position gespeichert"
StatusText.TextColor3 = Color3.fromRGB(140, 150, 175)
StatusText.TextSize = 11
StatusText.Font = Enum.Font.Gotham
StatusText.TextTruncate = Enum.TextTruncate.AtEnd
StatusText.Parent = StatusBox

-- 2. TP LOCATION BUTTON (Middle)
local tpBtn, tpLabel, tpStroke = createButton(3, "TP Location", "🚀", Color3.fromRGB(130, 85, 245))

-- 3. AUTO TP TOGGLE (Teleport every 0.1 seconds)
local ToggleFrame = Instance.new("Frame")
ToggleFrame.LayoutOrder = 4
ToggleFrame.Size = UDim2.new(1, 0, 0, 42)
ToggleFrame.BackgroundColor3 = Color3.fromRGB(24, 29, 42)
ToggleFrame.BorderSizePixel = 0
ToggleFrame.Parent = Content

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleFrame

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(60, 70, 95)
ToggleStroke.Thickness = 1
ToggleStroke.Transparency = 0.5
ToggleStroke.Parent = ToggleFrame

local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
ToggleLabel.Position = UDim2.new(0, 12, 0, 0)
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Text = "⚡ Auto TP (0.1s)"
ToggleLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
ToggleLabel.TextSize = 13
ToggleLabel.Font = Enum.Font.GothamSemibold
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.Parent = ToggleFrame

local SwitchBg = Instance.new("TextButton")
SwitchBg.Name = "SwitchBg"
SwitchBg.Size = UDim2.new(0, 40, 0, 22)
SwitchBg.Position = UDim2.new(1, -48, 0.5, -11)
SwitchBg.BackgroundColor3 = Color3.fromRGB(40, 48, 65)
SwitchBg.BorderSizePixel = 0
SwitchBg.Text = ""
SwitchBg.AutoButtonColor = false
SwitchBg.Parent = ToggleFrame

local SwitchCorner = Instance.new("UICorner")
SwitchCorner.CornerRadius = UDim.new(1, 0)
SwitchCorner.Parent = SwitchBg

local SwitchKnob = Instance.new("Frame")
SwitchKnob.Name = "Knob"
SwitchKnob.Size = UDim2.new(0, 16, 0, 16)
SwitchKnob.Position = UDim2.new(0, 3, 0.5, -8)
SwitchKnob.BackgroundColor3 = Color3.fromRGB(180, 190, 210)
SwitchKnob.BorderSizePixel = 0
SwitchKnob.Parent = SwitchBg

local KnobCorner = Instance.new("UICorner")
KnobCorner.CornerRadius = UDim.new(1, 0)
KnobCorner.Parent = SwitchKnob

-- 4. FORWARD TP FRAME ([L] Key & Studs Textbox)
local ForwardFrame = Instance.new("Frame")
ForwardFrame.LayoutOrder = 5
ForwardFrame.Size = UDim2.new(1, 0, 0, 42)
ForwardFrame.BackgroundColor3 = Color3.fromRGB(24, 29, 42)
ForwardFrame.BorderSizePixel = 0
ForwardFrame.Parent = Content

local ForwardCorner = Instance.new("UICorner")
ForwardCorner.CornerRadius = UDim.new(0, 8)
ForwardCorner.Parent = ForwardFrame

local ForwardStroke = Instance.new("UIStroke")
ForwardStroke.Color = Color3.fromRGB(60, 70, 95)
ForwardStroke.Thickness = 1
ForwardStroke.Transparency = 0.5
ForwardStroke.Parent = ForwardFrame

local ForwardLabel = Instance.new("TextLabel")
ForwardLabel.Size = UDim2.new(1, -95, 1, 0)
ForwardLabel.Position = UDim2.new(0, 12, 0, 0)
ForwardLabel.BackgroundTransparency = 1
ForwardLabel.Text = "⏩ Forward [L]"
ForwardLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
ForwardLabel.TextSize = 13
ForwardLabel.Font = Enum.Font.GothamSemibold
ForwardLabel.TextXAlignment = Enum.TextXAlignment.Left
ForwardLabel.Parent = ForwardFrame

-- Studs Input Textbox
local StudsInput = Instance.new("TextBox")
StudsInput.Name = "StudsInput"
StudsInput.Size = UDim2.new(0, 45, 0, 26)
StudsInput.Position = UDim2.new(1, -85, 0.5, -13)
StudsInput.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
StudsInput.BorderSizePixel = 0
StudsInput.Text = "15"
StudsInput.PlaceholderText = "Studs"
StudsInput.TextColor3 = Color3.fromRGB(0, 220, 255)
StudsInput.TextSize = 12
StudsInput.Font = Enum.Font.GothamBold
StudsInput.ClearTextOnFocus = false
StudsInput.Parent = ForwardFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = StudsInput

local InputStroke = Instance.new("UIStroke")
InputStroke.Color = Color3.fromRGB(0, 180, 255)
InputStroke.Thickness = 1
InputStroke.Transparency = 0.6
InputStroke.Parent = StudsInput

-- Forward TP Button
local ForwardBtn = Instance.new("TextButton")
ForwardBtn.Name = "ForwardBtn"
ForwardBtn.Size = UDim2.new(0, 32, 0, 26)
ForwardBtn.Position = UDim2.new(1, -36, 0.5, -13)
ForwardBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
ForwardBtn.BorderSizePixel = 0
ForwardBtn.Text = "TP"
ForwardBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ForwardBtn.TextSize = 11
ForwardBtn.Font = Enum.Font.GothamBold
ForwardBtn.AutoButtonColor = false
ForwardBtn.Parent = ForwardFrame

local ForwardBtnCorner = Instance.new("UICorner")
ForwardBtnCorner.CornerRadius = UDim.new(0, 6)
ForwardBtnCorner.Parent = ForwardBtn

-- Bottom Footer / Keybind Hint
local Footer = Instance.new("TextLabel")
Footer.LayoutOrder = 6
Footer.Size = UDim2.new(1, 0, 0, 18)
Footer.BackgroundTransparency = 1
Footer.Text = "[K] GUI Toggle  |  [L] Forward TP"
Footer.TextColor3 = Color3.fromRGB(100, 115, 140)
Footer.TextSize = 10
Footer.Font = Enum.Font.Gotham
Footer.Parent = Content


-- Helper Teleport Functions
local function teleportToSaved()
    if not savedCFrame then
        StatusText.Text = "⚠️ Erst Position setzen!"
        StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.delay(2, function()
            if not savedCFrame then
                StatusText.Text = "Keine Position gespeichert"
                StatusText.TextColor3 = Color3.fromRGB(140, 150, 175)
            end
        end)
        return false
    end

    local char = LocalPlayer.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if hrp and humanoid and humanoid.Health > 0 then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
        hrp.CFrame = savedCFrame
        return true
    end
    return false
end

local function tpForward(studs)
    studs = studs or forwardDistance
    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if hrp and humanoid and humanoid.Health > 0 then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end)
        -- Teleport forward along character facing direction
        hrp.CFrame = hrp.CFrame + (hrp.CFrame.LookVector * studs)
    end
end

-- --------------------------------------------------------------------
-- BUTTON LOGIC & INPUT CONNECTIONS
-- --------------------------------------------------------------------

-- 1. Set Location Handler
setBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hrp then
        savedCFrame = hrp.CFrame
        local pos = savedCFrame.Position
        StatusText.Text = string.format("📍 X:%.1f Y:%.1f Z:%.1f", pos.X, pos.Y, pos.Z)
        StatusText.TextColor3 = Color3.fromRGB(0, 220, 130)
        
        -- Visual flash feedback
        TweenService:Create(setStroke, TweenInfo.new(0.1), {Color = Color3.fromRGB(0, 255, 150), Transparency = 0}):Play()
        task.delay(0.2, function()
            TweenService:Create(setStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(0, 170, 255), Transparency = 0.5}):Play()
        end)
    else
        StatusText.Text = "⚠️ Character nicht gefunden!"
        StatusText.TextColor3 = Color3.fromRGB(255, 90, 90)
    end
end)

-- 2. TP Location Handler
tpBtn.MouseButton1Click:Connect(function()
    if teleportToSaved() then
        TweenService:Create(tpStroke, TweenInfo.new(0.1), {Color = Color3.fromRGB(180, 120, 255), Transparency = 0}):Play()
        task.delay(0.2, function()
            TweenService:Create(tpStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(130, 85, 245), Transparency = 0.5}):Play()
        end)
    end
end)

-- 3. Auto TP Toggle Handler
local function updateToggleVisuals(state)
    if state then
        TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 180, 120)}):Play()
        TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = UDim2.new(1, -19, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(ToggleStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(0, 220, 150), Transparency = 0.2}):Play()
    else
        TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 48, 65)}):Play()
        TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Color3.fromRGB(180, 190, 210)}):Play()
        TweenService:Create(ToggleStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(60, 70, 95), Transparency = 0.5}):Play()
    end
end

local function setAutoTp(state)
    autoTpActive = state
    updateToggleVisuals(autoTpActive)
    
    if autoTpActive then
        if not savedCFrame then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                savedCFrame = hrp.CFrame
                local pos = savedCFrame.Position
                StatusText.Text = string.format("📍 X:%.1f Y:%.1f Z:%.1f", pos.X, pos.Y, pos.Z)
                StatusText.TextColor3 = Color3.fromRGB(0, 220, 130)
            end
        end

        if autoTpThread then task.cancel(autoTpThread) end
        autoTpThread = task.spawn(function()
            while autoTpActive do
                teleportToSaved()
                task.wait(0.1)
            end
        end)
    else
        if autoTpThread then
            task.cancel(autoTpThread)
            autoTpThread = nil
        end
    end
end

SwitchBg.MouseButton1Click:Connect(function()
    setAutoTp(not autoTpActive)
end)

-- 4. Forward TP Input & Button Logic
StudsInput.FocusLost:Connect(function()
    local val = tonumber(StudsInput.Text)
    if val and val > 0 then
        forwardDistance = val
        StudsInput.Text = tostring(val)
    else
        StudsInput.Text = tostring(forwardDistance)
    end
end)

StudsInput:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(StudsInput.Text)
    if val then
        forwardDistance = val
    end
end)

ForwardBtn.MouseButton1Click:Connect(function()
    tpForward(forwardDistance)
end)

-- Minimize Button Logic
local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(UDim2.new(0, 230, 0, 36), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        Content.Visible = false
        MinimizeBtn.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 230, 0, 330), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        task.delay(0.1, function() Content.Visible = true end)
        MinimizeBtn.Text = "-"
    end
end)

-- Keybinds: [K] Toggle GUI | [L] Forward Teleport
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        MainFrame.Visible = not MainFrame.Visible
    elseif input.KeyCode == Enum.KeyCode.L then
        tpForward(forwardDistance)
    end
end)

print("[TP Location Suite] Loaded! Press 'K' to toggle UI | Press 'L' to TP Forward.")
