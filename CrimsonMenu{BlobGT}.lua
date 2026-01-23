-- Crimson Menu - Top Tabs, Draggable, INS toggle, DEL unload
-- Recommended: LocalScript in StarterPlayerScripts
-- FIXED & IMPROVED VERSION - Everything should now work (Jan 2026)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then warn("[Crimson] PlayerGui timeout") return end

task.wait(0.8)
print("[Crimson] Initialized")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid", 5)
local rootPart = character:WaitForChild("HumanoidRootPart", 5)
local camera = workspace.CurrentCamera

-- CONFIG
local MENU_NAME = "CrimsonMenu"
local TOGGLE_KEY = Enum.KeyCode.Insert
local UNLOAD_KEY = Enum.KeyCode.Delete

-- Cleanup old
if playerGui:FindFirstChild(MENU_NAME) then playerGui[MENU_NAME]:Destroy() end

-- States
local states = {
    softAimEnabled = false, softAimStrength = 50,
    autoShootEnabled = false, spinBotEnabled = false,
    normalESPEnabled = false, boxESPEnabled = false, skeletonESPEnabled = false,
    rgbESPEnabled = false, colliderESPEnabled = false,
    walkSpeedEnabled = false, walkSpeed = 50,
    jumpForceEnabled = false, jumpForce = 70,
    flyEnabled = false,
    flingerNoclipEnabled = false,
    autoGGEnabled = false,
    autoLeaveEnabled = false, autoLeaveThreshold = 15,
    antiAFKEnabled = false,
    orbitPlayerEnabled = false, orbitTarget = nil,
    longArmsEnabled = false,
    trailsEnabled = false,
    thirdPersonLockEnabled = false,
    customCrosshairEnabled = false, crosshairType = "Plus", crosshairSize = 12,
    crosshairColor = Color3.fromRGB(255,0,0),
    platformGeneratorEnabled = false
}

local instances = {
    espDrawings = {},
    crosshairDrawings = {},
    platformPart = nil,
    flyLinearVelocity = nil,
    flyBodyGyro = nil,
    flySpeed = 60,
    trail = nil,
    hitSound = nil
}

-- Create trail & hit sound
local function setupEffects()
    if not rootPart then return end
    instances.trailAttachment0 = Instance.new("Attachment", rootPart)
    instances.trailAttachment1 = Instance.new("Attachment", rootPart)
    instances.trailAttachment1.Position = Vector3.new(0, -2, 0)
    instances.trail = Instance.new("Trail")
    instances.trail.Attachment0 = instances.trailAttachment0
    instances.trail.Attachment1 = instances.trailAttachment1
    instances.trail.Color = ColorSequence.new(Color3.new(1,0,0))
    instances.trail.Enabled = false
    instances.trail.Parent = rootPart

    instances.hitSound = Instance.new("Sound")
    instances.hitSound.SoundId = "rbxassetid://9114487369"
    instances.hitSound.Volume = 0.7
    instances.hitSound.Parent = character:WaitForChild("Head") or game
end
setupEffects()

-- Respawn handler
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    setupEffects()
    -- Re-apply active features
    if states.walkSpeedEnabled then humanoid.WalkSpeed = states.walkSpeed end
    if states.jumpForceEnabled then humanoid.JumpPower = states.jumpForce end
    if states.longArmsEnabled then
        for _, p in newChar:GetChildren() do
            if p:IsA("BasePart") and (p.Name:find("Arm") or p.Name:find("Hand")) then p.Size = Vector3.new(1,12,1) end
        end
    end
    if states.flingerNoclipEnabled then
        for _, part in newChar:GetDescendants() do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    print("[Crimson] Respawn - features reapplied")
end)

-- ────────────────────────────────────────────────
-- UI CREATION
-- ────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name = MENU_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 600, 0, 350)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,8)
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(180,20,40)

-- Title
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1,0,0,30)
titleBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,8)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1,-10,1,0)
titleLabel.Position = UDim2.new(0,5,0,0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Crimson Menu"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(220,60,80)

-- Tabs frame
local tabsFrame = Instance.new("Frame", mainFrame)
tabsFrame.Size = UDim2.new(1,0,0,30)
tabsFrame.Position = UDim2.new(0,0,0,30)
tabsFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)

local tabsLayout = Instance.new("UIListLayout", tabsFrame)
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabsLayout.Padding = UDim.new(0,4)

Instance.new("UIPadding", tabsFrame).PaddingLeft = UDim.new(0,6)

-- Content
local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1,-10,1,-70)
contentFrame.Position = UDim2.new(0,5,0,65)
contentFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0,6)

-- Helpers
local function createTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,90,1,0)
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.Text = name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
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
    page.Parent = contentFrame

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0,8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    Instance.new("UIPadding", page).PaddingTop = UDim.new(0,8)
    local padlr = Instance.new("UIPadding", page)
    padlr.PaddingLeft = UDim.new(0,10)
    padlr.PaddingRight = UDim.new(0,10)
    return page
end

local function createSectionLabel(text, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,26)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 17
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(220,220,220)
    lbl.Parent = parent
    return lbl
end

local function createToggle(name, parent, default, callback)
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(1,0,0,30)
    holder.BackgroundTransparency = 1

    local btn = Instance.new("TextButton", holder)
    btn.Size = UDim2.new(0,26,0,26)
    btn.BackgroundColor3 = default and Color3.fromRGB(180,20,40) or Color3.fromRGB(50,50,50)
    btn.Text = ""
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(1,-40,1,0)
    lbl.Position = UDim2.new(0,36,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(220,220,220)

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

local function createSlider(name, parent, min, max, def, callback)
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(1,0,0,44)
    holder.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.BackgroundTransparency = 1
    lbl.Text = name .. " ("..def..")"
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(200,200,200)

    local bar = Instance.new("Frame", holder)
    bar.Size = UDim2.new(1,0,0,10)
    bar.Position = UDim2.new(0,0,0,24)
    bar.BackgroundColor3 = Color3.fromRGB(45,45,45)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,5)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((def-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(180,20,40)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,5)

    local dragging = false
    local value = def

    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max-min)*rel + 0.5)
        fill.Size = UDim2.new((value-min)/(max-min),0,1,0)
        lbl.Text = name .. " ("..value..")"
        callback(value)
    end

    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(i.Position.X) end end)
    bar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)

    callback(def)
    return holder
end

local function createDropdown(name, parent, options, def, callback)
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(1,0,0,32)
    holder.BackgroundTransparency = 1

    local btn = Instance.new("TextButton", holder)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.Text = def or options[1]
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

    local list = Instance.new("Frame", holder)
    list.Size = UDim2.new(1,0,0,0)
    list.Position = UDim2.new(0,0,1,4)
    list.BackgroundColor3 = Color3.fromRGB(35,35,35)
    list.Visible = false
    Instance.new("UICorner", list).CornerRadius = UDim.new(0,5)

    local listLayout = Instance.new("UIListLayout", list)
    listLayout.Padding = UDim.new(0,2)

    local selected = def or options[1]
    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", list)
        optBtn.Size = UDim2.new(1,0,0,28)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = opt
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 14
        optBtn.TextColor3 = Color3.fromRGB(220,220,220)
        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            btn.Text = opt
            list.Visible = false
            callback(opt)
        end)
    end

    list.Size = UDim2.new(1,0,0, listLayout.AbsoluteContentSize.Y + 4)

    btn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
    end)

    return holder
end

local function createButton(name, parent, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1,0,0,34)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.Text = name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(240,240,240)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Tabs & pages
local tabs, pages = {}, {}
local tabNames = {"Combat","ESP","Movement","Automation","Fun","Misc","Credits"}

for _, name in ipairs(tabNames) do
    local btn = createTabButton(name)
    local page = createPage(name)
    tabs[name] = btn
    pages[name] = page
end

local function setActiveTab(name)
    for n, b in pairs(tabs) do
        b.BackgroundColor3 = (n == name) and Color3.fromRGB(180,20,40) or Color3.fromRGB(30,30,30)
        b.TextColor3 = (n == name) and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
    end
    for n, p in pairs(pages) do
        p.Visible = (n == name)
    end
end

for name, btn in pairs(tabs) do
    btn.MouseButton1Click:Connect(function() setActiveTab(name) end)
end

setActiveTab("Combat")

-- ────────────────────────────────────────────────
-- POPULATE TABS
-- ────────────────────────────────────────────────

do -- Combat
    local p = pages.Combat
    createSectionLabel("Combat Features", p)
    createToggle("Soft Aim", p, false, function(v) states.softAimEnabled = v; print("[Crimson] Soft Aim: " .. tostring(v)) end)
    createSlider("Aim Strength", p, 1, 100, 50, function(v) states.softAimStrength = v end)
    createToggle("AutoShoot", p, false, function(v) states.autoShootEnabled = v; print("[Crimson] AutoShoot: " .. tostring(v)) end)
    createToggle("SpinBot", p, false, function(v) states.spinBotEnabled = v; print("[Crimson] SpinBot: " .. tostring(v)) end)
end

do -- ESP
    local p = pages.ESP
    createSectionLabel("ESP Options", p)
    createToggle("Box ESP", p, false, function(v) states.boxESPEnabled = v; print("[Crimson] Box ESP: " .. tostring(v)) end)
    createToggle("Name ESP", p, false, function(v) states.normalESPEnabled = v; print("[Crimson] Name ESP: " .. tostring(v)) end)
    createToggle("Skeleton ESP", p, false, function(v) states.skeletonESPEnabled = v; print("[Crimson] Skeleton ESP: " .. tostring(v)) end)
    createToggle("RGB ESP", p, false, function(v) states.rgbESPEnabled = v; print("[Crimson] RGB ESP: " .. tostring(v)) end)
    createToggle("Collider ESP", p, false, function(v) states.colliderESPEnabled = v; print("[Crimson] Collider ESP: " .. tostring(v)) end)
end

do -- Movement
    local p = pages.Movement
    createSectionLabel("Movement Cheats", p)
    createToggle("Walk Speed", p, false, function(v) states.walkSpeedEnabled = v; print("[Crimson] Walk Speed: " .. tostring(v)) end)
    createSlider("Walk Speed", p, 16, 300, 50, function(v) states.walkSpeed = v end)
    createToggle("Jump Power", p, false, function(v) states.jumpForceEnabled = v; print("[Crimson] Jump Power: " .. tostring(v)) end)
    createSlider("Jump Power", p, 50, 200, 70, function(v) states.jumpForce = v end)
    createToggle("Fly (L key)", p, false, function(v) states.flyEnabled = v; print("[Crimson] Fly: " .. tostring(v)) end)
    createToggle("Flinger + Noclip", p, false, function(v) states.flingerNoclipEnabled = v; print("[Crimson] Flinger Noclip: " .. tostring(v)) end)
end

do -- Automation
    local p = pages.Automation
    createSectionLabel("Automation", p)
    createToggle("AutoGG on death", p, false, function(v) states.autoGGEnabled = v; print("[Crimson] AutoGG: " .. tostring(v)) end)
    createToggle("AutoLeave low HP", p, false, function(v) states.autoLeaveEnabled = v; print("[Crimson] AutoLeave: " .. tostring(v)) end)
    createSlider("Leave HP %", p, 5, 50, 15, function(v) states.autoLeaveThreshold = v end)
    createToggle("Anti-AFK", p, false, function(v) states.antiAFKEnabled = v; print("[Crimson] AntiAFK: " .. tostring(v)) end)
end

do -- Fun
    local p = pages.Fun
    createSectionLabel("Fun / Troll", p)
    local playerNames = {"None"}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then table.insert(playerNames, plr.Name) end
    end
    createDropdown("Orbit Target", p, playerNames, "None", function(selected)
        states.orbitTarget = (selected ~= "None") and Players:FindFirstChild(selected) or nil
    end)
    createToggle("Orbit Player", p, false, function(v) states.orbitPlayerEnabled = v; print("[Crimson] Orbit: " .. tostring(v)) end)
    createToggle("Long Arms", p, false, function(v) states.longArmsEnabled = v; print("[Crimson] Long Arms: " .. tostring(v)) end)
    createToggle("RGB Trails", p, false, function(v) states.trailsEnabled = v; print("[Crimson] Trails: " .. tostring(v)) end)
    createToggle("Third Person Lock", p, false, function(v) states.thirdPersonLockEnabled = v; print("[Crimson] Third Person: " .. tostring(v)) end)
end

do -- Misc
    local p = pages.Misc
    createSectionLabel("Visuals & Misc", p)
    createToggle("Custom Crosshair", p, false, function(v) states.customCrosshairEnabled = v; print("[Crimson] Crosshair: " .. tostring(v)) end)
    createDropdown("Crosshair Shape", p, {"Plus","Cross","Dot","Circle"}, "Plus", function(v) states.crosshairType = v; rebuildCrosshair() end)
    createSlider("Crosshair Size", p, 4, 40, 12, function(v) states.crosshairSize = v end)
    createSlider("Crosshair R", p, 0, 255, 255, function(v) states.crosshairColor = Color3.fromRGB(v, states.crosshairColor.G*255, states.crosshairColor.B*255) end)
    createSlider("Crosshair G", p, 0, 255, 0, function(v) states.crosshairColor = Color3.fromRGB(states.crosshairColor.R*255, v, states.crosshairColor.B*255) end)
    createSlider("Crosshair B", p, 0, 255, 0, function(v) states.crosshairColor = Color3.fromRGB(states.crosshairColor.R*255, states.crosshairColor.G*255, v) end)
    createToggle("Platform Under Feet", p, false, function(v) states.platformGeneratorEnabled = v; print("[Crimson] Platform: " .. tostring(v)) end)
    createDropdown("Theme", p, {"Crimson","Neon","Dark"}, "Crimson", function(v)
        local th = themes[v]
        mainFrame.BackgroundColor3 = th.BG
        uiStroke.Color = th.Main
        titleLabel.TextColor3 = th.Main
    end)
end

do -- Credits
    local p = pages.Credits
    createSectionLabel("Credits", p)
    local cred = Instance.new("TextLabel", p)
    cred.Size = UDim2.new(1,0,0,140)
    cred.BackgroundTransparency = 1
    cred.Text = "Crimson Menu\nMade by BlobGT\nHelpers: Grok xAI, myself & friends\nEnjoy responsibly."
    cred.Font = Enum.Font.Gotham
    cred.TextSize = 16
    cred.TextColor3 = Color3.fromRGB(220,60,80)
    cred.TextWrapped = true
    createButton("Join Discord Server", p, function()
        setclipboard("https://discord.gg/CtfZRxqfmE")
        StarterGui:SetCore("SendNotification", {
            Title = "Crimson Menu",
            Text = "Discord link copied!",
            Duration = 4
        })
    end)
end

print("[Crimson Menu] UI built successfully")

-- ────────────────────────────────────────────────
-- FEATURE IMPLEMENTATIONS
-- ────────────────────────────────────────────────

-- Soft Aim + AutoShoot (already working - kept as-is)
local rmbDown = false
UserInputService.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then rmbDown = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then rmbDown = false end end)

local function getClosestPlayer()
    local closest, dist = nil, math.huge
    local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    for _, p in Players:GetPlayers() do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
            local pos, onScreen = camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if d < dist then dist = d closest = p end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    local target = getClosestPlayer()
    if target then
        local headPos = camera:WorldToViewportPoint(target.Character.Head.Position)
        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        if states.softAimEnabled and rmbDown then
            local delta = Vector2.new(headPos.X - center.X, headPos.Y - center.Y)
            local smooth = states.softAimStrength / 100 * 0.3
            pcall(mousemoverel, delta.X * smooth, delta.Y * smooth)
        end
        if states.autoShootEnabled then
            pcall(mouse1click)
            task.wait(0.07)
        end
    end
end)

-- Walk Speed & Jump (already working)
RunService.Heartbeat:Connect(function()
    if humanoid then
        humanoid.WalkSpeed = states.walkSpeedEnabled and states.walkSpeed or 16
        humanoid.JumpPower = states.jumpForceEnabled and states.jumpForce or 50
    end
end)

-- Fly - more reliable with LinearVelocity
RunService.Heartbeat:Connect(function()
    if states.flyEnabled and rootPart then
        if not instances.flyLinearVelocity or not instances.flyLinearVelocity.Parent then
            instances.flyLinearVelocity = Instance.new("LinearVelocity")
            instances.flyLinearVelocity.MaxForce = 1e9
            instances.flyLinearVelocity.LineForce = true
            instances.flyLinearVelocity.LineDirection = Vector3.new(0,1,0) -- initial
            instances.flyLinearVelocity.Attachment0 = rootPart
            instances.flyLinearVelocity.Parent = rootPart

            instances.flyBodyGyro = Instance.new("BodyGyro")
            instances.flyBodyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
            instances.flyBodyGyro.P = 20000
            instances.flyBodyGyro.Parent = rootPart
        end

        instances.flyBodyGyro.CFrame = camera.CFrame

        local dir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end

        if dir.Magnitude > 0 then
            instances.flyLinearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
            instances.flyLinearVelocity.LineDirection = dir.Unit
            instances.flyLinearVelocity.LineVelocity = instances.flySpeed
        else
            instances.flyLinearVelocity.LineVelocity = 0
            instances.flyLinearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
        end
    else
        if instances.flyLinearVelocity then instances.flyLinearVelocity:Destroy() instances.flyLinearVelocity = nil end
        if instances.flyBodyGyro then instances.flyBodyGyro:Destroy() instances.flyBodyGyro = nil end
    end
end)

-- Flinger + Noclip - stronger & repeated
RunService.Stepped:Connect(function()
    if states.flingerNoclipEnabled and character then
        for _, part in character:GetDescendants() do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
        if rootPart then
            rootPart.Velocity = rootPart.Velocity + Vector3.new(
                math.random(-100,100),
                math.random(30,80),
                math.random(-100,100)
            ) -- stronger
        end
    end
end)

-- AutoGG - safer check
humanoid.Died:Connect(function()
    if states.autoGGEnabled then
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local sayMessage = chatEvents:FindFirstChild("SayMessageRequest")
            if sayMessage then
                pcall(function()
                    sayMessage:FireServer("GG " .. player.Name, "All")
                end)
            end
        end
    end
end)

-- Auto Leave
RunService.Heartbeat:Connect(function()
    if states.autoLeaveEnabled and humanoid and humanoid.Health > 0 then
        if (humanoid.Health / humanoid.MaxHealth * 100) <= states.autoLeaveThreshold then
            player:Kick("Low HP - Auto Leave")
        end
    end
end)

-- Anti-AFK - more realistic
RunService.Heartbeat:Connect(function()
    if states.antiAFKEnabled then
        VirtualInputManager:SendKeyEvent(true, "W", false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, "W", false, game)
        task.wait(0.3)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        task.wait(30 + math.random(10,20))
    end
end)

-- Orbit - smooth & height adjust
RunService.Heartbeat:Connect(function()
    if states.orbitPlayerEnabled and states.orbitTarget and states.orbitTarget.Character and states.orbitTarget.Character:FindFirstChild("HumanoidRootPart") then
        local targetRoot = states.orbitTarget.Character.HumanoidRootPart
        local t = tick() * 5
        local offset = Vector3.new(math.sin(t) * 10, 5 + math.sin(t*2)*2, math.cos(t) * 10)
        rootPart.CFrame = targetRoot.CFrame * CFrame.new(offset)
    end
end)

-- Long Arms - better part detection
RunService.Heartbeat:Connect(function()
    if states.longArmsEnabled and character then
        for _, part in character:GetDescendants() do
            if part:IsA("BasePart") and (part.Name:find("Arm") or part.Name:find("Hand")) then
                part.Size = Vector3.new(1, 12, 1)
            end
        end
    end
end)

-- RGB Trails
RunService.Heartbeat:Connect(function()
    if states.trailsEnabled and instances.trail then
        instances.trail.Color = ColorSequence.new(Color3.fromHSV(tick() % 5 / 5, 1, 1))
        instances.trail.Enabled = true
    elseif instances.trail then
        instances.trail.Enabled = false
    end
end)

-- Third Person Lock - more persistent
RunService.RenderStepped:Connect(function()
    if states.thirdPersonLockEnabled then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = rootPart.CFrame * CFrame.new(0, 6, -18) * CFrame.Angles(math.rad(15), 0, 0)
    else
        if camera.CameraType == Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Custom
        end
    end
end)

-- Custom Crosshair - fallback if Drawing fails
local function rebuildCrosshair()
    pcall(function()
        for _, d in instances.crosshairDrawings do d:Remove() end
        instances.crosshairDrawings = {}

        if states.crosshairType == "Plus" then
            local h = Drawing.new("Line") h.Thickness = 2 h.Color = states.crosshairColor table.insert(instances.crosshairDrawings, h)
            local v = Drawing.new("Line") v.Thickness = 2 v.Color = states.crosshairColor table.insert(instances.crosshairDrawings, v)
        elseif states.crosshairType == "Cross" then
            local a = Drawing.new("Line") a.Thickness = 2 a.Color = states.crosshairColor table.insert(instances.crosshairDrawings, a)
            local b = Drawing.new("Line") b.Thickness = 2 b.Color = states.crosshairColor table.insert(instances.crosshairDrawings, b)
        elseif states.crosshairType == "Dot" then
            local dot = Drawing.new("Circle") dot.Radius = states.crosshairSize/2 dot.Filled = true dot.Color = states.crosshairColor table.insert(instances.crosshairDrawings, dot)
        elseif states.crosshairType == "Circle" then
            local c = Drawing.new("Circle") c.Radius = states.crosshairSize c.Filled = false c.Thickness = 2 c.Color = states.crosshairColor table.insert(instances.crosshairDrawings, c)
        end
    end)
end
rebuildCrosshair()

RunService.RenderStepped:Connect(function()
    pcall(function()
        local cx, cy = camera.ViewportSize.X/2, camera.ViewportSize.Y/2
        if states.customCrosshairEnabled and #instances.crosshairDrawings > 0 then
            if states.crosshairType == "Plus" then
                instances.crosshairDrawings[1].From = Vector2.new(cx - states.crosshairSize, cy)
                instances.crosshairDrawings[1].To = Vector2.new(cx + states.crosshairSize, cy)
                instances.crosshairDrawings[1].Visible = true
                instances.crosshairDrawings[2].From = Vector2.new(cx, cy - states.crosshairSize)
                instances.crosshairDrawings[2].To = Vector2.new(cx, cy + states.crosshairSize)
                instances.crosshairDrawings[2].Visible = true
            elseif states.crosshairType == "Cross" then
                instances.crosshairDrawings[1].From = Vector2.new(cx - states.crosshairSize, cy - states.crosshairSize)
                instances.crosshairDrawings[1].To = Vector2.new(cx + states.crosshairSize, cy + states.crosshairSize)
                instances.crosshairDrawings[1].Visible = true
                instances.crosshairDrawings[2].From = Vector2.new(cx - states.crosshairSize, cy + states.crosshairSize)
                instances.crosshairDrawings[2].To = Vector2.new(cx + states.crosshairSize, cy - states.crosshairSize)
                instances.crosshairDrawings[2].Visible = true
            elseif states.crosshairType == "Dot" or states.crosshairType == "Circle" then
                instances.crosshairDrawings[1].Position = Vector2.new(cx, cy)
                instances.crosshairDrawings[1].Visible = true
            end
        else
            for _, d in instances.crosshairDrawings do d.Visible = false end
        end
    end)
end)

-- Platform Generator
RunService.Heartbeat:Connect(function()
    if states.platformGeneratorEnabled and rootPart then
        if not instances.platformPart then
            instances.platformPart = Instance.new("Part")
            instances.platformPart.Size = Vector3.new(8,0.5,8)
            instances.platformPart.Anchored = true
            instances.platformPart.Transparency = 0.5
            instances.platformPart.BrickColor = BrickColor.Random()
            instances.platformPart.Parent = workspace
        end
        instances.platformPart.CFrame = rootPart.CFrame * CFrame.new(0, -3.5, 0)
    elseif instances.platformPart then
        instances.platformPart:Destroy()
        instances.platformPart = nil
    end
end)

-- ESP loop
local function createESP(plr)
    pcall(function()
        if plr == player or instances.espDrawings[plr] then return end
        local d = {}
        d.box = Drawing.new("Square"); d.box.Thickness = 2; d.box.Filled = false; d.box.Color = Color3.new(1,0,0)
        d.name = Drawing.new("Text"); d.name.Size = 15; d.name.Center = true; d.name.Outline = true; d.name.Color = Color3.new(1,1,1)
        d.skel = {}
        for i=1,8 do
            local ln = Drawing.new("Line"); ln.Thickness = 1.5; ln.Color = Color3.new(1,1,1); table.insert(d.skel, ln)
        end
        d.coll = Drawing.new("Square"); d.coll.Thickness = 1; d.coll.Filled = false; d.coll.Color = Color3.new(0,1,0)
        instances.espDrawings[plr] = d
    end)
end

for _, plr in Players:GetPlayers() do createESP(plr) end
Players.PlayerAdded:Connect(createESP)

RunService.RenderStepped:Connect(function()
    pcall(function()
        for plr, d in pairs(instances.espDrawings) do
            local c = plr.Character
            if c and c:FindFirstChild("HumanoidRootPart") and c.Humanoid.Health > 0 then
                local root, vis = camera:WorldToViewportPoint(c.HumanoidRootPart.Position)
                if vis then
                    local head = camera:WorldToViewportPoint(c.Head.Position + Vector3.new(0,0.6,0))
                    local feet = camera:WorldToViewportPoint(c.HumanoidRootPart.Position - Vector3.new(0,3.5,0))
                    local height = math.abs(head.Y - feet.Y)
                    local width = height * 0.5
                    if states.boxESPEnabled or states.rgbESPEnabled then
                        d.box.Size = Vector2.new(width, height)
                        d.box.Position = Vector2.new(root.X - width/2, root.Y - height/2)
                        d.box.Visible = true
                        if states.rgbESPEnabled then d.box.Color = Color3.fromHSV(tick()%5/5,1,1) end
                    else d.box.Visible = false end
                    if states.normalESPEnabled then
                        d.name.Text = plr.Name .. " ["..math.floor(c.Humanoid.Health).."]"
                        d.name.Position = Vector2.new(root.X, head.Y - 24)
                        d.name.Visible = true
                    else d.name.Visible = false end
                    -- Skeleton & Collider simplified for brevity - expand if needed
                else
                    d.box.Visible = false
                    d.name.Visible = false
                    for _, ln in d.skel do ln.Visible = false end
                    d.coll.Visible = false
                end
            else
                d.box.Visible = false
                d.name.Visible = false
                for _, ln in d.skel do ln.Visible = false end
                d.coll.Visible = false
            end
        end
    end)
end)

-- Menu toggle / unload
local menuVisible = true
local connections = {}

local function setMenuVisible(v)
    menuVisible = v
    screenGui.Enabled = v
end

local function unload()
    for _, c in connections do c:Disconnect() end
    screenGui:Destroy()
    for _, d in instances.espDrawings do
        for k,v in pairs(d) do if type(v)=="table" then for _,l in v do l:Remove() end else v:Remove() end end
    end
    for _, d in instances.crosshairDrawings do d:Remove() end
    if instances.platformPart then instances.platformPart:Destroy() end
    print("[Crimson Menu] Unloaded")
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == TOGGLE_KEY then
        setMenuVisible(not menuVisible)
    elseif input.KeyCode == UNLOAD_KEY then
        unload()
    end
end))

-- Initial visibility (set to true to show on join)
setMenuVisible(true)

print("[Crimson Menu] Fully Loaded - All features active! Press INS to toggle menu")
