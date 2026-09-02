import sys

with open('greedy_growers.lua', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace tabs creation
old_tabs = """-- Tabs
local collectTab = int:CreateTab("Auto Collect", "Conveyor Belt Automation", "op", true)
local fruitsTab = int:CreateTab("Fruits", "Fruit Farming", "op")
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")"""

new_tabs = """-- Tabs
local mainTab = int:CreateTab("Main", "Auto Collection", "op", true)
local autoTab = int:CreateTab("Automation", "Farming & Selling", "op")
local settingsTab = int:CreateTab("Settings", "UI Customization", "misc")"""

content = content.replace(old_tabs, new_tabs)

# Inject Auto Sell Loop
auto_sell_loop = """
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
"""

content = content.replace("-- UI INTERFACE CREATION", auto_sell_loop, 1)

# Replace the entire UI INTERFACE CREATION block
ui_start = content.find("-- UI INTERFACE CREATION")
if ui_start != -1:
    content = content[:ui_start + len("-- UI INTERFACE CREATION")]
    
    new_ui = """
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
"""
    content += new_ui

with open('greedy_growers.lua', 'w', encoding='utf-8') as f:
    f.write(content)

print("greedy_growers.lua refactored successfully")
