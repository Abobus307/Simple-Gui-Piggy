local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function createGui(parent)
    local PiggyGui = Instance.new("ScreenGui", parent)
    PiggyGui.Name = "PiggyGui"
    PiggyGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", PiggyGui)
    MainFrame.Name = "MainFrame"
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.Position = UDim2.new(0.08, 0, 0.42, 0)
    MainFrame.Size = UDim2.new(0, 320, 0, 460)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true

    local ToggleButton = Instance.new("TextButton", MainFrame)
    ToggleButton.Name = "ToggleButton"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ToggleButton.Size = UDim2.new(1, 0, 0, 40)
    ToggleButton.Text = "Свернуть"
    ToggleButton.TextColor3 = Color3.new(1, 1, 1)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 30
    ToggleButton.BorderSizePixel = 0
    ToggleButton.ZIndex = 2

    local ContentFrame = Instance.new("Frame", MainFrame)
    ContentFrame.Name = "ContentFrame"
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Position = UDim2.new(0, 0, 0, 40)
    ContentFrame.Size = UDim2.new(1, 0, 1, -40)

    local ScrollingFrame = Instance.new("ScrollingFrame", ContentFrame)
    ScrollingFrame.Name = "ScrollingFrame"
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.Position = UDim2.new(0, 10, 0, 0)
    ScrollingFrame.Size = UDim2.new(1, -25, 1, 0)
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.ScrollBarThickness = 0

    local UIGridLayout = Instance.new("UIGridLayout", ScrollingFrame)
    UIGridLayout.CellSize = UDim2.new(0, 90, 0, 90)
    UIGridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local SliderTrack = Instance.new("Frame", ContentFrame)
    SliderTrack.Name = "SliderTrack"
    SliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    SliderTrack.Position = UDim2.new(1, -8, 0, 5)
    SliderTrack.Size = UDim2.new(0, 4, 1, -10)
    SliderTrack.BorderSizePixel = 0
    SliderTrack.AnchorPoint = Vector2.new(0.5, 0)

    local SliderThumb = Instance.new("Frame", SliderTrack)
    SliderThumb.Name = "SliderThumb"
    SliderThumb.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    SliderThumb.Size = UDim2.new(1, 0, 0, 40)
    SliderThumb.BorderSizePixel = 0

    local function updateSlider()
        local maxScroll = ScrollingFrame.CanvasSize.Y.Offset - ScrollingFrame.AbsoluteWindowSize.Y
        if maxScroll <= 0 then
            SliderTrack.Visible = false
            return
        end

        SliderTrack.Visible = true
        local ratio = ScrollingFrame.CanvasPosition.Y / maxScroll
        local available = SliderTrack.AbsoluteSize.Y - SliderThumb.AbsoluteSize.Y
        SliderThumb.Position = UDim2.new(0, 0, 0, math.clamp(ratio * available, 0, available))
    end

    local isDragging = false
    SliderThumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            local startY = input.Position.Y
            local startThumb = SliderThumb.Position.Y.Offset

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                    conn:Disconnect()
                else
                    local delta = input.Position.Y - startY
                    local newY = math.clamp(startThumb + delta, 0, SliderTrack.AbsoluteSize.Y - SliderThumb.AbsoluteSize.Y)
                    SliderThumb.Position = UDim2.new(0, 0, 0, newY)
                    local ratio = newY / (SliderTrack.AbsoluteSize.Y - SliderThumb.AbsoluteSize.Y)
                    ScrollingFrame.CanvasPosition = Vector2.new(0, ratio * ScrollingFrame.CanvasSize.Y.Offset)
                end
            end)
        end
    end)

    ScrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateSlider)
    ScrollingFrame:GetPropertyChangedSignal("CanvasSize"):Connect(updateSlider)

    UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIGridLayout.AbsoluteContentSize.Y)
        updateSlider()
    end)

    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
    local isExpanded = true

    ToggleButton.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        TweenService:Create(MainFrame, tweenInfo, {
            Size = isExpanded and UDim2.new(0, 320, 0, 460) or UDim2.new(0, 320, 0, 40)
        }):Play()
        ToggleButton.Text = isExpanded and "Свернуть" or "Развернуть"
        ContentFrame.Visible = isExpanded
        SliderTrack.Visible = isExpanded
    end)

    return ScrollingFrame
end

local scrollingFrame = createGui(game.CoreGui)

local function isItem(obj)
    if obj:FindFirstChild("ClickDetector") then
        local name = obj.Name:lower()
        return not (name:find("door") or obj.Parent.Name:lower():find("door") or obj:FindFirstChild("DoorScript"))
            and ((obj:IsA("BasePart") and obj.Transparency < 0.5) or (obj:IsA("Model") and obj.PrimaryPart))
    end
    return false
end

local function getItems()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isItem(obj) then
            table.insert(list, obj)
        end
    end
    return list
end

local function createItemButton(object)
    local btn = Instance.new("TextButton", scrollingFrame)
    btn.Name = "ItemFrame"
    btn.BackgroundColor3 = Color3.new(1, 1, 1)
    btn.BackgroundTransparency = 0.95
    btn.Size = UDim2.new(0, 90, 0, 90)
    btn.Text = ""
    btn.AutoButtonColor = false

    local ref = Instance.new("ObjectValue", btn)
    ref.Name = "ItemRef"
    ref.Value = object

    local view = Instance.new("ViewportFrame", btn)
    view.Name = "View"
    view.Size = UDim2.new(1, 0, 1, 0)
    view.BackgroundTransparency = 1
    view.BorderSizePixel = 0

    local success = pcall(function()
        local clone = object:Clone()
        clone.Parent = view

        local cam = Instance.new("Camera", clone)
        cam.CameraType = Enum.CameraType.Fixed

        local pos = object:GetPivot().Position
        cam.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0), pos)
        view.CurrentCamera = cam
    end)

    if not success then
        btn:Destroy()
        return
    end

    btn.MouseButton1Down:Connect(function()
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then return end

        local detector = object:FindFirstChild("ClickDetector")
        if not detector then return end

        local originalCFrame = hrp.CFrame
        humanoid.PlatformStand = true
        character:PivotTo(object:GetPivot() * CFrame.new(0, 0, -2))

        task.wait(0.1)
        fireclickdetector(detector)

        task.delay(0.2, function()
            if character and hrp then
                character:PivotTo(originalCFrame)
                humanoid.PlatformStand = false
            end
        end)
    end)
end

local function updateGui()
    local items = getItems()
    local children = scrollingFrame:GetChildren()

    for _, child in ipairs(children) do
        if child:IsA("TextButton") then
            local ref = child:FindFirstChild("ItemRef")
            if ref and not table.find(items, ref.Value) then
                child:Destroy()
            end
        end
    end

    for _, item in ipairs(items) do
        local found = false
        for _, child in ipairs(children) do
            if child:IsA("TextButton") then
                local ref = child:FindFirstChild("ItemRef")
                if ref and ref.Value == item then
                    found = true
                    break
                end
            end
        end
        if not found then
            createItemButton(item)
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        pcall(updateGui)
    end
end)
