--[[
    bonbon script V3.7 (RAGE AIMBOT EDITION - UPGRADED)
    Hệ thống Khóa cứng thực thụ - Tùy chọn Aim Part (Head / Torso / Auto) - Sticky Lock
    Phím tắt: Q (Aim), T (Wallbang), R (Đổi Aim Part), Right Shift (Ẩn/Hiện UI)
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- === CẤU HÌNH HỆ THỐNG ===
local IsAimEnabled = true
local IsWallbangEnabled = false
local MaxWhitelist = 10
local Whitelist = {}
local FOVRadius = 150
local CurrentTarget = nil

-- Chế độ Aim Target: 1 = Head, 2 = Torso, 3 = Auto (Quét đa bộ phận)
local AimTargetMode = 3
local ModeNames = {[1] = "Head Only", [2] = "Torso Only", [3] = "Auto Scan"}

local PriorityParts = {
    "Head",
    "UpperTorso",
    "Torso",
    "LowerTorso",
    "HumanoidRootPart"
}

-- === TẠO GIAO DIỆN (UI) ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BonbonScriptV37_RageAimbot"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Khung chính
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 390)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Tiêu đề
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "bonbon RAGE AIMBOT V3.7"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.TextSize = 18
Title.Font = Enum.Font.SourceSansBold
Title.BackgroundColor3 = Color3.fromRGB(40, 5, 5)
Title.Parent = MainFrame

-- Trạng thái Aim / Target Name
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 45)
StatusLabel.Text = "Target: None"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 15
StatusLabel.Parent = MainFrame

-- Nút Bật/Tắt Aim
local ToggleAimBtn = Instance.new("TextButton")
ToggleAimBtn.Size = UDim2.new(0.45, 0, 0, 35)
ToggleAimBtn.Position = UDim2.new(0, 10, 0, 80)
ToggleAimBtn.Text = "Aimbot: ON (Q)"
ToggleAimBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
ToggleAimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleAimBtn.Font = Enum.Font.SourceSansBold
ToggleAimBtn.TextSize = 13
ToggleAimBtn.Parent = MainFrame

-- Nút Bật/Tắt Xuyên tường
local ToggleWallBtn = Instance.new("TextButton")
ToggleWallBtn.Size = UDim2.new(0.45, 0, 0, 35)
ToggleWallBtn.Position = UDim2.new(0.55, 0, 0, 80)
ToggleWallBtn.Text = "Wallbang: OFF (T)"
ToggleWallBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
ToggleWallBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleWallBtn.Font = Enum.Font.SourceSansBold
ToggleWallBtn.TextSize = 13
ToggleWallBtn.Parent = MainFrame

-- Nút Chọn Aim Part (Head / Torso / Auto)
local TogglePartBtn = Instance.new("TextButton")
TogglePartBtn.Size = UDim2.new(1, -20, 0, 35)
TogglePartBtn.Position = UDim2.new(0, 10, 0, 122)
TogglePartBtn.Text = "Target Part: Auto Scan (R)"
TogglePartBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 120)
TogglePartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TogglePartBtn.Font = Enum.Font.SourceSansBold
TogglePartBtn.TextSize = 14
TogglePartBtn.Parent = MainFrame

-- Thanh trượt/Nhập FOV
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(1, -20, 0, 20)
FOVLabel.Position = UDim2.new(0, 10, 0, 165)
FOVLabel.Text = "FOV Size: " .. FOVRadius
FOVLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVLabel.BackgroundTransparency = 1
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.Parent = MainFrame

local FOVSlider = Instance.new("TextBox")
FOVSlider.Size = UDim2.new(1, -20, 0, 25)
FOVSlider.Position = UDim2.new(0, 10, 0, 185)
FOVSlider.Text = tostring(FOVRadius)
FOVSlider.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
FOVSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVSlider.PlaceholderText = "Nhập số FOV (Ví dụ: 150)"
FOVSlider.Parent = MainFrame

-- Khu vực Whitelist
local WhitelistTitle = Instance.new("TextLabel")
WhitelistTitle.Size = UDim2.new(0, 100, 0, 30)
WhitelistTitle.Position = UDim2.new(0, 10, 0, 220)
WhitelistTitle.Text = "Whitelist"
WhitelistTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
WhitelistTitle.TextXAlignment = Enum.TextXAlignment.Left
WhitelistTitle.BackgroundTransparency = 1
WhitelistTitle.Font = Enum.Font.SourceSansBold
WhitelistTitle.TextSize = 16
WhitelistTitle.Parent = MainFrame

local AddWhitelistBtn = Instance.new("TextButton")
AddWhitelistBtn.Size = UDim2.new(0, 30, 0, 30)
AddWhitelistBtn.Position = UDim2.new(0, 90, 0, 220)
AddWhitelistBtn.Text = "+"
AddWhitelistBtn.TextSize = 20
AddWhitelistBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
AddWhitelistBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AddWhitelistBtn.Parent = MainFrame

-- Danh sách hiển thị Whitelist
local WhitelistListLabel = Instance.new("TextLabel")
WhitelistListLabel.Size = UDim2.new(1, -20, 0, 90)
WhitelistListLabel.Position = UDim2.new(0, 10, 0, 255)
WhitelistListLabel.Text = "Chưa có ai trong danh sách"
WhitelistListLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
WhitelistListLabel.TextYAlignment = Enum.TextYAlignment.Top
WhitelistListLabel.TextXAlignment = Enum.TextXAlignment.Left
WhitelistListLabel.BackgroundTransparency = 1
WhitelistListLabel.TextWrapped = true
WhitelistListLabel.Parent = MainFrame

-- Nhãn hướng dẫn phím ẩn UI
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -20, 0, 15)
InfoLabel.Position = UDim2.new(0, 10, 0, 365)
InfoLabel.Text = "Ấn [Right Shift] để Ẩn / Hiện menu"
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.SourceSansItalic
InfoLabel.TextSize = 11
InfoLabel.Parent = MainFrame

-- === VÒNG TRÒN FOV ===
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Thickness = 1.8
FOVCircle.Filled = false
FOVCircle.Transparency = 0.9
FOVCircle.Visible = true
FOVCircle.Radius = FOVRadius

-- === LOGIC HỆ THỐNG AIMBOT ===

local function updateWhitelistUI()
    if #Whitelist == 0 then
        WhitelistListLabel.Text = "Chưa có ai trong danh sách"
    else
        WhitelistListLabel.Text = table.concat(Whitelist, ", ")
    end
end

local function isWhitelisted(player)
    for _, name in ipairs(Whitelist) do
        if string.lower(player.Name) == string.lower(name) or string.lower(player.DisplayName) == string.lower(name) then
            return true
        end
    end
    return false
end

-- Kiểm tra vật cản
local function isPartVisible(part, character)
    if IsWallbangEnabled then return true end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.IgnoreWater = true
    
    local rayDirection = part.Position - Camera.CFrame.Position
    local raycastResult = workspace:Raycast(Camera.CFrame.Position, rayDirection, raycastParams)
    
    if not raycastResult or raycastResult.Instance:IsDescendantOf(character) then
        return true
    end
    return false
end

-- Tìm bộ phận cần ngắm theo chế độ đã chọn
local function getVisiblePart(character)
    if AimTargetMode == 1 then
        -- Chế độ Head Only
        local head = character:FindFirstChild("Head")
        if head and isPartVisible(head, character) then
            return head
        end
    elseif AimTargetMode == 2 then
        -- Chế độ Torso Only
        local torsoParts = {"UpperTorso", "Torso", "HumanoidRootPart"}
        for _, name in ipairs(torsoParts) do
            local part = character:FindFirstChild(name)
            if part and isPartVisible(part, character) then
                return part
            end
        end
    else
        -- Chế độ Auto Scan (Ưu tiên Head -> Torso)
        for _, partName in ipairs(PriorityParts) do
            local part = character:FindFirstChild(partName)
            if part and isPartVisible(part, character) then
                return part
            end
        end
    end
    return nil
end

-- Tìm mục tiêu tối ưu nhất trong tầm FOV
local function getBestTarget()
    if CurrentTarget and CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("Humanoid") then
        if CurrentTarget.Character.Humanoid.Health > 0 and not isWhitelisted(CurrentTarget) then
            local targetPart = getVisiblePart(CurrentTarget.Character)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distance <= FOVRadius then
                        return CurrentTarget, targetPart
                    end
                end
            end
        end
    end

    local closestPlayer = nil
    local bestPart = nil
    local shortestDistance = FOVRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            if player.Character.Humanoid.Health > 0 and not isWhitelisted(player) then
                local visiblePart = getVisiblePart(player.Character)
                
                if visiblePart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(visiblePart.Position)
                    
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = player
                            bestPart = visiblePart
                        end
                    end
                end
            end
        end
    end
    return closestPlayer, bestPart
end

-- === ĐĂNG KÝ SỰ KIỆN GIAO DIỆN ===

local function toggleAim()
    IsAimEnabled = not IsAimEnabled
    if IsAimEnabled then
        ToggleAimBtn.Text = "Aimbot: ON (Q)"
        ToggleAimBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        FOVCircle.Visible = true
    else
        ToggleAimBtn.Text = "Aimbot: OFF (Q)"
        ToggleAimBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        FOVCircle.Visible = false
        StatusLabel.Text = "Target: None"
        CurrentTarget = nil
    end
end

local function toggleWallbang()
    IsWallbangEnabled = not IsWallbangEnabled
    if IsWallbangEnabled then
        ToggleWallBtn.Text = "Wallbang: ON (T)"
        ToggleWallBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        ToggleWallBtn.Text = "Wallbang: OFF (T)"
        ToggleWallBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    end
end

local function toggleAimPart()
    AimTargetMode = (AimTargetMode % 3) + 1
    TogglePartBtn.Text = "Target Part: " .. ModeNames[AimTargetMode] .. " (R)"
    CurrentTarget = nil
end

ToggleAimBtn.MouseButton1Click:Connect(toggleAim)
ToggleWallBtn.MouseButton1Click:Connect(toggleWallbang)
TogglePartBtn.MouseButton1Click:Connect(toggleAimPart)

FOVSlider.FocusLost:Connect(function(enterPressed)
    local num = tonumber(FOVSlider.Text)
    if num then
        FOVRadius = math.clamp(num, 10, 1000)
        FOVSlider.Text = tostring(FOVRadius)
        FOVLabel.Text = "FOV Size: " .. FOVRadius
        FOVCircle.Radius = FOVRadius
    else
        FOVSlider.Text = tostring(FOVRadius)
    end
end)

AddWhitelistBtn.MouseButton1Click:Connect(function()
    local oldText = AddWhitelistBtn.Text
    AddWhitelistBtn.Text = "..."
    
    local tempTextBox = Instance.new("TextBox")
    tempTextBox.Size = UDim2.new(1, -20, 0, 30)
    tempTextBox.Position = UDim2.new(0, 10, 0, 220)
    tempTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    tempTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    tempTextBox.PlaceholderText = "Nhập tên và Enter..."
    tempTextBox.Parent = MainFrame
    
    tempTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and tempTextBox.Text ~= "" then
            if #Whitelist < MaxWhitelist then
                table.insert(Whitelist, tempTextBox.Text)
                updateWhitelistUI()
            end
        end
        tempTextBox:Destroy()
        AddWhitelistBtn.Text = oldText
    end)
    tempTextBox:CaptureFocus()
end)

-- SỰ KIỆN NHẤN PHÍM TẮT (PC)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
        return
    end

    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        toggleAim()
    elseif input.KeyCode == Enum.KeyCode.T then
        toggleWallbang()
    elseif input.KeyCode == Enum.KeyCode.R then
        toggleAimPart()
    end
end)

-- === VÒNG LẶP KHÓA TÂM SIÊU TỐC (RAGE ACTIVE) ===
RunService.RenderStepped:Connect(function()
    if IsAimEnabled and ScreenGui.Enabled then
        FOVCircle.Visible = true
        FOVCircle.Position = UserInputService:GetMouseLocation()
    else
        FOVCircle.Visible = false
    end

    if IsAimEnabled then
        local target, targetPart = getBestTarget()
        
        if target and targetPart then
            CurrentTarget = target
            StatusLabel.Text = "Target: LOCK -> " .. targetPart.Name
            StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        else
            CurrentTarget = nil
            StatusLabel.Text = "Target: None"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        end
    end
end)