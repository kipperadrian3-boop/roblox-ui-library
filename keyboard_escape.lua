--[[
    Keyboard Escape - Custom Script Suite (keyboard_escape.lua)
    Features: Summer Coins Auto Farm & Player Tab (WalkSpeed 0-500, JumpPower 0-500)
    Powered by Custom UI Framework (lib.lua)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua"))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Keyboard Escape Error] Could not load UI Library from GitHub!")
    return
end

local int = lib:CreateInterface("Keyboard Escape", "Summer Coins & Player Utilities", "", "bottom left", "royal", 0.25)

local farmTab = int:CreateTab("Farm", "Coin Farming Utilities", "item", true)
local playerTab = int:CreateTab("Player", "Movement & Speed Controls", "player")
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Config State
local Config = {
    SummerCoinsFarm = false,
    WalkSpeed = 16,
    JumpPower = 50,
    ModifySpeed = false,
    ModifyJump = false
}

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
-- SUMMER COINS FARM LOOP (Teleports every 1 second)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(1)
        if Config.SummerCoinsFarm then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local coinsFolder = Workspace:FindFirstChild("SummerCoinsLocal")
                if coinsFolder then
                    for _, item in ipairs(coinsFolder:GetChildren()) do
                        if not Config.SummerCoinsFarm then break end
                        if item.Name == "SummerCoin" then
                            local targetCF = item:IsA("Model") and item:GetPivot() or (item:IsA("BasePart") and item.CFrame)
                            if targetCF then
                                hrp.CFrame = targetCF + Vector3.new(0, 2, 0)
                                task.wait(1)
                            end
                        end
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: FARM CONTROLS
-- --------------------------------------------------------------------
farmTab:CreateToggleSwitch("Summer Coins Farm", false, function(val)
    Config.SummerCoinsFarm = val
    if val then
        lib:Notify("Keyboard Escape", "Summer Coins Farm Started!", 1.5)
    else
        lib:Notify("Keyboard Escape", "Summer Coins Farm Stopped.", 1.5)
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 2: PLAYER CONTROLS (WalkSpeed 0-500 & JumpPower 0-500)
-- --------------------------------------------------------------------
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

print("[Keyboard Escape Suite] Player Frame Loaded!")
