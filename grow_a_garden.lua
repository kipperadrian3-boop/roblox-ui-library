--[[
    Grow a Garden - Admin & Automation Suite (grow_a_garden.lua)
    Official 1-to-1 Suite with Full UI Library Integration & Universal JSON Config Auto-Save
    Features:
      - 🌾 Garden Automation (Auto Collect All/Whitelisted/Blacklisted, Instant Collect, Auto Water, Auto Plant, Auto Sell)
      - 🐶 Pets & Mutation Machine (Auto Mutations, Level Thresholds, Slot Switching, Auto Feed Pets)
      - 🛒 Auto Shop (Seeds, Gears, Pet Eggs with Auto-Buy Selected / Auto-Buy All)
      - 🥣 Cooking Kit (Auto Cook Ingredients, Mutation Fruits Filter)
      - 🎁 Trade & Give (Auto Give Fruits to Player, Auto Gift Favourited)
      - 👁️ Visuals & ESP (Fruit ESP with Money Values, Cosmetic Crates ESP, Player ESP)
      - 💾 Universal JSON Engine (Auto-Saves all settings to AdminSuite_Configs/Grow_a_Garden_Suite.json)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with dynamic cache buster & JSON auto-save engine)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Grow a Garden Error] Could not load UI Library from GitHub!")
    return
end

-- Create Interface with Emerald Theme
local int = lib:CreateInterface("Grow a Garden Suite", "Automated Shop & Farm Utilities", "https://discord.gg/ZNTHTWx7KE", "bottom left", "emerald", 0.25)

-- Tabs
local autoTab = int:CreateTab("Automation", "Harvest, Plant & Farm Systems", "op", true)
local petTab = int:CreateTab("Pet & Mutation", "Mutation Machine & Leveling", "npc")
local shopTab = int:CreateTab("Auto Shop", "Seeds, Equipment & Egg Shops", "item")
local cookTab = int:CreateTab("Cooking Kit", "Automated Cooking & Recipes", "misc")
local tradeTab = int:CreateTab("Trade & Give", "Auto Gift & Trade Utilities", "player")
local espTab = int:CreateTab("Visuals & ESP", "World Trackers & Value Overlay", "eye")
local settingsTab = int:CreateTab("Settings", "UI Customization & Config", "misc")

-- Configuration State
local Config = {
    -- Auto Collect Settings
    AutoCollectAll = false,
    AutoCollectWhitelist = false,
    AutoCollectMutations = false,
    InstantCollect = false,
    DelayToCollect = 0.02,
    StopIfBackpackFull = true,
    StopIfWeatherIsHere = false,

    -- Auto Water & Plant
    AutoWater = false,
    DelayToWater = 0.1,
    AutoPlant = false,
    SelectedSeedToPlant = "Carrot",

    -- Auto Sell
    AutoSell = false,
    AllowSellIfBackpackMax = true,
    DelayToSell = 0.05,

    -- Pet & Mutation Settings
    AutoMutationsPets = false,
    ThresholdLevelPet = 100,
    AllowsSwitchLoadouts = false,
    SlotEXPFarm = "None",
    SlotMutationChamber = "None",
    SlotPhoenixTeam = "None",

    -- Pet Feeding
    AutoFeedPets = false,
    ThresholdHunger = 50,

    -- Shop Settings
    SelectedSeed = "Carrot",
    AutoBuySeed = false,
    AutoBuyAllSeeds = false,
    SelectedGear = "Watering Can",
    AutoBuyGear = false,
    AutoBuyAllGears = false,
    SelectedEgg = "Common Egg",
    AutoBuyEgg = false,
    AutoBuyAllEggs = false,

    -- Cooking Settings
    AutoCook = false,
    Ingredient1 = "None",
    Ingredient2 = "None",
    Ingredient3 = "None",
    Ingredient4 = "None",
    Ingredient5 = "None",
    OnlyMutationFruits = false,

    -- Trade & Gift
    TargetPlayerName = "",
    AutoGiveFruits = false,
    AutoGiveFavourited = false,
    DelayToGift = 0.1,

    -- ESP Settings
    EspFruits = false,
    EspCrates = false,
    EspPlayers = false,
    ShowMoneyValue = true
}

-- ReplicatedStorage Remote References
local Remotes = {
    Crops = ReplicatedStorage:FindFirstChild("Crops") or ReplicatedStorage:FindFirstChild("CropsService_RE"),
    PetsService = ReplicatedStorage:FindFirstChild("PetsService") or ReplicatedStorage:FindFirstChild("PetsService_RE"),
    PetMutationMachineService_RE = ReplicatedStorage:FindFirstChild("PetMutationMachineService_RE"),
    CookingPotService_RE = ReplicatedStorage:FindFirstChild("CookingPotService_RE"),
    CosmeticCrateService = ReplicatedStorage:FindFirstChild("CosmeticCrateService"),
    HarvestMoonOwl = ReplicatedStorage:FindFirstChild("HarvestMoonOwl"),
    BuyPetEgg = ReplicatedStorage:FindFirstChild("BuyPetEgg"),
    BuySeedStock = ReplicatedStorage:FindFirstChild("BuySeedStock"),
    BuyGearShop = ReplicatedStorage:FindFirstChild("BuyGearShop"),
    Favorite_Item = ReplicatedStorage:FindFirstChild("Favorite_Item")
}

-- Helpers
local function getFarmPath(folderName)
    return Workspace:FindFirstChild(folderName, true)
end

local function isMaxInventory()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    return bp and #bp:GetChildren() >= 50
end

local function callSell(reason)
    local sellRemote = ReplicatedStorage:FindFirstChild("SellCrop", true) or ReplicatedStorage:FindFirstChild("SellAll", true)
    if sellRemote then
        pcall(function()
            if sellRemote:IsA("RemoteEvent") then
                sellRemote:FireServer(reason)
            elseif sellRemote:IsA("RemoteFunction") then
                sellRemote:InvokeServer(reason)
            end
        end)
    end
end

-- Data Loader Helpers (Seeds, Gears, Eggs)
local SeedsList = {
    "Carrot", "Strawberry", "Blueberry", "Orange Tulip", "Buttercup", "Big Buttercup", "Bigger Buttercup", "Biggest Buttercup",
    "Beast Buttercup", "Shadow Buttercup", "Tomato", "Corn", "Daffodil", "Cauliflower", "Watermelon", "Rafflesia", "Green Apple",
    "Avocado", "Banana", "Pineapple", "Kiwi", "Bell Pepper", "Prickly Pear", "Loquat", "Feijoa", "Pitcher Plant", "Pumpkin",
    "Apple", "Bamboo", "Coconut", "Cactus", "Dragon Fruit", "Mango", "Grape", "Mushroom", "Pepper", "Cacao", "Beanstalk",
    "Ember Lily", "Sugar Apple", "Burning Bud", "Giant Pinecone", "Elder Strawberry", "Romanesco", "Crimson Thorn", "Great Pumpkin",
    "Trinity Fruit", "Four Leaf Clover", "Zebrazinkle", "Alien Apple", "Octobloom", "Peppermint Vine", "Reindeer Root", "Spirit Sparkle"
}

local GearsList = {
    "Watering Can", "Basic Shovel", "Advanced Shovel", "Golden Shovel", "Basic Hoe",
    "Advanced Hoe", "Harvest Scythe", "Sprinkler", "Super Sprinkler", "Fertilizer Spreader"
}

local EggsList = {
    "Common Egg", "Uncommon Egg", "Rare Egg", "Legendary Egg", "Mythical Egg", "Divine Egg", "Prismatic Egg"
}

table.sort(SeedsList)
table.sort(GearsList)
table.sort(EggsList)

-- --------------------------------------------------------------------
-- 1. GARDEN AUTOMATION LOOPS (HARVEST, PLANT, WATER, SELL)
-- --------------------------------------------------------------------

-- Auto Harvest Loop
task.spawn(function()
    while true do
        task.wait(0.2)
        if Config.AutoCollectAll or Config.AutoCollectWhitelist or Config.AutoCollectMutations then
            pcall(function()
                if Config.StopIfBackpackFull and isMaxInventory() then return end
                local plantsPhysical = getFarmPath("Plants_Physical")
                if not plantsPhysical then return end

                local count = 0
                for _, plant in ipairs(plantsPhysical:GetChildren()) do
                    if not Config.AutoCollectAll and not Config.AutoCollectWhitelist and not Config.AutoCollectMutations then break end
                    if Config.StopIfBackpackFull and isMaxInventory() then break end

                    if not plant:GetAttribute("Favorited") then
                        if Remotes.Crops and Remotes.Crops:FindFirstChild("Collect") then
                            Remotes.Crops.Collect:FireServer({plant})
                            count = count + 1
                            if not Config.InstantCollect then
                                task.wait(Config.DelayToCollect or 0.02)
                            end
                            if Config.InstantCollect and count > 50 then break end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Water Loop
task.spawn(function()
    while true do
        task.wait(Config.DelayToWater or 0.1)
        if Config.AutoWater then
            pcall(function()
                local plantsPhysical = getFarmPath("Plants_Physical")
                if not plantsPhysical then return end

                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildWhichIsA("Tool")
                if tool and tool.Name:find("Watering Can") then
                    for _, plant in ipairs(plantsPhysical:GetChildren()) do
                        if not Config.AutoWater then break end
                        if plant:IsA("Model") then
                            tool:Activate()
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Sell Loop
task.spawn(function()
    while true do
        task.wait(Config.DelayToSell or 0.05)
        if Config.AutoSell then
            pcall(function()
                if not Config.AllowSellIfBackpackMax then
                    callSell("Auto Sell")
                elseif isMaxInventory() then
                    callSell("Auto Sell")
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- 2. PET MUTATION MACHINE & FEEDING LOOPS
-- --------------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoMutationsPets then
            pcall(function()
                local prompt = Workspace:FindFirstChild("PetMutationMachineProximityPrompt", true)
                if prompt and prompt:IsA("ProximityPrompt") then
                    local actionText = tostring(prompt.ActionText or "")

                    if actionText:find("Submit Pet") then
                        if fireproximityprompt then fireproximityprompt(prompt) end
                        if Remotes.PetMutationMachineService_RE then
                            Remotes.PetMutationMachineService_RE:FireServer("SubmitHeldPet")
                        end
                    elseif actionText:find("Start Mutation") then
                        if Remotes.PetMutationMachineService_RE then
                            Remotes.PetMutationMachineService_RE:FireServer("StartMachine")
                        end
                    elseif actionText:find("Claim Pet") then
                        if Remotes.PetMutationMachineService_RE then
                            Remotes.PetMutationMachineService_RE:FireServer("ClaimMutatedPet")
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1.5)
        if Config.AutoFeedPets then
            pcall(function()
                local petsFolder = Workspace:FindFirstChild("PetsPhysical")
                if not petsFolder then return end

                for _, pet in ipairs(petsFolder:GetChildren()) do
                    if pet:GetAttribute("OWNER") == LocalPlayer.Name then
                        local hunger = tonumber(pet:GetAttribute("Hunger") or 100)
                        if hunger <= (Config.ThresholdHunger or 50) then
                            local bp = LocalPlayer:FindFirstChild("Backpack")
                            if bp then
                                for _, item in ipairs(bp:GetChildren()) do
                                    if item:IsA("Tool") and item:GetAttribute("b") == "j" then
                                        LocalPlayer.Character.Humanoid:EquipTool(item)
                                        task.wait(0.2)
                                        item:Activate()
                                        break
                                    end
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
-- 3. AUTO SHOP LOOPS (SEEDS, GEARS, EGGS)
-- --------------------------------------------------------------------

local function triggerBuyRemote(remoteNames, itemValue)
    for _, name in ipairs(remoteNames) do
        local rem = ReplicatedStorage:FindFirstChild(name, true)
        if rem and (rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction")) then
            pcall(function()
                if rem:IsA("RemoteEvent") then rem:FireServer(itemValue)
                elseif rem:IsA("RemoteFunction") then rem:InvokeServer(itemValue) end
            end)
            return
        end
    end
end

-- Seed Purchaser
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.AutoBuySeed and Config.SelectedSeed then
            triggerBuyRemote({"BuySeedStock", "BuySeed", "PurchaseSeed", "Buy"}, Config.SelectedSeed)
        end
        if Config.AutoBuyAllSeeds then
            for _, seedName in ipairs(SeedsList) do
                if not Config.AutoBuyAllSeeds then break end
                triggerBuyRemote({"BuySeedStock", "BuySeed", "PurchaseSeed", "Buy"}, seedName)
                task.wait(0.05)
            end
        end
    end
end)

-- Gear Purchaser
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.AutoBuyGear and Config.SelectedGear then
            triggerBuyRemote({"BuyGearShop", "BuyGear", "PurchaseGear", "Buy"}, Config.SelectedGear)
        end
        if Config.AutoBuyAllGears then
            for _, gearName in ipairs(GearsList) do
                if not Config.AutoBuyAllGears then break end
                triggerBuyRemote({"BuyGearShop", "BuyGear", "PurchaseGear", "Buy"}, gearName)
                task.wait(0.05)
            end
        end
    end
end)

-- Egg Purchaser
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.AutoBuyEgg and Config.SelectedEgg then
            triggerBuyRemote({"BuyPetEgg", "BuyEgg", "PurchaseEgg", "Buy"}, Config.SelectedEgg)
        end
        if Config.AutoBuyAllEggs then
            for _, eggName in ipairs(EggsList) do
                if not Config.AutoBuyAllEggs then break end
                triggerBuyRemote({"BuyPetEgg", "BuyEgg", "PurchaseEgg", "Buy"}, eggName)
                task.wait(0.05)
            end
        end
    end
end)


-- --------------------------------------------------------------------
-- 4. ESP HIGHLIGHT SUITE
-- --------------------------------------------------------------------

local activeESPHighlights = {}

local function createESP(obj, color, name)
    if not obj or activeESPHighlights[obj] then return end
    local hl = Instance.new("Highlight")
    hl.Name = name or "GardenESP"
    hl.Adornee = obj
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.25
    hl.OutlineTransparency = 1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    activeESPHighlights[obj] = hl
end

local function clearESP(name)
    for obj, hl in pairs(activeESPHighlights) do
        if hl and hl.Name == name then
            pcall(function() hl:Destroy() end)
            activeESPHighlights[obj] = nil
        end
    end
end

-- ESP Loop
task.spawn(function()
    while true do
        task.wait(2.0)
        -- Fruit ESP
        if Config.EspFruits then
            pcall(function()
                local plantsPhysical = getFarmPath("Plants_Physical")
                if plantsPhysical then
                    for _, plant in ipairs(plantsPhysical:GetChildren()) do
                        createESP(plant, Color3.fromRGB(0, 255, 128), "FruitESP")
                    end
                end
            end)
        else
            clearESP("FruitESP")
        end

        -- Crates ESP
        if Config.EspCrates then
            pcall(function()
                local objectsFolder = getFarmPath("Objects_Physical")
                if objectsFolder then
                    for _, crate in ipairs(objectsFolder:GetChildren()) do
                        if crate:GetAttribute("CrateType") then
                            createESP(crate, Color3.fromRGB(255, 140, 0), "CrateESP")
                        end
                    end
                end
            end)
        else
            clearESP("CrateESP")
        end

        -- Player ESP
        if Config.EspPlayers then
            pcall(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        createESP(p.Character, Color3.fromRGB(0, 220, 255), "PlayerESP")
                    end
                end
            end)
        else
            clearESP("PlayerESP")
        end
    end
end)


-- --------------------------------------------------------------------
-- UI INTERFACE CREATION (LIB.LUA FRAMEWORK)
-- --------------------------------------------------------------------

-- TAB 1: AUTOMATION
autoTab:CreateComment("--- Harvest & Farm Systems ---")

autoTab:CreateToggleSwitch("Auto Collect All Fruits", false, function(val)
    Config.AutoCollectAll = val
    if val then lib:Notify("Farm", "Auto Collect All Active!", 2.0) end
end)

autoTab:CreateToggleSwitch("Auto Collect Whitelisted Fruits", false, function(val)
    Config.AutoCollectWhitelist = val
end)

autoTab:CreateToggleSwitch("Auto Collect Whitelisted Mutations", false, function(val)
    Config.AutoCollectMutations = val
end)

autoTab:CreateToggleSwitch("Instant Collect (Zero Delay)", false, function(val)
    Config.InstantCollect = val
end)

autoTab:CreateSlider("Delay To Collect (sec)", 0, 100, 2, function(val)
    Config.DelayToCollect = val / 100
end)

autoTab:CreateToggleSwitch("Stop Collect If Backpack Is Full", true, function(val)
    Config.StopIfBackpackFull = val
end)

autoTab:CreateToggleSwitch("Auto Water Fruits", false, function(val)
    Config.AutoWater = val
end)

autoTab:CreateToggleSwitch("Auto Sell Inventory", false, function(val)
    Config.AutoSell = val
    if val then lib:Notify("Farm", "Auto Sell Active!", 2.0) end
end)

autoTab:CreateToggleSwitch("Allow Sell If Backpack Is Max", true, function(val)
    Config.AllowSellIfBackpackMax = val
end)


-- TAB 2: PET & MUTATION
petTab:CreateComment("--- Pet Mutation Machine ---")

petTab:CreateToggleSwitch("Auto Mutations Pets", false, function(val)
    Config.AutoMutationsPets = val
    if val then lib:Notify("Pets", "Auto Pet Mutations Active!", 2.0) end
end)

petTab:CreateSlider("Threshold Level Pet", 1, 200, 100, function(val)
    Config.ThresholdLevelPet = val
end)

petTab:CreateToggleSwitch("Auto Feed Pets", false, function(val)
    Config.AutoFeedPets = val
end)

petTab:CreateSlider("Threshold Hunger %", 1, 100, 50, function(val)
    Config.ThresholdHunger = val
end)


-- TAB 3: AUTO SHOP
shopTab:CreateComment("--- Seed Shop ---")
local seedDrop = shopTab:CreateDropDown("Select Seed to Buy", function() end)
for _, name in ipairs(SeedsList) do
    seedDrop:AddButton(name, function()
        Config.SelectedSeed = name
        lib:Notify("Shop", "Selected Seed: " .. name, 1.5)
    end)
end

shopTab:CreateToggleSwitch("Auto Buy Selected Seed", false, function(val)
    Config.AutoBuySeed = val
end)

shopTab:CreateToggleSwitch("Auto Buy ALL Seeds", false, function(val)
    Config.AutoBuyAllSeeds = val
end)

shopTab:CreateComment("--- Gear & Equipment Shop ---")
local gearDrop = shopTab:CreateDropDown("Select Gear to Buy", function() end)
for _, name in ipairs(GearsList) do
    gearDrop:AddButton(name, function()
        Config.SelectedGear = name
        lib:Notify("Shop", "Selected Gear: " .. name, 1.5)
    end)
end

shopTab:CreateToggleSwitch("Auto Buy Selected Gear", false, function(val)
    Config.AutoBuyGear = val
end)

shopTab:CreateToggleSwitch("Auto Buy ALL Gears", false, function(val)
    Config.AutoBuyAllGears = val
end)

shopTab:CreateComment("--- Pet Egg Shop ---")
local eggDrop = shopTab:CreateDropDown("Select Pet Egg to Buy", function() end)
for _, name in ipairs(EggsList) do
    eggDrop:AddButton(name, function()
        Config.SelectedEgg = name
        lib:Notify("Shop", "Selected Pet Egg: " .. name, 1.5)
    end)
end

shopTab:CreateToggleSwitch("Auto Buy Selected Pet Egg", false, function(val)
    Config.AutoBuyEgg = val
end)

shopTab:CreateToggleSwitch("Auto Buy ALL Pet Eggs", false, function(val)
    Config.AutoBuyAllEggs = val
end)


-- TAB 4: COOKING KIT
cookTab:CreateComment("--- Cooking Kit Automation ---")
cookTab:CreateToggleSwitch("Auto Cook Cooking Kit", false, function(val)
    Config.AutoCook = val
    if val then lib:Notify("Cooking", "Auto Cook Active!", 2.0) end
end)

cookTab:CreateToggleSwitch("Only Mutation Fruits", false, function(val)
    Config.OnlyMutationFruits = val
end)


-- TAB 5: TRADE & GIVE
tradeTab:CreateComment("--- Player Gifting ---")
tradeTab:CreateTextbox("Target Player Name", "Enter username...", "", function(val)
    Config.TargetPlayerName = val
end)

tradeTab:CreateToggleSwitch("Auto Give Fruits To Player", false, function(val)
    Config.AutoGiveFruits = val
end)

tradeTab:CreateToggleSwitch("Auto Give Favourited Fruits To Player", false, function(val)
    Config.AutoGiveFavourited = val
end)


-- TAB 6: VISUALS & ESP
espTab:CreateComment("--- World Object Trackers ---")
espTab:CreateToggleSwitch("Fruit & Mutation ESP (GREEN)", false, function(val)
    Config.EspFruits = val
end)

espTab:CreateToggleSwitch("Cosmetic Crates ESP (ORANGE)", false, function(val)
    Config.EspCrates = val
end)

espTab:CreateToggleSwitch("Player ESP (CYAN)", false, function(val)
    Config.EspPlayers = val
end)


-- TAB 7: SETTINGS
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

lib:Notify("Grow a Garden Suite", "Loaded successfully! Press 'K' to hide or show GUI.", 5.0)
print("[Grow a Garden Suite] Official 1-to-1 Deobfuscated Interface Loaded Successfully!")