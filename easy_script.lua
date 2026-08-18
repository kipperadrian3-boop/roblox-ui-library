--[[
	Easy Script (easy_script.lua)
	Minimalist Movement Utility:
	  - 📜 Main Tab (Fly, FlySpeed, Noclip, Infinite Jump)
	  - 🛸 WASD Flight System (WASD + Q/E)
	  - 🏃 Noclip (Walk Through Walls)
	  - 🦘 Infinite Jump (Jump continuously in mid-air)
	  - 💾 Universal JSON Auto-Save via lib.lua Framework (Cyber Blue Theme)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with dynamic cache buster & JSON auto-save engine)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Easy Script Error] Could not load UI Library from GitHub!")
    return
end

-- Create Interface with Standard Cyber Blue Theme
local int = lib:CreateInterface("Easy Script", "Minimalist Movement & Utility Suite", "", "bottom left", "cyber", 0.25)

-- Main Tab ONLY
local mainTab = int:CreateTab("Main", "Essential Movement Controls", "player", true)

-- Configuration & State
local Config = {
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    InfiniteJumpEnabled = false
}

-- --------------------------------------------------------------------
-- 1. WASD FLIGHT SYSTEM
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
-- 2. NOCLIP LOOP
-- --------------------------------------------------------------------

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
-- 3. INFINITE JUMP
-- --------------------------------------------------------------------

UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJumpEnabled and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, hum.JumpPower or 50, hrp.Velocity.Z)
        end
    end
end)

-- --------------------------------------------------------------------
-- UI INTERFACE CREATION (MAIN TAB ONLY)
-- --------------------------------------------------------------------

mainTab:CreateComment("--- Movement & Flying ---")

mainTab:CreateToggleSwitch("WASD Flight System", false, function(val)
    Config.FlyEnabled = val
    if val then
        startFly()
        lib:Notify("Flight", "Flight Active! Controls: WASD + Q/E", 2.5)
    else
        stopFly()
        lib:Notify("Flight", "Flight Deactivated.", 1.5)
    end
end)

mainTab:CreateSlider("Fly Speed", 10, 300, 50, function(val)
    Config.FlySpeed = val
end)

mainTab:CreateToggleSwitch("Noclip (Walk Through Walls)", false, function(val)
    Config.NoclipEnabled = val
    if val then
        lib:Notify("Noclip", "Noclip Enabled!", 2.0)
    else
        lib:Notify("Noclip", "Noclip Disabled.", 1.5)
    end
end)

mainTab:CreateToggleSwitch("Infinite Jump", false, function(val)
    Config.InfiniteJumpEnabled = val
    if val then
        lib:Notify("Infinite Jump", "Infinite Jump Enabled! Press Space to jump in air.", 2.5)
    else
        lib:Notify("Infinite Jump", "Infinite Jump Disabled.", 1.5)
    end
end)

lib:Notify("Easy Script", "Loaded successfully! Press 'K' to hide or show GUI.", 5.0)
print("[Easy Script] Minimalist Movement Suite Loaded Successfully!")
