local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer

local blob2 = "\u{001E}" -- invisible character
local blob = "\u{000D}" -- newline

local function chatMessage(str)
    str = tostring(str)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.TextChannels.RBXGeneral:SendAsync(str)
    else
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
    end
end

-----------------------------------------------------------
-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerCrasherGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 240)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(40, 40, 50)
UIStroke.Transparency = 0.6
UIStroke.Parent = MainFrame

local Shadow = Instance.new("UIStroke")
Shadow.Thickness = 4
Shadow.Color = Color3.fromRGB(0, 0, 0)
Shadow.Transparency = 0.8
Shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
Shadow.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Server Control"
TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 22
TitleLabel.Parent = TitleBar

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 36, 0, 36)
MinimizeButton.Position = UDim2.new(1, -80, 0, 2)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
MinimizeButton.Text = "–"
MinimizeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextSize = 24
MinimizeButton.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 36, 0, 36)
CloseButton.Position = UDim2.new(1, -38, 0, 2)
CloseButton.BackgroundColor3 = Color3.fromRGB(50, 35, 35)
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 120, 120)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 24
CloseButton.Parent = TitleBar

for _, btn in pairs({MinimizeButton, CloseButton}) do
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
end

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 100, 1, -40)
TabBar.Position = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local TabBarCorner = Instance.new("UICorner")
TabBarCorner.CornerRadius = UDim.new(0, 12)
TabBarCorner.Parent = TabBar

local MainTabButton = Instance.new("TextButton")
MainTabButton.Size = UDim2.new(1, -10, 0, 50)
MainTabButton.Position = UDim2.new(0, 5, 0, 10)
MainTabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
MainTabButton.Text = "Main"
MainTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MainTabButton.Font = Enum.Font.SourceSansSemibold
MainTabButton.TextSize = 18
MainTabButton.TextXAlignment = Enum.TextXAlignment.Center
MainTabButton.Parent = TabBar

local ChatTabButton = Instance.new("TextButton")
ChatTabButton.Size = UDim2.new(1, -10, 0, 50)
ChatTabButton.Position = UDim2.new(0, 5, 0, 70)
ChatTabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
ChatTabButton.Text = "Chat"
ChatTabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
ChatTabButton.Font = Enum.Font.SourceSansSemibold
ChatTabButton.TextSize = 18
ChatTabButton.TextXAlignment = Enum.TextXAlignment.Center
ChatTabButton.Parent = TabBar

local SettingsTabButton = Instance.new("TextButton")
SettingsTabButton.Size = UDim2.new(1, -10, 0, 50)
SettingsTabButton.Position = UDim2.new(0, 5, 0, 130)
SettingsTabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
SettingsTabButton.Text = "Settings"
SettingsTabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
SettingsTabButton.Font = Enum.Font.SourceSansSemibold
SettingsTabButton.TextSize = 18
SettingsTabButton.TextXAlignment = Enum.TextXAlignment.Center
SettingsTabButton.Parent = TabBar

for _, btn in pairs({MainTabButton, ChatTabButton, SettingsTabButton}) do
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
end

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(0, 290, 1, -50)
ContentArea.Position = UDim2.new(0, 110, 0, 45)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local MainFrameContent = Instance.new("Frame")
MainFrameContent.Name = "MainFrameContent"
MainFrameContent.Size = UDim2.new(1, 0, 1, 0)
MainFrameContent.BackgroundTransparency = 1
MainFrameContent.Parent = ContentArea
MainFrameContent.Visible = true

local ChatFrame = Instance.new("Frame")
ChatFrame.Name = "ChatFrame"
ChatFrame.Size = UDim2.new(1, 0, 1, 0)
ChatFrame.BackgroundTransparency = 1
ChatFrame.Parent = ContentArea
ChatFrame.Visible = false

local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(1, 0, 1, 0)
SettingsFrame.BackgroundTransparency = 1
SettingsFrame.Parent = ContentArea
SettingsFrame.Visible = false

local LagServerButton = Instance.new("TextButton")
LagServerButton.Size = UDim2.new(1, -20, 0, 50)
LagServerButton.Position = UDim2.new(0, 10, 0, 20)
LagServerButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
LagServerButton.Text = "Lag Server: OFF"
LagServerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LagServerButton.Font = Enum.Font.SourceSansSemibold
LagServerButton.TextSize = 20
LagServerButton.Parent = MainFrameContent

local AnnoyServerButton = Instance.new("TextButton")
AnnoyServerButton.Size = UDim2.new(1, -20, 0, 50)
AnnoyServerButton.Position = UDim2.new(0, 10, 0, 80)
AnnoyServerButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
AnnoyServerButton.Text = "Annoy Server: OFF"
AnnoyServerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AnnoyServerButton.Font = Enum.Font.SourceSansSemibold
AnnoyServerButton.TextSize = 20
AnnoyServerButton.Parent = MainFrameContent

local ChatClearButton = Instance.new("TextButton")
ChatClearButton.Size = UDim2.new(1, -20, 0, 50)
ChatClearButton.Position = UDim2.new(0, 10, 0, 20)
ChatClearButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ChatClearButton.Text = "Clear Chat"
ChatClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ChatClearButton.Font = Enum.Font.SourceSansSemibold
ChatClearButton.TextSize = 20
ChatClearButton.Parent = ChatFrame

for _, btn in pairs({LagServerButton, AnnoyServerButton, ChatClearButton}) do
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(70, 70, 80)
    stroke.Parent = btn
end

local NotificationToggle = Instance.new("TextButton")
NotificationToggle.Size = UDim2.new(1, -20, 0, 40)
NotificationToggle.Position = UDim2.new(0, 10, 0, 20)
NotificationToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
NotificationToggle.Text = "Notifications: ON"
NotificationToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
NotificationToggle.Font = Enum.Font.SourceSansSemibold
NotificationToggle.TextSize = 18
NotificationToggle.Parent = SettingsFrame

local NotificationCorner = Instance.new("UICorner")
NotificationCorner.CornerRadius = UDim.new(0, 10)
NotificationCorner.Parent = NotificationToggle

local NotificationStroke = Instance.new("UIStroke")
NotificationStroke.Thickness = 1
NotificationStroke.Color = Color3.fromRGB(70, 70, 80)
NotificationStroke.Parent = NotificationToggle

-----------------------------------------------------------
-- Draggable Functionality
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

local minimized = false
local expandedSize = UDim2.new(0, 400, 0, 240)
local minimizedSize = UDim2.new(0, 400, 0, 40)

MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TabBar.Visible = false
        ContentArea.Visible = false
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(MainFrame, tweenInfo, {Size = minimizedSize})
        tween:Play()
        tween.Completed:Connect(function()
            MinimizeButton.Text = "+"
        end)
    else
        MinimizeButton.TextTransparency = 1
        MinimizeButton.BackgroundTransparency = 1
        CloseButton.TextTransparency = 1
        CloseButton.BackgroundTransparency = 1
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(MainFrame, tweenInfo, {Size = expandedSize})
        tween:Play()
        tween.Completed:Connect(function()
            TabBar.Visible = true
            ContentArea.Visible = true
            MinimizeButton.Text = "–"
            local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            TweenService:Create(MinimizeButton, fadeInfo, {TextTransparency = 0, BackgroundTransparency = 0}):Play()
            TweenService:Create(CloseButton, fadeInfo, {TextTransparency = 0, BackgroundTransparency = 0}):Play()
        end)
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local function setTabActive(tabButton, frame)
    MainFrameContent.Visible = frame == MainFrameContent
    ChatFrame.Visible = frame == ChatFrame
    SettingsFrame.Visible = frame == SettingsFrame
    MainTabButton.BackgroundColor3 = frame == MainFrameContent and Color3.fromRGB(45, 45, 50) or Color3.fromRGB(35, 35, 40)
    ChatTabButton.BackgroundColor3 = frame == ChatFrame and Color3.fromRGB(45, 45, 50) or Color3.fromRGB(35, 35, 40)
    SettingsTabButton.BackgroundColor3 = frame == SettingsFrame and Color3.fromRGB(45, 45, 50) or Color3.fromRGB(35, 35, 40)
    MainTabButton.TextColor3 = frame == MainFrameContent and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    ChatTabButton.TextColor3 = frame == ChatFrame and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    SettingsTabButton.TextColor3 = frame == SettingsFrame and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
end

MainTabButton.MouseButton1Click:Connect(function()
    setTabActive(MainTabButton, MainFrameContent)
end)

ChatTabButton.MouseButton1Click:Connect(function()
    setTabActive(ChatTabButton, ChatFrame)
end)

SettingsTabButton.MouseButton1Click:Connect(function()
    setTabActive(SettingsTabButton, SettingsFrame)
end)

for _, btn in pairs({MainTabButton, ChatTabButton, SettingsTabButton}) do
    btn.MouseEnter:Connect(function()
        if btn.BackgroundColor3 ~= Color3.fromRGB(45, 45, 50) then
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.BackgroundColor3 ~= Color3.fromRGB(45, 45, 50) then
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        end
    end)
end

ChatClearButton.MouseButton1Click:Connect(function()
    chatMessage(blob2 .. string.rep(blob, 100) .. blob2)
end)

-----------------------------------------------------------
-- Spectate Setup
local SpectateGui = Instance.new("ScreenGui")
SpectateGui.Name = "Spectate"
SpectateGui.Parent = localPlayer:WaitForChild("PlayerGui")
SpectateGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SpectateGui.ResetOnSpawn = false

local SpectateFrame = Instance.new("Frame")
SpectateFrame.Name = "SpectateFrame"
SpectateFrame.Parent = SpectateGui
SpectateFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SpectateFrame.BackgroundTransparency = 1
SpectateFrame.BorderSizePixel = 0
SpectateFrame.Position = UDim2.new(0, 0, 0.8, 0)
SpectateFrame.Size = UDim2.new(1, 0, 0.2, 0)
SpectateFrame.Visible = false

local LeftButton = Instance.new("TextButton")
LeftButton.Name = "Left"
LeftButton.Parent = SpectateFrame
LeftButton.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
LeftButton.BackgroundTransparency = 0.25
LeftButton.BorderSizePixel = 0
LeftButton.Position = UDim2.new(0.183150187, 0, 0.238433674, 0)
LeftButton.Size = UDim2.new(0.0688644722, 0, 0.514322877, 0)
LeftButton.Font = Enum.Font.FredokaOne
LeftButton.Text = "<"
LeftButton.TextColor3 = Color3.fromRGB(0, 0, 0)
LeftButton.TextScaled = true

local RightButton = Instance.new("TextButton")
RightButton.Name = "Right"
RightButton.Parent = SpectateFrame
RightButton.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
RightButton.BackgroundTransparency = 0.25
RightButton.BorderSizePixel = 0
RightButton.Position = UDim2.new(0.747985363, 0, 0.238433674, 0)
RightButton.Size = UDim2.new(0.0688644722, 0, 0.514322877, 0)
RightButton.Font = Enum.Font.FredokaOne
RightButton.Text = ">"
RightButton.TextColor3 = Color3.fromRGB(0, 0, 0)
RightButton.TextScaled = true

local PlayerDisplay = Instance.new("TextLabel")
PlayerDisplay.Name = "PlayerDisplay"
PlayerDisplay.Parent = SpectateFrame
PlayerDisplay.BackgroundTransparency = 1
PlayerDisplay.Position = UDim2.new(0.252014756, 0, 0.238433674, 0)
PlayerDisplay.Size = UDim2.new(0.495970696, 0, 0.514322877, 0)
PlayerDisplay.Font = Enum.Font.FredokaOne
PlayerDisplay.Text = "<player>"
PlayerDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerDisplay.TextScaled = true

local PlayerIndex = Instance.new("NumberValue")
PlayerIndex.Name = "PlayerIndex"
PlayerIndex.Parent = SpectateFrame
PlayerIndex.Value = 1

local UIStroke1 = Instance.new("UIStroke")
UIStroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke1.Thickness = 5
UIStroke1.Parent = LeftButton

local UIStroke2 = Instance.new("UIStroke")
UIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke2.Thickness = 5
UIStroke2.Parent = RightButton

local UIStroke3 = Instance.new("UIStroke")
UIStroke3.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
UIStroke3.Thickness = 5
UIStroke3.Parent = PlayerDisplay

local allPlayers = {}
local currentSpectateTarget = nil

local function updatePlayers(leavingPlayer)
    local oldPlayers = allPlayers
    allPlayers = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            table.insert(allPlayers, plr)
        end
    end
    
    if spectating and #allPlayers > 0 then
        if leavingPlayer and leavingPlayer == currentSpectateTarget then
            local oldIndex = PlayerIndex.Value
            PlayerIndex.Value = math.clamp(oldIndex, 1, #allPlayers)
            currentSpectateTarget = allPlayers[PlayerIndex.Value]
        else
            local newIndex = table.find(allPlayers, currentSpectateTarget)
            if newIndex then
                PlayerIndex.Value = newIndex
            else
                PlayerIndex.Value = math.clamp(PlayerIndex.Value, 1, #allPlayers)
                currentSpectateTarget = allPlayers[PlayerIndex.Value]
            end
        end
    elseif #allPlayers == 0 then
        PlayerIndex.Value = 1
        currentSpectateTarget = nil
    elseif PlayerIndex.Value > #allPlayers then
        PlayerIndex.Value = #allPlayers
        currentSpectateTarget = allPlayers[PlayerIndex.Value]
    end
end
updatePlayers()

Players.PlayerAdded:Connect(function() updatePlayers() end)
Players.PlayerRemoving:Connect(function(player) updatePlayers(player) end)

local function onPress(skip)
    if #allPlayers == 0 then return end
    local newIndex = PlayerIndex.Value + skip
    if newIndex > #allPlayers then
        PlayerIndex.Value = 1
    elseif newIndex < 1 then
        PlayerIndex.Value = #allPlayers
    else
        PlayerIndex.Value = newIndex
    end
    currentSpectateTarget = allPlayers[PlayerIndex.Value]
end

LeftButton.MouseButton1Click:Connect(function() onPress(-1) end)
RightButton.MouseButton1Click:Connect(function() onPress(1) end)
LeftButton.TouchTap:Connect(function() onPress(-1) end)
RightButton.TouchTap:Connect(function() onPress(1) end)

local cam = workspace.CurrentCamera
local spectating = false

RunService.RenderStepped:Connect(function()
    if spectating and #allPlayers > 0 then
        local targetPlayer = allPlayers[PlayerIndex.Value]
        if targetPlayer and targetPlayer.Character then
            cam.CameraSubject = targetPlayer.Character:WaitForChild("Humanoid", 5)
            PlayerDisplay.Text = targetPlayer.Name
            currentSpectateTarget = targetPlayer
        end
    elseif not spectating then
        if localPlayer.Character then
            cam.CameraSubject = localPlayer.Character:WaitForChild("Humanoid", 5)
            PlayerDisplay.Text = localPlayer.Name
        end
    end
end)

local function updateStrokeThickness()
    local screenSize = workspace.CurrentCamera.ViewportSize
    local scaleFactor = screenSize.X / 1920
    UIStroke1.Thickness = 5 * scaleFactor * 1.25
    UIStroke2.Thickness = 5 * scaleFactor * 1.25
    UIStroke3.Thickness = 5 * scaleFactor * 1.25
end
RunService.RenderStepped:Connect(updateStrokeThickness)

-----------------------------------------------------------
-- Lag Server Functionality
local lagToggled = false
local lagEnabled = false
local ragdollConnection
local lastModifiedUsername
local lagButtonCooldown = false
local lagCooldownTime = 10
local knifeEquipConnection

local ragdollEvent = ReplicatedStorage:FindFirstChild("RagdollEvent")
local unragdollEvent = ReplicatedStorage:FindFirstChild("UnragdollEvent")
local ToggleDisallowEvent = ReplicatedStorage:WaitForChild("ToggleDisallowEvent")
local ModifyUserEvent = ReplicatedStorage:WaitForChild("ModifyUserEvent")
local ModifyUsername_upvr = ReplicatedStorage:WaitForChild("ModifyUsername")

local function setVelocityToZero(part)
    if part then
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end
end

local function teleportToKnife()
    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        rootPart.CFrame = CFrame.new(-62.9152107, 4.01578045, -65.7834625, 0.707134247, 0, 0.707079291, 0, 1, 0, -0.707079291, 0, 0.707134247)
    end
end

local function activateProximityPrompt()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local promptPos = obj.Parent.Position
            if (promptPos - Vector3.new(-62.9152107, 4.01578045, -65.7834625)).Magnitude < 5 then
                fireproximityprompt(obj)
                break
            end
        end
    end
end

local function isKnifeInInventory()
    for _, item in ipairs(localPlayer.Backpack:GetChildren()) do
        if item.Name == "Knife" then
            return true
        end
    end
    return localPlayer.Character and localPlayer.Character:FindFirstChild("Knife") ~= nil
end

local function toggleKnifeEquip()
    if not lagToggled or not isKnifeInInventory() then return end
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local knife = localPlayer.Backpack:FindFirstChild("Knife") or (character and character:FindFirstChild("Knife"))
    
    if knife and humanoid then
        if knife.Parent == localPlayer.Backpack then
            humanoid:EquipTool(knife)
        else
            humanoid:UnequipTools()
        end
    end
end

local function loopKnifeToggle()
    while lagToggled and isKnifeInInventory() do
        toggleKnifeEquip()
        wait(0.1)
    end
end

local function toggleRagdoll()
    local character = localPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if lagEnabled then
        updatePlayers()
        if #allPlayers > 0 then
            spectating = true
            SpectateFrame.Visible = true
            PlayerIndex.Value = 1
            currentSpectateTarget = allPlayers[PlayerIndex.Value]
            wait(1)
        end

        if lagToggled then
            lastModifiedUsername = "elijahcole2004"
            ModifyUsername_upvr:FireServer("elijahcole2004")
            wait(1)
        else
            ToggleDisallowEvent:FireServer()
            ModifyUserEvent:FireServer(localPlayer.Name)
            wait(1)
            ToggleDisallowEvent:FireServer()
        end

        -- Teleport to knife proximity prompt and obtain knife
        teleportToKnife()
        wait(0.5)
        activateProximityPrompt()
        wait(0.5)

        -- Teleport to hidden spot after obtaining knife
        if rootPart then
            rootPart.CFrame = CFrame.new(4224, 26, 62)
            wait(0.5)
        end

        if humanoid then humanoid.PlatformStand = true end
        if rootPart then rootPart.Anchored = true end
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Anchored = true
                setVelocityToZero(part)
            end
        end

        ragdollEvent:FireServer()
        wait(0.2)
        local oldCFrame = rootPart.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        local offset = 100000
        ragdollConnection = RunService.Heartbeat:Connect(function()
            if not character or not lagEnabled then return end
            local parts = {
                Head = oldCFrame * CFrame.new(0, 0, -offset/2),
                UpperTorso = oldCFrame * CFrame.new(0, offset, 0),
                LowerTorso = oldCFrame * CFrame.new(0, -offset/2, 0),
                RightUpperArm = oldCFrame * CFrame.new(offset, 0, 0),
                RightLowerArm = oldCFrame * CFrame.new(offset*1.5, 0, 0),
                RightHand = oldCFrame * CFrame.new(offset*2, 0, 0),
                LeftUpperArm = oldCFrame * CFrame.new(-offset, 0, 0),
                LeftLowerArm = oldCFrame * CFrame.new(-offset*1.5, 0, 0),
                LeftHand = oldCFrame * CFrame.new(-offset*2, 0, 0),
                RightUpperLeg = oldCFrame * CFrame.new(offset/2, -offset, 0),
                RightLowerLeg = oldCFrame * CFrame.new(offset/2, -offset*1.5, 0),
                RightFoot = oldCFrame * CFrame.new(offset/2, -offset*2, 0),
                LeftUpperLeg = oldCFrame * CFrame.new(-offset/2, -offset, 0),
                LeftLowerLeg = oldCFrame * CFrame.new(-offset/2, -offset*1.5, 0),
                LeftFoot = oldCFrame * CFrame.new(-offset/2, -offset*2, 0)
            }
            for partName, cf in pairs(parts) do
                local part = character:FindFirstChild(partValue)
                if part then
                    part.CFrame = cf
                    setVelocityToZero(part)
                end
            end
        end)
        
        if lagToggled and isKnifeInInventory() then
            spawn(loopKnifeToggle)
        end
    else
        unragdollEvent:FireServer()
        if ragdollConnection then ragdollConnection:Disconnect() end
        if knifeEquipConnection then knifeEquipConnection:Disconnect() end
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then part.Anchored = false end
        end
        if humanoid then
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        ToggleDisallowEvent:FireServer()
        ModifyUserEvent:FireServer(localPlayer.Name)
        wait(0.5)
        ToggleDisallowEvent:FireServer()

        if rootPart then rootPart.CFrame = CFrame.new(0, 50, 0) end
        wait(1)

        spectating = false
        SpectateFrame.Visible = false
        currentSpectateTarget = nil
    end
end

LagServerButton.MouseButton1Click:Connect(function()
    if lagButtonCooldown or annoyToggled then return end

    lagToggled = not lagToggled
    lagEnabled = lagToggled
    LagServerButton.Text = "Lag Server: " .. (lagToggled and "ON" or "OFF")
    LagServerButton.BackgroundColor3 = lagToggled and Color3.fromRGB(0, 150, 150) or Color3.fromRGB(45, 45, 50)

    toggleRagdoll()

    lagButtonCooldown = true
    LagServerButton.AutoButtonColor = false
    spawn(function()
        local cooldownRemaining = lagCooldownTime
        while cooldownRemaining > 0 do
            LagServerButton.Text = "Lag Server: " .. (lagToggled and "ON" or "OFF") .. " (" .. cooldownRemaining .. "s)"
            wait(1)
            cooldownRemaining = cooldownRemaining - 1
        end
        lagButtonCooldown = false
        LagServerButton.Text = "Lag Server: " .. (lagToggled and "ON" or "OFF")
        LagServerButton.AutoButtonColor = true
    end)
end)

-----------------------------------------------------------
-- Annoy Server Functionality
local annoyToggled = false
local annoyConnection
local originalPositions = {}
local currentKeyframe = 1
local animationTime = 0
local lastKeyframeTime = 0
local nearestTargetPlayers = {}
local farthestTargetPlayers = {}
local randomTargetPlayers = {}
local initialHumanoidRootPartCFrame = nil

local keyframes = {
    {
        duration = 0.1,
        config = {
            Humanoid = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "ad0",
                matchTargetPart = false
            },
            Head = {
                position = Vector3.new(101, 3, -2152),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            UpperTorso = {
                position = Vector3.new(101, 15, -2150002),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LowerTorso = {
                position = Vector3.new(101, -3.2, -2150002),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftUpperArm = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftLowerArm = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftHand = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightUpperArm = {
                position = Vector3.new(999999, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightLowerArm = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightHand = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftUpperLeg = {
                position = Vector3.new(-10000000, 15, 25000000),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftLowerLeg = {
                position = Vector3.new(-10000000, 15, -25000000),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftFoot = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightUpperLeg = {
                position = Vector3.new(10000000, 15, 25000000),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightLowerLeg = {
                position = Vector3.new(10000000, 15, -25000000),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightFoot = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            }
        }
    },
    {
        duration = 0.1,
        config = {
            Humanoid = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "ad0",
                matchTargetPart = false
            },
            Head = {
                position = Vector3.new(101, 3, -2152),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            UpperTorso = {
                position = Vector3.new(101, -3.2, -2150002),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LowerTorso = {
                position = Vector3.new(101, 7, -2150002),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftUpperArm = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftLowerArm = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftHand = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightUpperArm = {
                position = Vector3.new(999999, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightLowerArm = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightHand = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftUpperLeg = {
                position = Vector3.new(-10000000, 15, 25000000),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftLowerLeg = {
                position = Vector3.new(-10000000, 15, -25000000),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            LeftFoot = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightUpperLeg = {
                position = Vector3.new(10000000, 15, 25000000),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightLowerLeg = {
                position = Vector3.new(10000000, 15, -25000000),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            },
            RightFoot = {
                position = Vector3.new(0, 0, 0),
                rotation = Vector3.new(0, 0, 0),
                targetPlayer = "",
                matchTargetPart = true
            }
        }
    }
} -- Added closing brace for keyframes table

local bodyParts = {}
for partName, _ in pairs(keyframes[1].config) do
    table.insert(bodyParts, partName)
end

local function FindPlayerByPartialName(partialName, partName)
    if partialName == "nearest" then
        if nearestTargetPlayers[partName] then
            return nearestTargetPlayers[partName]
        else
            local localCharacter = localPlayer.Character
            if not localCharacter then return nil end
            local localHumanoidRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
            if not localHumanoidRootPart then return nil end

            local nearestPlayer = nil
            local nearestDistance = math.huge
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    local character = player.Character
                    if character then
                        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                        if humanoidRootPart then
                            local distance = (localHumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                            if distance < nearestDistance then
                                nearestDistance = distance
                                nearestPlayer = player
                            end
                        end
                    end
                end
            end
            nearestTargetPlayers[partName] = nearestPlayer
            return nearestPlayer
        end
    elseif partialName == "farthest" then
        if farthestTargetPlayers[partName] then
            return farthestTargetPlayers[partName]
        else
            local localCharacter = localPlayer.Character
            if not localCharacter then return nil end
            local localHumanoidRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
            if not localHumanoidRootPart then return nil end

            local farthestPlayer = nil
            local farthestDistance = -math.huge
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= localPlayer then
                    local character = player.Character
                    if character then
                        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                        if humanoidRootPart then
                            local distance = (localHumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                            if distance > farthestDistance then
                                farthestDistance = distance
                                farthestPlayer = player
                            end
                        end
                    end
                end
            end
            farthestTargetPlayers[partName] = farthestPlayer
            return farthestPlayer
        end
    elseif partialName == "random" then
        if randomTargetPlayers[partName] then
            return randomTargetPlayers[partName]
        else
            local allPlayers = Players:GetPlayers()
            local validPlayers = {}
            for _, player in ipairs(allPlayers) do
                if player ~= localPlayer then
                    table.insert(validPlayers, player)
                end
            end
            if #validPlayers > 0 then
                local randomIndex = math.random(1, #validPlayers)
                local randomPlayer = validPlayers[randomIndex]
                randomTargetPlayers[partName] = randomPlayer
                return randomPlayer
            end
            return nil
        end
    end
    
    partialName = partialName:lower()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(partialName) or (player.DisplayName and player.DisplayName:lower():find(partialName)) then
            return player
        end
    end
    return nil
end

local function SaveOriginalPositions()
    local character = localPlayer.Character
    if character then
        for partName, _ in pairs(keyframes[1].config) do
            if partName ~= "Humanoid" then
                local part = character:FindFirstChild(partName)
                if part then
                    originalPositions[partName] = part.CFrame
                end
            end
        end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            initialHumanoidRootPartCFrame = humanoidRootPart.CFrame
        end
    end
end

local function UpdateBodyPart(character, partName, currentConfig, nextConfig, alpha)
    local part = character:FindFirstChild(partName)
    if part and annoyToggled and partName ~= "Humanoid" then
        local baseCFrame = originalPositions[partName]
        if baseCFrame then
            local currentTargetCFrame = baseCFrame
            local nextTargetCFrame = baseCFrame
            
            if currentConfig.targetPlayer and currentConfig.targetPlayer ~= "" then
                local currentPlayer = FindPlayerByPartialName(currentConfig.targetPlayer, partName)
                if currentPlayer and currentPlayer.Character then
                    if currentConfig.matchTargetPart then
                        local targetPart = currentPlayer.Character:FindFirstChild(partName)
                        if targetPart then
                            currentTargetCFrame = CFrame.new(targetPart.Position)
                        end
                    else
                        local targetHumanoidRootPart = currentPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if targetHumanoidRootPart then
                            currentTargetCFrame = CFrame.new(targetHumanoidRootPart.Position)
                        end
                    end
                end
            else
                currentTargetCFrame = CFrame.new(baseCFrame.Position)
            end
            
            if nextConfig.targetPlayer and nextConfig.targetPlayer ~= "" then
                local nextPlayer = FindPlayerByPartialName(nextConfig.targetPlayer, partName)
                if nextPlayer and nextPlayer.Character then
                    if nextConfig.matchTargetPart then
                        local targetPart = nextPlayer.Character:FindFirstChild(partName)
                        if targetPart then
                            nextTargetCFrame = CFrame.new(targetPart.Position)
                        end
                    else
                        local targetHumanoidRootPart = nextPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if targetHumanoidRootPart then
                            nextTargetCFrame = CFrame.new(targetHumanoidRootPart.Position)
                        end
                    end
                end
            else
                nextTargetCFrame = CFrame.new(baseCFrame.Position)
            end
            
            local currentOffset = CFrame.new(currentConfig.position) *
                CFrame.Angles(
                    math.rad(currentConfig.rotation.X),
                    math.rad(currentConfig.rotation.Y),
                    math.rad(currentConfig.rotation.Z)
                )
            local nextOffset = CFrame.new(nextConfig.position) *
                CFrame.Angles(
                    math.rad(nextConfig.rotation.X),
                    math.rad(nextConfig.rotation.Y),
                    math.rad(nextConfig.rotation.Z)
                )
            
            local finalCurrentCFrame = currentTargetCFrame * currentOffset
            local finalNextCFrame = nextTargetCFrame * nextOffset
            local finalCFrame = finalCurrentCFrame:Lerp(finalNextCFrame, alpha)
            
            local _, origYaw, _ = baseCFrame:ToOrientation()
            finalCFrame = CFrame.new(finalCFrame.Position) * CFrame.Angles(0, origYaw, 0)
            
            part.CFrame = finalCFrame
            part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end
end

local function UpdateHumanoid(character, currentConfig, nextConfig, alpha)
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoid and humanoidRootPart and initialHumanoidRootPartCFrame then
        local currentTargetCFrame = initialHumanoidRootPartCFrame
        local nextTargetCFrame = initialHumanoidRootPartCFrame
        
        if currentConfig.targetPlayer and currentConfig.targetPlayer ~= "" then
            local currentPlayer = FindPlayerByPartialName(currentConfig.targetPlayer, "Humanoid")
            if currentPlayer and currentPlayer.Character then
                local targetHumanoidRootPart = currentPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHumanoidRootPart then
                    currentTargetCFrame = CFrame.new(targetHumanoidRootPart.Position)
                end
            end
        else
            currentTargetCFrame = CFrame.new(initialHumanoidRootPartCFrame.Position)
        end
        
        if nextConfig.targetPlayer and nextConfig.targetPlayer ~= "" then
            local nextPlayer = FindPlayerByPartialName(nextConfig.targetPlayer, "Humanoid")
            if nextPlayer and nextPlayer.Character then
                local targetHumanoidRootPart = nextPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHumanoidRootPart then
                    nextTargetCFrame = CFrame.new(targetHumanoidRootPart.Position)
                end
            end
        else
            nextTargetCFrame = CFrame.new(initialHumanoidRootPartCFrame.Position)
        end
        
        local currentOffset = CFrame.new(currentConfig.position) *
            CFrame.Angles(
                math.rad(currentConfig.rotation.X),
                math.rad(currentConfig.rotation.Y),
                math.rad(currentConfig.rotation.Z)
            )
        local nextOffset = CFrame.new(nextConfig.position) *
            CFrame.Angles(
                math.rad(nextConfig.rotation.X),
                math.rad(nextConfig.rotation.Y),
                math.rad(nextConfig.rotation.Z)
            )
        
        local finalCurrentCFrame = currentTargetCFrame * currentOffset
        local finalNextCFrame = nextTargetCFrame * nextOffset
        local finalCFrame = finalCurrentCFrame:Lerp(finalNextCFrame, alpha)
        
        local _, origYaw, _ = initialHumanoidRootPartCFrame:ToOrientation()
        finalCFrame = CFrame.new(finalCFrame.Position) * CFrame.Angles(0, origYaw, 0)
        
        humanoidRootPart.CFrame = finalCFrame
        humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        humanoid.WalkSpeed = 16
    end
end

local function UpdateBody()
    local character = localPlayer.Character
    if character and annoyToggled then
        local humanoid = character:FindFirstChild("Humanoid")
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoid and humanoidRootPart and initialHumanoidRootPartCFrame then
            local deltaTime = tick() - lastKeyframeTime
            animationTime = animationTime + deltaTime
            lastKeyframeTime = tick()
            
            local currentFrame = keyframes[currentKeyframe]
            local nextFrame = keyframes[currentKeyframe + 1] or keyframes[1]
            
            local alpha = math.min(animationTime / currentFrame.duration, 1)
            
            for partName, _ in pairs(currentFrame.config) do
                UpdateBodyPart(character, partName, currentFrame.config[partName], nextFrame.config[partName], alpha)
            end
            if currentFrame.config.Humanoid then
                UpdateHumanoid(character, currentFrame.config.Humanoid, nextFrame.config.Humanoid, alpha)
            end
            if alpha >= 1 then
                currentKeyframe = currentKeyframe + 1
                if currentKeyframe > #keyframes then
                    currentKeyframe = 1
                end
                animationTime = 0
            end
        end
    end
end

local function SafeDeactivateAnnoy()
    for i = 1, 3 do
        ReplicatedStorage.UnragdollEvent:FireServer()
        task.wait(0.1)
    end
    
    local character = localPlayer.Character
    if character then
        for partName, _ in pairs(keyframes[1].config) do
            if partName ~= "Humanoid" then
                local part = character:FindFirstChild(partName)
                if part and originalPositions[partName] then
                    part.CFrame = originalPositions[partName]
                    part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
    
    nearestTargetPlayers = {}
    farthestTargetPlayers = {}
    randomTargetPlayers = {}
    initialHumanoidRootPartCFrame = nil
end

AnnoyServerButton.MouseButton1Click:Connect(function()
    if lagToggled then return end

    annoyToggled = not annoyToggled
    AnnoyServerButton.Text = "Annoy Server: " .. (annoyToggled and "ON" or "OFF")
    AnnoyServerButton.BackgroundColor3 = annoyToggled and Color3.fromRGB(0, 150, 150) or Color3.fromRGB(45, 45, 50)

    if annoyToggled then
        ModifyUsername_upvr:FireServer("VirtuallyNad")
        wait(1.5)
        
        SaveOriginalPositions()
        currentKeyframe = 1
        animationTime = 0
        lastKeyframeTime = tick()
        
        if annoyConnection then
            annoyConnection:Disconnect()
        end
        annoyConnection = RunService.Heartbeat:Connect(UpdateBody)
        
        ReplicatedStorage.RagdollEvent:FireServer()
    else
        if annoyConnection then
            annoyConnection:Disconnect()
        end
        SafeDeactivateAnnoy()
        ModifyUserEvent:FireServer(localPlayer.Name)
        wait(0.5)
    end
end)

Players.LocalPlayer.CharacterAdded:Connect(function()
    if annoyToggled then
        annoyToggled = false
        if annoyConnection then
            annoyConnection:Disconnect()
        end
        AnnoyServerButton.Text = "Annoy Server: OFF"
        AnnoyServerButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        SafeDeactivateAnnoy()
    end
end)

-----------------------------------------------------------
-- Anti Lag
local targetItemNames = {"aura", "Fluffy Satin Gloves Black"}
local antiLagToggled = true

local function hasItemInName(accessory)
    for _, itemName in pairs(targetItemNames) do
        if accessory.Name:lower():find(itemName:lower()) then
            return true
        end
    end
    return false
end

local function isAccessoryOnHeadOrAbove(accessory)
    local handle = accessory:FindFirstChild("Handle")
    if handle and handle.Parent and handle.Parent.Name == "Head" then return true end
    local attachment = accessory:FindFirstChildWhichIsA("Attachment")
    if attachment and attachment.Parent and attachment.Parent.Name == "Head" then return true end
    if accessory.Parent and accessory.Parent:IsA("Model") then
        local head = accessory.Parent:FindFirstChild("Head")
        if head and handle and handle.Position.Y >= head.Position.Y then return true end
    end
    return false
end

local function removeTargetedItems(character)
    if not character then return end
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Accessory") and hasItemInName(item) and not isAccessoryOnHeadOrAbove(item) then
            item:Destroy()
        end
    end
end

local function continuouslyCheckItems()
    while antiLagToggled do
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                removeTargetedItems(player.Character)
            end
        end
        wait(1)
    end
end

spawn(continuouslyCheckItems)

-----------------------------------------------------------
-- Live Notification System (Unlimited with Fade-Out)
local playerGui = localPlayer:WaitForChild("PlayerGui")
local screenGui = playerGui:FindFirstChild("NotificationGui") or Instance.new("ScreenGui", playerGui)
screenGui.Name = "NotificationGui"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local activeNotifications = {}
local notificationsEnabled = true
local notificationHeight = 80
local notificationSpacing = 10
local initialYOffset = -150
local notificationWidth = 300
local slideDuration = 0.3
local fadeDuration = 0.5
local displayDuration = 2

local function createNotification()
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, notificationWidth, 0, notificationHeight)
    notification.BackgroundTransparency = 0
    notification.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    notification.Visible = false
    notification.Parent = screenGui
    notification.ZIndex = 10

    local uiCorner = Instance.new("UICorner", notification)
    uiCorner.CornerRadius = UDim.new(0, 16)

    local uiShadow = Instance.new("UIStroke", notification)
    uiShadow.Name = "UIShadow"
    uiShadow.Thickness = 2
    uiShadow.Color = Color3.fromRGB(0, 0, 0)
    uiShadow.Transparency = 0.7
    uiShadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local pfpFrame = Instance.new("Frame", notification)
    pfpFrame.Name = "PfpFrame"
    pfpFrame.Size = UDim2.new(0, 70, 0, 70)
    pfpFrame.Position = UDim2.new(0, 5, 0, 5)
    pfpFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    pfpFrame.BackgroundTransparency = 0.4
    pfpFrame.ZIndex = 11
    local pfpFrameCorner = Instance.new("UICorner", pfpFrame)
    pfpFrameCorner.CornerRadius = UDim.new(0, 35)

    local profilePicture = Instance.new("ImageLabel", pfpFrame)
    profilePicture.Name = "ProfilePicture"
    profilePicture.Size = UDim2.new(0, 60, 0, 60)
    profilePicture.Position = UDim2.new(0, 5, 0, 5)
    profilePicture.BackgroundTransparency = 1
    profilePicture.ZIndex = 12
    local picCorner = Instance.new("UICorner", profilePicture)
    picCorner.CornerRadius = UDim.new(0, 30)

    local notificationText = Instance.new("TextLabel", notification)
    notificationText.Name = "NotificationText"
    notificationText.Size = UDim2.new(0, 220, 0, 60)
    notificationText.Position = UDim2.new(0, 80, 0, 10)
    notificationText.BackgroundTransparency = 1
    notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notificationText.TextSize = 18
    notificationText.Font = Enum.Font.GothamBold
    notificationText.TextXAlignment = Enum.TextXAlignment.Left
    notificationText.TextScaled = true
    notificationText.TextWrapped = true
    notificationText.ZIndex = 11

    local notificationSound = Instance.new("Sound", notification)
    notificationSound.SoundId = "rbxassetid://8503529943"
    notificationSound.Volume = 1.5

    return notification, profilePicture, notificationText, notificationSound
end

local function updateNotificationPositions()
    for i, notifData in ipairs(activeNotifications) do
        if notifData.notification and notifData.notification.Parent then
            local targetY = initialYOffset - ((i - 1) * (notificationHeight + notificationSpacing))
            local tweenInfo = TweenInfo.new(slideDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(notifData.notification, tweenInfo, {
                Position = UDim2.new(1, -notificationWidth - 10, 1, targetY)
            })
            tween:Play()
        end
    end
end

local function showNotification(leavingPlayer)
    if not notificationsEnabled then return end
    
    -- Create new notification
    local notification, profilePicture, notificationText, notificationSound = createNotification()
    
    -- Set notification content
    notificationText.Text = leavingPlayer.Name .. " has left the server."
    local success, content = pcall(function()
        return Players:GetUserThumbnailAsync(leavingPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    profilePicture.Image = success and content or "rbxassetid://0"

    -- Play sound if enabled
    if notificationsEnabled then
        pcall(function()
            notificationSound:Play()
        end)
    end

    -- Position off-screen to the right
    local startX = 1
    local startOffsetX = -notificationWidth - 10
    local startY = initialYOffset
    
    -- Add to active notifications table
    local notifData = {
        notification = notification,
        creationTime = os.clock(),
        profilePicture = profilePicture,
        notificationText = notificationText
    }
    table.insert(activeNotifications, 1, notifData)
    
    -- Make visible and slide in from right
    notification.Position = UDim2.new(startX, startOffsetX + notificationWidth + 20, 1, startY)
    notification.Visible = true
    
    local tweenInfo = TweenInfo.new(slideDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local showTween = TweenService:Create(notification, tweenInfo, {
        Position = UDim2.new(startX, startOffsetX, 1, startY)
    })
    showTween:Play()
    
    -- Update positions of all notifications
    updateNotificationPositions()
    
    -- Start removal timer
    task.spawn(function()
        local startTime = os.clock()
        
        -- Wait for display duration
        while os.clock() - startTime < displayDuration do
            task.wait()
        end
        
        -- Only remove if still in active notifications
        if table.find(activeNotifications, notifData) then
            -- Fade out and slide right animation
            local fadeOutTween = TweenService:Create(notification, TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, startOffsetX + notificationWidth + 20, 1, notification.Position.Y.Offset)
            })
            
            -- Fade out text and picture too
            if profilePicture then
                TweenService:Create(profilePicture, TweenInfo.new(fadeDuration), {ImageTransparency = 1}):Play()
            end
            if notificationText then
                TweenService:Create(notificationText, TweenInfo.new(fadeDuration), {TextTransparency = 1}):Play()
            end
            
            fadeOutTween:Play()
            fadeOutTween.Completed:Wait()
            
            -- Clean up
            notification:Destroy()
            table.remove(activeNotifications, table.find(activeNotifications, notifData))
            updateNotificationPositions()
        end
    end)
end

Players.PlayerRemoving:Connect(function(leavingPlayer)
    pcall(function()
        showNotification(leavingPlayer)
    end)
end)

NotificationToggle.MouseButton1Click:Connect(function()
    notificationsEnabled = not notificationsEnabled
    NotificationToggle.Text = "Notifications: " .. (notificationsEnabled and "ON" or "OFF")
end)
