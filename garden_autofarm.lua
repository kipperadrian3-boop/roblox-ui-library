--[[
    Grow a Garden / Pet Garden - 1:1 Deobfuscated Script Suite
    All original Luraph obfuscated functions translated 1:1 into clean readable Lua.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Module = {}

-- --------------------------------------------------------------------
-- 1. FPS BOOSTER (Deletes Particles, Lights & Sounds from PetsPhysical)
-- --------------------------------------------------------------------
function Module.BoostPetFPS()
    local petsPhysical = Workspace:FindFirstChild("PetsPhysical")
    if not petsPhysical then return end

    for _, item in ipairs(petsPhysical:GetDescendants()) do
        if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") 
        or item:IsA("Fire") or item:IsA("Smoke") or item:IsA("Sparkles") then
            item.Enabled = false
            item:Destroy()
        elseif item:IsA("PointLight") or item:IsA("SpotLight") or item:IsA("SurfaceLight") then
            item.Enabled = false
            item:Destroy()
        elseif item:IsA("Sound") then
            item.Volume = 0
            item:Destroy()
        end
    end
end

-- --------------------------------------------------------------------
-- 2. ANIMATION CLEANER (Stops & Deletes Pet Animation Tracks)
-- --------------------------------------------------------------------
function Module.CleanPetAnimations()
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

-- --------------------------------------------------------------------
-- 3. AUTO GIVE FRUITS TO PLAYER (Trade / Gift Fruits via ProximityPrompt)
-- --------------------------------------------------------------------
function Module.AutoGiveFruits(config, timer, targetFolder, helper)
    return function()
        local delayTime = tonumber(config["Delay To Gift"]) or 0.1
        if not timer:Expired("Auto Give Fruits To Player") then return end
        timer:Set("Auto Give Fruits To Player", delayTime)

        local targetPlayer = targetFolder and targetFolder:FindFirstChild(config["Select Players"])
        if not targetPlayer or not targetPlayer.Character then return end

        local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local prompt = hrp and hrp:FindFirstChildWhichIsA("ProximityPrompt")

        if hrp and helper.GetMagnitude(hrp.CFrame) > 10 then
            helper.GetTo(hrp.CFrame)
            return
        end

        if prompt and prompt.Enabled then
            fireproximityprompt(prompt)
            return
        end

        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChild("Humanoid")
        if not (backpack and humanoid) then return end

        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local isMatch = helper.FruitFilter({
                    config["Select Fruits Trade"],
                    config["Select Mutation Trade"],
                    config["Select Variant Trade"]
                }, tool)

                if isMatch then
                    humanoid:EquipTool(tool)
                    task.wait(0.1)
                    if char:FindFirstChild(tool.Name) then break end
                end
            end
        end
    end
end

-- --------------------------------------------------------------------
-- 4. AUTO WATER FRUITS (Fires Water_RE for Selected Plants)
-- --------------------------------------------------------------------
function Module.AutoWaterFruits(config, helper, player, remotes)
    return function()
        local delayTime = config["Delay to Water "] or 0.1
        task.wait(delayTime)

        local farmPath = helper.GetFarmPath("Plants_Physical")
        if not farmPath then return end

        local currentTool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
        for _, plant in ipairs(farmPath:GetChildren()) do
            if not config["Auto Water Fruits"] then break end
            if not (currentTool and currentTool.Name:match("Watering Can")) then break end

            if plant:IsA("Model") and table.find(config["Select Water Fruits"], plant.Name) then
                remotes.Water_RE:FireServer(plant:GetPivot().Position)
                task.wait(0.15)
            end
        end
    end
end

-- --------------------------------------------------------------------
-- 5. AUTO PET MUTATION MACHINE (Submit, Start & Claim Mutated Pets)
-- --------------------------------------------------------------------
function Module.AutoPetMutationMachine(config, helper, remotes, state, player)
    return function()
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not humanoid or not hrp then return end

        if helper:IsSwitchingActive() then return end

        local prompt = Workspace:FindFirstChild("PetMutationMachineProximityPrompt", true)
        if not prompt or not prompt:IsA("ProximityPrompt") then return end

        local actionText = tostring(prompt.ActionText or "")
        local thresholdLevel = tonumber(config["Threshold Level Pet"]) or 100

        local function fireRemote(remote, ...)
            local args = {...}
            return pcall(function() remote:FireServer(unpack(args)) end)
        end

        local function getPetData(uuid)
            if not uuid then return end
            local success, data = pcall(function() return helper.DataClient.GetPet_Data(uuid) end)
            if success then return data end
        end

        local function getPetLevel(tool, petData)
            local level
            if petData and petData.PetData then level = tonumber(petData.PetData.Level) end
            if not level and tool then level = tonumber(tostring(tool.Name):match("%[Age %((%d+)%)%]")) end
            return level or 0
        end

        local function isValidPet(tool)
            if not tool:IsA("Tool") then return false end
            if tool:GetAttribute("b") ~= "l" then return false end
            if tool:GetAttribute("d") then return false end
            local uuid = tool:GetAttribute("PET_UUID")
            if not uuid then return false end
            local data = getPetData(uuid)
            if not data or not data.PetType or not data.PetData then return false end

            local mutationType = data.PetData.MutationType or "N/A"
            local mutationCode = helper.API.Data.PetMutationsCode[mutationType] or "N/A"

            if not table.find(config["Select Pets Mutations"], data.PetType) then return false end
            if table.find(config["Prevent Mutations Pets"], mutationCode) then return false end

            return true, uuid, data
        end

        if actionText == "Submit Pet" then
            local submitted = false
            do
                local petsPhysical = Workspace:FindFirstChild("PetsPhysical")
                if petsPhysical then
                    for _, petModel in ipairs(petsPhysical:GetChildren()) do
                        if not config["Auto Mutations Pets"] then break end
                        if petModel:GetAttribute("OWNER") ~= player.Name then continue end
                        local uuid = petModel:GetAttribute("UUID")
                        if not uuid then continue end
                        local petData = getPetData(uuid)
                        if not petData or not petData.PetType or not petData.PetData then continue end
                        if not table.find(config["Select Pets Mutations"], petData.PetType) then continue end

                        local mutationType = petData.PetData.MutationType or "N/A"
                        local mutationCode = helper.API.Data.PetMutationsCode[mutationType] or "N/A"
                        if table.find(config["Prevent Mutations Pets"], mutationCode) then continue end

                        if getPetLevel(nil, petData) >= thresholdLevel then
                            local success = fireRemote(remotes.PetsService, "UnequipPet", uuid)
                            if success then
                                state.PetMutations[uuid] = nil
                                task.wait(0.25)
                            end
                        end
                    end
                end
            end

            for _, tool in ipairs(player.Backpack:GetChildren()) do
                if not config["Auto Mutations Pets"] then break end
                local valid, uuid, petData = isValidPet(tool)
                if not valid then continue end

                local level = getPetLevel(tool, petData)
                if level >= thresholdLevel then
                    local equipped = pcall(function() humanoid:EquipTool(tool) end)
                    if equipped and tool.Parent == char then
                        task.wait(0.35)
                        local success = fireRemote(remotes.PetMutationMachineService_RE, "SubmitHeldPet")
                        if success then
                            state.PetMutations[uuid] = nil
                            submitted = true
                            break
                        end
                    end
                elseif config["Allows Switch Loadouts"] then
                    local slot = config["Select Slot (For EXP Farm)"]
                    if slot and slot ~= "None" and not state.PetMutations[uuid] then
                        local switched = helper:FireSlotLoadout(slot, "Delay To Switch")
                        if switched then
                            state.PetMutations[uuid] = {PetType = petData.PetType, StartTime = tick()}
                            task.wait(0.5)
                            local equipped = fireRemote(remotes.PetsService, "EquipPet", uuid, hrp.CFrame)
                            if equipped then task.wait(0.5) end
                        end
                    end
                end
            end

            if not submitted and config["Allows Switch Loadouts"] then
                for uuid, data in pairs(state.PetMutations) do
                    if not config["Auto Mutations Pets"] then break end
                    local petData = getPetData(uuid)
                    if petData and petData.PetData then
                        local level = getPetLevel(nil, petData)
                        if level >= thresholdLevel then
                            local unequipped = fireRemote(remotes.PetsService, "UnequipPet", uuid)
                            if unequipped then
                                state.PetMutations[uuid] = nil
                                task.wait(0.25)
                            end
                        end
                    elseif tick() - (data.StartTime or 0) > 300 then
                        state.PetMutations[uuid] = nil
                    end
                end
            end
        elseif string.find(actionText, "Start Mutation") then
            if helper:IsSwitchingActive() then return end
            local allowed = true
            if config["Allows Switch Loadouts"] then
                local slot = config["Select Slot (For Mutation Chamber Boost)"]
                if slot and slot ~= "None" then
                    allowed = helper:FireSlotLoadout(slot, "Delay To Switch")
                end
            end
            if allowed then
                task.wait(0.5)
                fireRemote(remotes.PetMutationMachineService_RE, "StartMachine")
            end
        elseif actionText == "Claim Pet" then
            if helper:IsSwitchingActive() then return end
            local allowed = true
            if config["Allows Switch Loadouts"] then
                local slot = config["Select Slot (For Phoenix Team)"]
                if slot and slot ~= "None" then
                    allowed = helper:FireSlotLoadout(slot, "Delay To Switch")
                end
            end
            if allowed then
                task.wait(0.5)
                local claimed = fireRemote(remotes.PetMutationMachineService_RE, "ClaimMutatedPet")
                if claimed then task.wait(0.5) end
            end
        end

        task.wait(0.5)
    end
end

-- --------------------------------------------------------------------
-- 6. EGG WEIGHT CHECKER & FILTER
-- --------------------------------------------------------------------
function Module.CheckEggFilter(config, utils, helper, player)
    return function()
        function player:CheckEgg(uuid)
            if not (config:find("Solara") or config:find("Xeno")) then
                local savedData = helper.DataClient.GetSaved_Data()
                if not savedData or not savedData[uuid] then return true end

                local eggEntry = savedData[uuid]
                if not eggEntry or not eggEntry.Data then return true end

                local data = eggEntry.Data
                local eggType = data.Type or "N/A"
                local baseWeight = data.BaseWeight or 1

                local chosenPets = utils["Choose Pets "]
                if #chosenPets > 1 and not table.find(chosenPets, "None") then
                    local filterMode = utils["Select Filter Mode"]
                    if filterMode == "Blacklist" then
                        if table.find(chosenPets, eggType) then return false end
                    else
                        if not table.find(chosenPets, eggType) then return false end
                    end
                end

                local thresholdWeight = tonumber(utils["Weights Pet Threshold "]) or 0
                local thresholdMode = utils["Select Threshold Mode     "]
                local currentWeight = helper.Calculator.CurrentWeight(data, 1)

                return (thresholdWeight == 0) or (currentWeight and (thresholdMode == "Above" and currentWeight > thresholdWeight or thresholdMode ~= "Above" and currentWeight < thresholdWeight))
            else
                return true
            end
        end
    end
end

-- --------------------------------------------------------------------
-- 7. EGG VISUAL TRACKER / BILLBOARD ESP (KG Weight Display)
-- --------------------------------------------------------------------
function Module.UpdateEggVisuals(config, utils, helper, espManager, formatHelper, player)
    return function()
        local objectsPhysical = config.GetFarmPath("Objects_Physical")
        if not objectsPhysical then return end

        local savedData = config.DataClient.GetSaved_Data()
        if not savedData then return end

        local delayTime = 1
        for _, obj in ipairs(objectsPhysical:GetChildren()) do
            pcall(function()
                if obj:GetAttribute("OWNER") == player.Name then
                    local esp = obj:FindFirstChild("ESP")
                    if not esp then
                        espManager.CreateESP(obj, {Color = Color3.fromRGB(255, 255, 255), Text = "", Enabled = false})
                        esp = obj:FindFirstChild("ESP")
                    end

                    if esp then
                        local billboard = esp:FindFirstChild("BillboardGui", true)
                        local textLabel = billboard and billboard:FindFirstChild("TextLabel")
                        if billboard then billboard.Enabled = true end

                        if obj:GetAttribute("READY") then
                            local timeToHatch = obj:GetAttribute("TimeToHatch")
                            local uuid = obj:GetAttribute("OBJECT_UUID")
                            local formattedText

                            if timeToHatch and timeToHatch > 0 then
                                delayTime = utils["Disable ESP Cooldown Egg"] and 1 or 0
                                formattedText = utils["Disable ESP Cooldown Egg"] and "" or string.format("<font color='rgb(3,219,252)'>%s</font>\n<font color='rgb(255,215,0)'>%s</font>\n", tostring(obj:GetAttribute("EggName")), formatHelper(timeToHatch))
                            else
                                delayTime = 1
                                local eggEntry = savedData[uuid]
                                if eggEntry then
                                    local data = eggEntry.Data
                                    local eggType = data.Type
                                    local baseWeight = data.BaseWeight or 1
                                    local currentWeight = config.Calculator.CurrentWeight(baseWeight, 1)
                                    local formattedWeight = helper:DecimalNumberFormat(currentWeight)
                                    local category = (currentWeight > 9 and "Titanic") or (currentWeight >= 6 and currentWeight <= 9 and "Semi Titanic") or (currentWeight > 3 and "Huge") or "Small"

                                    formattedText = string.format(
                                        "<font color='rgb(3,219,252)'>%s</font>\n<font color='rgb(255,215,0)'>%s</font>\n<font color='rgb(108,255,100)'>%s (%s)</font>",
                                        tostring(obj:GetAttribute("EggName")),
                                        eggType,
                                        tostring(formattedWeight) .. " KG",
                                        category
                                    )
                                end
                            end

                            if formattedText and textLabel and textLabel.Text ~= formattedText then
                                textLabel.Text = formattedText
                            end
                        end
                    end
                end
            end)
        end
        task.wait(delayTime)
    end
end

-- --------------------------------------------------------------------
-- 8. AUTO COLLECT CROPS (Whitelisted Mutated Crops Harvester)
-- --------------------------------------------------------------------
function Module.AutoCollectCrops(config, inventory, options, helper, remotes)
    return function()
        local plantList = helper.GetPlantList(config.GetFarmPath("Plants_Physical"), {})
        local whitelistedMutations = options["Select Whitelisted Mutations"]
        local filterList = {{}, whitelistedMutations, {}}
        local collectedCount = 0

        for i = 1, #plantList do
            if not options["Auto Collect Whitelisted Mutations"] then break end
            if options["Stop Collect If Backpack Is Full Max"] and inventory.IsMaxInventory() then break end

            local plant = plantList[i]
            if not plant:GetAttribute("Favorited") and config.FruitFilter(filterList, plant) then
                if not options["Instant Collect"] then
                    task.wait(options["Delay To Collect"] or 0)
                end

                remotes.Crops.Collect:FireServer({plant})
                collectedCount = collectedCount + 1

                if not options["Instant Collect"] then task.wait(0.02) end
                if options["Instant Collect"] and collectedCount > 50 then break end
            end
        end
        task.wait(1)
    end
end

-- Return System Module
return Module
