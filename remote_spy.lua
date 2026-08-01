--[[
    Roblox Advanced Remote Spy & Event Inspector
    Features:
      - 'K' key toggle for UI visibility
      - Draggable UI Frame with modern dark theme
      - Intercepts & logs RemoteEvents (FireServer) & RemoteFunctions (InvokeServer)
      - Displays Remote Name, Method, Full Instance Path, and Formatted Arguments
      - Copy Code / Copy Path button (uses setclipboard & selectable TextBox)
      - Block / Filter button (prevents blocked Remotes from clogging the log or firing)
      - Search / Filter bar to filter logs in real-time
      - Clear logs & Pause logging controls
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

-- State Management
local SpyState = {
    Enabled = true,
    Paused = false,
    BlockedRemotes = {}, -- [RemotePath or Name] = true
    BlockExecution = false, -- If true, blocked remotes are also blocked from sending to server
    Logs = {},
    LogCount = 0,
    MaxLogs = 200,
    SearchQuery = ""
}

-- Utility Functions
local function getPath(instance)
    if not instance then return "nil" end
    local path = instance.Name
    local current = instance.Parent
    while current and current ~= game do
        path = current.Name .. "." .. path
        current = current.Parent
    end
    return "game." .. path
end

local function formatTable(tbl, indent)
    indent = indent or 1
    local spacing = string.rep("  ", indent)
    local result = "{\n"
    for k, v in pairs(tbl) do
        local keyStr = type(k) == "string" and ('["' .. k .. '"]') or ("[" .. tostring(k) .. "]")
        local valStr = ""
        if type(v) == "table" then
            valStr = formatTable(v, indent + 1)
        elseif type(v) == "string" then
            valStr = '"' .. tostring(v) .. '"'
        elseif typeof(v) == "Instance" then
            valStr = getPath(v)
        elseif typeof(v) == "Vector3" then
            valStr = string.format("Vector3.new(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
        elseif typeof(v) == "CFrame" then
            valStr = string.format("CFrame.new(%.2f, %.2f, %.2f)", v.Position.X, v.Position.Y, v.Position.Z)
        elseif typeof(v) == "Color3" then
            valStr = string.format("Color3.fromRGB(%d, %d, %d)", math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255))
        else
            valStr = tostring(v)
        end
        result = result .. spacing .. keyStr .. " = " .. valStr .. ",\n"
    end
    result = result .. string.rep("  ", indent - 1) .. "}"
    return result
end

local function formatArgs(...)
    local args = {...}
    if #args == 0 then return "nil" end
    local formatted = {}
    for i, v in ipairs(args) do
        if type(v) == "table" then
            table.insert(formatted, string.format("[%d] = %s", i, formatTable(v, 1)))
        elseif type(v) == "string" then
            table.insert(formatted, string.format('[%d] = "%s"', i, tostring(v)))
        elseif typeof(v) == "Instance" then
            table.insert(formatted, string.format("[%d] = %s", i, getPath(v)))
        elseif typeof(v) == "Vector3" then
            table.insert(formatted, string.format("[%d] = Vector3.new(%.2f, %.2f, %.2f)", i, v.X, v.Y, v.Z))
        elseif typeof(v) == "CFrame" then
            table.insert(formatted, string.format("[%d] = CFrame.new(%.2f, %.2f, %.2f)", i, v.Position.X, v.Position.Y, v.Position.Z))
        else
            table.insert(formatted, string.format("[%d] = %s", i, tostring(v)))
        end
    end
    return table.concat(formatted, ",\n")
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

-- ScreenGui Setup
local ScreenGui = create("ScreenGui", {
    Name = "AdvancedRemoteSpy",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = parentGui
})

-- Main Frame (Draggable)
local MainFrame = create("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 680, 0, 460),
    Position = UDim2.new(0.5, -340, 0.5, -230),
    BackgroundColor3 = Color3.fromRGB(20, 22, 30),
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
    Parent = ScreenGui
})

create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
create("UIStroke", { Color = Color3.fromRGB(55, 60, 85), Thickness = 1.5, Parent = MainFrame })

-- Top Header Bar
local Header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Color3.fromRGB(14, 15, 22),
    BorderSizePixel = 0,
    Parent = MainFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Header })

local TitleLabel = create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(0, 300, 0, 22),
    Position = UDim2.new(0, 14, 0, 4),
    BackgroundTransparency = 1,
    Text = "📡 Remote Event Inspector",
    TextColor3 = Color3.fromRGB(245, 245, 250),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Header
})

local KeybindNotice = create("TextLabel", {
    Name = "Notice",
    Size = UDim2.new(0, 300, 0, 16),
    Position = UDim2.new(0, 14, 0, 24),
    BackgroundTransparency = 1,
    Text = "Press [K] to toggle window visibility",
    TextColor3 = Color3.fromRGB(140, 150, 180),
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Header
})

-- Header Buttons
local CloseBtn = create("TextButton", {
    Name = "CloseBtn",
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -34, 0, 9),
    BackgroundColor3 = Color3.fromRGB(45, 22, 28),
    Text = "✕",
    TextColor3 = Color3.fromRGB(255, 90, 90),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    Parent = Header
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CloseBtn })
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Controls Toolbar
local Toolbar = create("Frame", {
    Name = "Toolbar",
    Size = UDim2.new(1, -24, 0, 36),
    Position = UDim2.new(0, 12, 0, 52),
    BackgroundColor3 = Color3.fromRGB(14, 15, 22),
    BorderSizePixel = 0,
    Parent = MainFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Toolbar })

local SearchBox = create("TextBox", {
    Name = "SearchBox",
    Size = UDim2.new(0, 220, 0, 26),
    Position = UDim2.new(0, 6, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(26, 29, 40),
    Text = "",
    PlaceholderText = "🔍 Filter by Remote Name/Path...",
    PlaceholderColor3 = Color3.fromRGB(120, 130, 160),
    TextColor3 = Color3.fromRGB(240, 240, 250),
    TextSize = 12,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Toolbar
})
create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = SearchBox })
create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = SearchBox })

local PauseBtn = create("TextButton", {
    Name = "PauseBtn",
    Size = UDim2.new(0, 90, 0, 26),
    Position = UDim2.new(0, 234, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(0, 120, 215),
    Text = "⏸ Pause",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 12,
    Font = Enum.Font.GothamMedium,
    Parent = Toolbar
})
create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = PauseBtn })

local ClearBtn = create("TextButton", {
    Name = "ClearBtn",
    Size = UDim2.new(0, 85, 0, 26),
    Position = UDim2.new(0, 330, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(40, 44, 58),
    Text = "🗑 Clear",
    TextColor3 = Color3.fromRGB(230, 235, 245),
    TextSize = 12,
    Font = Enum.Font.GothamMedium,
    Parent = Toolbar
})
create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ClearBtn })

local UnblockBtn = create("TextButton", {
    Name = "UnblockBtn",
    Size = UDim2.new(0, 110, 0, 26),
    Position = UDim2.new(0, 421, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(40, 44, 58),
    Text = "🔓 Clear Blocked",
    TextColor3 = Color3.fromRGB(230, 235, 245),
    TextSize = 12,
    Font = Enum.Font.GothamMedium,
    Parent = Toolbar
})
create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = UnblockBtn })

local BlockModeToggle = create("TextButton", {
    Name = "BlockModeToggle",
    Size = UDim2.new(0, 125, 0, 26),
    Position = UDim2.new(1, -131, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(40, 44, 58),
    Text = "Block Exec: OFF",
    TextColor3 = Color3.fromRGB(180, 190, 210),
    TextSize = 11,
    Font = Enum.Font.GothamMedium,
    Parent = Toolbar
})
create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = BlockModeToggle })

-- Scroll Frame for Logs
local LogScroll = create("ScrollingFrame", {
    Name = "LogScroll",
    Size = UDim2.new(1, -24, 1, -96),
    Position = UDim2.new(0, 12, 0, 92),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Parent = MainFrame
})
create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
    Parent = LogScroll
})
create("UIPadding", {
    PaddingTop = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 6),
    Parent = LogScroll
})

-- Toggle Controls
PauseBtn.MouseButton1Click:Connect(function()
    SpyState.Paused = not SpyState.Paused
    if SpyState.Paused then
        PauseBtn.Text = "▶ Resume"
        PauseBtn.BackgroundColor3 = Color3.fromRGB(220, 130, 0)
    else
        PauseBtn.Text = "⏸ Pause"
        PauseBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(LogScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    SpyState.Logs = {}
    SpyState.LogCount = 0
end)

UnblockBtn.MouseButton1Click:Connect(function()
    SpyState.BlockedRemotes = {}
    UnblockBtn.Text = "Cleared!"
    task.wait(1)
    UnblockBtn.Text = "🔓 Clear Blocked"
end)

BlockModeToggle.MouseButton1Click:Connect(function()
    SpyState.BlockExecution = not SpyState.BlockExecution
    if SpyState.BlockExecution then
        BlockModeToggle.Text = "Block Exec: ON"
        BlockModeToggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        BlockModeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        BlockModeToggle.Text = "Block Exec: OFF"
        BlockModeToggle.BackgroundColor3 = Color3.fromRGB(40, 44, 58)
        BlockModeToggle.TextColor3 = Color3.fromRGB(180, 190, 210)
    end
end)

-- Search Filtering
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    SpyState.SearchQuery = SearchBox.Text:lower()
    for _, card in ipairs(LogScroll:GetChildren()) do
        if card:IsA("Frame") and card:FindFirstChild("SearchKey") then
            local key = card.SearchKey.Value:lower()
            if SpyState.SearchQuery == "" or string.find(key, SpyState.SearchQuery, 1, true) then
                card.Visible = true
            else
                card.Visible = false
            end
        end
    end
end)

-- UI Log Builder
local function addLogEntry(remoteInstance, method, args)
    if SpyState.Paused then return end
    
    local remoteName = remoteInstance and remoteInstance.Name or "UnknownRemote"
    local remotePath = getPath(remoteInstance)

    if SpyState.BlockedRemotes[remoteName] or SpyState.BlockedRemotes[remotePath] then
        return
    end

    SpyState.LogCount = SpyState.LogCount + 1
    local entryIndex = SpyState.LogCount
    local timeStr = os.date("%H:%M:%S")

    local formattedArgsStr = formatArgs(unpack(args))
    local fullScriptCode = string.format("local remote = %s\nremote:%s(%s)", remotePath, method, formattedArgsStr)

    -- Log Entry Card
    local Card = create("Frame", {
        Name = "LogCard_" .. entryIndex,
        Size = UDim2.new(1, 0, 0, 110),
        BackgroundColor3 = Color3.fromRGB(26, 29, 40),
        BorderSizePixel = 0,
        Parent = LogScroll
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })
    create("UIStroke", { Color = Color3.fromRGB(45, 50, 68), Thickness = 1, Parent = Card })

    local SearchKey = create("StringValue", {
        Name = "SearchKey",
        Value = remoteName .. " " .. remotePath .. " " .. method .. " " .. formattedArgsStr,
        Parent = Card
    })

    -- Card Top Bar
    local CardHeader = create("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Color3.fromRGB(18, 20, 28),
        BorderSizePixel = 0,
        Parent = Card
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CardHeader })

    local MethodBadge = create("TextLabel", {
        Size = UDim2.new(0, 75, 0, 18),
        Position = UDim2.new(0, 8, 0.5, -9),
        BackgroundColor3 = method == "FireServer" and Color3.fromRGB(0, 140, 220) or Color3.fromRGB(160, 80, 220),
        Text = method,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = CardHeader
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = MethodBadge })

    local RemoteTitle = create("TextLabel", {
        Size = UDim2.new(1, -260, 1, 0),
        Position = UDim2.new(0, 90, 0, 0),
        BackgroundTransparency = 1,
        Text = string.format("#%d  [%s]  %s", entryIndex, timeStr, remoteName),
        TextColor3 = Color3.fromRGB(240, 240, 250),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = CardHeader
    })

    -- Action Buttons on Entry
    local CopyCodeBtn = create("TextButton", {
        Size = UDim2.new(0, 70, 0, 18),
        Position = UDim2.new(1, -155, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(40, 44, 60),
        Text = "📋 Code",
        TextColor3 = Color3.fromRGB(220, 225, 240),
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        Parent = CardHeader
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = CopyCodeBtn })

    local BlockBtn = create("TextButton", {
        Size = UDim2.new(0, 70, 0, 18),
        Position = UDim2.new(1, -80, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(70, 30, 35),
        Text = "🚫 Block",
        TextColor3 = Color3.fromRGB(255, 120, 120),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = CardHeader
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = BlockBtn })

    -- Path Box
    local PathBox = create("TextBox", {
        Size = UDim2.new(1, -16, 0, 20),
        Position = UDim2.new(0, 8, 0, 30),
        BackgroundColor3 = Color3.fromRGB(18, 20, 28),
        Text = remotePath,
        TextColor3 = Color3.fromRGB(150, 165, 195),
        TextSize = 11,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = Card
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = PathBox })
    create("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = PathBox })

    -- Args Box (Selectable / Copyable)
    local ArgsBox = create("TextBox", {
        Size = UDim2.new(1, -16, 0, 52),
        Position = UDim2.new(0, 8, 0, 53),
        BackgroundColor3 = Color3.fromRGB(18, 20, 28),
        Text = formattedArgsStr,
        TextColor3 = Color3.fromRGB(120, 220, 170),
        TextSize = 11,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        MultiLine = true,
        ClearTextOnFocus = false,
        Parent = Card
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ArgsBox })
    create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), Parent = ArgsBox })

    -- Copy Code Functionality
    CopyCodeBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(fullScriptCode)
            CopyCodeBtn.Text = "Copied!"
            CopyCodeBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 90)
            task.wait(1.2)
            CopyCodeBtn.Text = "📋 Code"
            CopyCodeBtn.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
        else
            ArgsBox:CaptureFocus()
        end
    end)

    -- Block Event Functionality
    BlockBtn.MouseButton1Click:Connect(function()
        SpyState.BlockedRemotes[remoteName] = true
        SpyState.BlockedRemotes[remotePath] = true
        Card:Destroy()
    end)

    -- Check Search Filter for newly added card
    if SpyState.SearchQuery ~= "" and not string.find(SearchKey.Value:lower(), SpyState.SearchQuery, 1, true) then
        Card.Visible = false
    end
end

-- Keybind Toggle (K Key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.K then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Metatable Hook for Intercepting Client-Side Remote Calls
local function setupHooks()
    local success, err = pcall(function()
        local gmt = getrawmetatable(game)
        local oldNamecall = gmt.__namecall
        setreadonly(gmt, false)

        gmt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and type(self) == "userdata" and (method == "FireServer" or method == "InvokeServer") then
                if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    local remoteName = self.Name
                    local remotePath = getPath(self)

                    if SpyState.BlockedRemotes[remoteName] or SpyState.BlockedRemotes[remotePath] then
                        if SpyState.BlockExecution then
                            return nil
                        end
                    else
                        local args = {...}
                        task.spawn(function()
                            addLogEntry(self, method, args)
                        end)
                    end
                end
            end
            return oldNamecall(self, ...)
        end)

        setreadonly(gmt, true)
    end)

    if not success then
        -- Fallback: Scan workspace & ReplicatedStorage for RemoteEvents
        warn("[Remote Spy] Hookmetamethod not available. Operating in Fallback Listener mode.")
        local function attachListener(remote)
            if remote:IsA("RemoteEvent") then
                remote.OnClientEvent:Connect(function(...)
                    addLogEntry(remote, "OnClientEvent", {...})
                end)
            end
        end

        for _, instance in ipairs(game:GetDescendants()) do
            if instance:IsA("RemoteEvent") then
                pcall(attachListener, instance)
            end
        end

        game.DescendantAdded:Connect(function(instance)
            if instance:IsA("RemoteEvent") then
                pcall(attachListener, instance)
            end
        end)
    end
end

setupHooks()
