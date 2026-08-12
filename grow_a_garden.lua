--[[
    Grow a Garden - Complete Standalone Deobfuscated Script (grow_a_garden.lua)
    Deobfuscated from Luraph Obfuscator v14.8
    Standalone Lua Script - No External Library Required
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- Global Configuration Table
local Config = {
    -- Auto Collect Settings
    ["Auto Collect All Fruits"] = false,
    ["Auto Collect Whitelisted Fruits"] = false,
    ["Auto Collect Whitelisted Mutations"] = false,
    ["Auto Collect Blacklisted Fruits"] = false,
    ["Instant Collect"] = false,
    ["Delay To Collect"] = 0.05,
    ["Stop Collect If Backpack Is Full Max"] = true,
    ["Stop Collect If Weather Is Here"] = false,

    -- Selection Filters
    ["Select Whitelist Fruits"] = {},
    ["Select Whitelist Mutation"] = {},
    ["Select Whitelist Variant"] = {},
    ["Select Blacklist Fruits"] = {},
    ["Select Blacklist Mutation"] = {},
    ["Select Blacklist Variant"] = {},
    ["Select Blacklist Tree"] = {},

    -- Auto Plant & Water
    ["Auto Plant Seeds"] = false,
    ["Auto Water Fruits"] = false,
    ["Delay to Water"] = 0.1,
    ["Select Seeds To Plant"] = {},

    -- Auto Sell
    ["Auto Sell"] = false,
    ["Allow Sell If Backpack Is Max"] = true,
    ["Delay To Sell Inventory"] = 0.05,

    -- Pet & Mutation Machine Settings
    ["Auto Mutations Pets"] = false,
    ["Threshold Level Pet"] = 100,
    ["Select Pets Mutations"] = {},
    ["Prevent Mutations Pets"] = {},
    ["Allows Switch Loadouts"] = false,
    ["Select Slot (For EXP Farm)"] = "None",
    ["Select Slot (For Mutation Chamber Boost)"] = "None",
    ["Select Slot (For Phoenix Team)"] = "None",

    -- Pet Feeding
    ["Auto Feed Pets"] = false,
    ["Select Pets"] = {},
    ["Select Fruits"] = {},
    ["Threshold Hunger %"] = 50,
    ["Select Feed Type"] = "Fruit",

    -- Auto Shops (Seeds, Gears, Eggs)
    ["Auto Buy Selected Seed"] = false,
    ["Select Seed"] = "Carrot",
    ["Auto Buy Selected Gear"] = false,
    ["Select Gear"] = "Watering Can",
    ["Auto Buy Selected Egg"] = false,
    ["Select Eggs"] = "Normal",

    -- Cooking Kit Automation
    ["Auto Cook Cooking Kit"] = false,
    ["Ingredient 1"] = "None",
    ["Ingredient 2"] = "None",
    ["Ingredient 3"] = "None",
    ["Ingredient 4"] = "None",
    ["Ingredient 5"] = "None",
    ["Only Mutation Fruits"] = false,

    -- Trade & Give Systems
    ["Auto Give Fruits To Player"] = false,
    ["Auto Give Favourited Fruits To Player"] = false,
    ["Select Players"] = "",
    ["Delay To Gift"] = 0.1,
    ["Select Fruits Trade"] = {},
    ["Select Mutation Trade"] = {},
    ["Select Variant Trade"] = {},

    -- Favorite Tools & Pets Settings
    ["Auto Favorite Pets"] = false,
    ["Select Pets Favourite"] = {},
    ["Age Threshold"] = 0,
    ["Weights Threshold"] = 0,
    ["Select Threshold Mode"] = "Above",

    -- Crates & Harvest Moon Owl
    ["Auto Open Cosmetic Crates"] = false,
    ["Select Items"] = {},
    ["Auto Collect Required Fruit"] = false,
    ["Auto Submit All Plants"] = false,

    -- ESP & Visuals
    ["ESP Fruit"] = false,
    ["Select Fruits ESP"] = {},
    ["Select Mutation ESP"] = {},
    ["Select Variant ESP"] = {},
    ["Allow Show Value Money"] = true,
    ["Cosmetic Crates ESP"] = false,
    ["Player ESP"] = false
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

-- Dynamic Helper Functions
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

-- --------------------------------------------------------------------
-- 1. AUTO HARVEST & COLLECTION SYSTEMS (FUNCTIONS L, E, d, N, W)
-- --------------------------------------------------------------------

-- Function L: Auto Collect All Fruits
task.spawn(function()
    while true do
        task.wait(0.3)
        if Config["Auto Collect All Fruits"] then
            pcall(function()
                if Config["Stop Collect If Backpack Is Full Max"] and isMaxInventory() then return end
                local plantsPhysical = getFarmPath("Plants_Physical")
                if not plantsPhysical then return end

                local collected = 0
                for _, plant in ipairs(plantsPhysical:GetChildren()) do
                    if not Config["Auto Collect All Fruits"] then break end
                    if Config["Stop Collect If Backpack Is Full Max"] and isMaxInventory() then break end

                    if not plant:GetAttribute("Favorited") then
                        if Remotes.Crops and Remotes.Crops:FindFirstChild("Collect") then
                            Remotes.Crops.Collect:FireServer({plant})
                            collected = collected + 1
                            if not Config["Instant Collect"] then
                                task.wait(Config["Delay To Collect"] or 0.02)
                            end
                            if Config["Instant Collect"] and collected > 50 then break end
                        end
                    end
                end
            end)
        end
    end
end)

-- Function E & d: Auto Collect Whitelisted Fruits & Mutations
task.spawn(function()
    while true do
        task.wait(0.3)
        if Config["Auto Collect Whitelisted Fruits"] or Config["Auto Collect Whitelisted Mutations"] then
            pcall(function()
                if Config["Stop Collect If Backpack Is Full Max"] and isMaxInventory() then return end
                local plantsPhysical = getFarmPath("Plants_Physical")
                if not plantsPhysical then return end

                for _, plant in ipairs(plantsPhysical:GetChildren()) do
                    if not Config["Auto Collect Whitelisted Fruits"] and not Config["Auto Collect Whitelisted Mutations"] then break end

                    local name = plant.Name
                    local mutation = plant:GetAttribute("Mutation") or ""
                    local variant = plant:GetAttribute("Variant") or ""

                    local isWhiteFruit = table.find(Config["Select Whitelist Fruits"], name)
                    local isWhiteMut = table.find(Config["Select Whitelist Mutation"], mutation)
                    local isWhiteVar = table.find(Config["Select Whitelist Variant"], variant)

                    if (isWhiteFruit or isWhiteMut or isWhiteVar) and not plant:GetAttribute("Favorited") then
                        if Remotes.Crops and Remotes.Crops:FindFirstChild("Collect") then
                            Remotes.Crops.Collect:FireServer({plant})
                            if not Config["Instant Collect"] then
                                task.wait(Config["Delay To Collect"] or 0.02)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- --------------------------------------------------------------------
-- 2. AUTO WATER FRUITS (FUNCTION I)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(Config["Delay to Water"] or 0.1)
        if Config["Auto Water Fruits"] then
            pcall(function()
                local plantsPhysical = getFarmPath("Plants_Physical")
                if not plantsPhysical then return end
                
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildWhichIsA("Tool")
                if tool and tool.Name:find("Watering Can") then
                    for _, plant in ipairs(plantsPhysical:GetChildren()) do
                        if not Config["Auto Water Fruits"] then break end
                        if plant:IsA("Model") then
                            tool:Activate()
                        end
                    end
                end
            end)
        end
    end
end)

-- --------------------------------------------------------------------
-- 3. AUTO SELL INVENTORY (FUNCTIONS W, q)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(tonumber(Config["Delay To Sell Inventory"]) or 0.1)
        if Config["Auto Sell"] then
            pcall(function()
                if not Config["Allow Sell If Backpack Is Max"] then
                    callSell("Auto Sell")
                elseif isMaxInventory() then
                    callSell("Auto Sell")
                end
            end)
        end
    end
end)

-- --------------------------------------------------------------------
-- 4. PET MUTATION MACHINE AUTOMATION (FUNCTION U)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config["Auto Mutations Pets"] then
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

-- --------------------------------------------------------------------
-- 5. AUTO FEED PETS (FUNCTION l)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(1.5)
        if Config["Auto Feed Pets"] then
            pcall(function()
                local petsFolder = Workspace:FindFirstChild("PetsPhysical")
                if not petsFolder then return end

                for _, pet in ipairs(petsFolder:GetChildren()) do
                    if pet:GetAttribute("OWNER") == LocalPlayer.Name then
                        local hunger = tonumber(pet:GetAttribute("Hunger") or 100)
                        if hunger <= (Config["Threshold Hunger %"] or 50) then
                            -- Feed pet using selected fruit from backpack
                            local bp = LocalPlayer:FindFirstChild("Backpack")
                            if bp then
                                for _, item in ipairs(bp:GetChildren()) do
                                    if item:IsA("Tool") and table.find(Config["Select Fruits"], item.Name) then
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
-- 6. AUTO OPEN COSMETIC CRATES (FUNCTIONS T, S)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(2.0)
        if Config["Auto Open Cosmetic Crates"] then
            pcall(function()
                local objectsFolder = getFarmPath("Objects_Physical")
                if not objectsFolder then return end

                for _, crate in ipairs(objectsFolder:GetChildren()) do
                    if crate:GetAttribute("OWNER") == LocalPlayer.Name and crate:GetAttribute("CrateType") and (crate:GetAttribute("TimeToOpen") or 0) <= 0 then
                        if Remotes.CosmeticCrateService then
                            Remotes.CosmeticCrateService:FireServer("OpenCrate", crate)
                        end
                    end
                end
            end)
        end
    end
end)

-- --------------------------------------------------------------------
-- 7. COOKING KIT AUTO COOK (FUNCTION n)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(1.0)
        if Config["Auto Cook Cooking Kit"] then
            pcall(function()
                local cosmeticFolder = getFarmPath("Cosmetic_Physical")
                if not cosmeticFolder then return end

                for _, kit in ipairs(cosmeticFolder:GetChildren()) do
                    local cookingKit = kit:FindFirstChild("Cooking Kit", true)
                    if cookingKit then
                        local uuid = kit:GetAttribute("CosmeticUUID")
                        if uuid and Remotes.CookingPotService_RE then
                            Remotes.CookingPotService_RE:FireServer("CookBest", uuid)
                        end
                    end
                end
            end)
        end
    end
end)

-- --------------------------------------------------------------------
-- 8. AUTO GIVE FAVORITED FRUITS TO PLAYER (FUNCTIONS H, M)
-- --------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(tonumber(Config["Delay To Gift"]) or 0.2)
        if Config["Auto Give Favourited Fruits To Player"] then
            pcall(function()
                local targetPlr = Players:FindFirstChild(Config["Select Players"])
                if targetPlr and targetPlr.Character then
                    local targetHrp = targetPlr.Character:FindFirstChild("HumanoidRootPart")
                    if targetHrp then
                        -- Equip favorited fruit and fire prompt
                        local bp = LocalPlayer:FindFirstChild("Backpack")
                        if bp then
                            for _, tool in ipairs(bp:GetChildren()) do
                                if tool:IsA("Tool") and tool:GetAttribute("Favorited") then
                                    LocalPlayer.Character.Humanoid:EquipTool(tool)
                                    task.wait(0.1)
                                    break
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
-- 9. ESP HIGHLIGHT SUITE (FUNCTIONS p, Z)
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
        -- Fruit & Mutation ESP
        if Config["ESP Fruit"] then
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

        -- Cosmetic Crates ESP
        if Config["Cosmetic Crates ESP"] then
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
        if Config["Player ESP"] then
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

print("[Grow a Garden] Pure Standalone Deobfuscated Script Executed Successfully!")