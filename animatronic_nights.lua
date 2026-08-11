--[[
    Animatronic Nights - Player ESP Script (animatronic_nights.lua)
    Features:
      - ESP Tab: Player ESP (Highlights all players in workspace in GREEN, visible through walls)
      - Customizable ESP Transparency
      - Auto-updates when players join/respawn
    Powered by Custom UI Framework (lib.lua)
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with dynamic cache buster)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Animatronic Nights Error] Could not load UI Library from GitHub!")
    return
end

-- Create Interface with Emerald Theme
local int = lib:CreateInterface("Animatronic Nights", "Player Visuals & ESP Suite", "", "bottom left", "emerald", 0.25)

local espTab = int:CreateTab("ESP", "Player Visuals", "eye", true)
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Configuration State
local Config = {
    EspEnabled = false,
    FillTransparency = 0.5,
    OutlineTransparency = 0,
    EspColor = Color3.fromRGB(0, 255, 128) -- Bright Green
}

-- Table to store active highlights
local espHighlights = {}
local playerConnections = {}

-- Function to apply Green ESP Highlight to a Character
local function applyESP(player)
    if player == LocalPlayer then return end

    local function setupChar(char)
        if not char then return end

        -- Remove existing highlight if present
        if espHighlights[player] then
            pcall(function() espHighlights[player]:Destroy() end)
            espHighlights[player] = nil
        end

        if not Config.EspEnabled then return end

        local highlight = Instance.new("Highlight")
        highlight.Name = "AnimatronicESP"
        highlight.Adornee = char
        highlight.FillColor = Config.EspColor
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = Config.FillTransparency
        highlight.OutlineTransparency = Config.OutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Visible through all walls!
        highlight.Parent = char

        espHighlights[player] = highlight
    end

    if player.Character then
        setupChar(player.Character)
    end

    if not playerConnections[player] then
        playerConnections[player] = player.CharacterAdded:Connect(function(newChar)
            task.wait(0.2)
            setupChar(newChar)
        end)
    end
end

-- Function to remove ESP from all players
local function clearAllESP()
    for player, highlight in pairs(espHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    table.clear(espHighlights)
end

-- Function to refresh ESP for all current players
local function refreshESP()
    clearAllESP()
    if Config.EspEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                applyESP(player)
            end
        end
    end
end

-- Listen for new players joining
Players.PlayerAdded:Connect(function(player)
    if Config.EspEnabled then
        applyESP(player)
    end
end)

-- Listen for players leaving
Players.PlayerRemoving:Connect(function(player)
    if espHighlights[player] then
        pcall(function() espHighlights[player]:Destroy() end)
        espHighlights[player] = nil
    end
    if playerConnections[player] then
        playerConnections[player]:Disconnect()
        playerConnections[player] = nil
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: ESP CONTROLS
-- --------------------------------------------------------------------
espTab:CreateComment("--- Player Visuals (Green ESP) ---")

espTab:CreateToggleSwitch("Enable Green Player ESP", false, function(val)
    Config.EspEnabled = val
    refreshESP()
    if val then
        lib:Notify("Animatronic ESP", "Green Player ESP Activated!", 2.0)
    else
        clearAllESP()
        lib:Notify("Animatronic ESP", "Player ESP Deactivated.", 1.5)
    end
end)

espTab:CreateSlider("Fill Transparency", 0, 100, 50, function(val)
    Config.FillTransparency = val / 100
    for _, highlight in pairs(espHighlights) do
        if highlight and highlight.Parent then
            highlight.FillTransparency = Config.FillTransparency
        end
    end
end)


-- --------------------------------------------------------------------
-- UI TAB 2: UI SETTINGS & TRANSPARENCY
-- --------------------------------------------------------------------
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)
local themesList = {"emerald", "cyber", "royal", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

print("[Animatronic Nights] Green Player ESP Script Loaded!")
