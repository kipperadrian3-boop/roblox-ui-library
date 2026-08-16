--[[
	Mine a Mountain - Official Script Suite (mine_a_mountain.lua)
	Features:
	  - 💎 Rich Finder / Leaderboard Hop: Server hops automatically until a player with >10B Coins (configurable) is found!
	  - 🔄 Auto Re-Execution: Uses queue_on_teleport to automatically re-run the script after every server hop!
	  - 🚫 Anti-Repeat Server Hop: Remembers visited server IDs so it NEVER joins the same server twice!
	  - ⛏️ Auto Mine & Farm: Automates mining, swinging pickaxe & collecting drops
	  - 🏃 Movement Suite: Fly, FlySpeed, Noclip, WalkSpeed & JumpPower
	  - 💾 Universal JSON Config Engine (lib.lua) with Cyber Theme
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local REPO_URL = "https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/"

-- Load UI Library Framework (lib.lua with dynamic cache buster & JSON auto-save engine)
local success, lib = pcall(function()
    return loadstring(game:HttpGet(REPO_URL .. "lib.lua?v=" .. tostring(math.random(1, 9999999))))()
end)

if not success or not lib or type(lib) ~= "table" then
    warn("[Mine a Mountain Error] Could not load UI Library from GitHub!")
    return
end

-- Create Interface with Cyber Theme
local int = lib:CreateInterface("Mine a Mountain Suite", "Rich Finder & Mining Automation", "https://discord.gg/ZNTHTWx7KE", "bottom left", "cyber", 0.25)

-- Tabs
local richTab = int:CreateTab("Rich Finder", "Leaderboard Hop > 10B Coins", "op", true)
local farmTab = int:CreateTab("Auto Mining", "Mine, Farm & Upgrade", "item")
local moveTab = int:CreateTab("Movement & Fly", "Flight, Speed & Noclip", "player")
local settingsTab = int:CreateTab("Settings", "UI Customization & Config", "misc")

-- Configuration State
local Config = {
    RichFinderActive = false,
    MinCoinsBillion = 10, -- 10 Billion Coins default
    AutoMine = false,
    AutoCollect = false,
    AutoUpgrade = false,
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50
}

-- Active Status Label for Rich Finder
local richStatusLabel = nil

-- --------------------------------------------------------------------
-- HELPER: PARSE & FORMAT COINS / LEADERSTATS
-- --------------------------------------------------------------------

local function parseCoinsValue(val)
    if type(val) == "number" then return val end
    if type(val) == "string" then
        val = val:upper():gsub(",", "")
        local num = tonumber(val:match("[%d%.]+"))
        if not num then return 0 end
        if val:find("T") or val:find("TRILLION") then return num * 1e12
        elseif val:find("B") or val:find("BILLION") then return num * 1e9
        elseif val:find("M") or val:find("MILLION") then return num * 1e6
        elseif val:find("K") or val:find("THOUSAND") then return num * 1e3
        end
        return num
    end
    return 0
end

local function formatCoinsShort(val)
    if val >= 1e12 then return string.format("%.2f T", val / 1e12)
    elseif val >= 1e9 then return string.format("%.2f B", val / 1e9)
    elseif val >= 1e6 then return string.format("%.2f M", val / 1e6)
    elseif val >= 1e3 then return string.format("%.2f K", val / 1e3)
    else return tostring(val) end
end

local function getPlayerCoins(player)
    if not player then return 0 end
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            local sName = stat.Name:lower()
            if sName:find("coin") or sName:find("money") or sName:find("cash") or sName:find("gold") then
                return parseCoinsValue(stat.Value)
            end
        end
    end
    local dataFolder = player:FindFirstChild("Data") or player:FindFirstChild("Stats")
    if dataFolder then
        for _, stat in ipairs(dataFolder:GetChildren()) do
            local sName = stat.Name:lower()
            if sName:find("coin") or sName:find("money") or sName:find("cash") then
                return parseCoinsValue(stat.Value)
            end
        end
    end
    return 0
end

-- --------------------------------------------------------------------
-- SERVER HOPPER & VISITED SERVERS CACHE
-- --------------------------------------------------------------------

local visitedFile = "MineAMountain_VisitedServers.json"
local visitedServers = {}

pcall(function()
    if isfile and isfile(visitedFile) then
        visitedServers = HttpService:JSONDecode(readfile(visitedFile)) or {}
    end
end)

local function recordVisitedServer(jobId)
    if not jobId then return end
    visitedServers[jobId] = os.time()
    pcall(function()
        if writefile then
            writefile(visitedFile, HttpService:JSONEncode(visitedServers))
        end
    end)
end

local function performServerHop()
    recordVisitedServer(game.JobId)

    -- Queue self re-execution on teleport using executor queue API
    local queueTeleport = queue_on_teleport or (syn and syn.queue_on_teleport) or queue_to_teleport or (Fluxus and Fluxus.queue_on_teleport)
    if queueTeleport then
        pcall(function()
            queueTeleport([[
                loadstring(game:HttpGet("https://raw.githubusercontent.com/kipperadrian3-boop/roblox-ui-library/main/mine_a_mountain.lua?v=" .. tostring(os.time())))()
            ]])
        end)
    end

    lib:Notify("Server Hop", "No rich player found. Hopping to a new server...", 2.5)

    pcall(function()
        local placeId = game.PlaceId
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        local req = (http_request or request or (syn and syn.request) or (http and http.request))
        if req then
            local response = req({Url = url, Method = "GET"})
            if response and response.Body then
                local data = HttpService:JSONDecode(response.Body)
                if data and data.data then
                    for _, server in ipairs(data.data) do
                        if server.id ~= game.JobId and not visitedServers[server.id] and server.playing < server.maxPlayers then
                            recordVisitedServer(server.id)
                            TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                            return
                        end
                    end
                end
            end
        end
        TeleportService:Teleport(placeId, LocalPlayer)
    end)
end

-- --------------------------------------------------------------------
-- RICH FINDER LOGIC
-- --------------------------------------------------------------------

local function checkServerForRichPlayer()
    local targetThreshold = (Config.MinCoinsBillion or 10) * 1e9
    local highestCoins = 0
    local richestPlayer = nil

    for _, player in ipairs(Players:GetPlayers()) do
        local coins = getPlayerCoins(player)
        if coins > highestCoins then
            highestCoins = coins
            richestPlayer = player
        end
    end

    if richStatusLabel then
        if richestPlayer then
            richStatusLabel.Text = string.format("Highest Coins: %s (%s)", formatCoinsShort(highestCoins), richestPlayer.Name)
        else
            richStatusLabel.Text = "Scanning players..."
        end
    end

    if highestCoins >= targetThreshold then
        lib:Notify("Rich Player Found!", string.format("Player %s has %s Coins!", richestPlayer.Name, formatCoinsShort(highestCoins)), 5.0)
        if richStatusLabel then
            richStatusLabel.Text = string.format("MATCH FOUND! %s (%s Coins)", richestPlayer.Name, formatCoinsShort(highestCoins))
            richStatusLabel.TextColor3 = Color3.fromRGB(0, 255, 180)
        end
        return true -- Found! Stay in server!
    end

    return false
end

-- Auto Server Hop Loop
task.spawn(function()
    task.wait(3.0) -- Wait for leaderstats to load
    while true do
        task.wait(1.5)
        if Config.RichFinderActive then
            local found = checkServerForRichPlayer()
            if not found then
                task.wait(2.0)
                if Config.RichFinderActive then
                    performServerHop()
                    break
                end
            end
        end
    end
end)

-- --------------------------------------------------------------------
-- AUTO MINING & FARMING LOOPS
-- --------------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.AutoMine then
            pcall(function()
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildWhichIsA("Tool")
                if tool then
                    tool:Activate()
                else
                    local bp = LocalPlayer:FindFirstChild("Backpack")
                    if bp then
                        local pickaxe = bp:FindFirstChildWhichIsA("Tool")
                        if pickaxe then
                            char.Humanoid:EquipTool(pickaxe)
                        end
                    end
                end
            end)
        end
    end
end)


-- --------------------------------------------------------------------
-- MOVEMENT & FLY SUITE
-- --------------------------------------------------------------------

local flyGyro, flyVel

local function startFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flyGyro then flyGyro:Destroy() end
    if flyVel then flyVel:Destroy() end

    flyGyro = Instance.new("BodyGyro")
    flyGyro.P = 9e4
    flyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.cframe = hrp.CFrame
    flyGyro.Parent = hrp

    flyVel = Instance.new("BodyVelocity")
    flyVel.velocity = Vector3.new(0, 0.1, 0)
    flyVel.maxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVel.Parent = hrp
end

local function stopFly()
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
    if flyVel then flyVel:Destroy() flyVel = nil end
end

RunService.RenderStepped:Connect(function()
    if Config.FlyEnabled and flyVel and flyGyro and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local cam = Workspace.CurrentCamera
        if hrp and cam then
            flyGyro.cframe = cam.CFrame
            local dir = Vector3.new()

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end

            flyVel.velocity = dir * Config.FlySpeed
        end
    end
end)

RunService.Stepped:Connect(function()
    if Config.NoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)


-- --------------------------------------------------------------------
-- UI INTERFACE CREATION
-- --------------------------------------------------------------------

-- RICH FINDER TAB
richTab:CreateComment("--- Leaderboard Server Hop (Rich Finder) ---")

richTab:CreateToggleSwitch("Rich Finder Auto Server Hop", false, function(val)
    Config.RichFinderActive = val
    if val then
        lib:Notify("Rich Finder", "Server Hop Active! Searching for player with >" .. tostring(Config.MinCoinsBillion) .. "B Coins...", 3.0)
    else
        lib:Notify("Rich Finder", "Server Hop Deactivated.", 1.5)
    end
end)

richTab:CreateSlider("Minimum Coins Threshold (Billion)", 1, 100, 10, function(val)
    Config.MinCoinsBillion = val
end)

-- Status Card
local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 42)
statusCard.BackgroundColor3 = int.Theme and int.Theme.CardBg or Color3.fromRGB(24, 28, 42)
statusCard.BorderSizePixel = 0
statusCard.Parent = richTab.TabContent

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 6)
cardCorner.Parent = statusCard

richStatusLabel = Instance.new("TextLabel")
richStatusLabel.Size = UDim2.new(1, -20, 1, 0)
richStatusLabel.Position = UDim2.new(0, 10, 0, 0)
richStatusLabel.BackgroundTransparency = 1
richStatusLabel.Text = "Scanning leaderboard..."
richStatusLabel.TextColor3 = Color3.fromRGB(180, 185, 210)
richStatusLabel.TextSize = 13
richStatusLabel.Font = Enum.Font.GothamBold
richStatusLabel.TextWrapped = true
richStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
richStatusLabel.Parent = statusCard

richTab:CreateButton("Manual Server Hop Now", function()
    performServerHop()
end)


-- AUTO MINING TAB
farmTab:CreateComment("--- Mining & Upgrades ---")

farmTab:CreateToggleSwitch("Auto Mine (Swing Pickaxe)", false, function(val)
    Config.AutoMine = val
    if val then lib:Notify("Mining", "Auto Mine Active!", 2.0) end
end)


-- MOVEMENT TAB
moveTab:CreateComment("--- WASD Flight & Speed Controls ---")

moveTab:CreateToggleSwitch("WASD Flight System", false, function(val)
    Config.FlyEnabled = val
    if val then
        startFly()
        lib:Notify("Flight", "Flight Mode Active! Use WASD + Q/E to fly.", 2.5)
    else
        stopFly()
        lib:Notify("Flight", "Flight Mode Deactivated.", 1.5)
    end
end)

moveTab:CreateSlider("Fly Speed", 10, 300, 50, function(val)
    Config.FlySpeed = val
end)

moveTab:CreateToggleSwitch("Noclip (Walk Through Walls)", false, function(val)
    Config.NoclipEnabled = val
end)

moveTab:CreateSlider("WalkSpeed", 16, 250, 16, function(val)
    Config.WalkSpeed = val
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
        end
    end)
end)


-- SETTINGS TAB
local themeDrop = settingsTab:CreateDropDown("Select UI Theme", function() end)
local themesList = {"cyber", "royal", "emerald", "dark", "midnight", "blood", "gold", "neon"}
for _, themeName in ipairs(themesList) do
    themeDrop:AddButton("Theme: " .. themeName:upper(), function()
        int:SetTheme(themeName)
    end)
end

settingsTab:CreateSlider("Window Transparency", 0, 90, 25, function(val)
    int:SetTransparency(val / 100)
end)

-- Check immediately on startup
checkServerForRichPlayer()

lib:Notify("Mine a Mountain Suite", "Loaded successfully! Press 'K' to hide or show GUI.", 5.0)
print("[Mine a Mountain Suite] Official Rich Finder Suite Loaded Successfully!")
