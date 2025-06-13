local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MAX_ITEMS = 20

local function createGui(parent)
    if parent:FindFirstChild("PiggyGui") then
        return parent.PiggyGui.ScrollingFrame
    end

    local PiggyGui = Instance.new("ScreenGui")
    PiggyGui.Name = "PiggyGui"
    PiggyGui.ResetOnSpawn = false
    PiggyGui.Parent = parent

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.Position = UDim2.new(0.08, 0, 0.42, 0)
    MainFrame.Size = UDim2.new(0, 320, 0, 460)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = PiggyGui

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ToggleButton.Size = UDim2.new(1, 0, 0, 40)
    ToggleButton.Text = "Свернуть"
    ToggleButton.TextColor3 = Color3.new(1, 1, 1)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 30
    ToggleButton.BorderSizePixel = 0
    ToggleButton.ZIndex = 2
    ToggleButton.Parent = MainFrame

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Position = UDim2.new(0, 0, 0, 40)
    ContentFrame.Size = UDim2.new(1, 0, 1, -40)
    ContentFrame.Parent = MainFrame

    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Name = "ScrollingFrame"
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.Position = UDim2.new(0, 10, 0, 0)
    ScrollingFrame.Size = UDim2.new(1, -25, 1, 0)
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.ScrollBarThickness = 0
    ScrollingFrame.Parent = ContentFrame

    local UIGridLayout = Instance.new("UIGridLayout")
    UIGridLayout.CellSize = UDim2.new(0, 90, 0, 90)
    UIGridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIGridLayout.Parent = ScrollingFrame

    local SliderTrack = Instance.new("Frame")
    SliderTrack.Name = "SliderTrack"
    SliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    SliderTrack.Position = UDim2.new(1, -8, 0, 5)
    SliderTrack.Size = UDim2.new(0, 4, 1, -10)
    SliderTrack.BorderSizePixel = 0
    SliderTrack.AnchorPoint = Vector2.new(0.5, 0)
    SliderTrack.Parent = ContentFrame

    local SliderThumb = Instance.new("Frame")
    SliderThumb.Name = "SliderThumb"
    SliderThumb.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    SliderThumb.Size = UDim2.new(1, 0, 0, 40)
    SliderThumb.BorderSizePixel = 0
    SliderThumb.Parent = SliderTrack

    local function updateSlider()
        local maxScroll = ScrollingFrame.CanvasSize.Y.Offset - ScrollingFrame.AbsoluteWindowSize.Y
        if maxScroll <= 0 then
            SliderTrack.Visible = false
            return
        end

        SliderTrack.Visible = true
        local ratio = ScrollingFrame.CanvasPosition.Y / maxScroll
        local availableSpace = SliderTrack.AbsoluteSize.Y - SliderThumb.AbsoluteSize.Y
        SliderThumb.Position = UDim2.new(0, 0, 0, math.clamp(ratio * availableSpace, 0, availableSpace))
    end

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
        local targetSize = isExpanded and UDim2.new(0, 320, 0, 460) or UDim2.new(0, 320, 0, 40)
        TweenService:Create(MainFrame, tweenInfo, {Size = targetSize}):Play()
        ToggleButton.Text = isExpanded and "Свернуть" or "Развернуть"
        ContentFrame.Visible = isExpanded
        SliderTrack.Visible = isExpanded
    end)

    return ScrollingFrame
end

local scrollingFrame = createGui(game.CoreGui)

local function getItems()
    local items = {}
    local itemsFolder = Workspace:FindFirstChild("Items")
    if not itemsFolder then return items end

    for _, obj in ipairs(itemsFolder:GetChildren()) do
        table.insert(items, obj)
        if #items >= MAX_ITEMS then break end
    end
    return items
end

local function createItemButton(object)
    local ItemFrame = Instance.new("TextButton")
    ItemFrame.Name = "ItemFrame"
    ItemFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    ItemFrame.BackgroundTransparency = 0.95
    ItemFrame.Size = UDim2.new(0, 90, 0, 90)
    ItemFrame.Text = ""
    ItemFrame.AutoButtonColor = false
    ItemFrame.Parent = scrollingFrame

    local itemRef = Instance.new("ObjectValue")
    itemRef.Name = "ItemRef"
    itemRef.Value = object
    itemRef.Parent = ItemFrame

    local View = Instance.new("ViewportFrame")
    View.Name = "View"
    View.Size = UDim2.new(1, 0, 1, 0)
    View.BackgroundTransparency = 1
    View.BorderSizePixel = 0
    View.Parent = ItemFrame

    local success, result = pcall(function()
        local viewportClone = object:Clone()
        viewportClone.Parent = View

        local cam = Instance.new("Camera")
        cam.CameraType = Enum.CameraType.Fixed
        cam.Parent = viewportClone

        local objectPosition = object:GetPivot().Position
        local cameraPosition = objectPosition + Vector3.new(0, 3, 0)
        cam.CFrame = CFrame.new(cameraPosition, objectPosition)
        View.CurrentCamera = cam
    end)

    if not success then
        ItemFrame:Destroy()
        return
    end

    ItemFrame.MouseButton1Down:Connect(function()
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then return end

        local clickDetector = object:FindFirstChild("ClickDetector")
        if not clickDetector then return end

        local originalCFrame = hrp.CFrame
        humanoid.PlatformStand = true

        character:PivotTo(object:GetPivot() * CFrame.new(0, 0, -2))
        wait(0.1)
        fireclickdetector(clickDetector)
        task.delay(0.2, function()
            if character and hrp then
                character:PivotTo(originalCFrame)
                humanoid.PlatformStand = false
            end
        end)
    end)
end

local lastItems = {}

local function itemsEqual(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i] ~= b[i] then return false end
    end
    return true
end

local function updateGui()
    local currentItems = getItems()
    if itemsEqual(currentItems, lastItems) then return end
    lastItems = table.clone(currentItems)

    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if child:IsA("TextButton") then
            local itemRef = child:FindFirstChild("ItemRef")
            if itemRef and not table.find(currentItems, itemRef.Value) then
                child:Destroy()
            end
        end
    end

    for _, item in ipairs(currentItems) do
        local exists = false
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("TextButton") then
                local itemRef = child:FindFirstChild("ItemRef")
                if itemRef and itemRef.Value == item then
                    exists = true
                    break
                end
            end
        end
        if not exists then
            createItemButton(item)
        end
    end
end

local itemsFolder = Workspace:FindFirstChild("Items")
if itemsFolder then
    itemsFolder.ChildAdded:Connect(function(obj)
        updateGui()
    end)
    itemsFolder.ChildRemoved:Connect(function(obj)
        updateGui()
    end)
end

task.spawn(function()
    while true do
        pcall(updateGui)
        task.wait(0.5)
    end
end)
