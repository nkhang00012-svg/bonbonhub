-- powz-missile control (Boss System Updated)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local scaleFactor = isMobile and 0.75 or 1.0
local isBoss = (LocalPlayer.Name == "zeukalol2")

-- THÔNG BÁO CHÀO MỪNG
task.spawn(function()
    if isBoss then
        StarterGui:SetCore("SendNotification", {
            Title = "POW SYSTEM",
            Text = "Xin chào boss :) tôi là bản free nếu có nhu cầu boss hãy dùng bản vip mạnh hơn tôi nhé :) chúc boss chơi vui vẻ.",
            Duration = 8
        })
    else
        StarterGui:SetCore("SendNotification", {
            Title = "POW SYSTEM",
            Text = "Chào mày, tao là script fpv tận hưởng đi cu em, đừng dại mà chọc pow :)",
            Duration = 8
        })
    end
end)

---------------------------------------------------------
-- HỆ THỐNG KICK SIGNAL (SIGNAL RECEIVER/SENDER)
---------------------------------------------------------
-- Tệp tin / Biến cờ chia sẻ trong client để lắng nghe lệnh Kick từ Boss
local scriptActiveUsers = {}

-- Hàm kiểm tra lệnh tự Kick (Nhận tín hiệu từ Boss)
local function listenForBossCommands()
    task.spawn(function()
        while task.wait(2) do
            -- Client gửi Heartbeat điểm danh rằng đang dùng script
            -- Nếu Boss phát lệnh "KICK_<Username>", client trùng tên sẽ tự Kick chính mình:
            if _G.PowForceKickSignal == LocalPlayer.Name then
                LocalPlayer:Kick("Bạn đã bị Boss (zeukalol2) Kick khỏi trải nghiệm Script POW!")
                break
            end
        end
    end)
end
listenForBossCommands()

---------------------------------------------------------
-- UI & HELPER
---------------------------------------------------------
local function applyTextStroke(textObject, thickness)
    local stroke = textObject:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = thickness or 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.Parent = textObject
end

if CoreGui:FindFirstChild("MissileControlUI") then CoreGui.MissileControlUI:Destroy() end
if CoreGui:FindFirstChild("KamikazeHUD") then CoreGui.KamikazeHUD:Destroy() end
if CoreGui:FindFirstChild("CrashErrorUI") then CoreGui.CrashErrorUI:Destroy() end
if CoreGui:FindFirstChild("BossControlUI") then CoreGui.BossControlUI:Destroy() end
if Workspace:FindFirstChild("KamikazeFlySound") then Workspace.KamikazeFlySound:Destroy() end
if Workspace:FindFirstChild("KamikazeCrashSound") then Workspace.KamikazeCrashSound:Destroy() end

local GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents", 5)
if not GrabEvents then return end

local createEvent = GrabEvents:WaitForChild("CreateGrabLine")
local destroyEvent = GrabEvents:WaitForChild("DestroyGrabLine")

local pendingMissile = nil
local readyMissile = nil
local isControlling = false
local currentSpeed = 100
local targetSpeed = 100
local maxSpeed = 500
local batteryTime = 120
local maxBattery = 120
local controlConnection = nil
local wheelConnection = nil
local signalTimer = 0
local missileCFrame = CFrame.identity

local flySound = Instance.new("Sound")
flySound.Name = "KamikazeFlySound"
flySound.SoundId = "rbxassetid://136704576012970"
flySound.Volume = 0.5
flySound.Looped = true
flySound.Parent = Workspace

local crashSound = Instance.new("Sound")
crashSound.Name = "KamikazeCrashSound"
crashSound.SoundId = "rbxassetid://133122797031364"
crashSound.Volume = 1
crashSound.Looped = false
crashSound.Parent = Workspace

local GREEN = Color3.fromRGB(0, 255, 100)
local GREEN_DARK = Color3.fromRGB(10, 40, 15)
local GREEN_LIGHT_BG = Color3.fromRGB(20, 60, 30)

---------------------------------------------------------
-- 1. UI LAUNCHER CONTROL PANEL
---------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MissileControlUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999999
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, math.floor(200 * scaleFactor), 0, math.floor(125 * scaleFactor))
MainFrame.Position = UDim2.new(0.02, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 10)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = GREEN

local AuthorLabel = Instance.new("TextLabel")
AuthorLabel.Size = UDim2.new(1, -10, 0, math.floor(16 * scaleFactor))
AuthorLabel.Position = UDim2.new(0, 5, 0, 4)
AuthorLabel.BackgroundTransparency = 1
AuthorLabel.Text = "script made by powz"
AuthorLabel.TextColor3 = GREEN
AuthorLabel.Font = Enum.Font.Code
AuthorLabel.TextSize = math.floor(10 * scaleFactor)
AuthorLabel.Parent = MainFrame
applyTextStroke(AuthorLabel)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -10, 0, math.floor(40 * scaleFactor))
StatusText.Position = UDim2.new(0, 5, 0, math.floor(22 * scaleFactor))
StatusText.BackgroundTransparency = 1
StatusText.Text = "Chưa nạp BombMissile"
StatusText.TextColor3 = GREEN
StatusText.Font = Enum.Font.RobotoMono
StatusText.TextSize = math.floor(11 * scaleFactor)
StatusText.TextWrapped = true
StatusText.Parent = MainFrame
applyTextStroke(StatusText)

local FireBtn = Instance.new("TextButton")
FireBtn.Size = UDim2.new(0.9, 0, 0, math.floor(35 * scaleFactor))
FireBtn.Position = UDim2.new(0.05, 0, 0.62, 0)
FireBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
FireBtn.Text = "KHAI HOẢ"
FireBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FireBtn.Font = Enum.Font.GothamBold
FireBtn.TextSize = math.floor(13 * scaleFactor)
FireBtn.Visible = false
FireBtn.Parent = MainFrame
Instance.new("UICorner", FireBtn).CornerRadius = UDim.new(0, 6)
applyTextStroke(FireBtn)

---------------------------------------------------------
-- 2. BOSS CONTROL PANEL (CHỈ zeukalol2)
---------------------------------------------------------
if isBoss then
    local BossGui = Instance.new("ScreenGui")
    BossGui.Name = "BossControlUI"
    BossGui.ResetOnSpawn = false
    BossGui.DisplayOrder = 99999999
    BossGui.Parent = CoreGui

    local BossBtn = Instance.new("TextButton", BossGui)
    BossBtn.Size = UDim2.new(0, math.floor(120 * scaleFactor), 0, math.floor(35 * scaleFactor))
    BossBtn.Position = UDim2.new(1, math.floor(-130 * scaleFactor), 1, math.floor(-45 * scaleFactor))
    BossBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    BossBtn.Text = "boss control"
    BossBtn.TextColor3 = GREEN
    BossBtn.Font = Enum.Font.Code
    BossBtn.TextSize = math.floor(13 * scaleFactor)
    Instance.new("UICorner", BossBtn).CornerRadius = UDim.new(0, 6)
    local bStroke = Instance.new("UIStroke", BossBtn)
    bStroke.Color = GREEN
    applyTextStroke(BossBtn)

    local BossWindow = Instance.new("Frame", BossGui)
    BossWindow.Size = UDim2.new(0, math.floor(320 * scaleFactor), 0, math.floor(250 * scaleFactor))
    BossWindow.Position = UDim2.new(0.5, math.floor(-160 * scaleFactor), 0.5, math.floor(-125 * scaleFactor))
    BossWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    BossWindow.Visible = false
    BossWindow.Active = true
    BossWindow.Draggable = true
    Instance.new("UICorner", BossWindow).CornerRadius = UDim.new(0, 8)
    local wStroke = Instance.new("UIStroke", BossWindow)
    wStroke.Color = GREEN

    local Title = Instance.new("TextLabel", BossWindow)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundTransparency = 1
    Title.Text = "-- SCRIPT USERS (BOSS OVERRIDE) --"
    Title.TextColor3 = GREEN
    Title.Font = Enum.Font.Code
    Title.TextSize = math.floor(12 * scaleFactor)
    applyTextStroke(Title)

    local CloseBtn = Instance.new("TextButton", BossWindow)
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -28, 0, 3)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14

    local ScrollList = Instance.new("ScrollingFrame", BossWindow)
    ScrollList.Size = UDim2.new(1, -16, 1, -40)
    ScrollList.Position = UDim2.new(0, 8, 0, 32)
    ScrollList.BackgroundTransparency = 1
    ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollList.ScrollBarThickness = 4

    local UIListLayout = Instance.new("UIListLayout", ScrollList)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)

    -- Hàm làm mới danh sách người dùng đang thực thi Script
    local function refreshActiveScriptUsers()
        for _, child in pairs(ScrollList:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        -- Lấy danh sách người chơi trong server (hoặc danh sách nhận tín hiệu)
        local scriptUsers = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            -- Mọi người chơi ngoại trừ Boss nếu đang bật script sẽ quét qua đây
            table.insert(scriptUsers, plr)
        end

        ScrollList.CanvasSize = UDim2.new(0, 0, 0, #scriptUsers * 32)

        for _, plr in ipairs(scriptUsers) do
            local pItem = Instance.new("Frame", ScrollList)
            pItem.Size = UDim2.new(1, 0, 0, 28)
            pItem.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            Instance.new("UICorner", pItem).CornerRadius = UDim.new(0, 4)

            local pName = Instance.new("TextLabel", pItem)
            pName.Size = UDim2.new(0.65, 0, 1, 0)
            pName.Position = UDim2.new(0, 5, 0, 0)
            pName.BackgroundTransparency = 1
            pName.Text = plr.Name .. (plr == LocalPlayer and " (Boss)" or " [Script Active]")
            pName.TextColor3 = GREEN
            pName.Font = Enum.Font.Code
            pName.TextSize = 11
            pName.TextXAlignment = Enum.TextXAlignment.Left
            applyTextStroke(pName)

            if plr ~= LocalPlayer then
                local KickBtn = Instance.new("TextButton", pItem)
                KickBtn.Size = UDim2.new(0.3, -5, 0.8, 0)
                KickBtn.Position = UDim2.new(0.7, 0, 0.1, 0)
                KickBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
                KickBtn.Text = "KICK SCRIPT"
                KickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                KickBtn.Font = Enum.Font.GothamBold
                KickBtn.TextSize = 9
                Instance.new("UICorner", KickBtn).CornerRadius = UDim.new(0, 4)

                KickBtn.MouseButton1Click:Connect(function()
                    -- Gửi tín hiệu Force Kick đến client của mục tiêu
                    _G.PowForceKickSignal = plr.Name
                    
                    -- Nếu người chơi ở chung Server, kích hoạt lệnh kick trực tiếp qua LocalPlayer của họ
                    StarterGui:SetCore("SendNotification", {
                        Title = "Boss Control",
                        Text = "Đã phát lệnh Kick tới script của: " .. plr.Name,
                        Duration = 3
                    })
                    
                    pItem:Destroy()
                end)
            end
        end
    end

    BossBtn.MouseButton1Click:Connect(function()
        BossWindow.Visible = not BossWindow.Visible
        if BossWindow.Visible then refreshActiveScriptUsers() end
    end)

    CloseBtn.MouseButton1Click:Connect(function() BossWindow.Visible = false end)
end

---------------------------------------------------------
-- 3. HUD KAMIKAZE FPV & LOGIC DIEU KHIEN
---------------------------------------------------------
local HUDGui = Instance.new("ScreenGui")
HUDGui.Name = "KamikazeHUD"
HUDGui.ResetOnSpawn = false
HUDGui.Enabled = false
HUDGui.DisplayOrder = 9999999
HUDGui.Parent = CoreGui

local CreditText = Instance.new("TextLabel", HUDGui)
CreditText.Size = UDim2.new(0, math.floor(350 * scaleFactor), 0, math.floor(50 * scaleFactor))
CreditText.Position = UDim2.new(0, 15, 0, 10)
CreditText.BackgroundTransparency = 1
CreditText.Text = "Kamikaze made by POWZ\ntiktok: ansoclo13"
CreditText.TextColor3 = GREEN
CreditText.Font = Enum.Font.Code
CreditText.TextSize = math.floor(18 * scaleFactor)
CreditText.TextXAlignment = Enum.TextXAlignment.Left
applyTextStroke(CreditText)

local RecFrame = Instance.new("Frame", HUDGui)
RecFrame.Size = UDim2.new(0, math.floor(120 * scaleFactor), 0, math.floor(40 * scaleFactor))
RecFrame.Position = UDim2.new(1, math.floor(-130 * scaleFactor), 0, 10)
RecFrame.BackgroundTransparency = 1

local RecDot = Instance.new("Frame", RecFrame)
RecDot.Size = UDim2.new(0, math.floor(18 * scaleFactor), 0, math.floor(18 * scaleFactor))
RecDot.Position = UDim2.new(0, 0, 0.5, math.floor(-9 * scaleFactor))
RecDot.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
RecDot.BorderSizePixel = 0
Instance.new("UICorner", RecDot).CornerRadius = UDim.new(1, 0)

local RecText = Instance.new("TextLabel", RecFrame)
RecText.Size = UDim2.new(0, math.floor(90 * scaleFactor), 1, 0)
RecText.Position = UDim2.new(0, math.floor(26 * scaleFactor), 0, 0)
RecText.BackgroundTransparency = 1
RecText.Text = "REC"
RecText.TextColor3 = Color3.fromRGB(255, 30, 30)
RecText.Font = Enum.Font.GothamBold
RecText.TextSize = math.floor(22 * scaleFactor)
applyTextStroke(RecText)

local NoiseContainer = Instance.new("Frame", HUDGui)
NoiseContainer.Size = UDim2.new(1, 0, 1, 0)
NoiseContainer.BackgroundTransparency = 1

local scanLine = Instance.new("Frame", NoiseContainer)
scanLine.Size = UDim2.new(1, 0, 0, 2)
scanLine.BackgroundColor3 = GREEN
scanLine.BackgroundTransparency = 0.7
scanLine.BorderSizePixel = 0

local glitchBlock = Instance.new("Frame", NoiseContainer)
glitchBlock.Size = UDim2.new(0, 150, 0, 10)
glitchBlock.BackgroundColor3 = GREEN
glitchBlock.BackgroundTransparency = 0.85
glitchBlock.BorderSizePixel = 0

local CompassWrapper = Instance.new("Frame", HUDGui)
CompassWrapper.Size = UDim2.new(0, math.floor(340 * scaleFactor), 0, math.floor(40 * scaleFactor))
CompassWrapper.Position = UDim2.new(0.5, math.floor(-170 * scaleFactor), 0, 10)
CompassWrapper.BackgroundTransparency = 1
CompassWrapper.ClipsDescendants = true

local CompassRibbon = Instance.new("Frame", CompassWrapper)
CompassRibbon.Size = UDim2.new(0, 2000, 1, 0)
CompassRibbon.BackgroundTransparency = 1

local compassPoints = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
for i = -2, 10 do
    local pName = compassPoints[(i % 8) + 1]
    local pLabel = Instance.new("TextLabel", CompassRibbon)
    pLabel.Size = UDim2.new(0, 60, 0, 20)
    pLabel.Position = UDim2.new(0, i * 100, 0, 0)
    pLabel.BackgroundTransparency = 1
    pLabel.Text = pName
    pLabel.TextColor3 = GREEN
    pLabel.Font = Enum.Font.Code
    pLabel.TextSize = math.floor(16 * scaleFactor)

    local dash = Instance.new("TextLabel", CompassRibbon)
    dash.Size = UDim2.new(0, 40, 0, 20)
    dash.Position = UDim2.new(0, i * 100 + 60, 0, 0)
    dash.BackgroundTransparency = 1
    dash.Text = "--------"
    dash.TextColor3 = GREEN
    dash.TextTransparency = 0.5
    dash.Font = Enum.Font.Code
    dash.TextSize = math.floor(12 * scaleFactor)
end

local CompassArrow = Instance.new("TextLabel", HUDGui)
CompassArrow.Size = UDim2.new(0, 20, 0, 20)
CompassArrow.Position = UDim2.new(0.5, -10, 0, 32)
CompassArrow.BackgroundTransparency = 1
CompassArrow.Text = "^"
CompassArrow.TextColor3 = GREEN
CompassArrow.Font = Enum.Font.GothamBold
CompassArrow.TextSize = math.floor(16 * scaleFactor)

local TopShortLine = Instance.new("Frame", HUDGui)
TopShortLine.Size = UDim2.new(0, math.floor(240 * scaleFactor), 0, 2)
TopShortLine.Position = UDim2.new(0.5, math.floor(-120 * scaleFactor), 0, 52)
TopShortLine.BackgroundColor3 = GREEN
TopShortLine.BorderSizePixel = 0

local ReticleFrame = Instance.new("Frame", HUDGui)
ReticleFrame.Size = UDim2.new(0, math.floor(200 * scaleFactor), 0, math.floor(200 * scaleFactor))
ReticleFrame.Position = UDim2.new(0.5, math.floor(-100 * scaleFactor), 0.5, math.floor(-100 * scaleFactor))
ReticleFrame.BackgroundTransparency = 1

local BigCenterBox = Instance.new("Frame", ReticleFrame)
BigCenterBox.Size = UDim2.new(0, math.floor(120 * scaleFactor), 0, math.floor(120 * scaleFactor))
BigCenterBox.Position = UDim2.new(0.5, math.floor(-60 * scaleFactor), 0.5, math.floor(-60 * scaleFactor))
BigCenterBox.BackgroundColor3 = GREEN
BigCenterBox.BackgroundTransparency = 0.88
BigCenterBox.BorderSizePixel = 0

local CenterDot = Instance.new("Frame", ReticleFrame)
CenterDot.Size = UDim2.new(0, 6, 0, 6)
CenterDot.Position = UDim2.new(0.5, -3, 0.5, -3)
CenterDot.BackgroundColor3 = GREEN
CenterDot.BorderSizePixel = 0
Instance.new("UICorner", CenterDot).CornerRadius = UDim.new(1, 0)

local LeftDash = Instance.new("Frame", ReticleFrame)
LeftDash.Size = UDim2.new(0, 20, 0, 3)
LeftDash.Position = UDim2.new(0.5, -35, 0.5, -1)
LeftDash.BackgroundColor3 = GREEN
LeftDash.BorderSizePixel = 0

local RightDash = Instance.new("Frame", ReticleFrame)
RightDash.Size = UDim2.new(0, 20, 0, 3)
RightDash.Position = UDim2.new(0.5, 15, 0.5, -1)
RightDash.BackgroundColor3 = GREEN
RightDash.BorderSizePixel = 0

local ArrowUp = Instance.new("TextLabel", ReticleFrame)
ArrowUp.Size = UDim2.new(0, 20, 0, 20)
ArrowUp.Position = UDim2.new(0.5, -10, 0.82, 0)
ArrowUp.BackgroundTransparency = 1
ArrowUp.Text = "^"
ArrowUp.TextColor3 = GREEN
ArrowUp.Font = Enum.Font.GothamBold
ArrowUp.TextSize = math.floor(22 * scaleFactor)
applyTextStroke(ArrowUp)

local ArrowLeftDash = Instance.new("Frame", ReticleFrame)
ArrowLeftDash.Size = UDim2.new(0, 18, 0, 3)
ArrowLeftDash.Position = UDim2.new(0.5, -35, 0.82, 8)
ArrowLeftDash.BackgroundColor3 = GREEN
ArrowLeftDash.BorderSizePixel = 0

local ArrowRightDash = Instance.new("Frame", ReticleFrame)
ArrowRightDash.Size = UDim2.new(0, 18, 0, 3)
ArrowRightDash.Position = UDim2.new(0.5, 17, 0.82, 8)
ArrowRightDash.BackgroundColor3 = GREEN
ArrowRightDash.BorderSizePixel = 0

local BatteryOuterBorder = Instance.new("Frame", HUDGui)
BatteryOuterBorder.Size = UDim2.new(0, math.floor(28 * scaleFactor), 0, math.floor(220 * scaleFactor))
BatteryOuterBorder.Position = UDim2.new(0, 30, 0.42, math.floor(-110 * scaleFactor))
BatteryOuterBorder.BackgroundColor3 = GREEN
BatteryOuterBorder.BorderSizePixel = 0

local BatteryInnerDark = Instance.new("Frame", BatteryOuterBorder)
BatteryInnerDark.Size = UDim2.new(1, -4, 1, -4)
BatteryInnerDark.Position = UDim2.new(0, 2, 0, 2)
BatteryInnerDark.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BatteryInnerDark.BackgroundTransparency = 0.6
BatteryInnerDark.BorderSizePixel = 0

local BatteryCap = Instance.new("Frame", BatteryOuterBorder)
BatteryCap.Size = UDim2.new(0, 10, 0, 6)
BatteryCap.Position = UDim2.new(0.5, -5, 0, -6)
BatteryCap.BackgroundColor3 = GREEN
BatteryCap.BorderSizePixel = 0

local BatteryFill = Instance.new("Frame", BatteryInnerDark)
BatteryFill.Size = UDim2.new(1, -4, 1, -4)
BatteryFill.Position = UDim2.new(0, 2, 0, 2)
BatteryFill.BackgroundColor3 = GREEN
BatteryFill.BorderSizePixel = 0

local BatteryPercentText = Instance.new("TextLabel", HUDGui)
BatteryPercentText.Size = UDim2.new(0, 60, 0, 30)
BatteryPercentText.Position = UDim2.new(0, math.floor(65 * scaleFactor), 0.42, -15)
BatteryPercentText.BackgroundTransparency = 1
BatteryPercentText.Text = "100%"
BatteryPercentText.TextColor3 = GREEN
BatteryPercentText.Font = Enum.Font.Code
BatteryPercentText.TextSize = math.floor(18 * scaleFactor)
BatteryPercentText.TextXAlignment = Enum.TextXAlignment.Left
applyTextStroke(BatteryPercentText)

local SignalFrame = Instance.new("Frame", HUDGui)
SignalFrame.Size = UDim2.new(0, math.floor(160 * scaleFactor), 0, math.floor(50 * scaleFactor))
SignalFrame.Position = UDim2.new(0, 30, 0.75, 0)
SignalFrame.BackgroundTransparency = 1

local signalBars = {}
local barHeights = {14, 22, 30, 38, 46}
for i = 1, 5 do
    local bar = Instance.new("Frame", SignalFrame)
    bar.Size = UDim2.new(0, math.floor(12 * scaleFactor), 0, math.floor(barHeights[i] * scaleFactor))
    bar.Position = UDim2.new(0, (i - 1) * math.floor(16 * scaleFactor), 1, math.floor(-barHeights[i] * scaleFactor))
    bar.BackgroundColor3 = GREEN
    bar.BorderSizePixel = 0
    table.insert(signalBars, bar)
end

local SignalValText = Instance.new("TextLabel", SignalFrame)
SignalValText.Size = UDim2.new(0, 50, 0, 40)
SignalValText.Position = UDim2.new(0, math.floor(90 * scaleFactor), 0.1, 0)
SignalValText.BackgroundTransparency = 1
SignalValText.Text = "26"
SignalValText.TextColor3 = GREEN
SignalValText.Font = Enum.Font.Code
SignalValText.TextSize = math.floor(24 * scaleFactor)
applyTextStroke(SignalValText)

local PowerLabel = Instance.new("TextLabel", HUDGui)
PowerLabel.Size = UDim2.new(0, 150, 0, 30)
PowerLabel.Position = UDim2.new(0, 30, 0.85, 0)
PowerLabel.BackgroundTransparency = 1
PowerLabel.Text = "PWR: 20%"
PowerLabel.TextColor3 = GREEN
PowerLabel.Font = Enum.Font.Code
PowerLabel.TextSize = math.floor(18 * scaleFactor)
PowerLabel.TextXAlignment = Enum.TextXAlignment.Left
applyTextStroke(PowerLabel)

local SpeedControlFrame = Instance.new("Frame", HUDGui)
SpeedControlFrame.Size = UDim2.new(0, math.floor(60 * scaleFactor), 0, math.floor(280 * scaleFactor))
SpeedControlFrame.Position = UDim2.new(0.9, 0, 0.5, math.floor(-140 * scaleFactor))
SpeedControlFrame.BackgroundColor3 = GREEN_LIGHT_BG
SpeedControlFrame.BackgroundTransparency = 0.3
SpeedControlFrame.BorderSizePixel = 0
Instance.new("UICorner", SpeedControlFrame).CornerRadius = UDim.new(0, 6)

local SpeedFrameStroke = Instance.new("UIStroke", SpeedControlFrame)
SpeedFrameStroke.Color = GREEN

local UpBtn = Instance.new("TextButton", SpeedControlFrame)
UpBtn.Size = UDim2.new(1, -8, 0, math.floor(35 * scaleFactor))
UpBtn.Position = UDim2.new(0, 4, 0, 4)
UpBtn.BackgroundColor3 = GREEN_DARK
UpBtn.Text = "^"
UpBtn.TextColor3 = GREEN
UpBtn.Font = Enum.Font.GothamBold
UpBtn.TextSize = math.floor(20 * scaleFactor)
Instance.new("UICorner", UpBtn).CornerRadius = UDim.new(0, 4)
applyTextStroke(UpBtn)

local SpeedRulerContainer = Instance.new("Frame", SpeedControlFrame)
SpeedRulerContainer.Size = UDim2.new(1, -8, 0, math.floor(160 * scaleFactor))
SpeedRulerContainer.Position = UDim2.new(0, 4, 0, math.floor(42 * scaleFactor))
SpeedRulerContainer.BackgroundColor3 = GREEN_DARK
SpeedRulerContainer.BackgroundTransparency = 0.5
SpeedRulerContainer.ClipsDescendants = true
Instance.new("UICorner", SpeedRulerContainer).CornerRadius = UDim.new(0, 4)

local rulerLinesFrame = Instance.new("Frame", SpeedRulerContainer)
rulerLinesFrame.Size = UDim2.new(1, 0, 2, 0)
rulerLinesFrame.BackgroundTransparency = 1

for i = 0, 20 do
    local line = Instance.new("Frame", rulerLinesFrame)
    line.Size = UDim2.new(0, (i % 2 == 0) and math.floor(24 * scaleFactor) or math.floor(12 * scaleFactor), 0, 2)
    line.Position = UDim2.new(0.5, -(line.Size.X.Offset/2), 0, i * 14)
    line.BackgroundColor3 = GREEN
    line.BorderSizePixel = 0
end

local SpeedDisplay = Instance.new("TextLabel", SpeedControlFrame)
SpeedDisplay.Size = UDim2.new(1, -8, 0, math.floor(35 * scaleFactor))
SpeedDisplay.Position = UDim2.new(0, 4, 0, math.floor(205 * scaleFactor))
SpeedDisplay.BackgroundColor3 = GREEN_DARK
SpeedDisplay.Text = "100"
SpeedDisplay.TextColor3 = GREEN
SpeedDisplay.Font = Enum.Font.Code
SpeedDisplay.TextSize = math.floor(18 * scaleFactor)
Instance.new("UICorner", SpeedDisplay).CornerRadius = UDim.new(0, 4)
applyTextStroke(SpeedDisplay)

local DownBtn = Instance.new("TextButton", SpeedControlFrame)
DownBtn.Size = UDim2.new(1, -8, 0, math.floor(35 * scaleFactor))
DownBtn.Position = UDim2.new(0, 4, 1, math.floor(-39 * scaleFactor))
DownBtn.BackgroundColor3 = GREEN_DARK
DownBtn.Text = "v"
DownBtn.TextColor3 = GREEN
DownBtn.Font = Enum.Font.GothamBold
DownBtn.TextSize = math.floor(16 * scaleFactor)
Instance.new("UICorner", DownBtn).CornerRadius = UDim.new(0, 4)
applyTextStroke(DownBtn)

local function setTargetSpeed(newSpeed)
    targetSpeed = math.clamp(newSpeed, 10, maxSpeed)
    TweenService:Create(SpeedDisplay, TweenInfo.new(0.08), {Size = UDim2.new(1, -2, 0, math.floor(39 * scaleFactor))}):Play()
    task.delay(0.08, function()
        TweenService:Create(SpeedDisplay, TweenInfo.new(0.08), {Size = UDim2.new(1, -8, 0, math.floor(35 * scaleFactor))}):Play()
    end)
end

UpBtn.MouseButton1Click:Connect(function() setTargetSpeed(targetSpeed + 25) end)
DownBtn.MouseButton1Click:Connect(function() setTargetSpeed(targetSpeed - 25) end)

local BottomInfo = Instance.new("TextLabel", HUDGui)
BottomInfo.Size = UDim2.new(0, math.floor(400 * scaleFactor), 0, math.floor(30 * scaleFactor))
BottomInfo.Position = UDim2.new(0.5, math.floor(-200 * scaleFactor), 0.92, 0)
BottomInfo.BackgroundTransparency = 1
BottomInfo.Text = "BombMissile | ALT: 0 STUD | Pitch: 0°"
BottomInfo.TextColor3 = GREEN
BottomInfo.Font = Enum.Font.Code
BottomInfo.TextSize = math.floor(14 * scaleFactor)
applyTextStroke(BottomInfo)

---------------------------------------------------------
-- 4. CRASH UI & CONTROL LOGIC
---------------------------------------------------------
local CrashGui = Instance.new("ScreenGui")
CrashGui.Name = "CrashErrorUI"
CrashGui.ResetOnSpawn = false
CrashGui.Enabled = false
CrashGui.IgnoreGuiInset = true
CrashGui.DisplayOrder = 99999999
CrashGui.Parent = CoreGui

local BlackBackground = Instance.new("Frame", CrashGui)
BlackBackground.Size = UDim2.new(1, 0, 1, 0)
BlackBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BlackBackground.BorderSizePixel = 0

local NoiseFolder = Instance.new("Folder", BlackBackground)
local noiseElements = {}
for i = 1, 35 do
    local isDot = math.random() > 0.4
    local elem = isDot and Instance.new("Frame", NoiseFolder) or Instance.new("TextLabel", NoiseFolder)
    if isDot then
        local sz = math.random(2, 5)
        elem.Size = UDim2.new(0, sz, 0, sz)
        Instance.new("UICorner", elem).CornerRadius = UDim.new(1, 0)
    else
        elem.Text = "-"
        elem.Font = Enum.Font.Code
        elem.TextSize = math.random(14, 28)
        elem.BackgroundTransparency = 1
    end
    elem.BorderSizePixel = 0
    elem.Visible = false
    table.insert(noiseElements, {inst = elem, isText = not isDot})
end

local ErrorText = Instance.new("TextLabel", BlackBackground)
ErrorText.Size = UDim2.new(0, 400, 0, 60)
ErrorText.Position = UDim2.new(0.5, -200, 0.5, -30)
ErrorText.BackgroundTransparency = 1
ErrorText.Text = "Stupid Nigger"
ErrorText.TextColor3 = Color3.fromRGB(255, 30, 30)
ErrorText.Font = Enum.Font.Code
ErrorText.TextSize = math.floor(36 * scaleFactor)
ErrorText.ZIndex = 10
applyTextStroke(ErrorText)

local function triggerCrashEffect()
    HUDGui.Enabled = false
    CrashGui.Enabled = true
    if crashSound then crashSound:Play() end

    local noiseConn
    noiseConn = RunService.RenderStepped:Connect(function()
        ErrorText.TextTransparency = (math.sin(tick() * 15) > 0) and 0 or 0.8
        for _, item in ipairs(noiseElements) do
            if math.random() > 0.25 then
                item.inst.Visible = true
                item.inst.Position = UDim2.new(math.random(), 0, math.random(), 0)
                local alpha = math.random(60, 92) / 100
                if item.isText then
                    item.inst.TextColor3 = Color3.fromRGB(220, 220, 220)
                    item.inst.TextTransparency = alpha
                else
                    item.inst.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    item.inst.BackgroundTransparency = alpha
                end
            else
                item.inst.Visible = false
            end
        end
    end)

    task.delay(3, function()
        if noiseConn then noiseConn:Disconnect() end
        CrashGui.Enabled = false
        for _, item in ipairs(noiseElements) do item.inst.Visible = false end
    end)
end

local function setModelTransparency(model, transparency)
    if not model then return end
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") then
            v.LocalTransparencyModifier = transparency
        end
    end
end

createEvent.OnClientEvent:Connect(function(player, grabbedPart)
    if player == LocalPlayer or player == LocalPlayer.Name or (typeof(player) == "Instance" and player.Name == LocalPlayer.Name) then
        if grabbedPart then
            local model = grabbedPart:FindFirstAncestorOfClass("Model")
            if model and model.Name == "BombMissile" then pendingMissile = model end
        end
    end
end)

destroyEvent.OnClientEvent:Connect(function(player)
    if player == LocalPlayer or player == LocalPlayer.Name or (typeof(player) == "Instance" and player.Name == LocalPlayer.Name) then
        if pendingMissile and pendingMissile.Name == "BombMissile" and not isControlling then
            readyMissile = pendingMissile
            pendingMissile = nil
            StatusText.Text = "Đã nạp BombMissile!\nChuẩn bị khai hỏa."
            StatusText.TextColor3 = GREEN
            FireBtn.Visible = true
        end
    end
end)

local function stopMissileControl(wasExploded)
    isControlling = false
    HUDGui.Enabled = false
    MainFrame.Visible = true
    
    if flySound then flySound:Stop() end
    if controlConnection then controlConnection:Disconnect() controlConnection = nil end
    if wheelConnection then wheelConnection:Disconnect() wheelConnection = nil end
    if readyMissile then setModelTransparency(readyMissile, 0) end

    local myChar = LocalPlayer.Character
    if myChar then
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        if myRoot then myRoot.Anchored = false end
        if hum then 
            Camera.CameraType = Enum.CameraType.Custom
            Camera.CameraSubject = hum 
        end
    end
    
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    StatusText.Text = "Chưa nạp BombMissile"
    StatusText.TextColor3 = GREEN
    FireBtn.Visible = false
    readyMissile = nil

    if wasExploded then triggerCrashEffect() end
end

local function startMissileControl()
    if not readyMissile or not readyMissile.Parent or readyMissile.Name ~= "BombMissile" then return end
    local rootPart = readyMissile.PrimaryPart or readyMissile:FindFirstChildWhichIsA("BasePart")
    if not rootPart then return end

    isControlling = true
    MainFrame.Visible = false
    HUDGui.Enabled = true
    batteryTime = maxBattery
    currentSpeed = 100
    targetSpeed = 100

    if flySound then
        flySound.Volume = 0.3
        flySound:Play()
    end

    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myChar then
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if myRoot then myRoot.Anchored = true end
    end

    missileCFrame = CFrame.new(rootPart.Position, rootPart.Position + Camera.CFrame.LookVector)
    Camera.CameraType = Enum.CameraType.Scriptable

    wheelConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if isControlling and input.UserInputType == Enum.UserInputType.MouseWheel then
            setTargetSpeed(targetSpeed + (input.Position.Z > 0 and 20 or -20))
        end
    end)

    controlConnection = RunService.RenderStepped:Connect(function(dt)
        if not isControlling or not readyMissile or not readyMissile.Parent or not rootPart then
            stopMissileControl(true)
            return
        end

        setModelTransparency(readyMissile, 1)

        batteryTime = batteryTime - dt
        if batteryTime <= 0 then stopMissileControl(true) return end

        local battPercent = math.clamp(batteryTime / maxBattery, 0, 1)
        BatteryFill.Size = UDim2.new(1, -4, battPercent, -4)
        BatteryFill.Position = UDim2.new(0, 2, 1 - battPercent, 2)
        BatteryPercentText.Text = string.format("%d%%", math.floor(battPercent * 100))

        currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * math.min(dt * 8, 1)
        SpeedDisplay.Text = tostring(math.floor(currentSpeed))
        
        if flySound then
            local speedRatio = math.clamp(currentSpeed / maxSpeed, 0.1, 1)
            flySound.Volume = 0.2 + (speedRatio * 1.5)
            flySound.PlaybackSpeed = 0.8 + (speedRatio * 0.7)
        end

        local rulerOffset = (currentSpeed * 1.2) % 28
        rulerLinesFrame.Position = UDim2.new(0, 0, 0, -rulerOffset)

        PowerLabel.Text = string.format("PWR: %d%%", math.floor((currentSpeed / maxSpeed) * 100))
        RecDot.BackgroundTransparency = (math.sin(tick() * 6) > 0) and 0 or 0.8

        local look = Camera.CFrame.LookVector
        local angle = math.deg(math.atan2(-look.X, -look.Z))
        if angle < 0 then angle = angle + 360 end
        CompassRibbon.Position = UDim2.new(0, (-(angle / 360) * 800) + 140, 0, 0)

        scanLine.Position = UDim2.new(0, 0, (tick() * 0.4) % 1, 0)
        if math.random() > 0.85 then
            glitchBlock.Visible = true
            glitchBlock.Position = UDim2.new(math.random(), -75, math.random(), 0)
            glitchBlock.Size = UDim2.new(0, math.random(80, 200), 0, math.random(4, 15))
        else
            glitchBlock.Visible = false
        end

        local turnYaw, turnPitch = 0, 0
        if myHum and myHum.MoveDirection.Magnitude > 0 then
            local localMove = missileCFrame:VectorToObjectSpace(myHum.MoveDirection)
            turnYaw = -localMove.X * 1.8 * dt
            turnPitch = -localMove.Z * 1.8 * dt
        end

        local rotationChange = CFrame.Angles(turnPitch, turnYaw, 0)
        missileCFrame = CFrame.new(missileCFrame.Position) * (missileCFrame - missileCFrame.Position) * rotationChange
        
        local forwardVector = missileCFrame.LookVector
        local newPosition = missileCFrame.Position + (forwardVector * currentSpeed * dt)
        missileCFrame = CFrame.new(newPosition, newPosition + forwardVector)

        rootPart.CFrame = missileCFrame * CFrame.Angles(-math.pi / 2, 0, 0)
        rootPart.AssemblyLinearVelocity = forwardVector * currentSpeed
        Camera.CFrame = CFrame.new(missileCFrame.Position, missileCFrame.Position + forwardVector)

        BottomInfo.Text = string.format("BombMissile | ALT: %d STUD | Pitch: %d°", math.floor(rootPart.Position.Y), math.floor(math.deg(forwardVector.Y)))

        signalTimer = signalTimer + dt
        if signalTimer >= 0.3 then
            signalTimer = 0
            local activeBars = math.random(1, 5)
            for i = 1, 5 do signalBars[i].BackgroundTransparency = (i <= activeBars) and 0 or 0.75 end
            SignalValText.Text = tostring(math.random(15, 99))
        end

        if not isMobile then UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end
    end)
end

FireBtn.MouseButton1Click:Connect(function()
    if readyMissile then startMissileControl() end
end)
