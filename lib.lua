--[[
    Roblox UI Library Framework - Glassmorphism Edition (lib.lua)
    Supports Themes, Glass Transparency, Notifications, Keybinds, ColorPickers, Switches, Dropdowns & Animations
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Library = {}

-- Preset Themes with Glass Colors
local DefaultThemes = {
    royal = {
        MainBg = Color3.fromRGB(20, 22, 32),
        HeaderBg = Color3.fromRGB(14, 15, 22),
        SidebarBg = Color3.fromRGB(14, 15, 22),
        CardBg = Color3.fromRGB(28, 31, 44),
        Accent = Color3.fromRGB(130, 85, 245),
        AccentText = Color3.fromRGB(255, 255, 255),
        Stroke = Color3.fromRGB(85, 70, 140),
        TextColor = Color3.fromRGB(245, 245, 250),
        SubText = Color3.fromRGB(160, 165, 195)
    },
    dark = {
        MainBg = Color3.fromRGB(18, 18, 18),
        HeaderBg = Color3.fromRGB(12, 12, 12),
        SidebarBg = Color3.fromRGB(12, 12, 12),
        CardBg = Color3.fromRGB(26, 26, 26),
        Accent = Color3.fromRGB(0, 140, 240),
        AccentText = Color3.fromRGB(255, 255, 255),
        Stroke = Color3.fromRGB(60, 60, 60),
        TextColor = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(150, 150, 150)
    },
    emerald = {
        MainBg = Color3.fromRGB(16, 24, 20),
        HeaderBg = Color3.fromRGB(11, 17, 14),
        SidebarBg = Color3.fromRGB(11, 17, 14),
        CardBg = Color3.fromRGB(22, 34, 28),
        Accent = Color3.fromRGB(0, 200, 120),
        AccentText = Color3.fromRGB(255, 255, 255),
        Stroke = Color3.fromRGB(50, 95, 70),
        TextColor = Color3.fromRGB(235, 248, 240),
        SubText = Color3.fromRGB(140, 175, 155)
    },
    cyber = {
        MainBg = Color3.fromRGB(15, 20, 28),
        HeaderBg = Color3.fromRGB(10, 14, 20),
        SidebarBg = Color3.fromRGB(10, 14, 20),
        CardBg = Color3.fromRGB(22, 29, 40),
        Accent = Color3.fromRGB(0, 220, 255),
        AccentText = Color3.fromRGB(10, 14, 20),
        Stroke = Color3.fromRGB(0, 160, 210),
        TextColor = Color3.fromRGB(235, 245, 255),
        SubText = Color3.fromRGB(140, 170, 200)
    },
    midnight = {
        MainBg = Color3.fromRGB(14, 15, 22),
        HeaderBg = Color3.fromRGB(9, 10, 15),
        SidebarBg = Color3.fromRGB(9, 10, 15),
        CardBg = Color3.fromRGB(20, 22, 32),
        Accent = Color3.fromRGB(255, 110, 180),
        AccentText = Color3.fromRGB(255, 255, 255),
        Stroke = Color3.fromRGB(90, 50, 95),
        TextColor = Color3.fromRGB(245, 240, 250),
        SubText = Color3.fromRGB(160, 145, 175)
    },
    blood = {
        MainBg = Color3.fromRGB(24, 14, 16),
        HeaderBg = Color3.fromRGB(16, 8, 10),
        SidebarBg = Color3.fromRGB(16, 8, 10),
        CardBg = Color3.fromRGB(34, 18, 22),
        Accent = Color3.fromRGB(235, 45, 60),
        AccentText = Color3.fromRGB(255, 255, 255),
        Stroke = Color3.fromRGB(100, 40, 48),
        TextColor = Color3.fromRGB(250, 240, 242),
        SubText = Color3.fromRGB(180, 140, 145)
    },
    gold = {
        MainBg = Color3.fromRGB(24, 22, 16),
        HeaderBg = Color3.fromRGB(16, 14, 10),
        SidebarBg = Color3.fromRGB(16, 14, 10),
        CardBg = Color3.fromRGB(34, 30, 20),
        Accent = Color3.fromRGB(240, 185, 45),
        AccentText = Color3.fromRGB(20, 15, 5),
        Stroke = Color3.fromRGB(105, 85, 38),
        TextColor = Color3.fromRGB(250, 245, 235),
        SubText = Color3.fromRGB(180, 165, 135)
    },
    neon = {
        MainBg = Color3.fromRGB(18, 12, 28),
        HeaderBg = Color3.fromRGB(12, 8, 20),
        SidebarBg = Color3.fromRGB(12, 8, 20),
        CardBg = Color3.fromRGB(28, 18, 42),
        Accent = Color3.fromRGB(50, 255, 150),
        AccentText = Color3.fromRGB(10, 20, 15),
        Stroke = Color3.fromRGB(120, 50, 200),
        TextColor = Color3.fromRGB(245, 240, 255),
        SubText = Color3.fromRGB(175, 145, 205)
    }
}

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

-- Notification Toast Container
local NotificationContainer = nil

function Library:Notify(title, message, duration, icon)
    duration = duration or 3.5

    local parentGui = CoreGui
    pcall(function()
        if not CoreGui:FindFirstChildOfClass("ScreenGui") then
            parentGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
    end)

    if not NotificationContainer or not NotificationContainer.Parent then
        local notifGui = parentGui:FindFirstChild("LibraryNotificationGui") or create("ScreenGui", {
            Name = "LibraryNotificationGui",
            ResetOnSpawn = false,
            Parent = parentGui
        })

        NotificationContainer = notifGui:FindFirstChild("Container") or create("Frame", {
            Name = "Container",
            Size = UDim2.new(0, 280, 1, -20),
            Position = UDim2.new(1, -290, 0, 10),
            BackgroundTransparency = 1,
            Parent = notifGui
        })

        if not NotificationContainer:FindFirstChildOfClass("UIListLayout") then
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 8),
                Parent = NotificationContainer
            })
        end
    end

    local Toast = create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Color3.fromRGB(20, 22, 32),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Parent = NotificationContainer
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Toast })
    local Stroke = create("UIStroke", { Color = Color3.fromRGB(130, 85, 245), Thickness = 1.5, Parent = Toast })

    local TitleLabel = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = title or "Notification",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Toast
    })

    local MsgLabel = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 12, 0, 26),
        BackgroundTransparency = 1,
        Text = message or "",
        TextColor3 = Color3.fromRGB(170, 175, 205),
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Toast
    })

    -- Slide in animation
    Toast.Position = UDim2.new(1, 300, 0, 0)
    TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    task.spawn(function()
        task.wait(duration)
        local fadeOut = TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 300, 0, 0),
            BackgroundTransparency = 1
        })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            Toast:Destroy()
        end)
    end)
end

function Library:CreateInterface(titleText, descText, discordLink, position, themeName, bgTransparency)
    local themeKey = tostring(themeName or "royal"):lower()
    local theme = DefaultThemes[themeKey] or DefaultThemes.royal
    local glassTransparency = bgTransparency or 0.25

    local parentGui = CoreGui
    pcall(function()
        if not CoreGui:FindFirstChildOfClass("ScreenGui") then
            parentGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
    end)

    for _, child in ipairs(parentGui:GetChildren()) do
        if child.Name == "AdminSuiteUI" then
            child:Destroy()
        end
    end

    local themeUpdaters = {}
    local toggleKey = Enum.KeyCode.K

    local ScreenGui = create("ScreenGui", {
        Name = "AdminSuiteUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = parentGui
    })

    -- Main Frame (Glassmorphism Styled)
    local MainFrame = create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 650, 0, 440),
        Position = UDim2.new(0.5, -325, 0.5, -220),
        BackgroundColor3 = theme.MainBg,
        BackgroundTransparency = glassTransparency,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
        Parent = ScreenGui
    })

    create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = MainFrame })
    local MainStroke = create("UIStroke", { Color = theme.Stroke, Thickness = 1.8, Parent = MainFrame })

    -- Glass Gradient Accent Overlay
    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 200))
        }),
        Rotation = 45,
        Parent = MainFrame
    })

    table.insert(themeUpdaters, function(t)
        MainFrame.BackgroundColor3 = t.MainBg
        MainStroke.Color = t.Stroke
    end)

    -- Toggle UI with Key
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    -- Top Header Bar
    local Header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = theme.HeaderBg,
        BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Header })

    local TitleLabel = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 320, 0, 22),
        Position = UDim2.new(0, 15, 0, 6),
        BackgroundTransparency = 1,
        Text = titleText or "Admin Panel",
        TextColor3 = theme.TextColor,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header
    })

    local SubtitleLabel = create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(0, 320, 0, 16),
        Position = UDim2.new(0, 15, 0, 26),
        BackgroundTransparency = 1,
        Text = descText or "Admin & Management Suite",
        TextColor3 = theme.SubText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header
    })

    table.insert(themeUpdaters, function(t)
        Header.BackgroundColor3 = t.HeaderBg
        TitleLabel.TextColor3 = t.TextColor
        SubtitleLabel.TextColor3 = t.SubText
    end)

    -- Control Buttons (Minimize, Close)
    local CloseBtn = create("TextButton", {
        Name = "CloseBtn",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -36, 0, 10),
        BackgroundColor3 = Color3.fromRGB(45, 22, 28),
        Text = "✕",
        TextColor3 = Color3.fromRGB(255, 90, 90),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = Header
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CloseBtn })
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local Minimized = false
    local MinimizeBtn = create("TextButton", {
        Name = "MinimizeBtn",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -70, 0, 10),
        BackgroundColor3 = theme.CardBg,
        Text = "─",
        TextColor3 = theme.SubText,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = Header
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MinimizeBtn })

    -- Discord Button
    local DiscordBtn = nil
    if discordLink and discordLink ~= "" then
        DiscordBtn = create("TextButton", {
            Name = "DiscordBtn",
            Size = UDim2.new(0, 75, 0, 28),
            Position = UDim2.new(1, -152, 0, 10),
            BackgroundColor3 = theme.Accent,
            Text = "Discord",
            TextColor3 = theme.AccentText,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            Parent = Header
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DiscordBtn })

        table.insert(themeUpdaters, function(t)
            DiscordBtn.BackgroundColor3 = t.Accent
            DiscordBtn.TextColor3 = t.AccentText
        end)

        DiscordBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(discordLink)
                DiscordBtn.Text = "Copied!"
                Library:Notify("Clipboard", "Discord link copied to clipboard!", 2.5)
                task.wait(1.5)
                DiscordBtn.Text = "Discord"
            end
        end)
    end

    -- Tab Bar (Left side panel)
    local TabBar = create("ScrollingFrame", {
        Name = "TabBar",
        Size = UDim2.new(0, 160, 1, -58),
        Position = UDim2.new(0, 10, 0, 53),
        BackgroundColor3 = theme.SidebarBg,
        BackgroundTransparency = math.clamp(glassTransparency - 0.05, 0, 1),
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = MainFrame
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = TabBar })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = TabBar
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = TabBar
    })

    table.insert(themeUpdaters, function(t)
        TabBar.BackgroundColor3 = t.SidebarBg
    end)

    -- Content Container (Right side)
    local ContentFolder = create("Folder", {
        Name = "ContentFolder",
        Parent = MainFrame
    })

    local InterfaceObj = {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        TabBar = TabBar,
        ContentFolder = ContentFolder,
        Tabs = {},
        ActiveTab = nil,
        Theme = theme,
        GlassTransparency = glassTransparency
    }

    -- Toggle Minimize Animation with FIXED TAB RESTORE LOGIC
    MinimizeBtn.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        if Minimized then
            TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), { Size = UDim2.new(0, 650, 0, 48) }):Play()
            TabBar.Visible = false
            for _, t in ipairs(InterfaceObj.Tabs) do
                t.TabContent.Visible = false
            end
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), { Size = UDim2.new(0, 650, 0, 440) }):Play()
            task.wait(0.12)
            TabBar.Visible = true
            if InterfaceObj.ActiveTab and InterfaceObj.ActiveTab.Activate then
                InterfaceObj.ActiveTab.Activate()
            end
        end
    end)

    function InterfaceObj:SetTransparency(transparencyVal)
        transparencyVal = math.clamp(transparencyVal or 0.25, 0, 0.9)
        InterfaceObj.GlassTransparency = transparencyVal
        MainFrame.BackgroundTransparency = transparencyVal
        Header.BackgroundTransparency = math.clamp(transparencyVal - 0.1, 0, 1)
        TabBar.BackgroundTransparency = math.clamp(transparencyVal - 0.05, 0, 1)
    end

    function InterfaceObj:SetTheme(newThemeName)
        local key = tostring(newThemeName or "royal"):lower()
        local t = DefaultThemes[key] or DefaultThemes.royal
        InterfaceObj.Theme = t
        theme = t
        for _, updater in ipairs(themeUpdaters) do
            pcall(updater, t)
        end
        if InterfaceObj.ActiveTab and InterfaceObj.ActiveTab.Activate then
            InterfaceObj.ActiveTab.Activate()
        end
    end

    function InterfaceObj:CreateTab(tabName, tabDesc, icon, isDefault)
        local TabBtn = create("TextButton", {
            Name = "TabBtn_" .. tabName,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = theme.CardBg,
            BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
            Text = "  " .. tabName,
            TextColor3 = theme.SubText,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabBar
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBtn })

        -- Content Frame for this Tab
        local TabContent = create("ScrollingFrame", {
            Name = "Content_" .. tabName,
            Size = UDim2.new(1, -185, 1, -58),
            Position = UDim2.new(0, 177, 0, 53),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            Visible = false,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = ContentFolder
        })
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = TabContent
        })
        create("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 15),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 8),
            Parent = TabContent
        })

        local TabObj = {
            TabBtn = TabBtn,
            TabContent = TabContent,
            Name = tabName
        }

        local function activateTab()
            for _, t in ipairs(InterfaceObj.Tabs) do
                t.TabContent.Visible = false
                t.TabBtn.BackgroundColor3 = InterfaceObj.Theme.CardBg
                t.TabBtn.TextColor3 = InterfaceObj.Theme.SubText
            end
            TabContent.Visible = true
            TabBtn.BackgroundColor3 = InterfaceObj.Theme.Accent
            TabBtn.TextColor3 = InterfaceObj.Theme.AccentText
            InterfaceObj.ActiveTab = TabObj
        end
        TabObj.Activate = activateTab

        TabBtn.MouseButton1Click:Connect(activateTab)

        table.insert(themeUpdaters, function(t)
            if InterfaceObj.ActiveTab == TabObj then
                TabBtn.BackgroundColor3 = t.Accent
                TabBtn.TextColor3 = t.AccentText
            else
                TabBtn.BackgroundColor3 = t.CardBg
                TabBtn.TextColor3 = t.SubText
            end
        end)

        table.insert(InterfaceObj.Tabs, TabObj)

        if isDefault or #InterfaceObj.Tabs == 1 then
            activateTab()
        end

        -- -------------------------------------------------------------
        -- ELEMENT BUILDERS
        -- -------------------------------------------------------------

        -- 1. Animated Pill Switch Toggle
        function TabObj:CreateToggleSwitch(labelTitle, defaultState, callback)
            local state = defaultState or false

            local Card = create("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = InterfaceObj.Theme.CardBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                Parent = TabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

            local Label = create("TextLabel", {
                Size = UDim2.new(1, -65, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = labelTitle,
                TextColor3 = InterfaceObj.Theme.TextColor,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Card
            })

            -- Pill Track
            local PillTrack = create("TextButton", {
                Size = UDim2.new(0, 42, 0, 22),
                Position = UDim2.new(1, -50, 0.5, -11),
                BackgroundColor3 = state and InterfaceObj.Theme.Accent or InterfaceObj.Theme.MainBg,
                Text = "",
                Parent = Card
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = PillTrack })

            -- Sliding Pill Knob
            local Knob = create("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = PillTrack
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })

            local function toggleState()
                state = not state
                local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                local targetBg = state and InterfaceObj.Theme.Accent or InterfaceObj.Theme.MainBg

                TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { Position = targetPos }):Play()
                TweenService:Create(PillTrack, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { BackgroundColor3 = targetBg }):Play()

                if callback then pcall(callback, state) end
            end

            PillTrack.MouseButton1Click:Connect(toggleState)
            Label.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    toggleState()
                end
            end)

            table.insert(themeUpdaters, function(t)
                Card.BackgroundColor3 = t.CardBg
                Label.TextColor3 = t.TextColor
                PillTrack.BackgroundColor3 = state and t.Accent or t.MainBg
            end)

            return Card
        end

        -- Checkbox
        function TabObj:CreateCheckbox(labelTitle, callback)
            return TabObj:CreateToggleSwitch(labelTitle, false, callback)
        end

        -- 2. Slider Component
        function TabObj:CreateSlider(labelTitle, minValArg, maxValArg, defaultValArg, callbackArg)
            local minVal, maxVal, defaultVal, callback

            if type(callbackArg) == "function" then
                minVal = minValArg or 0
                maxVal = maxValArg or 500
                defaultVal = defaultValArg or minVal
                callback = callbackArg
            elseif type(defaultValArg) == "function" then
                maxVal = minValArg or 500
                minVal = 0
                defaultVal = maxValArg or 0
                callback = defaultValArg
            else
                minVal = minValArg or 0
                maxVal = maxValArg or 500
                defaultVal = defaultValArg or minVal
                callback = callbackArg
            end

            local Card = create("Frame", {
                Size = UDim2.new(1, 0, 0, 52),
                BackgroundColor3 = InterfaceObj.Theme.CardBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                Parent = TabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

            local Label = create("TextLabel", {
                Size = UDim2.new(0.7, 0, 0, 22),
                Position = UDim2.new(0, 12, 0, 4),
                BackgroundTransparency = 1,
                Text = labelTitle,
                TextColor3 = InterfaceObj.Theme.TextColor,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Card
            })

            local ValueLabel = create("TextLabel", {
                Size = UDim2.new(0.25, 0, 0, 22),
                Position = UDim2.new(0.72, 0, 0, 4),
                BackgroundTransparency = 1,
                Text = tostring(defaultVal),
                TextColor3 = InterfaceObj.Theme.SubText,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = Card
            })

            local SliderTrack = create("TextButton", {
                Size = UDim2.new(1, -24, 0, 8),
                Position = UDim2.new(0, 12, 0, 32),
                BackgroundColor3 = InterfaceObj.Theme.MainBg,
                Text = "",
                Parent = Card
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SliderTrack })

            local fillPercent = math.clamp((defaultVal - minVal) / math.max(maxVal - minVal, 1), 0, 1)
            local SliderFill = create("Frame", {
                Size = UDim2.new(fillPercent, 0, 1, 0),
                BackgroundColor3 = InterfaceObj.Theme.Accent,
                BorderSizePixel = 0,
                Parent = SliderTrack
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SliderFill })

            table.insert(themeUpdaters, function(t)
                Card.BackgroundColor3 = t.CardBg
                Label.TextColor3 = t.TextColor
                ValueLabel.TextColor3 = t.SubText
                SliderTrack.BackgroundColor3 = t.MainBg
                SliderFill.BackgroundColor3 = t.Accent
            end)

            local dragging = false

            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
                local val = math.floor(minVal + (maxVal - minVal) * pos)
                SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                ValueLabel.Text = tostring(val)
                if callback then pcall(callback, val) end
            end

            SliderTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            return Card
        end

        -- 3. Textbox / Input Component
        function TabObj:CreateTextbox(labelTitle, placeholderText, defaultVal, callback)
            local Card = create("Frame", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = InterfaceObj.Theme.CardBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                Parent = TabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

            local Label = create("TextLabel", {
                Size = UDim2.new(0.5, -12, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = labelTitle,
                TextColor3 = InterfaceObj.Theme.TextColor,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Card
            })

            local InputBox = create("TextBox", {
                Size = UDim2.new(0.5, -12, 0, 28),
                Position = UDim2.new(0.5, 0, 0.5, -14),
                BackgroundColor3 = InterfaceObj.Theme.MainBg,
                Text = defaultVal or "",
                PlaceholderText = placeholderText or "Enter value...",
                PlaceholderColor3 = InterfaceObj.Theme.SubText,
                TextColor3 = InterfaceObj.Theme.TextColor,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                ClearTextOnFocus = false,
                Parent = Card
            })
            create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = InputBox })

            InputBox.FocusLost:Connect(function(enterPressed)
                if callback then pcall(callback, InputBox.Text, enterPressed) end
            end)

            table.insert(themeUpdaters, function(t)
                Card.BackgroundColor3 = t.CardBg
                Label.TextColor3 = t.TextColor
                InputBox.BackgroundColor3 = t.MainBg
                InputBox.PlaceholderColor3 = t.SubText
                InputBox.TextColor3 = t.TextColor
            end)

            return Card
        end

        -- 4. Keybind Picker Component
        function TabObj:CreateKeybind(labelTitle, defaultKey, callback)
            local currentKey = defaultKey or Enum.KeyCode.K
            local listening = false

            local Card = create("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = InterfaceObj.Theme.CardBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                Parent = TabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

            local Label = create("TextLabel", {
                Size = UDim2.new(1, -110, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = labelTitle,
                TextColor3 = InterfaceObj.Theme.TextColor,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Card
            })

            local KeyBtn = create("TextButton", {
                Size = UDim2.new(0, 85, 0, 24),
                Position = UDim2.new(1, -95, 0.5, -12),
                BackgroundColor3 = InterfaceObj.Theme.MainBg,
                Text = currentKey.Name,
                TextColor3 = InterfaceObj.Theme.Accent,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                Parent = Card
            })
            create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = KeyBtn })

            KeyBtn.MouseButton1Click:Connect(function()
                listening = true
                KeyBtn.Text = "Press Key..."
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if listening and not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    currentKey = input.KeyCode
                    KeyBtn.Text = currentKey.Name
                    if callback then pcall(callback, currentKey) end
                end
            end)

            table.insert(themeUpdaters, function(t)
                Card.BackgroundColor3 = t.CardBg
                Label.TextColor3 = t.TextColor
                KeyBtn.BackgroundColor3 = t.MainBg
                KeyBtn.TextColor3 = t.Accent
            end)

            return Card
        end

        -- 5. Button Component
        function TabObj:CreateButton(btnText, callback)
            local Card = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = InterfaceObj.Theme.Accent,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                Text = btnText,
                TextColor3 = InterfaceObj.Theme.AccentText,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                Parent = TabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

            Card.MouseButton1Click:Connect(function()
                if callback then pcall(callback) end
            end)

            table.insert(themeUpdaters, function(t)
                Card.BackgroundColor3 = t.Accent
                Card.TextColor3 = t.AccentText
            end)

            return Card
        end

        -- Comment / Header Divider
        function TabObj:CreateComment(text)
            local Card = create("Frame", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = InterfaceObj.Theme.HeaderBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                Parent = TabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

            local commentcontent = create("TextLabel", {
                Name = "commentcontent",
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = text or "",
                TextColor3 = InterfaceObj.Theme.SubText,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Card
            })

            table.insert(themeUpdaters, function(t)
                Card.BackgroundColor3 = t.HeaderBg
                commentcontent.TextColor3 = t.SubText
            end)

            local CommentObj = {
                Card = Card,
                commentcontent = commentcontent
            }

            function CommentObj:SetText(newText)
                commentcontent.Text = newText
            end

            return CommentObj
        end

        -- 6. Searchable Dropdown
        function TabObj:CreateDropDown(dropTitle, callback)
            local isOpen = false

            local DropCard = create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = InterfaceObj.Theme.CardBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = TabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropCard })

            local HeaderBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text = "",
                Parent = DropCard
            })

            local TitleLabel = create("TextLabel", {
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = dropTitle,
                TextColor3 = InterfaceObj.Theme.TextColor,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = HeaderBtn
            })

            local Arrow = create("TextLabel", {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -28, 0.5, -10),
                BackgroundTransparency = 1,
                Text = "▼",
                TextColor3 = InterfaceObj.Theme.SubText,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                Parent = HeaderBtn
            })

            -- Search Bar inside Dropdown
            local SearchFrame = create("Frame", {
                Size = UDim2.new(1, -16, 0, 28),
                Position = UDim2.new(0, 8, 0, 40),
                BackgroundColor3 = InterfaceObj.Theme.MainBg,
                BorderSizePixel = 0,
                Parent = DropCard
            })
            create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = SearchFrame })

            local SearchBox = create("TextBox", {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                PlaceholderText = "🔍 Search options...",
                PlaceholderColor3 = InterfaceObj.Theme.SubText,
                Text = "",
                TextColor3 = InterfaceObj.Theme.TextColor,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = SearchFrame
            })

            local ItemsContainer = create("Frame", {
                Size = UDim2.new(1, -16, 0, 0),
                Position = UDim2.new(0, 8, 0, 74),
                BackgroundTransparency = 1,
                Parent = DropCard
            })
            local ItemLayout = create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = ItemsContainer
            })

            table.insert(themeUpdaters, function(t)
                DropCard.BackgroundColor3 = t.CardBg
                TitleLabel.TextColor3 = t.TextColor
                Arrow.TextColor3 = t.SubText
                SearchFrame.BackgroundColor3 = t.MainBg
                SearchBox.PlaceholderColor3 = t.SubText
                SearchBox.TextColor3 = t.TextColor
            end)

            local function updateDropSize()
                if isOpen then
                    local totalH = 78 + ItemLayout.AbsoluteContentSize.Y
                    DropCard.Size = UDim2.new(1, 0, 0, totalH)
                    Arrow.Text = "▲"
                else
                    DropCard.Size = UDim2.new(1, 0, 0, 36)
                    Arrow.Text = "▼"
                end
            end

            local function filterItems()
                local query = SearchBox.Text:lower()
                for _, child in ipairs(ItemsContainer:GetChildren()) do
                    if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                        local itemText = ""
                        if child:IsA("TextButton") then
                            itemText = child.Text
                        else
                            local label = child:FindFirstChildWhichIsA("TextLabel")
                            if label then itemText = label.Text end
                        end
                        if query == "" or itemText:lower():find(query, 1, true) then
                            child.Visible = true
                        else
                            child.Visible = false
                        end
                    end
                end
                if isOpen then updateDropSize() end
            end

            SearchBox:GetPropertyChangedSignal("Text"):Connect(filterItems)
            ItemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if isOpen then updateDropSize() end
            end)

            HeaderBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                updateDropSize()
            end)

            local DropdownObj = {
                Card = DropCard,
                ItemsContainer = ItemsContainer,
                SearchBox = SearchBox
            }

            function DropdownObj:AddButton(btnText, btnCallback)
                local Btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = InterfaceObj.Theme.MainBg,
                    Text = btnText,
                    TextColor3 = InterfaceObj.Theme.TextColor,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    Parent = ItemsContainer
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Btn })

                table.insert(themeUpdaters, function(t)
                    Btn.BackgroundColor3 = t.MainBg
                    Btn.TextColor3 = t.TextColor
                end)

                Btn.MouseButton1Click:Connect(function()
                    if btnCallback then pcall(btnCallback) end
                end)
                return Btn
            end

            function DropdownObj:AddCheckbox(chkText, chkCallback)
                local chkState = false

                local ChkFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = InterfaceObj.Theme.MainBg,
                    Parent = ItemsContainer
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ChkFrame })

                local ChkLabel = create("TextLabel", {
                    Size = UDim2.new(1, -35, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = chkText,
                    TextColor3 = InterfaceObj.Theme.TextColor,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ChkFrame
                })

                local ChkBox = create("TextButton", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(1, -24, 0.5, -9),
                    BackgroundColor3 = InterfaceObj.Theme.CardBg,
                    Text = "",
                    Parent = ChkFrame
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ChkBox })

                local Ind = create("Frame", {
                    Size = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(0.5, -5, 0.5, -5),
                    BackgroundColor3 = InterfaceObj.Theme.Accent,
                    Visible = false,
                    Parent = ChkBox
                })
                create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = Ind })

                local function toggleChk()
                    chkState = not chkState
                    Ind.Visible = chkState
                    ChkBox.BackgroundColor3 = chkState and InterfaceObj.Theme.Accent or InterfaceObj.Theme.CardBg
                    if chkCallback then pcall(chkCallback, chkState) end
                end

                ChkBox.MouseButton1Click:Connect(toggleChk)
                ChkLabel.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        toggleChk()
                    end
                end)

                table.insert(themeUpdaters, function(t)
                    ChkFrame.BackgroundColor3 = t.MainBg
                    ChkLabel.TextColor3 = t.TextColor
                    ChkBox.BackgroundColor3 = chkState and t.Accent or t.CardBg
                    Ind.BackgroundColor3 = t.Accent
                end)

                return ChkFrame
            end

            return DropdownObj
        end

        return TabObj
    end

    return InterfaceObj
end

return Library
