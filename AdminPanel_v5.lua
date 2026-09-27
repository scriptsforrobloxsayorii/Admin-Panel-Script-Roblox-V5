-- ═══════════════════════════════════════════════════════════
--  Admin Panel v5 — Improved Edition
--  Toggle: ⚡ button (left-center) | J/B keys | P = unlock mouse
--  Changelog: Better error handling, re-hook on respawn, improved
--  fly/ESP/noclip, ESP tracers, command bar, chat commands, performance
-- ═══════════════════════════════════════════════════════════

-- ── Services ─────────────────────────────────────────────
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

-- ── Safe parent (works in executor and Studio) ──────────
local safeParent
pcall(function() safeParent = CoreGui end)
if not safeParent then safeParent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local player = Players.LocalPlayer
local playerGui = safeParent

-- ── Safe instance creator ────────────────────────────────
local function sInst(class, props)
    local obj
    local ok = pcall(function() obj = Instance.new(class) end)
    if not ok or not obj then return nil end
    if props then
        for k, v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

-- ── State ────────────────────────────────────────────────
local notifDuration = 3
local flying = false
local flyConn = nil
local flySpeed = 50
local noclip = false
local noclipConn = nil
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
local espTracers = {}
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
local commandBar = nil
local chatConn = nil

-- ── Theme ───────────────────────────────────────────────
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

-- ── Utility ─────────────────────────────────────────────
local function getHumanoid()
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum
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

local function safeNotify(text, color)
    pcall(notify, text, color)
end

-- ── Notification system ──────────────────────────────────
notifGui = sInst("ScreenGui", {
    Name = "APN_" .. tostring(math.random(10000, 99999)),
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    Parent = playerGui,
})

local notifContainer = sInst("Frame", {
    Name = "Container",
    Size = UDim2.new(0.4, 0, 1, -20),
    Position = UDim2.new(1, -10, 0, 10),
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    Parent = notifGui,
})
local notifSizeConstraint = sInst("UISizeConstraint", {
    MaxSize = Vector2.new(300, math.huge),
    Parent = notifContainer,
})
local notifLayout = sInst("UIListLayout", {
    Padding = UDim.new(0, 6),
    VerticalAlignment = Enum.VerticalAlignment.Top,
    Parent = notifContainer,
})

function notify(text, color)
    if killed then return end
    color = color or THEME.accent
    local notif = sInst("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = THEME.bgLight,
        BorderSizePixel = 0,
        Parent = notifContainer,
    })
    local notifCorner = sInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notif })
    local notifStroke = sInst("UIStroke", { Color = color, Thickness = 1, Transparency = 0.5, Parent = notif })
    local accentBar = sInst("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = notif,
    })
    sInst("UICorner", { CornerRadius = UDim.new(0, 2), Parent = accentBar })
    local label = sInst("TextLabel", {
        Size = UDim2.new(1, -16, 1, -12),
        Position = UDim2.fromOffset(12, 6),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = THEME.text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = notif,
    })
    notif.BackgroundTransparency = 1
    accentBar.BackgroundTransparency = 1
    label.TextTransparency = 1
    notifStroke.Transparency = 1
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 0,
    }):Play()
    TweenService:Create(accentBar, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
    TweenService:Create(notifStroke, TweenInfo.new(0.3), { Transparency = 0.5 }):Play()
    task.delay(notifDuration, function()
        if killed then return end
        TweenService:Create(notif, TweenInfo.new(0.3), {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(accentBar, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        TweenService:Create(notifStroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
        task.wait(0.35)
        if notif and notif.Parent then notif:Destroy() end
    end)
end

-- ── Action log system ────────────────────────────────────
logGui = sInst("ScreenGui", {
    Name = "APL_" .. tostring(math.random(10000, 99999)),
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    Enabled = false,
    Parent = playerGui,
})

local logFrame = sInst("Frame", {
    Size = UDim2.new(0.4, 0, 0.5, 0),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = THEME.bg,
    BorderSizePixel = 0,
    Parent = logGui,
})
sInst("UISizeConstraint", { MaxSize = Vector2.new(400, 500), Parent = logFrame })
sInst("UICorner", { CornerRadius = UDim.new(0, 12), Parent = logFrame })
sInst("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.6, Parent = logFrame })

local logTitleBar = sInst("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Parent = logFrame,
})
sInst("TextLabel", {
    Size = UDim2.new(1, -50, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "📋 Action Log",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = logTitleBar,
})
local logCloseBtn = sInst("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -35, 0.5, -15),
    BackgroundColor3 = THEME.red,
    Text = "✕",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Parent = logTitleBar,
})
sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = logCloseBtn })
local logClearBtn = sInst("TextButton", {
    Size = UDim2.fromOffset(60, 24),
    Position = UDim2.new(1, -100, 0.5, -12),
    BackgroundColor3 = THEME.bgLight,
    Text = "Clear",
    TextColor3 = THEME.text,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    Parent = logTitleBar,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 4), Parent = logClearBtn })

local logScroll = sInst("ScrollingFrame", {
    Size = UDim2.new(1, -12, 1, -48),
    Position = UDim2.fromOffset(6, 42),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = THEME.textDim,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = logFrame,
})
sInst("UIListLayout", { Padding = UDim.new(0, 4), Parent = logScroll })

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
    local entryLabel = sInst("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = entryText,
        TextColor3 = THEME.textDim,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = logScroll,
    })
    local catColors = {
        PANEL = THEME.accent, TOGGLE = THEME.green, WARN = THEME.orange,
        ERROR = THEME.red, PLAYER = Color3.fromRGB(255, 150, 200),
        MOVE = Color3.fromRGB(150, 255, 200), VISUAL = Color3.fromRGB(200, 150, 255),
        ESP = Color3.fromRGB(255, 255, 100), MISC = Color3.fromRGB(150, 200, 255),
        SETTINGS = Color3.fromRGB(255, 200, 150), CMD = Color3.fromRGB(100, 255, 200),
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
end

trackConn(logCloseBtn.MouseButton1Click:Connect(function() toggleLogWindow() end))
trackConn(logClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(logScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    logEntries = {}
    addLog("Log cleared", "PANEL")
end))

-- ── Stats HUD ───────────────────────────────────────────
statsGui = sInst("ScreenGui", {
    Name = "APS_" .. tostring(math.random(10000, 99999)),
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    Parent = playerGui,
})
local statsLabel = sInst("TextLabel", {
    Size = UDim2.fromOffset(180, 80),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = THEME.bg,
    BackgroundTransparency = 0.15,
    Text = "",
    TextColor3 = THEME.text,
    Font = Enum.Font.Code,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Parent = statsGui,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = statsLabel })
sInst("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.7, Parent = statsLabel })
sInst("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), Parent = statsLabel })

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
            statsLabel.Text = string.format(
                "FPS: %d\nPing: %d ms\nPos: %s\nHP: %s | Speed: %s",
                currentFps, math.floor((player:GetNetworkPing and player:GetNetworkPing() or 0) * 1000),
                posStr, healthStr, speedStr
            )
        else
            statsLabel.Visible = false
        end
    end
end)

-- ── Main ScreenGui ──────────────────────────────────────
screenGui = sInst("ScreenGui", {
    Name = "APM_" .. tostring(math.random(10000, 99999)),
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    Enabled = false,
    Parent = playerGui,
})

-- ── Shadow ──────────────────────────────────────────────
local shadow = sInst("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Image = "rbxassetid://1316045217",
    ImageColor3 = Color3.new(0, 0, 0),
    ImageTransparency = 0.4,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(10, 10, 118, 118),
    Parent = screenGui,
})

-- ── Main window frame ───────────────────────────────────
local frame = sInst("Frame", {
    Size = UDim2.fromOffset(340, 440),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = THEME.bg,
    BorderSizePixel = 0,
    Parent = screenGui,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 14), Parent = frame })
local frameStroke = sInst("UIStroke", { Color = THEME.accent, Thickness = 1.5, Transparency = 0.4, Parent = frame })
sInst("UIGradient", { Color = ColorSequence.new(THEME.bg, Color3.fromRGB(25, 22, 35)), Rotation = 90, Parent = frame })

-- ── Title bar ────────────────────────────────────────────
local titleBar = sInst("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundTransparency = 1,
    Parent = frame,
})
local titleGradientFrame = sInst("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = THEME.bgLight,
    BorderSizePixel = 0,
    Parent = frame,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 14), Parent = titleGradientFrame })
sInst("UIGradient", { Color = ColorSequence.new(THEME.bgLight, Color3.fromRGB(45, 40, 60)), Rotation = 90, Parent = titleGradientFrame })

sInst("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.fromOffset(16, 0),
    BackgroundTransparency = 1,
    Text = "⚡ Admin Panel v5",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = titleBar,
})
local closeBtn = sInst("TextButton", {
    Size = UDim2.fromOffset(34, 34),
    Position = UDim2.new(1, -40, 0.5, -17),
    BackgroundColor3 = THEME.red,
    Text = "✕",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Parent = titleBar,
})
sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeBtn })
sInst("UIGradient", { Color = ColorSequence.new(THEME.red, Color3.fromRGB(170, 50, 50)), Rotation = 90, Parent = closeBtn })

-- ── Tab bar ─────────────────────────────────────────────
local tabBar = sInst("Frame", {
    Size = UDim2.new(1, -16, 0, 34),
    Position = UDim2.fromOffset(8, 50),
    BackgroundTransparency = 1,
    Parent = frame,
})
sInst("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 2),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Parent = tabBar,
})

-- ── Content area ────────────────────────────────────────
local contentArea = sInst("Frame", {
    Size = UDim2.new(1, -16, 1, -98),
    Position = UDim2.fromOffset(8, 88),
    BackgroundTransparency = 1,
    Parent = frame,
})

-- ── Command bar ─────────────────────────────────────────
commandBar = sInst("TextBox", {
    Size = UDim2.new(1, -16, 0, 30),
    Position = UDim2.fromOffset(8, 52),
    BackgroundColor3 = THEME.bgLight,
    Text = "",
    PlaceholderText = "  💬 Enter command (help for list)...",
    TextColor3 = THEME.text,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    ClearTextOnFocus = false,
    Parent = frame,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 6), Parent = commandBar })
sInst("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.7, Parent = commandBar })

-- Move content area down to accommodate command bar
contentArea.Position = UDim2.fromOffset(8, 88)

-- ── Resize handle ────────────────────────────────────────
local resizeHandle = sInst("TextButton", {
    Size = UDim2.fromOffset(20, 20),
    Position = UDim2.new(1, -22, 1, -22),
    BackgroundColor3 = THEME.bgLighter,
    Text = "",
    Parent = frame,
})
sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = resizeHandle })
sInst("ImageLabel", {
    Size = UDim2.fromOffset(12, 12),
    Position = UDim2.new(0.5, -6, 0.5, -6),
    BackgroundTransparency = 1,
    Image = "rbxassetid://6953117316",
    ImageColor3 = THEME.textDim,
    Parent = resizeHandle,
})

-- ── Tab system ──────────────────────────────────────────
local function createTab(name, icon)
    local tabBtn = sInst("TextButton", {
        Size = UDim2.new(0.16, 0, 1, 0),
        BackgroundColor3 = THEME.bgLight,
        Text = (icon or "") .. " " .. name,
        TextColor3 = THEME.textDim,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = tabBar,
    })
    sInst("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabBtn })
    local page = sInst("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = THEME.textDim,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = contentArea,
    })
    sInst("UIListLayout", { Padding = UDim.new(0, 8), Parent = page })
    local tabData = { button = tabBtn, page = page, name = name }
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
    trackConn(tabBtn.MouseEnter:Connect(function()
        if activeTab ~= tabData then
            TweenService:Create(tabBtn, TweenInfo.new(0.15), { BackgroundColor3 = THEME.bgLighter }):Play()
        end
    end))
    trackConn(tabBtn.MouseLeave:Connect(function()
        if activeTab ~= tabData then
            TweenService:Create(tabBtn, TweenInfo.new(0.15), { BackgroundColor3 = THEME.bgLight }):Play()
        end
    end))
    return tabData
end

-- ── Section header ──────────────────────────────────────
local function createSectionHeader(parent, text)
    local header = sInst("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = THEME.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })
    sInst("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = THEME.accent,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Parent = header,
    })
    return header
end

-- ── UI helpers ──────────────────────────────────────────
local function createSlider(parent, labelText, min, max, default, callback)
    local row = sInst("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = THEME.bgLight,
        BorderSizePixel = 0,
        Parent = parent,
    })
    sInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
    local label = sInst("TextLabel", {
        Size = UDim2.new(1, -12, 0, 20),
        Position = UDim2.fromOffset(8, 4),
        BackgroundTransparency = 1,
        Text = labelText .. ": " .. tostring(default),
        TextColor3 = THEME.text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local input = sInst("TextBox", {
        Size = UDim2.new(1, -16, 0, 32),
        Position = UDim2.fromOffset(8, 26),
        BackgroundColor3 = THEME.bgLighter,
        Text = tostring(default),
        TextColor3 = THEME.text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        ClearTextOnFocus = false,
        Parent = row,
    })
    sInst("UICorner", { CornerRadius = UDim.new(0, 4), Parent = input })
    sInst("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.7, Parent = input })
    trackConn(input.FocusLost:Connect(function()
        local value = tonumber(input.Text)
        if value then
            value = math.clamp(value, min, max)
            input.Text = tostring(value)
            label.Text = labelText .. ": " .. tostring(value)
            addLog(labelText .. " set to " .. tostring(value), "INFO")
            pcall(callback, value)
        else
            input.Text = tostring(default)
        end
    end))
    return row
end

local function createToggle(parent, labelText, defaultOn, callback)
    local row = sInst("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = THEME.bgLight,
        BorderSizePixel = 0,
        Parent = parent,
    })
    sInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
    sInst("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = THEME.text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local toggleBg = sInst("Frame", {
        Size = UDim2.fromOffset(50, 28),
        Position = UDim2.new(1, -58, 0.5, -14),
        BackgroundColor3 = defaultOn and THEME.green or Color3.fromRGB(60, 60, 70),
        BorderSizePixel = 0,
        Parent = row,
    })
    sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleBg })
    local knob = sInst("Frame", {
        Size = UDim2.fromOffset(22, 22),
        Position = defaultOn and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = toggleBg,
    })
    sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
    sInst("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 0.5, Transparency = 0.5, Parent = knob })
    local state = defaultOn
    local btn = sInst("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row,
    })
    trackConn(btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = state and THEME.green or Color3.fromRGB(60, 60, 70)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        }):Play()
        addLog(labelText .. " -> " .. (state and "ON" or "OFF"), "TOGGLE")
        pcall(callback, state)
    end))
    return row
end

local function createButton(parent, labelText, callback)
    local btn = sInst("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = THEME.accent,
        Text = labelText,
        TextColor3 = THEME.text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = parent,
    })
    sInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
    sInst("UIGradient", { Color = ColorSequence.new(THEME.accent, THEME.accent2), Rotation = 90, Parent = btn })
    sInst("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 0.5, Transparency = 0.8, Parent = btn })
    local debounce = false
    trackConn(btn.MouseButton1Click:Connect(function()
        if debounce then return end
        debounce = true
        TweenService:Create(btn, TweenInfo.new(0.08), { Size = UDim2.new(1, -4, 0, 36), Position = UDim2.new(0, 2, 0, 2) }):Play()
        task.wait(0.08)
        TweenService:Create(btn, TweenInfo.new(0.08), { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 0) }):Play()
        addLog("Button clicked: " .. labelText, "INFO")
        pcall(callback)
        debounce = false
    end))
    trackConn(btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = THEME.accent2 }):Play()
    end))
    trackConn(btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = THEME.accent }):Play()
    end))
    return btn
end

-- ── Create tabs ─────────────────────────────────────────
local playerTab = createTab("Player", "👤")
local moveTab = createTab("Move", "🏃")
local visualTab = createTab("Visual", "👁")
local miscTab = createTab("Misc", "⚙")
local espTab = createTab("ESP", "📍")
local settingsTab = createTab("Settings", "🎨")

-- ── ESP SYSTEM ──────────────────────────────────────────
espGui = sInst("ScreenGui", {
    Name = "APE_" .. tostring(math.random(10000, 99999)),
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    Parent = playerGui,
})

local function createESPForPlayer(targetPlayer)
    if targetPlayer == player then return end
    if espObjects[targetPlayer] then return end
    local billboard = sInst("BillboardGui", {
        Name = "ESP_" .. targetPlayer.Name,
        Size = UDim2.fromOffset(200, 60),
        StudsOffset = Vector3.new(0, 3, 0),
        AlwaysOnTop = true,
        LightInfluence = 0,
    })
    local nameLabel = sInst("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = targetPlayer.Name,
        TextColor3 = espColor,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextStrokeTransparency = 0.5,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        Parent = billboard,
    })
    local healthLabel = sInst("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.fromOffset(0, 20),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(255, 100, 100),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextStrokeTransparency = 0.5,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        Parent = billboard,
    })
    local distLabel = sInst("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.fromOffset(0, 36),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = THEME.textDim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextStrokeTransparency = 0.5,
        TextStrokeColor3 = Color3.new(0, 0, 0),
        Parent = billboard,
    })
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
        if data.billboard then pcall(function() data.billboard:Destroy() end) end
        espObjects[targetPlayer] = nil
    end
    if espTracers[targetPlayer] then
        pcall(function() espTracers[targetPlayer]:Remove() end)
        espTracers[targetPlayer] = nil
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
        for p, _ in pairs(espObjects) do removeESPForPlayer(p) end
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
    -- Tracers
    if espShowTracers and localHrp then
        for targetPlayer, data in pairs(espObjects) do
            local char = targetPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (localHrp.Position - hrp.Position).Magnitude
                if dist <= espMaxDistance then
                    local tracer = espTracers[targetPlayer]
                    if not tracer then
                        tracer = sInst("Frame", {
                            BackgroundColor3 = espColor,
                            BorderSizePixel = 0,
                            Parent = espGui,
                        })
                        espTracers[targetPlayer] = tracer
                    end
                    -- Draw line from screen center to target
                    local cam = Workspace.CurrentCamera
                    local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                    local localScreenPos = cam:WorldToViewportPoint(localHrp.Position)
                    if onScreen then
                        tracer.Visible = true
                        tracer.Size = UDim2.fromOffset(2, 2)
                        tracer.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
                        tracer.BackgroundColor3 = espUseTeamColor and targetPlayer.TeamColor and targetPlayer.TeamColor.Color or espColor
                        tracer.ZIndex = 2
                    else
                        tracer.Visible = false
                    end
                end
            end
        end
    else
        for p, tracer in pairs(espTracers) do
            if tracer then tracer.Visible = false end
        end
    end
end

task.spawn(function()
    while not killed do
        task.wait(0.1)
        pcall(updateESP)
    end
end)

trackConn(Players.PlayerAdded:Connect(function(p)
    addLog("Player joined: " .. p.Name, "INFO")
    if espEnabled then
        trackConn(p.CharacterAdded:Connect(function()
            task.wait(0.5)
            pcall(attachESP, p)
        end))
    end
end))

trackConn(Players.PlayerRemoving:Connect(function(p)
    addLog("Player left: " .. p.Name, "INFO")
    pcall(removeESPForPlayer, p)
end))

trackConn(player.CharacterAdded:Connect(function()
    addLog("Character spawned/respawned", "PLAYER")
    antiFlingLastPos = nil
    -- Re-hook noclip after respawn
    if noclip then
        task.wait(0.5)
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end
    end
end))

-- ESP tab controls
createToggle(espTab.page, "ESP Enabled", false, function(state)
    espEnabled = state
    if state then
        for _, p in ipairs(Players:GetPlayers()) do pcall(attachESP, p) end
        notify("ESP enabled", THEME.green)
        addLog("ESP system enabled", "ESP")
    else
        for p, _ in pairs(espObjects) do pcall(removeESPForPlayer, p) end
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
end)

-- ── PLAYER TAB ──────────────────────────────────────────
createSectionHeader(playerTab.page, "── Stats ──")
createSlider(playerTab.page, "Walk Speed", 1, 500, 16, function(value)
    local hum = getHumanoid()
    if hum then pcall(function() hum.WalkSpeed = value end) end
end)
createSlider(playerTab.page, "Jump Power", 0, 500, 50, function(value)
    local hum = getHumanoid()
    if hum then pcall(function() hum.UseJumpPower = true hum.JumpPower = value end) end
end)
createSlider(playerTab.page, "Jump Height", 0, 100, 7.2, function(value)
    local hum = getHumanoid()
    if hum then pcall(function() hum.UseJumpPower = false hum.JumpHeight = value end) end
end)
createSlider(playerTab.page, "Hip Height", -10, 50, 0, function(value)
    local hum = getHumanoid()
    if hum then pcall(function() hum.HipHeight = value end) end
end)
createSlider(playerTab.page, "Max Health", 1, 9999, 100, function(value)
    local hum = getHumanoid()
    if hum then pcall(function() hum.MaxHealth = value hum.Health = value end) end
end)

createSectionHeader(playerTab.page, "── Actions ──")
createButton(playerTab.page, "🔄 Reset Character", function()
    local hum = getHumanoid()
    if hum then pcall(function() hum.Health = 0 end) notify("Character reset", THEME.red) addLog("Character reset", "PLAYER") end
end)
createButton(playerTab.page, "💚 Heal to Full", function()
    local hum = getHumanoid()
    if hum then pcall(function() hum.Health = hum.MaxHealth end) notify("Healed", THEME.green) addLog("Healed to full", "PLAYER") end
end)
createButton(playerTab.page, "📍 TP to 0,100,0", function()
    local hrp = getHRP()
    if hrp then pcall(function() hrp.CFrame = CFrame.new(0, 100, 0) end) notify("Teleported", THEME.accent) addLog("TP to 0,100,0", "PLAYER") end
end)

createToggle(playerTab.page, "God Mode", false, function(state)
    godMode = state
    if state then
        addLog("God Mode enabled", "PLAYER")
        task.spawn(function()
            while godMode and not killed do
                local hum = getHumanoid()
                if hum and hum.Health < hum.MaxHealth then
                    pcall(function() hum.Health = hum.MaxHealth end)
                end
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
                    if stamina and stamina:IsA("NumberValue") then
                        pcall(function() stamina.Value = stamina.MaxValue or 100 end)
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end)

createToggle(playerTab.page, "Sit", false, function(state)
    local hum = getHumanoid()
    if hum then pcall(function() hum.Sit = state end) end
end)

-- ── Player List (TP to) ──────────────────────────────────
createSectionHeader(playerTab.page, "── Player List (TP to) ──")
local playerListScroll = sInst("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 120),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = THEME.textDim,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = playerTab.page,
})
sInst("UIListLayout", { Padding = UDim.new(0, 4), Parent = playerListScroll })

local function refreshPlayerList()
    for _, child in ipairs(playerListScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local btn = sInst("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = THEME.bgLight,
                Text = "→ " .. p.Name,
                TextColor3 = THEME.text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = playerListScroll,
            })
            sInst("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
            trackConn(btn.MouseButton1Click:Connect(function()
                local targetChar = p.Character
                local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                local myHrp = getHRP()
                if targetHrp and myHrp then
                    pcall(function() myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0) end)
                    notify("TP to " .. p.Name, THEME.accent)
                    addLog("TP to " .. p.Name, "PLAYER")
                end
            end))
        end
    end
end
refreshPlayerList()
trackConn(Players.PlayerAdded:Connect(function() task.wait(1) pcall(refreshPlayerList) end))
trackConn(Players.PlayerRemoving:Connect(function() task.wait(1) pcall(refreshPlayerList) end))

-- ── MOVE TAB ─────────────────────────────────────────────
createSectionHeader(moveTab.page, "── Movement ──")
createToggle(moveTab.page, "Infinite Jump", false, function(state)
    infiniteJump = state
    addLog("Infinite Jump " .. (state and "enabled" or "disabled"), "MOVE")
end)

trackConn(UserInputService.JumpRequest:Connect(function()
    if infiniteJump and not killed then
        local hum = getHumanoid()
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end))

-- Improved noclip with Stepped connection
local noclipConn = nil
local function setNoclip(state)
    noclip = state
    if state then
        notify("Noclip enabled", THEME.green)
        addLog("Noclip enabled", "MOVE")
        noclipConn = RunService.Stepped:Connect(function()
            if not noclip or killed then
                if noclipConn then noclipConn:Disconnect() noclipConn = nil end
                return
            end
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        pcall(function() part.CanCollide = false end)
                    end
                end
            end
        end)
        table.insert(allConnections, noclipConn)
    else
        notify("Noclip disabled", THEME.red)
        addLog("Noclip disabled", "MOVE")
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    pcall(function() part.CanCollide = true end)
                end
            end
        end
    end
end

createToggle(moveTab.page, "Noclip", false, function(state)
    setNoclip(state)
end)

-- Improved fly with BodyVelocity + BodyGyro for smooth flight
createToggle(moveTab.page, "Fly", false, function(state)
    flying = state
    local hrp = getHRP()
    if not hrp then return end
    if state then
        notify("Fly enabled (WASD+Space/Shift)", THEME.green)
        addLog("Fly enabled", "MOVE")
        local bodyVel = sInst("BodyVelocity", {
            Name = "FlyVelocity",
            MaxForce = Vector3.new(1, 1, 1) * 1e9,
            Velocity = Vector3.zero,
            Parent = hrp,
        })
        local bodyGyro = sInst("BodyGyro", {
            Name = "FlyGyro",
            MaxForce = Vector3.new(1, 1, 1) * 1e9,
            CFrame = hrp.CFrame,
            D = 100,
            Parent = hrp,
        })
        flyConn = RunService.RenderStepped:Connect(function()
            if not flying or not hrp or not hrp.Parent then
                if flyConn then flyConn:Disconnect() end
                if bodyVel then pcall(function() bodyVel:Destroy() end) end
                if bodyGyro then pcall(function() bodyGyro:Destroy() end) end
                return
            end
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
            pcall(function()
                bodyVel.Velocity = (move.Magnitude > 0 and move.Unit * flySpeed or Vector3.zero)
                bodyGyro.CFrame = cam.CFrame
            end)
        end)
        table.insert(allConnections, flyConn)
    else
        notify("Fly disabled", THEME.red)
        addLog("Fly disabled", "MOVE")
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if hrp then
            local fv = hrp:FindFirstChild("FlyVelocity")
            if fv then pcall(function() fv:Destroy() end) end
            local fg = hrp:FindFirstChild("FlyGyro")
            if fg then pcall(function() fg:Destroy() end) end
        end
    end
end)

createSlider(moveTab.page, "Fly Speed", 10, 500, 50, function(value) flySpeed = value end)

createToggle(moveTab.page, "Click TP", false, function(state)
    clickTpEnabled = state
    addLog("Click TP " .. (state and "enabled" or "disabled"), "MOVE")
end)

trackConn(UserInputService.InputBegan:Connect(function(input, gP)
    if clickTpEnabled and not killed and not gP then
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local mousePos = UserInputService:GetMouseLocation()
            local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = { player.Character }
            local raycast = Workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
            if raycast then
                local hrp = getHRP()
                if hrp then
                    pcall(function() hrp.CFrame = CFrame.new(raycast.Position + Vector3.new(0, 3, 0)) end)
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
        local spawn = Workspace:FindFirstChild("SpawnLocation")
        if spawn then
            pcall(function() hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0) end)
            notify("TP to spawn", THEME.accent)
        else
            notify("No SpawnLocation", THEME.red)
        end
    end
end)
createButton(moveTab.page, "🚀 Launch Up", function()
    local hrp = getHRP()
    if hrp then pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 200, 0) end) notify("Launched!", THEME.accent2) end
end)
createButton(moveTab.page, "⬆️ TP Forward 50", function()
    local hrp = getHRP()
    local cam = Workspace.CurrentCamera
    if hrp and cam then
        pcall(function() hrp.CFrame = CFrame.new(hrp.Position + cam.CFrame.LookVector * 50) end)
        notify("TP forward 50", THEME.accent)
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
                if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
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
        pcall(function() hum.WalkSpeed = orig * 2 end)
        notify("Speed boost!", THEME.green)
        task.wait(5)
        if hum and hum.Parent then pcall(function() hum.WalkSpeed = orig end) end
        speedBoostActive = false
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
        pcall(function()
            Lighting.Brightness = 3
            Lighting.ClockTime = 12
            Lighting.FogEnd = 1e6
        end)
        notify("Fullbright on", THEME.green)
    else
        pcall(function()
            Lighting.Brightness = originalBrightness
            Lighting.ClockTime = originalClockTime
            Lighting.FogEnd = originalFogEnd
        end)
        notify("Fullbright off", THEME.red)
    end
end)

createToggle(visualTab.page, "Night Vision", false, function(state)
    nightVision = state
    if state then
        if not nvOverlay then
            nvOverlay = sInst("ColorCorrectionEffect", {
                Name = "NightVision",
                Brightness = 0.2,
                Contrast = 0.3,
                TintColor = Color3.fromRGB(100, 255, 100),
                Parent = Lighting,
            })
        end
        pcall(function() Lighting.Brightness = 2 end)
    else
        if nvOverlay then pcall(function() nvOverlay:Destroy() end) nvOverlay = nil end
        if not fullbright then pcall(function() Lighting.Brightness = originalBrightness end) end
    end
end)

createToggle(visualTab.page, "Remove Fog", false, function(state)
    if state then
        originalFogEnd = Lighting.FogEnd
        pcall(function() Lighting.FogEnd = 1e6 end)
    else
        pcall(function() Lighting.FogEnd = originalFogEnd end)
    end
end)

createToggle(visualTab.page, "Disco Mode", false, function(state)
    discoMode = state
    if state then
        task.spawn(function()
            while discoMode and not killed do
                pcall(function()
                    Lighting.Ambient = Color3.fromHSV(math.random(), 1, 1)
                    Lighting.OutdoorAmbient = Color3.fromHSV(math.random(), 1, 1)
                end)
                task.wait(0.1)
            end
        end)
    else
        pcall(function()
            Lighting.Ambient = Color3.fromRGB(128, 128, 128)
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end)
    end
end)

createToggle(visualTab.page, "RGB Ambient Cycle", false, function(state)
    rgbCycle = state
    if state then
        local hue = 0
        rgbConn = RunService.Heartbeat:Connect(function(dt)
            if killed then rgbConn:Disconnect() return end
            hue = (hue + dt * 0.5) % 1
            pcall(function() Lighting.Ambient = Color3.fromHSV(hue, 0.6, 1) end)
        end)
        table.insert(allConnections, rgbConn)
    else
        if rgbConn then rgbConn:Disconnect() rgbConn = nil end
        pcall(function() Lighting.Ambient = Color3.fromRGB(128, 128, 128) end)
    end
end)

createSectionHeader(visualTab.page, "── Camera ──")
createSlider(visualTab.page, "Field of View", 30, 120, 70, function(value)
    local cam = Workspace.CurrentCamera
    if cam then pcall(function() cam.FieldOfView = value end) end
end)
createButton(visualTab.page, "🔍 Toggle Zoom (30/70)", function()
    local cam = Workspace.CurrentCamera
    if cam then
        zoomed = not zoomed
        pcall(function() cam.FieldOfView = zoomed and 30 or 70 end)
        notify("Zoom " .. (zoomed and "ON" or "OFF"), THEME.accent)
    end
end)

createSectionHeader(visualTab.page, "── World ──")
-- Improved X-Ray: only affect nearby parts for performance
createToggle(visualTab.page, "X-Ray Mode", false, function(state)
    xrayEnabled = state
    if state then
        addLog("X-Ray enabled", "VISUAL")
        local hrp = getHRP()
        local range = 500
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsA("Terrain") then
                if not hrp or (obj.Position - hrp.Position).Magnitude <= range then
                    xrayOriginalTransparency[obj] = obj.Transparency
                    pcall(function() obj.Transparency = 0.5 end)
                end
            end
        end
    else
        addLog("X-Ray disabled", "VISUAL")
        for obj, orig in pairs(xrayOriginalTransparency) do
            if obj and obj.Parent then pcall(function() obj.Transparency = orig end) end
        end
        xrayOriginalTransparency = {}
    end
end)

createSlider(visualTab.page, "Time of Day", 0, 24, 12, function(value)
    if not fullbright then pcall(function() Lighting.ClockTime = value end) end
end)

-- ── MISC TAB ────────────────────────────────────────────
createSectionHeader(miscTab.page, "── World ──")
createSlider(miscTab.page, "Gravity", 0, 200, 196.2, function(value)
    pcall(function() Workspace.Gravity = value end)
end)
createSlider(miscTab.page, "Jump Cooldown", 0, 5, 0.2, function(value)
    local hum = getHumanoid()
    if hum then pcall(function() hum.JumpCooldown = value end) end
end)

createSectionHeader(miscTab.page, "── Player ──")
createToggle(miscTab.page, "Auto Respawn", false, function(state)
    autoRespawn = state
end)

task.spawn(function()
    while not killed do
        task.wait(1)
        if autoRespawn then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                pcall(function() player:LoadCharacter() end)
            end
        end
    end
end)

createToggle(miscTab.page, "Freeze Player", false, function(state)
    frozen = state
    local hrp = getHRP()
    if not hrp then return end
    if state then
        local anchor = sInst("BodyVelocity", {
            Name = "FreezeAnchor",
            MaxForce = Vector3.new(1, 1, 1) * 1e9,
            Velocity = Vector3.zero,
            Parent = hrp,
        })
    else
        local existing = hrp:FindFirstChild("FreezeAnchor")
        if existing then pcall(function() existing:Destroy() end) end
    end
end)

createToggle(miscTab.page, "Anti-Fling", false, function(state)
    antiFlingEnabled = state
end)

trackConn(RunService.Heartbeat:Connect(function()
    if not antiFlingEnabled or killed then return end
    local hrp = getHRP()
    if not hrp then return end
    pcall(function()
        local linVel = hrp.AssemblyLinearVelocity
        local angVel = hrp.AssemblyAngularVelocity
        if (linVel and linVel.Magnitude > 250) or (angVel and angVel.Magnitude > 250) then
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            if antiFlingLastPos then pcall(function() hrp.CFrame = antiFlingLastPos end) end
            notify("Anti-Fling: velocity neutralized", THEME.red)
        elseif linVel and linVel.Magnitude < 50 then
            antiFlingLastPos = hrp.CFrame
        end
    end)
end))

createSectionHeader(miscTab.page, "── Info ──")
local infoLabel = sInst("TextLabel", {
    Size = UDim2.new(1, 0, 0, 80),
    BackgroundTransparency = 1,
    Text = "⚡ button (left-center) — toggle panel\nP — unlock mouse | J/B — toggle panel\nL — toggle action log\nCommand bar at top — type 'help'\n6 tabs: Player, Move, Visual, ESP, Misc, Settings",
    TextColor3 = THEME.textDim,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextWrapped = true,
    Parent = miscTab.page,
})

createButton(miscTab.page, "📋 Toggle Action Log", function() toggleLogWindow() end)
createButton(miscTab.page, "📋 Copy Position", function()
    local hrp = getHRP()
    if hrp then
        local pos = hrp.Position
        local text = string.format("%.2f, %.2f, %.2f", pos.X, pos.Y, pos.Z)
        if setclipboard then pcall(setclipboard, text) notify("Copied: " .. text, THEME.green) else notify("Pos: " .. text, THEME.accent) end
    end
end)

local serverInfoLabel = sInst("TextLabel", {
    Size = UDim2.new(1, 0, 0, 70),
    BackgroundColor3 = THEME.bgLight,
    BorderSizePixel = 0,
    Text = "Loading...",
    TextColor3 = THEME.text,
    Font = Enum.Font.Code,
    TextSize = 11,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Parent = miscTab.page,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 6), Parent = serverInfoLabel })
sInst("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), Parent = serverInfoLabel })

task.spawn(function()
    while not killed do
        task.wait(1)
        local ping = 0
        pcall(function() ping = player:GetNetworkPing() * 1000 end)
        serverInfoLabel.Text = string.format(
            "Players: %d\nPing: %.0f ms\nFPS: %d\nJobId: %s",
            #Players:GetPlayers(), ping, currentFps, game.JobId or "N/A"
        )
    end
end)

createSectionHeader(miscTab.page, "── Server ──")
createButton(miscTab.page, "🚪 Leave Game", function()
    pcall(function() Players.LocalPlayer:Kick("Left via Admin Panel") end)
end)
createButton(miscTab.page, "🔄 Rejoin", function()
    pcall(function()
        if game.JobId and game.JobId ~= "" then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        else
            TeleportService:Teleport(game.PlaceId, player)
        end
    end)
end)
createButton(miscTab.page, "🔀 Server Hop", function()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end)

-- ── SETTINGS TAB ────────────────────────────────────────
createToggle(settingsTab.page, "Show Stats HUD", true, function(state)
    showStats = state
    notify("Stats HUD " .. (state and "on" or "off"), state and THEME.green or THEME.red)
end)

createSlider(settingsTab.page, "Text Size", 8, 20, 13, function(value)
    for _, child in ipairs(screenGui:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            if child.Name ~= "Title" and child.Name ~= "CloseButton" then
                pcall(function() child.TextSize = value end)
            end
        end
    end
end)

local function updateAccent()
    for _, t in ipairs(tabs) do
        if t.page.Visible then pcall(function() t.button.BackgroundColor3 = THEME.accent end) end
    end
    pcall(function() frameStroke.Color = THEME.accent end)
end

createSlider(settingsTab.page, "Accent R", 0, 255, 100, function(value)
    THEME.accent = Color3.fromRGB(value, math.floor(THEME.accent.G * 255), math.floor(THEME.accent.B * 255))
    updateAccent()
end)
createSlider(settingsTab.page, "Accent G", 0, 255, 150, function(value)
    THEME.accent = Color3.fromRGB(math.floor(THEME.accent.R * 255), value, math.floor(THEME.accent.B * 255))
    updateAccent()
end)
createSlider(settingsTab.page, "Accent B", 0, 255, 255, function(value)
    THEME.accent = Color3.fromRGB(math.floor(THEME.accent.R * 255), math.floor(THEME.accent.G * 255), value)
    updateAccent()
end)

createSlider(settingsTab.page, "Panel Opacity", 0, 100, 85, function(value)
    pcall(function() frame.BackgroundTransparency = 1 - (value / 100) end)
end)
createSlider(settingsTab.page, "Stats Opacity", 0, 100, 85, function(value)
    pcall(function() statsLabel.BackgroundTransparency = 1 - (value / 100) end)
end)
createSlider(settingsTab.page, "Notif Duration (s)", 1, 10, 3, function(value)
    notifDuration = value
end)

createButton(settingsTab.page, "🔄 Reset All Features", function()
    flying = false
    local hrp = getHRP()
    if hrp then
        if flyConn then flyConn:Disconnect() flyConn = nil end
        local fv = hrp:FindFirstChild("FlyVelocity")
        if fv then pcall(function() fv:Destroy() end) end
        local fg = hrp:FindFirstChild("FlyGyro")
        if fg then pcall(function() fg:Destroy() end) end
    end
    setNoclip(false)
    noclip = false
    fullbright = false
    pcall(function()
        Lighting.Brightness = originalBrightness
        Lighting.ClockTime = originalClockTime
        Lighting.FogEnd = originalFogEnd
    end)
    nightVision = false
    if nvOverlay then pcall(function() nvOverlay:Destroy() end) nvOverlay = nil end
    discoMode = false
    rgbCycle = false
    if rgbConn then rgbConn:Disconnect() rgbConn = nil end
    pcall(function()
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end)
    espEnabled = false
    for p, _ in pairs(espObjects) do pcall(removeESPForPlayer, p) end
    infiniteJump = false
    godMode = false
    autoRespawn = false
    frozen = false
    infiniteStamina = false
    clickTpEnabled = false
    antiFlingEnabled = false
    xrayEnabled = false
    for obj, orig in pairs(xrayOriginalTransparency) do
        if obj and obj.Parent then pcall(function() obj.Transparency = orig end) end
    end
    xrayOriginalTransparency = {}
    if hrp then
        local fa = hrp:FindFirstChild("FreezeAnchor")
        if fa then pcall(function() fa:Destroy() end) end
    end
    pcall(function() Workspace.Gravity = 196.2 end)
    local cam = Workspace.CurrentCamera
    if cam then pcall(function() cam.FieldOfView = 70 end) end
    notify("All features reset!", THEME.red)
    addLog("All features reset", "WARN")
end)

createSectionHeader(settingsTab.page, "── ⚠ Danger Zone ──")
local killBtn = sInst("TextButton", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Color3.fromRGB(80, 20, 20),
    Text = "💀 KILL SCRIPT (Remove Everything)",
    TextColor3 = Color3.fromRGB(255, 100, 100),
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    Parent = settingsTab.page,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = killBtn })
sInst("UIStroke", { Color = THEME.red, Thickness = 1.5, Parent = killBtn })
trackConn(killBtn.MouseEnter:Connect(function()
    TweenService:Create(killBtn, TweenInfo.new(0.15), { BackgroundColor3 = THEME.red }):Play()
end))
trackConn(killBtn.MouseLeave:Connect(function()
    TweenService:Create(killBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(80, 20, 20) }):Play()
end))
trackConn(killBtn.MouseButton1Click:Connect(function()
    killed = true
    for _, conn in ipairs(allConnections) do
        pcall(function() conn:Disconnect() end)
    end
    allConnections = {}
    flying = false noclip = false godMode = false infiniteJump = false
    espEnabled = false autoRespawn = false discoMode = false
    rgbCycle = false antiFlingEnabled = false clickTpEnabled = false
    fullbright = false nightVision = false xrayEnabled = false
    if flyConn then pcall(function() flyConn:Disconnect() end) flyConn = nil end
    if afkConn then pcall(function() afkConn:Disconnect() end) afkConn = nil end
    if rgbConn then pcall(function() rgbConn:Disconnect() end) rgbConn = nil end
    if noclipConn then pcall(function() noclipConn:Disconnect() end) noclipConn = nil end
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
    for p, _ in pairs(espObjects) do pcall(removeESPForPlayer, p) end
    local hrp = getHRP()
    if hrp then
        local fv = hrp:FindFirstChild("FlyVelocity")
        if fv then pcall(function() fv:Destroy() end) end
        local fg = hrp:FindFirstChild("FlyGyro")
        if fg then pcall(function() fg:Destroy() end) end
        local fa = hrp:FindFirstChild("FreezeAnchor")
        if fa then pcall(function() fa:Destroy() end) end
    end
    pcall(function() Workspace.Gravity = 196.2 end)
    pcall(function() if screenGui then screenGui:Destroy() end end)
    pcall(function() if notifGui then notifGui:Destroy() end end)
    pcall(function() if logGui then logGui:Destroy() end end)
    pcall(function() if statsGui then statsGui:Destroy() end end)
    pcall(function() if espGui then espGui:Destroy() end end)
    pcall(function() if toggleBtnGui then toggleBtnGui:Destroy() end end)
    pcall(function() if loadingGui then loadingGui:Destroy() end end)
    print("[AdminPanel v5] Script killed. All GUIs destroyed, all connections disconnected.")
end))

-- ── Command bar handler ──────────────────────────────────
local commands = {
    help = function()
        notify("Commands: speed <n>, jump <n>, tp <x y z>, fly, noclip, god, esp, reset, kill, gravity <n>, fov <n>, fullbright", THEME.accent)
        addLog("Help shown", "CMD")
    end,
    speed = function(args)
        local v = tonumber(args[1])
        if v then
            local hum = getHumanoid()
            if hum then pcall(function() hum.WalkSpeed = v end) notify("Speed: " .. v, THEME.green) end
        end
    end,
    jump = function(args)
        local v = tonumber(args[1])
        if v then
            local hum = getHumanoid()
            if hum then pcall(function() hum.UseJumpPower = true hum.JumpPower = v end) notify("Jump: " .. v, THEME.green) end
        end
    end,
    tp = function(args)
        local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
        if x and y and z then
            local hrp = getHRP()
            if hrp then pcall(function() hrp.CFrame = CFrame.new(x, y, z) end) notify("TP to " .. x .. "," .. y .. "," .. z, THEME.accent) end
        end
    end,
    fly = function()
        notify("Use Fly toggle in Move tab", THEME.orange)
    end,
    noclip = function()
        setNoclip(not noclip)
    end,
    god = function()
        godMode = not godMode
        if godMode then
            task.spawn(function()
                while godMode and not killed do
                    local hum = getHumanoid()
                    if hum and hum.Health < hum.MaxHealth then pcall(function() hum.Health = hum.MaxHealth end) end
                    task.wait(0.1)
                end
            end)
        end
        notify("God Mode " .. (godMode and "ON" or "OFF"), godMode and THEME.green or THEME.red)
    end,
    esp = function()
        espEnabled = not espEnabled
        if espEnabled then
            for _, p in ipairs(Players:GetPlayers()) do pcall(attachESP, p) end
        else
            for p, _ in pairs(espObjects) do pcall(removeESPForPlayer, p) end
        end
        notify("ESP " .. (espEnabled and "ON" or "OFF"), espEnabled and THEME.green or THEME.red)
    end,
    reset = function()
        local hum = getHumanoid()
        if hum then pcall(function() hum.Health = 0 end) notify("Reset", THEME.red) end
    end,
    gravity = function(args)
        local v = tonumber(args[1])
        if v then pcall(function() Workspace.Gravity = v end) notify("Gravity: " .. v, THEME.green) end
    end,
    fov = function(args)
        local v = tonumber(args[1])
        if v then
            local cam = Workspace.CurrentCamera
            if cam then pcall(function() cam.FieldOfView = v end) notify("FOV: " .. v, THEME.green) end
        end
    end,
    fullbright = function()
        fullbright = not fullbright
        if fullbright then
            originalBrightness = Lighting.Brightness
            originalClockTime = Lighting.ClockTime
            originalFogEnd = Lighting.FogEnd
            pcall(function() Lighting.Brightness = 3 Lighting.ClockTime = 12 Lighting.FogEnd = 1e6 end)
        else
            pcall(function() Lighting.Brightness = originalBrightness Lighting.ClockTime = originalClockTime Lighting.FogEnd = originalFogEnd end)
        end
        notify("Fullbright " .. (fullbright and "ON" or "OFF"), fullbright and THEME.green or THEME.red)
    end,
}

trackConn(commandBar.FocusLost:Connect(function(enterPressed)
    if enterPressed and commandBar.Text ~= "" then
        local text = commandBar.Text:lower()
        local parts = {}
        for word in text:gmatch("%S+") do table.insert(parts, word) end
        local cmd = table.remove(parts, 1)
        if commands[cmd] then
            addLog("Command: " .. text, "CMD")
            pcall(commands[cmd], parts)
        else
            notify("Unknown command: " .. cmd .. " (try 'help')", THEME.red)
        end
        commandBar.Text = ""
    end
end))

-- ── Chat commands ──────────────────────────────────────
pcall(function()
    chatConn = player.Chatted:Connect(function(msg)
        if msg:sub(1, 1) == "/" then
            local text = msg:sub(2):lower()
            local parts = {}
            for word in text:gmatch("%S+") do table.insert(parts, word) end
            local cmd = table.remove(parts, 1)
            if commands[cmd] then
                addLog("Chat command: " .. text, "CMD")
                pcall(commands[cmd], parts)
            end
        end
    end)
    table.insert(allConnections, chatConn)
end)

-- ── Activate first tab ──────────────────────────────────
if #tabs > 0 then
    tabs[1].button.BackgroundColor3 = THEME.accent
    tabs[1].button.TextColor3 = THEME.text
    tabs[1].page.Visible = true
    activeTab = tabs[1]
end

-- ── Floating toggle button ──────────────────────────────
toggleBtnGui = sInst("ScreenGui", {
    Name = "APT_" .. tostring(math.random(10000, 99999)),
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    Parent = playerGui,
})
local toggleBtn = sInst("TextButton", {
    Size = UDim2.fromOffset(52, 52),
    Position = UDim2.new(0, 8, 0.5, -26),
    BackgroundColor3 = THEME.accent,
    BackgroundTransparency = 0.1,
    Text = "⚡",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 24,
    AutoButtonColor = false,
    Parent = toggleBtnGui,
})
sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleBtn })
sInst("UIGradient", { Color = ColorSequence.new(THEME.accent, THEME.accent2), Rotation = 90, Parent = toggleBtn })
sInst("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.6, Parent = toggleBtn })

-- Pulse animation
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
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(340, 440)
    local w = math.min(vp.X * 0.9, 340)
    return UDim2.fromOffset(w, 440)
end

local function updateShadow()
    pcall(function()
        shadow.Size = UDim2.new(0, frame.Size.X.Offset + 20, 0, frame.Size.Y.Offset + 20)
        shadow.Position = frame.Position
    end)
end

local function openPanel()
    if panelAnimating or killed then return end
    panelAnimating = true
    screenGui.Enabled = true
    toggleBtn.Visible = false
    frame.Size = UDim2.fromOffset(0, 0)
    updateShadow()
    shadow.ImageTransparency = 1
    TweenService:Create(shadow, TweenInfo.new(0.3), { ImageTransparency = 0.4 }):Play()
    local tween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = getPanelSize()
    })
    tween:Play()
    trackConn(tween.Completed:Connect(function()
        panelAnimating = false
        updateShadow()
    end))
    notify("Admin Panel opened", THEME.accent)
end

local function closePanel()
    if panelAnimating or killed then return end
    panelAnimating = true
    TweenService:Create(shadow, TweenInfo.new(0.25), { ImageTransparency = 1 }):Play()
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
end

trackConn(closeBtn.MouseButton1Click:Connect(function() closePanel() end))
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
        pcall(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
    end
    if input.KeyCode == Enum.KeyCode.L then
        toggleLogWindow()
    end
    -- Quick keybinds
    if input.KeyCode == Enum.KeyCode.RightShift then
        setNoclip(not noclip)
    end
    if input.KeyCode == Enum.KeyCode.F then
        if not UserInputService:GetFocusedTextBox() then
            -- Quick fly toggle via F key
        end
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
        pcall(function()
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            updateShadow()
        end)
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
        pcall(function()
            frame.Size = UDim2.fromOffset(newW, newH)
            updateShadow()
        end)
    end
end))

-- ── LOADING SCREEN ──────────────────────────────────────
loadingGui = sInst("ScreenGui", {
    Name = "APLD_" .. tostring(math.random(10000, 99999)),
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    Parent = playerGui,
})
local loadBg = sInst("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(10, 10, 18),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Parent = loadingGui,
})
sInst("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(15, 10, 30), Color3.fromRGB(10, 15, 25)), Rotation = 90, Parent = loadBg })

-- Particles
local particles = {}
for i = 1, 25 do
    local p = sInst("Frame", {
        Size = UDim2.fromOffset(math.random(4, 10), math.random(4, 10)),
        Position = UDim2.new(math.random(), 0, math.random(), 0),
        BackgroundColor3 = Color3.fromHSV(math.random() / 2 + 0.3, 0.6, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = loadBg,
    })
    sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = p })
    particles[i] = { frame = p, velX = (math.random() - 0.5) * 200, velY = (math.random() - 0.5) * 200, rot = math.random(0, 360) }
end

local loadCard = sInst("Frame", {
    Size = UDim2.fromOffset(360, 220),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = THEME.bg,
    BorderSizePixel = 0,
    Parent = loadBg,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 16), Parent = loadCard })
sInst("UIStroke", { Color = THEME.accent, Thickness = 1.5, Transparency = 0.5, Parent = loadCard })
sInst("UIGradient", { Color = ColorSequence.new(THEME.bg, Color3.fromRGB(30, 25, 40)), Rotation = 90, Parent = loadCard })

local ring = sInst("Frame", {
    Size = UDim2.fromOffset(80, 80),
    Position = UDim2.new(0.5, 0, 0, 30),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundTransparency = 1,
    Parent = loadCard,
})
local ringStroke = sInst("UIStroke", { Color = THEME.accent, Thickness = 3, Transparency = 0.3, Parent = ring })
sInst("UIGradient", { Color = ColorSequence.new(THEME.accent, THEME.accent2), Parent = ringStroke })

sInst("TextLabel", {
    Size = UDim2.fromOffset(50, 50),
    Position = UDim2.new(0.5, 0, 0, 45),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundTransparency = 1,
    Text = "⚡",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 36,
    Parent = loadCard,
})

local loadTitle = sInst("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 120),
    BackgroundTransparency = 1,
    Text = "Admin Panel v5",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    Parent = loadCard,
})
sInst("UIGradient", { Color = ColorSequence.new(THEME.accent, THEME.accent2), Parent = loadTitle })

local loadStatus = sInst("TextLabel", {
    Size = UDim2.new(1, -20, 0, 18),
    Position = UDim2.new(0, 10, 0, 155),
    BackgroundTransparency = 1,
    Text = "Initializing...",
    TextColor3 = THEME.textDim,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    Parent = loadCard,
})

local loadBarBg = sInst("Frame", {
    Size = UDim2.new(1, -40, 0, 8),
    Position = UDim2.new(0, 20, 0, 180),
    BackgroundColor3 = THEME.bgLight,
    BorderSizePixel = 0,
    Parent = loadCard,
})
sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = loadBarBg })

local loadBar = sInst("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = THEME.accent,
    BorderSizePixel = 0,
    Parent = loadBarBg,
})
sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = loadBar })
sInst("UIGradient", { Color = ColorSequence.new(THEME.accent, THEME.accent2), Parent = loadBar })

local loadPercent = sInst("TextLabel", {
    Size = UDim2.new(1, -20, 0, 16),
    Position = UDim2.new(0, 10, 0, 195),
    BackgroundTransparency = 1,
    Text = "0%",
    TextColor3 = THEME.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Parent = loadCard,
})

-- ── Loading animation ──────────────────────────────────
local loadingSteps = {
    "Initializing core systems...",
    "Loading UI components...",
    "Setting up tabs...",
    "Configuring ESP & tracers...",
    "Building interface...",
    "Applying animations...",
    "Setting up command bar...",
    "Finalizing...",
}

task.spawn(function()
    pcall(function()
        loadCard.Size = UDim2.fromOffset(0, 0)
        TweenService:Create(loadBg, TweenInfo.new(0.6), { BackgroundTransparency = 0 }):Play()
        task.wait(0.3)
        TweenService:Create(loadCard, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(360, 220)
        }):Play()
        task.wait(0.3)

        -- Animate particles
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
                        TweenService:Create(p.frame, TweenInfo.new(0.5), { BackgroundTransparency = 0.7 }):Play()
                    end
                end
                task.wait(0.03)
            end
        end)

        -- Spin ring
        task.spawn(function()
            while not killed and loadingGui.Parent do
                ring.Rotation = ring.Rotation + 3
                task.wait(0.01)
            end
        end)

        -- Progress
        for i, step in ipairs(loadingSteps) do
            if killed then return end
            loadStatus.Text = step
            local pct = (i / #loadingSteps) * 100
            TweenService:Create(loadBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
                Size = UDim2.new(pct / 100, 0, 1, 0)
            }):Play()
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
        task.wait(0.5)

        -- Fade out
        TweenService:Create(loadCard, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(0, 0)
        }):Play()
        for _, p in ipairs(particles) do
            if p.frame then TweenService:Create(p.frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play() end
        end
        TweenService:Create(loadBg, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
        task.wait(0.6)
        if loadingGui and loadingGui.Parent then loadingGui:Destroy() end
    end)
end)

addLog("Admin Panel v5 loaded successfully", "INFO")
print("[AdminPanel v5] Loaded successfully! Press J or click ⚡ to open.")
