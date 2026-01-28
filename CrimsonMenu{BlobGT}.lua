-- Made By CrimsonMenu!
-- Took 3hr to make 😭🙏🛠

--== Services ==--
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Ensure character + PlayerGui exist
player.CharacterAdded:Wait()
repeat task.wait() until player:FindFirstChild("PlayerGui")

local playerGui = player:WaitForChild("PlayerGui")

--== Globals / State ==--
local MENU_NAME = "CrimsonMenuX"
local TOGGLE_KEYS = {Enum.KeyCode.L, Enum.KeyCode.Insert}
local UNLOAD_KEYS = {Enum.KeyCode.M, Enum.KeyCode.Delete}

-- Cleanup old menu
local old = playerGui:FindFirstChild(MENU_NAME)
if old then old:Destroy() end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local headPart = character:WaitForChild("Head")
local camera = Workspace.CurrentCamera

local states = {
    -- Combat
    softAimEnabled = false,
    softAimStrength = 8,
    autoShootEnabled = false,

    -- ESP (UI only, logic stubbed for stability)
    boxESPEnabled = false,
    normalESPEnabled = false,
    skeletonESPEnabled = false,
    rgbESPEnabled = false,

    -- Movement
    walkSpeedEnabled = false,
    walkSpeed = 50,
    jumpPowerEnabled = false,
    jumpPower = 70,
    flyEnabled = false,
    flySpeed = 60,
    noclipEnabled = false,

    -- Automation
    autoGGEnabled = false,
    autoLeaveEnabled = false,
    autoLeaveThreshold = 15,
    antiAFKEnabled = false,

    -- Fun
    orbitPlayerEnabled = false,
    orbitDistance = 20,
    orbitSpeed = 2,
    thirdPersonLockEnabled = false,
    thirdPersonDistance = 15,
    customCrosshairEnabled = false,

    -- Misc
    platformEnabled = false,
    flingAllEnabled = false,
}

local instances = {
    flyBodyVelocity = nil,
    flyBodyGyro = nil,
    defaultWalkSpeed = humanoid.WalkSpeed,
    defaultJumpPower = humanoid.JumpPower,
    crosshairGui = nil,
    platformPart = nil,
}

local connections = {}
local flyKeys = {W=false, A=false, S=false, D=false, Space=false, Ctrl=false}
local menuVisible = true

--== UI Creation ==--

local screenGui = Instance.new("ScreenGui")
screenGui.Name = MENU_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 9999
screenGui.Enabled = true
screenGui.Parent = playerGui

-- Main container (Rayfield-like: sidebar + content)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 720, 0, 430)
mainFrame.Position = UDim2.new(0.5, -360, 0.5, -215)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 1.5
mainStroke.Color = Color3.fromRGB(90, 40, 200)

-- Top gradient header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(40, 0, 80)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner", header)
headerCorner.CornerRadius = UDim.new(0, 10)

local headerGradient = Instance.new("UIGradient", header)
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255)),
})
headerGradient.Rotation = 0

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "CrimsonMenu X  |  CyberPulse"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
titleLabel.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0.4, -10, 1, 0)
subtitle.Position = UDim2.new(0.6, 0, 0, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "INS/L = Toggle  |  M/DEL = Unload"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 13
subtitle.TextXAlignment = Enum.TextXAlignment.Right
subtitle.TextColor3 = Color3.fromRGB(190, 210, 255)
subtitle.Parent = header

-- Layout: Sidebar (left) + Content (right)
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 170, 1, -42)
sidebar.Position = UDim2.new(0, 0, 0, 42)
sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local sidebarStroke = Instance.new("UIStroke", sidebar)
sidebarStroke.Thickness = 1
sidebarStroke.Color = Color3.fromRGB(60, 40, 120)

local sidebarPadding = Instance.new("UIPadding", sidebar)
sidebarPadding.PaddingTop = UDim.new(0, 10)
sidebarPadding.PaddingLeft = UDim.new(0, 8)
sidebarPadding.PaddingRight = UDim.new(0, 8)

local sidebarList = Instance.new("UIListLayout", sidebar)
sidebarList.FillDirection = Enum.FillDirection.Vertical
sidebarList.Padding = UDim.new(0, 6)
sidebarList.SortOrder = Enum.SortOrder.LayoutOrder

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -170, 1, -42)
contentFrame.Position = UDim2.new(0, 170, 0, 42)
contentFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner", contentFrame)
contentCorner.CornerRadius = UDim.new(0, 10)

local contentStroke = Instance.new("UIStroke", contentFrame)
contentStroke.Thickness = 1
contentStroke.Color = Color3.fromRGB(50, 40, 100)

--== UI Helpers ==--

local tabs = {}
local pages = {}
local activeTab = nil

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function createSidebarButton(name)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(210, 220, 255)
    btn.AutoButtonColor = false
    btn.Parent = sidebar

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(60, 40, 120)

    btn.MouseEnter:Connect(function()
        tween(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(30, 30, 55)
        })
    end)

    btn.MouseLeave:Connect(function()
        if activeTab ~= name then
            tween(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(18, 18, 30)
            })
        end
    end)

    return btn
end

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.new(0, 8, 0, 8)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.Visible = false
    page.Parent = contentFrame

    local layout = Instance.new("UIListLayout", page)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local padding = Instance.new("UIPadding", page)
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)

    return page
end

local function createSection(title, parent)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(210, 220, 255)
    label.Parent = frame

    return frame
end

local function createToggle(name, parent, default, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 30)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 50, 0, 22)
    bg.Position = UDim2.new(1, -60, 0.5, -11)
    bg.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    bg.Parent = holder

    local bgCorner = Instance.new("UICorner", bg)
    bgCorner.CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(180, 180, 220)
    knob.Parent = bg

    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(210, 220, 255)
    label.Parent = holder

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = holder

    local state = default

    local function setState(v)
        state = v
        local targetX = v and (bg.AbsoluteSize.X - knob.AbsoluteSize.X - 2) or 2
        tween(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, targetX, 0.5, -9)
        })
        tween(bg, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = v and Color3.fromRGB(120, 70, 255) or Color3.fromRGB(25, 25, 40)
        })
        callback(v)
    end

    btn.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    setState(default)
    return setState
end

local function createSlider(name, parent, min, max, default, callback, unit)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 46)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(210, 220, 255)
    label.Parent = holder

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default) .. (unit or "")
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextColor3 = Color3.fromRGB(140, 180, 255)
    valueLabel.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 0, 26)
    bar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    bar.Parent = holder

    local barCorner = Instance.new("UICorner", bar)
    barCorner.CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(120, 70, 255)
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(220, 230, 255)
    knob.Parent = bar

    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function setValue(v)
        v = math.clamp(v, min, max)
        local alpha = (v - min) / (max - min)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, -6, 0.5, -6)
        valueLabel.Text = tostring(math.floor(v)) .. (unit or "")
        callback(v)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            setValue(min + rel * (max - min))
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            setValue(min + rel * (max - min))
        end
    end)

    setValue(default)
    return setValue
end

local function createButton(name, parent, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(220, 230, 255)
    btn.AutoButtonColor = false
    btn.Parent = parent

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(70, 50, 140)

    btn.MouseEnter:Connect(function()
        tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(35, 35, 60)
        })
    end)

    btn.MouseLeave:Connect(function()
        tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(20, 20, 35)
        })
    end)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

--== Tabs + Pages ==--

local tabOrder = {"Combat", "ESP", "Movement", "Auto", "Fun", "Misc", "Credits"}

for _, name in ipairs(tabOrder) do
    tabs[name] = createSidebarButton(name)
    pages[name] = createPage(name)
end

local function setActiveTab(name)
    activeTab = name
    for tabName, btn in pairs(tabs) do
        local isActive = (tabName == name)
        tween(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = isActive and Color3.fromRGB(60, 40, 120) or Color3.fromRGB(18, 18, 30)
        })
    end
    for pageName, page in pairs(pages) do
        if pageName == name then
            page.Visible = true
            page.BackgroundTransparency = 1
            tween(page, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0
            })
        else
            page.Visible = false
        end
    end
end

for name, btn in pairs(tabs) do
    btn.MouseButton1Click:Connect(function()
        setActiveTab(name)
    end)
end

setActiveTab("Combat")

--== Populate Tabs ==--

-- Combat
do
    local page = pages.Combat
    createSection("Soft Aim", page)
    createToggle("Soft Aim (Hold RMB)", page, false, function(v)
        states.softAimEnabled = v
    end)
    createSlider("Aim Smoothness", page, 2, 20, 8, function(v)
        states.softAimStrength = v
    end)
    createToggle("Auto Shoot", page, false, function(v)
        states.autoShootEnabled = v
    end)

    createSection("Other", page)
end

-- ESP (UI only)
do
    local page = pages.ESP
    createSection("Visuals", page)
    createToggle("Box ESP", page, false, function(v)
        states.boxESPEnabled = v
    end)
    createToggle("Normal ESP (Name + Dist)", page, false, function(v)
        states.normalESPEnabled = v
    end)
    createToggle("Skeleton ESP", page, false, function(v)
        states.skeletonESPEnabled = v
    end)
    createToggle("RGB ESP", page, false, function(v)
        states.rgbESPEnabled = v
    end)
end

-- Movement
do
    local page = pages.Movement
    createSection("Speeds", page)
    createToggle("Walk Speed", page, false, function(v)
        states.walkSpeedEnabled = v
    end)
    createSlider("Speed", page, 16, 300, 50, function(v)
        states.walkSpeed = v
    end)

    createToggle("Jump Power", page, false, function(v)
        states.jumpPowerEnabled = v
    end)
    createSlider("Jump", page, 50, 300, 70, function(v)
        states.jumpPower = v
    end)

    createSection("Fly", page)
    createToggle("Fly (WASD + Space/Ctrl)", page, false, function(v)
        states.flyEnabled = v
    end)
    createSlider("Fly Speed", page, 10, 300, 60, function(v)
        states.flySpeed = v
    end)

    createToggle("Noclip", page, false, function(v)
        states.noclipEnabled = v
    end)
end

-- Auto
do
    local page = pages.Auto
    createSection("Automation", page)
    createToggle("Auto GG (on death)", page, false, function(v)
        states.autoGGEnabled = v
    end)
    createButton("Manual GG", page, function()
        local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvent and chatEvent:FindFirstChild("SayMessageRequest") then
            chatEvent.SayMessageRequest:FireServer("gg", "All")
        end
    end)
    createToggle("Auto Leave (low players)", page, false, function(v)
        states.autoLeaveEnabled = v
    end)
    createSlider("Player Threshold", page, 1, 30, 15, function(v)
        states.autoLeaveThreshold = v
    end)
    createToggle("Anti AFK", page, false, function(v)
        states.antiAFKEnabled = v
    end)
end

-- Fun
do
    local page = pages.Fun
    createSection("Camera / View", page)
    createToggle("Third Person Lock", page, false, function(v)
        states.thirdPersonLockEnabled = v
    end)
    createSlider("Third Person Distance", page, 5, 50, 15, function(v)
        states.thirdPersonDistance = v
    end)

    createToggle("Custom Crosshair", page, false, function(v)
        states.customCrosshairEnabled = v
        if v then
            if not instances.crosshairGui then
                local cg = Instance.new("ScreenGui")
                cg.Name = "CrimsonCrosshair"
                cg.ResetOnSpawn = false
                cg.IgnoreGuiInset = true
                cg.Parent = playerGui
                instances.crosshairGui = cg

                local center = Instance.new("Frame")
                center.Name = "CenterDot"
                center.Size = UDim2.new(0, 4, 0, 4)
                center.AnchorPoint = Vector2.new(0.5, 0.5)
                center.Position = UDim2.new(0.5, 0, 0.5, 0)
                center.BackgroundColor3 = Color3.fromRGB(200, 230, 255)
                center.Parent = cg

                local corner = Instance.new("UICorner", center)
                corner.CornerRadius = UDim.new(1, 0)
            end
        else
            if instances.crosshairGui then
                instances.crosshairGui:Destroy()
                instances.crosshairGui = nil
            end
        end
    end)
end

-- Misc
do
    local page = pages.Misc
    createSection("Utility", page)
    createToggle("Platform Stand", page, false, function(v)
        states.platformEnabled = v
        if v then
            if not instances.platformPart then
                local p = Instance.new("Part")
                p.Anchored = true
                p.Size = Vector3.new(6, 1, 6)
                p.Color = Color3.fromRGB(80, 80, 120)
                p.Material = Enum.Material.Neon
                p.CanCollide = true
                p.Parent = Workspace
                instances.platformPart = p
            end
        else
            if instances.platformPart then
                instances.platformPart:Destroy()
                instances.platformPart = nil
            end
        end
    end)

    createToggle("Fling All (experimental)", page, false, function(v)
        states.flingAllEnabled = v
    end)
end

-- Credits
do
    local page = pages.Credits
    createSection("Credits", page)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 120)
    label.BackgroundTransparency = 1
    label.Text = "CrimsonMenu X\nCyberPulse Edition\n\nRebuilt for stability, performance, and style."
    label.Font = Enum.Font.Gotham
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(210, 220, 255)
    label.TextWrapped = true
    label.Parent = page
end

--== Character / Movement Handling ==--

local function onCharacterAdded(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    headPart = char:WaitForChild("Head")
    instances.defaultWalkSpeed = humanoid.WalkSpeed
    instances.defaultJumpPower = humanoid.JumpPower
    humanoid.UseJumpPower = true
end

player.CharacterAdded:Connect(onCharacterAdded)

connections[#connections+1] = RunService.Stepped:Connect(function()
    if humanoid then
        if states.walkSpeedEnabled then
            humanoid.WalkSpeed = states.walkSpeed
        else
            humanoid.WalkSpeed = instances.defaultWalkSpeed
        end

        if states.jumpPowerEnabled then
            humanoid.JumpPower = states.jumpPower
        else
            humanoid.JumpPower = instances.defaultJumpPower
        end
    end

    if states.noclipEnabled and character then
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    if states.platformEnabled and instances.platformPart and rootPart then
        instances.platformPart.CFrame = CFrame.new(rootPart.Position - Vector3.new(0, 4, 0))
    end
end)

-- Fly controls
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.W then flyKeys.W = true end
    if input.KeyCode == Enum.KeyCode.S then flyKeys.S = true end
    if input.KeyCode == Enum.KeyCode.A then flyKeys.A = true end
    if input.KeyCode == Enum.KeyCode.D then flyKeys.D = true end
    if input.KeyCode == Enum.KeyCode.Space then flyKeys.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftControl then flyKeys.Ctrl = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then flyKeys.W = false end
    if input.KeyCode == Enum.KeyCode.S then flyKeys.S = false end
    if input.KeyCode == Enum.KeyCode.A then flyKeys.A = false end
    if input.KeyCode == Enum.KeyCode.D then flyKeys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then flyKeys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftControl then flyKeys.Ctrl = false end
end)

local function setFly(enabled)
    if enabled then
        if rootPart and not instances.flyBodyVelocity then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bv.Velocity = Vector3.new()
            bv.Parent = rootPart
            instances.flyBodyVelocity = bv

            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            bg.P = 2e4
            bg.CFrame = rootPart.CFrame
            bg.Parent = rootPart
            instances.flyBodyGyro = bg
        end
    else
        if instances.flyBodyVelocity then
            instances.flyBodyVelocity:Destroy()
            instances.flyBodyVelocity = nil
        end
        if instances.flyBodyGyro then
            instances.flyBodyGyro:Destroy()
            instances.flyBodyGyro = nil
        end
    end
end

connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if states.flyEnabled and rootPart then
        setFly(true)
        local cam = Workspace.CurrentCamera
        local dir = Vector3.new()

        if flyKeys.W then dir = dir + cam.CFrame.LookVector end
        if flyKeys.S then dir = dir - cam.CFrame.LookVector end
        if flyKeys.A then dir = dir - cam.CFrame.RightVector end
        if flyKeys.D then dir = dir + cam.CFrame.RightVector end
        if flyKeys.Space then dir = dir + Vector3.yAxis end
        if flyKeys.Ctrl then dir = dir - Vector3.yAxis end

        if dir.Magnitude > 0 then
            dir = dir.Unit * states.flySpeed
        end

        if instances.flyBodyVelocity then
            instances.flyBodyVelocity.Velocity = dir
        end
        if instances.flyBodyGyro then
            instances.flyBodyGyro.CFrame = cam.CFrame
        end
    else
        setFly(false)
    end
end)

--== Anti AFK ==--

local lastAFK = tick()
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if states.antiAFKEnabled and tick() - lastAFK > 240 then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        lastAFK = tick()
    end
end)

--== Auto Leave ==--

task.spawn(function()
    while task.wait(5) do
        if states.autoLeaveEnabled then
            if #Players:GetPlayers() <= states.autoLeaveThreshold then
                player:Kick("CrimsonMenu X: Auto Leave Triggered")
            end
        end
    end
end)

--== Third Person Lock ==--

connections[#connections+1] = RunService.RenderStepped:Connect(function()
    if states.thirdPersonLockEnabled and camera and rootPart then
        local offset = Vector3.new(0, 2, states.thirdPersonDistance)
        camera.CFrame = CFrame.new(rootPart.Position + rootPart.CFrame:VectorToWorldSpace(offset), rootPart.Position)
    end
end)

--== Keybinds: Toggle + Unload ==--

local function isKeyInList(keyCode, list)
    for _, k in ipairs(list) do
        if keyCode == k then
            return true
        end
    end
    return false
end

local function unload()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end

    if instances.crosshairGui then
        instances.crosshairGui:Destroy()
        instances.crosshairGui = nil
    end

    if instances.platformPart then
        instances.platformPart:Destroy()
        instances.platformPart = nil
    end

    setFly(false)

    if screenGui then
        screenGui:Destroy()
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if isKeyInList(input.KeyCode, TOGGLE_KEYS) then
            menuVisible = not menuVisible
            screenGui.Enabled = menuVisible
        elseif isKeyInList(input.KeyCode, UNLOAD_KEYS) then
            unload()
        end
    end
end)
print("[CRIMSON] The menu has loaded but it will take a bit due to features being broken :( DO NOT UNLOAD!")
print("[CRIMSON] The menu has loaded but it will take a bit due to features being broken :( DO NOT UNLOAD!")
print("[CRIMSON] The menu has loaded but it will take a bit due to features being broken :( DO NOT UNLOAD!")
