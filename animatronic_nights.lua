--[[
    Animatronic Nights - Advanced ESP & Automation Suite (animatronic_nights.lua)
    Features:
      - Automation Tab: Auto-Insert Green Rods into Fuse Box (Fires ProximityPrompts within range)
      - Animatronic ESP (RED Solid Highlight for all Monsters/Killers/Animatronics)
      - Green Rods & Fuse Box ESP (ORANGE Solid Fill ONLY for Green Rods & Fuse Boxes)
      - Player ESP (GREEN Highlight for Night Guard Players)
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
local int = lib:CreateInterface("Animatronic Nights", "ESP & Automation Suite", "", "bottom left", "cyber", 0.25)

local espTab = int:CreateTab("ESP", "Visual Trackers", "eye", true)
local autoTab = int:CreateTab("Automation", "Auto Fix & Fuse Utilities", "misc")
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Configuration State
local Config = {
    PlayerEsp = false,
    AnimatronicEsp = false,
    ItemEsp = false,
    AutoInsertRods = false,
    AutoInsertRadius = 15, -- Studs range for auto-inserting
    FillTransparency = 0.2, -- Solid vibrant fill
    OutlineTransparency = 1 -- NO stroke outline clutter!
}

-- Active Highlight Containers
local playerHighlights = {}
local animatronicHighlights = {}
local itemHighlights = {}

-- Helper to create a Solid Highlight on any instance (No stroke outline clutter)
local function createHighlight(adornee, color, name)
    local highlight = Instance.new("Highlight")
    highlight.Name = name or "AnimatronicSuiteESP"
    highlight.Adornee = adornee
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = Config.FillTransparency
    highlight.OutlineTransparency = Config.OutlineTransparency -- 1 = No stroke outline
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Visible through all walls!
    highlight.Parent = adornee
    return highlight
end

-- --------------------------------------------------------------------
-- 1. AUTOMATION: AUTO-INSERT GREEN RODS INTO FUSE BOX
-- --------------------------------------------------------------------
local function fireProximityPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            -- Fallback: Trigger input directly
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end
    end)
end

-- Loop to check nearby Fuse Boxes / Electrical Panels and auto-insert Green Rods
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.AutoInsertRods then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                for _, descendant in ipairs(Workspace:GetDescendants()) do
                    if not Config.AutoInsertRods then break end

                    if descendant:IsA("ProximityPrompt") then
                        local actionText = descendant.ActionText:lower()
                        local objectText = descendant.ObjectText:lower()

                        -- Match Fuse Box / Green Rod insertion prompts
                        if actionText:find("insert") or actionText:find("rod") or actionText:find("fuse") or actionText:find("fix") or
                           objectText:find("fuse") or objectText:find("box") or objectText:find("rod") or objectText:find("sicherung") then
                            
                            local parentPart = descendant.Parent
                            if parentPart and parentPart:IsA("BasePart") then
                                local dist = (hrp.Position - parentPart.Position).Magnitude
                                if dist <= Config.AutoInsertRadius then
                                    fireProximityPrompt(descendant)
                                    lib:Notify("Auto-Insert", "Inserted Green Rod into Fuse Box!", 1.5)
                                    task.wait(0.3)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- 2. PLAYER ESP (GREEN)
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
-- 3. ANIMATRONIC / KILLER ESP (RED)
-- --------------------------------------------------------------------
local function isAnimatronicKiller(obj)
    if not obj then return false end
    if not (obj:IsA("Model") or obj:IsA("Folder")) then return false end

    local name = obj.Name:lower()
    local parentName = obj.Parent and obj.Parent.Name:lower() or ""

    if Players:GetPlayerFromCharacter(obj) then return false end

    if name:find("animatronic") or name:find("killer") or name:find("monster") or 
       name:find("bot") or name:find("npc") or name:find("freddy") or 
       name:find("bonnie") or name:find("chica") or name:find("foxy") or 
       name:find("puppet") or name:find("springtrap") or name:find("mangle") or
       name:find("bear") or name:find("rabbit") or name:find("fox") or
       name:find("duck") or name:find("endo") or name:find("entity") or
       parentName:find("animatronic") or parentName:find("killer") or parentName:find("monster") then
        return true
    end

    local hum = obj:FindFirstChildOfClass("Humanoid") or obj:FindFirstChildOfClass("AnimationController")
    if hum and not Players:GetPlayerFromCharacter(obj) then
        if obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj:FindFirstChild("Torso") then
            return true
        end
    end

    return false
end

local function checkAndHighlightAnimatronic(obj)
    if not Config.AnimatronicEsp then return end
    if isAnimatronicKiller(obj) and not animatronicHighlights[obj] then
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
-- 4. GREEN RODS & FUSE BOX ESP ONLY (ORANGE SOLID FILL)
-- --------------------------------------------------------------------
local function isGreenRodOrFuseBox(obj)
    if not obj then return false end
    local name = obj.Name:lower()

    if name:find("green") or name:find("rod") or name:find("stäbchen") or 
       name:find("fusebox") or name:find("fuse_box") or name:find("sicherung") or 
       name:find("fuse box") or (name:find("fuse") and name:find("box")) then
        return true
    end

    for _, child in ipairs(obj:GetChildren()) do
        if child:IsA("ProximityPrompt") then
            local action = child.ActionText:lower()
            local objectText = child.ObjectText:lower()
            if action:find("rod") or action:find("green") or action:find("fuse box") or 
               objectText:find("rod") or objectText:find("green") or objectText:find("fuse box") or
               objectText:find("sicherung") then
                return true
            end
        end
    end

    return false
end

local function checkAndHighlightItem(obj)
    if not Config.ItemEsp then return end
    if (obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Tool")) and not itemHighlights[obj] then
        if isGreenRodOrFuseBox(obj) then
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
    task.wait(0.05)
    if Config.AnimatronicEsp then checkAndHighlightAnimatronic(descendant) end
    if Config.ItemEsp then checkAndHighlightItem(descendant) end
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

-- Backup Scanner loop every 2s
task.spawn(function()
    while true do
        task.wait(2.0)
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
espTab:CreateComment("--- Trackers & Visual Highlights ---")

espTab:CreateToggleSwitch("Animatronic / Killer ESP (RED)", false, function(val)
    Config.AnimatronicEsp = val
    scanAnimatronics()
    if val then
        lib:Notify("Animatronic ESP", "Red Killer ESP Activated!", 2.0)
    else
        for obj, hl in pairs(animatronicHighlights) do pcall(function() hl:Destroy() end) end
        table.clear(animatronicHighlights)
        lib:Notify("Animatronic ESP", "Killer ESP Deactivated.", 1.5)
    end
end)

espTab:CreateToggleSwitch("Green Rods & Fuse Box ESP (ORANGE)", false, function(val)
    Config.ItemEsp = val
    scanItems()
    if val then
        lib:Notify("Fuse ESP", "Orange Green Rods & Fuse Box ESP Activated!", 2.0)
    else
        for obj, hl in pairs(itemHighlights) do pcall(function() hl:Destroy() end) end
        table.clear(itemHighlights)
        lib:Notify("Fuse ESP", "Fuse Box ESP Deactivated.", 1.5)
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

espTab:CreateSlider("ESP Fill Transparency", 0, 100, 20, function(val)
    Config.FillTransparency = val / 100
    for _, hl in pairs(playerHighlights) do if hl then hl.FillTransparency = Config.FillTransparency end end
    for _, hl in pairs(animatronicHighlights) do if hl then hl.FillTransparency = Config.FillTransparency end end
    for _, hl in pairs(itemHighlights) do if hl then hl.FillTransparency = Config.FillTransparency end end
end)


-- --------------------------------------------------------------------
-- UI TAB 2: AUTOMATION CONTROLS (AUTO-INSERT GREEN RODS)
-- --------------------------------------------------------------------
autoTab:CreateComment("--- Fuse Box Automation ---")

autoTab:CreateToggleSwitch("Auto-Insert Green Rods into Fuse Box", false, function(val)
    Config.AutoInsertRods = val
    if val then
        lib:Notify("Automation", "Auto-Insert Green Rods Active!", 2.0)
    else
        lib:Notify("Automation", "Auto-Insert Stopped.", 1.5)
    end
end)

autoTab:CreateSlider("Auto-Insert Range (Studs)", 5, 40, 15, function(val)
    Config.AutoInsertRadius = val
end)


-- --------------------------------------------------------------------
-- UI TAB 3: UI SETTINGS & TRANSPARENCY
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

print("[Animatronic Nights] Automation & ESP Suite Loaded!")
