--[[
    99 Nights Admin Suite - Custom UI Library (lib.lua)
    Supports Themes (royal, dark, emerald, cyber, midnight)
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Library = {}

-- Preset Themes Fallback
local DefaultThemes = {
    royal = {
        MainBg = Color3.fromRGB(20, 22, 32),
        HeaderBg = Color3.fromRGB(14, 15, 22),
        SidebarBg = Color3.fromRGB(14, 15, 22),
        CardBg = Color3.fromRGB(28, 31, 44),
        Accent = Color3.fromRGB(120, 80, 230),
        AccentText = Color3.fromRGB(255, 255, 255),
        Stroke = Color3.fromRGB(65, 55, 105),
        TextColor = Color3.fromRGB(245, 245, 250),
        SubText = Color3.fromRGB(145, 150, 180)
    },
    dark = {
        MainBg = Color3.fromRGB(18, 18, 18),
        HeaderBg = Color3.fromRGB(12, 12, 12),
        SidebarBg = Color3.fromRGB(12, 12, 12),
        CardBg = Color3.fromRGB(26, 26, 26),
        Accent = Color3.fromRGB(0, 120, 215),
        AccentText = Color3.fromRGB(255, 255, 255),
        Stroke = Color3.fromRGB(48, 48, 48),
        TextColor = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(150, 150, 150)
    },
    emerald = {
        MainBg = Color3.fromRGB(16, 24, 20),
        HeaderBg = Color3.fromRGB(11, 17, 14),
        SidebarBg = Color3.fromRGB(11, 17, 14),
        CardBg = Color3.fromRGB(22, 34, 28),
        Accent = Color3.fromRGB(0, 180, 110),
        AccentText = Color3.fromRGB(255, 255, 255),
        Stroke = Color3.fromRGB(40, 75, 55),
        TextColor = Color3.fromRGB(235, 248, 240),
        SubText = Color3.fromRGB(135, 165, 148)
    },
    cyber = {
        MainBg = Color3.fromRGB(15, 20, 28),
        HeaderBg = Color3.fromRGB(10, 14, 20),
        SidebarBg = Color3.fromRGB(10, 14, 20),
        CardBg = Color3.fromRGB(22, 29, 40),
        Accent = Color3.fromRGB(0, 210, 255),
        AccentText = Color3.fromRGB(10, 14, 20),
        Stroke = Color3.fromRGB(0, 140, 180),
        TextColor = Color3.fromRGB(235, 245, 255),
        SubText = Color3.fromRGB(130, 160, 190)
    },
    midnight = {
        MainBg = Color3.fromRGB(14, 15, 22),
        HeaderBg = Color3.fromRGB(9, 10, 15),
        SidebarBg = Color3.fromRGB(9, 10, 15),
        CardBg = Color3.fromRGB(20, 22, 32),
        Accent = Color3.fromRGB(255, 110, 180),
        AccentText = Color3.fromRGB(255, 255, 255),
        Stroke = Color3.fromRGB(70, 40, 75),
        TextColor = Color3.fromRGB(245, 240, 250),
        SubText = Color3.fromRGB(150, 140, 165)
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

function Library:CreateInterface(titleText, descText, discordLink, position, themeName)
    local themeKey = tostring(themeName or "royal"):lower()
    local theme = DefaultThemes[themeKey] or DefaultThemes.royal

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

    local ScreenGui = create("ScreenGui", {
        Name = "AdminSuiteUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = parentGui
    })

    -- Main Frame
    local MainFrame = create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 640, 0, 430),
        Position = UDim2.new(0.5, -320, 0.5, -215),
        BackgroundColor3 = theme.MainBg,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
        Parent = ScreenGui
    })

    create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
    create("UIStroke", { Color = theme.Stroke, Thickness = 1.5, Parent = MainFrame })

    -- Top Header Bar
    local Header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = theme.HeaderBg,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Header })

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

    -- Close Button
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

    -- Discord Button
    if discordLink and discordLink ~= "" then
        local DiscordBtn = create("TextButton", {
            Name = "DiscordBtn",
            Size = UDim2.new(0, 80, 0, 28),
            Position = UDim2.new(1, -124, 0, 10),
            BackgroundColor3 = theme.Accent,
            Text = "Discord",
            TextColor3 = theme.AccentText,
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            Parent = Header
        })
        create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DiscordBtn })
        DiscordBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(discordLink)
                DiscordBtn.Text = "Copied!"
                task.wait(1.5)
                DiscordBtn.Text = "Discord"
            end
        end)
    end

    -- Tab Bar (Left side panel)
    local TabBar = create("ScrollingFrame", {
        Name = "TabBar",
        Size = UDim2.new(0, 155, 1, -58),
        Position = UDim2.new(0, 10, 0, 53),
        BackgroundColor3 = theme.SidebarBg,
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
        Theme = theme
    }

    function InterfaceObj:CreateTab(tabName, tabDesc, icon, isDefault)
        local TabBtn = create("TextButton", {
            Name = "TabBtn_" .. tabName,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = theme.CardBg,
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
            Size = UDim2.new(1, -180, 1, -58),
            Position = UDim2.new(0, 172, 0, 53),
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
            TabContent = TabContent
        }

        local function activateTab()
            for _, t in pairs(InterfaceObj.Tabs) do
                t.TabContent.Visible = false
                t.TabBtn.BackgroundColor3 = theme.CardBg
                t.TabBtn.TextColor3 = theme.SubText
            end
            TabContent.Visible = true
            TabBtn.BackgroundColor3 = theme.Accent
            TabBtn.TextColor3 = theme.AccentText
            InterfaceObj.ActiveTab = TabObj
        end

        TabBtn.MouseButton1Click:Connect(activateTab)

        table.insert(InterfaceObj.Tabs, TabObj)

        if isDefault or #InterfaceObj.Tabs == 1 then
            activateTab()
        end

        -- Element Builders

        function TabObj:CreateCheckbox(labelTitle, callback)
            local state = false

            local Card = create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = theme.CardBg,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

            local Label = create("TextLabel", {
                Size = UDim2.new(1, -50, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = labelTitle,
                TextColor3 = theme.TextColor,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Card
            })

            local ToggleBox = create("TextButton", {
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(1, -32, 0.5, -12),
                BackgroundColor3 = theme.MainBg,
                Text = "",
                Parent = Card
            })
            create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ToggleBox })

            local Indicator = create("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0.5, -7, 0.5, -7),
                BackgroundColor3 = theme.Accent,
                Visible = false,
                Parent = ToggleBox
            })
            create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Indicator })

            ToggleBox.MouseButton1Click:Connect(function()
                state = not state
                Indicator.Visible = state
                ToggleBox.BackgroundColor3 = state and theme.Accent or theme.MainBg
                if callback then
                    pcall(callback, state)
                end
            end)

            return Card
        end

        function TabObj:CreateSlider(labelTitle, maxVal, minOrDefault, callback)
            local minVal = 0
            local defaultVal = minOrDefault or 16
            if type(minOrDefault) == "number" and minOrDefault > maxVal then
                defaultVal = minOrDefault
            end

            local Card = create("Frame", {
                Size = UDim2.new(1, 0, 0, 52),
                BackgroundColor3 = theme.CardBg,
                BorderSizePixel = 0,
                Parent = TabContent
            })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })

            local Label = create("TextLabel", {
                Size = UDim2.new(0.7, 0, 0, 22),
                Position = UDim2.new(0, 12, 0, 4),
                BackgroundTransparency = 1,
                Text = labelTitle,
                TextColor3 = theme.TextColor,
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
                TextColor3 = theme.SubText,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = Card
            })

            local SliderTrack = create("TextButton", {
                Size = UDim2.new(1, -24, 0, 8),
                Position = UDim2.new(0, 12, 0, 32),
                BackgroundColor3 = theme.MainBg,
                Text = "",
                Parent = Card
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SliderTrack })

            local fillPercent = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
            local SliderFill = create("Frame", {
                Size = UDim2.new(fillPercent, 0, 1, 0),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Parent = SliderTrack
            })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SliderFill })

            local dragging = false

            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
                local val = math.floor(minVal + (maxVal - minVal) * pos)
                SliderFill.Size = UDim2.new(pos, 0, 1, 0)
                ValueLabel.Text = tostring(val)
                if callback then
                    pcall(callback, val)
                end
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

        function TabObj:CreateComment(text)
            local Card = create("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = theme.HeaderBg,
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
                TextColor3 = theme.SubText,
                TextSize = 12,
                Font = Enum.Font.GothamItalic,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Card
            })

            local CommentObj = {
                Card = Card,
                commentcontent = commentcontent
            }

            function CommentObj:SetText(newText)
                commentcontent.Text = newText
            end

            return CommentObj
        end

        function TabObj:CreateDropDown(dropTitle, callback)
            local isOpen = false

            local DropCard = create("Frame", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = theme.CardBg,
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
                TextColor3 = theme.TextColor,
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
                TextColor3 = theme.SubText,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                Parent = HeaderBtn
            })

            local ItemsContainer = create("Frame", {
                Size = UDim2.new(1, -16, 0, 0),
                Position = UDim2.new(0, 8, 0, 40),
                BackgroundTransparency = 1,
                Parent = DropCard
            })
            local ItemLayout = create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = ItemsContainer
            })

            local function updateDropSize()
                if isOpen then
                    local totalH = 44 + ItemLayout.AbsoluteContentSize.Y
                    DropCard.Size = UDim2.new(1, 0, 0, totalH)
                    Arrow.Text = "▲"
                else
                    DropCard.Size = UDim2.new(1, 0, 0, 36)
                    Arrow.Text = "▼"
                end
            end

            ItemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if isOpen then updateDropSize() end
            end)

            HeaderBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                updateDropSize()
            end)

            local DropdownObj = {
                Card = DropCard,
                ItemsContainer = ItemsContainer
            }

            function DropdownObj:AddButton(btnText, btnCallback)
                local Btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = theme.MainBg,
                    Text = btnText,
                    TextColor3 = theme.TextColor,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    Parent = ItemsContainer
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Btn })

                Btn.MouseButton1Click:Connect(function()
                    if btnCallback then
                        pcall(btnCallback)
                    end
                end)
                return Btn
            end

            function DropdownObj:AddCheckbox(chkText, chkCallback)
                local chkState = false

                local ChkFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = theme.MainBg,
                    Parent = ItemsContainer
                })
                create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ChkFrame })

                local ChkLabel = create("TextLabel", {
                    Size = UDim2.new(1, -35, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = chkText,
                    TextColor3 = theme.TextColor,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ChkFrame
                })

                local ChkBox = create("TextButton", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(1, -24, 0.5, -9),
                    BackgroundColor3 = theme.CardBg,
                    Text = "",
                    Parent = ChkFrame
                })
                create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ChkBox })

                local Ind = create("Frame", {
                    Size = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(0.5, -5, 0.5, -5),
                    BackgroundColor3 = theme.Accent,
                    Visible = false,
                    Parent = ChkBox
                })
                create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = Ind })

                ChkBox.MouseButton1Click:Connect(function()
                    chkState = not chkState
                    Ind.Visible = chkState
                    ChkBox.BackgroundColor3 = chkState and theme.Accent or theme.CardBg
                    if chkCallback then
                        pcall(chkCallback, chkState)
                    end
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
