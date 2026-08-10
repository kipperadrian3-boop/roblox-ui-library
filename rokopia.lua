--[[
    Rokopia - Custom Script Suite (rokopia.lua)
    Features: 
      - Troll Tab: Perfect 5x5 Void Hole Digger (Clears 5x5 area from top Y down to bedrock/void Y = -64)
      - Character TP directly above targeted block for 100% hit accuracy and zero distance kicks
      - Options for 1x1, 3x3, and 5x5 Void Holes
      - Player Tab: WalkSpeed (0-500), JumpPower (0-500), Fly (0-300), Noclip
    Powered by Custom UI Framework (lib.lua)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with dynamic cache buster)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Rokopia Suite Error] Could not load UI Library from GitHub!")
    return
end

local int = lib:CreateInterface("Rokopia Suite", "Void Digger & Movement Suite", "", "bottom left", "royal", 0.25)

local trollTab = int:CreateTab("Troll", "Void Digger & Pitfalls", "item", true)
local playerTab = int:CreateTab("Player", "Movement & Speed Controls", "player")
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Configuration State
local Config = {
    RandomHoles = false,
    HoleSize = 2, -- 0 = 1x1, 1 = 3x3, 2 = 5x5
    HoleRadius = 20,
    HitsPerBlock = 14, -- High hit count to guarantee 100% destruction of stone/altar stone
    CooldownSpeed = 0.01, -- 10ms delay
    WalkSpeed = 16,
    JumpPower = 50,
    ModifySpeed = false,
    ModifyJump = false,
    Flying = false,
    FlySpeed = 50,
    Noclip = false
}

-- Fly Physics State
local flyBV = nil
local flyBG = nil
local renderConnection = nil
local noclipConnection = nil

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

-- Noclip Loop
noclipConnection = RunService.Stepped:Connect(function()
    if Config.Noclip then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- Apply Player Speed & Jump Modifiers
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
    if Config.Flying then startFly() end
end)

-- Fetch BreakBlock Remote Function
local function getBreakBlockRemote()
    local remoteFuncFolder = ReplicatedStorage:FindFirstChild("RemoteFunction")
    if remoteFuncFolder then
        return remoteFuncFolder:FindFirstChild("BreakBlock")
    end
    return nil
end

-- Teleport Character Directly Above Target Block & Anchor
local function positionCharacterForBlock(blockX, blockY, blockZ)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local targetWorldPos = Vector3.new(blockX * 4.2, (blockY + 1.8) * 4.2, blockZ * 4.2)
        hrp.CFrame = CFrame.new(targetWorldPos)
        hrp.Anchored = true
        task.wait(0.005)
    end
end

-- Unanchor Character
local function unanchorCharacter()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
    end
end

-- Safely break a block by teleporting character directly over it and hitting up to max durability
local function destroyTargetBlock(targetX, targetY, targetZ)
    if not Config.RandomHoles then return false end

    local breakRemote = getBreakBlockRemote()
    if not breakRemote then return false end

    -- 1. Teleport player directly on top of the target block
    positionCharacterForBlock(targetX, targetY, targetZ)

    local key = string.format("%d,%d,%d", targetX, targetY, targetZ)

    -- 2. Repeatedly hit the block to guarantee complete removal down to void
    for hit = 1, Config.HitsPerBlock do
        if not Config.RandomHoles then break end

        -- Send 1 damage hit per call (SELECTION_MAX_BLOCKS = 1 for anti-cheat safety)
        local res = breakRemote:InvokeServer({ key })
        task.wait(Config.CooldownSpeed)

        -- If server returned false (block fully removed / empty), stop hitting
        if res == false then
            break
        end
    end

    return true
end


-- --------------------------------------------------------------------
-- PERFECT VOID DIGGER ENGINE (Clears area layer-by-layer down to Y = -64)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.RandomHoles then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                -- 1. Pick a random hole center point within search radius
                local playerPos = hrp.Position
                local pX = math.floor(playerPos.X / 4.2)
                local pY = math.floor(playerPos.Y / 4.2)
                local pZ = math.floor(playerPos.Z / 4.2)

                local maxRadiusBlocks = math.clamp(math.floor(Config.HoleRadius / 4.2), 1, 5)
                local randOffsetX = math.random(-maxRadiusBlocks, maxRadiusBlocks)
                local randOffsetZ = math.random(-maxRadiusBlocks, maxRadiusBlocks)
                local centerX = pX + randOffsetX
                local centerZ = pZ + randOffsetZ

                -- Start digging from high Y (above houses/trees) down to Bedrock/Void (Y = -64)
                local startY = math.min(pY + 6, 32)
                local endY = -64

                local halfSize = Config.HoleSize -- 0 for 1x1, 1 for 3x3, 2 for 5x5

                -- 2. Clear entire area layer-by-layer from top Y down to -64
                for y = startY, endY, -1 do
                    if not Config.RandomHoles then break end

                    for dx = -halfSize, halfSize do
                        for dz = -halfSize, halfSize do
                            if not Config.RandomHoles then break end

                            local targetX = centerX + dx
                            local targetZ = centerZ + dz

                            -- Teleport character directly over block and break it completely
                            destroyTargetBlock(targetX, y, targetZ)
                        end
                    end
                end

                -- Unanchor after finishing void hole
                unanchorCharacter()
                task.wait(0.2)
            end)
        else
            unanchorCharacter()
        end
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: TROLL CONTROLS (Void Digger)
-- --------------------------------------------------------------------
trollTab:CreateToggleSwitch("Build Void Hole", false, function(val)
    Config.RandomHoles = val
    if val then
        lib:Notify("Rokopia Troll", "Void Digger Active! Digging down to Y = -64...", 2.0)
    else
        unanchorCharacter()
        lib:Notify("Rokopia Troll", "Void Digger Stopped.", 1.5)
    end
end)

local sizeDrop = trollTab:CreateDropDown("Hole Matrix Size", function() end)
sizeDrop:AddButton("1x1 Single Shaft Hole", function()
    Config.HoleSize = 0
    lib:Notify("Hole Size", "Set to 1x1 Single Shaft", 1.5)
end)
sizeDrop:AddButton("3x3 Medium Void Hole", function()
    Config.HoleSize = 1
    lib:Notify("Hole Size", "Set to 3x3 Medium Hole", 1.5)
end)
sizeDrop:AddButton("5x5 Large Void Hole", function()
    Config.HoleSize = 2
    lib:Notify("Hole Size", "Set to 5x5 Large Hole", 1.5)
end)

trollTab:CreateSlider("Cooldown Delay (ms)", 10, 200, 10, function(val)
    Config.CooldownSpeed = val / 1000
end)

trollTab:CreateSlider("Max Hits Per Block", 1, 14, 14, function(val)
    Config.HitsPerBlock = val
end)

trollTab:CreateSlider("Search Radius (Studs)", 5, 30, 20, function(val)
    Config.HoleRadius = val
end)


-- --------------------------------------------------------------------
-- UI TAB 2: PLAYER CONTROLS (WalkSpeed, JumpPower, Fly & Noclip)
-- --------------------------------------------------------------------
playerTab:CreateToggleSwitch("Enable Fly", false, function(val)
    Config.Flying = val
    if val then
        startFly()
        lib:Notify("Player", "Fly Activated! WASD + Space/Shift", 2)
    else
        stopFly()
        lib:Notify("Player", "Fly Deactivated.", 1.5)
    end
end)

playerTab:CreateSlider("Fly Speed (0 - 300)", 0, 300, 50, function(val)
    Config.FlySpeed = val
end)

playerTab:CreateToggleSwitch("Enable Noclip", false, function(val)
    Config.Noclip = val
    if val then
        lib:Notify("Player", "Noclip Activated!", 1.5)
    else
        lib:Notify("Player", "Noclip Deactivated.", 1.5)
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

print("[Rokopia Suite] Perfect Void Digger & Movement Suite Loaded!")
