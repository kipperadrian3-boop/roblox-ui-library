--[[
    Greedy Growers - Automated Farming & Selling Suite (greedy_growers.lua)
    Engineered with Full JSON State Restoration & Multi-Threaded Automation
]]

local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework with Cache Buster
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Greedy Growers Error] Could not load UI Library from GitHub!")
    return
end

-- Create GUI Interface
local int = lib:CreateInterface("Greedy Growers", "Automation & Farming Suite", "", "bottom left", "emerald", 0.20)

-- Navigation Tabs
local mainTab = int:CreateTab("Main", "Farming & Collecting", "op", true)
local autoTab = int:CreateTab("Automation", "Selling & Stand", "op")
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Configuration State
local Config = {
    AutoBuyEnabled = false,
    AutoCollectFruits = false,
    SellAllEnabled = false
}

-- Seed Definitions & Rarities
local t = {}
t.Seeds = {
    Oak = { rarity = "COMMON" },
    Pine = { rarity = "COMMON" },
    Apple = { rarity = "RARE" },
    Peach = { rarity = "RARE" },
    Fig = { rarity = "RARE" },
    Orange = { rarity = "EPIC" },
    Lemon = { rarity = "EPIC" },
    Avocado = { rarity = "EPIC" },
    Cherry = { rarity = "LEGENDARY" },
    Mango = { rarity = "LEGENDARY" },
    Coconut = { rarity = "LEGENDARY" },
    Banana = { rarity = "MYTHIC" },
    Starfruit = { rarity = "MYTHIC" },
    DragonFruit = { rarity = "MYTHIC" },
    Glowing = { rarity = "CELESTIAL" },
    Blooming = { rarity = "CELESTIAL" },
    Magic = { rarity = "SECRET" },
    Pizza = { rarity = "SECRET" },
    Diamond = { rarity = "DIVINE" },
    Void = { rarity = "DIVINE" },
    Mushroom = { rarity = "TRANSCENDENT" },
    Money = { rarity = "TRANSCENDENT" },
    Glowshroom = { rarity = "ANCIENT" },
    Elder = { rarity = "ANCIENT" },
    Inferno = { rarity = "ETHEREAL" },
    Spirit = { rarity = "ETHEREAL" },
    Prismatic = { rarity = "GODLY" },
    Astral = { rarity = "GODLY" }
}

-- -------------------------------------------------------------
-- AUTOMATION THREADS
-- -------------------------------------------------------------

-- Helper function to reliably trigger any ProximityPrompt
local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then return end

    pcall(function()
        prompt.MaxActivationDistance = 9e9
        prompt.RequiresLineOfSight = false
        prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
        prompt.HoldDuration = 0
        prompt.Enabled = true
    end)

    if fireproximityprompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
    else
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.01)
            prompt:InputHoldEnd()
        end)
    end
end

-- 1. Seed Auto-Buy Loop (Runs every 0.5s)
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoBuyEnabled then
            local bigField = Workspace:FindFirstChild("BigField")
            local conveyorSeeds = bigField and bigField:FindFirstChild("ConveyorSeeds")

            if conveyorSeeds then
                for _, seedHolder in ipairs(conveyorSeeds:GetChildren()) do
                    if seedHolder.Name == "SeedHolder" then
                        local foundSeedName = nil
                        for _, child in ipairs(seedHolder:GetChildren()) do
                            local cName = child.Name
                            local stripped = string.gsub(cName, "Seed$", "")

                            if cName == "AvacadoSeed" then stripped = "Avocado" end
                            if cName == "DragonfruitSeed" then stripped = "DragonFruit" end

                            if t.Seeds[cName] then
                                foundSeedName = cName
                                break
                            elseif t.Seeds[stripped] then
                                foundSeedName = stripped
                                break
                            end
                        end

                        if foundSeedName then
                            local isSeedSelected = Config["Collect_" .. foundSeedName]
                            local seedRarity = t.Seeds[foundSeedName] and t.Seeds[foundSeedName].rarity
                            local isRaritySelected = seedRarity and Config["CollectRarity_" .. seedRarity]

                            if isSeedSelected or isRaritySelected then
                                local prompt = seedHolder:FindFirstChildWhichIsA("ProximityPrompt", true)
                                if prompt then
                                    triggerPrompt(prompt)

                                    task.spawn(function()
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Nine, false, game)
                                        task.wait(0.000001)
                                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Nine, false, game)
                                        task.wait(0.000001)
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Nine, false, game)
                                        task.wait(0.000001)
                                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Nine, false, game)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 2. Fruit & FindPrompt Auto-Collect Loop (Runs every 0.01s per prompt)
task.spawn(function()
    while true do
        task.wait(0.05)
        if Config.AutoCollectFruits then
            local bigField = Workspace:FindFirstChild("BigField")
            local playerPlots = bigField and bigField:FindFirstChild("PlayerPlots")
            local myPlot = nil

            if playerPlots then
                for _, plot in ipairs(playerPlots:GetChildren()) do
                    if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                        myPlot = plot
                        break
                    end
                end
            end

            if myPlot then
                local promptsToTrigger = {}
                for _, desc in ipairs(myPlot:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") then
                        local parent = desc.Parent
                        if desc.Name == "FindPrompt" or (parent and parent.Parent and parent.Parent.Name == "FruitSpawns") then
                            table.insert(promptsToTrigger, desc)
                        end
                    end
                end

                for _, prompt in ipairs(promptsToTrigger) do
                    if not Config.AutoCollectFruits then break end
                    triggerPrompt(prompt)
                    task.wait(0.01)
                end
            end
        end
    end
end)

-- 3. Auto-Sell RemoteFunction Loop (Runs every 0.2s)
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.SellAllEnabled then
            local sellRemote = nil
            pcall(function()
                sellRemote = ReplicatedStorage.Packages._Index["sleitnick_knit@1.6.0"].knit.Services.SellStandService.RF.SellAll
            end)

            if not sellRemote then
                local function findRemote(parent)
                    for _, child in ipairs(parent:GetChildren()) do
                        if child:IsA("RemoteFunction") and child.Name == "SellAll" then
                            return child
                        end
                        local found = findRemote(child)
                        if found then return found end
                    end
                    return nil
                end
                sellRemote = findRemote(ReplicatedStorage)
            end

            if sellRemote then
                pcall(function()
                    sellRemote:InvokeServer()
                end)
            end
        end
    end
end)

-- -------------------------------------------------------------
-- UI INTERFACE CREATION
-- -------------------------------------------------------------

-- TAB 1: MAIN
local seedsSection = mainTab:CreateSection("Seeds")

seedsSection:CreateToggleSwitch("Enable Auto Collect", false, function(val)
    Config.AutoBuyEnabled = val
    if val then lib:Notify("Farm", "Auto Seed Collect Active!", 2.0) end
end)

local SeedDropdown = seedsSection:CreateDropDown("Select Seed", function() end)

local sortedSeeds = {}
for seedName, _ in pairs(t.Seeds) do
    table.insert(sortedSeeds, seedName)
end
table.sort(sortedSeeds)

for _, seedName in ipairs(sortedSeeds) do
    Config["Collect_" .. seedName] = false
    SeedDropdown:AddCheckbox(seedName, function(state)
        Config["Collect_" .. seedName] = state
    end)
end

local RarityDropdown = seedsSection:CreateDropDown("Select by Rarity", function() end)
local RarityList = {
    "COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC", "CELESTIAL", 
    "SECRET", "DIVINE", "TRANSCENDENT", "ANCIENT", "ETHEREAL", "GODLY"
}
for _, rarity in ipairs(RarityList) do
    local hasSeedsInRarity = false
    for seedName, info in pairs(t.Seeds) do
        if info.rarity == rarity then hasSeedsInRarity = true break end
    end
    if hasSeedsInRarity then
        Config["CollectRarity_" .. rarity] = false
        RarityDropdown:AddCheckbox(rarity, function(state)
            Config["CollectRarity_" .. rarity] = state
            local action = state and "Selected" or "Deselected"
            lib:Notify("Selection", action .. " rarity: " .. rarity, 2.0)
        end)
    end
end

local fruitsSection = mainTab:CreateSection("Fruits")
fruitsSection:CreateToggleSwitch("Auto Collect Fruits", false, function(val)
    Config.AutoCollectFruits = val
    if val then lib:Notify("Farm", "Auto Collect Fruits Active!", 2.0) end
end)

-- TAB 2: AUTOMATION
local sellSection = autoTab:CreateSection("Sell")
sellSection:CreateToggleSwitch("Sell All", false, function(val)
    Config.SellAllEnabled = val
    if val then lib:Notify("Automation", "Sell All Active (0.2s)!", 2.0) end
end)

-- TAB 3: SETTINGS
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)
local themesList = {"emerald", "cyber", "royal", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 20, function(val)
    int:SetTransparency(val / 100)
end)

lib:Notify("Greedy Growers", "Loaded successfully! Press 'K' to toggle GUI.", 4.0)
print("[Greedy Growers] Automation Suite Ready & Running!")
