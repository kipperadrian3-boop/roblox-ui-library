--[[
    Keyboard Escape - Custom Script Suite (keyboard_escape.lua)
    Features: Summer Coins Auto Farm (Teleports to Workspace.SummerCoinsLocal.SummerCoin every 1s)
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

local int = lib:CreateInterface("Keyboard Escape", "Summer Coins Auto Farm Suite", "", "bottom left", "royal", 0.25)

local farmTab = int:CreateTab("Farm", "Coin Farming Utilities", "item", true)
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Config State
local Config = {
    SummerCoinsFarm = false
}

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
-- UI CONTROLS
-- --------------------------------------------------------------------
farmTab:CreateToggleSwitch("Summer Coins Farm", false, function(val)
    Config.SummerCoinsFarm = val
    if val then
        lib:Notify("Keyboard Escape", "Summer Coins Farm Started!", 1.5)
    else
        lib:Notify("Keyboard Escape", "Summer Coins Farm Stopped.", 1.5)
    end
end)

-- UI Settings
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

print("[Keyboard Escape Suite] Loaded Successfully!")
