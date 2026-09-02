--[[
    Universal Premium UI Library (lib.lua)
    Engineered for Roblox Exploits with Full JSON Auto-Save & Nested Dynamic Sections
]]

local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)

local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local RunService: RunService = cloneref(game:GetService("RunService"))

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.ActiveInterfaces = {}
Library.CurrentTheme = nil

-- -------------------------------------------------------------
-- THEME DEFINITIONS
-- -------------------------------------------------------------
local DefaultThemes = {
    emerald = {
        MainBg = Color3.fromRGB(18, 22, 26),
        HeaderBg = Color3.fromRGB(12, 16, 20),
        SidebarBg = Color3.fromRGB(14, 18, 22),
        CardBg = Color3.fromRGB(24, 30, 36),
        TextColor = Color3.fromRGB(240, 245, 250),
        SubText = Color3.fromRGB(140, 160, 180),
        Accent = Color3.fromRGB(46, 204, 113),
        AccentText = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(35, 45, 55)
    },
    cyber = {
        MainBg = Color3.fromRGB(15, 15, 25),
        HeaderBg = Color3.fromRGB(10, 10, 18),
        SidebarBg = Color3.fromRGB(12, 12, 20),
        CardBg = Color3.fromRGB(22, 22, 36),
        TextColor = Color3.fromRGB(235, 240, 255),
        SubText = Color3.fromRGB(130, 140, 180),
        Accent = Color3.fromRGB(0, 230, 255),
        AccentText = Color3.fromRGB(10, 10, 20),
        Border = Color3.fromRGB(30, 35, 60)
    },
    royal = {
        MainBg = Color3.fromRGB(20, 22, 32),
        HeaderBg = Color3.fromRGB(14, 15, 22),
        SidebarBg = Color3.fromRGB(14, 15, 22),
        CardBg = Color3.fromRGB(28, 31, 44),
        TextColor = Color3.fromRGB(245, 245, 250),
        SubText = Color3.fromRGB(150, 155, 180),
        Accent = Color3.fromRGB(130, 85, 245),
        AccentText = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(40, 44, 62)
    },
    dark = {
        MainBg = Color3.fromRGB(22, 22, 22),
        HeaderBg = Color3.fromRGB(16, 16, 16),
        SidebarBg = Color3.fromRGB(18, 18, 18),
        CardBg = Color3.fromRGB(28, 28, 28),
        TextColor = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(150, 150, 150),
        Accent = Color3.fromRGB(255, 255, 255),
        AccentText = Color3.fromRGB(20, 20, 20),
        Border = Color3.fromRGB(45, 45, 45)
    },
    midnight = {
        MainBg = Color3.fromRGB(10, 12, 18),
        HeaderBg = Color3.fromRGB(6, 8, 12),
        SidebarBg = Color3.fromRGB(8, 10, 15),
        CardBg = Color3.fromRGB(16, 20, 30),
        TextColor = Color3.fromRGB(230, 235, 245),
        SubText = Color3.fromRGB(120, 130, 160),
        Accent = Color3.fromRGB(80, 140, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(25, 32, 48)
    },
    blood = {
        MainBg = Color3.fromRGB(22, 14, 16),
        HeaderBg = Color3.fromRGB(15, 9, 10),
        SidebarBg = Color3.fromRGB(17, 10, 12),
        CardBg = Color3.fromRGB(32, 18, 22),
        TextColor = Color3.fromRGB(250, 240, 240),
        SubText = Color3.fromRGB(180, 140, 145),
        Accent = Color3.fromRGB(235, 60, 75),
        AccentText = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(55, 25, 32)
    },
    gold = {
        MainBg = Color3.fromRGB(24, 22, 16),
        HeaderBg = Color3.fromRGB(16, 15, 10),
        SidebarBg = Color3.fromRGB(19, 17, 12),
        CardBg = Color3.fromRGB(35, 31, 22),
        TextColor = Color3.fromRGB(250, 248, 240),
        SubText = Color3.fromRGB(185, 175, 145),
        Accent = Color3.fromRGB(245, 185, 45),
        AccentText = Color3.fromRGB(20, 18, 10),
        Border = Color3.fromRGB(60, 52, 30)
    },
    neon = {
        MainBg = Color3.fromRGB(14, 14, 18),
        HeaderBg = Color3.fromRGB(9, 9, 12),
        SidebarBg = Color3.fromRGB(11, 11, 15),
        CardBg = Color3.fromRGB(22, 22, 30),
        TextColor = Color3.fromRGB(245, 245, 250),
        SubText = Color3.fromRGB(145, 145, 170),
        Accent = Color3.fromRGB(255, 0, 128),
        AccentText = Color3.fromRGB(255, 255, 255),
        Border = Color3.fromRGB(45, 30, 50)
    }
}

-- Default active theme
Library.CurrentTheme = DefaultThemes.emerald

-- -------------------------------------------------------------
-- HELPER FUNCTIONS
-- -------------------------------------------------------------
local function getParentGui()
    local success, result = pcall(function()
        return CoreGui:FindFirstChildWhichIsA("ScreenGui") and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    end)
    if success and result then return result end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function create(className, properties)
    local inst = Instance.new(className)
    for prop, val in pairs(properties or {}) do
        inst[prop] = val
    end
    return inst
end

-- -------------------------------------------------------------
-- NOTIFICATION SYSTEM
-- -------------------------------------------------------------
local NotificationContainer = nil

function Library:Notify(title, message, duration)
    duration = duration or 3.5
    local parentGui = getParentGui()

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

    local theme = Library.CurrentTheme or DefaultThemes.emerald

    local Toast = create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        Position = UDim2.new(1, 100, 0, 0),
        BackgroundColor3 = theme.MainBg,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Parent = NotificationContainer
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Toast })
    local Stroke = create("UIStroke", { Color = theme.Accent, Thickness = 1.5, Parent = Toast })

    local TitleLabel = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = title or "Notification",
        TextColor3 = theme.TextColor,
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
        TextColor3 = theme.SubText,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = Toast
    })

    -- Slide in animation
    Toast.Position = UDim2.new(1, 100, 0, 0)
    TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    task.delay(duration, function()
        if Toast and Toast.Parent then
            local tw = TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 100, 0, 0),
                BackgroundTransparency = 1
            })
            tw:Play()
            tw.Completed:Connect(function()
                Toast:Destroy()
            end)
        end
    end)
end

-- -------------------------------------------------------------
-- CREATE INTERFACE
-- -------------------------------------------------------------
function Library:CreateInterface(suiteTitle, suiteDesc, icon, position, defaultTheme, defaultTransparency)
    local themeKey = tostring(defaultTheme or "emerald"):lower()
    local theme = DefaultThemes[themeKey] or DefaultThemes.emerald
    Library.CurrentTheme = theme

    local glassTransparency = defaultTransparency or 0.15
    local themeUpdaters = {}

    local configFileName = string.gsub(string.lower(suiteTitle or "admin"), "%s+", "_") .. "_config.json"
    local ConfigState = {}

    local function loadSavedConfig()
        if readfile and isfile and isfile(configFileName) then
            local success, content = pcall(readfile, configFileName)
            if success and content and #content > 0 then
                local decodeSuccess, data = pcall(function()
                    return HttpService:JSONDecode(content)
                end)
                if decodeSuccess and type(data) == "table" then
                    ConfigState = data
                end
            end
        end
    end

    local function autoSaveConfig()
        if writefile then
            pcall(function()
                writefile(configFileName, HttpService:JSONEncode(ConfigState))
            end)
        end
    end

    loadSavedConfig()

    local parentGui = getParentGui()
    local ScreenGui = create("ScreenGui", {
        Name = "AdminSuiteUI_" .. tostring(math.random(1000, 9999)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = parentGui
    })

    -- Main Window Frame
    local MainFrame = create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 640, 0, 400),
        Position = UDim2.new(0.5, -320, 0.5, -200),
        BackgroundColor3 = theme.MainBg,
        BackgroundTransparency = glassTransparency,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = ScreenGui
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainFrame })
    local MainStroke = create("UIStroke", { Color = theme.Border, Thickness = 1.5, Parent = MainFrame })

    -- Top Header Bar
    local TopBar = create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = theme.HeaderBg,
        BackgroundTransparency = math.clamp(glassTransparency - 0.05, 0, 1),
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = TopBar })

    local TitleLabel = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.6, 0, 0, 22),
        Position = UDim2.new(0, 14, 0, 4),
        BackgroundTransparency = 1,
        Text = suiteTitle or "Admin Suite",
        TextColor3 = theme.TextColor,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })

    local DescLabel = create("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(0.6, 0, 0, 16),
        Position = UDim2.new(0, 14, 0, 24),
        BackgroundTransparency = 1,
        Text = suiteDesc or "Universal Automation",
        TextColor3 = theme.SubText,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })

    -- Top Bar Controls (Minimize & Close)
    local Controls = create("Frame", {
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -85, 0, 0),
        BackgroundTransparency = 1,
        Parent = TopBar
    })

    local MinimizeBtn = create("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0, 5, 0.5, -15),
        BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = 0.5,
        Text = "-",
        TextColor3 = theme.TextColor,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Parent = Controls
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MinimizeBtn })

    local CloseBtn = create("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0, 45, 0.5, -15),
        BackgroundColor3 = theme.CardBg,
        BackgroundTransparency = 0.5,
        Text = "×",
        TextColor3 = theme.TextColor,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        Parent = Controls
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CloseBtn })

    -- Sidebar (Tabs list)
    local Sidebar = create("ScrollingFrame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 150, 1, -52),
        Position = UDim2.new(0, 8, 0, 48),
        BackgroundColor3 = theme.SidebarBg,
        BackgroundTransparency = math.clamp(glassTransparency - 0.05, 0, 1),
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = MainFrame
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Sidebar })
    local SidebarList = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = Sidebar
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = Sidebar
    })

    -- Content Area Container
    local ContentContainer = create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -172, 1, -52),
        Position = UDim2.new(0, 164, 0, 48),
        BackgroundTransparency = 1,
        Parent = MainFrame
    })

    -- Dragging Logic
    local isDragging = false
    local dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and isDragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Toggle GUI Keybind ('K')
    local isGuiVisible = true
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.K then
            isGuiVisible = not isGuiVisible
            MainFrame.Visible = isGuiVisible
        end
    end)

    -- Minimize Toggle
    local isMinimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 640, 0, 44)
            }):Play()
            Sidebar.Visible = false
            ContentContainer.Visible = false
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 640, 0, 400)
            }):Play()
            task.delay(0.15, function()
                if not isMinimized then
                    Sidebar.Visible = true
                    ContentContainer.Visible = true
                end
            end)
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Interface Object State
    local InterfaceObj = {
        Theme = theme,
        ThemeName = themeKey,
        Tabs = {},
        ActiveTab = nil,
        ConfigState = ConfigState
    }

    function InterfaceObj:SetTheme(newThemeName)
        local key = tostring(newThemeName or "emerald"):lower()
        local t = DefaultThemes[key] or DefaultThemes.emerald
        InterfaceObj.Theme = t
        InterfaceObj.ThemeName = key
        theme = t
        Library.CurrentTheme = t

        MainFrame.BackgroundColor3 = t.MainBg
        MainStroke.Color = t.Border
        TopBar.BackgroundColor3 = t.HeaderBg
        TitleLabel.TextColor3 = t.TextColor
        DescLabel.TextColor3 = t.SubText
        MinimizeBtn.BackgroundColor3 = t.CardBg
        MinimizeBtn.TextColor3 = t.TextColor
        CloseBtn.BackgroundColor3 = t.CardBg
        CloseBtn.TextColor3 = t.TextColor
        Sidebar.BackgroundColor3 = t.SidebarBg

        for _, updater in ipairs(themeUpdaters) do
            pcall(updater, t)
        end

        if InterfaceObj.ActiveTab and InterfaceObj.ActiveTab.Activate then
            InterfaceObj.ActiveTab.Activate()
        end
        autoSaveConfig()
    end

    function InterfaceObj:SetTransparency(val)
        val = math.clamp(tonumber(val) or 0.15, 0, 0.95)
        glassTransparency = val
        MainFrame.BackgroundTransparency = glassTransparency
        TopBar.BackgroundTransparency = math.clamp(glassTransparency - 0.05, 0, 1)
        Sidebar.BackgroundTransparency = math.clamp(glassTransparency - 0.05, 0, 1)
    end

    -- -------------------------------------------------------------
    -- RECURSIVE ELEMENT BUILDER ENGINE
    -- -------------------------------------------------------------
    local function createElementBuilder(targetContainer, tabName, parentSection)
        local Builder = {}

        -- 1. Collapsible Section Component
        function Builder:CreateSection(sectionTitle)
            local isOpen = true

            local SectionFrame = create("Frame", {
                Name = "Section_" .. tostring(sectionTitle),
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = InterfaceObj.Theme.HeaderBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.05, 0, 1),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = targetContainer
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SectionFrame })
            local SecStroke = create("UIStroke", { Color = InterfaceObj.Theme.Border, Thickness = 1, Parent = SectionFrame })

            local HeaderBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text = "",
                Parent = SectionFrame
            })

            local TitleLabel = create("TextLabel", {
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = sectionTitle or "Section",
                TextColor3 = InterfaceObj.Theme.TextColor,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
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

            local ItemsContainer = create("Frame", {
                Name = "ItemsContainer",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 36),
                BackgroundTransparency = 1,
                ClipsDescendants = false,
                Parent = SectionFrame
            })

            local SectionLayout = create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Parent = ItemsContainer
            })
            create("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                Parent = ItemsContainer
            })

            local SectionObject = {}

            local function updateSectionHeight()
                local contentHeight = SectionLayout.AbsoluteContentSize.Y
                ItemsContainer.Size = UDim2.new(1, 0, 0, contentHeight + 10)
                if isOpen then
                    ItemsContainer.Visible = true
                    local targetHeight = 36 + contentHeight + 10
                    TweenService:Create(SectionFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, targetHeight)
                    }):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.25), { Rotation = 0 }):Play()
                else
                    TweenService:Create(SectionFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, 36)
                    }):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.25), { Rotation = -90 }):Play()
                    task.delay(0.25, function()
                        if not isOpen then
                            ItemsContainer.Visible = false
                        end
                    end)
                end
                if parentSection and parentSection.UpdateHeight then
                    parentSection.UpdateHeight()
                end
            end

            SectionObject.UpdateHeight = updateSectionHeight

            SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if isOpen then updateSectionHeight() end
            end)

            HeaderBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then ItemsContainer.Visible = true end
                updateSectionHeight()
            end)

            table.insert(themeUpdaters, function(t)
                SectionFrame.BackgroundColor3 = t.HeaderBg
                SecStroke.Color = t.Border
                TitleLabel.TextColor3 = t.TextColor
                Arrow.TextColor3 = t.SubText
            end)

            -- The Section returns its own Builder targeting its ItemsContainer
            local childBuilder = createElementBuilder(ItemsContainer, tabName, SectionObject)
            for k, v in pairs(childBuilder) do
                SectionObject[k] = v
            end

            updateSectionHeight()
            return SectionObject
        end

        -- 2. Animated Pill Toggle Switch
        function Builder:CreateToggleSwitch(labelTitle, defaultState, callback)
            local configKey = tabName .. "_" .. labelTitle
            local savedVal = ConfigState[configKey]
            local state = (savedVal ~= nil) and savedVal or (defaultState or false)
            ConfigState[configKey] = state

            local Card = create("Frame", {
                Name = "Card_Toggle_" .. labelTitle,
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = InterfaceObj.Theme.CardBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                Parent = targetContainer
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

            local PillTrack = create("TextButton", {
                Size = UDim2.new(0, 42, 0, 22),
                Position = UDim2.new(1, -52, 0.5, -11),
                BackgroundColor3 = state and InterfaceObj.Theme.Accent or InterfaceObj.Theme.MainBg,
                Text = "",
                Parent = Card
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = PillTrack })

            local PillKnob = create("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = PillTrack
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = PillKnob })

            local function updateVisuals()
                if state then
                    TweenService:Create(PillTrack, TweenInfo.new(0.2), { BackgroundColor3 = InterfaceObj.Theme.Accent }):Play()
                    TweenService:Create(PillKnob, TweenInfo.new(0.2), { Position = UDim2.new(1, -19, 0.5, -8) }):Play()
                else
                    TweenService:Create(PillTrack, TweenInfo.new(0.2), { BackgroundColor3 = InterfaceObj.Theme.MainBg }):Play()
                    TweenService:Create(PillKnob, TweenInfo.new(0.2), { Position = UDim2.new(0, 3, 0.5, -8) }):Play()
                end
            end

            local function toggle()
                state = not state
                ConfigState[configKey] = state
                autoSaveConfig()
                updateVisuals()
                if callback then pcall(callback, state) end
            end

            PillTrack.MouseButton1Click:Connect(toggle)

            table.insert(themeUpdaters, function(t)
                Card.BackgroundColor3 = t.CardBg
                Label.TextColor3 = t.TextColor
                PillTrack.BackgroundColor3 = state and t.Accent or t.MainBg
            end)

            if savedVal ~= nil and callback then
                pcall(callback, state)
            end

            return Card
        end

        function Builder:CreateCheckbox(labelTitle, callback)
            return Builder:CreateToggleSwitch(labelTitle, false, callback)
        end

        -- 3. Searchable Dropdown with Highlighting Checkboxes
        function Builder:CreateDropDown(dropTitle, callback)
            local isOpen = false
            local configKey = tabName .. "_" .. dropTitle

            local DropCard = create("Frame", {
                Name = "DropCard_" .. dropTitle,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = InterfaceObj.Theme.CardBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = targetContainer
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

            -- Search Box
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
                PlaceholderText = "Search...",
                PlaceholderColor3 = InterfaceObj.Theme.SubText,
                Text = "",
                TextColor3 = InterfaceObj.Theme.TextColor,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = SearchFrame
            })

            local ItemsHolder = create("ScrollingFrame", {
                Size = UDim2.new(1, -16, 0, 0),
                Position = UDim2.new(0, 8, 0, 72),
                BackgroundTransparency = 1,
                ScrollBarThickness = 3,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Parent = DropCard
            })

            local ItemLayout = create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = ItemsHolder
            })

            local allItemFrames = {}

            local function updateDropSize()
                if isOpen then
                    local contentHeight = ItemLayout.AbsoluteContentSize.Y
                    local maxScrollHeight = math.clamp(contentHeight, 30, 160)
                    ItemsHolder.Size = UDim2.new(1, -16, 0, maxScrollHeight)
                    local totalHeight = 76 + maxScrollHeight
                    TweenService:Create(DropCard, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, totalHeight)
                    }):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.25), { Rotation = 180 }):Play()
                else
                    TweenService:Create(DropCard, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, 36)
                    }):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.25), { Rotation = 0 }):Play()
                end
                if parentSection and parentSection.UpdateHeight then
                    parentSection.UpdateHeight()
                end
            end

            HeaderBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                updateDropSize()
            end)

            SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local q = string.lower(SearchBox.Text)
                for _, itemData in ipairs(allItemFrames) do
                    if q == "" or string.find(string.lower(itemData.Text), q, 1, true) then
                        itemData.Frame.Visible = true
                    else
                        itemData.Frame.Visible = false
                    end
                end
                updateDropSize()
            end)

            table.insert(themeUpdaters, function(t)
                DropCard.BackgroundColor3 = t.CardBg
                TitleLabel.TextColor3 = t.TextColor
                Arrow.TextColor3 = t.SubText
                SearchFrame.BackgroundColor3 = t.MainBg
                SearchBox.TextColor3 = t.TextColor
                SearchBox.PlaceholderColor3 = t.SubText
            end)

            local DropdownObj = {
                Card = DropCard
            }

            function DropdownObj:AddButton(btnText, btnCallback)
                local Btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = InterfaceObj.Theme.MainBg,
                    Text = btnText,
                    TextColor3 = InterfaceObj.Theme.TextColor,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    Parent = ItemsHolder
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Btn })

                table.insert(themeUpdaters, function(t)
                    Btn.BackgroundColor3 = t.MainBg
                    Btn.TextColor3 = t.TextColor
                end)

                Btn.MouseButton1Click:Connect(function()
                    ConfigState[configKey] = btnText
                    autoSaveConfig()
                    if btnCallback then pcall(btnCallback) end
                end)

                table.insert(allItemFrames, { Frame = Btn, Text = btnText })
                updateDropSize()
                return Btn
            end

            function DropdownObj:AddCheckbox(chkText, chkCallback)
                local chkConfigKey = configKey .. "_" .. chkText
                local savedChk = ConfigState[chkConfigKey]
                local chkState = (savedChk ~= nil) and savedChk or false
                ConfigState[chkConfigKey] = chkState

                local ChkBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = InterfaceObj.Theme.MainBg,
                    Text = "  " .. chkText,
                    TextColor3 = chkState and InterfaceObj.Theme.Accent or InterfaceObj.Theme.TextColor,
                    TextSize = 12,
                    Font = chkState and Enum.Font.GothamBold or Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ItemsHolder
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ChkBtn })
                local Stroke = create("UIStroke", {
                    Color = InterfaceObj.Theme.Accent,
                    Thickness = 1.2,
                    Transparency = chkState and 0 or 1,
                    Parent = ChkBtn
                })

                local function toggleChk()
                    chkState = not chkState
                    ConfigState[chkConfigKey] = chkState
                    autoSaveConfig()
                    Stroke.Transparency = chkState and 0 or 1
                    ChkBtn.TextColor3 = chkState and InterfaceObj.Theme.Accent or InterfaceObj.Theme.TextColor
                    ChkBtn.Font = chkState and Enum.Font.GothamBold or Enum.Font.Gotham
                    if chkCallback then pcall(chkCallback, chkState) end
                end

                ChkBtn.MouseButton1Click:Connect(toggleChk)

                table.insert(themeUpdaters, function(t)
                    ChkBtn.BackgroundColor3 = t.MainBg
                    Stroke.Color = t.Accent
                    ChkBtn.TextColor3 = chkState and t.Accent or t.TextColor
                end)

                if savedChk ~= nil and chkCallback then
                    pcall(chkCallback, chkState)
                end

                table.insert(allItemFrames, { Frame = ChkBtn, Text = chkText })
                updateDropSize()

                return {
                    Frame = ChkBtn,
                    SetValue = function(self, val)
                        if chkState ~= val then
                            toggleChk()
                        end
                    end
                }
            end

            return DropdownObj
        end

        -- 4. Draggable Slider Component
        function Builder:CreateSlider(labelTitle, minValArg, maxValArg, defaultValArg, callbackArg)
            local minVal = minValArg or 0
            local maxVal = maxValArg or 100
            local defaultVal = defaultValArg or minVal
            local callback = callbackArg

            local configKey = tabName .. "_" .. labelTitle
            local savedVal = ConfigState[configKey]
            local currentVal = (savedVal ~= nil) and tonumber(savedVal) or defaultVal
            ConfigState[configKey] = currentVal

            local Card = create("Frame", {
                Name = "Card_Slider_" .. labelTitle,
                Size = UDim2.new(1, 0, 0, 48),
                BackgroundColor3 = InterfaceObj.Theme.CardBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                Parent = targetContainer
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

            local Label = create("TextLabel", {
                Size = UDim2.new(0.7, 0, 0, 20),
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
                Size = UDim2.new(0.25, 0, 0, 20),
                Position = UDim2.new(0.72, 0, 0, 4),
                BackgroundTransparency = 1,
                Text = tostring(currentVal),
                TextColor3 = InterfaceObj.Theme.SubText,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = Card
            })

            local SliderTrack = create("TextButton", {
                Size = UDim2.new(1, -24, 0, 8),
                Position = UDim2.new(0, 12, 0, 28),
                BackgroundColor3 = InterfaceObj.Theme.MainBg,
                Text = "",
                Parent = Card
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderTrack })

            local fillPercent = math.clamp((currentVal - minVal) / math.max(maxVal - minVal, 1), 0, 1)
            local SliderFill = create("Frame", {
                Size = UDim2.new(fillPercent, 0, 1, 0),
                BackgroundColor3 = InterfaceObj.Theme.Accent,
                BorderSizePixel = 0,
                Parent = SliderTrack
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderFill })

            local dragging = false
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
                local val = math.floor(minVal + ((maxVal - minVal) * pos))
                currentVal = val
                ValueLabel.Text = tostring(val)
                SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                ConfigState[configKey] = val
                autoSaveConfig()
                if callback then pcall(callback, val) end
            end

            SliderTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            table.insert(themeUpdaters, function(t)
                Card.BackgroundColor3 = t.CardBg
                Label.TextColor3 = t.TextColor
                ValueLabel.TextColor3 = t.SubText
                SliderTrack.BackgroundColor3 = t.MainBg
                SliderFill.BackgroundColor3 = t.Accent
            end)

            if savedVal ~= nil and callback then
                pcall(callback, currentVal)
            end

            return Card
        end

        -- 5. Accent Button
        function Builder:CreateButton(btnText, callback)
            local Card = create("TextButton", {
                Name = "Card_Button_" .. btnText,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = InterfaceObj.Theme.Accent,
                BackgroundTransparency = 0.1,
                Text = btnText,
                TextColor3 = InterfaceObj.Theme.AccentText,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                Parent = targetContainer
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

        -- 6. Comment Divider
        function Builder:CreateComment(text)
            local Card = create("Frame", {
                Name = "Card_Comment",
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = InterfaceObj.Theme.HeaderBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                Parent = targetContainer
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

            local commentcontent = create("TextLabel", {
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = text or "",
                TextColor3 = InterfaceObj.Theme.SubText,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Card
            })

            table.insert(themeUpdaters, function(t)
                Card.BackgroundColor3 = t.HeaderBg
                commentcontent.TextColor3 = t.SubText
            end)

            return {
                Card = Card,
                SetText = function(self, newText)
                    commentcontent.Text = newText
                end
            }
        end

        return Builder
    end

    -- -------------------------------------------------------------
    -- CREATE TAB
    -- -------------------------------------------------------------
    function InterfaceObj:CreateTab(tabName, tabDesc, icon, isDefault)
        local TabBtn = create("TextButton", {
            Name = "TabBtn_" .. tabName,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = theme.CardBg,
            BackgroundTransparency = 0.6,
            Text = "  " .. tabName,
            TextColor3 = theme.SubText,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Sidebar
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBtn })

        -- Tab Content ScrollingFrame
        local TabContent = create("ScrollingFrame", {
            Name = "Content_" .. tabName,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            Visible = false,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = ContentContainer
        })

        local ContentLayout = create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = TabContent
        })
        create("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            Parent = TabContent
        })

        local TabObj = {
            TabBtn = TabBtn,
            TabContent = TabContent
        }

        local function activateTab()
            for _, t in ipairs(InterfaceObj.Tabs) do
                t.TabContent.Visible = false
                t.TabBtn.TextColor3 = InterfaceObj.Theme.SubText
                t.TabBtn.BackgroundColor3 = InterfaceObj.Theme.CardBg
                t.TabBtn.BackgroundTransparency = 0.6
                t.TabBtn.Font = Enum.Font.GothamMedium
            end
            TabContent.Visible = true
            TabBtn.TextColor3 = InterfaceObj.Theme.AccentText
            TabBtn.BackgroundColor3 = InterfaceObj.Theme.Accent
            TabBtn.BackgroundTransparency = 0.15
            TabBtn.Font = Enum.Font.GothamBold
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

        if #InterfaceObj.Tabs == 1 or isDefault then
            activateTab()
        end

        -- Attach the component builder directly to TabContent
        local builder = createElementBuilder(TabContent, tabName, nil)
        for k, v in pairs(builder) do
            TabObj[k] = v
        end

        return TabObj
    end

    table.insert(Library.ActiveInterfaces, InterfaceObj)
    return InterfaceObj
end

return Library
