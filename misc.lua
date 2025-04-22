-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

-- Local Player
local LocalPlayer = Players.LocalPlayer

-- Body Copy Logic
local bodyParts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "HumanoidRootPart"}
local offsetMagnitude = 2.0
local updateConnection = nil
local selectedDirection = "Side"
local selectedTarget = nil
local ScreenGui = nil
local isMinimized = false
local MIN_DISTANCE = 1.0
local MAX_DISTANCE = 5.0

-- Snake Reanimation Logic
local snakeOrder = {
    "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot"
}
local snakeDistance = 1.0
local snakeSmoothing = 0.02
local SNAKE_MIN_DISTANCE = 0.5
local SNAKE_MAX_DISTANCE = 5.0
local ghostEnabled = false
local originalCharacter
local ghostClone
local originalCFrame
local originalAnimateScript
local snakeUpdateConnection
local snakeRenderStepConnection
local previousPositions = {}
local targetPositions = {}
local lastUpdateTime = 0
local preservedGuis = {}

-- GUI elements
local NameBox, CrossButton, PositionButton, PositionDropdownList, PlayerDropdown, PlayerDropdownList, PlayerPFP, MainFrame, MinimizeButton, DistanceSliderButton
local SnakeTabFrame, SnakeButton, SnakeDistanceSlider, CopyTabFrame

local function findPlayer(displayName)
    displayName = displayName:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p.DisplayName:lower():match(displayName) or p.Name:lower():match(displayName) then
            return p
        end
    end
    return nil
end

local function getOffset(targetCFrame, direction, distance)
    if distance == 1.0 then
        return Vector3.new(0, 0, 0)
    end
    
    if direction == "Side" then
        return targetCFrame.RightVector * -(distance - 1) * 3
    elseif direction == "Front" then
        return targetCFrame.LookVector * (distance - 1) * 3
    elseif direction == "Behind" then
        return targetCFrame.LookVector * -(distance - 1) * 3
    elseif direction == "Facing" then
        return targetCFrame.LookVector * (distance - 1) * 3
    else
        warn("Invalid direction: " .. tostring(direction) .. ". Defaulting to Side.")
        return targetCFrame.RightVector * -(distance - 1) * 3
    end
end

local function destroyAllSeats()
    for _, seat in pairs(Workspace:GetDescendants()) do
        if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
            seat:Destroy()
        end
    end
end

local function activateBodyCopy(target)
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    if getgenv().Running then
        deactivateBodyCopy()
    end

    if not target or not target.Character then
        warn("Target player not found or has no character!")
        return
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then 
        warn("Local player character not loaded!")
        return 
    end

    Workspace.Gravity = 0
    for _, partName in ipairs(bodyParts) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    if ReplicatedStorage:FindFirstChild("RagdollEvent") then
        ReplicatedStorage.RagdollEvent:FireServer()
    end
    
    if target.Character and target.Character:FindFirstChild("Humanoid") then
        Workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
    end
    
    getgenv().Running = true
    selectedTarget = target

    updateConnection = RunService.RenderStepped:Connect(function()
        if not getgenv().Running or not selectedTarget then 
            if updateConnection then
                updateConnection:Disconnect()
                updateConnection = nil
            end
            return 
        end
        
        local localChar = LocalPlayer.Character
        local targetChar = selectedTarget.Character
        
        if localChar and targetChar then
            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
            if targetHRP and targetHRP.Position then
                local offset = getOffset(targetHRP.CFrame, selectedDirection, offsetMagnitude)
                for _, partName in ipairs(bodyParts) do
                    local localPart = localChar:FindFirstChild(partName)
                    local targetPart = targetChar:FindFirstChild(partName)
                    if localPart and targetPart and localPart:IsA("BasePart") and targetPart:IsA("BasePart") then
                        if offsetMagnitude == 1.0 then
                            localPart.CFrame = targetPart.CFrame
                        else
                            if selectedDirection == "Facing" then
                                local basePosition = targetPart.CFrame.Position + offset
                                local targetOrientation = targetHRP.CFrame - targetHRP.CFrame.Position
                                local facingCFrame = targetOrientation * CFrame.Angles(0, math.rad(180), 0)
                                localPart.CFrame = CFrame.new(basePosition) * facingCFrame
                            else
                                localPart.CFrame = targetPart.CFrame + offset
                            end
                        end
                    end
                end
            else
                warn("Target HumanoidRootPart not found or has no Position!")
            end
        end
    end)
end

local function deactivateBodyCopy()
    getgenv().Running = false
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    Workspace.Gravity = 196.2
    if ReplicatedStorage:FindFirstChild("UnragdollEvent") then
        ReplicatedStorage.UnragdollEvent:FireServer()
    end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        Workspace.CurrentCamera.CameraSubject = char.Humanoid
    end
    if NameBox then
        NameBox.Text = ""
    end
    if CrossButton then
        CrossButton.Visible = false
    end
    if PlayerPFP then
        PlayerPFP.Visible = false
    end
    selectedTarget = nil
end

-- Snake Reanimation Functions
local function preserveGuis()
    local playerGui = LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "MiscGUI" and gui.ResetOnSpawn then
                table.insert(preservedGuis, gui)
                gui.ResetOnSpawn = false
            end
        end
    end
end

local function restoreGuis()
    for _, gui in ipairs(preservedGuis) do
        if gui and gui.Parent then
            gui.ResetOnSpawn = true
        end
    end
    table.clear(preservedGuis)
end

local function updateSnakeParts(dt)
    if not ghostEnabled or not originalCharacter or not originalCharacter.Parent or not ghostClone or not ghostClone.Parent then
        if snakeUpdateConnection then
            snakeUpdateConnection:Disconnect()
            snakeUpdateConnection = nil
        end
        if snakeRenderStepConnection then
            snakeRenderStepConnection:Disconnect()
            snakeRenderStepConnection = nil
        end
        return
    end

    local currentTime = tick()
    local actualDt = currentTime - lastUpdateTime
    lastUpdateTime = currentTime

    local rootPart = ghostClone:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    if not targetPositions then targetPositions = {} end
    if not previousPositions then previousPositions = {} end

    local activeSnakeParts = snakeOrder

    if #activeSnakeParts == 0 then return end

    for i, partName in ipairs(activeSnakeParts) do
        local part = originalCharacter:FindFirstChild(partName)
        if not part then continue end

        if i == 1 then
            local targetPosition = rootPart.Position
            local targetRotation = rootPart.CFrame - rootPart.Position
            targetPositions[partName] = CFrame.new(targetPosition) * targetRotation
        else
            local previousPartName = activeSnakeParts[i-1]
            local previousPart = originalCharacter:FindFirstChild(previousPartName)
            if previousPart then
                local prevPartPos = previousPart.Position
                local prevPartRot = previousPart.CFrame - previousPart.Position
                local directionVector
                if i == 2 then
                    directionVector = (prevPartPos - rootPart.Position).Unit
                else
                    local beforePreviousPart = originalCharacter:FindFirstChild(activeSnakeParts[i-2])
                    if beforePreviousPart then
                        directionVector = (prevPartPos - beforePreviousPart.Position).Unit
                    else
                        directionVector = prevPartRot.LookVector
                    end
                end
                if directionVector.Magnitude < 0.1 then
                    directionVector = prevPartRot.LookVector
                end
                local targetPosition = prevPartPos + directionVector * snakeDistance
                local targetRotation = prevPartRot
                targetPositions[partName] = CFrame.new(targetPosition) * targetRotation
            end
        end

        if not targetPositions[partName] then targetPositions[partName] = part.CFrame end
        if not previousPositions[partName] then previousPositions[partName] = part.CFrame end
        local smoothCFrame = previousPositions[partName]:Lerp(targetPositions[partName], snakeSmoothing)
        part.CFrame = smoothCFrame
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
        previousPositions[partName] = smoothCFrame
    end
end

local function setGhostEnabled(newState)
    ghostEnabled = newState

    if ghostEnabled then
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root then return end
        if originalCharacter or ghostClone then return end

        originalCharacter = char
        originalCFrame = root.CFrame
        char.Archivable = true
        ghostClone = char:Clone()
        char.Archivable = false
        ghostClone.Name = originalCharacter.Name .. "_clone"
        local ghostHumanoid = ghostClone:FindFirstChildWhichIsA("Humanoid")
        if ghostHumanoid then
            ghostHumanoid.DisplayName = originalCharacter.Name .. "_clone"
            ghostHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
        if not ghostClone.PrimaryPart then
            local hrp = ghostClone:FindFirstChild("HumanoidRootPart")
            if hrp then ghostClone.PrimaryPart = hrp else warn("Clone HRP not found!") end
        end
        for _, part in ipairs(ghostClone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1; part.CanCollide = false; part.Anchored = false; part.CanQuery = false
            elseif part:IsA("Decal") then part.Transparency = 1
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then handle.Transparency = 1; handle.CanCollide = false; handle.CanQuery = false end
            end
        end
        local animate = originalCharacter:FindFirstChild("Animate")
        if animate then originalAnimateScript = animate; originalAnimateScript.Disabled = true; originalAnimateScript.Parent = ghostClone end
        preserveGuis()
        ghostClone.Parent = Workspace
        LocalPlayer.Character = ghostClone
        if ghostHumanoid then Workspace.CurrentCamera.CameraSubject = ghostHumanoid end
        restoreGuis()
        if originalAnimateScript and originalAnimateScript.Parent == ghostClone then originalAnimateScript.Disabled = false end
        ReplicatedStorage.RagdollEvent:FireServer()

        targetPositions = {}
        previousPositions = {}
        lastUpdateTime = tick()

        if snakeUpdateConnection then snakeUpdateConnection:Disconnect(); snakeUpdateConnection = nil end
        if snakeRenderStepConnection then snakeRenderStepConnection:Disconnect(); snakeRenderStepConnection = nil end

        snakeUpdateConnection = RunService.Heartbeat:Connect(updateSnakeParts)
    else
        if not originalCharacter or not ghostClone then return end
        if snakeUpdateConnection then snakeUpdateConnection:Disconnect(); snakeUpdateConnection = nil end
        if snakeRenderStepConnection then snakeRenderStepConnection:Disconnect(); snakeRenderStepConnection = nil end

        ReplicatedStorage.UnragdollEvent:FireServer()

        local targetCFrame = originalCFrame
        local ghostPrimary = ghostClone.PrimaryPart
        if ghostPrimary then targetCFrame = ghostPrimary.CFrame else warn("Clone PrimaryPart not found for CFrame!") end

        local animate = ghostClone:FindFirstChild("Animate")
        if animate then animate.Disabled = true; animate.Parent = originalCharacter end

        ghostClone:Destroy(); ghostClone = nil

        if originalCharacter and originalCharacter.Parent then
            local origRoot = originalCharacter:FindFirstChild("HumanoidRootPart")
            local origHumanoid = originalCharacter:FindFirstChildWhichIsA("Humanoid")

            if origRoot then
                origRoot.CFrame = targetCFrame
                origRoot.AssemblyLinearVelocity = Vector3.zero
                origRoot.AssemblyAngularVelocity = Vector3.zero
            end
            preserveGuis()
            LocalPlayer.Character = originalCharacter
            if origHumanoid then
                Workspace.CurrentCamera.CameraSubject = origHumanoid
                origHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            restoreGuis()
            if animate and animate.Parent == originalCharacter then task.wait(0.1); animate.Disabled = false end
        else
            print("Original character lost during disable.")
        end
        originalCharacter = nil; originalAnimateScript = nil
    end
end

-- GUI Setup
local function createGUI()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MiscGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 500, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 16)
    UICorner.Parent = MainFrame

    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 50))
    }
    UIGradient.Parent = MainFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 50)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    TitleBar.BackgroundTransparency = 0
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    TitleBar.Name = "TitleBar"

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 16)
    TitleCorner.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -100, 1, 0)
    TitleLabel.Position = UDim2.new(0, 20, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "MISC"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    TitleLabel.Parent = TitleBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 40, 0, 40)
    CloseButton.Position = UDim2.new(1, -50, 0, 5)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "X"
    CloseButton.TextSize = 20
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TitleBar

    MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Size = UDim2.new(0, 40, 0, 40)
    MinimizeButton.Position = UDim2.new(1, -95, 0, 5)
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.Text = "−"
    MinimizeButton.TextSize = 20
    MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Parent = TitleBar

    -- Sidebar for Tabs
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 120, 1, -50)
    Sidebar.Position = UDim2.new(0, 0, 0, 50)
    Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Sidebar.BackgroundTransparency = 0
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 12)
    SidebarCorner.Parent = Sidebar

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Padding = UDim.new(0, 10)
    SidebarLayout.Parent = Sidebar

    local tabs = {
        {name = "Copy", frame = nil, button = nil, indicator = nil},
        {name = "Snake", frame = nil, button = nil, indicator = nil}
    }

    -- Content Area
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -120, 1, -50)
    ContentFrame.Position = UDim2.new(0, 120, 0, 50)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    -- Tab Frames
    CopyTabFrame = Instance.new("Frame")
    CopyTabFrame.Size = UDim2.new(1, 0, 1, 0)
    CopyTabFrame.BackgroundTransparency = 1
    CopyTabFrame.Visible = true
    CopyTabFrame.Parent = ContentFrame

    SnakeTabFrame = Instance.new("Frame")
    SnakeTabFrame.Size = UDim2.new(1, 0, 1, 0)
    SnakeTabFrame.BackgroundTransparency = 1
    SnakeTabFrame.Visible = false
    SnakeTabFrame.Parent = ContentFrame

    tabs[1].frame = CopyTabFrame
    tabs[2].frame = SnakeTabFrame

    -- Create Tab Buttons
    for i, tab in ipairs(tabs) do
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, -10, 0, 50)
        TabButton.Position = UDim2.new(0, 5, 0, 10 + (i-1)*60)
        TabButton.BackgroundTransparency = 1
        TabButton.Text = tab.name
        TabButton.Font = Enum.Font.GothamBold
        TabButton.TextSize = 16
        TabButton.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
        TabButton.LayoutOrder = i
        TabButton.Parent = Sidebar

        local TabIndicator = Instance.new("Frame")
        TabIndicator.Size = UDim2.new(0, 4, 0, 30)
        TabIndicator.Position = UDim2.new(0, 0, 0.5, -15)
        TabIndicator.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
        TabIndicator.BackgroundTransparency = i == 1 and 0 or 1
        TabIndicator.BorderSizePixel = 0
        TabIndicator.Parent = TabButton

        local IndicatorCorner = Instance.new("UICorner")
        IndicatorCorner.CornerRadius = UDim.new(0, 4)
        IndicatorCorner.Parent = TabIndicator

        tab.button = TabButton
        tab.indicator = TabIndicator
    end

    local function switchTab(tabName)
        for _, tab in ipairs(tabs) do
            if tab.name == tabName then
                tab.frame.Visible = true
                TweenService:Create(tab.button, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
                TweenService:Create(tab.indicator, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0,
                    Size = UDim2.new(0, 4, 0, 30)
                }):Play()
                if tabName == "Copy" and ghostEnabled then
                    setGhostEnabled(false)
                    if SnakeButton then
                        SnakeButton.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
                        SnakeButton.Text = "Enable Snake"
                    end
                elseif tabName == "Snake" and getgenv().Running then
                    deactivateBodyCopy()
                end
            else
                tab.frame.Visible = false
                TweenService:Create(tab.button, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    TextColor3 = Color3.fromRGB(180, 180, 180)
                }):Play()
                TweenService:Create(tab.indicator, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 4, 0, 10)
                }):Play()
            end
        end
    end

    -- Connect Tab Buttons
    for _, tab in ipairs(tabs) do
        tab.button.MouseButton1Click:Connect(function()
            switchTab(tab.name)
        end)

        tab.button.MouseEnter:Connect(function()
            if tab.frame.Visible then return end
            TweenService:Create(tab.button, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                TextColor3 = Color3.fromRGB(80, 120, 255)
            }):Play()
            TweenService:Create(tab.indicator, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                BackgroundTransparency = 0.5,
                Size = UDim2.new(0, 4, 0, 20)
            }):Play()
        end)

        tab.button.MouseLeave:Connect(function()
            if tab.frame.Visible then return end
            TweenService:Create(tab.button, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                TextColor3 = Color3.fromRGB(180, 180, 180)
            }):Play()
            TweenService:Create(tab.indicator, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 4, 0, 10)
            }):Play()
        end)
    end

    CloseButton.MouseEnter:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(80, 120, 255)}):Play()
    end)

    CloseButton.MouseLeave:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)

    MinimizeButton.MouseEnter:Connect(function()
        TweenService:Create(MinimizeButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(80, 120, 255)}):Play()
    end)

    MinimizeButton.MouseLeave:Connect(function()
        TweenService:Create(MinimizeButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)

    -- Copy Tab Content
    local SearchLabel = Instance.new("TextLabel")
    SearchLabel.Size = UDim2.new(0.9, 0, 0, 20)
    SearchLabel.Position = UDim2.new(0.05, 0, 0, 20)
    SearchLabel.BackgroundTransparency = 1
    SearchLabel.Text = "PLAYER TO COPY:"
    SearchLabel.Font = Enum.Font.Gotham
    SearchLabel.TextSize = 12
    SearchLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    SearchLabel.TextXAlignment = Enum.TextXAlignment.Left
    SearchLabel.Parent = CopyTabFrame

    NameBox = Instance.new("TextBox")
    NameBox.Size = UDim2.new(0.9, 0, 0, 40)
    NameBox.Position = UDim2.new(0.05, 0, 0, 40)
    NameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    NameBox.BackgroundTransparency = 0.4
    NameBox.BorderSizePixel = 0
    NameBox.Text = ""
    NameBox.PlaceholderText = "Enter Display Name..."
    NameBox.Font = Enum.Font.Gotham
    NameBox.TextSize = 14
    NameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    NameBox.ClearTextOnFocus = false
    NameBox.TextXAlignment = Enum.TextXAlignment.Center
    NameBox.Parent = CopyTabFrame

    local NameBoxCorner = Instance.new("UICorner")
    NameBoxCorner.CornerRadius = UDim.new(0, 10)
    NameBoxCorner.Parent = NameBox

    CrossButton = Instance.new("TextButton")
    CrossButton.Size = UDim2.new(0, 30, 0, 30)
    CrossButton.Position = UDim2.new(1, -35, 0, 5)
    CrossButton.BackgroundTransparency = 1
    CrossButton.Text = "✖"
    CrossButton.TextSize = 16
    CrossButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CrossButton.Font = Enum.Font.GothamBold
    CrossButton.Visible = false
    CrossButton.Parent = NameBox

    PlayerPFP = Instance.new("ImageLabel")
    PlayerPFP.Size = UDim2.new(0, 30, 0, 30)
    PlayerPFP.Position = UDim2.new(0.5, 0, 0, 5)
    PlayerPFP.BackgroundTransparency = 1
    PlayerPFP.Visible = false
    PlayerPFP.Parent = NameBox

    local PfpCorner = Instance.new("UICorner")
    PfpCorner.CornerRadius = UDim.new(1, 0)
    PfpCorner.Parent = PlayerPFP

    local PositionLabel = Instance.new("TextLabel")
    PositionLabel.Size = UDim2.new(0.9, 0, 0, 20)
    PositionLabel.Position = UDim2.new(0.05, 0, 0, 90)
    PositionLabel.BackgroundTransparency = 1
    PositionLabel.Text = "POSITION:"
    PositionLabel.Font = Enum.Font.Gotham
    PositionLabel.TextSize = 12
    PositionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    PositionLabel.TextXAlignment = Enum.TextXAlignment.Left
    PositionLabel.Parent = CopyTabFrame

    local PositionDropdown = Instance.new("Frame")
    PositionDropdown.Size = UDim2.new(0.9, 0, 0, 40)
    PositionDropdown.Position = UDim2.new(0.05, 0, 0, 110)
    PositionDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    PositionDropdown.BackgroundTransparency = 0.4
    PositionDropdown.BorderSizePixel = 0
    PositionDropdown.Parent = CopyTabFrame

    local PositionCorner = Instance.new("UICorner")
    PositionCorner.CornerRadius = UDim.new(0, 10)
    PositionCorner.Parent = PositionDropdown

    PositionButton = Instance.new("TextButton")
    PositionButton.Size = UDim2.new(1, -40, 1, 0)
    PositionButton.Position = UDim2.new(0, 0, 0, 0)
    PositionButton.BackgroundTransparency = 1
    PositionButton.Text = selectedDirection
    PositionButton.Font = Enum.Font.Gotham
    PositionButton.TextSize = 14
    PositionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    PositionButton.TextXAlignment = Enum.TextXAlignment.Center
    PositionButton.Parent = PositionDropdown

    local DropdownArrow = Instance.new("TextLabel")
    DropdownArrow.Size = UDim2.new(0, 30, 0, 30)
    DropdownArrow.Position = UDim2.new(1, -35, 0, 5)
    DropdownArrow.BackgroundTransparency = 1
    DropdownArrow.Text = "▼"
    DropdownArrow.Font = Enum.Font.Gotham
    DropdownArrow.TextSize = 14
    DropdownArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
    DropdownArrow.Parent = PositionDropdown

    PositionDropdownList = Instance.new("Frame")
    PositionDropdownList.Size = UDim2.new(0.9, 0, 0, 90)
    PositionDropdownList.Position = UDim2.new(0.05, 0, 0, 150)
    PositionDropdownList.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    PositionDropdownList.BackgroundTransparency = 0.2
    PositionDropdownList.BorderSizePixel = 0
    PositionDropdownList.Visible = false
    PositionDropdownList.ZIndex = 5
    PositionDropdownList.Parent = CopyTabFrame

    local PositionListCorner = Instance.new("UICorner")
    PositionListCorner.CornerRadius = UDim.new(0, 10)
    PositionListCorner.Parent = PositionDropdownList

    local PositionListLayout = Instance.new("UIListLayout")
    PositionListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PositionListLayout.Padding = UDim.new(0, 2)
    PositionListLayout.Parent = PositionDropdownList

    PlayerDropdown = Instance.new("Frame")
    PlayerDropdown.Size = UDim2.new(0.9, 0, 0, 150)
    PlayerDropdown.Position = UDim2.new(0.05, 0, 0, 80)
    PlayerDropdown.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    PlayerDropdown.BackgroundTransparency = 0.2
    PlayerDropdown.BorderSizePixel = 0
    PlayerDropdown.Visible = false
    PlayerDropdown.ZIndex = 10
    PlayerDropdown.Parent = CopyTabFrame

    local PlayerDropdownCorner = Instance.new("UICorner")
    PlayerDropdownCorner.CornerRadius = UDim.new(0, 10)
    PlayerDropdownCorner.Parent = PlayerDropdown

    PlayerDropdownList = Instance.new("ScrollingFrame")
    PlayerDropdownList.Size = UDim2.new(1, 0, 1, 0)
    PlayerDropdownList.BackgroundTransparency = 1
    PlayerDropdownList.BorderSizePixel = 0
    PlayerDropdownList.ScrollBarThickness = 4
    PlayerDropdownList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    PlayerDropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
    PlayerDropdownList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PlayerDropdownList.Parent = PlayerDropdown

    local PlayerListLayout = Instance.new("UIListLayout")
    PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PlayerListLayout.Padding = UDim.new(0, 5)
    PlayerListLayout.Parent = PlayerDropdownList

    local DistanceLabel = Instance.new("TextLabel")
    DistanceLabel.Size = UDim2.new(0.9, 0, 0, 20)
    DistanceLabel.Position = UDim2.new(0.05, 0, 0, 270)
    DistanceLabel.BackgroundTransparency = 1
    DistanceLabel.Text = "DISTANCE: " .. string.format("%.1f", offsetMagnitude)
    DistanceLabel.Font = Enum.Font.Gotham
    DistanceLabel.TextSize = 12
    DistanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    DistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    DistanceLabel.Parent = CopyTabFrame

    local DistanceSlider = Instance.new("Frame")
    DistanceSlider.Size = UDim2.new(0.9, 0, 0, 20)
    DistanceSlider.Position = UDim2.new(0.05, 0, 0, 290)
    DistanceSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    DistanceSlider.BackgroundTransparency = 0.4
    DistanceSlider.BorderSizePixel = 0
    DistanceSlider.Parent = CopyTabFrame

    local DistanceSliderCorner = Instance.new("UICorner")
    DistanceSliderCorner.CornerRadius = UDim.new(0, 10)
    DistanceSliderCorner.Parent = DistanceSlider

    local DistanceSliderFill = Instance.new("Frame")
    DistanceSliderFill.Size = UDim2.new(0, 0, 1, 0)
    DistanceSliderFill.Position = UDim2.new(0, 0, 0, 0)
    DistanceSliderFill.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    DistanceSliderFill.BorderSizePixel = 0
    DistanceSliderFill.Parent = DistanceSlider

    local DistanceSliderFillCorner = Instance.new("UICorner")
    DistanceSliderFillCorner.CornerRadius = UDim.new(0, 10)
    DistanceSliderFillCorner.Parent = DistanceSliderFill

    DistanceSliderButton = Instance.new("TextButton")
    DistanceSliderButton.Size = UDim2.new(0, 24, 0, 24)
    DistanceSliderButton.Position = UDim2.new(0, -12, 0, -2)
    DistanceSliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DistanceSliderButton.BackgroundTransparency = 0
    DistanceSliderButton.Text = ""
    DistanceSliderButton.ZIndex = 2
    DistanceSliderButton.Parent = DistanceSlider

    local DistanceSliderButtonCorner = Instance.new("UICorner")
    DistanceSliderButtonCorner.CornerRadius = UDim.new(1, 0)
    DistanceSliderButtonCorner.Parent = DistanceSliderButton

    local SliderButtonGradient = Instance.new("UIGradient")
    SliderButtonGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 140, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 255))
    }
    SliderButtonGradient.Parent = DistanceSliderButton

    local SliderHitbox = Instance.new("TextButton")
    SliderHitbox.Size = UDim2.new(1, 0, 1, 0)
    SliderHitbox.BackgroundTransparency = 1
    SliderHitbox.Text = ""
    SliderHitbox.ZIndex = 1
    SliderHitbox.Parent = DistanceSlider

    -- Snake Tab Content
    SnakeButton = Instance.new("TextButton")
    SnakeButton.Size = UDim2.new(0.9, 0, 0, 40)
    SnakeButton.Position = UDim2.new(0.05, 0, 0, 20)
    SnakeButton.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    SnakeButton.Text = "Enable Snake"
    SnakeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SnakeButton.Font = Enum.Font.GothamBold
    SnakeButton.TextSize = 14
    SnakeButton.Parent = SnakeTabFrame

    local SnakeButtonCorner = Instance.new("UICorner")
    SnakeButtonCorner.CornerRadius = UDim.new(0, 10)
    SnakeButtonCorner.Parent = SnakeButton

    local SnakeDistanceLabel = Instance.new("TextLabel")
    SnakeDistanceLabel.Size = UDim2.new(0.9, 0, 0, 20)
    SnakeDistanceLabel.Position = UDim2.new(0.05, 0, 0, 70)
    SnakeDistanceLabel.BackgroundTransparency = 1
    SnakeDistanceLabel.Text = "DISTANCE: " .. string.format("%.2f", snakeDistance)
    SnakeDistanceLabel.Font = Enum.Font.Gotham
    SnakeDistanceLabel.TextSize = 12
    SnakeDistanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    SnakeDistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    SnakeDistanceLabel.Parent = SnakeTabFrame

    local SnakeDistanceSliderFrame = Instance.new("Frame")
    SnakeDistanceSliderFrame.Size = UDim2.new(0.9, 0, 0, 20)
    SnakeDistanceSliderFrame.Position = UDim2.new(0.05, 0, 0, 90)
    SnakeDistanceSliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    SnakeDistanceSliderFrame.BackgroundTransparency = 0.4
    SnakeDistanceSliderFrame.BorderSizePixel = 0
    SnakeDistanceSliderFrame.Parent = SnakeTabFrame

    local SnakeSliderCorner = Instance.new("UICorner")
    SnakeSliderCorner.CornerRadius = UDim.new(0, 10)
    SnakeSliderCorner.Parent = SnakeDistanceSliderFrame

    local SnakeSliderFill = Instance.new("Frame")
    SnakeSliderFill.Size = UDim2.new(0, 0, 1, 0)
    SnakeSliderFill.Position = UDim2.new(0, 0, 0, 0)
    SnakeSliderFill.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    SnakeSliderFill.BorderSizePixel = 0
    SnakeSliderFill.Parent = SnakeDistanceSliderFrame

    local SnakeSliderFillCorner = Instance.new("UICorner")
    SnakeSliderFillCorner.CornerRadius = UDim.new(0, 10)
    SnakeSliderFillCorner.Parent = SnakeSliderFill

    SnakeDistanceSlider = Instance.new("TextButton")
    SnakeDistanceSlider.Size = UDim2.new(0, 24, 0, 24)
    SnakeDistanceSlider.Position = UDim2.new(0, -12, 0, -2)
    SnakeDistanceSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SnakeDistanceSlider.BackgroundTransparency = 0
    SnakeDistanceSlider.Text = ""
    SnakeDistanceSlider.ZIndex = 2
    SnakeDistanceSlider.Parent = SnakeDistanceSliderFrame

    local SnakeSliderButtonCorner = Instance.new("UICorner")
    SnakeSliderButtonCorner.CornerRadius = UDim.new(1, 0)
    SnakeSliderButtonCorner.Parent = SnakeDistanceSlider

    local SnakeSliderButtonGradient = Instance.new("UIGradient")
    SnakeSliderButtonGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 140, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 255))
    }
    SnakeSliderButtonGradient.Parent = SnakeDistanceSlider

    local SnakeSliderHitbox = Instance.new("TextButton")
    SnakeSliderHitbox.Size = UDim2.new(1, 0, 1, 0)
    SnakeSliderHitbox.BackgroundTransparency = 1
    SnakeSliderHitbox.Text = ""
    SnakeSliderHitbox.ZIndex = 1
    SnakeSliderHitbox.Parent = SnakeDistanceSliderFrame

    -- Event Connections
    CloseButton.MouseButton1Click:Connect(function()
        if ScreenGui then
            deactivateBodyCopy()
            if ghostEnabled then
                setGhostEnabled(false)
            end
            ScreenGui:Destroy()
            ScreenGui = nil
        end
    end)

    local function toggleMinimize()
        if isMinimized then
            MinimizeButton.Text = "−"
            local restoreTween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 500, 0, 400)
            })
            
            local descendants = MainFrame:GetDescendants()
            for _, descendant in pairs(descendants) do
                if descendant:IsA("Frame") and descendant ~= TitleBar and descendant.Parent ~= TitleBar then
                    local originalTransparency = descendant:GetAttribute("OriginalBackgroundTransparency") or descendant.BackgroundTransparency
                    TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        BackgroundTransparency = originalTransparency
                    }):Play()
                elseif descendant:IsA("TextLabel") or descendant:IsA("TextBox") then
                    if descendant ~= TitleLabel then
                        local originalTextTransparency = descendant:GetAttribute("OriginalTextTransparency") or descendant.TextTransparency
                        TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                            TextTransparency = originalTextTransparency
                        }):Play()
                        -- Handle NameBox BackgroundTransparency
                        if descendant == NameBox then
                            local originalBgTransparency = descendant:GetAttribute("OriginalBackgroundTransparency") or descendant.BackgroundTransparency
                            TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                                BackgroundTransparency = originalBgTransparency
                            }):Play()
                        end
                    end
                elseif descendant:IsA("TextButton") then
                    if descendant ~= MinimizeButton and descendant ~= CloseButton then
                        local originalTextTransparency = descendant:GetAttribute("OriginalTextTransparency") or descendant.TextTransparency
                        TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                            TextTransparency = originalTextTransparency
                        }):Play()
                        -- Handle SnakeButton and DistanceSliderButton BackgroundTransparency
                        if descendant == SnakeButton then
                            local originalBgTransparency = descendant:GetAttribute("OriginalBackgroundTransparency") or descendant.BackgroundTransparency
                            TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                                BackgroundTransparency = originalBgTransparency
                            }):Play()
                        end
                    end
                elseif descendant:IsA("ImageLabel") then
                    local originalTransparency = descendant:GetAttribute("OriginalBackgroundTransparency") or descendant.BackgroundTransparency
                    TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        BackgroundTransparency = originalTransparency
                    }):Play()
                end
            end
            
            -- Restore SnakeDistanceSlider and DistanceSliderButton separately
            local originalSnakeSliderTransparency = SnakeDistanceSlider:GetAttribute("OriginalBackgroundTransparency") or SnakeDistanceSlider.BackgroundTransparency
            TweenService:Create(SnakeDistanceSlider, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                BackgroundTransparency = originalSnakeSliderTransparency
            }):Play()
            
            local originalDistanceSliderButtonTransparency = DistanceSliderButton:GetAttribute("OriginalBackgroundTransparency") or DistanceSliderButton.BackgroundTransparency
            TweenService:Create(DistanceSliderButton, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                BackgroundTransparency = originalDistanceSliderButtonTransparency
            }):Play()
            
            restoreTween:Play()
            isMinimized = false
        else
            local descendants = MainFrame:GetDescendants()
            for _, descendant in pairs(descendants) do
                if descendant:IsA("Frame") then
                    descendant:SetAttribute("OriginalBackgroundTransparency", descendant.BackgroundTransparency)
                elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                    descendant:SetAttribute("OriginalTextTransparency", descendant.TextTransparency)
                    -- Store NameBox, SnakeButton, and DistanceSliderButton BackgroundTransparency
                    if descendant == NameBox or descendant == SnakeButton or descendant == DistanceSliderButton then
                        descendant:SetAttribute("OriginalBackgroundTransparency", descendant.BackgroundTransparency)
                    end
                elseif descendant:IsA("ImageLabel") then
                    descendant:SetAttribute("OriginalBackgroundTransparency", descendant.BackgroundTransparency)
                end
            end
            
            -- Store SnakeDistanceSlider BackgroundTransparency
            SnakeDistanceSlider:SetAttribute("OriginalBackgroundTransparency", SnakeDistanceSlider.BackgroundTransparency)
            
            for _, descendant in pairs(descendants) do
                if descendant:IsA("Frame") and descendant ~= TitleBar and descendant.Parent ~= TitleBar then
                    TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                        BackgroundTransparency = 1
                    }):Play()
                elseif descendant:IsA("TextLabel") or descendant:IsA("TextBox") then
                    if descendant ~= TitleLabel then
                        TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                            TextTransparency = 1
                        }):Play()
                        -- Fade NameBox BackgroundTransparency
                        if descendant == NameBox then
                            TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                                BackgroundTransparency = 1
                            }):Play()
                        end
                    end
                elseif descendant:IsA("TextButton") then
                    if descendant ~= MinimizeButton and descendant ~= CloseButton then
                        TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                            TextTransparency = 1
                        }):Play()
                        -- Fade SnakeButton BackgroundTransparency
                        if descendant == SnakeButton then
                            TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                                BackgroundTransparency = 1
                            }):Play()
                        end
                    end
                elseif descendant:IsA("ImageLabel") then
                    TweenService:Create(descendant, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                        BackgroundTransparency = 1
                    }):Play()
                end
            end
            
            -- Fade SnakeDistanceSlider and DistanceSliderButton
            TweenService:Create(SnakeDistanceSlider, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            }):Play()
            
            TweenService:Create(DistanceSliderButton, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            }):Play()
            
            task.wait(0.3)
            local barTween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 500, 0, 50)
            })
            barTween:Play()
            barTween.Completed:Wait()
            
            local minimizeTween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 200, 0, 50)
            })
            minimizeTween:Play()
            
            MinimizeButton.Text = "+"
            isMinimized = true
        end
    end

    MinimizeButton.MouseButton1Click:Connect(toggleMinimize)

    local dragging = false
    local dragStart, startPos

    local function updateDrag(input)
        if dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            MainFrame.Position = MainFrame.Position:Lerp(newPos, 0.8)
        end
    end

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateDrag(input)
        end
    end)

    -- Copy Tab Interactions
    local function adjustPfpPosition()
        if PlayerPFP.Visible and NameBox.Text ~= "" then
            local textSize = TextService:GetTextSize(
                NameBox.Text,
                NameBox.TextSize,
                NameBox.Font,
                Vector2.new(1000, 100)
            )
            local textWidth = textSize.X
            local pfpOffset = -(textWidth / 2 + 35)
            PlayerPFP.Position = UDim2.new(0.5, pfpOffset, 0, 5)
        end
    end

    local sliding = false
    local snakeSliding = false
    local minDistance = MIN_DISTANCE
    local maxDistance = MAX_DISTANCE
    local snakeMinDistance = SNAKE_MIN_DISTANCE
    local snakeMaxDistance = SNAKE_MAX_DISTANCE

    local function updateDistance(value)
        offsetMagnitude = math.clamp(value, minDistance, maxDistance)
        DistanceLabel.Text = "DISTANCE: " .. string.format("%.1f", offsetMagnitude)
        
        local fillPercent = (offsetMagnitude - minDistance)/(maxDistance - minDistance)
        local targetSize = UDim2.new(fillPercent, 0, 1, 0)
        local targetPos = UDim2.new(fillPercent, -12, 0, -2)
        
        TweenService:Create(DistanceSliderFill, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Size = targetSize}):Play()
        TweenService:Create(DistanceSliderButton, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Position = targetPos}):Play()
    end

    local function updateSnakeDistance(value)
        snakeDistance = math.clamp(value, snakeMinDistance, snakeMaxDistance)
        SnakeDistanceLabel.Text = "DISTANCE: " .. string.format("%.2f", snakeDistance)
        
        local fillPercent = (snakeDistance - snakeMinDistance)/(snakeMaxDistance - snakeMinDistance)
        local targetSize = UDim2.new(fillPercent, 0, 1, 0)
        local targetPos = UDim2.new(fillPercent, -12, 0, -2)
        
        TweenService:Create(SnakeSliderFill, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Size = targetSize}):Play()
        TweenService:Create(SnakeDistanceSlider, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Position = targetPos}):Play()
    end

    local function handleSliderInput(inputPos)
        local sliderPos = DistanceSlider.AbsolutePosition
        local sliderSize = DistanceSlider.AbsoluteSize
        local relativeX = (inputPos.X - sliderPos.X) / sliderSize.X
        relativeX = math.clamp(relativeX, 0, 1)
        local newDistance = minDistance + (relativeX * (maxDistance - minDistance))
        updateDistance(newDistance)
    end

    local function handleSnakeSliderInput(inputPos)
        local sliderPos = SnakeDistanceSliderFrame.AbsolutePosition
        local sliderSize = SnakeDistanceSliderFrame.AbsoluteSize
        local relativeX = (inputPos.X - sliderPos.X) / sliderSize.X
        relativeX = math.clamp(relativeX, 0, 1)
        local newDistance = snakeMinDistance + (relativeX * (snakeMaxDistance - snakeMinDistance))
        updateSnakeDistance(newDistance)
    end

    DistanceSliderButton.MouseButton1Down:Connect(function()
        sliding = true
    end)

    SliderHitbox.MouseButton1Down:Connect(function()
        sliding = true
        local mousePos = UserInputService:GetMouseLocation()
        handleSliderInput(mousePos)
    end)

    SnakeDistanceSlider.MouseButton1Down:Connect(function()
        snakeSliding = true
    end)

    SnakeSliderHitbox.MouseButton1Down:Connect(function()
        snakeSliding = true
        local mousePos = UserInputService:GetMouseLocation()
        handleSnakeSliderInput(mousePos)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
            snakeSliding = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            handleSliderInput(input.Position)
        end
        if snakeSliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            handleSnakeSliderInput(input.Position)
        end
    end)

    updateDistance(offsetMagnitude)
    updateSnakeDistance(snakeDistance)

    local directions = {"Side", "Front", "Behind", "Facing"}

    local function updatePositionDropdown()
        for _, child in ipairs(PositionDropdownList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local availableDirections = {}
        for _, dir in ipairs(directions) do
            if dir ~= selectedDirection then
                table.insert(availableDirections, dir)
            end
        end
        
        PositionDropdownList.Size = UDim2.new(0.9, 0, 0, #availableDirections * 30)
        
        for i, dir in ipairs(availableDirections) do
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, 0, 0, 28)
            option.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            option.BackgroundTransparency = 0.4
            option.Text = dir
            option.Font = Enum.Font.Gotham
            option.TextSize = 14
            option.TextColor3 = Color3.fromRGB(255, 255, 255)
            option.LayoutOrder = i
            option.ZIndex = 6
            option.Parent = PositionDropdownList

            local optionCorner = Instance.new("UICorner")
            optionCorner.CornerRadius = UDim.new(0, 8)
            optionCorner.Parent = option

            option.MouseEnter:Connect(function()
                TweenService:Create(option, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(55, 55, 65),
                    TextColor3 = Color3.fromRGB(80, 120, 255)
                }):Play()
            end)
            
            option.MouseLeave:Connect(function()
                TweenService:Create(option, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(45, 45, 55),
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end)

            option.MouseButton1Click:Connect(function()
                selectedDirection = dir
                PositionButton.Text = dir
                PositionDropdownList.Visible = false
            end)
        end
    end

    PositionButton.MouseEnter:Connect(function()
        TweenService:Create(PositionButton, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(80, 120, 255)
        }):Play()
    end)

    PositionButton.MouseLeave:Connect(function()
        TweenService:Create(PositionButton, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)

    PositionButton.MouseButton1Click:Connect(function()
        PositionDropdownList.Visible = not PositionDropdownList.Visible
        PlayerDropdown.Visible = false
        updatePositionDropdown()
    end)

    local function createPlayerEntry(playerObj)
        local entry = Instance.new("Frame")
        entry.Size = UDim2.new(1, 0, 0, 40)
        entry.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        entry.BackgroundTransparency = 0.4
        entry.BorderSizePixel = 0
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = entry
        
        local pfp = Instance.new("ImageLabel")
        pfp.Size = UDim2.new(0, 30, 0, 30)
        pfp.Position = UDim2.new(0, 5, 0.5, -15)
        pfp.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        pfp.BorderSizePixel = 0
        pfp.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(playerObj.UserId) .. "&w=150&h=150"
        pfp.Parent = entry
        
        local pfpCorner = Instance.new("UICorner")
        pfpCorner.CornerRadius = UDim.new(1, 0)
        pfpCorner.Parent = pfp
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -45, 1, 0)
        nameLabel.Position = UDim2.new(0, 40, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = playerObj.DisplayName .. " (@" .. playerObj.Name .. ")"
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 14
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = entry
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = entry
        
        button.MouseEnter:Connect(function()
            TweenService:Create(entry, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(entry, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
        end)
        
        button.MouseButton1Click:Connect(function()
            if not playerObj or not playerObj.Parent then
                warn("Selected player is no longer valid!")
                return
            end
            
            if getgenv().Running then
                deactivateBodyCopy()
            end
            
            NameBox.Text = playerObj.DisplayName .. " (@" .. playerObj.Name .. ")"
            PlayerPFP.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(playerObj.UserId) .. "&w=150&h=150"
            PlayerPFP.Visible = true
            adjustPfpPosition()
            selectedTarget = playerObj
            PlayerDropdown.Visible = false
            CrossButton.Visible = true
            activateBodyCopy(playerObj)
        end)
        
        return entry
    end

    local function updatePlayerDropdown(searchText)
        for _, child in ipairs(PlayerDropdownList:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        searchText = searchText:lower()
        local players = Players:GetPlayers()
        local matches = {}
        
        for _, p in ipairs(players) do
            if p ~= LocalPlayer and (p.DisplayName:lower():find(searchText) or p.Name:lower():find(searchText)) then
                table.insert(matches, p)
            end
        end
        
        table.sort(matches, function(a, b)
            return a.DisplayName:lower() < b.DisplayName:lower()
        end)
        
        for _, p in ipairs(matches) do
            local entry = createPlayerEntry(p)
            entry.Parent = PlayerDropdownList
        end
        
        PlayerDropdown.Visible = #matches > 0
        PositionDropdownList.Visible = false
    end

    NameBox:GetPropertyChangedSignal("Text"):Connect(function()
        updatePlayerDropdown(NameBox.Text)
        PlayerPFP.Visible = false
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            
            local playerBoxPos = NameBox.AbsolutePosition
            local playerBoxSize = NameBox.AbsoluteSize
            local playerDropdownPos = PlayerDropdown.AbsolutePosition
            local playerDropdownSize = PlayerDropdown.AbsoluteSize
            
            if not (mousePos.X >= playerBoxPos.X and mousePos.X <= playerBoxPos.X + playerBoxSize.X and
                   mousePos.Y >= playerBoxPos.Y and mousePos.Y <= playerDropdownPos.Y + playerDropdownSize.Y) then
                PlayerDropdown.Visible = false
            end
            
            local positionBoxPos = PositionDropdown.AbsolutePosition
            local positionBoxSize = PositionDropdown.AbsoluteSize
            local positionDropdownPos = PositionDropdownList.AbsolutePosition
            local positionDropdownSize = PositionDropdownList.AbsoluteSize

            if not (mousePos.X >= positionBoxPos.X and mousePos.X <= positionBoxPos.X + positionBoxSize.X and
                   mousePos.Y >= positionBoxPos.Y and mousePos.Y <= positionDropdownPos.Y + positionDropdownSize.Y) then
                PositionDropdownList.Visible = false
            end
        end
    end)

    CrossButton.MouseButton1Click:Connect(function()
        deactivateBodyCopy()
    end)

    CrossButton.MouseEnter:Connect(function()
        TweenService:Create(CrossButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(80, 120, 255)}):Play()
    end)

    CrossButton.MouseLeave:Connect(function()
        TweenService:Create(CrossButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)

    -- Snake Tab Interactions
    SnakeButton.MouseButton1Click:Connect(function()
        local newState = not ghostEnabled
        setGhostEnabled(newState)
        SnakeButton.BackgroundColor3 = newState and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 120, 255)
        SnakeButton.Text = newState and "Disable Snake" or "Enable Snake"
    end)

    SnakeButton.MouseEnter:Connect(function()
        TweenService:Create(SnakeButton, TweenInfo.new(0.2), {
            BackgroundColor3 = ghostEnabled and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 140, 255)
        }):Play()
    end)

    SnakeButton.MouseLeave:Connect(function()
        TweenService:Create(SnakeButton, TweenInfo.new(0.2), {
            BackgroundColor3 = ghostEnabled and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 120, 255)
        }):Play()
    end)
end

destroyAllSeats()
createGUI()

-- Cleanup
local function cleanup()
    print("Cleaning up Misc GUI script...")
    deactivateBodyCopy()
    if ghostEnabled then
        setGhostEnabled(false)
    end
    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end
    if updateConnection then updateConnection:Disconnect(); updateConnection = nil end
    if snakeUpdateConnection then snakeUpdateConnection:Disconnect(); snakeUpdateConnection = nil end
    if snakeRenderStepConnection then snakeRenderStepConnection:Disconnect(); snakeRenderStepConnection = nil end
end

if LocalPlayer.Character then
    LocalPlayer.Character.Destroying:Connect(function()
        if ghostEnabled then
            if snakeUpdateConnection then snakeUpdateConnection:Disconnect(); snakeUpdateConnection = nil end
            if snakeRenderStepConnection then snakeRenderStepConnection:Disconnect(); snakeRenderStepConnection = nil end
            if ghostClone then ghostClone:Destroy(); ghostClone = nil end
            originalCharacter = nil
            ghostEnabled = false
            if SnakeButton then
                SnakeButton.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
                SnakeButton.Text = "Enable Snake"
            end
        end
    end)
end

script.Destroying:Connect(cleanup)
