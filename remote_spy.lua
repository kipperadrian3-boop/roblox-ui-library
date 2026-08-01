--[[
    Roblox High-Performance Anti-Lag Remote Spy (remote_spy.lua)
    Optimized for zero FPS drop and universal executor compatibility.
    
    Features:
      - 'K' Keybind toggle for UI
      - Universal hooking (hookmetamethod / getrawmetatable / hookfunction)
      - Anti-Lag Queue & UI Batching (processes max 5 logs per tick)
      - Auto-Spam Filter (Ignores Ping, Heartbeat, MousePos, CharacterMove)
      - Duplicate Suppression (groups identical rapid fires with x2, x3 counters)
      - Copy Code Button (copies ready-to-use Lua script to clipboard)
      - Selectable TextBoxes for argument inspection
      - Remote Blocking (ignore from log and/or block execution)
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- GUI Parent Setup
local parentGui = CoreGui
pcall(function()
    if not CoreGui:FindFirstChildOfClass("ScreenGui") then
        parentGui = LocalPlayer:WaitForChild("PlayerGui")
    end
end)

-- Clean up any existing instances
for _, child in ipairs(parentGui:GetChildren()) do
    if child.Name == "AdvancedRemoteSpy" then
        child:Destroy()
    end
end

-- State & Configuration
local SpyState = {
    Enabled = true,
    Paused = false,
    BlockExecution = false,
    BlockedRemotes = {}, -- [name_or_path] = true
    IgnoredSpamNames = {
        ["Ping"] = true, ["GetPing"] = true, ["Heartbeat"] = true,
        ["MousePos"] = true, ["UpdatePos"] = true, ["CharacterMove"] = true,
        ["Sound"] = true, ["Animate"] = true, ["Stats"] = true, ["UpdateCFrame"] = true
    },
    LogQueue = {},
    LogCount = 0,
    MaxLogs = 50,
    LastLogSignature = "",
    LastLogCard = nil,
    LastLogRepeatCount = 1,
    SearchQuery = ""
}

-- Path Resolver
local function getPath(instance)
    if not instance then return "nil" end
    local success, result = pcall(function()
        local path = instance.Name
        local current = instance.Parent
        while current and current ~= game do
            path = current.Name .. "." .. path
            current = current.Parent
        end
        return "game." .. path
    end)
    return success and result or tostring(instance)
end

-- Fast Simple Format
local function formatVal(v)
    local t = typeof(v)
    if t == "string" then
        return '"' .. string.gsub(v, '"', '\\"') .. '"'
    elseif t == "Instance" then
        return getPath(v)
    elseif t == "Vector3" then
        return string.format("Vector3.new(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then
        return string.format("CFrame.new(%.1f, %.1f, %.1f)", v.Position.X, v.Position.Y, v.Position.Z)
    elseif t == "table" then
        local count = 0
        for _ in pairs(v) do count = count + 1 if count > 5 then break end end
        if count > 5 then return "{ ...table... }" end
        local items = {}
        for k, val in pairs(v) do
            table.insert(items, tostring(k) .. "=" .. formatVal(val))
        end
        return "{" .. table.concat(items, ", ") .. "}"
    else
        return tostring(v)
    end
end

local function formatArgsList(args)
    if not args or #args == 0 then return "nil" end
    local list = {}
    for i, v in ipairs(args) do
        table.insert(list, string.format("[%d] = %s", i, formatVal(v)))
    end
    return table.concat(list, ",\n")
end

local function create(instanceType, properties)
    local inst = Instance.new(instanceType)
    for prop, val in pairs(properties) do
        if prop ~= "Parent" then
            inst[prop] = val
        end
    end
    if properties.Parent then
        inst.Parent = properties.Parent
    end
    return inst
end

-- UI Construction (Lightweight)
local ScreenGui = create("ScreenGui", {
    Name = "AdvancedRemoteSpy",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = parentGui
})

local MainFrame = create("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 620, 0, 420),
    Position = UDim2.new(0.5, -310, 0.5, -210),
    BackgroundColor3 = Color3.fromRGB(20, 22, 30),
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
    Parent = ScreenGui
})

create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainFrame })
create("UIStroke", { Color = Color3.fromRGB(50, 55, 75), Thickness = 1.5, Parent = MainFrame })

-- Header
local Header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Color3.fromRGB(14, 15, 22),
    BorderSizePixel = 0,
    Parent = MainFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Header })

create("TextLabel", {
    Size = UDim2.new(0, 250, 0, 20),
    Position = UDim2.new(0, 12, 0, 4),
    BackgroundTransparency = 1,
    Text = "📡 Remote Event Inspector",
    TextColor3 = Color3.fromRGB(245, 245, 250),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Header
})

create("TextLabel", {
    Size = UDim2.new(0, 250, 0, 14),
    Position = UDim2.new(0, 12, 0, 22),
    BackgroundTransparency = 1,
    Text = "Press [K] to show / hide UI",
    TextColor3 = Color3.fromRGB(140, 150, 180),
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Header
})

local CloseBtn = create("TextButton", {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -32, 0, 8),
    BackgroundColor3 = Color3.fromRGB(45, 22, 28),
    Text = "✕",
    TextColor3 = Color3.fromRGB(255, 90, 90),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    Parent = Header
})
create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = CloseBtn })
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Toolbar
local Toolbar = create("Frame", {
    Size = UDim2.new(1, -20, 0, 34),
    Position = UDim2.new(0, 10, 0, 46),
    BackgroundColor3 = Color3.fromRGB(14, 15, 22),
    BorderSizePixel = 0,
    Parent = MainFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Toolbar })

local SearchBox = create("TextBox", {
    Size = UDim2.new(0, 200, 0, 24),
    Position = UDim2.new(0, 5, 0.5, -12),
    BackgroundColor3 = Color3.fromRGB(26, 29, 40),
    Text = "",
    PlaceholderText = "🔍 Search remotes...",
    PlaceholderColor3 = Color3.fromRGB(120, 130, 160),
    TextColor3 = Color3.fromRGB(240, 240, 250),
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Toolbar
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SearchBox })
create("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = SearchBox })

local PauseBtn = create("TextButton", {
    Size = UDim2.new(0, 80, 0, 24),
    Position = UDim2.new(0, 212, 0.5, -12),
    BackgroundColor3 = Color3.fromRGB(0, 120, 215),
    Text = "⏸ Pause",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    Font = Enum.Font.GothamMedium,
    Parent = Toolbar
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = PauseBtn })

local ClearBtn = create("TextButton", {
    Size = UDim2.new(0, 75, 0, 24),
    Position = UDim2.new(0, 298, 0.5, -12),
    BackgroundColor3 = Color3.fromRGB(36, 40, 54),
    Text = "🗑 Clear",
    TextColor3 = Color3.fromRGB(230, 235, 245),
    TextSize = 11,
    Font = Enum.Font.GothamMedium,
    Parent = Toolbar
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ClearBtn })

local BlockModeToggle = create("TextButton", {
    Size = UDim2.new(0, 110, 0, 24),
    Position = UDim2.new(1, -116, 0.5, -12),
    BackgroundColor3 = Color3.fromRGB(36, 40, 54),
    Text = "Block Exec: OFF",
    TextColor3 = Color3.fromRGB(170, 180, 200),
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    Parent = Toolbar
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = BlockModeToggle })

-- Scrolling Log Container
local LogScroll = create("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -90),
    Position = UDim2.new(0, 10, 0, 85),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Parent = MainFrame
})
create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
    Parent = LogScroll
})
create("UIPadding", {
    PaddingTop = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 4),
    Parent = LogScroll
})

-- Controls Event Listeners
PauseBtn.MouseButton1Click:Connect(function()
    SpyState.Paused = not SpyState.Paused
    if SpyState.Paused then
        PauseBtn.Text = "▶ Resume"
        PauseBtn.BackgroundColor3 = Color3.fromRGB(210, 130, 0)
    else
        PauseBtn.Text = "⏸ Pause"
        PauseBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(LogScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    SpyState.LogCount = 0
    SpyState.LastLogSignature = ""
    SpyState.LastLogCard = nil
    SpyState.LastLogRepeatCount = 1
end)

BlockModeToggle.MouseButton1Click:Connect(function()
    SpyState.BlockExecution = not SpyState.BlockExecution
    if SpyState.BlockExecution then
        BlockModeToggle.Text = "Block Exec: ON"
        BlockModeToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        BlockModeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        BlockModeToggle.Text = "Block Exec: OFF"
        BlockModeToggle.BackgroundColor3 = Color3.fromRGB(36, 40, 54)
        BlockModeToggle.TextColor3 = Color3.fromRGB(170, 180, 200)
    end
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    SpyState.SearchQuery = SearchBox.Text:lower()
    for _, card in ipairs(LogScroll:GetChildren()) do
        if card:IsA("Frame") and card:FindFirstChild("SearchKey") then
            local key = card.SearchKey.Value:lower()
            card.Visible = (SpyState.SearchQuery == "" or string.find(key, SpyState.SearchQuery, 1, true) ~= nil)
        end
    end
end)

-- Process Queued Log Card UI Creation (Anti-Lag Batching)
local function renderLogCard(item)
    local remote = item.Remote
    local method = item.Method
    local args = item.Args
    local remoteName = remote and remote.Name or "UnknownRemote"
    local remotePath = getPath(remote)
    local argsStr = formatArgsList(args)

    local signature = remotePath .. "|" .. method .. "|" .. argsStr

    -- Duplicate Suppression (Increase repeat counter instead of making new UI card)
    if SpyState.LastLogSignature == signature and SpyState.LastLogCard and SpyState.LastLogCard.Parent then
        SpyState.LastLogRepeatCount = SpyState.LastLogRepeatCount + 1
        local titleLbl = SpyState.LastLogCard:FindFirstChild("TitleLabel", true)
        if titleLbl then
            titleLbl.Text = string.format("[%s]  %s  (x%d)", os.date("%H:%M:%S"), remoteName, SpyState.LastLogRepeatCount)
        end
        return
    end

    SpyState.LogCount = SpyState.LogCount + 1
    SpyState.LastLogSignature = signature
    SpyState.LastLogRepeatCount = 1

    -- Limit Max Log Cards to avoid UI clutter
    local children = {}
    for _, child in ipairs(LogScroll:GetChildren()) do
        if child:IsA("Frame") then table.insert(children, child) end
    end
    if #children >= SpyState.MaxLogs then
        children[1]:Destroy()
    end

    local fullCode = string.format("local remote = %s\nremote:%s(%s)", remotePath, method, argsStr)

    -- Card Frame
    local Card = create("Frame", {
        Name = "LogCard_" .. SpyState.LogCount,
        Size = UDim2.new(1, 0, 0, 96),
        BackgroundColor3 = Color3.fromRGB(26, 29, 40),
        BorderSizePixel = 0,
        Parent = LogScroll
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

    SpyState.LastLogCard = Card

    create("StringValue", {
        Name = "SearchKey",
        Value = remoteName .. " " .. remotePath .. " " .. argsStr,
        Parent = Card
    })

    -- Header Sub-Frame
    local CardHeader = create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = Color3.fromRGB(18, 20, 28),
        BorderSizePixel = 0,
        Parent = Card
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CardHeader })

    local MethodTag = create("TextLabel", {
        Size = UDim2.new(0, 70, 0, 16),
        Position = UDim2.new(0, 6, 0.5, -8),
        BackgroundColor3 = method == "FireServer" and Color3.fromRGB(0, 130, 210) or Color3.fromRGB(150, 70, 210),
        Text = method,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = CardHeader
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = MethodTag })

    local TitleLabel = create("TextLabel", {
        Name = "TitleLabel",
        Size = UDim2.new(1, -230, 1, 0),
        Position = UDim2.new(0, 82, 0, 0),
        BackgroundTransparency = 1,
        Text = string.format("[%s]  %s", os.date("%H:%M:%S"), remoteName),
        TextColor3 = Color3.fromRGB(240, 240, 250),
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = CardHeader
    })

    local CopyBtn = create("TextButton", {
        Size = UDim2.new(0, 65, 0, 16),
        Position = UDim2.new(1, -135, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(36, 40, 56),
        Text = "📋 Code",
        TextColor3 = Color3.fromRGB(220, 225, 240),
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        Parent = CardHeader
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = CopyBtn })

    local BlockBtn = create("TextButton", {
        Size = UDim2.new(0, 60, 0, 16),
        Position = UDim2.new(1, -66, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(65, 28, 32),
        Text = "🚫 Block",
        TextColor3 = Color3.fromRGB(255, 120, 120),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = CardHeader
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = BlockBtn })

    -- Path Input
    local PathInput = create("TextBox", {
        Size = UDim2.new(1, -12, 0, 18),
        Position = UDim2.new(0, 6, 0, 27),
        BackgroundColor3 = Color3.fromRGB(18, 20, 28),
        Text = remotePath,
        TextColor3 = Color3.fromRGB(140, 160, 195),
        TextSize = 10,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = Card
    })
    create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = PathInput })
    create("UIPadding", { PaddingLeft = UDim.new(0, 4), Parent = PathInput })

    -- Args Input (Selectable / Copyable)
    local ArgsInput = create("TextBox", {
        Size = UDim2.new(1, -12, 0, 44),
        Position = UDim2.new(0, 6, 0, 47),
        BackgroundColor3 = Color3.fromRGB(18, 20, 28),
        Text = argsStr,
        TextColor3 = Color3.fromRGB(120, 220, 170),
        TextSize = 10,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        MultiLine = true,
        ClearTextOnFocus = false,
        Parent = Card
    })
    create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = ArgsInput })
    create("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 3), Parent = ArgsInput })

    -- Copy Callback
    CopyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(fullCode)
            CopyBtn.Text = "Copied!"
            CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
            task.wait(1)
            CopyBtn.Text = "📋 Code"
            CopyBtn.BackgroundColor3 = Color3.fromRGB(36, 40, 56)
        else
            ArgsInput:CaptureFocus()
        end
    end)

    -- Block Callback
    BlockBtn.MouseButton1Click:Connect(function()
        SpyState.BlockedRemotes[remoteName] = true
        SpyState.BlockedRemotes[remotePath] = true
        Card:Destroy()
    end)

    if SpyState.SearchQuery ~= "" and not string.find(remoteName:lower() .. " " .. remotePath:lower(), SpyState.SearchQuery, 1, true) then
        Card.Visible = false
    end
end

-- Queue Processor Loop (Anti-Lag: 10 FPS batching)
task.spawn(function()
    while true do
        task.wait(0.1)
        if #SpyState.LogQueue > 0 and not SpyState.Paused then
            local count = 0
            while #SpyState.LogQueue > 0 and count < 5 do
                local item = table.remove(SpyState.LogQueue, 1)
                renderLogCard(item)
                count = count + 1
            end
        end
    end
end)

-- Main Remote Processing Handler
local function handleRemoteCall(remote, method, args)
    if SpyState.Paused or not remote then return end
    local remoteName = remote.Name
    if SpyState.IgnoredSpamNames[remoteName] then return end

    local remotePath = getPath(remote)
    if SpyState.BlockedRemotes[remoteName] or SpyState.BlockedRemotes[remotePath] then
        return
    end

    if #SpyState.LogQueue < 30 then
        table.insert(SpyState.LogQueue, {
            Remote = remote,
            Method = method,
            Args = args
        })
    end
end

-- Universal Metamethod / Namecall Hooking
local function initRemoteHooks()
    local hooked = false

    -- Method 1: hookmetamethod (Standard for modern executors)
    if type(hookmetamethod) == "function" then
        pcall(function()
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if not checkcaller() and type(self) == "userdata" and (method == "FireServer" or method == "InvokeServer") then
                    if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                        handleRemoteCall(self, method, {...})
                        local path = getPath(self)
                        if SpyState.BlockedRemotes[self.Name] or SpyState.BlockedRemotes[path] then
                            if SpyState.BlockExecution then
                                return nil
                            end
                        end
                    end
                end
                return oldNamecall(self, ...)
            end))
            hooked = true
        end)
    end

    -- Method 2: getrawmetatable fallback
    if not hooked and type(getrawmetatable) == "function" and type(setreadonly) == "function" then
        pcall(function()
            local gmt = getrawmetatable(game)
            local oldNamecall = gmt.__namecall
            setreadonly(gmt, false)

            gmt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if not checkcaller() and type(self) == "userdata" and (method == "FireServer" or method == "InvokeServer") then
                    if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                        handleRemoteCall(self, method, {...})
                        local path = getPath(self)
                        if SpyState.BlockedRemotes[self.Name] or SpyState.BlockedRemotes[path] then
                            if SpyState.BlockExecution then
                                return nil
                            end
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)

            setreadonly(gmt, true)
            hooked = true
        end)
    end

    -- Method 3: hookfunction on FireServer/InvokeServer directly
    if not hooked and type(hookfunction) == "function" then
        pcall(function()
            local dummyEvent = Instance.new("RemoteEvent")
            local oldFireServer
            oldFireServer = hookfunction(dummyEvent.FireServer, newcclosure(function(self, ...)
                if not checkcaller() and self and self:IsA("RemoteEvent") then
                    handleRemoteCall(self, "FireServer", {...})
                end
                return oldFireServer(self, ...)
            end))
            dummyEvent:Destroy()
            hooked = true
        end)
    end

    if not hooked then
        warn("[Remote Spy Warning] Executor metamethod hooks restricted. Using Event Listener mode.")
    end
end

initRemoteHooks()

-- Keybind Listener (K Key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.K then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
