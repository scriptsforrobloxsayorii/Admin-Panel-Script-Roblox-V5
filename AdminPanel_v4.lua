
-- ═══════════════════════════════════════════════════════════
--  Admin Panel v4 — Full Rewrite
--  Toggle: ⚡ button (left-center) | J/B keys | P = unlock mouse
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Forward declarations (ALL state vars here) ────────────
local notifDuration = 3
local flying = false
local flyConn = nil
local flySpeed = 50
local noclip = false
local fullbright = false
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalFogEnd = Lighting.FogEnd
local nightVision = false
local nvOverlay = nil
local godMode = false
local autoRespawn = false
local frozen = false
local espMaxDistance = 9999
local espUseTeamColor = false
local espShowTracers = false
local espEnabled = false
local espShowName = true
local espShowHealth = true
local espShowDistance = true
local espColor = Color3.fromRGB(100, 255, 100)
local espObjects = {}
local infiniteJump = false
local antiAfk = false
local afkConn = nil
local speedBoostActive = false
local zoomed = false
local xrayEnabled = false
local xrayOriginalTransparency = {}
local rgbCycle = false
local rgbConn = nil
local showStats = true
local fpsCount = 0
local fpsTimer = 0
local currentFps = 60
local panelAnimating = false
local dragging = false
local dragStart = nil
local startPos = nil
local resizing = false
local resizeStart = nil
local resizeStartSize = nil
local discoMode = false
local infiniteStamina = false
local clickTpEnabled = false
local antiFlingEnabled = false
local antiFlingLastPos = nil
local killed = false
local screenGui = nil
local notifGui = nil
local logGui = nil
local statsGui = nil
local espGui = nil
local toggleBtnGui = nil
local loadingGui = nil
local allConnections = {}
local tabs = {}
local activeTab = nil

-- ── Theme ─────────────────────────────────────────────────
local THEME = {
    bg = Color3.fromRGB(20, 20, 28),
    bgLight = Color3.fromRGB(35, 35, 45),
    bgLighter = Color3.fromRGB(50, 50, 62),
    accent = Color3.fromRGB(100, 150, 255),
    accent2 = Color3.fromRGB(150, 100, 255),
    text = Color3.fromRGB(235, 235, 240),
    textDim = Color3.fromRGB(150, 150, 165),
    green = Color3.fromRGB(60, 180, 90),
    red = Color3.fromRGB(200, 70, 70),
    orange = Color3.fromRGB(255, 160, 50),
}

-- ── Utility ───────────────────────────────────────────────
local function getHumanoid()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function trackConn(conn)
    if killed then conn:Disconnect() return nil end
    table.insert(allConnections, conn)
    return conn
end

-- ── Notification system ────────────────────────────────────
notifGui = Instance.new("ScreenGui")
notifGui.Name = "AdminNotifs"
notifGui.ResetOnSpawn = false
notifGui.IgnoreGuiInset = true
notifGui.Parent = playerGui

local notifContainer = Instance.new("Frame")
notifContainer.Name = "Container"
notifContainer.Size = UDim2.new(0.4, 0, 1, -20)
notifContainer.Position = UDim2.new(1, -10, 0, 10)
notifContainer.AnchorPoint = Vector2.new(1, 0)
local notifSizeConstraint = Instance.new("UISizeConstraint")
notifSizeConstraint.MaxSize = Vector2.new(300, math.huge)
notifSizeConstraint.Parent = notifContainer
notifContainer.BackgroundTransparency = 1
notifContainer.Parent = notifGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0, 6)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifLayout.Parent = notifContainer

local function notify(text, color)
    if killed then return end
    color = color or THEME.accent
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif.BackgroundColor3 = THEME.bgLight
    notif.BorderSizePixel = 0
    notif.Parent = notifContainer
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notif
    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = color
    notifStroke.Thickness = 1
    notifStroke.Transparency = 0.5
    notifStroke.Parent = notif
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.BackgroundColor3 = color
    accentBar.BorderSizePixel = 0
    accentBar.Parent = notif
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 2)
    accentCorner.Parent = accentBar
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 1, -12)
    label.Position = UDim2.fromOffset(12, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = notif
    notif.BackgroundTransparency = 1
    accentBar.BackgroundTransparency = 1
    label.TextTransparency = 1
    notifStroke.Transparency = 1
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 0,
    }):Play()
    TweenService:Create(accentBar, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
    TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    TweenService:Create(notifStroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play()
    task.delay(notifDuration, function()
        if killed then return end
        TweenService:Create(notif, TweenInfo.new(0.3), {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(accentBar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(label, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(notifStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
        task.wait(0.35)
        if notif and notif.Parent then notif:Destroy() end
    end)
end

-- ── Action log system ─────────────────────────────────────
logGui = Instance.new("ScreenGui")
logGui.Name = "AdminLog"
logGui.ResetOnSpawn = false
logGui.IgnoreGuiInset = true
logGui.Enabled = false
logGui.Parent = playerGui

local logFrame = Instance.new("Frame")
logFrame.Name = "LogFrame"
logFrame.Size = UDim2.new(0.4, 0, 0.5, 0)
logFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
logFrame.AnchorPoint = Vector2.new(0.5, 0.5)
local logSizeConstraint = Instance.new("UISizeConstraint")
logSizeConstraint.MaxSize = Vector2.new(400, 500)
logSizeConstraint.Parent = logFrame
logFrame.BackgroundColor3 = THEME.bg
logFrame.BorderSizePixel = 0
logFrame.Parent = logGui
local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 12)
logCorner.Parent = logFrame
local logStroke = Instance.new("UIStroke")
logStroke.Color = THEME.accent
logStroke.Thickness = 1
logStroke.Transparency = 0.6
logStroke.Parent = logFrame

local logTitleBar = Instance.new("Frame")
logTitleBar.Name = "LogTitleBar"
logTitleBar.Size = UDim2.new(1, 0, 0, 40)
logTitleBar.BackgroundTransparency = 1
logTitleBar.Parent = logFrame

local logTitle = Instance.new("TextLabel")
logTitle.Size = UDim2.new(1, -50, 1, 0)
logTitle.Position = UDim2.fromOffset(12, 0)
logTitle.BackgroundTransparency = 1
logTitle.Text = "📋 Action Log"
logTitle.TextColor3 = THEME.text
logTitle.Font = Enum.Font.GothamBold
logTitle.TextSize = 15
logTitle.TextXAlignment = Enum.TextXAlignment.Left
logTitle.Parent = logTitleBar

local logCloseBtn = Instance.new("TextButton")
logCloseBtn.Size = UDim2.fromOffset(30, 30)
logCloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
logCloseBtn.BackgroundColor3 = THEME.red
logCloseBtn.Text = "✕"
logCloseBtn.TextColor3 = THEME.text
logCloseBtn.Font = Enum.Font.GothamBold
logCloseBtn.TextSize = 12
logCloseBtn.Parent = logTitleBar
local logCloseCorner = Instance.new("UICorner")
logCloseCorner.CornerRadius = UDim.new(1, 0)
logCloseCorner.Parent = logCloseBtn

local logClearBtn = Instance.new("TextButton")
logClearBtn.Size = UDim2.fromOffset(60, 24)
logClearBtn.Position = UDim2.new(1, -100, 0.5, -12)
logClearBtn.BackgroundColor3 = THEME.bgLight
logClearBtn.Text = "Clear"
logClearBtn.TextColor3 = THEME.text
logClearBtn.Font = Enum.Font.Gotham
logClearBtn.TextSize = 11
logClearBtn.Parent = logTitleBar
local logClearCorner = Instance.new("UICorner")
logClearCorner.CornerRadius = UDim.new(0, 4)
logClearCorner.Parent = logClearBtn

local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, -12, 1, -48)
logScroll.Position = UDim2.fromOffset(6, 42)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.ScrollBarThickness = 4
logScroll.ScrollBarImageColor3 = THEME.textDim
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
logScroll.Parent = logFrame

local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 4)
logLayout.Parent = logScroll

local logEntries = {}
local logVisible = false

local function getTimestamp()
    local t = os.date("*t")
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

local function addLog(action, category)
    if killed then return end
    category = category or "INFO"
    local ts = getTimestamp()
    local entryText = string.format("[%s] [%s] %s", ts, category, action)
    table.insert(logEntries, entryText)
    local entryLabel = Instance.new("TextLabel")
    entryLabel.Size = UDim2.new(1, 0, 0, 0)
    entryLabel.AutomaticSize = Enum.AutomaticSize.Y
    entryLabel.BackgroundTransparency = 1
    entryLabel.Text = entryText
    entryLabel.TextColor3 = THEME.textDim
    entryLabel.Font = Enum.Font.Code
    entryLabel.TextSize = 11
    entryLabel.TextWrapped = true
    entryLabel.TextXAlignment = Enum.TextXAlignment.Left
    entryLabel.TextYAlignment = Enum.TextYAlignment.Top
    entryLabel.Parent = logScroll
    local catColors = {
        PANEL = THEME.accent, TOGGLE = THEME.green, WARN = THEME.orange,
        ERROR = THEME.red, PLAYER = Color3.fromRGB(255, 150, 200),
        MOVE = Color3.fromRGB(150, 255, 200), VISUAL = Color3.fromRGB(200, 150, 255),
        ESP = Color3.fromRGB(255, 255, 100), MISC = Color3.fromRGB(150, 200, 255),
        SETTINGS = Color3.fromRGB(255, 200, 150),
    }
    if catColors[category] then
        entryLabel.TextColor3 = catColors[category]
    end
    task.defer(function()
        logScroll.CanvasPosition = Vector2.new(0, logScroll.CanvasSize.Y.Offset)
    end)
    print("[AdminPanel] " .. entryText)
end

local function toggleLogWindow()
    logVisible = not logVisible
    logGui.Enabled = logVisible
    if logVisible then
        addLog("Log window opened", "PANEL")
    else
        addLog("Log window closed", "PANEL")
    end
end

trackConn(logCloseBtn.MouseButton1Click:Connect(function()
    toggleLogWindow()
end))

trackConn(logClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(logScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    logEntries = {}
    addLog("Log cleared", "PANEL")
end))

-- ── Stats HUD ────────────────────────────────────────────
statsGui = Instance.new("ScreenGui")
statsGui.Name = "AdminStats"
statsGui.ResetOnSpawn = false
statsGui.IgnoreGuiInset = true
statsGui.Parent = playerGui

local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsLabel"
statsLabel.Size = UDim2.fromOffset(180, 80)
statsLabel.Position = UDim2.new(0, 10, 0, 10)
statsLabel.BackgroundColor3 = THEME.bg
statsLabel.BackgroundTransparency = 0.15
statsLabel.Text = ""
statsLabel.TextColor3 = THEME.text
statsLabel.Font = Enum.Font.Code
statsLabel.TextSize = 12
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Parent = statsGui
local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 8)
statsCorner.Parent = statsLabel
local statsStroke = Instance.new("UIStroke")
statsStroke.Color = THEME.accent
statsStroke.Thickness = 1
statsStroke.Transparency = 0.7
statsStroke.Parent = statsLabel
local statsPadding = Instance.new("UIPadding")
statsPadding.PaddingLeft = UDim.new(0, 8)
statsPadding.PaddingTop = UDim.new(0, 6)
statsPadding.Parent = statsLabel

trackConn(RunService.RenderStepped:Connect(function(dt)
    if killed then return end
    fpsCount = fpsCount + 1
    fpsTimer = fpsTimer + dt
    if fpsTimer >= 1 then
        currentFps = fpsCount
        fpsCount = 0
        fpsTimer = 0
    end
end))

task.spawn(function()
    while not killed do
        task.wait(0.5)
        if showStats and not killed then
            statsLabel.Visible = true
            local hum = getHumanoid()
            local hrp = getHRP()
            local posStr = hrp and string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "N/A"
            local healthStr = hum and string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)) or "N/A"
            local speedStr = hum and tostring(math.floor(hum.WalkSpeed)) or "N/A"
            local fpsColor = currentFps >= 50 and THEME.green or (currentFps >= 30 and THEME.orange or THEME.red)
            statsLabel.Text = string.format(
                "FPS: %d\nPing: %d ms\nPos: %s\nHP: %s | Speed: %s",
                currentFps, math.floor(player:GetNetworkPing() * 1000),
                posStr, healthStr, speedStr
            )
        else
            statsLabel.Visible = false
        end
    end
end)

-- ── Main ScreenGui ────────────────────────────────────────
screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminPanel"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false
screenGui.Parent = playerGui

-- ── Shadow ────────────────────────────────────────────────
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.4
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.Parent = screenGui

-- ── Main window frame ─────────────────────────────────────
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.fromOffset(340, 440)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = THEME.bg
frame.BorderSizePixel = 0
frame.Parent = screenGui
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame
local frameStroke = Instance.new("UIStroke")
frameStroke.Color = THEME.accent
frameStroke.Thickness = 1.5
frameStroke.Transparency = 0.4
frameStroke.Parent = frame

-- gradient on frame
local frameGradient = Instance.new("UIGradient")
frameGradient.Color = ColorSequence.new(THEME.bg, Color3.fromRGB(25, 22, 35))
frameGradient.Rotation = 90
frameGradient.Parent = frame

-- ── Title bar ─────────────────────────────────────────────
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundTransparency = 1
titleBar.Parent = frame

local titleGradientFrame = Instance.new("Frame")
titleGradientFrame.Size = UDim2.new(1, 0, 0, 48)
titleGradientFrame.BackgroundColor3 = THEME.bgLight
titleGradientFrame.BorderSizePixel = 0
titleGradientFrame.Parent = frame
local titleGradCorner = Instance.new("UICorner")
titleGradCorner.CornerRadius = UDim.new(0, 14)
titleGradCorner.Parent = titleGradientFrame
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new(THEME.bgLight, Color3.fromRGB(45, 40, 60))
titleGrad.Rotation = 90
titleGrad.Parent = titleGradientFrame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.fromOffset(16, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ Admin Panel v4"
title.TextColor3 = THEME.text
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.fromOffset(34, 34)
closeBtn.Position = UDim2.new(1, -40, 0.5, -17)
closeBtn.BackgroundColor3 = THEME.red
closeBtn.Text = "✕"
closeBtn.TextColor3 = THEME.text
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = titleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn
local closeGradient = Instance.new("UIGradient")
closeGradient.Color = ColorSequence.new(THEME.red, Color3.fromRGB(170, 50, 50))
closeGradient.Rotation = 90
closeGradient.Parent = closeBtn

-- ── Tab bar ──────────────────────────────────────────────
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -16, 0, 34)
tabBar.Position = UDim2.fromOffset(8, 50)
tabBar.BackgroundTransparency = 1
tabBar.Parent = frame
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 2)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Parent = tabBar

-- ── Content area ─────────────────────────────────────────
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -16, 1, -98)
contentArea.Position = UDim2.fromOffset(8, 88)
contentArea.BackgroundTransparency = 1
contentArea.Parent = frame

-- ── Resize handle ────────────────────────────────────────
local resizeHandle = Instance.new("TextButton")
resizeHandle.Name = "ResizeHandle"
resizeHandle.Size = UDim2.fromOffset(20, 20)
resizeHandle.Position = UDim2.new(1, -22, 1, -22)
resizeHandle.AnchorPoint = Vector2.new(0, 0)
resizeHandle.BackgroundColor3 = THEME.bgLighter
resizeHandle.Text = ""
resizeHandle.Parent = frame
local resizeCorner = Instance.new("UICorner")
resizeCorner.CornerRadius = UDim.new(1, 0)
resizeCorner.Parent = resizeHandle
local resizeDots = Instance.new("ImageLabel")
resizeDots.Size = UDim2.fromOffset(12, 12)
resizeDots.Position = UDim2.new(0.5, -6, 0.5, -6)
resizeDots.BackgroundTransparency = 1
resizeDots.Image = "rbxassetid://6953117316"
resizeDots.ImageColor3 = THEME.textDim
resizeDots.Parent = resizeHandle

-- ── Tab system ───────────────────────────────────────────
local function createTab(name, icon)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = name .. "Tab"
    tabBtn.Size = UDim2.new(0.16, 0, 1, 0)
    tabBtn.BackgroundColor3 = THEME.bgLight
    tabBtn.Text = (icon or "") .. " " .. name
    tabBtn.TextColor3 = THEME.textDim
    tabBtn.Font = Enum.Font.GothamMedium
    tabBtn.TextSize = 11
    tabBtn.AutoButtonColor = false
    tabBtn.Parent = tabBar
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabBtn
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = THEME.textDim
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = contentArea
    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = page
    local tabData = {button = tabBtn, page = page, name = name}
    table.insert(tabs, tabData)
    trackConn(tabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(tabs) do
            if t == tabData then
                t.page.Visible = true
                t.button.BackgroundColor3 = THEME.accent
                t.button.TextColor3 = THEME.text
            else
                t.page.Visible = false
                t.button.BackgroundColor3 = THEME.bgLight
                t.button.TextColor3 = THEME.textDim
            end
        end
        activeTab = tabData
        addLog("Switched to tab: " .. name, "PANEL")
    end))
    -- hover
    trackConn(tabBtn.MouseEnter:Connect(function()
        if activeTab ~= tabData then
            TweenService:Create(tabBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.bgLighter}):Play()
        end
    end))
    trackConn(tabBtn.MouseLeave:Connect(function()
        if activeTab ~= tabData then
            TweenService:Create(tabBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.bgLight}):Play()
        end
    end))
    return tabData
end

-- ── Section header ────────────────────────────────────────
local function createSectionHeader(parent, text)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundTransparency = 1
    header.Text = text
    header.TextColor3 = THEME.accent
    header.Font = Enum.Font.GothamBold
    header.TextSize = 12
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = parent
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = THEME.accent
    line.BackgroundTransparency = 0.6
    line.BorderSizePixel = 0
    line.Parent = header
    return header
end

-- ── UI helpers ───────────────────────────────────────────
local function createSlider(parent, labelText, min, max, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 64)
    row.BackgroundColor3 = THEME.bgLight
    row.BorderSizePixel = 0
    row.Parent = parent
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 0, 20)
    label.Position = UDim2.fromOffset(8, 4)
    label.BackgroundTransparency = 1
    label.Text = labelText .. ": " .. tostring(default)
    label.TextColor3 = THEME.text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -16, 0, 32)
    input.Position = UDim2.fromOffset(8, 26)
    input.BackgroundColor3 = THEME.bgLighter
    input.Text = tostring(default)
    input.TextColor3 = THEME.text
    input.Font = Enum.Font.Gotham
    input.TextSize = 13
    input.ClearTextOnFocus = false
    input.Parent = row
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = input
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = THEME.accent
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.7
    inputStroke.Parent = input
    trackConn(input.FocusLost:Connect(function()
        local value = tonumber(input.Text)
        if value then
            value = math.clamp(value, min, max)
            input.Text = tostring(value)
            label.Text = labelText .. ": " .. tostring(value)
            addLog(labelText .. " set to " .. tostring(value), "INFO")
            callback(value)
        else
            input.Text = tostring(default)
        end
    end))
    return row
end

local function createToggle(parent, labelText, defaultOn, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = THEME.bgLight
    row.BorderSizePixel = 0
    row.Parent = parent
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 8)
    rowCorner.Parent = row
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = THEME.text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    -- iOS-style toggle
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.fromOffset(50, 28)
    toggleBg.Position = UDim2.new(1, -58, 0.5, -14)
    toggleBg.BackgroundColor3 = defaultOn and THEME.green or Color3.fromRGB(60, 60, 70)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = row
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBg
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(22, 22)
    knob.Position = defaultOn and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = Color3.new(0, 0, 0)
    knobStroke.Thickness = 0.5
    knobStroke.Transparency = 0.5
    knobStroke.Parent = knob
    local state = defaultOn
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    trackConn(btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = state and THEME.green or Color3.fromRGB(60, 60, 70)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        }):Play()
        addLog(labelText .. " -> " .. (state and "ON" or "OFF"), "TOGGLE")
        callback(state)
    end))
    return row
end

local function createButton(parent, labelText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = THEME.accent
    btn.Text = labelText
    btn.TextColor3 = THEME.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.Parent = parent
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    local btnGradient = Instance.new("UIGradient")
    btnGradient.Color = ColorSequence.new(THEME.accent, THEME.accent2)
    btnGradient.Rotation = 90
    btnGradient.Parent = btn
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.new(1, 1, 1)
    btnStroke.Thickness = 0.5
    btnStroke.Transparency = 0.8
    btnStroke.Parent = btn
    local debounce = false
    trackConn(btn.MouseButton1Click:Connect(function()
        if debounce then return end
        debounce = true
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = UDim2.new(1, -4, 0, 36), Position = UDim2.new(0, 2, 0, 2)}):Play()
        task.wait(0.08)
        TweenService:Create(btn, TweenInfo.new(0.08), {Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 0)}):Play()
        addLog("Button clicked: " .. labelText, "INFO")
        callback()
        debounce = false
    end))
    trackConn(btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.accent2}):Play()
    end))
    trackConn(btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.accent}):Play()
    end))
    return btn
end

-- ── Create tabs ──────────────────────────────────────────
local playerTab = createTab("Player", "👤")
local moveTab = createTab("Move", "🏃")
local visualTab = createTab("Visual", "👁")
local miscTab = createTab("Misc", "⚙")
local espTab = createTab("ESP", "📍")
local settingsTab = createTab("Settings", "🎨")

-- ── ESP SYSTEM ───────────────────────────────────────────
espGui = Instance.new("ScreenGui")
espGui.Name = "AdminESP"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.Parent = playerGui

local function createESPForPlayer(targetPlayer)
    if targetPlayer == player then return end
    if espObjects[targetPlayer] then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. targetPlayer.Name
    billboard.Size = UDim2.fromOffset(200, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlayer.Name
    nameLabel.TextColor3 = espColor
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Parent = billboard
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0, 16)
    healthLabel.Position = UDim2.fromOffset(0, 20)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = ""
    healthLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 12
    healthLabel.TextStrokeTransparency = 0.5
    healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    healthLabel.Parent = billboard
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 16)
    distLabel.Position = UDim2.fromOffset(0, 36)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = THEME.textDim
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 11
    distLabel.TextStrokeTransparency = 0.5
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLabel.Parent = billboard
    espObjects[targetPlayer] = {
        billboard = billboard,
        nameLabel = nameLabel,
        healthLabel = healthLabel,
        distLabel = distLabel,
    }
end

local function removeESPForPlayer(targetPlayer)
    local data = espObjects[targetPlayer]
    if data then
        if data.billboard then data.billboard:Destroy() end
        espObjects[targetPlayer] = nil
    end
end

local function attachESP(targetPlayer)
    if not espEnabled then return end
    if targetPlayer == player then return end
    createESPForPlayer(targetPlayer)
    local data = espObjects[targetPlayer]
    if data then
        local char = targetPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            data.billboard.Adornee = hrp
            data.billboard.Parent = espGui
        end
    end
end

local function updateESP()
    if not espEnabled then
        for p, _ in pairs(espObjects) do
            removeESPForPlayer(p)
        end
        return
    end
    local localHrp = getHRP()
    for targetPlayer, data in pairs(espObjects) do
        local char = targetPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local dist = localHrp and (localHrp.Position - hrp.Position).Magnitude or 0
            if dist > espMaxDistance then
                data.billboard.Parent = nil
            else
                data.billboard.Adornee = hrp
                data.billboard.Parent = espGui
                data.nameLabel.Visible = espShowName
                if espUseTeamColor and targetPlayer.Team and targetPlayer.TeamColor then
                    data.nameLabel.TextColor3 = targetPlayer.TeamColor.Color
                else
                    data.nameLabel.TextColor3 = espColor
                end
                data.healthLabel.Visible = espShowHealth
                if espShowHealth then
                    data.healthLabel.Text = string.format("HP: %d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
                end
                data.distLabel.Visible = espShowDistance
                if espShowDistance and localHrp then
                    data.distLabel.Text = string.format("%.0f studs", dist)
                end
            end
        else
            data.billboard.Parent = nil
        end
    end
end

task.spawn(function()
    while not killed do
        task.wait(0.2)
        updateESP()
    end
end)

trackConn(Players.PlayerAdded:Connect(function(p)
    addLog("Player joined: " .. p.Name, "INFO")
    if espEnabled then
        trackConn(p.CharacterAdded:Connect(function()
            task.wait(0.5)
            attachESP(p)
        end))
    end
end))

trackConn(Players.PlayerRemoving:Connect(function(p)
    addLog("Player left: " .. p.Name, "INFO")
    removeESPForPlayer(p)
end))

trackConn(player.CharacterAdded:Connect(function()
    addLog("Character spawned/respawned", "PLAYER")
    antiFlingLastPos = nil
end))

-- ESP tab controls
createToggle(espTab.page, "ESP Enabled", false, function(state)
    espEnabled = state
    if state then
        for _, p in ipairs(Players:GetPlayers()) do attachESP(p) end
        notify("ESP enabled", THEME.green)
        addLog("ESP system enabled", "ESP")
    else
        for p, _ in pairs(espObjects) do removeESPForPlayer(p) end
        notify("ESP disabled", THEME.red)
        addLog("ESP system disabled", "ESP")
    end
end)

createToggle(espTab.page, "Show Name", true, function(state) espShowName = state end)
createToggle(espTab.page, "Show Health", true, function(state) espShowHealth = state end)
createToggle(espTab.page, "Show Distance", true, function(state) espShowDistance = state end)
createToggle(espTab.page, "Show Tracers", false, function(state)
    espShowTracers = state
    addLog("ESP Tracers " .. (state and "enabled" or "disabled"), "ESP")
end)
createSlider(espTab.page, "ESP Color R", 0, 255, 100, function(value)
    espColor = Color3.fromRGB(value, math.floor(espColor.G * 255), math.floor(espColor.B * 255))
end)
createSlider(espTab.page, "ESP Color G", 0, 255, 255, function(value)
    espColor = Color3.fromRGB(math.floor(espColor.R * 255), value, math.floor(espColor.B * 255))
end)
createSlider(espTab.page, "ESP Color B", 0, 255, 100, function(value)
    espColor = Color3.fromRGB(math.floor(espColor.R * 255), math.floor(espColor.G * 255), value)
end)
createSlider(espTab.page, "Max ESP Distance", 50, 9999, 9999, function(value)
    espMaxDistance = value
end)
createToggle(espTab.page, "Use Team Color", false, function(state)
    espUseTeamColor = state
    addLog("ESP Team Color " .. (state and "enabled" or "disabled"), "ESP")
end)

-- ── PLAYER TAB ───────────────────────────────────────────
createSectionHeader(playerTab.page, "── Stats ──")
createSlider(playerTab.page, "Walk Speed", 1, 500, 16, function(value)
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = value end
end)
createSlider(playerTab.page, "Jump Power", 0, 500, 50, function(value)
    local hum = getHumanoid()
    if hum then hum.UseJumpPower = true hum.JumpPower = value end
end)
createSlider(playerTab.page, "Jump Height", 0, 100, 7.2, function(value)
    local hum = getHumanoid()
    if hum then hum.UseJumpPower = false hum.JumpHeight = value end
end)
createSlider(playerTab.page, "Hip Height", -10, 50, 0, function(value)
    local hum = getHumanoid()
    if hum then hum.HipHeight = value end
end)
createSlider(playerTab.page, "Max Health", 1, 9999, 100, function(value)
    local hum = getHumanoid()
    if hum then hum.MaxHealth = value hum.Health = value end
end)

createSectionHeader(playerTab.page, "── Actions ──")
createButton(playerTab.page, "🔄 Reset Character", function()
    local hum = getHumanoid()
    if hum then hum.Health = 0 notify("Character reset", THEME.red) addLog("Character reset", "PLAYER") end
end)
createButton(playerTab.page, "💚 Heal to Full", function()
    local hum = getHumanoid()
    if hum then hum.Health = hum.MaxHealth notify("Healed", THEME.green) addLog("Healed to full", "PLAYER") end
end)
createButton(playerTab.page, "📍 TP to 0,100,0", function()
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(0, 100, 0) notify("Teleported", THEME.accent) addLog("TP to 0,100,0", "PLAYER") end
end)

createToggle(playerTab.page, "God Mode", false, function(state)
    godMode = state
    if state then
        addLog("God Mode enabled", "PLAYER")
        task.spawn(function()
            while godMode and not killed do
                local hum = getHumanoid()
                if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
                task.wait(0.1)
            end
        end)
    else
        addLog("God Mode disabled", "PLAYER")
    end
end)

createToggle(playerTab.page, "Infinite Stamina", false, function(state)
    infiniteStamina = state
    if state then
        addLog("Infinite Stamina enabled", "PLAYER")
        task.spawn(function()
            while infiniteStamina and not killed do
                local hum = getHumanoid()
                if hum then
                    local stamina = hum:FindFirstChild("Stamina")
                    if stamina and stamina:IsA("NumberValue") then stamina.Value = stamina.MaxValue or 100 end
                end
                task.wait(0.1)
            end
        end)
    else
        addLog("Infinite Stamina disabled", "PLAYER")
    end
end)

createToggle(playerTab.page, "Sit", false, function(state)
    local hum = getHumanoid()
    if hum then hum.Sit = state addLog("Sit " .. (state and "on" or "off"), "PLAYER") end
end)

createSectionHeader(playerTab.page, "── Player List (TP to) ──")
local playerListScroll = Instance.new("ScrollingFrame")
playerListScroll.Size = UDim2.new(1, 0, 0, 120)
playerListScroll.BackgroundTransparency = 1
playerListScroll.BorderSizePixel = 0
playerListScroll.ScrollBarThickness = 4
playerListScroll.ScrollBarImageColor3 = THEME.textDim
playerListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListScroll.Parent = playerTab.page
local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding = UDim.new(0, 4)
playerListLayout.Parent = playerListScroll

local function refreshPlayerList()
    for _, child in ipairs(playerListScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = THEME.bgLight
            btn.Text = "→ " .. p.Name
            btn.TextColor3 = THEME.text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = playerListScroll
            local btnC = Instance.new("UICorner")
            btnC.CornerRadius = UDim.new(0, 6)
            btnC.Parent = btn
            trackConn(btn.MouseButton1Click:Connect(function()
                local targetChar = p.Character
                local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                local myHrp = getHRP()
                if targetHrp and myHrp then
                    myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0)
                    notify("TP to " .. p.Name, THEME.accent)
                    addLog("TP to " .. p.Name, "PLAYER")
                end
            end))
        end
    end
end
refreshPlayerList()
trackConn(Players.PlayerAdded:Connect(function() task.wait(1) refreshPlayerList() end))
trackConn(Players.PlayerRemoving:Connect(function() task.wait(1) refreshPlayerList() end))

-- ── MOVE TAB ─────────────────────────────────────────────
createSectionHeader(moveTab.page, "── Movement ──")
createToggle(moveTab.page, "Infinite Jump", false, function(state)
    infiniteJump = state
    addLog("Infinite Jump " .. (state and "enabled" or "disabled"), "MOVE")
end)

trackConn(UserInputService.JumpRequest:Connect(function()
    if infiniteJump and not killed then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

createToggle(moveTab.page, "Noclip", false, function(state)
    noclip = state
    if state then notify("Noclip enabled", THEME.green) addLog("Noclip enabled", "MOVE")
    else notify("Noclip disabled", THEME.red) addLog("Noclip disabled", "MOVE") end
    if not state then
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end
            end
        end
    end
end)

task.spawn(function()
    while not killed do
        task.wait(0.1)
        if noclip then
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = false end
                end
            end
        end
    end
end)

createToggle(moveTab.page, "Fly", false, function(state)
    flying = state
    local hrp = getHRP()
    if not hrp then return end
    if state then notify("Fly enabled (WASD+Space/Shift)", THEME.green) addLog("Fly enabled", "MOVE")
    else notify("Fly disabled", THEME.red) addLog("Fly disabled", "MOVE") end
    if state then
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.Name = "FlyVelocity"
        bodyVel.MaxForce = Vector3.new(1, 1, 1) * 1e9
        bodyVel.Velocity = Vector3.zero
        bodyVel.Parent = hrp
        flyConn = RunService.RenderStepped:Connect(function()
            if not flying or not hrp or not hrp.Parent then
                if flyConn then flyConn:Disconnect() end
                if bodyVel then bodyVel:Destroy() end
                return
            end
            local cam = workspace.CurrentCamera
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
            bodyVel.Velocity = (move.Magnitude > 0 and move.Unit * flySpeed or Vector3.zero)
        end)
        table.insert(allConnections, flyConn)
    else
        if flyConn then flyConn:Disconnect() flyConn = nil end
        local existing = hrp:FindFirstChild("FlyVelocity")
        if existing then existing:Destroy() end
    end
end)

createSlider(moveTab.page, "Fly Speed", 10, 300, 50, function(value) flySpeed = value end)

createToggle(moveTab.page, "Click TP", false, function(state)
    clickTpEnabled = state
    addLog("Click TP " .. (state and "enabled" or "disabled"), "MOVE")
end)

trackConn(UserInputService.InputBegan:Connect(function(input, gP)
    if clickTpEnabled and not killed and not gP then
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local cam = workspace.CurrentCamera
            local mousePos = UserInputService:GetMouseLocation()
            local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
            local raycast = workspace:Raycast(ray.Origin, ray.Direction * 1000)
            if raycast then
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = CFrame.new(raycast.Position + Vector3.new(0, 3, 0))
                    notify("Click TP!", THEME.accent)
                    addLog("Click TP to " .. tostring(raycast.Position), "MOVE")
                end
            end
        end
    end
end))

createSectionHeader(moveTab.page, "── Teleport ──")
createButton(moveTab.page, "📍 TP to Spawn", function()
    local hrp = getHRP()
    if hrp then
        local spawn = workspace:FindFirstChild("SpawnLocation")
        if spawn then
            hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
            notify("TP to spawn", THEME.accent) addLog("TP to spawn", "MOVE")
        else notify("No SpawnLocation", THEME.red) end
    end
end)
createButton(moveTab.page, "🚀 Launch Up", function()
    local hrp = getHRP()
    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 200, 0) notify("Launched!", THEME.accent2) addLog("Launch up", "MOVE") end
end)
createButton(moveTab.page, "⬆️ TP Forward 50", function()
    local hrp = getHRP()
    local cam = workspace.CurrentCamera
    if hrp and cam then
        hrp.CFrame = CFrame.new(hrp.Position + cam.CFrame.LookVector * 50)
        notify("TP forward 50", THEME.accent) addLog("TP forward 50", "MOVE")
    end
end)

createSectionHeader(moveTab.page, "── Other ──")
createToggle(moveTab.page, "Anti-AFK", false, function(state)
    antiAfk = state
    if state then
        addLog("Anti-AFK enabled", "MOVE")
        afkConn = UserInputService.Idle:Connect(function()
            if antiAfk and not killed then
                local hum = getHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
        table.insert(allConnections, afkConn)
    else
        addLog("Anti-AFK disabled", "MOVE")
        if afkConn then afkConn:Disconnect() afkConn = nil end
    end
end)

createButton(moveTab.page, "💨 Speed Boost (2x, 5s)", function()
    if speedBoostActive then return end
    speedBoostActive = true
    local hum = getHumanoid()
    if hum then
        local orig = hum.WalkSpeed
        hum.WalkSpeed = orig * 2
        notify("Speed boost!", THEME.green) addLog("Speed boost 2x", "MOVE")
        task.wait(5)
        if hum and hum.Parent then hum.WalkSpeed = orig end
        speedBoostActive = false
        addLog("Speed boost ended", "MOVE")
    end
end)

-- ── VISUAL TAB ──────────────────────────────────────────
createSectionHeader(visualTab.page, "── Lighting ──")
createToggle(visualTab.page, "Fullbright", false, function(state)
    fullbright = state
    if state then
        originalBrightness = Lighting.Brightness
        originalClockTime = Lighting.ClockTime
        originalFogEnd = Lighting.FogEnd
        Lighting.Brightness = 3 Lighting.ClockTime = 12 Lighting.FogEnd = 1e6
        notify("Fullbright on", THEME.green) addLog("Fullbright enabled", "VISUAL")
    else
        Lighting.Brightness = originalBrightness
        Lighting.ClockTime = originalClockTime
        Lighting.FogEnd = originalFogEnd
        notify("Fullbright off", THEME.red) addLog("Fullbright disabled", "VISUAL")
    end
end)

createToggle(visualTab.page, "Night Vision", false, function(state)
    nightVision = state
    if state then
        addLog("Night Vision enabled", "VISUAL")
        if not nvOverlay then
            nvOverlay = Instance.new("ColorCorrectionEffect")
            nvOverlay.Name = "NightVision"
            nvOverlay.Brightness = 0.2
            nvOverlay.Contrast = 0.3
            nvOverlay.TintColor = Color3.fromRGB(100, 255, 100)
            nvOverlay.Parent = Lighting
        end
        Lighting.Brightness = 2
    else
        if nvOverlay then nvOverlay:Destroy() nvOverlay = nil end
        if not fullbright then Lighting.Brightness = originalBrightness end
        addLog("Night Vision disabled", "VISUAL")
    end
end)

createToggle(visualTab.page, "Remove Fog", false, function(state)
    if state then
        originalFogEnd = Lighting.FogEnd
        Lighting.FogEnd = 1e6
        addLog("Fog removed", "VISUAL")
    else
        Lighting.FogEnd = originalFogEnd
        addLog("Fog restored", "VISUAL")
    end
end)

createToggle(visualTab.page, "Disco Mode", false, function(state)
    discoMode = state
    if state then
        addLog("Disco Mode enabled", "VISUAL")
        task.spawn(function()
            while discoMode and not killed do
                Lighting.Ambient = Color3.fromHSV(math.random(), 1, 1)
                Lighting.OutdoorAmbient = Color3.fromHSV(math.random(), 1, 1)
                task.wait(0.1)
            end
        end)
    else
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        addLog("Disco Mode disabled", "VISUAL")
    end
end)

createToggle(visualTab.page, "RGB Ambient Cycle", false, function(state)
    rgbCycle = state
    if state then
        addLog("RGB Cycle enabled", "VISUAL")
        local hue = 0
        rgbConn = RunService.Heartbeat:Connect(function(dt)
            if killed then rgbConn:Disconnect() return end
            hue = (hue + dt * 0.5) % 1
            Lighting.Ambient = Color3.fromHSV(hue, 0.6, 1)
        end)
        table.insert(allConnections, rgbConn)
    else
        addLog("RGB Cycle disabled", "VISUAL")
        if rgbConn then rgbConn:Disconnect() rgbConn = nil end
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    end
end)

createSectionHeader(visualTab.page, "── Camera ──")
createSlider(visualTab.page, "Field of View", 30, 120, 70, function(value)
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = value end
end)
createButton(visualTab.page, "🔍 Toggle Zoom (30/70)", function()
    local cam = workspace.CurrentCamera
    if cam then
        zoomed = not zoomed
        cam.FieldOfView = zoomed and 30 or 70
        notify("Zoom " .. (zoomed and "ON" or "OFF"), THEME.accent)
        addLog("Zoom " .. (zoomed and "30" or "70"), "VISUAL")
    end
end)

createSectionHeader(visualTab.page, "── World ──")
createToggle(visualTab.page, "X-Ray Mode", false, function(state)
    xrayEnabled = state
    if state then
        addLog("X-Ray enabled", "VISUAL")
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsA("Terrain") then
                xrayOriginalTransparency[obj] = obj.Transparency
                obj.Transparency = 0.5
            end
        end
    else
        addLog("X-Ray disabled", "VISUAL")
        for obj, orig in pairs(xrayOriginalTransparency) do
            if obj and obj.Parent then obj.Transparency = orig end
        end
        xrayOriginalTransparency = {}
    end
end)

createSlider(visualTab.page, "Time of Day", 0, 24, 12, function(value)
    if not fullbright then Lighting.ClockTime = value end
end)

-- ── MISC TAB ────────────────────────────────────────────
createSectionHeader(miscTab.page, "── World ──")
createSlider(miscTab.page, "Gravity", 0, 200, 196.2, function(value)
    workspace.Gravity = value
end)
createSlider(miscTab.page, "Jump Cooldown", 0, 5, 0.2, function(value)
    local hum = getHumanoid()
    if hum then hum.JumpCooldown = value end
end)

createSectionHeader(miscTab.page, "── Player ──")
createToggle(miscTab.page, "Auto Respawn", false, function(state)
    autoRespawn = state
    addLog("Auto Respawn " .. (state and "on" or "off"), "MISC")
end)

task.spawn(function()
    while not killed do
        task.wait(1)
        if autoRespawn then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then player:LoadCharacter() end
        end
    end
end)

createToggle(miscTab.page, "Freeze Player", false, function(state)
    frozen = state
    local hrp = getHRP()
    if not hrp then return end
    addLog("Freeze " .. (state and "on" or "off"), "MISC")
    if state then
        local anchor = Instance.new("BodyVelocity")
        anchor.Name = "FreezeAnchor"
        anchor.MaxForce = Vector3.new(1, 1, 1) * 1e9
        anchor.Velocity = Vector3.zero
        anchor.Parent = hrp
    else
        local existing = hrp:FindFirstChild("FreezeAnchor")
        if existing then existing:Destroy() end
    end
end)

createToggle(miscTab.page, "Anti-Fling", false, function(state)
    antiFlingEnabled = state
    addLog("Anti-Fling " .. (state and "on" or "off"), "MISC")
end)

trackConn(RunService.Heartbeat:Connect(function()
    if not antiFlingEnabled or killed then return end
    local hrp = getHRP()
    if not hrp then return end
    pcall(function()
        if hrp.AssemblyLinearVelocity.Magnitude > 250 or hrp.AssemblyAngularVelocity.Magnitude > 250 then
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            if antiFlingLastPos then hrp.CFrame = antiFlingLastPos end
            notify("Anti-Fling: velocity neutralized", THEME.red)
        elseif hrp.AssemblyLinearVelocity.Magnitude < 50 then
            antiFlingLastPos = hrp.CFrame
        end
    end)
end))

createSectionHeader(miscTab.page, "── Info ──")
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 60)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "⚡ button (left-center) — toggle panel\nP — unlock mouse | J/B — toggle panel\nL — toggle action log\n6 tabs: Player, Move, Visual, ESP, Misc, Settings"
infoLabel.TextColor3 = THEME.textDim
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 12
infoLabel.TextWrapped = true
infoLabel.Parent = miscTab.page

createButton(miscTab.page, "📋 Toggle Action Log", function() toggleLogWindow() end)
createButton(miscTab.page, "📋 Copy Position", function()
    local hrp = getHRP()
    if hrp then
        local pos = hrp.Position
        local text = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
        if setclipboard then setclipboard(text) notify("Copied: " .. text, THEME.green) else notify("Pos: " .. text, THEME.accent) end
        addLog("Position copied: " .. text, "MISC")
    end
end)

local serverInfoLabel = Instance.new("TextLabel")
serverInfoLabel.Size = UDim2.new(1, 0, 0, 70)
serverInfoLabel.BackgroundColor3 = THEME.bgLight
serverInfoLabel.BorderSizePixel = 0
serverInfoLabel.Text = "Loading..."
serverInfoLabel.TextColor3 = THEME.text
serverInfoLabel.Font = Enum.Font.Code
serverInfoLabel.TextSize = 11
serverInfoLabel.TextWrapped = true
serverInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
serverInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
serverInfoLabel.Parent = miscTab.page
local siCorner = Instance.new("UICorner")
siCorner.CornerRadius = UDim.new(0, 6)
siCorner.Parent = serverInfoLabel
local siPadding = Instance.new("UIPadding")
siPadding.PaddingLeft = UDim.new(0, 8)
siPadding.PaddingTop = UDim.new(0, 6)
siPadding.Parent = serverInfoLabel

task.spawn(function()
    while not killed do
        task.wait(1)
        serverInfoLabel.Text = string.format(
            "Players: %d\nPing: %.0f ms\nFPS: %d\nJobId: %s",
            #Players:GetPlayers(), player:GetNetworkPing() * 1000, currentFps, game.JobId or "N/A"
        )
    end
end)

createSectionHeader(miscTab.page, "── Server ──")
createButton(miscTab.page, "🚪 Leave Game", function()
    addLog("Left game", "MISC")
    Players.LocalPlayer:Kick("Left via Admin Panel")
end)
createButton(miscTab.page, "🔄 Rejoin", function()
    addLog("Rejoining", "MISC")
    if game.JobId and game.JobId ~= "" then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    else
        TeleportService:Teleport(game.PlaceId, player)
    end
end)
createButton(miscTab.page, "🔀 Server Hop", function()
    addLog("Server hopping", "MISC")
    TeleportService:Teleport(game.PlaceId, player)
end)

-- ── SETTINGS TAB ────────────────────────────────────────
createToggle(settingsTab.page, "Show Stats HUD", true, function(state)
    showStats = state
    notify("Stats HUD " .. (state and "on" or "off"), state and THEME.green or THEME.red)
    addLog("Stats HUD " .. (state and "on" or "off"), "SETTINGS")
end)

createSlider(settingsTab.page, "Text Size", 8, 20, 13, function(value)
    for _, child in ipairs(screenGui:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            if child.Name ~= "Title" and child.Name ~= "CloseButton" then
                child.TextSize = value
            end
        end
    end
end)

createSlider(settingsTab.page, "Accent R", 0, 255, 100, function(value)
    THEME.accent = Color3.fromRGB(value, math.floor(THEME.accent.G * 255), math.floor(THEME.accent.B * 255))
    for _, t in ipairs(tabs) do
        if t.page.Visible then t.button.BackgroundColor3 = THEME.accent end
    end
    frameStroke.Color = THEME.accent
end)
createSlider(settingsTab.page, "Accent G", 0, 255, 150, function(value)
    THEME.accent = Color3.fromRGB(math.floor(THEME.accent.R * 255), value, math.floor(THEME.accent.B * 255))
    for _, t in ipairs(tabs) do
        if t.page.Visible then t.button.BackgroundColor3 = THEME.accent end
    end
    frameStroke.Color = THEME.accent
end)
createSlider(settingsTab.page, "Accent B", 0, 255, 255, function(value)
    THEME.accent = Color3.fromRGB(math.floor(THEME.accent.R * 255), math.floor(THEME.accent.G * 255), value)
    for _, t in ipairs(tabs) do
        if t.page.Visible then t.button.BackgroundColor3 = THEME.accent end
    end
    frameStroke.Color = THEME.accent
end)

createSlider(settingsTab.page, "Panel Opacity", 0, 100, 85, function(value)
    frame.BackgroundTransparency = 1 - (value / 100)
end)
createSlider(settingsTab.page, "Stats Opacity", 0, 100, 85, function(value)
    statsLabel.BackgroundTransparency = 1 - (value / 100)
end)
createSlider(settingsTab.page, "Notif Duration (s)", 1, 10, 3, function(value)
    notifDuration = value
end)

createButton(settingsTab.page, "💾 Save Settings", function()
    local s = script or playerGui:FindFirstChild("AdminPanel")
    if s then
        s:SetAttribute("AccentR", THEME.accent.R)
        s:SetAttribute("AccentG", THEME.accent.G)
        s:SetAttribute("AccentB", THEME.accent.B)
        s:SetAttribute("ShowStats", showStats)
    end
    notify("Settings saved!", THEME.green) addLog("Settings saved", "SETTINGS")
end)
createButton(settingsTab.page, "📂 Load Settings", function()
    local s = script or playerGui:FindFirstChild("AdminPanel")
    if s then
        local r = s:GetAttribute("AccentR")
        local g = s:GetAttribute("AccentG")
        local b = s:GetAttribute("AccentB")
        local st = s:GetAttribute("ShowStats")
        if r and g and b then
            THEME.accent = Color3.new(r, g, b)
            for _, t in ipairs(tabs) do
                if t.page.Visible then t.button.BackgroundColor3 = THEME.accent end
            end
            frameStroke.Color = THEME.accent
        end
        if st ~= nil then showStats = st end
    end
    notify("Settings loaded!", THEME.accent) addLog("Settings loaded", "SETTINGS")
end)
createButton(settingsTab.page, "🔄 Reset Settings", function()
    THEME.accent = Color3.fromRGB(100, 150, 255)
    for _, t in ipairs(tabs) do
        if t.page.Visible then t.button.BackgroundColor3 = THEME.accent end
    end
    frameStroke.Color = THEME.accent
    showStats = true
    notify("Settings reset!", THEME.accent2) addLog("Settings reset", "SETTINGS")
end)

createButton(settingsTab.page, "⚠️ Reset All Features", function()
    flying = false
    local hrp = getHRP()
    if hrp then
        if flyConn then flyConn:Disconnect() flyConn = nil end
        local existing = hrp:FindFirstChild("FlyVelocity")
        if existing then existing:Destroy() end
    end
    noclip = false
    local char = player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end
        end
    end
    fullbright = false
    Lighting.Brightness = originalBrightness
    Lighting.ClockTime = originalClockTime
    Lighting.FogEnd = originalFogEnd
    nightVision = false
    if nvOverlay then nvOverlay:Destroy() nvOverlay = nil end
    discoMode = false
    rgbCycle = false
    if rgbConn then rgbConn:Disconnect() rgbConn = nil end
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    espEnabled = false
    for p, _ in pairs(espObjects) do removeESPForPlayer(p) end
    infiniteJump = false
    godMode = false
    autoRespawn = false
    frozen = false
    infiniteStamina = false
    clickTpEnabled = false
    antiFlingEnabled = false
    discoMode = false
    xrayEnabled = false
    for obj, orig in pairs(xrayOriginalTransparency) do
        if obj and obj.Parent then obj.Transparency = orig end
    end
    xrayOriginalTransparency = {}
    if hrp then
        local fa = hrp:FindFirstChild("FreezeAnchor")
        if fa then fa:Destroy() end
    end
    workspace.Gravity = 196.2
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = 70 end
    notify("All features reset!", THEME.red) addLog("All features reset", "WARN")
end)

-- KILL SCRIPT BUTTON
createSectionHeader(settingsTab.page, "── ⚠ Danger Zone ──")
local killBtn = Instance.new("TextButton")
killBtn.Size = UDim2.new(1, 0, 0, 44)
killBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
killBtn.Text = "💀 KILL SCRIPT (Remove Everything)"
killBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
killBtn.Font = Enum.Font.GothamBold
killBtn.TextSize = 13
killBtn.Parent = settingsTab.page
local killCorner = Instance.new("UICorner")
killCorner.CornerRadius = UDim.new(0, 8)
killCorner.Parent = killBtn
local killStroke = Instance.new("UIStroke")
killStroke.Color = THEME.red
killStroke.Thickness = 1.5
killStroke.Parent = killBtn
trackConn(killBtn.MouseEnter:Connect(function()
    TweenService:Create(killBtn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.red}):Play()
end))
trackConn(killBtn.MouseLeave:Connect(function()
    TweenService:Create(killBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 20, 20)}):Play()
end))
trackConn(killBtn.MouseButton1Click:Connect(function()
    killed = true
    -- disconnect all
    for _, conn in ipairs(allConnections) do
        pcall(function() conn:Disconnect() end)
    end
    allConnections = {}
    -- stop features
    flying = false noclip = false godMode = false infiniteJump = false
    espEnabled = false autoRespawn = false discoMode = false
    rgbCycle = false antiFlingEnabled = false clickTpEnabled = false
    fullbright = false nightVision = false xrayEnabled = false
    if flyConn then pcall(function() flyConn:Disconnect() end) flyConn = nil end
    if afkConn then pcall(function() afkConn:Disconnect() end) afkConn = nil end
    if rgbConn then pcall(function() rgbConn:Disconnect() end) rgbConn = nil end
    -- restore
    pcall(function()
        Lighting.Brightness = originalBrightness
        Lighting.ClockTime = originalClockTime
        Lighting.FogEnd = originalFogEnd
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)
    if nvOverlay then pcall(function() nvOverlay:Destroy() end) nvOverlay = nil end
    for obj, orig in pairs(xrayOriginalTransparency) do
        pcall(function() if obj and obj.Parent then obj.Transparency = orig end end)
    end
    for p, _ in pairs(espObjects) do pcall(function() removeESPForPlayer(p) end) end
    local hrp = getHRP()
    if hrp then
        local fv = hrp:FindFirstChild("FlyVelocity")
        if fv then pcall(function() fv:Destroy() end) end
        local fa = hrp:FindFirstChild("FreezeAnchor")
        if fa then pcall(function() fa:Destroy() end) end
    end
    pcall(function() workspace.Gravity = 196.2 end)
    -- destroy GUIs
    pcall(function() if screenGui then screenGui:Destroy() end end)
    pcall(function() if notifGui then notifGui:Destroy() end end)
    pcall(function() if logGui then logGui:Destroy() end end)
    pcall(function() if statsGui then statsGui:Destroy() end end)
    pcall(function() if espGui then espGui:Destroy() end end)
    pcall(function() if toggleBtnGui then toggleBtnGui:Destroy() end end)
    pcall(function() if loadingGui then loadingGui:Destroy() end end)
    print("[AdminPanel] Script killed. All GUIs destroyed, all connections disconnected.")
end))

-- ── Activate first tab ──────────────────────────────────
if #tabs > 0 then
    tabs[1].button.BackgroundColor3 = THEME.accent
    tabs[1].button.TextColor3 = THEME.text
    tabs[1].page.Visible = true
    activeTab = tabs[1]
end

-- ── Floating toggle button (LEFT-CENTER) ──────────────
toggleBtnGui = Instance.new("ScreenGui")
toggleBtnGui.Name = "AdminToggle"
toggleBtnGui.ResetOnSpawn = false
toggleBtnGui.IgnoreGuiInset = true
toggleBtnGui.Parent = playerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.fromOffset(52, 52)
toggleBtn.Position = UDim2.new(0, 8, 0.5, -26)
toggleBtn.BackgroundColor3 = THEME.accent
toggleBtn.BackgroundTransparency = 0.1
toggleBtn.Text = "⚡"
toggleBtn.TextColor3 = THEME.text
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 24
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = toggleBtnGui
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggleBtn
local toggleGradient = Instance.new("UIGradient")
toggleGradient.Color = ColorSequence.new(THEME.accent, THEME.accent2)
toggleGradient.Rotation = 90
toggleGradient.Parent = toggleBtn
local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.new(1, 1, 1)
toggleStroke.Thickness = 1
toggleStroke.Transparency = 0.6
toggleStroke.Parent = toggleBtn

-- pulse when panel closed
task.spawn(function()
    while not killed do
        if not screenGui.Enabled then
            TweenService:Create(toggleBtn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.4,
                Size = UDim2.fromOffset(56, 56),
                Position = UDim2.new(0, 6, 0.5, -28),
            }):Play()
            task.wait(0.8)
            if killed then break end
            TweenService:Create(toggleBtn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.1,
                Size = UDim2.fromOffset(52, 52),
                Position = UDim2.new(0, 8, 0.5, -26),
            }):Play()
            task.wait(0.8)
        else
            task.wait(0.5)
        end
    end
end)

-- ── Open / close animation ──────────────────────────────
local function getPanelSize()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(340, 440)
    local w = math.min(vp.X * 0.9, 340)
    return UDim2.fromOffset(w, 440)
end

local function updateShadow()
    shadow.Size = UDim2.new(0, frame.Size.X.Offset + 20, 0, frame.Size.Y.Offset + 20)
    shadow.Position = frame.Position
end

local function openPanel()
    if panelAnimating or killed then return end
    panelAnimating = true
    screenGui.Enabled = true
    toggleBtn.Visible = false
    frame.Size = UDim2.fromOffset(0, 0)
    updateShadow()
    shadow.ImageTransparency = 1
    TweenService:Create(shadow, TweenInfo.new(0.3), {ImageTransparency = 0.4}):Play()
    local tween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = getPanelSize()
    })
    tween:Play()
    trackConn(tween.Completed:Connect(function()
        panelAnimating = false
        updateShadow()
    end))
    notify("Admin Panel opened", THEME.accent)
    addLog("Panel opened", "PANEL")
end

local function closePanel()
    if panelAnimating or killed then return end
    panelAnimating = true
    TweenService:Create(shadow, TweenInfo.new(0.25), {ImageTransparency = 1}):Play()
    local tween = TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 0)
    })
    tween:Play()
    trackConn(tween.Completed:Connect(function()
        if killed then return end
        screenGui.Enabled = false
        frame.Size = getPanelSize()
        toggleBtn.Visible = true
        panelAnimating = false
    end))
    addLog("Panel closed", "PANEL")
end

trackConn(closeBtn.MouseButton1Click:Connect(function()
    addLog("Panel closed via ✕", "PANEL")
    closePanel()
end))

trackConn(toggleBtn.MouseButton1Click:Connect(function()
    if screenGui.Enabled then closePanel() else openPanel() end
end))

-- ── Keybinds ────────────────────────────────────────────
trackConn(UserInputService.InputBegan:Connect(function(input, gP)
    if gP or killed then return end
    if input.KeyCode == Enum.KeyCode.J or input.KeyCode == Enum.KeyCode.B then
        if screenGui.Enabled then closePanel() else openPanel() end
    end
    if input.KeyCode == Enum.KeyCode.P then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        addLog("Mouse unlocked (P)", "PANEL")
    end
    if input.KeyCode == Enum.KeyCode.L then
        toggleLogWindow()
    end
end))

-- ── Dragging ────────────────────────────────────────────
trackConn(titleBar.InputBegan:Connect(function(input)
    if killed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end))

trackConn(titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

trackConn(UserInputService.InputChanged:Connect(function(input)
    if killed then return end
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        updateShadow()
    end
end))

-- ── Resizing ────────────────────────────────────────────
trackConn(resizeHandle.InputBegan:Connect(function(input)
    if killed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        resizeStartSize = frame.Size
    end
end))

trackConn(resizeHandle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end))

trackConn(UserInputService.InputChanged:Connect(function(input)
    if killed then return end
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStart
        local newW = math.clamp(resizeStartSize.X.Offset + delta.X, 280, 600)
        local newH = math.clamp(resizeStartSize.Y.Offset + delta.Y, 340, 700)
        frame.Size = UDim2.fromOffset(newW, newH)
        updateShadow()
    end
end))

-- ── LOADING SCREEN ──────────────────────────────────────
loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "AdminLoading"
loadingGui.ResetOnSpawn = false
loadingGui.IgnoreGuiInset = true
loadingGui.DisplayOrder = 999
loadingGui.Parent = playerGui

local loadBg = Instance.new("Frame")
loadBg.Size = UDim2.new(1, 0, 1, 0)
loadBg.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
loadBg.BackgroundTransparency = 1
loadBg.BorderSizePixel = 0
loadBg.Parent = loadingGui
local loadBgGradient = Instance.new("UIGradient")
loadBgGradient.Color = ColorSequence.new(Color3.fromRGB(15, 10, 30), Color3.fromRGB(10, 15, 25))
loadBgGradient.Rotation = 90
loadBgGradient.Parent = loadBg

-- particles
local particles = {}
for i = 1, 25 do
    local p = Instance.new("Frame")
    p.Size = UDim2.fromOffset(math.random(4, 10), math.random(4, 10))
    p.Position = UDim2.new(math.random(), 0, math.random(), 0)
    p.BackgroundColor3 = Color3.fromHSV(math.random() / 2 + 0.3, 0.6, 1)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.Parent = loadBg
    local pc = Instance.new("UICorner")
    pc.CornerRadius = UDim.new(1, 0)
    pc.Parent = p
    particles[i] = {frame = p, velX = (math.random() - 0.5) * 200, velY = (math.random() - 0.5) * 200, rot = math.random(0, 360)}
end

local loadCard = Instance.new("Frame")
loadCard.Size = UDim2.fromOffset(360, 220)
loadCard.Position = UDim2.new(0.5, 0, 0.5, 0)
loadCard.AnchorPoint = Vector2.new(0.5, 0.5)
loadCard.BackgroundColor3 = THEME.bg
loadCard.BorderSizePixel = 0
loadCard.Parent = loadBg
local loadCardCorner = Instance.new("UICorner")
loadCardCorner.CornerRadius = UDim.new(0, 16)
loadCardCorner.Parent = loadCard
local loadCardStroke = Instance.new("UIStroke")
loadCardStroke.Color = THEME.accent
loadCardStroke.Thickness = 1.5
loadCardStroke.Transparency = 0.5
loadCardStroke.Parent = loadCard
local loadCardGrad = Instance.new("UIGradient")
loadCardGrad.Color = ColorSequence.new(THEME.bg, Color3.fromRGB(30, 25, 40))
loadCardGrad.Rotation = 90
loadCardGrad.Parent = loadCard

-- spinning ring
local ring = Instance.new("Frame")
ring.Size = UDim2.fromOffset(80, 80)
ring.Position = UDim2.new(0.5, 0, 0, 30)
ring.AnchorPoint = Vector2.new(0.5, 0)
ring.BackgroundTransparency = 1
ring.Parent = loadCard
local ringStroke = Instance.new("UIStroke")
ringStroke.Color = THEME.accent
ringStroke.Thickness = 3
ringStroke.Transparency = 0.3
ringStroke.Parent = ring
local ringGrad = Instance.new("UIGradient")
ringGrad.Color = ColorSequence.new(THEME.accent, THEME.accent2)
ringGrad.Parent = ringStroke

local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromOffset(50, 50)
icon.Position = UDim2.new(0.5, 0, 0, 45)
icon.AnchorPoint = Vector2.new(0.5, 0)
icon.BackgroundTransparency = 1
icon.Text = "⚡"
icon.TextColor3 = THEME.text
icon.Font = Enum.Font.GothamBold
icon.TextSize = 36
icon.Parent = loadCard

local loadTitle = Instance.new("TextLabel")
loadTitle.Size = UDim2.new(1, 0, 0, 30)
loadTitle.Position = UDim2.new(0, 0, 0, 120)
loadTitle.BackgroundTransparency = 1
loadTitle.Text = "Admin Panel v4"
loadTitle.TextColor3 = THEME.text
loadTitle.Font = Enum.Font.GothamBold
loadTitle.TextSize = 20
loadTitle.Parent = loadCard
local loadTitleGrad = Instance.new("UIGradient")
loadTitleGrad.Color = ColorSequence.new(THEME.accent, THEME.accent2)
loadTitleGrad.Parent = loadTitle

local loadStatus = Instance.new("TextLabel")
loadStatus.Size = UDim2.new(1, -20, 0, 18)
loadStatus.Position = UDim2.new(0, 10, 0, 155)
loadStatus.BackgroundTransparency = 1
loadStatus.Text = "Initializing..."
loadStatus.TextColor3 = THEME.textDim
loadStatus.Font = Enum.Font.Gotham
loadStatus.TextSize = 12
loadStatus.Parent = loadCard

local loadBarBg = Instance.new("Frame")
loadBarBg.Size = UDim2.new(1, -40, 0, 8)
loadBarBg.Position = UDim2.new(0, 20, 0, 180)
loadBarBg.BackgroundColor3 = THEME.bgLight
loadBarBg.BorderSizePixel = 0
loadBarBg.Parent = loadCard
local loadBarBgCorner = Instance.new("UICorner")
loadBarBgCorner.CornerRadius = UDim.new(1, 0)
loadBarBgCorner.Parent = loadBarBg

local loadBar = Instance.new("Frame")
loadBar.Size = UDim2.new(0, 0, 1, 0)
loadBar.BackgroundColor3 = THEME.accent
loadBar.BorderSizePixel = 0
loadBar.Parent = loadBarBg
local loadBarCorner = Instance.new("UICorner")
loadBarCorner.CornerRadius = UDim.new(1, 0)
loadBarCorner.Parent = loadBar
local loadBarGrad = Instance.new("UIGradient")
loadBarGrad.Color = ColorSequence.new(THEME.accent, THEME.accent2)
loadBarGrad.Parent = loadBar

local loadPercent = Instance.new("TextLabel")
loadPercent.Size = UDim2.new(1, -20, 0, 16)
loadPercent.Position = UDim2.new(0, 10, 0, 195)
loadPercent.BackgroundTransparency = 1
loadPercent.Text = "0%"
loadPercent.TextColor3 = THEME.accent
loadPercent.Font = Enum.Font.GothamBold
loadPercent.TextSize = 11
loadPercent.Parent = loadCard

-- ── Loading animation ──────────────────────────────────
local loadingSteps = {
    "Initializing core systems...",
    "Loading UI components...",
    "Setting up tabs...",
    "Configuring ESP...",
    "Building interface...",
    "Applying animations...",
    "Finalizing...",
}

task.spawn(function()
    -- fade in
    loadCard.Size = UDim2.fromOffset(0, 0)
    TweenService:Create(loadBg, TweenInfo.new(0.6), {BackgroundTransparency = 0}):Play()
    task.wait(0.3)
    TweenService:Create(loadCard, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(360, 220)
    }):Play()
    task.wait(0.3)

    -- animate particles
    task.spawn(function()
        while not killed and loadingGui.Parent do
            for _, p in ipairs(particles) do
                if p.frame and p.frame.Parent then
                    local curX = p.frame.Position.X.Scale
                    local curY = p.frame.Position.Y.Scale
                    curX = curX + p.velX / 1000
                    curY = curY + p.velY / 1000
                    if curX < 0 or curX > 1 then p.velX = -p.velX curX = math.clamp(curX, 0, 1) end
                    if curY < 0 or curY > 1 then p.velY = -p.velY curY = math.clamp(curY, 0, 1) end
                    p.frame.Position = UDim2.new(curX, 0, curY, 0)
                    p.rot = p.rot + 1
                    p.frame.Rotation = p.rot
                    TweenService:Create(p.frame, TweenInfo.new(0.5), {BackgroundTransparency = 0.7}):Play()
                end
            end
            task.wait(0.03)
        end
    end)

    -- spin ring
    task.spawn(function()
        while not killed and loadingGui.Parent do
            ring.Rotation = ring.Rotation + 3
            task.wait(0.01)
        end
    end)

    -- progress
    for i, step in ipairs(loadingSteps) do
        if killed then return end
        loadStatus.Text = step
        local pct = (i / #loadingSteps) * 100
        TweenService:Create(loadBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
            Size = UDim2.new(pct / 100, 0, 1, 0)
        }):Play()
        -- animate percent text
        local startPct = tonumber(string.match(loadPercent.Text, "%d+")) or 0
        local animTime = 0.4
        local elapsed = 0
        while elapsed < animTime do
            elapsed = elapsed + 0.02
            local t = elapsed / animTime
            local cur = math.floor(startPct + (pct - startPct) * t)
            loadPercent.Text = tostring(cur) .. "%"
            task.wait(0.02)
        end
        loadPercent.Text = tostring(math.floor(pct)) .. "%"
        task.wait(0.3)
    end

    task.wait(0.5)
    loadStatus.Text = "Ready!"

    -- fade out
    task.wait(0.5)
    TweenService:Create(loadCard, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 0)
    }):Play()
    for _, p in ipairs(particles) do
        if p.frame then
            TweenService:Create(p.frame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        end
    end
    TweenService:Create(loadBg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    task.wait(0.6)
    if loadingGui and loadingGui.Parent then
        loadingGui:Destroy()
    end
end)

addLog("Admin Panel v4 loaded", "INFO")
