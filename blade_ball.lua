--[[
    Blade Ball - Safe Clean Auto Parry (blade_ball.lua)
    Minimalist, Humanized Auto Parry powered by lib.lua
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

local int = lib:CreateInterface("Blade Ball Safe", "Minimal Humanized Auto Parry", "", "bottom left", "royal", 0.2)

local mainTab = int:CreateTab("Auto Parry", "Safe Auto Deflect", "item", true)
local settingsTab = int:CreateTab("Settings", "UI Appearance", "misc")

-- Configuration State
local Config = {
    Enabled = false,
    ParryDistance = 25,
    HumanDelay = 35, -- ms
    LastParry = 0
}

local function getActiveBall()
    local balls = Workspace:FindFirstChild("Balls")
    if balls then
        for _, ball in ipairs(balls:GetChildren()) do
            if ball:IsA("BasePart") and (ball:GetAttribute("realBall") == true or ball:GetAttribute("target") ~= nil) then
                return ball
            end
        end
    end
    return nil
end

-- Humanized Keyboard Parry (Simulates natural key press)
local function pressParryKey()
    local now = tick()
    if now - Config.LastParry < 0.15 then return end -- Enforce minimum 150ms cooldown between parries
    Config.LastParry = now

    task.spawn(function()
        if Config.HumanDelay > 0 then
            task.wait(math.random(Config.HumanDelay - 5, Config.HumanDelay + 10) / 1000)
        end
        pcall(function()
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, true, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyPressEvent(Enum.KeyCode.F, false, game)
        end)
    end)
end

-- RenderStepped Detection Loop
RunService.RenderStepped:Connect(function()
    if not Config.Enabled then return end

    pcall(function()
        local ball = getActiveBall()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if ball and hrp then
            local isTargetingMe = (ball:GetAttribute("target") == LocalPlayer.Name)

            if isTargetingMe then
                local distance = (ball.Position - hrp.Position).Magnitude
                local speed = math.max(ball.AssemblyLinearVelocity.Magnitude, 1)

                -- Calculate safe distance threshold taking ball speed into account
                local dynamicThreshold = math.clamp(Config.ParryDistance + (speed * 0.08), 15, 80)

                if distance <= dynamicThreshold then
                    pressParryKey()
                end
            end
        end
    end)
end)

-- --------------------------------------------------------------------
-- UI CONTROLS
-- --------------------------------------------------------------------
mainTab:CreateToggleSwitch("Enable Safe Auto Parry", false, function(val)
    Config.Enabled = val
    if val then
        lib:Notify("Auto Parry", "Safe Auto Parry Enabled!", 1.5)
    else
        lib:Notify("Auto Parry", "Auto Parry Disabled.", 1.5)
    end
end)

mainTab:CreateSlider("Parry Distance", 15, 60, 25, function(val)
    Config.ParryDistance = val
end)

mainTab:CreateSlider("Human Delay (ms)", 0, 80, 35, function(val)
    Config.HumanizeDelay = val
end)

-- UI Settings
local themeDrop = settingsTab:CreateDropDown("Select Theme", function() end)
local themesList = {"royal", "cyber", "emerald", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 20, function(val)
    int:SetTransparency(val / 100)
end)

print("[Blade Ball Safe Parry] Active & Clean!")
