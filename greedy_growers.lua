--[[
    Greedy Growers - Auto Seed Buyer (greedy_growers.lua)
    Universal JSON Engine Auto-Save Enabled
]]

local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with dynamic cache buster & JSON auto-save engine)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Greedy Growers Error] Could not load UI Library from GitHub!")
    return
end

-- Create Interface
local int = lib:CreateInterface("Greedy Growers", "Auto Seed Collection", "", "bottom left", "emerald", 0.25)

-- Tabs
local mainTab = int:CreateTab("Main", "Auto Collection", "op", true)
local autoTab = int:CreateTab("Automation", "Farming & Selling", "op")
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")

-- Configuration State (JSON Auto-Saved by lib.lua)
local Config = {
    AutoBuyEnabled = false
}

-- Seed Config
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

-- Auto Collect Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoBuyEnabled then
            local bigField = Workspace:FindFirstChild("BigField")
            local conveyorSeeds = bigField and bigField:FindFirstChild("ConveyorSeeds")
            
            if not conveyorSeeds then
                continue
            end
            
            -- Suche durch alle Kinder in ConveyorSeeds
            for _, seedHolder in ipairs(conveyorSeeds:GetChildren()) do
                if seedHolder.Name == "SeedHolder" then
                    -- Finde heraus, welcher Seed in diesem Holder ist
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
                        -- Check against the UI state tracked in Config table
                        local isSeedSelected = Config["Collect_" .. foundSeedName]
                        local seedRarity = t.Seeds[foundSeedName] and t.Seeds[foundSeedName].rarity
                        local isRaritySelected = seedRarity and Config["CollectRarity_" .. seedRarity]
                        
                        if isSeedSelected or isRaritySelected then
                            local prompt = seedHolder:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                else
                                    prompt.MaxActivationDistance = 9e9
                                    prompt.RequiresLineOfSight = false
                                    prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
                                    prompt:InputHoldBegin()
                                    task.wait(prompt.HoldDuration + 0.05)
                                    prompt:InputHoldEnd()
                                end
                                
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
end)

-- Auto Collect Fruits Loop
task.spawn(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    while true do
        task.wait(0.01)
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
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    else
                        prompt.MaxActivationDistance = 9e9
                        prompt.RequiresLineOfSight = false
                        prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration + 0.05)
                        prompt:InputHoldEnd()
                    end
                    task.wait(0.01)
                end
            end
        end
    end
end)


-- Auto Sell Loop
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
                        if child:IsA("RemoteFunction") and child.Name == "SellAll" then return child end
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

-- UI INTERFACE CREATION
-- TAB: MAIN
local seedsSection = mainTab:CreateSection("Seeds")

seedsSection:CreateToggleSwitch("Enable Auto Collect", false, function(val)
    Config.AutoBuyEnabled = val
    if val then lib:Notify("Farm", "Auto Collect Active!", 2.0) end
end)

local SeedCheckboxes = {}
local SeedDropdown = seedsSection:CreateDropDown("Select Seed", function() end)

local sortedSeeds = {}
for seedName, _ in pairs(t.Seeds) do
    table.insert(sortedSeeds, seedName)
end
table.sort(sortedSeeds)

for _, seedName in ipairs(sortedSeeds) do
    Config["Collect_" .. seedName] = false
    local chk = SeedDropdown:AddCheckbox(seedName, function(state)
        Config["Collect_" .. seedName] = state
    end)
    SeedCheckboxes[seedName] = chk
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

-- TAB: AUTOMATION
local sellSection = autoTab:CreateSection("Sell")
sellSection:CreateToggleSwitch("Sell All", false, function(val)
    Config.SellAllEnabled = val
    if val then lib:Notify("Farm", "Sell All Active!", 2.0) end
end)

-- TAB: SETTINGS
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

lib:Notify("Greedy Growers", "Loaded successfully! Press 'K' to hide or show GUI.", 5.0)
print("[Greedy Growers] Auto Seed Collection Loaded Successfully!")
