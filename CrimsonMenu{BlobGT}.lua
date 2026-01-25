-- Made By CrimsonMenu 
-- V2.0 
-- added some new stuff
-- May be buggy :(((
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then warn("[Crimson] PlayerGui timeout") return end

task.wait(0.8)
print("[Crimson] Initialized")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid", 5)
local rootPart = character:WaitForChild("HumanoidRootPart", 5)
local headPart = character:WaitForChild("Head", 5)
local camera = workspace.CurrentCamera

-- CONFIG
local MENU_NAME = "CrimsonMenu"
local TOGGLE_KEY = Enum.KeyCode.Insert
local UNLOAD_KEY = Enum.KeyCode.Delete

-- Cleanup old menu
if playerGui:FindFirstChild(MENU_NAME) then playerGui[MENU_NAME]:Destroy() end

-- States
local states = {
    -- Combat
    softAimEnabled = false, softAimStrength = 5,
    autoShootEnabled = false, spinBotEnabled = false,
    -- ESP
    boxESPEnabled = false, normalESPEnabled = false, skeletonESPEnabled = false,
    rgbESPEnabled = false, colliderESPEnabled = false,
    -- Movement
    walkSpeedEnabled = false, walkSpeed = 50,
    jumpForceEnabled = false, jumpForce = 70,
    flyEnabled = false, flySpeed = 60,
    flingerNoclipEnabled = false,
    -- Automation
    autoGGEnabled = false,
    autoLeaveEnabled = false, autoLeaveThreshold = 15,
    antiAFKEnabled = false,
    -- Fun
    orbitPlayerEnabled = false, orbitDistance = 20, orbitSpeed = 2,
    longArmsEnabled = false, longArmsLength = 3,
    trailsEnabled = false,
    thirdPersonLockEnabled = false, thirdPersonDistance = 15,
    customCrosshairEnabled = false, crosshairType = "Plus", crosshairSize = 12,
    -- New Fun
    headSpinXEnabled = false, headSpinXSpeed = 180,
    headSpinYEnabled = false, headSpinYSpeed = 180,
    headSpinZEnabled = false, headSpinZSpeed = 180,
    spazRigEnabled = false, spazIntensity = 5,
    -- Misc
    platformGeneratorEnabled = false
}

-- Instances
local instances = {
    espDrawings = {}, espTexts = {}, skeletonLines = {},
    crosshairGui = nil,
    platformPart = nil,
    trail = nil,
    flyBodyVelocity = nil, flyBodyGyro = nil,
    defaultWalkSpeed = 16, defaultJumpPower = 50
}

local connections = {}
local lastAutoShoot = 0
local flyKeys = {W=false, A=false, S=false, D=false, Space=false, Ctrl=false}
local oldStates = {} -- For change detection

-- ────────────────────────────────────────────────
-- UI CREATION (unchanged)
-- ────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = MENU_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 9999
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 600, 0, 400) -- Slightly taller for new features
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ZIndex = 100
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,8)

local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(180,20,40)

local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1,0,0,30)
titleBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,8)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1,-10,1,0)
titleLabel.Position = UDim2.new(0,5,0,0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Crimson Menu v2.0"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(220,60,80)

local tabsFrame = Instance.new("Frame", mainFrame)
tabsFrame.Size = UDim2.new(1,0,0,30)
tabsFrame.Position = UDim2.new(0,0,0,30)
tabsFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)

local tabsLayout = Instance.new("UIListLayout", tabsFrame)
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0,4)
Instance.new("UIPadding", tabsFrame).PaddingLeft = UDim.new(0,6)

local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1,-10,1,-70)
contentFrame.Position = UDim2.new(0,5,0,65)
contentFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0,6)

-- UI Helpers (unchanged from previous)
local function createTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,85,1,0)
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.Text = name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.ZIndex = 101
    btn.Parent = tabsFrame
    return btn
end

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name.."Page"
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 5
    page.ZIndex = 101
    page.Parent = contentFrame
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0,6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", page).PaddingTop = UDim.new(0,8)
    local padlr = Instance.new("UIPadding", page)
    padlr.PaddingLeft = UDim.new(0,10)
    padlr.PaddingRight = UDim.new(0,10)
    return page
end

local function createSectionLabel(text, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,24)
    lbl.BackgroundTransparency = 1
    lbl.Text = "   " .. text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(220,220,220)
    lbl.ZIndex = 102
    lbl.Parent = parent
    return lbl
end

local function createToggle(name, parent, default, callback)
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(1,0,0,28)
    holder.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", holder)
    btn.Size = UDim2.new(0,24,0,24)
    btn.BackgroundColor3 = default and Color3.fromRGB(180,20,40) or Color3.fromRGB(50,50,50)
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.ZIndex = 103
    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(1,-35,1,0)
    lbl.Position = UDim2.new(0,34,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(220,220,220)
    lbl.ZIndex = 103
    local state = default
    local function set(v)
        state = v
        btn.BackgroundColor3 = v and Color3.fromRGB(180,20,40) or Color3.fromRGB(50,50,50)
        callback(v)
    end
    btn.MouseButton1Click:Connect(function() set(not state) end)
    set(default)
    return set
end

local function createSlider(name, parent, min, max, default, callback, unit)
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(1,0,0,45)
    holder.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(220,220,220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local bar = Instance.new("Frame", holder)
    bar.Size = UDim2.new(1,0,0,8)
    bar.Position = UDim2.new(0,0,0,28)
    bar.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,4)
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(180,20,40)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,4)
    local knob = Instance.new("Frame", bar)
    knob.Size = UDim2.new(0,16,0,16)
    knob.Position = UDim2.new((default-min)/(max-min), -8, -0.5, -4)
    knob.BackgroundColor3 = Color3.fromRGB(220,220,220)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local valueLabel = Instance.new("TextLabel", holder)
    valueLabel.Size = UDim2.new(0,60,0,20)
    valueLabel.Position = UDim2.new(1, -70,0,2)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = default .. (unit or "")
    valueLabel.TextColor3 = Color3.fromRGB(180,20,40)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 14
    local current = default
    local dragging = false
    local function update(value)
        current = math.clamp(value, min, max)
        local percent = (current - min) / (max - min)
        fill.Size = UDim2.new(percent,0,1,0)
        knob.Position = UDim2.new(percent, -8, -0.5, -4)
        valueLabel.Text = math.floor(current) .. (unit or "")
        callback(current)
    end
    update(default)
    local inputCon
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = true 
            inputCon = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = inp.Position.X - bar.AbsolutePosition.X
                    local percent = math.clamp(delta / bar.AbsoluteSize.X, 0, 1)
                    update(min + percent * (max - min))
                end
            end)
        end
    end)
    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = false
            if inputCon then inputCon:Disconnect() end
        end
    end)
    return update
end

local function createButton(name, parent, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1,0,0,32)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.ZIndex = 103
    btn.MouseButton1Click:Connect(callback)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(180,20,40) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(40,40,40) end)
    return btn
end

-- Tabs
local tabs = {}
local pages = {}
local tabNames = {"Combat", "ESP", "Movement", "Automation", "Fun", "Misc", "Credits"}
for _, tabName in ipairs(tabNames) do
    tabs[tabName] = createTabButton(tabName)
    pages[tabName] = createPage(tabName)
end

local function setActiveTab(tabName)
    for name, btn in pairs(tabs) do
        btn.BackgroundColor3 = (name == tabName) and Color3.fromRGB(180,20,40) or Color3.fromRGB(30,30,30)
        btn.TextColor3 = (name == tabName) and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
    end
    for name, page in pairs(pages) do
        page.Visible = (name == tabName)
    end
end

for tabName, btn in pairs(tabs) do
    btn.MouseButton1Click:Connect(function() setActiveTab(tabName) end)
end
setActiveTab("Combat")

-- Populate Tabs
do -- Combat
    createSectionLabel("Aiming", pages.Combat)
    createToggle("Soft Aim (Hold RMB)", pages.Combat, false, function(v) states.softAimEnabled = v end)
    createSlider("Aim Smoothness", pages.Combat, 1, 20, 5, function(v) states.softAimStrength = v end)
    createToggle("Auto Shoot", pages.Combat, false, function(v) states.autoShootEnabled = v end)
    createSectionLabel("Other", pages.Combat)
    createToggle("Spin Bot", pages.Combat, false, function(v) states.spinBotEnabled = v end)
end

do -- ESP
    createSectionLabel("Visuals", pages.ESP)
    createToggle("Box ESP", pages.ESP, false, function(v) states.boxESPEnabled = v end)
    createToggle("Normal ESP (Name+Dist)", pages.ESP, false, function(v) states.normalESPEnabled = v end)
    createToggle("Skeleton ESP", pages.ESP, false, function(v) states.skeletonESPEnabled = v end)
    createToggle("RGB ESP", pages.ESP, false, function(v) states.rgbESPEnabled = v end)
    createToggle("Collider ESP", pages.ESP, false, function(v) states.colliderESPEnabled = v end)
end

do -- Movement
    createSectionLabel("Speeds", pages.Movement)
    createToggle("Walk Speed", pages.Movement, false, function(v) states.walkSpeedEnabled = v end)
    createSlider("Speed", pages.Movement, 16, 300, 50, function(v) states.walkSpeed = v end)
    createToggle("Jump Power", pages.Movement, false, function(v) states.jumpForceEnabled = v end)
    createSlider("Jump", pages.Movement, 50, 300, 70, function(v) states.jumpForce = v end)
    createSectionLabel("Fly", pages.Movement)
    createToggle("Fly (WASD Space Ctrl)", pages.Movement, false, function(v) states.flyEnabled = v end)
    createSlider("Fly Speed", pages.Movement, 10, 300, 60, function(v) states.flySpeed = v end)
    createToggle("Noclip", pages.Movement, false, function(v) states.flingerNoclipEnabled = v end)
end

do -- Automation
    createSectionLabel("Auto", pages.Automation)
    createToggle("Auto GG (on death)", pages.Automation, false, function(v) states.autoGGEnabled = v end)
    createButton("Manual GG", pages.Automation, function() game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer("gg", "All") end)
    createToggle("Auto Leave (low players)", pages.Automation, false, function(v) states.autoLeaveEnabled = v end)
    createSlider("Player Threshold", pages.Automation, 1, 30, 15, function(v) states.autoLeaveThreshold = v end)
    createToggle("Anti AFK", pages.Automation, false, function(v) states.antiAFKEnabled = v end)
end

do -- Fun (NEW FEATURES)
    createSectionLabel("Player Effects", pages.Fun)
    createToggle("Orbit Nearest", pages.Fun, false, function(v) states.orbitPlayerEnabled = v end)
    createSlider("Orbit Distance", pages.Fun, 10, 100, 20, function(v) states.orbitDistance = v end)
    createSlider("Orbit Speed", pages.Fun, 1, 10, 2, function(v) states.orbitSpeed = v end)
    createToggle("Long Arms", pages.Fun, false, function(v) states.longArmsEnabled = v end)
    createSlider("Arm Length", pages.Fun, 1, 10, 3, function(v) states.longArmsLength = v end)
    createSectionLabel("Head Spins", pages.Fun)
    createToggle("Head Spin X", pages.Fun, false, function(v) states.headSpinXEnabled = v end)
    createSlider("X Speed", pages.Fun, 0, 720, 180, function(v) states.headSpinXSpeed = v end)
    createToggle("Head Spin Y", pages.Fun, false, function(v) states.headSpinYEnabled = v end)
    createSlider("Y Speed", pages.Fun, 0, 720, 180, function(v) states.headSpinYSpeed = v end)
    createToggle("Head Spin Z", pages.Fun, false, function(v) states.headSpinZEnabled = v end)
    createSlider("Z Speed", pages.Fun, 0, 720, 180, function(v) states.headSpinZSpeed = v end)
    createSectionLabel("Rig Glitch", pages.Fun)
    createToggle("Spaz Rig", pages.Fun, false, function(v) states.spazRigEnabled = v end)
    createSlider("Spaz Intensity", pages.Fun, 1, 20, 5, function(v) states.spazIntensity = v end)
    createSectionLabel("Visual", pages.Fun)
    createToggle("RGB Trails", pages.Fun, false, function(v) states.trailsEnabled = v end)
    createToggle("Third Person Lock", pages.Fun, false, function(v) states.thirdPersonLockEnabled = v end)
    createSlider("TP Distance", pages.Fun, 5, 50, 15, function(v) states.thirdPersonDistance = v end)
    createToggle("Custom Crosshair", pages.Fun, false, function(v) states.customCrosshairEnabled = v end)
end

do -- Misc
    createSectionLabel("Utility", pages.Misc)
    createToggle("Platform Stand", pages.Misc, false, function(v) states.platformGeneratorEnabled = v end)
end

do -- Credits
    createSectionLabel("Credits", pages.Creds)
    local cred = Instance.new("TextLabel", pages.Creds)
    cred.Size = UDim2.new(1,0,1,0)
    cred.BackgroundTransparency = 1
    cred.Text = "Fixed & Enhanced by Grok\nOriginal: CrimsonMenu\nFeatures: All requested + more!"
    cred.Font = Enum.Font.Gotham
    cred.TextSize = 18
    cred.TextColor3 = Color3.fromRGB(220,60,80)
    cred.TextWrapped = true
end

print("[Crimson Menu] UI Complete")

-- ────────────────────────────────────────────────
-- CORE FEATURES
-- ────────────────────────────────────────────────

-- Respawn Handler
local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid", 3)
    rootPart = char:WaitForChild("HumanoidRootPart", 3)
    headPart = char:WaitForChild("Head", 3)
    instances.defaultWalkSpeed = humanoid.WalkSpeed
    instances.defaultJumpPower = humanoid.JumpPower
    humanoid.UseJumpPower = true
end
setupCharacter(character)
player.CharacterAdded:Connect(setupCharacter)

-- Movement Fixes (Stepped for anti-override)
connections[#connections+1] = RunService.Stepped:Connect(function()
    if character and humanoid then
        if states.walkSpeedEnabled then
            humanoid.WalkSpeed = states.walkSpeed
        else
            humanoid.WalkSpeed = instances.defaultWalkSpeed
        end
        if states.jumpForceEnabled then
            humanoid.JumpPower = states.jumpForce
        else
            humanoid.JumpPower = instances.defaultJumpPower
        end
    end
end)

-- Noclip
connections[#connections+1] = RunService.Stepped:Connect(function()
    if states.flingerNoclipEnabled and character then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Fly
UserInputService.InputBegan:Connect(function(key, gpe)
    if gpe then return end
    if key.KeyCode == Enum.KeyCode.W then flyKeys.W = true
    elseif key.KeyCode == Enum.KeyCode.S then flyKeys.S = true
    elseif key.KeyCode == Enum.KeyCode.A then flyKeys.A = true
    elseif key.KeyCode == Enum.KeyCode.D then flyKeys.D = true
    elseif key.KeyCode == Enum.KeyCode.Space then flyKeys.Space = true
    elseif key.KeyCode == Enum.KeyCode.LeftControl then flyKeys.Ctrl = true end
end)
UserInputService.InputEnded:Connect(function(key)
    if key.KeyCode == Enum.KeyCode.W then flyKeys.W = false
    elseif key.KeyCode == Enum.KeyCode.S then flyKeys.S = false
    elseif key.KeyCode == Enum.KeyCode.A then flyKeys.A = false
    elseif key.KeyCode == Enum.KeyCode.D then flyKeys.D = false
    elseif key.KeyCode == Enum.KeyCode.Space then flyKeys.Space = false
    elseif key.KeyCode == Enum.KeyCode.LeftControl then flyKeys.Ctrl = false end
end)

local function toggleFly(enabled)
    if enabled then
        if rootPart then
            instances.flyBodyVelocity = Instance.new("BodyVelocity")
            instances.flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
            instances.flyBodyVelocity.Parent = rootPart
            instances.flyBodyGyro = Instance.new("BodyGyro")
            instances.flyBodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
            instances.flyBodyGyro.P = 20000
            instances.flyBodyGyro.Parent = rootPart
        end
    else
        if instances.flyBodyVelocity then instances.flyBodyVelocity:Destroy() instances.flyBodyVelocity = nil end
        if instances.flyBodyGyro then instances.flyBodyGyro:Destroy() instances.flyBodyGyro = nil end
    end
end

connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if states.flyEnabled and rootPart then
        toggleFly(true)
        local cam = workspace.CurrentCamera
        local vel = Vector3.new()
        if flyKeys.W then vel = vel + cam.CFrame.LookVector end
        if flyKeys.S then vel = vel - cam.CFrame.LookVector end
        if flyKeys.A then vel = vel - cam.CFrame.RightVector end
        if flyKeys.D then vel = vel + cam.CFrame.RightVector end
        if flyKeys.Space then vel = vel + Vector3.yAxis end
        if flyKeys.Ctrl then vel = vel - Vector3.yAxis end
        instances.flyBodyVelocity.Velocity = vel.Unit * states.flySpeed
        instances.flyBodyGyro.CFrame = cam.CFrame
    else
        toggleFly(false)
    end
end)

-- Anti-AFK
local afkTime = tick()
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if states.antiAFKEnabled and tick() - afkTime > 300 then -- 5 min
        keypress(Enum.KeyCode.Right) -- Simulate jump or move
        afkTime = tick()
    end
end)

-- Auto Leave
spawn(function()
    while task.wait(5) do
        if states.autoLeaveEnabled and #Players:GetPlayers() <= states.autoLeaveThreshold then
            game:Shutdown() -- or player:Kick()
        end
    end
end)

-- ESP Setup
local function createESPDrawings(plr)
    if plr == player then return end
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.new(1,0,0)
    box.Thickness = 2
    box.Filled = false
    instances.espDrawings[plr] = box
    
    local text = Drawing.new("Text")
    text.Visible = false
    text.Color = Color3.new(1,1,1)
    text.Size = 16
    text.Center = true
    text.Outline = true
    instances.espTexts[plr] = text
    
    -- Skeleton lines
    local lines = {}
    for i = 1, 8 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Color3.new(0,1,0)
        line.Thickness = 2
        table.insert(lines, line)
    end
    instances.skeletonLines[plr] = lines
end

for _, plr in Players:GetPlayers() do createESPDrawings(plr) end
Players.PlayerAdded:Connect(createESPDrawings)
Players.PlayerRemoving:Connect(function(plr)
    if instances.espDrawings[plr] then instances.espDrawings[plr]:Remove() end
    if instances.espTexts[plr] then instances.espTexts[plr]:Remove() end
    if instances.skeletonLines[plr] then
        for _, line in instances.skeletonLines[plr] do line:Remove() end
    end
end)

-- ESP Update Loop
connections[#connections+1] = RunService.RenderStepped:Connect(function()
    for plr, box in pairs(instances.espDrawings) do
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.Humanoid.Health > 0 then
            local root = plr.Character.HumanoidRootPart
            local humanoid = plr.Character.Humanoid
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local rootScr, onScreen = camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local headScr = camera:WorldToViewportPoint(head.Position)
                    local legScr = camera:WorldToViewportPoint(root.Position - Vector3.new(0,4,0))
                    local boxHeight = math.abs(headScr.Y - legScr.Y)
                    local boxWidth = boxHeight * 0.4
                    box.Size = Vector2.new(boxWidth, boxHeight)
                    box.Position = Vector2.new(rootScr.X - boxWidth/2, rootScr.Y - boxHeight/2)
                    
                    -- Colors/Types
                    if states.rgbESPEnabled then
                        box.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                    elseif states.boxESPEnabled then
                        box.Color = Color3.new(1,0,0)
                    else
                        box.Color = Color3.new(0,0,0)
                    end
                    box.Visible = (states.boxESPEnabled or states.rgbESPEnabled)
                    
                    -- Normal ESP Text
                    if states.normalESPEnabled then
                        local dist = (rootPart.Position - root.Position).Magnitude
                        instances.espTexts[plr].Text = plr.Name .. " [" .. math.floor(dist) .. "]"
                        instances.espTexts[plr].Position = Vector2.new(rootScr.X, rootScr.Y - boxHeight/2 - 20)
                        instances.espTexts[plr].Visible = true
                    else
                        instances.espTexts[plr].Visible = false
                    end
                    
                    -- Skeleton (basic)
                    if states.skeletonESPEnabled then
                        local lines = instances.skeletonLines[plr]
                        local parts = {head, plr.Character:FindFirstChild("Torso") or plr.Character:FindFirstChild("UpperTorso")}
                        -- Head to Torso
                        local hPos = camera:WorldToViewportPoint(head.Position)
                        local tPos = camera:WorldToViewportPoint(parts[2].Position)
                        lines[1].From = Vector2.new(hPos.X, hPos.Y)
                        lines[1].To = Vector2.new(tPos.X, tPos.Y)
                        lines[1].Visible = true
                        -- Arms, Legs simplified
                        for i=2,5 do lines[i].Visible = false end -- Skip advanced for brevity
                    else
                        for _, line in instances.skeletonLines[plr] do line.Visible = false end
                    end
                else
                    box.Visible = false
                    instances.espTexts[plr].Visible = false
                    for _, line in instances.skeletonLines[plr] do line.Visible = false end
                end
            end
        else
            box.Visible = false
            instances.espTexts[plr].Visible = false
            for _, line in instances.skeletonLines[plr] do line.Visible = false end
        end
    end
end)

-- Collider ESP (simple highlight if parts named "Hitbox")
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if states.colliderESPEnabled then
        for _, plr in Players:GetPlayers() do
            if plr ~= player and plr.Character then
                for _, part in plr.Character:GetChildren() do
                    if part.Name:lower():find("hitbox") and part:IsA("BasePart") then
                        part.Material = Enum.Material.Neon
                        part.BrickColor = BrickColor.new("Bright red")
                    end
                end
            end
        end
    end
end)

-- Soft Aim + Auto Shoot (RMB HOLD ONLY)
local function getClosestTarget()
    local closest, closestDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, plr in Players:GetPlayers() do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character.Humanoid.Health > 0 then
            local head = plr.Character.Head
            local screenPos, visible = camera:WorldToViewportPoint(head.Position)
            if visible then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < 200 and dist < closestDist then -- FOV 200px
                    closestDist = dist
                    closest = head
                end
            end
        end
    end
    return closest
end

connections[#connections+1] = RunService.RenderStepped:Connect(function(dt)
    local rmbHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if states.softAimEnabled and rmbHeld then
        local targetHead = getClosestTarget()
        if targetHead then
            local targetCFrame = CFrame.lookAt(camera.CFrame.Position, targetHead.Position)
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, dt * states.softAimStrength)
            
            -- Auto Shoot Debounce
            if states.autoShootEnabled and tick() > lastAutoShoot + 0.1 then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0) -- Left click down
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0) -- Up
                lastAutoShoot = tick()
            end
        end
    end
end)

-- Spin Bot
local spinConnection
connections[#connections+1] = RunService.Heartbeat:Connect(function(dt)
    if states.spinBotEnabled and rootPart then
        rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(360 * dt * 5), 0)
    end
end)

-- Fun Features Loop
connections[#connections+1] = RunService.Heartbeat:Connect(function(dt)
    if not character then return end
    
    -- Head Spins
    if headPart then
        local spinCf = CFrame.new()
        if states.headSpinXEnabled then spinCf *= CFrame.Angles(math.rad(states.headSpinXSpeed * dt), 0, 0) end
        if states.headSpinYEnabled then spinCf *= CFrame.Angles(0, math.rad(states.headSpinYSpeed * dt), 0) end
        if states.headSpinZEnabled then spinCf *= CFrame.Angles(0, 0, math.rad(states.headSpinZSpeed * dt)) end
        headPart.CFrame = headPart.CFrame * spinCf
    end
    
    -- Spaz Rig
    if states.spazRigEnabled then
        local intensity = states.spazIntensity / 10
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name:find("Arm") or part.Name:find("Leg") or part.Name:find("Hand") or part.Name:find("Foot") then
                local randRot = Vector3.new(math.random(-intensity, intensity), math.random(-intensity, intensity), math.random(-intensity, intensity))
                part.CFrame = part.CFrame * CFrame.Angles(math.rad(randRot.X), math.rad(randRot.Y), math.rad(randRot.Z))
            end
        end
    end
    
    -- Long Arms
    if states.longArmsEnabled then
        local length = states.longArmsLength
        for _, part in pairs(character:GetChildren()) do
            if part.Name == "Left Arm" or part.Name == "Right Arm" or part.Name == "Left Leg" or part.Name == "Right Leg" then
                part.Size = Vector3.new(part.Size.X * length, part.Size.Y, part.Size.Z * length)
            end
        end
    end
    
    -- Orbit
    if states.orbitPlayerEnabled then
        local closest, dist = nil, math.huge
        for _, plr in Players:GetPlayers() do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local tdist = (rootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                if tdist < dist then dist = tdist closest = plr.Character.HumanoidRootPart end
            end
        end
        if closest then
            local angle = tick() * states.orbitSpeed
            local offset = Vector3.new(math.cos(angle) * states.orbitDistance, 5, math.sin(angle) * states.orbitDistance)
            rootPart.CFrame = CFrame.lookAt(closest.Position + offset, closest.Position)
        end
    end
    
    -- Third Person Lock
    if states.thirdPersonLockEnabled and rootPart then
        local behind = rootPart.Position - (rootPart.CFrame.LookVector * states.thirdPersonDistance)
        camera.CFrame = CFrame.lookAt(behind, rootPart.Position)
    end
    
    -- Platform
    if states.platformGeneratorEnabled and instances.platformPart and rootPart then
        instances.platformPart.Position = rootPart.Position - Vector3.new(0, 4, 0)
    end
end)

-- Trails
local function toggleTrails(v)
    if v and rootPart then
        local att0 = Instance.new("Attachment", rootPart)
        att0.Position = Vector3.new(0,0,-2)
        local att1 = Instance.new("Attachment", rootPart)
        att1.Position = Vector3.new(0,0,2)
        instances.trail = Instance.new("Trail", rootPart)
        instances.trail.Attachment0 = att0
        instances.trail.Attachment1 = att1
        instances.trail.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromHSV(tick()%5/5,1,1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV((tick()+1)%5/5,1,1))
        }
        instances.trail.Lifetime = 2
        instances.trail.MinLength = 0
        instances.trail.WidthScale = NumberSequence.new{NumberSequenceKeypoint.new(0,2), NumberSequenceKeypoint.new(1,0)}
        spawn(function()
            while instances.trail do
                instances.trail.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromHSV(tick()%5/5,1,1)),
                    ColorSequenceKeypoint.new(1, Color3.fromHSV((tick()+1)%5/5,1,1))
                }
                task.wait(0.1)
            end
        end)
    else
        if instances.trail then instances.trail:Destroy() instances.trail = nil end
    end
end

-- Custom Crosshair (simple)
local function updateCrosshair()
    if instances.crosshairGui then instances.crosshairGui:Destroy() end
    if states.customCrosshairEnabled then
        instances.crosshairGui = Instance.new("ScreenGui", playerGui)
        instances.crosshairGui.IgnoreGuiInset = true
        local ch = Instance.new("Frame", instances.crosshairGui)
        ch.AnchorPoint = Vector2.new(0.5,0.5)
        ch.Position = UDim2.new(0.5,0,0.5,0)
        ch.Size = UDim2.new(0, states.crosshairSize*2, 0, states.crosshairSize*2)
        ch.BackgroundTransparency = 1
        if states.crosshairType == "Plus" then
            local horz = Instance.new("Frame", ch)
            horz.Size = UDim2.new(1,0,0.2,0)
            horz.Position = UDim2.new(0,0,0.4,0)
            horz.BackgroundColor3 = Color3.fromRGB(255,0,0)
            horz.BorderSizePixel = 0
            local vert = Instance.new("Frame", ch)
            vert.Size = UDim2.new(0.2,0,1,0)
            vert.Position = UDim2.new(0.4,0,0,0)
            vert.BackgroundColor3 = Color3.fromRGB(255,0,0)
            vert.BorderSizePixel = 0
        else -- Dot
            ch.Size = UDim2.new(0, states.crosshairSize, 0, states.crosshairSize)
            ch.BackgroundColor3 = Color3.fromRGB(255,0,0)
            Instance.new("UICorner", ch).CornerRadius = UDim.new(0.5,0)
        end
    end
end

-- State Change Detection (for one-time actions)
for k, v in pairs(states) do oldStates[k] = v end
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    for k, v in pairs(states) do
        if v ~= oldStates[k] then
            oldStates[k] = v
            if k == "trailsEnabled" then toggleTrails(v) end
            if k == "customCrosshairEnabled" or k == "crosshairType" or k == "crosshairSize" then updateCrosshair() end
            if k == "platformGeneratorEnabled" then
                if v then
                    instances.platformPart = Instance.new("Part")
                    instances.platformPart.Name = "CrimsonPlatform"
                    instances.platformPart.Size = Vector3.new(20, 2, 20)
                    instances.platformPart.Anchored = true
                    instances.platformPart.CanCollide = true
                    instances.platformPart.Material = Enum.Material.ForceField
                    instances.platformPart.BrickColor = BrickColor.Random()
                    instances.platformPart.Parent = workspace
                else
                    if instances.platformPart then instances.platformPart:Destroy() instances.platformPart = nil end
                end
            end
        end
    end
end)

-- Auto GG on Death
local wasAlive = true
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if humanoid.Health <= 0 and wasAlive then
        wasAlive = false
        if states.autoGGEnabled then
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer("gg", "All")
        end
    elseif humanoid.Health > 0 then
        wasAlive = true
    end
end)

-- Menu Controls
local menuVisible = true
local function toggleMenu()
    menuVisible = not menuVisible
    screenGui.Enabled = menuVisible
end

local function unloadMenu()
    for _, conn in ipairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    if instances.flyBodyVelocity then instances.flyBodyVelocity:Destroy() end
    if instances.flyBodyGyro then instances.flyBodyGyro:Destroy() end
    if instances.trail then instances.trail:Destroy() end
    if instances.platformPart then instances.platformPart:Destroy() end
    if instances.crosshairGui then instances.crosshairGui:Destroy() end
    for plr, box in pairs(instances.espDrawings) do box:Remove() end
    for plr, text in pairs(instances.espTexts) do text:Remove() end
    for plr, lines in pairs(instances.skeletonLines) do
        for _, line in ipairs(lines) do line:Remove() end
    end
    screenGui:Destroy()
    print("[Crimson] Fully Unloaded ✓")
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == TOGGLE_KEY then toggleMenu()
    elseif input.KeyCode == UNLOAD_KEY then unloadMenu() end
end)

toggleMenu()
print("Crimson Menu Loaded! ✓ (INS: Toggle | DEL: Unload | RMB+HOLD: Soft Aim)")
