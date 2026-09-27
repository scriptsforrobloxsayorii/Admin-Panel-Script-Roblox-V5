local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local safeParent
pcall(function() safeParent = CoreGui end)
if not safeParent then safeParent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local player = Players.LocalPlayer
local playerGui = safeParent

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
local godModeConn = nil
local autoRespawn = false
local autoRespawnConn = nil
local frozen = false
local espMaxDistance = 9999
local espUseTeamColor = false
local espShowTracers = false
local espEnabled = false
local espShowName = true
local espShowHealth = true
local espShowDistance = true
local espShowBox = false
local espColor = Color3.fromRGB(100, 255, 100)
local espObjects = {}
local espTracers = {}
local espBoxes = {}
local infiniteJump = false
local infiniteJumpConn = nil
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
local infiniteStaminaConn = nil
local clickTpEnabled = false
local clickTpConn = nil
local antiFlingEnabled = false
local antiFlingLastPos = nil
local antiFlingConn = nil
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
local rainbowCharacter = false
local rainbowConn = nil
local antiFallEnabled = false
local antiFallConn = nil
local spiderEnabled = false
local spiderConn = nil
local walkSpeed = 16
local jumpPower = 50

local THEME = {
	bg = Color3.fromRGB(20, 20, 28),
	bgLight = Color3.fromRGB(35, 35, 45),
	bgLighter = Color3.fromRGB(50, 50, 62),
	accent = Color3.fromRGB(100, 150, 255),
	accent2 = Color3.fromRGB(150, 100, 255),
	text = Color3.fromRGB(235, 235, 240),
	textDim = Color3.fromRGB(150, 150, 165),
	green = Color3.fromRGB(60, 180, 90),
	red = Color3.fromRGB(220, 60, 60),
	orange = Color3.fromRGB(255, 160, 50),
	yellow = Color3.fromRGB(255, 220, 80),
}

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
	if killed then
		pcall(function() conn:Disconnect() end)
		return nil
	end
	table.insert(allConnections, conn)
	return conn
end

-- ===== NOTIFICATIONS =====
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
sInst("UISizeConstraint", { MaxSize = Vector2.new(300, math.huge), Parent = notifContainer })
sInst("UIListLayout", { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Top, Parent = notifContainer })

local function notify(text, color)
	if killed then return end
	color = color or THEME.accent
	local notif = sInst("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = THEME.bgLight,
		BorderSizePixel = 0,
		Parent = notifContainer,
	})
	sInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = notif })
	sInst("UIStroke", { Color = color, Thickness = 1, Transparency = 0.5, Parent = notif })
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
	local notifStroke = notif:FindFirstChild("UIStroke")
	if notifStroke then notifStroke.Transparency = 1 end
	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 0,
	}):Play()
	TweenService:Create(accentBar, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	if notifStroke then
		TweenService:Create(notifStroke, TweenInfo.new(0.3), { Transparency = 0.5 }):Play()
	end
	task.delay(notifDuration, function()
		if killed then return end
		TweenService:Create(notif, TweenInfo.new(0.3), { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }):Play()
		TweenService:Create(accentBar, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		if notifStroke then
			TweenService:Create(notifStroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		end
		task.wait(0.35)
		if notif and notif.Parent then notif:Destroy() end
	end)
end

-- ===== LOG =====
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

local logTitleBar = sInst("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = logFrame })
sInst("TextLabel", {
	Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1,
	Text = "Action Log", TextColor3 = THEME.text, Font = Enum.Font.GothamBold, TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left, Parent = logTitleBar,
})
local logCloseBtn = sInst("TextButton", {
	Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -35, 0.5, -15),
	BackgroundColor3 = THEME.red, Text = "X", TextColor3 = THEME.text,
	Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, Parent = logTitleBar,
})
sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = logCloseBtn })
local logClearBtn = sInst("TextButton", {
	Size = UDim2.fromOffset(60, 24), Position = UDim2.new(1, -100, 0.5, -12),
	BackgroundColor3 = THEME.bgLight, Text = "Clear", TextColor3 = THEME.text,
	Font = Enum.Font.Gotham, TextSize = 11, AutoButtonColor = false, Parent = logTitleBar,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 4), Parent = logClearBtn })

local logScroll = sInst("ScrollingFrame", {
	Size = UDim2.new(1, -12, 1, -48), Position = UDim2.fromOffset(6, 42),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.textDim, CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = logFrame,
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
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, Text = entryText, TextColor3 = THEME.textDim,
		Font = Enum.Font.Code, TextSize = 11, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Parent = logScroll,
	})
	local catColors = {
		PANEL = THEME.accent, TOGGLE = THEME.green, WARN = THEME.orange,
		ERROR = THEME.red, PLAYER = Color3.fromRGB(255, 150, 200),
		MOVE = Color3.fromRGB(150, 255, 200), VISUAL = Color3.fromRGB(200, 150, 255),
		ESP = Color3.fromRGB(255, 255, 100), MISC = Color3.fromRGB(150, 200, 255),
		SETTINGS = Color3.fromRGB(255, 200, 150), CMD = Color3.fromRGB(100, 255, 200),
	}
	if catColors[category] then entryLabel.TextColor3 = catColors[category] end
	task.defer(function() logScroll.CanvasPosition = Vector2.new(0, logScroll.CanvasSize.Y.Offset) end)
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

-- ===== STATS =====
statsGui = sInst("ScreenGui", {
	Name = "APS_" .. tostring(math.random(10000, 99999)),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = playerGui,
})
local statsLabel = sInst("TextLabel", {
	Size = UDim2.fromOffset(180, 90),
	Position = UDim2.new(0, 10, 0.5, 34),
	BackgroundColor3 = THEME.bg,
	BackgroundTransparency = 0.15,
	Text = "",
	TextColor3 = THEME.text,
	Font = Enum.Font.Code,
	TextSize = 11,
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
			local pingVal = 0
			pcall(function() pingVal = player:GetNetworkPing() * 1000 end)
			statsLabel.Text = string.format(
				"Player: %s\nFPS: %d  Ping: %d ms\nPos: %s\nHP: %s | Speed: %s",
				player.Name, currentFps, math.floor(pingVal), posStr, healthStr, speedStr
			)
		else
			statsLabel.Visible = false
		end
	end
end)

-- ===== ESP GUI =====
espGui = sInst("ScreenGui", {
	Name = "APE_" .. tostring(math.random(10000, 99999)),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Enabled = false,
	Parent = playerGui,
})

-- ===== MAIN PANEL =====
screenGui = sInst("ScreenGui", {
	Name = "APM_" .. tostring(math.random(10000, 99999)),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Enabled = false,
	Parent = playerGui,
})

local shadow = sInst("ImageLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
	Image = "rbxassetid://1316045217", ImageColor3 = Color3.new(0, 0, 0),
	ImageTransparency = 0.4, ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(10, 10, 118, 118), Parent = screenGui,
})

local frame = sInst("Frame", {
	Size = UDim2.fromOffset(280, 360),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.bg, BorderSizePixel = 0, Parent = screenGui,
})
sInst("UISizeConstraint", { MinSize = Vector2.new(220, 280), MaxSize = Vector2.new(600, 800), Parent = frame })
sInst("UICorner", { CornerRadius = UDim.new(0, 14), Parent = frame })
local frameStroke = sInst("UIStroke", { Color = THEME.accent, Thickness = 1.5, Transparency = 0.4, Parent = frame })
sInst("UIGradient", { Color = ColorSequence.new(THEME.bg, Color3.fromRGB(25, 22, 35)), Rotation = 90, Parent = frame })

local titleGradientFrame = sInst("Frame", {
	Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = THEME.bgLight, BorderSizePixel = 0, Parent = frame,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 14), Parent = titleGradientFrame })
sInst("UIGradient", { Color = ColorSequence.new(THEME.bgLight, Color3.fromRGB(45, 40, 60)), Rotation = 90, Parent = titleGradientFrame })

local titleBar = sInst("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Parent = frame })

sInst("TextLabel", {
	Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1,
	Text = "Admin Panel v6", TextColor3 = THEME.text, Font = Enum.Font.GothamBold, TextSize = 17,
	TextXAlignment = Enum.TextXAlignment.Left, Parent = titleBar,
})
local minimizeBtn = sInst("TextButton", {
	Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -80, 0.5, -17),
	BackgroundColor3 = THEME.bgLighter, Text = "-", TextColor3 = THEME.text,
	Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false, Parent = titleBar,
})
sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = minimizeBtn })
sInst("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.5, Parent = minimizeBtn })

local closeBtn = sInst("TextButton", {
	Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -40, 0.5, -17),
	BackgroundColor3 = THEME.red, Text = "X", TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, Parent = titleBar,
})
sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeBtn })
sInst("UIGradient", { Color = ColorSequence.new(THEME.red, Color3.fromRGB(180, 40, 40)), Rotation = 90, Parent = closeBtn })
sInst("UIStroke", { Color = Color3.fromRGB(255, 100, 100), Thickness = 1, Transparency = 0.3, Parent = closeBtn })

local tabBar = sInst("Frame", {
	Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 50), BackgroundTransparency = 1, Parent = frame,
})
sInst("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2),
	HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = tabBar,
})

local commandBar = sInst("TextBox", {
	Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 84),
	BackgroundColor3 = THEME.bgLight, Text = "", PlaceholderText = "  Enter command (type 'help')...",
	TextColor3 = THEME.text, Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, Parent = frame,
})
sInst("UICorner", { CornerRadius = UDim.new(0, 6), Parent = commandBar })
sInst("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.7, Parent = commandBar })

local contentArea = sInst("Frame", {
	Size = UDim2.new(1, -16, 1, -120), Position = UDim2.fromOffset(8, 118),
	BackgroundTransparency = 1, Parent = frame,
})

local resizeHandle = sInst("TextButton", {
	Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -22, 1, -22),
	BackgroundColor3 = THEME.bgLighter, Text = "", AutoButtonColor = false, Parent = frame,
})
sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = resizeHandle })
sInst("ImageLabel", {
	Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0.5, -6, 0.5, -6), BackgroundTransparency = 1,
	Image = "rbxassetid://6953117316", ImageColor3 = THEME.textDim, Parent = resizeHandle,
})

-- ===== DRAG =====
local function enableDrag(draggableFrame, handle)
	trackConn(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = UserInputService:GetMouseLocation()
			local framePos = draggableFrame.AbsolutePosition
			local frameSize = draggableFrame.AbsoluteSize
			if mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X
			and mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y then
				local handlePos = handle.AbsolutePosition
				local handleSize = handle.AbsoluteSize
				if mousePos.X >= handlePos.X and mousePos.X <= handlePos.X + handleSize.X
				and mousePos.Y >= handlePos.Y and mousePos.Y <= handlePos.Y + handleSize.Y then
					dragging = true
					dragStart = Vector2.new(input.Position.X, input.Position.Y)
					startPos = draggableFrame.Position
				end
			end
		end
	end))
	trackConn(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			draggableFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			if shadow then
				shadow.Position = draggableFrame.Position
			end
		end
	end))
	trackConn(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

-- ===== RESIZE =====
trackConn(resizeHandle.MouseButton1Down:Connect(function()
	resizing = true
	resizeStart = UserInputService:GetMouseLocation()
	resizeStartSize = frame.Size
end))
trackConn(UserInputService.InputChanged:Connect(function(input)
	if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = UserInputService:GetMouseLocation() - resizeStart
		local newW = math.clamp(resizeStartSize.X.Offset + delta.X, 220, 600)
		local newH = math.clamp(resizeStartSize.Y.Offset + delta.Y, 280, 800)
		frame.Size = UDim2.fromOffset(newW, newH)
		shadow.Size = frame.Size
	end
end))
trackConn(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = false
	end
end))

-- ===== SHADOW SYNC =====
local function syncShadow()
	shadow.Size = frame.Size
	shadow.Position = frame.Position
end
syncShadow()

-- ===== TABS =====
local function createTab(name, icon)
	local tabBtn = sInst("TextButton", {
		Size = UDim2.new(0.18, 0, 1, 0), BackgroundColor3 = THEME.bgLight,
		Text = (icon or "") .. " " .. name, TextColor3 = THEME.textDim,
		Font = Enum.Font.GothamMedium, TextSize = 10, AutoButtonColor = false, Parent = tabBar,
	})
	sInst("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabBtn })
	local page = sInst("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.textDim,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false, Parent = contentArea,
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

local function createSectionHeader(parent, text)
	local header = sInst("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
		Text = text, TextColor3 = THEME.accent, Font = Enum.Font.GothamBold, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = parent,
	})
	sInst("Frame", {
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = THEME.accent, BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = header,
	})
	return header
end

local function createSlider(parent, labelText, min, max, default, callback)
	local row = sInst("Frame", {
		Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = THEME.bgLight, BorderSizePixel = 0, Parent = parent,
	})
	sInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
	local label = sInst("TextLabel", {
		Size = UDim2.new(1, -12, 0, 20), Position = UDim2.fromOffset(8, 4), BackgroundTransparency = 1,
		Text = labelText .. ": " .. tostring(default), TextColor3 = THEME.text, Font = Enum.Font.Gotham,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
	})
	local input = sInst("TextBox", {
		Size = UDim2.new(1, -16, 0, 32), Position = UDim2.fromOffset(8, 26), BackgroundColor3 = THEME.bgLighter,
		Text = tostring(default), TextColor3 = THEME.text, Font = Enum.Font.Gotham, TextSize = 13,
		ClearTextOnFocus = false, Parent = row,
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
		Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = THEME.bgLight, BorderSizePixel = 0, Parent = parent,
	})
	sInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
	local label = sInst("TextLabel", {
		Size = UDim2.new(1, -56, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1,
		Text = labelText, TextColor3 = THEME.text, Font = Enum.Font.Gotham, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
	})
	local toggleBtn = sInst("TextButton", {
		Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -50, 0.5, -12),
		BackgroundColor3 = defaultOn and THEME.green or THEME.bgLighter, Text = "",
		AutoButtonColor = false, Parent = row,
	})
	sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = toggleBtn })
	local knob = sInst("Frame", {
		Size = UDim2.fromOffset(20, 20),
		Position = defaultOn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
		BackgroundColor3 = THEME.text, BorderSizePixel = 0, Parent = toggleBtn,
	})
	sInst("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local state = defaultOn
	local function updateVisual()
		TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = state and THEME.green or THEME.bgLighter,
		}):Play()
		TweenService:Create(knob, TweenInfo.new(0.2), {
			Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
		}):Play()
	end
	trackConn(toggleBtn.MouseButton1Click:Connect(function()
		state = not state
		updateVisual()
		addLog(labelText .. " " .. (state and "ON" or "OFF"), "TOGGLE")
		notify(labelText .. " " .. (state and "enabled" or "disabled"), state and THEME.green or THEME.red)
		pcall(callback, state)
	end))
	return row
end

local function createButton(parent, labelText, callback)
	local btn = sInst("TextButton", {
		Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = THEME.bgLight, BorderSizePixel = 0,
		Text = labelText, TextColor3 = THEME.text, Font = Enum.Font.GothamMedium, TextSize = 13,
		AutoButtonColor = false, Parent = parent,
	})
	sInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
	sInst("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = 0.6, Parent = btn })
	trackConn(btn.MouseButton1Click:Connect(function()
		addLog("Button: " .. labelText, "CMD")
		pcall(callback)
	end))
	trackConn(btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = THEME.bgLighter }):Play()
	end))
	trackConn(btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = THEME.bgLight }):Play()
	end))
	return btn
end

-- ===== FEATURE IMPLEMENTATIONS =====

-- FLY
local function toggleFly(state)
	flying = state
	if flying then
		notify("Fly enabled", THEME.green)
		task.spawn(function()
			local hrp = getHRP()
			if not hrp then return end
			local bv = sInst("BodyVelocity", { MaxForce = Vector3.new(9e9, 9e9, 9e9), Velocity = Vector3.zero, Parent = hrp })
			local bg = sInst("BodyGyro", { MaxForce = Vector3.new(9e9, 9e9, 9e9), P = 10000, Parent = hrp })
			flyConn = trackConn(RunService.RenderStepped:Connect(function()
				if not flying or killed then
					if bv then bv:Destroy() end
					if bg then bg:Destroy() end
					if flyConn then flyConn:Disconnect() end
					return
				end
				local cam = Workspace.CurrentCamera
				local hrp2 = getHRP()
				if not hrp2 or not cam then return end
				local dir = Vector3.zero
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
				if dir.Magnitude > 0 then dir = dir.Unit end
				bv.Parent = hrp2
				bv.Velocity = dir * flySpeed
				bg.CFrame = cam.CFrame
			end)
		end)
	else
		notify("Fly disabled", THEME.red)
		local hrp = getHRP()
		if hrp then
			for _, v in ipairs(hrp:GetChildren()) do
				if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
			end
		end
		if flyConn then flyConn:Disconnect() end
	end
	addLog("Fly " .. (state and "ON" or "OFF"), "MOVE")
end

-- NOCLIP
local function toggleNoclip(state)
	noclip = state
	if noclip then
		notify("Noclip enabled", THEME.green)
		noclipConn = trackConn(RunService.Stepped:Connect(function()
			if not noclip or killed then
				if noclipConn then noclipConn:Disconnect() end
				return
			end
			local char = player.Character
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") and p.CanCollide then
						p.CanCollide = false
					end
				end
			end
		end))
	else
		notify("Noclip disabled", THEME.red)
		if noclipConn then noclipConn:Disconnect() end
		local char = player.Character
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					p.CanCollide = true
				end
			end
		end
	end
	addLog("Noclip " .. (state and "ON" or "OFF"), "MOVE")
end

-- FULLBRIGHT
local function toggleFullbright(state)
	fullbright = state
	if fullbright then
		originalBrightness = Lighting.Brightness
		originalClockTime = Lighting.ClockTime
		originalFogEnd = Lighting.FogEnd
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		notify("Fullbright enabled", THEME.green)
	else
		Lighting.Brightness = originalBrightness
		Lighting.ClockTime = originalClockTime
		Lighting.FogEnd = originalFogEnd
		notify("Fullbright disabled", THEME.red)
	end
	addLog("Fullbright " .. (state and "ON" or "OFF"), "VISUAL")
end

-- NIGHT VISION
local function toggleNightVision(state)
	nightVision = state
	if nightVision then
		Lighting.Brightness = 0.2
		Lighting.ClockTime = 0
		Lighting.FogEnd = 100000
		Lighting.Ambient = Color3.fromRGB(30, 50, 30)
		nvOverlay = sInst("ColorCorrectionEffect", {
			Brightness = 0.1, Contrast = 0.3, Saturation = 0.5,
			TintColor = Color3.fromRGB(80, 255, 80), Parent = Lighting,
		})
		notify("Night Vision enabled", THEME.green)
	else
		Lighting.Brightness = originalBrightness
		Lighting.ClockTime = originalClockTime
		Lighting.FogEnd = originalFogEnd
		Lighting.Ambient = Color3.fromRGB(0, 0, 0)
		if nvOverlay then nvOverlay:Destroy() end
		notify("Night Vision disabled", THEME.red)
	end
	addLog("Night Vision " .. (state and "ON" or "OFF"), "VISUAL")
end

-- GOD MODE
local function toggleGodMode(state)
	godMode = state
	if godMode then
		notify("God Mode enabled", THEME.green)
		godModeConn = trackConn(RunService.Heartbeat:Connect(function()
			if not godMode or killed then
				if godModeConn then godModeConn:Disconnect() end
				return
			end
			local hum = getHumanoid()
			if hum and hum.Health < hum.MaxHealth then
				hum.Health = hum.MaxHealth
			end
		end))
	else
		notify("God Mode disabled", THEME.red)
		if godModeConn then godModeConn:Disconnect() end
	end
	addLog("God Mode " .. (state and "ON" or "OFF"), "PLAYER")
end

-- AUTO RESPAWN
local function toggleAutoRespawn(state)
	autoRespawn = state
	if autoRespawn then
		notify("Auto Respawn enabled", THEME.green)
		autoRespawnConn = trackConn(player.CharacterAdded:Connect(function(char)
			task.wait(1)
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health <= 0 then
				player:LoadCharacter()
			end
		end))
	else
		notify("Auto Respawn disabled", THEME.red)
		if autoRespawnConn then autoRespawnConn:Disconnect() end
	end
	addLog("Auto Respawn " .. (state and "ON" or "OFF"), "PLAYER")
end

-- FREEZE
local function toggleFreeze(state)
	frozen = state
	local hum = getHumanoid()
	if hum then
		hum.WalkSpeed = frozen and 0 or walkSpeed
		hum.JumpPower = frozen and 0 or jumpPower
	end
	notify(frozen and "Frozen" or "Unfrozen", frozen and THEME.orange or THEME.green)
	addLog("Freeze " .. (state and "ON" or "OFF"), "MOVE")
end

-- INFINITE JUMP
local function toggleInfiniteJump(state)
	infiniteJump = state
	if infiniteJump then
		notify("Infinite Jump enabled", THEME.green)
		infiniteJumpConn = trackConn(UserInputService.JumpRequest:Connect(function()
			if not infiniteJump or killed then
				if infiniteJumpConn then infiniteJumpConn:Disconnect() end
				return
			end
			local hum = getHumanoid()
			if hum then
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
			end
		end))
	else
		notify("Infinite Jump disabled", THEME.red)
		if infiniteJumpConn then infiniteJumpConn:Disconnect() end
	end
	addLog("Infinite Jump " .. (state and "ON" or "OFF"), "MOVE")
end

-- ANTI AFK
local function toggleAntiAFK(state)
	antiAfk = state
	if antiAfk then
		notify("Anti-AFK enabled", THEME.green)
		local vu = game:GetService("VirtualUser")
		afkConn = trackConn(player.Idled:Connect(function()
			if antiAfk and not killed then
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end
		end))
	else
		notify("Anti-AFK disabled", THEME.red)
		if afkConn then afkConn:Disconnect() end
	end
	addLog("Anti-AFK " .. (state and "ON" or "OFF"), "MISC")
end

-- SPEED BOOST
local function toggleSpeedBoost(state)
	speedBoostActive = state
	local hum = getHumanoid()
	if hum then
		hum.WalkSpeed = state and (walkSpeed * 2) or walkSpeed
	end
	notify(state and "Speed Boost ON" or "Speed Boost OFF", state and THEME.green or THEME.red)
	addLog("Speed Boost " .. (state and "ON" or "OFF"), "MOVE")
end

-- X-RAY
local function toggleXray(state)
	xrayEnabled = state
	if xrayEnabled then
		notify("X-Ray enabled", THEME.green)
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and not obj:IsDescendantOf(player.Character or {}) then
				xrayOriginalTransparency[obj] = obj.Transparency
				obj.Transparency = 0.7
			end
		end
	else
		notify("X-Ray disabled", THEME.red)
		for obj, transp in pairs(xrayOriginalTransparency) do
			if obj and obj.Parent then
				obj.Transparency = transp
			end
		end
		xrayOriginalTransparency = {}
	end
	addLog("X-Ray " .. (state and "ON" or "OFF"), "VISUAL")
end

-- RGB CYCLE
local function toggleRgbCycle(state)
	rgbCycle = state
	if rgbCycle then
		notify("RGB Cycle enabled", THEME.green)
		local hue = 0
		rgbConn = trackConn(RunService.RenderStepped:Connect(function(dt)
			if not rgbCycle or killed then
				if rgbConn then rgbConn:Disconnect() end
				return
			end
			hue = (hue + dt * 0.1) % 1
			local color = Color3.fromHSV(hue, 0.7, 1)
			frameStroke.Color = color
		end))
	else
		notify("RGB Cycle disabled", THEME.red)
		frameStroke.Color = THEME.accent
		if rgbConn then rgbConn:Disconnect() end
	end
	addLog("RGB Cycle " .. (state and "ON" or "OFF"), "VISUAL")
end

-- DISCO MODE
local function toggleDiscoMode(state)
	discoMode = state
	if discoMode then
		notify("Disco Mode enabled", THEME.green)
		local hue = 0
		task.spawn(function()
			while discoMode and not killed do
				task.wait(0.1)
				hue = (hue + 0.05) % 1
				Lighting.ColorShift_Top = Color3.fromHSV(hue, 1, 1)
				Lighting.ColorShift_Bottom = Color3.fromHSV((hue + 0.5) % 1, 1, 1)
			end
			Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
			Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
		end)
	else
		notify("Disco Mode disabled", THEME.red)
		Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
		Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	end
	addLog("Disco Mode " .. (state and "ON" or "OFF"), "VISUAL")
end

-- INFINITE STAMINA
local function toggleInfiniteStamina(state)
	infiniteStamina = state
	local hum = getHumanoid()
	if hum then
		if state then
			local val = hum:FindFirstChild("Stamina") or hum:FindFirstChild("Energy")
			if val and val:IsA("ValueBase") then
				infiniteStaminaConn = trackConn(RunService.Heartbeat:Connect(function()
					if not infiniteStamina or killed then
						if infiniteStaminaConn then infiniteStaminaConn:Disconnect() end
						return
					end
					val.Value = val.MaxValue or 100
				end))
			else
				notify("Stamina attribute not found", THEME.orange)
			end
		else
			if infiniteStaminaConn then infiniteStaminaConn:Disconnect() end
		end
	end
	notify(state and "Infinite Stamina ON" or "Infinite Stamina OFF", state and THEME.green or THEME.red)
	addLog("Infinite Stamina " .. (state and "ON" or "OFF"), "PLAYER")
end

-- CLICK TP
local function toggleClickTp(state)
	clickTpEnabled = state
	if clickTpEnabled then
		notify("Click TP enabled (click to teleport)", THEME.green)
		clickTpConn = trackConn(UserInputService.InputBegan:Connect(function(input, gp)
			if gp or not clickTpEnabled or killed then
				if clickTpConn then clickTpConn:Disconnect() end
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local mouse = player:GetMouse()
				local hrp = getHRP()
				if hrp and mouse.Hit then
					hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
				end
			end
		end))
	else
		notify("Click TP disabled", THEME.red)
		if clickTpConn then clickTpConn:Disconnect() end
	end
	addLog("Click TP " .. (state and "ON" or "OFF"), "MOVE")
end

-- ANTI FLING
local function toggleAntiFling(state)
	antiFlingEnabled = state
	if antiFlingEnabled then
		notify("Anti-Fling enabled", THEME.green)
		antiFlingLastPos = nil
		antiFlingConn = trackConn(RunService.Heartbeat:Connect(function()
			if not antiFlingEnabled or killed then
				if antiFlingConn then antiFlingConn:Disconnect() end
				return
			end
			local hrp = getHRP()
			if not hrp then return end
			if antiFlingLastPos then
				local dist = (hrp.Position - antiFlingLastPos).Magnitude
				if dist > 200 then
					hrp.CFrame = CFrame.new(antiFlingLastPos)
				end
			end
			antiFlingLastPos = hrp.Position
		end))
	else
		notify("Anti-Fling disabled", THEME.red)
		if antiFlingConn then antiFlingConn:Disconnect() end
	end
	addLog("Anti-Fling " .. (state and "ON" or "OFF"), "MISC")
end

-- RAINBOW CHARACTER
local function toggleRainbowCharacter(state)
	rainbowCharacter = state
	if rainbowCharacter then
		notify("Rainbow Character enabled", THEME.green)
		local hue = 0
		rainbowConn = trackConn(RunService.RenderStepped:Connect(function(dt)
			if not rainbowCharacter or killed then
				if rainbowConn then rainbowConn:Disconnect() end
				return
			end
			hue = (hue + dt * 0.2) % 1
			local color = Color3.fromHSV(hue, 0.8, 1)
			local char = player.Character
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
						p.Color = color
					end
				end
			end
		end))
	else
		notify("Rainbow Character disabled", THEME.red)
		if rainbowConn then rainbowConn:Disconnect() end
	end
	addLog("Rainbow Character " .. (state and "ON" or "OFF"), "VISUAL")
end

-- ANTI FALL
local function toggleAntiFall(state)
	antiFallEnabled = state
	if antiFallEnabled then
		notify("Anti-Fall enabled", THEME.green)
		antiFallConn = trackConn(RunService.Heartbeat:Connect(function()
			if not antiFallEnabled or killed then
				if antiFallConn then antiFallConn:Disconnect() end
				return
			end
			local char = player.Character
			if not char then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum:GetState() == Enum.HumanoidStateType.Freefall then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp and hrp.Velocity.Y < -150 then
					hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
				end
			end
		end))
	else
		notify("Anti-Fall disabled", THEME.red)
		if antiFallConn then antiFallConn:Disconnect() end
	end
	addLog("Anti-Fall " .. (state and "ON" or "OFF"), "MOVE")
end

-- SPIDER
local function toggleSpider(state)
	spiderEnabled = state
	if spiderEnabled then
		notify("Spider enabled", THEME.green)
		spiderConn = trackConn(RunService.Heartbeat:Connect(function()
			if not spiderEnabled or killed then
				if spiderConn then spiderConn:Disconnect() end
				return
			end
			local char = player.Character
			if not char then return end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hrp or not hum then return end
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {char}
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local ray = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 5, rayParams)
			if ray and ray.Instance then
				local normal = ray.Normal
				if math.abs(normal.Y) > 0.5 then
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end))
	else
		notify("Spider disabled", THEME.red)
		if spiderConn then spiderConn:Disconnect() end
	end
	addLog("Spider " .. (state and "ON" or "OFF"), "MOVE")
end

-- ESP
local function clearEsp()
	for _, obj in pairs(espObjects) do
		if obj then pcall(function() obj:Destroy() end) end
	end
	for _, obj in pairs(espTracers) do
		if obj then pcall(function() obj:Destroy() end) end
	end
	for _, obj in pairs(espBoxes) do
		if obj then pcall(function() obj:Destroy() end) end
	end
	espObjects = {}
	espTracers = {}
	espBoxes = {}
end

local function updateEsp()
	if not espEnabled or killed then return end
	clearEsp()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			local head = p.Character:FindFirstChild("Head")
			if hrp and hum and head then
				local dist = (getHRP() and (hrp.Position - getHRP().Position).Magnitude or 0)
				if dist <= espMaxDistance then
					local color = espUseTeamColor and (p.TeamColor and p.TeamColor.Color or espColor) or espColor
					local bb = sInst("BillboardGui", {
						Size = UDim2.fromOffset(200, 60),
						Adornee = head, AlwaysOnTop = true, LightInfluence = 0, Parent = espGui,
					})
					espObjects[p] = bb
					if espShowName then
						sInst("TextLabel", {
							Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
							Text = p.Name, TextColor3 = color, Font = Enum.Font.GothamBold, TextSize = 14,
							Parent = bb,
						})
					end
					local yOffset = espShowName and 20 or 0
					if espShowHealth then
						sInst("TextLabel", {
							Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, yOffset), BackgroundTransparency = 1,
							Text = string.format("%d/%d HP", math.floor(hum.Health), math.floor(hum.MaxHealth)), TextColor3 = THEME.text,
							Font = Enum.Font.Gotham, TextSize = 12, Parent = bb,
						})
						yOffset = yOffset + 20
					end
					if espShowDistance then
						sInst("TextLabel", {
							Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, yOffset), BackgroundTransparency = 1,
							Text = string.format("%d m", math.floor(dist)), TextColor3 = THEME.textDim,
							Font = Enum.Font.Gotham, TextSize = 12, Parent = bb,
						})
					end
					if espShowBox then
						local box = sInst("BillboardGui", {
							Size = UDim2.fromOffset(6, 6),
							Adornee = hrp, AlwaysOnTop = true, LightInfluence = 0, Parent = espGui,
						})
						espBoxes[p] = box
						local hl = sInst("Frame", {
							Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 0.5,
							BackgroundColor3 = color, BorderSizePixel = 0, Parent = box,
						})
						sInst("UIStroke", { Color = color, Thickness = 2, Parent = hl })
					end
					if espShowTracers then
						local tracer = sInst("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = color, BorderSizePixel = 0,
							Parent = espGui,
						})
						espTracers[p] = tracer
					end
				end
			end
		end
	end
end

local espUpdateConn = nil
local function toggleEsp(state)
	espEnabled = state
	if espEnabled then
		espGui.Enabled = true
		notify("ESP enabled", THEME.green)
		espUpdateConn = trackConn(RunService.RenderStepped:Connect(function()
			if not espEnabled or killed then
				if espUpdateConn then espUpdateConn:Disconnect() end
				return
			end
			for p, tracer in pairs(espTracers) do
				if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					local cam = Workspace.CurrentCamera
					local hrp = p.Character.HumanoidRootPart
					local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
					if onScreen and getHRP() then
						local myHrp = getHRP()
						local myScreen = cam:WorldToViewportPoint(myHrp.Position)
						tracer.Visible = true
						local startX = screenPos.X
						local startY = screenPos.Y
						local endX = myScreen.X
						local endY = myScreen.Y
						local midX = (startX + endX) / 2
						local midY = (startY + endY) / 2
						local dist = math.sqrt((endX - startX)^2 + (endY - startY)^2)
						local angle = math.atan2(endY - startY, endX - startX)
						tracer.Position = UDim2.fromOffset(midX, midY)
						tracer.Size = UDim2.fromOffset(dist, 2)
						tracer.Rotation = math.deg(angle)
					else
						tracer.Visible = false
					end
				end
			end
		end))
		task.spawn(function()
			while espEnabled and not killed do
				updateEsp()
				task.wait(1)
			end
		end)
	else
		espGui.Enabled = false
		clearEsp()
		if espUpdateConn then espUpdateConn:Disconnect() end
		notify("ESP disabled", THEME.red)
	end
	addLog("ESP " .. (state and "ON" or "OFF"), "ESP")
end

-- ===== CREATE TABS =====
local tabMove = createTab("Move", ">>")
local tabVisual = createTab("Vis", "##")
local tabPlayer = createTab("Player", "@")
local tabEsp = createTab("ESP", "[]")
local tabMisc = createTab("Misc", "*")

-- MOVE TAB
createSectionHeader(tabMove.page, "Movement")
createToggle(tabMove.page, "Fly", false, toggleFly)
createSlider(tabMove.page, "Fly Speed", 10, 500, 50, function(v) flySpeed = v end)
createToggle(tabMove.page, "Noclip", false, toggleNoclip)
createToggle(tabMove.page, "Speed Boost", false, toggleSpeedBoost)
createToggle(tabMove.page, "Infinite Jump", false, toggleInfiniteJump)
createToggle(tabMove.page, "Spider Climb", false, toggleSpider)
createToggle(tabMove.page, "Anti-Fall", false, toggleAntiFall)
createToggle(tabMove.page, "Click TP", false, toggleClickTp)
createToggle(tabMove.page, "Freeze", false, toggleFreeze)
createSlider(tabMove.page, "Walk Speed", 16, 200, 16, function(v)
	walkSpeed = v
	local hum = getHumanoid()
	if hum and not frozen then hum.WalkSpeed = v end
end)
createSlider(tabMove.page, "Jump Power", 10, 300, 50, function(v)
	jumpPower = v
	local hum = getHumanoid()
	if hum and not frozen then hum.JumpPower = v end
end)

-- VISUAL TAB
createSectionHeader(tabVisual.page, "Visuals")
createToggle(tabVisual.page, "Fullbright", false, toggleFullbright)
createToggle(tabVisual.page, "Night Vision", false, toggleNightVision)
createToggle(tabVisual.page, "X-Ray", false, toggleXray)
createToggle(tabVisual.page, "RGB Border", false, toggleRgbCycle)
createToggle(tabVisual.page, "Disco Mode", false, toggleDiscoMode)
createToggle(tabVisual.page, "Rainbow Char", false, toggleRainbowCharacter)
createButton(tabVisual.page, "Reset Lighting", function()
	Lighting.Brightness = originalBrightness
	Lighting.ClockTime = originalClockTime
	Lighting.FogEnd = originalFogEnd
	Lighting.Ambient = Color3.fromRGB(0, 0, 0)
	Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	notify("Lighting reset", THEME.accent)
	addLog("Lighting reset to defaults", "VISUAL")
end)

-- PLAYER TAB
createSectionHeader(tabPlayer.page, "Player")
createToggle(tabPlayer.page, "God Mode", false, toggleGodMode)
createToggle(tabPlayer.page, "Auto Respawn", false, toggleAutoRespawn)
createToggle(tabPlayer.page, "Infinite Stamina", false, toggleInfiniteStamina)
createButton(tabPlayer.page, "Respawn", function()
	player:LoadCharacter()
	notify("Respawned", THEME.accent)
	addLog("Manual respawn", "PLAYER")
end)
createButton(tabPlayer.page, "Heal", function()
	local hum = getHumanoid()
	if hum then
		hum.Health = hum.MaxHealth
		notify("Healed to full", THEME.green)
	end
	addLog("Healed", "PLAYER")
end)
createButton(tabPlayer.page, "Kill Self", function()
	local hum = getHumanoid()
	if hum then
		hum.Health = 0
		notify("Killed self", THEME.red)
	end
	addLog("Self kill", "PLAYER")
end)

-- ESP TAB
createSectionHeader(tabEsp.page, "ESP Settings")
createToggle(tabEsp.page, "Enable ESP", false, toggleEsp)
createToggle(tabEsp.page, "Show Names", true, function(v) espShowName = v end)
createToggle(tabEsp.page, "Show Health", true, function(v) espShowHealth = v end)
createToggle(tabEsp.page, "Show Distance", true, function(v) espShowDistance = v end)
createToggle(tabEsp.page, "Show Boxes", false, function(v) espShowBox = v end)
createToggle(tabEsp.page, "Show Tracers", false, function(v) espShowTracers = v end)
createToggle(tabEsp.page, "Use Team Color", false, function(v) espUseTeamColor = v end)
createSlider(tabEsp.page, "ESP Distance", 100, 9999, 9999, function(v) espMaxDistance = v end)

-- MISC TAB
createSectionHeader(tabMisc.page, "Misc")
createToggle(tabMisc.page, "Anti-AFK", false, toggleAntiAfk)
createToggle(tabMisc.page, "Anti-Fling", false, toggleAntiFling)
createToggle(tabMisc.page, "Show Stats", true, function(v) showStats = v end)
createButton(tabMisc.page, "Toggle Log", toggleLogWindow)
createButton(tabMisc.page, "Rejoin Server", function()
	TeleportService:Teleport(game.PlaceId, player)
end)
createButton(tabMisc.page, "Unload Panel", function()
	notify("Unloading...", THEME.orange)
	addLog("Panel unloaded", "PANEL")
	killed = true
	for _, conn in ipairs(allConnections) do
		pcall(function() conn:Disconnect() end)
	end
	clearEsp()
	if screenGui then screenGui:Destroy() end
	if notifGui then notifGui:Destroy() end
	if logGui then logGui:Destroy() end
	if statsGui then statsGui:Destroy() end
	if espGui then espGui:Destroy() end
	if toggleBtnGui then toggleBtnGui:Destroy() end
	if loadingGui then loadingGui:Destroy() end
	Lighting.Brightness = originalBrightness
	Lighting.ClockTime = originalClockTime
	Lighting.FogEnd = originalFogEnd
end)

-- ===== COMMAND BAR =====
local commands = {
	help = "Commands: fly, noclip, god, esp, speed [num], jump [num], xray, fullbright, respawn, heal, freeze, disco, rgb, unload",
	fly = function() toggleFly(not flying) end,
	noclip = function() toggleNoclip(not noclip) end,
	god = function() toggleGodMode(not godMode) end,
	esp = function() toggleEsp(not espEnabled) end,
	speed = function(args)
		local v = tonumber(args[1]) or 16
		walkSpeed = v
		local hum = getHumanoid()
		if hum then hum.WalkSpeed = v end
		notify("Speed set to " .. v, THEME.accent)
	end,
	jump = function(args)
		local v = tonumber(args[1]) or 50
		jumpPower = v
		local hum = getHumanoid()
		if hum then hum.JumpPower = v end
		notify("Jump set to " .. v, THEME.accent)
	end,
	xray = function() toggleXray(not xrayEnabled) end,
	fullbright = function() toggleFullbright(not fullbright) end,
	respawn = function() player:LoadCharacter() end,
	heal = function()
		local hum = getHumanoid()
		if hum then hum.Health = hum.MaxHealth end
	end,
	freeze = function() toggleFreeze(not frozen) end,
	disco = function() toggleDiscoMode(not discoMode) end,
	rgb = function() toggleRgbCycle(not rgbCycle) end,
	log = function() toggleLogWindow() end,
	stats = function() showStats = not showStats end,
	antifling = function() toggleAntiFling(not antiFlingEnabled) end,
	antiafk = function() toggleAntiAFK(not antiAfk) end,
	infinitejump = function() toggleInfiniteJump(not infiniteJump) end,
	nightvision = function() toggleNightVision(not nightVision) end,
	unload = function()
		notify("Unloading...", THEME.orange)
		killed = true
		for _, conn in ipairs(allConnections) do
			pcall(function() conn:Disconnect() end)
		end
		if screenGui then screenGui:Destroy() end
		if notifGui then notifGui:Destroy() end
		if logGui then logGui:Destroy() end
		if statsGui then statsGui:Destroy() end
		if espGui then espGui:Destroy() end
		if toggleBtnGui then toggleBtnGui:Destroy() end
	end,
}

trackConn(commandBar.FocusLost:Connect(function(enter)
	if enter and commandBar.Text ~= "" then
		local text = commandBar.Text:lower()
		text = text:gsub("^%s+", ""):gsub("%s+$", "")
		local args = {}
		for word in text:gmatch("%S+") do
			table.insert(args, word)
		end
		local cmd = table.remove(args, 1)
		if commands[cmd] then
			if type(commands[cmd]) == "string" then
				notify(commands[cmd], THEME.accent)
			else
				pcall(commands[cmd], args)
			end
			addLog("Command: " .. text, "CMD")
		else
			notify("Unknown command: " .. cmd, THEME.red)
			addLog("Unknown command: " .. text, "ERROR")
		end
		commandBar.Text = ""
	end
end))

-- ===== MINIMIZE =====
local minimized = false
local minimizedSize = nil
trackConn(minimizeBtn.MouseButton1Click:Connect(function()
	panelAnimating = true
	if not minimized then
		minimizedSize = frame.Size
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Size = UDim2.fromOffset(frame.Size.X.Offset, 48),
		}):Play()
		contentArea.Visible = false
		tabBar.Visible = false
		commandBar.Visible = false
		resizeHandle.Visible = false
		minimized = true
		notify("Panel minimized", THEME.accent)
	else
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Size = minimizedSize or UDim2.fromOffset(280, 360),
		}):Play()
		contentArea.Visible = true
		tabBar.Visible = true
		commandBar.Visible = true
		resizeHandle.Visible = true
		minimized = false
		notify("Panel restored", THEME.accent)
	end
	task.wait(0.35)
	panelAnimating = false
end))

-- ===== CLOSE =====
trackConn(closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
	if toggleBtnGui then toggleBtnGui.Enabled = true end
	addLog("Panel closed", "PANEL")
end))

-- ===== TOGGLE BUTTON (floating) =====
toggleBtnGui = sInst("ScreenGui", {
	Name = "APT_" .. tostring(math.random(10000, 99999)),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = playerGui,
})
local toggleBtn = sInst("TextButton", {
	Size = UDim2.fromOffset(44, 44),
	Position = UDim2.new(0, 20, 0, 20),
	BackgroundColor3 = THEME.accent,
	Text = "AP",
	TextColor3 = THEME.text,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	AutoButtonColor = false,
	Parent = toggleBtnGui,
})
sInst("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = toggleBtn })
sInst("UIStroke", { Color = THEME.accent2, Thickness = 2, Transparency = 0.3, Parent = toggleBtn })

local toggleDragging = false
local toggleDragStart = nil
local toggleStartPos = nil
trackConn(toggleBtn.MouseButton1Down:Connect(function()
	toggleDragging = true
	toggleDragStart = UserInputService:GetMouseLocation()
	toggleStartPos = toggleBtn.Position
end))
trackConn(UserInputService.InputChanged:Connect(function(input)
	if toggleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = UserInputService:GetMouseLocation() - toggleDragStart
		toggleBtn.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y)
	end
end))
trackConn(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		toggleDragging = false
	end
end))

local toggleClickTime = 0
trackConn(toggleBtn.MouseButton1Click:Connect(function()
	if os.clock() - toggleClickTime < 0.3 then return end
	toggleClickTime = os.clock()
	screenGui.Enabled = not screenGui.Enabled
	if screenGui.Enabled then
		if toggleBtnGui then toggleBtnGui.Enabled = false end
		addLog("Panel opened", "PANEL")
		syncShadow()
	end
end))

-- ===== DRAG SETUP =====
enableDrag(frame, titleBar)

-- ===== KEYBINDS =====
trackConn(UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		screenGui.Enabled = not screenGui.Enabled
		if screenGui.Enabled then
			if toggleBtnGui then toggleBtnGui.Enabled = false end
			syncShadow()
		else
			if toggleBtnGui then toggleBtnGui.Enabled = true end
		end
	end
	if input.KeyCode == Enum.KeyCode.RightControl then
		screenGui.Enabled = false
		if toggleBtnGui then toggleBtnGui.Enabled = true end
	end
end))

-- ===== CHARACTER HANDLER =====
trackConn(player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	if killed then return end
	if frozen then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 0
			hum.JumpPower = 0
		end
	end
	if speedBoostActive then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = walkSpeed * 2 end
	end
	if godMode then
		toggleGodMode(false)
		task.wait(0.5)
		toggleGodMode(true)
	end
end))

-- ===== LOADING SCREEN =====
loadingGui = sInst("ScreenGui", {
	Name = "APLD_" .. tostring(math.random(10000, 99999)),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = playerGui,
})
local loadingFrame = sInst("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = THEME.bg,
	BackgroundTransparency = 0.2,
	Parent = loadingGui,
})
local loadingLabel = sInst("TextLabel", {
	Size = UDim2.new(0.6, 0, 0.1, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Text = "Loading Admin Panel...",
	TextColor3 = THEME.accent,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	Parent = loadingFrame,
})
sInst("UIGradient", {
	Color = ColorSequence.new(THEME.accent, THEME.accent2),
	Rotation = 90, Parent = loadingLabel,
})

-- ===== INIT =====
task.spawn(function()
	task.wait(0.5)
	TweenService:Create(loadingLabel, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
	task.wait(0.5)
	loadingGui:Destroy()
	screenGui.Enabled = true
	if toggleBtnGui then toggleBtnGui.Enabled = false end
	if tabs[1] then
		tabs[1].page.Visible = true
		tabs[1].button.BackgroundColor3 = THEME.accent
		tabs[1].button.TextColor3 = THEME.text
		activeTab = tabs[1]
	end
	notify("Admin Panel v6 loaded!", THEME.green)
	addLog("Admin Panel v6 initialized", "PANEL")
	addLog("Press RightShift to toggle panel", "PANEL")
	addLog("Type help in command bar for commands", "PANEL")
end)
