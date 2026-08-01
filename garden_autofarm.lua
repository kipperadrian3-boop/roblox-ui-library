--[[
    Garden Auto-Farm & Utility Suite (Deobfuscated & Keyless)
    Official Keyless Script for Roblox Garden / Farming Games
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Framework
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua"))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Garden Suite Error] Could not load UI Library from GitHub!")
    return
end

local int = lib:CreateInterface("Garden Utility Suite", "Keyless Auto-Farm & Performance Tools", "https://discord.gg/ZNTHTWx7KE", "bottom left", "dark")

local farmTab = int:CreateTab("Auto Farm", "Watering, Harvesting & Crops", "item", true)
local petTab = int:CreateTab("Pet & Mutation", "Pet Mutation Machine & Boosters", "npc")
local espTab = int:CreateTab("Egg & Item ESP", "Visual Trackers & Weight Inspection", "visuals")
local perfTab = int:CreateTab("FPS Booster", "Performance & Lag Reduction", "op")

-- State Controls
local Config = {
    AutoWater = false,
    WaterDelay = 0.1,
    AutoCollect = false,
    CollectDelay = 0.05,
    InstantCollect = false,
    AutoMutatePets = false,
    ThresholdLevelPet = 100,
    EggESPEnabled = false,
    DisableParticles = false,
    DisableAnimations = false
}

-- --------------------------------------------------------------------
-- 1. FPS BOOSTER / LAG REDUCER
-- --------------------------------------------------------------------
local function cleanPetParticles()
    local petsPhysical = Workspace:FindFirstChild("PetsPhysical")
    if not petsPhysical then return end

    for _, obj in ipairs(petsPhysical:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") 
        or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
            obj:Destroy()
        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = false
            obj:Destroy()
        elseif obj:IsA("Sound") then
            obj.Volume = 0
            obj:Destroy()
        end
    end
end

local function cleanPetAnimations()
    local petsPhysical = Workspace:FindFirstChild("PetsPhysical")
    if not petsPhysical then return end

    for _, obj in ipairs(petsPhysical:GetDescendants()) do
        if obj:IsA("Animation") then
            obj:Destroy()
        elseif obj:IsA("AnimationController") then
            pcall(function()
                for _, track in ipairs(obj:GetPlayingAnimationTracks()) do
                    track:Stop()
                end
            end)
            obj:Destroy()
        end
    end
end

perfTab:CreateCheckbox("Disable Pet Particles & Lights (Boost FPS)", function(state)
    Config.DisableParticles = state
end)

perfTab:CreateCheckbox("Disable Pet Animations (Reduce Lag)", function(state)
    Config.DisableAnimations = state
end)

task.spawn(function()
    while true do
        task.wait(2)
        if Config.DisableParticles then cleanPetParticles() end
        if Config.DisableAnimations then cleanPetAnimations() end
    end
end)


-- --------------------------------------------------------------------
-- 2. AUTO WATER & AUTO HARVEST
-- --------------------------------------------------------------------
local function getFarmPath(folderName)
    local map = Workspace:FindFirstChild("Map") or Workspace
    return map:FindFirstChild(folderName, true) or Workspace:FindFirstChild(folderName, true)
end

farmTab:CreateCheckbox("Auto Water Crops", function(state)
    Config.AutoWater = state
end)

farmTab:CreateCheckbox("Auto Collect Crops", function(state)
    Config.AutoCollect = state
end)

farmTab:CreateCheckbox("Instant Collect Mode", function(state)
    Config.InstantCollect = state
end)

-- Water Loop
task.spawn(function()
    while true do
        task.wait(Config.WaterDelay)
        if Config.AutoWater then
            pcall(function()
                local farmPath = getFarmPath("Plants_Physical")
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildWhichIsA("Tool")

                if farmPath and tool and tool.Name:match("Watering Can") then
                    local waterRemote = ReplicatedStorage:FindFirstChild("Water_RE", true)
                    for _, plant in ipairs(farmPath:GetChildren()) do
                        if not Config.AutoWater then break end
                        if plant:IsA("Model") and waterRemote then
                            waterRemote:FireServer(plant:GetPivot().Position)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
    end
end)

-- Collect Loop
task.spawn(function()
    while true do
        task.wait(0.3)
        if Config.AutoCollect then
            pcall(function()
                local farmPath = getFarmPath("Plants_Physical")
                local collectRemote = ReplicatedStorage:FindFirstChild("Collect", true) or ReplicatedStorage:FindFirstChild("HarvestCrop", true)
                if farmPath and collectRemote then
                    for _, plant in ipairs(farmPath:GetChildren()) do
                        if not Config.AutoCollect then break end
                        if plant:IsA("Model") and not plant:GetAttribute("Favorited") then
                            if not Config.InstantCollect then task.wait(Config.CollectDelay) end
                            collectRemote:FireServer({plant})
                        end
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- 3. PET MUTATION MACHINE AUTOMATION
-- --------------------------------------------------------------------
petTab:CreateCheckbox("Auto Pet Mutation Machine", function(state)
    Config.AutoMutatePets = state
end)

petTab:CreateSlider("Pet Level Threshold", 500, 100, function(val)
    Config.ThresholdLevelPet = val
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Config.AutoMutatePets then
            pcall(function()
                local prompt = Workspace:FindFirstChild("PetMutationMachineProximityPrompt", true)
                local mutationRemote = ReplicatedStorage:FindFirstChild("PetMutationMachineService_RE", true)

                if prompt and prompt:IsA("ProximityPrompt") and mutationRemote then
                    local actionText = tostring(prompt.ActionText or "")
                    if actionText == "Submit Pet" then
                        local char = LocalPlayer.Character
                        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                        local backpack = LocalPlayer:FindFirstChild("Backpack")

                        if humanoid and backpack then
                            for _, tool in ipairs(backpack:GetChildren()) do
                                if not Config.AutoMutatePets then break end
                                humanoid:EquipTool(tool)
                                task.wait(0.3)
                                mutationRemote:FireServer("SubmitHeldPet")
                                break
                            end
                        end
                    elseif string.find(actionText, "Start Mutation") then
                        task.wait(0.5)
                        mutationRemote:FireServer("StartMachine")
                    elseif actionText == "Claim Pet" then
                        task.wait(0.5)
                        mutationRemote:FireServer("ClaimMutatedPet")
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- 4. EGG VISUAL TRACKER (ESP)
-- --------------------------------------------------------------------
espTab:CreateCheckbox("Enable Egg ESP & Weight Display", function(state)
    Config.EggESPEnabled = state
end)

local function applyEggESP(model)
    if not model or model:FindFirstChild("EggESP") then return end
    local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primary then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "EggESP"
    gui.Adornee = primary
    gui.Size = UDim2.new(0, 140, 0, 45)
    gui.AlwaysOnTop = true
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.Parent = model

    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 215, 0)
    label.TextStrokeTransparency = 0.4
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = model.Name
end

task.spawn(function()
    while true do
        task.wait(1)
        if Config.EggESPEnabled then
            pcall(function()
                local objectsPath = getFarmPath("Objects_Physical")
                if objectsPath then
                    for _, obj in ipairs(objectsPath:GetChildren()) do
                        if obj:GetAttribute("OWNER") == LocalPlayer.Name or not obj:GetAttribute("OWNER") then
                            applyEggESP(obj)
                        end
                    end
                end
            end)
        end
    end
end)

print("[Garden Utility Suite] Loaded Successfully (Keyless Execution)!")
