import sys

with open('lib.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if 'function TabObj:CreateToggleSwitch' in line:
        start_idx = i
    if 'return TabObj' in line and i > start_idx and end_idx == -1:
        end_idx = i

if start_idx != -1 and end_idx != -1:
    components_code = "".join(lines[start_idx:end_idx])
    
    # Replace TabObj: with Obj:
    components_code = components_code.replace('function TabObj:', 'function Obj:')
    # Replace TabContent with TargetContainer
    components_code = components_code.replace('Parent = TabContent', 'Parent = TargetContainer')
    
    wrapped_code = f"""
        local function attachComponents(Obj, TargetContainer, tabName)
{components_code}        end

        attachComponents(TabObj, TabContent, tabName)

        function TabObj:CreateSection(sectionTitle)
            local isOpen = true
            
            local SectionFrame = create("Frame", {{
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = InterfaceObj.Theme.HeaderBg,
                BackgroundTransparency = math.clamp(glassTransparency - 0.1, 0, 1),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = TabContent
            }})
            create("UICorner", {{ CornerRadius = UDim.new(0, 6), Parent = SectionFrame }})
            
            local HeaderBtn = create("TextButton", {{
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text = "",
                Parent = SectionFrame
            }})
            
            local TitleLabel = create("TextLabel", {{
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = sectionTitle,
                TextColor3 = InterfaceObj.Theme.TextColor,
                TextSize = 13,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = HeaderBtn
            }})
            
            local Arrow = create("TextLabel", {{
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -28, 0.5, -10),
                BackgroundTransparency = 1,
                Text = "▼",
                TextColor3 = InterfaceObj.Theme.SubText,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                Parent = HeaderBtn
            }})
            
            local ItemsContainer = create("Frame", {{
                Size = UDim2.new(1, 0, 1, -36),
                Position = UDim2.new(0, 0, 0, 36),
                BackgroundTransparency = 1,
                Parent = SectionFrame
            }})
            
            local UIListLayout = create("UIListLayout", {{
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Parent = ItemsContainer
            }})
            create("UIPadding", {{
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                Parent = ItemsContainer
            }})
            
            local function updateSize()
                if isOpen then
                    local targetHeight = 36 + UIListLayout.AbsoluteContentSize.Y + 12
                    TweenService:Create(SectionFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {{Size = UDim2.new(1, 0, 0, targetHeight)}}):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.3), {{Rotation = 0}}):Play()
                else
                    TweenService:Create(SectionFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {{Size = UDim2.new(1, 0, 0, 36)}}):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.3), {{Rotation = -90}}):Play()
                end
            end
            
            UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if isOpen then updateSize() end
            end)
            
            HeaderBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                updateSize()
            end)
            
            table.insert(themeUpdaters, function(t)
                SectionFrame.BackgroundColor3 = t.HeaderBg
                TitleLabel.TextColor3 = t.TextColor
                Arrow.TextColor3 = t.SubText
            end)
            
            local SectionObj = {{}}
            attachComponents(SectionObj, ItemsContainer, tabName)
            
            -- Initialize size
            updateSize()
            
            return SectionObj
        end
"""
    
    new_lines = lines[:start_idx] + [wrapped_code] + lines[end_idx:]
    with open('lib.lua', 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Refactored successfully")
else:
    print("Failed to find start or end index")
