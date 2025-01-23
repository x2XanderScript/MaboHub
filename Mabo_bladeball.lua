local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui

-- กำหนดขนาดของกรอบ UI
local notificationFrame = Instance.new("Frame")
notificationFrame.Size = UDim2.new(0, 250, 0, 100)  -- ขนาดกรอบ
notificationFrame.Position = UDim2.new(1, -260, 0, 10)  -- อยู่ที่ขวาล่าง
notificationFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
notificationFrame.BackgroundTransparency = 0.7
notificationFrame.Parent = screenGui

-- โลโก้ (ImageLabel)
local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 30, 0, 30)
logo.Position = UDim2.new(0, 10, 0, 10)
logo.Image = "rbxassetid://72537090915907"  -- ใส่ Asset ID ของโลโก้วงกลมที่คุณต้องการ
logo.BackgroundTransparency = 1
logo.Parent = notificationFrame

-- ชื่อ
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 200, 0, 25)
titleLabel.Position = UDim2.new(0, 50, 0, 10)
titleLabel.Text = "MaboHub | BladeBall"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundTransparency = 1
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = notificationFrame

-- ข้อความ
local descriptionLabel = Instance.new("TextLabel")
descriptionLabel.Size = UDim2.new(0, 200, 0, 20)
descriptionLabel.Position = UDim2.new(0, 50, 0, 35)
descriptionLabel.Text = "Running..."
descriptionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
descriptionLabel.BackgroundTransparency = 1
descriptionLabel.TextSize = 14
descriptionLabel.Font = Enum.Font.SourceSans
descriptionLabel.Parent = notificationFrame

-- ปุ่ม "On"
local onButton = Instance.new("TextButton")
onButton.Size = UDim2.new(0, 90, 0, 30)
onButton.Position = UDim2.new(0, 50, 0, 60)
onButton.Text = "On"
onButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
onButton.TextColor3 = Color3.fromRGB(0, 0, 0)
onButton.Font = Enum.Font.SourceSans
onButton.TextSize = 14
onButton.Parent = notificationFrame

-- ปุ่ม "Off"
local offButton = Instance.new("TextButton")
offButton.Size = UDim2.new(0, 90, 0, 30)
offButton.Position = UDim2.new(0, 150, 0, 60)
offButton.Text = "Off"
offButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
offButton.TextColor3 = Color3.fromRGB(255, 255, 255)
offButton.Font = Enum.Font.SourceSans
offButton.TextSize = 14
offButton.Parent = notificationFrame

-- ตั้งค่าการเชื่อมต่อกับ RunService
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local vim = game:GetService("VirtualInputManager")
local ballFolder = workspace:WaitForChild("Balls")

-- ตั้งค่าค่าคงที่
local PRESS_KEY = Enum.KeyCode.F -- ปุ่มสำหรับตีลูกบอล
local PREDICTION_THRESHOLD = 0.4 -- เกณฑ์เวลาสำหรับการตี (ลดให้ต่ำลงเพื่อเพิ่มความเร็ว)
local MIN_REACTION_TIME = 0.001 -- ลดหน่วงเวลาการกดปุ่ม

-- ตัวแปร
local lastBallPressed, isKeyPressed = nil, false
local isActive = false

-- คำนวณเวลาในการชน
local function calculatePredictionTime(ball, player)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local distance = (ball.Position - rootPart.Position).Magnitude
        local relativeVelocity = (ball.Velocity - rootPart.Velocity).Magnitude
        if relativeVelocity > 0 then
            return distance / relativeVelocity
        end
    end
    return math.huge
end

-- ตรวจสอบและตีลูกบอลเมื่อใกล้ผู้เล่น
local function checkProximityToPlayer(ball, player)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local predictionTime = calculatePredictionTime(ball, player)
    local realBallAttribute = ball:GetAttribute("realBall")
    local target = ball:GetAttribute("target")

    if predictionTime <= PREDICTION_THRESHOLD and realBallAttribute and target == player.Name and not isKeyPressed then
        -- ตีลูกบอลทันที
        vim:SendKeyEvent(true, PRESS_KEY, false, nil)
        task.wait(MIN_REACTION_TIME) -- ลดหน่วงเวลาการกดปุ่ม
        vim:SendKeyEvent(false, PRESS_KEY, false, nil)
        lastBallPressed = ball
        isKeyPressed = true
    elseif lastBallPressed == ball and (predictionTime > PREDICTION_THRESHOLD or not realBallAttribute or target ~= player.Name) then
        -- รีเซ็ตสถานะ
        isKeyPressed = false
    end
end

-- ตรวจสอบลูกบอลใน BallFolder
local function checkBallsProximity()
    local player = players.LocalPlayer
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        for _, ball in ipairs(ballFolder:GetChildren()) do
            checkProximityToPlayer(ball, player)
        end
    end
end

-- ฟังก์ชันสำหรับปุ่ม On
onButton.MouseButton1Click:Connect(function()
    descriptionLabel.Text = "Script is running..."
    -- เปิดสคริปต์การตีลูกบอล
    isActive = true
    runService.Heartbeat:Connect(checkBallsProximity)  -- เชื่อมต่อ RunService เมื่อเปิด
end)

-- ฟังก์ชันสำหรับปุ่ม Off
offButton.MouseButton1Click:Connect(function()
    descriptionLabel.Text = "Script stopped."
    -- หยุดสคริปต์การตีลูกบอล
    isActive = false
    lastBallPressed = nil
    isKeyPressed = false
end)