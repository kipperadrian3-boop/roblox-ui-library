--[[
    Greedy Growers - Auto Seed Buyer (greedy_growers.lua)
    Obsidian UI Migration
]]

local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load Obsidian UI Library & Addons
local Library = loadstring(game:HttpGet(REPO_URL .. "lib.lua"))()
local ThemeManager = loadstring(game:HttpGet(REPO_URL .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(REPO_URL .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- Create Window
local Window = Library:CreateWindow({
	Title = "Greedy Growers",
	Footer = "Auto Seed Collection",
	Icon = 0,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

-- Create Tabs
local Tabs = {
	Main = Window:AddTab("Auto Collect"),
	["UI Settings"] = Window:AddTab("UI Settings"),
}

local CollectGroup = Tabs.Main:AddGroupbox({
	Side = "Left",
	Name = "Conveyor Belt Automation",
})

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

-- Create list of seed names for the dropdown
local SeedNames = {}
for seedName, _ in pairs(t.Seeds) do
    table.insert(SeedNames, seedName)
end
table.sort(SeedNames)

-- UI INTERFACE CREATION
CollectGroup:AddToggle("AutoBuyEnabled", {
    Text = "Enable Auto Collect",
    Default = false,
    Tooltip = "Turn on automation for seed collection",
    Callback = function(val)
        if val then Library:Notify({ Title = "Farm", Description = "Auto Collect Active!", Time = 2.0 }) end
    end
})

CollectGroup:AddDropdown("SelectedSeeds", {
    Values = SeedNames,
    Default = {},
    Multi = true,
    Text = "Select Seeds to Collect",
    Tooltip = "Select which seeds to automatically collect",
    Searchable = true
})

-- Auto Collect Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        -- Accessing via Toggles.AutoBuyEnabled.Value
        if Toggles.AutoBuyEnabled and Toggles.AutoBuyEnabled.Value then
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
                        -- Check against the Multi-Dropdown state
                        -- Multi dropdowns store `{ ["SeedName"] = true }` in `Options.SelectedSeeds.Value`
                        local selected = Options.SelectedSeeds.Value
                        if selected and selected[foundSeedName] then
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

-- UI SETTINGS TAB
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('GreedyGrowers')
SaveManager:SetFolder('GreedyGrowers/Autobuy')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:BuildThemeSection(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()
