--[[
	Grow a Garden - Admin & Automation Suite
	Official Script Suite with Auto Shop (Seeds, Gears, Eggs)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua"))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Grow a Garden Error] Could not load UI Library from GitHub!")
    return
end

local int = lib:CreateInterface("Grow a Garden Suite", "Automated Shop & Farm Utilities", "https://discord.gg/ZNTHTWx7KE", "bottom left", "emerald")

-- Tabs
local seedTab = int:CreateTab("Seed Shop", "Automated Seed Purchaser", "item", true)
local gearTab = int:CreateTab("Gear Shop", "Automated Gear & Equipment Purchaser", "op")
local eggTab = int:CreateTab("Egg Shop", "Automated Pet Egg Purchaser", "npc")
local autoTab = int:CreateTab("Garden Automation", "Harvest, Plant & Farm Systems", "default")
local miscTab = int:CreateTab("Utilities", "Remote Inspector & Extra Tools", "misc")

-- Data Loader Helpers
local SeedsList = {}
local GearsList = {}
local EggsList = {}

-- Safely require Data Modules from ReplicatedStorage
pcall(function()
    local dataFolder = ReplicatedStorage:FindFirstChild("Data")
    if dataFolder then
        if dataFolder:FindFirstChild("SeedData") then
            local seedData = require(dataFolder.SeedData)
            for k, v in pairs(seedData) do
                local name = (type(v) == "table" and (v.SeedName or v.DisplayName)) or k
                table.insert(SeedsList, name)
            end
        end
        if dataFolder:FindFirstChild("GearData") then
            local gearData = require(dataFolder.GearData)
            for k, v in pairs(gearData) do
                local name = (type(v) == "table" and (v.GearName or v.DisplayName)) or k
                table.insert(GearsList, name)
            end
        end
        if dataFolder:FindFirstChild("PetEggData") then
            local eggData = require(dataFolder.PetEggData)
            for k, v in pairs(eggData) do
                local name = (type(v) == "table" and (v.EggName or v.DisplayName)) or k
                table.insert(EggsList, name)
            end
        end
    end
end)

-- Fallback Seed Items (From provided game configuration)
if #SeedsList == 0 then
    SeedsList = {
        "Carrot", "Strawberry", "Blueberry", "Orange Tulip", "Buttercup", "Big Buttercup", "Bigger Buttercup", "Biggest Buttercup",
        "Beast Buttercup", "Shadow Buttercup", "Tomato", "Corn", "Daffodil", "Cauliflower", "Watermelon", "Rafflesia", "Green Apple",
        "Avocado", "Banana", "Pineapple", "Kiwi", "Bell Pepper", "Prickly Pear", "Loquat", "Feijoa", "Pitcher Plant", "Pumpkin",
        "Apple", "Bamboo", "Coconut", "Cactus", "Dragon Fruit", "Mango", "Grape", "Mushroom", "Pepper", "Cacao", "Beanstalk",
        "Ember Lily", "Sugar Apple", "Burning Bud", "Giant Pinecone", "Elder Strawberry", "Romanesco", "Crimson Thorn", "Great Pumpkin",
        "Trinity Fruit", "Four Leaf Clover", "Zebrazinkle", "Alien Apple", "Octobloom", "Peppermint Vine", "Reindeer Root", "Spirit Sparkle",
        "Super", "Broccoli", "Potato", "Brussels Sprout", "Cocomango", "Wild Carrot", "Pear", "Cantaloupe", "Parasol Flower", "Rosy Delight",
        "Elephant Ears", "Delphinium", "Lily of the Valley", "Traveler's Fruit", "Peace Lily", "Aloe Vera", "Guanabana", "Crocus", "Succulent",
        "Violet Corn", "Bendboo", "Cocovine", "Dragon Pepper", "Raspberry", "Peach", "Papaya", "Passionfruit", "Soul Fruit", "Cursed Fruit",
        "Cranberry", "Durian", "Eggplant", "Lotus", "Venus Fly Trap", "Nightshade", "Glowshroom", "Mint", "Moonflower", "Starfruit",
        "Moonglow", "Moon Blossom", "Chocolate Carrot", "Red Lollipop", "Candy Sunflower", "Easter Egg", "Candy Blossom", "Crimson Vine",
        "Moon Melon", "Blood Banana", "Celestiberry", "Moon Mango", "Rose", "Foxglove", "Lilac", "Pink Lily", "Purple Dahlia", "Lavender",
        "Nectarshade", "Nectarine", "Hive Fruit", "Manuka Flower", "Dandelion", "Lumira", "Honeysuckle", "Bee Balm", "Nectar Thorn", "Suncoil",
        "Liberty Lily", "Firework Flower", "Stonebite", "Paradise Petal", "Horned Dinoshroom", "Boneboo", "Firefly Fern", "Fossilight",
        "Bone Blossom", "Horsetail", "Lingonberry", "Amber Spine", "Grand Volcania", "Zenflare", "Sakura Bush", "Soft Sunshine", "Spiked Mango",
        "Monoblooma", "Serenity", "Taro Flower", "Zen Rocks", "Hinomai", "Maple Apple", "Enkaku", "Dezen", "Lucky Bamboo", "Tranquil Bloom",
        "Fruitball", "Onion", "Jalapeno", "Crown Melon", "Sugarglaze", "Tall Asparagus", "Grand Tomato", "Artichoke", "Taco Fern", "Twisted Tangle",
        "Veinpetal", "Rhubarb", "Badlands Pepper", "Pricklefruit", "King Cabbage", "Spring Onion", "Butternut Squash", "Bitter Melon", "Golden Egg",
        "Flare Daisy", "Duskpuff", "Mangosteen", "Poseidon Plant", "Gleamroot", "Princess Thorn", "Mandrake", "Canary Melon", "Amberheart",
        "Crown of Thorns", "Calla Lily", "Cyclamen", "Glowpod", "Flare Melon", "Willowberry", "Sunbulb", "Lightshoot", "Glowthorn", "Briar Rose",
        "Pink Rose", "Spirit Flower", "Wispwing", "Emerald Bud", "Pyracantha", "Aetherfruit", "Radish", "Blue Raspberry", "Horned Melon", "Ackee",
        "Urchin Plant", "Pixie Faern", "Untold Bell", "Turnip", "Parsley", "Meyer Lemon", "Carnival Pumpkin", "Kniphofia", "Golden Peach",
        "Maple Resin", "Mangrove", "Autumn Shroom", "Fall Berry", "Speargrass", "Torchflare", "Auburn Pine", "Firewell", "Sundew", "Black Bat Flower",
        "Mandrone Berry", "Corpse Flower", "Inferno Quince", "Multitrap", "Naval Wort", "Evo Beetroot I", "Evo Beetroot II", "Evo Beetroot III",
        "Evo Beetroot IV", "Evo Blueberry I", "Evo Blueberry II", "Evo Blueberry III", "Evo Blueberry IV", "Evo Pumpkin I", "Evo Pumpkin II",
        "Evo Pumpkin III", "Evo Pumpkin IV", "Evo Mushroom I", "Evo Mushroom II", "Evo Mushroom III", "Evo Mushroom IV", "Evo Apple I", "Evo Apple II",
        "Evo Apple III", "Evo Apple IV", "Hazelnut", "Persimmon", "Acorn", "Acorn Squash", "Ferntail", "Pecan", "Fissure Berry", "Bloodred Mushroom",
        "Jack O Lantern", "Ghoul Root", "Chicken Feed", "Seer Vine", "Poison Apple", "Banesberry", "Candy Cornflower", "Blood Orange", "Zombie Fruit",
        "Wisp Flower", "Mummy's Hand", "Weeping Branch", "Ghost Bush", "Devilroot", "Wereplant", "Severed Spine", "Glass Kiwi", "Spider Vine",
        "Monster Flower", "Horned Redrose", "Banana Orchid", "Viburnum Berry", "Buddhas Hand", "Ghost Pepper"
    }
end

if #GearsList == 0 then
    GearsList = {
        "Watering Can", "Basic Shovel", "Advanced Shovel", "Golden Shovel", "Basic Hoe",
        "Advanced Hoe", "Harvest Scythe", "Sprinkler", "Super Sprinkler", "Fertilizer Spreader"
    }
end

if #EggsList == 0 then
    EggsList = {
        "Common Egg", "Uncommon Egg", "Rare Egg", "Legendary Egg", "Mythical Egg", "Divine Egg", "Prismatic Egg"
    }
end

table.sort(SeedsList)
table.sort(GearsList)
table.sort(EggsList)

-- Remote Finder Utility
local function findRemote(possibleNames)
    for _, name in ipairs(possibleNames) do
        local remote = ReplicatedStorage:FindFirstChild(name, true)
        if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
            return remote
        end
    end
    -- Scan all descendants
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            for _, name in ipairs(possibleNames) do
                if string.find(desc.Name:lower(), name:lower()) then
                    return desc
                end
            end
        end
    end
    return nil
end

local seedRemote = findRemote({"BuySeedStock", "BuySeed", "BuyItem", "PurchaseSeed"})
local gearRemote = findRemote({"BuyGearShop", "BuyGear", "BuyEquipment", "PurchaseGear"})
local eggRemote  = findRemote({"BuyPetEgg", "BuyEgg", "PurchaseEgg", "BuyPet"})

local function triggerBuy(remote, itemValue)
    if not remote then return end
    pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(itemValue)
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer(itemValue)
        end
    end)
end

-- ==================== SEED SHOP ====================
local selectedSeed = SeedsList[1] or "Carrot"
local autoBuySeedToggle = false
local autoBuyAllSeedsToggle = false

local seedDropdown = seedTab:CreateDropDown("Select Seed to Buy")
for _, name in ipairs(SeedsList) do
    seedDropdown:AddButton(name, function()
        selectedSeed = name
        print("[Shop] Selected seed:", name)
    end)
end

seedTab:CreateCheckbox("Auto Buy Selected Seed (Every 0.2s)", function(state)
    autoBuySeedToggle = state
end)

seedTab:CreateCheckbox("Auto Buy ALL Seeds (Every 0.2s)", function(state)
    autoBuyAllSeedsToggle = state
end)

-- Seed Purchaser Loop
task.spawn(function()
    while true do
        task.wait(0.2)
        if autoBuySeedToggle and selectedSeed then
            triggerBuy(seedRemote, selectedSeed)
        end
        if autoBuyAllSeedsToggle then
            for _, seedName in ipairs(SeedsList) do
                triggerBuy(seedRemote, seedName)
                task.wait(0.05)
            end
        end
    end
end)


-- ==================== GEAR SHOP ====================
local selectedGear = GearsList[1] or "Watering Can"
local autoBuyGearToggle = false
local autoBuyAllGearsToggle = false

local gearDropdown = gearTab:CreateDropDown("Select Gear to Buy")
for _, name in ipairs(GearsList) do
    gearDropdown:AddButton(name, function()
        selectedGear = name
        print("[Shop] Selected gear:", name)
    end)
end

gearTab:CreateCheckbox("Auto Buy Selected Gear (Every 0.2s)", function(state)
    autoBuyGearToggle = state
end)

gearTab:CreateCheckbox("Auto Buy ALL Gears (Every 0.2s)", function(state)
    autoBuyAllGearsToggle = state
end)

-- Gear Purchaser Loop
task.spawn(function()
    while true do
        task.wait(0.2)
        if autoBuyGearToggle and selectedGear then
            triggerBuy(gearRemote, selectedGear)
        end
        if autoBuyAllGearsToggle then
            for _, gearName in ipairs(GearsList) do
                triggerBuy(gearRemote, gearName)
                task.wait(0.05)
            end
        end
    end
end)


-- ==================== EGG SHOP ====================
local selectedEgg = EggsList[1] or "Common Egg"
local autoBuyEggToggle = false
local autoBuyAllEggsToggle = false

local eggDropdown = eggTab:CreateDropDown("Select Pet Egg to Buy")
for _, name in ipairs(EggsList) do
    eggDropdown:AddButton(name, function()
        selectedEgg = name
        print("[Shop] Selected egg:", name)
    end)
end

eggTab:CreateCheckbox("Auto Buy Selected Pet Egg (Every 0.2s)", function(state)
    autoBuyEggToggle = state
end)

eggTab:CreateCheckbox("Auto Buy ALL Pet Eggs (Every 0.2s)", function(state)
    autoBuyAllEggsToggle = state
end)

-- Egg Purchaser Loop
task.spawn(function()
    while true do
        task.wait(0.2)
        if autoBuyEggToggle and selectedEgg then
            triggerBuy(eggRemote, selectedEgg)
        end
        if autoBuyAllEggsToggle then
            for _, eggName in ipairs(EggsList) do
                triggerBuy(eggRemote, eggName)
                task.wait(0.05)
            end
        end
    end
end)


-- ==================== GARDEN AUTOMATION ====================
local autoHarvestToggle = false
local autoSellToggle = false

autoTab:CreateCheckbox("Auto Harvest Nearby Crops", function(state)
    autoHarvestToggle = state
end)

autoTab:CreateCheckbox("Auto Sell Harvested Crops", function(state)
    autoSellToggle = state
end)

-- Farm Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if autoHarvestToggle then
            local harvestRemote = findRemote({"HarvestCrop", "Harvest", "PickCrop", "CollectFruit"})
            if harvestRemote then
                pcall(function() harvestRemote:FireServer() end)
            end
        end
        if autoSellToggle then
            local sellRemote = findRemote({"SellCrop", "SellAll", "SellInventory", "MerchantSell"})
            if sellRemote then
                pcall(function() sellRemote:FireServer() end)
            end
        end
    end
end)


-- ==================== UTILITIES ====================
miscTab:CreateComment("Extra Developer Utilities:")

miscTab:CreateCheckbox("Launch Remote Event Inspector", function(state)
    if state then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/remote_spy.lua"))()
    end
end)

print("[Grow a Garden Suite] Loaded Successfully!")
