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
local collectTab = int:CreateTab("Auto Collect", "Conveyor Belt Automation", "op", true)
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
                        if Config["Collect_" .. foundSeedName] then
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

-- UI INTERFACE CREATION

collectTab:CreateComment("--- Main Toggle ---")
collectTab:CreateToggleSwitch("Enable Auto Collect", false, function(val)
    Config.AutoBuyEnabled = val
    if val then lib:Notify("Farm", "Auto Collect Active!", 2.0) end
end)

collectTab:CreateComment("--- Seed Selection ---")
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
        collectTab:CreateComment("Rarity: " .. rarity)
        local sortedSeeds = {}
        for seedName, info in pairs(t.Seeds) do
            if info.rarity == rarity then table.insert(sortedSeeds, seedName) end
        end
        table.sort(sortedSeeds)
        
        for _, seedName in ipairs(sortedSeeds) do
            Config["Collect_" .. seedName] = false
            collectTab:CreateToggleSwitch("Collect " .. seedName, false, function(val)
                Config["Collect_" .. seedName] = val
            end)
        end
    end
end

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
