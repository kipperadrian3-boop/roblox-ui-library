--[[
    Animatronic Nights - Advanced ESP Suite (animatronic_nights.lua)
    Features:
      - Animatronic ESP (RED Highlight for Animatronics / Monsters)
      - Fuse / Green Rod / Electrical Box ESP (ORANGE Highlight for Electrical Items)
      - Player ESP (GREEN Highlight for Night Guard Players)
      - Real-Time Instance Added/Removed Listeners for Zero-Lag Instant ESP Updates
      - Full Universal JSON Auto-Save via lib.lua
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with dynamic cache buster & JSON auto-save engine)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Animatronic Nights Error] Could not load UI Library from GitHub!")
    return
end

-- Create Interface with Cyber Blue Theme
local int = lib:CreateInterface("Animatronic Nights", "ESP & Visuals Suite", "", "bottom left", "cyber", 0.25)

local espTab = int:CreateTab("ESP", "Visual Trackers", "eye", true)
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Configuration State
local Config = {
    PlayerEsp = false,
    AnimatronicEsp = false,
    ItemEsp = false,
    FillTransparency = 0.4,
    OutlineTransparency = 0
}

-- Active Highlight Containers
local playerHighlights = {}
local animatronicHighlights = {}
local itemHighlights = {}

-- Helper to create a Highlight on any instance
local function createHighlight(adornee, color, name)
    local highlight = Instance.new("Highlight")
    highlight.Name = name or "AnimatronicSuiteESP"
    highlight.Adornee = adornee
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = Config.FillTransparency
    highlight.OutlineTransparency = Config.OutlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Visible through all walls!
    highlight.Parent = adornee
    return highlight
end

-- --------------------------------------------------------------------
-- 1. PLAYER ESP (GREEN)
-- --------------------------------------------------------------------
local function applyPlayerESP(player)
    if player == LocalPlayer then return end

    local function setup(char)
        if not char then return end
        if playerHighlights[player] then
            pcall(function() playerHighlights[player]:Destroy() end)
            playerHighlights[player] = nil
        end
        if not Config.PlayerEsp then return end

        playerHighlights[player] = createHighlight(char, Color3.fromRGB(0, 255, 128), "PlayerGreenESP")
    end

    if player.Character then setup(player.Character) end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        setup(char)
    end)
end

local function refreshPlayerESP()
    for p, hl in pairs(playerHighlights) do pcall(function() hl:Destroy() end) end
    table.clear(playerHighlights)

    if Config.PlayerEsp then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then applyPlayerESP(player) end
        end
    end
end

-- --------------------------------------------------------------------
-- 2. ANIMATRONIC / MONSTER ESP (RED)
-- --------------------------------------------------------------------
local function isAnimatronicModel(obj)
    if not obj or not obj:IsA("Model") then return false end
    local name = obj.Name:lower()

    -- Check common animatronic names or model properties
    if name:find("animatronic") or name:find("monster") or name:find("freddy") or 
       name:find("bonnie") or name:find("chica") or name:find("foxy") or 
       name:find("puppet") or name:find("springtrap") or name:find("mangle") or
       name:find("killer") or name:find("bear") or name:find("rabbit") or
       name:find("duck") or name:find("fox") then
        return true
    end

    -- Check if it has a Humanoid but is NOT a human player character
    local hum = obj:FindFirstChildOfClass("Humanoid")
    if hum and not Players:GetPlayerFromCharacter(obj) then
        return true
    end

    return false
end

local function checkAndHighlightAnimatronic(obj)
    if not Config.AnimatronicEsp then return end
    if isAnimatronicModel(obj) and not animatronicHighlights[obj] then
        animatronicHighlights[obj] = createHighlight(obj, Color3.fromRGB(255, 30, 30), "AnimatronicRedESP")
    end
end

local function scanAnimatronics()
    for obj, hl in pairs(animatronicHighlights) do pcall(function() hl:Destroy() end) end
    table.clear(animatronicHighlights)

    if not Config.AnimatronicEsp then return end

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        checkAndHighlightAnimatronic(descendant)
    end
end

-- --------------------------------------------------------------------
-- 3. FUSE / GREEN ROD / ELECTRICAL BOX ESP (ORANGE)
-- --------------------------------------------------------------------
local function isFuseOrElectricalItem(obj)
    if not obj then return false end
    local name = obj.Name:lower()

    -- Check for Fuses, Green Rods, Sticks, Batteries, Generators, Electrical Boxes, Panels
    if name:find("fuse") or name:find("rod") or name:find("stick") or 
       name:find("green") or name:find("battery") or name:find("generator") or 
       name:find("box") or name:find("electric") or name:find("panel") or 
       name:find("plug") or name:find("wire") or name:find("circuit") then
        return true
    end

    -- Check ProximityPrompts or ClickDetectors inside the object for electrical terms
    for _, child in ipairs(obj:GetChildren()) do
        if child:IsA("ProximityPrompt") then
            local action = child.ActionText:lower()
            local objectText = child.ObjectText:lower()
            if action:find("fuse") or action:find("rod") or action:find("insert") or 
               objectText:find("fuse") or objectText:find("box") or objectText:find("rod") then
                return true
            end
        end
    end

    return false
end

local function checkAndHighlightItem(obj)
    if not Config.ItemEsp then return end
    if (obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Tool")) and not itemHighlights[obj] then
        if isFuseOrElectricalItem(obj) then
            itemHighlights[obj] = createHighlight(obj, Color3.fromRGB(255, 140, 0), "ItemOrangeESP")
        end
    end
end

local function scanItems()
    for obj, hl in pairs(itemHighlights) do pcall(function() hl:Destroy() end) end
    table.clear(itemHighlights)

    if not Config.ItemEsp then return end

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        checkAndHighlightItem(descendant)
    end
end

-- Real-Time Event Listener for Instant ESP on New Objects
Workspace.DescendantAdded:Connect(function(descendant)
    task.wait(0.1)
    if Config.AnimatronicEsp then
        checkAndHighlightAnimatronic(descendant)
    end
    if Config.ItemEsp then
        checkAndHighlightItem(descendant)
    end
end)

Workspace.DescendantRemoving:Connect(function(descendant)
    if animatronicHighlights[descendant] then
        pcall(function() animatronicHighlights[descendant]:Destroy() end)
        animatronicHighlights[descendant] = nil
    end
    if itemHighlights[descendant] then
        pcall(function() itemHighlights[descendant]:Destroy() end)
        itemHighlights[descendant] = nil
    end
end)

-- Backup Scanner loop every 3s
task.spawn(function()
    while true do
        task.wait(3.0)
        if Config.AnimatronicEsp then scanAnimatronics() end
        if Config.ItemEsp then scanItems() end
    end
end)

Players.PlayerAdded:Connect(function(p)
    if Config.PlayerEsp then applyPlayerESP(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    if playerHighlights[p] then pcall(function() playerHighlights[p]:Destroy() end) playerHighlights[p] = nil end
end)


-- --------------------------------------------------------------------
-- UI TAB 1: ESP CONTROLS
-- --------------------------------------------------------------------
espTab:CreateComment("--- Player & Animatronic Trackers ---")

espTab:CreateToggleSwitch("Animatronic ESP (RED)", false, function(val)
    Config.AnimatronicEsp = val
    scanAnimatronics()
    if val then
        lib:Notify("Animatronic ESP", "Red Animatronic ESP Activated!", 2.0)
    else
        for obj, hl in pairs(animatronicHighlights) do pcall(function() hl:Destroy() end) end
        table.clear(animatronicHighlights)
        lib:Notify("Animatronic ESP", "Animatronic ESP Deactivated.", 1.5)
    end
end)

espTab:CreateToggleSwitch("Fuse / Rod / Box ESP (ORANGE)", false, function(val)
    Config.ItemEsp = val
    scanItems()
    if val then
        lib:Notify("Item ESP", "Orange Fuse & Green Rod ESP Activated!", 2.0)
    else
        for obj, hl in pairs(itemHighlights) do pcall(function() hl:Destroy() end) end
        table.clear(itemHighlights)
        lib:Notify("Item ESP", "Fuse & Rod ESP Deactivated.", 1.5)
    end
end)

espTab:CreateToggleSwitch("Player ESP (GREEN)", false, function(val)
    Config.PlayerEsp = val
    refreshPlayerESP()
    if val then
        lib:Notify("Player ESP", "Green Player ESP Activated!", 2.0)
    else
        for p, hl in pairs(playerHighlights) do pcall(function() hl:Destroy() end) end
        table.clear(playerHighlights)
        lib:Notify("Player ESP", "Player ESP Deactivated.", 1.5)
    end
end)

espTab:CreateSlider("ESP Fill Transparency", 0, 100, 40, function(val)
    Config.FillTransparency = val / 100
    for _, hl in pairs(playerHighlights) do if hl then hl.FillTransparency = Config.FillTransparency end end
    for _, hl in pairs(animatronicHighlights) do if hl then hl.FillTransparency = Config.FillTransparency end end
    for _, hl in pairs(itemHighlights) do if hl then hl.FillTransparency = Config.FillTransparency end end
end)


-- --------------------------------------------------------------------
-- UI TAB 2: UI SETTINGS & TRANSPARENCY
-- --------------------------------------------------------------------
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)
local themesList = {"cyber", "emerald", "royal", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

print("[Animatronic Nights] Advanced Real-Time ESP Suite (Red Animatronics, Orange Fuses/Green Rods, Green Players) Loaded!")
