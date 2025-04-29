local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- Proxy server configuration
local PROXY_URL = "https://proxy-vjc2.onrender.com/query"
local FREE_API_URL = "https://leakcheck.io/api/public?check="

-- Colors for different states
local COLOR_NO_LEAKS = Color3.fromRGB(0, 255, 100) -- Green
local COLOR_LEAKS = Color3.fromRGB(255, 50, 50) -- Red
local COLOR_ERROR = Color3.fromRGB(255, 200, 0) -- Yellow
local COLOR_ACCENT = Color3.fromRGB(0, 200, 255) -- Cyan
local WINDOW_BG = Color3.fromRGB(20, 20, 20) -- Consistent window background
local COLOR_TEXT = Color3.fromRGB(255, 255, 255) -- White for most text
local COLOR_COPIED = Color3.fromRGB(0, 255, 100) -- Green for copied text
local COLOR_HOVER = Color3.fromRGB(135, 206, 250) -- Light blue for hover

-- Scanning distance (studs)
local SCAN_DISTANCE = 20

-- Emojis as UTF-8 characters
local EMOJI_GLOBE = "🌐"
local EMOJI_CALENDAR = "📅"
local EMOJI_GREEN = "🟢"
local EMOJI_RED = "🔴"

-- Sound IDs
local LEAK_FOUND_SOUND_ID = "rbxassetid://140419294351439"

-- Create ScreenGui for all UI elements
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WatchDogsScanner"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

-- Store player scan buttons and their connections
local playerScanButtons = {}
-- Store result windows and their connections
local playerResultWindows = {}

-- Status GUI
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(0, 220, 0, 110)
StatusFrame.Position = UDim2.new(1, -230, 0, -110) -- Start off-screen for animation
StatusFrame.BackgroundColor3 = WINDOW_BG
StatusFrame.BackgroundTransparency = 0.3 -- More transparent
StatusFrame.Parent = ScreenGui

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusFrame

local StatusEmoji = Instance.new("TextLabel")
StatusEmoji.Size = UDim2.new(0, 20, 0, 20)
StatusEmoji.Position = UDim2.new(0, 10, 0, 10)
StatusEmoji.BackgroundTransparency = 1
StatusEmoji.Text = EMOJI_GREEN
StatusEmoji.TextSize = 16
StatusEmoji.TextTransparency = 1
StatusEmoji.Parent = StatusFrame

local StatusTitle = Instance.new("TextLabel")
StatusTitle.Size = UDim2.new(1, 0, 0, 30)
StatusTitle.Position = UDim2.new(0, 0, 0, 0)
StatusTitle.BackgroundTransparency = 1
StatusTitle.Text = "Leak Scan"
StatusTitle.TextColor3 = COLOR_ACCENT
StatusTitle.TextSize = 20
StatusTitle.Font = Enum.Font.GothamBlack
StatusTitle.TextXAlignment = Enum.TextXAlignment.Center
StatusTitle.TextTransparency = 1
StatusTitle.Parent = StatusFrame

local StatusProviderLabel = Instance.new("TextLabel")
StatusProviderLabel.Size = UDim2.new(1, 0, 0, 20)
StatusProviderLabel.Position = UDim2.new(0, 0, 0, 35)
StatusProviderLabel.BackgroundTransparency = 1
StatusProviderLabel.Text = "Provided by leakcheck.io"
StatusProviderLabel.TextColor3 = COLOR_ACCENT
StatusProviderLabel.TextSize = 16
StatusProviderLabel.Font = Enum.Font.Gotham
StatusProviderLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusProviderLabel.TextTransparency = 1
StatusProviderLabel.Parent = StatusFrame

local StatusButton = Instance.new("TextButton")
StatusButton.Size = UDim2.new(0, 80, 0, 30)
StatusButton.Position = UDim2.new(0.5, -40, 0, 65)
StatusButton.BackgroundColor3 = COLOR_ACCENT
StatusButton.BackgroundTransparency = 0.2
StatusButton.Text = "Stop"
StatusButton.TextColor3 = COLOR_TEXT
StatusButton.TextSize = 16
StatusButton.Font = Enum.Font.GothamBold
StatusButton.TextTransparency = 1
StatusButton.Parent = StatusFrame

local StatusButtonCorner = Instance.new("UICorner")
StatusButtonCorner.CornerRadius = UDim.new(0, 8)
StatusButtonCorner.Parent = StatusButton

-- Close button for complete cleanup
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -40, 0, 5)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = COLOR_TEXT
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextTransparency = 1
CloseButton.Parent = StatusFrame

-- Hover effect for CloseButton
CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), { TextColor3 = COLOR_HOVER }):Play()
end)
CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
end)

-- Animate Status GUI appearance
local function animateGuiAppearance()
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(StatusFrame, tweenInfo, {
        Position = UDim2.new(1, -230, 0, 0),
        BackgroundTransparency = 0.3
    })
    TweenService:Create(StatusEmoji, tweenInfo, { TextTransparency = 0 }):Play()
    TweenService:Create(StatusTitle, tweenInfo, { TextTransparency = 0 }):Play()
    TweenService:Create(StatusProviderLabel, tweenInfo, { TextTransparency = 0 }):Play()
    TweenService:Create(StatusButton, tweenInfo, { TextTransparency = 0, BackgroundTransparency = 0.2 }):Play()
    TweenService:Create(CloseButton, tweenInfo, { TextTransparency = 0 }):Play()
    tween:Play()
end

animateGuiAppearance()

-- Fading animation for status emoji when scanning
local isAnimating = false
local function animateStatusEmoji()
    if isAnimating then return end
    isAnimating = true
    while StatusButton.Text == "Stop" do
        local fadeIn = TweenService:Create(StatusEmoji, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0 })
        local fadeOut = TweenService:Create(StatusEmoji, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 1 })
        fadeIn:Play()
        fadeIn.Completed:Wait()
        if StatusButton.Text ~= "Stop" then break end
        fadeOut:Play()
        fadeOut.Completed:Wait()
        if StatusButton.Text ~= "Stop" then break end
    end
    isAnimating = false
end

-- Global cooldown variables
local scanCooldown = false
local cooldownEndTime = 0

-- Function to update all buttons' cooldown visuals
local function updateAllButtonsCooldown()
    if not scanCooldown then return end

    local timeLeft = cooldownEndTime - tick()
    if timeLeft <= 0 then
        -- End cooldown
        scanCooldown = false
        for _, data in pairs(playerScanButtons) do
            local button = data.button
            button.BackgroundColor3 = COLOR_ACCENT
            button.Text = "Scan"
            -- Ensure button is visible and at correct transparency if player is in range
            if button.Visible then
                TweenService:Create(button, TweenInfo.new(0.2), { BackgroundTransparency = 0.2, TextTransparency = 0 }):Play()
            end
        end
    else
        -- Update countdown text
        local countdown = math.ceil(timeLeft)
        for _, data in pairs(playerScanButtons) do
            local button = data.button
            button.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Gray during cooldown
            button.Text = tostring(countdown)
        end
    end
end

-- Toggle scan functionality
local isScanningEnabled = true

StatusButton.MouseButton1Click:Connect(function()
    isScanningEnabled = not isScanningEnabled
    if isScanningEnabled then
        StatusButton.Text = "Stop"
        StatusEmoji.Text = EMOJI_GREEN
        local tween = TweenService:Create(StatusEmoji, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0 })
        tween:Play()
        tween.Completed:Connect(function()
            if StatusButton.Text == "Stop" then
                coroutine.wrap(animateStatusEmoji)()
            end
        end)
        for _, data in pairs(playerScanButtons) do
            data.button.Visible = true
        end
    else
        StatusButton.Text = "Start"
        isAnimating = false
        local tween = TweenService:Create(StatusEmoji, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0 })
        StatusEmoji.Text = EMOJI_RED
        tween:Play()
        for _, data in pairs(playerScanButtons) do
            local fadeOut = TweenService:Create(data.button, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 })
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                data.button.Visible = false
            end)
        end
    end
end)

coroutine.wrap(animateStatusEmoji)()

-- Complete cleanup function
local function cleanupAll()
    isAnimating = false
    for player, data in pairs(playerScanButtons) do
        if data.connection then
            data.connection:Disconnect()
        end
        if data.button then
            data.button:Destroy()
        end
    end
    playerScanButtons = {}
    for player, data in pairs(playerResultWindows) do
        if data.connection then
            data.connection:Disconnect()
        end
        if data.freeScanConnection then
            data.freeScanConnection:Disconnect()
        end
        if data.frame then
            data.frame:Destroy()
        end
    end
    playerResultWindows = {}
    local tweenInfo = TweenInfo.new(0.2)
    TweenService:Create(StatusFrame, tweenInfo, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(StatusEmoji, tweenInfo, { TextTransparency = 1 }):Play()
    TweenService:Create(StatusTitle, tweenInfo, { TextTransparency = 1 }):Play()
    TweenService:Create(StatusProviderLabel, tweenInfo, { TextTransparency = 1 }):Play()
    TweenService:Create(StatusButton, tweenInfo, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
    TweenService:Create(CloseButton, tweenInfo, { TextTransparency = 1 }):Play()
    task.delay(0.2, function()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end)
end

CloseButton.MouseButton1Click:Connect(cleanupAll)

-- Utility function to capitalize a string
local function capitalize(str)
    if not str or str == "" then return str end
    return str:sub(1, 1):upper() .. str:sub(2):lower()
end

-- Query LeakCheck API (Free version)
local function checkLeakCheckFree(username)
    local success, response = pcall(function()
        local url = FREE_API_URL .. HttpService:UrlEncode(username)
        return game:HttpGet(url)
    end)

    if not success then
        return { status = "error", text = "Network error: " .. tostring(response), color = COLOR_ERROR }
    end

    local data
    local decodeSuccess, decodeResult = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decodeSuccess then
        return { status = "error", text = "Error: Invalid API response format", color = COLOR_ERROR }
    end

    data = decodeResult

    if not data.success then
        return { status = "no_leaks", text = "No leaks found", color = COLOR_NO_LEAKS }
    end

    local found = data.found or 0
    local breaches = data.sources or {}

    if found > 0 then
        local resultText = found .. " leaks found:\n"
        for _, breach in ipairs(breaches) do
            local source = breach.name or "Unknown"
            local breachDate = breach.date or "Unknown date"
            resultText = resultText .. "- " .. source .. " (" .. breachDate .. ")\n"
        end
        local leakSound = Instance.new("Sound")
        leakSound.SoundId = LEAK_FOUND_SOUND_ID
        leakSound.Volume = 2
        leakSound.Parent = SoundService
        leakSound:Play()
        leakSound.Ended:Connect(function()
            leakSound:Destroy()
        end)
        return { status = "leaks", text = resultText, color = COLOR_LEAKS }
    else
        return { status = "no_leaks", text = "No leaks found", color = COLOR_NO_LEAKS }
    end
end

-- Query LeakCheck API via Proxy (POST request for exploiting context)
local function checkLeakCheck(username)
    local request = http_request or request or HttpPost or syn.request
    if not request then
        return { status = "error", text = "Executor does not support HTTP requests", color = COLOR_ERROR, showFreeScan = true }
    end

    local success, response = pcall(function()
        local payload = HttpService:JSONEncode({ username = username, type = "username" })
        local headers = { ["Content-Type"] = "application/json" }
        local webhookRequest = { Url = PROXY_URL, Body = payload, Method = "POST", Headers = headers }
        local result = request(webhookRequest)
        return result.Body
    end)

    if not success then
        return { status = "error", text = "Network error: " .. tostring(response), color = COLOR_ERROR, showFreeScan = true }
    end

    local data
    local decodeSuccess, decodeResult = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decodeSuccess then
        return { status = "error", text = "Error: Invalid API response format", color = COLOR_ERROR, showFreeScan = true }
    end

    data = decodeResult

    if data.error then
        local errorMsg = data.detail or data.error
        local errorText = "Proxy Error"
        local showFreeScan = false

        if errorMsg:lower():find("invalid x-api-key") then
            errorText = "Proxy Error (400): Invalid X-API-Key"
        elseif errorMsg:lower():find("invalid type") then
            errorText = "Proxy Error (400): Invalid search type"
        elseif errorMsg:lower():find("invalid email") then
            errorText = "Proxy Error (400): Invalid email format"
        elseif errorMsg:lower():find("invalid query") then
            errorText = "Proxy Error (400): Invalid query"
        elseif errorMsg:lower():find("invalid domain") then
            errorText = "Proxy Error (400): Invalid domain"
        elseif errorMsg:lower():find("too short query") then
            errorText = "Proxy Error (400): Query too short (< 3 characters)"
        elseif errorMsg:lower():find("invalid characters") then
            errorText = "Proxy Error (400): Invalid characters in query"
        elseif errorMsg:lower():find("missing x-api-key") then
            errorText = "Proxy Error (401): Missing X-API-Key"
        elseif errorMsg:lower():find("active plan required") then
            errorText = "Proxy Error (403): Active plan required"
            showFreeScan = true
        elseif errorMsg:lower():find("limit reached") then
            errorText = "Proxy Error (403): Query limit reached. Try again later."
            showFreeScan = true
        elseif errorMsg:lower():find("could not determine search type") then
            errorText = "Proxy Error (422): Could not determine search type"
        elseif errorMsg:lower():find("too many requests") then
            errorText = "Proxy Error (429): Too many requests (rate limit exceeded)"
            showFreeScan = true
        else
            errorText = "Proxy Error: " .. errorMsg
        end

        return { status = "error", text = errorText .. "\nTry free scan?", color = COLOR_ERROR, showFreeScan = showFreeScan }
    end

    local found = data.found or 0
    local quota = data.quota or 0
    local breaches = data.result or {}

    if found > 0 then
        local leaks = {}
        for _, breach in ipairs(breaches) do
            local source = breach.source and breach.source.name or "Unknown"
            local breachDate = breach.source and breach.source.breach_date or "Unknown date"
            local origin = breach.origin
            local originStr = "Unknown"
            if type(origin) == "table" and #origin > 0 then
                originStr = table.concat(origin, ", ")
            elseif origin then
                originStr = tostring(origin)
            end
            local fields = breach.fields or {}
            local leakData = {
                source = source,
                date = breachDate,
                origin = originStr,
                fields = {}
            }
            for _, field in ipairs(fields) do
                if breach[field] and field ~= "origin" then -- Exclude origin from fields since it's handled separately
                    leakData.fields[field] = breach[field]
                end
            end
            table.insert(leaks, leakData)
        end
        local resultText = found .. " leaks found"
        if quota < 10 then
            resultText = resultText .. "\nWarning: Low quota (" .. quota .. " remaining)"
        end
        local leakSound = Instance.new("Sound")
        leakSound.SoundId = LEAK_FOUND_SOUND_ID
        leakSound.Volume = 2
        leakSound.Parent = SoundService
        leakSound:Play()
        leakSound.Ended:Connect(function()
            leakSound:Destroy()
        end)
        return { status = "leaks", text = resultText, color = COLOR_LEAKS, leaks = leaks, found = found }
    else
        local resultText = "No leaks found"
        if quota < 10 then
            resultText = resultText .. "\nWarning: Low quota (" .. quota .. " remaining)"
        end
        return { status = "no_leaks", text = resultText, color = COLOR_NO_LEAKS }
    end
end

-- Create and show result pop-up
local function showResult(player, result)
    if playerResultWindows[player] then
        local frame = playerResultWindows[player].frame
        local resultList = frame:FindFirstChild("ResultList")
        local leaksFoundLabel = frame:FindFirstChild("LeaksFoundLabel")
        local freeScanButton = frame:FindFirstChild("FreeScanButton")
        local resultTitle = frame:FindFirstChild("ResultTitle")
        local closeButton = frame:FindFirstChild("CloseButton")
        local prevButton = frame:FindFirstChild("PrevButton")
        local nextButton = frame:FindFirstChild("NextButton")
        local pageLabel = frame:FindFirstChild("PageLabel")
        local currentLeakIndex = playerResultWindows[player].currentLeakIndex or 1
        local leaks = result.leaks or playerResultWindows[player].leaks or {}

        for _, child in ipairs(resultList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "FreeScanButton" and child.Name ~= "CloseButton" and child.Name ~= "PrevButton" and child.Name ~= "NextButton" then
                child:Destroy()
            end
        end

        if resultList then
            if result.status == "leaks" and #leaks > 0 then
                local leak = leaks[currentLeakIndex]
                local fieldsList = {
                    { field = "Source", value = leak.source, emoji = EMOJI_GLOBE },
                    { field = "Date", value = leak.date, emoji = EMOJI_CALENDAR }
                }
                if leak.origin and leak.origin ~= "Unknown" then
                    table.insert(fieldsList, { field = "Origin", value = leak.origin, emoji = EMOJI_GLOBE })
                end
                for field, value in pairs(leak.fields) do
                    table.insert(fieldsList, { field = field, value = tostring(value), emoji = nil })
                end

                local resultScroll = frame:FindFirstChild("ResultScroll")
                if resultScroll then
                    resultScroll.Size = UDim2.new(0.9, 0, #leaks > 1 and 0.7 or 0.8, 0)
                end

                if #fieldsList == 0 then
                    local noneLabel = Instance.new("TextButton")
                    noneLabel.Size = UDim2.new(1, 0, 0, 20)
                    noneLabel.BackgroundTransparency = 1
                    noneLabel.Text = "None"
                    noneLabel.TextColor3 = COLOR_TEXT
                    noneLabel.TextSize = 14
                    noneLabel.Font = Enum.Font.GothamBold
                    noneLabel.TextXAlignment = Enum.TextXAlignment.Left
                    noneLabel.TextTransparency = 1
                    noneLabel.AutoButtonColor = false
                    noneLabel.Parent = resultList
                    noneLabel.MouseButton1Click:Connect(function()
                        setclipboard("None")
                        TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
                        task.delay(0.2, function()
                            TweenService:Create(noneLabel, TweenInfo.new(1.8), { TextColor3 = COLOR_TEXT }):Play()
                        end)
                    end)
                    noneLabel.MouseEnter:Connect(function()
                        TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
                    end)
                    noneLabel.MouseLeave:Connect(function()
                        TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
                    end)
                else
                    for _, entry in ipairs(fieldsList) do
                        local fieldLabel = Instance.new("TextButton")
                        fieldLabel.Size = UDim2.new(1, 0, 0, 20)
                        fieldLabel.BackgroundTransparency = 1
                        fieldLabel.Text = (entry.emoji or "") .. " " .. capitalize(entry.field)
                        fieldLabel.TextColor3 = COLOR_TEXT
                        fieldLabel.TextSize = 14
                        fieldLabel.Font = Enum.Font.GothamBold
                        fieldLabel.TextXAlignment = Enum.TextXAlignment.Left
                        fieldLabel.TextTransparency = 1
                        fieldLabel.AutoButtonColor = false
                        fieldLabel.Parent = resultList
                        fieldLabel.MouseEnter:Connect(function()
                            TweenService:Create(fieldLabel, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
                        end)
                        fieldLabel.MouseLeave:Connect(function()
                            TweenService:Create(fieldLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
                        end)

                        local valueButton = Instance.new("TextButton")
                        valueButton.Size = UDim2.new(1, 0, 0, 20)
                        valueButton.BackgroundTransparency = 1
                        valueButton.Text = "  " .. entry.value
                        valueButton.TextColor3 = COLOR_TEXT
                        valueButton.TextSize = 14
                        valueButton.Font = Enum.Font.Gotham
                        valueButton.TextXAlignment = Enum.TextXAlignment.Left
                        valueButton.TextTransparency = 1
                        valueButton.AutoButtonColor = false
                        valueButton.Parent = resultList
                        valueButton.MouseButton1Click:Connect(function()
                            setclipboard(entry.value)
                            TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
                            task.delay(0.2, function()
                                TweenService:Create(valueButton, TweenInfo.new(1.8), { TextColor3 = COLOR_TEXT }):Play()
                            end)
                        end)
                        valueButton.MouseEnter:Connect(function()
                            TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
                        end)
                        valueButton.MouseLeave:Connect(function()
                            TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
                        end)
                    end
                end
                leaksFoundLabel.Text = #leaks == 1 and "Leaks Found" or tostring(#leaks) .. " Leaks Found"
                leaksFoundLabel.Visible = true
            else
                local textButton = Instance.new("TextButton")
                textButton.Size = UDim2.new(1, 0, 0, 20)
                textButton.Position = UDim2.new(0, 0, 0, 40)
                textButton.BackgroundTransparency = 1
                textButton.Text = result.text or "No leaks found"
                textButton.TextColor3 = result.color or COLOR_NO_LEAKS
                textButton.TextSize = 16
                textButton.Font = Enum.Font.GothamBold
                textButton.TextXAlignment = Enum.TextXAlignment.Center
                textButton.TextWrapped = true
                textButton.TextTransparency = 0
                textButton.AutoButtonColor = false
                textButton.Parent = frame
                textButton.Visible = true
                textButton.MouseButton1Click:Connect(function()
                    setclipboard(result.text or "No leaks found")
                    TweenService:Create(textButton, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
                    task.delay(0.2, function()
                        TweenService:Create(textButton, TweenInfo.new(1.8), { TextColor3 = result.color or COLOR_NO_LEAKS }):Play()
                    end)
                end)
                textButton.MouseEnter:Connect(function()
                    local r, g, b = (result.color or COLOR_NO_LEAKS).R * 255, (result.color or COLOR_NO_LEAKS).G * 255, (result.color or COLOR_NO_LEAKS).B * 255
                    local brighter = Color3.fromRGB(math.min(r + 50, 255), math.min(g + 50, 255), math.min(b + 50, 255))
                    TweenService:Create(textButton, TweenInfo.new(0.2), { TextColor3 = brighter }):Play()
                end)
                textButton.MouseLeave:Connect(function()
                    TweenService:Create(textButton, TweenInfo.new(0.2), { TextColor3 = result.color or COLOR_NO_LEAKS }):Play()
                end)
                leaksFoundLabel.Visible = false
                local resultScroll = frame:FindFirstChild("ResultScroll")
                if resultScroll then
                    resultScroll.Size = UDim2.new(0.9, 0, 0.8, 0)
                end
            end
        end

        if freeScanButton then
            freeScanButton.Visible = result.showFreeScan or false
        end

        if prevButton and nextButton and pageLabel then
            prevButton.Visible = #leaks > 1
            nextButton.Visible = #leaks > 1
            pageLabel.Visible = #leaks > 1
            pageLabel.Text = tostring(currentLeakIndex) .. " / " .. tostring(#leaks)
            prevButton.BackgroundTransparency = currentLeakIndex == 1 and 0.8 or 0.2
            prevButton.TextTransparency = currentLeakIndex == 1 and 0.8 or 0
            nextButton.BackgroundTransparency = currentLeakIndex == #leaks and 0.8 or 0.2
            nextButton.TextTransparency = currentLeakIndex == #leaks and 0.8 or 0
            if prevButton.Visible then
                prevButton.BackgroundTransparency = currentLeakIndex == 1 and 0.8 or 0.2
                prevButton.TextTransparency = currentLeakIndex == 1 and 0.8 or 0
            end
            if nextButton.Visible then
                nextButton.BackgroundTransparency = currentLeakIndex == #leaks and 0.8 or 0.2
                nextButton.TextTransparency = currentLeakIndex == #leaks and 0.8 or 0
            end
        end

        frame.Visible = true
        TweenService:Create(frame, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 }):Play()
        TweenService:Create(resultTitle, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
        TweenService:Create(leaksFoundLabel, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
        TweenService:Create(closeButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.2, TextTransparency = 0 }):Play()
        if freeScanButton and freeScanButton.Visible then
            TweenService:Create(freeScanButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.2, TextTransparency = 0 }):Play()
        end
        if prevButton and prevButton.Visible then
            TweenService:Create(prevButton, TweenInfo.new(0.2), { BackgroundTransparency = prevButton.BackgroundTransparency, TextTransparency = prevButton.TextTransparency }):Play()
        end
        if nextButton and nextButton.Visible then
            TweenService:Create(nextButton, TweenInfo.new(0.2), { BackgroundTransparency = nextButton.BackgroundTransparency, TextTransparency = nextButton.TextTransparency }):Play()
        end
        if pageLabel and pageLabel.Visible then
            TweenService:Create(pageLabel, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
        end
        for _, child in ipairs(resultList:GetChildren()) do
            if child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
            end
        end
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "FreeScanButton" and child.Name ~= "CloseButton" and child.Name ~= "PrevButton" and child.Name ~= "NextButton" then
                TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
            end
        end

        playerResultWindows[player].leaks = leaks
        playerResultWindows[player].currentLeakIndex = currentLeakIndex
        return
    end

    local ResultFrame = Instance.new("Frame")
    ResultFrame.Size = UDim2.new(0, 350, 0, 300)
    ResultFrame.BackgroundColor3 = WINDOW_BG
    ResultFrame.BackgroundTransparency = 1
    ResultFrame.Visible = false
    ResultFrame.Name = "ResultFrame_" .. player.Name
    ResultFrame.Parent = ScreenGui

    local ResultCorner = Instance.new("UICorner")
    ResultCorner.CornerRadius = UDim.new(0, 12)
    ResultCorner.Parent = ResultFrame

    local ResultTitle = Instance.new("TextLabel")
    ResultTitle.Name = "ResultTitle"
    ResultTitle.Size = UDim2.new(1, 0, 0, 40)
    ResultTitle.BackgroundTransparency = 1
    ResultTitle.Text = player.Name
    ResultTitle.TextColor3 = COLOR_ACCENT
    ResultTitle.TextSize = 20
    ResultTitle.Font = Enum.Font.GothamBlack
    ResultTitle.TextTransparency = 1
    ResultTitle.Parent = ResultFrame

    local LeaksFoundLabel = Instance.new("TextLabel")
    LeaksFoundLabel.Name = "LeaksFoundLabel"
    LeaksFoundLabel.Size = UDim2.new(1, 0, 0, 20)
    LeaksFoundLabel.Position = UDim2.new(0, 0, 0, 40)
    LeaksFoundLabel.BackgroundTransparency = 1
    LeaksFoundLabel.Text = (result.leaks and #result.leaks or 0) .. " Leaks Found"
    LeaksFoundLabel.TextColor3 = COLOR_LEAKS
    LeaksFoundLabel.TextSize = 16
    LeaksFoundLabel.Font = Enum.Font.GothamBold
    LeaksFoundLabel.TextTransparency = 1
    LeaksFoundLabel.Visible = result.status == "leaks" and result.leaks and #result.leaks > 0
    LeaksFoundLabel.Parent = ResultFrame

    local ResultScroll = Instance.new("ScrollingFrame")
    ResultScroll.Name = "ResultScroll"
    local scrollHeight = (result.status == "leaks" and result.leaks and #result.leaks > 1) and 0.7 or 0.8
    ResultScroll.Size = UDim2.new(0.9, 0, scrollHeight, 0)
    ResultScroll.Position = UDim2.new(0.05, 0, 0.15, 0)
    ResultScroll.BackgroundTransparency = 1
    ResultScroll.BorderSizePixel = 0
    ResultScroll.ScrollBarThickness = 4
    ResultScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ResultScroll.Parent = ResultFrame

    local ResultList = Instance.new("Frame")
    ResultList.Name = "ResultList"
    ResultList.Size = UDim2.new(1, 0, 1, 0)
    ResultList.BackgroundTransparency = 1
    ResultList.Parent = ResultScroll

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 5)
    ListLayout.Parent = ResultList

    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ResultScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
    end)

    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -40, 0, 10)
    CloseButton.BackgroundColor3 = COLOR_ACCENT
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 16
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextTransparency = 1
    CloseButton.Parent = ResultFrame

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton

    local FreeScanButton = Instance.new("TextButton")
    FreeScanButton.Name = "FreeScanButton"
    FreeScanButton.Size = UDim2.new(0, 100, 0, 30)
    FreeScanButton.Position = UDim2.new(0.5, -50, 0, 230)
    FreeScanButton.BackgroundColor3 = COLOR_ACCENT
    FreeScanButton.BackgroundTransparency = 1
    FreeScanButton.Text = "Free Scan"
    FreeScanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    FreeScanButton.TextSize = 16
    FreeScanButton.Font = Enum.Font.GothamBold
    FreeScanButton.TextTransparency = 1
    FreeScanButton.Visible = result.showFreeScan or false
    FreeScanButton.Parent = ResultFrame

    local FreeScanCorner = Instance.new("UICorner")
    FreeScanCorner.CornerRadius = UDim.new(0, 8)
    FreeScanCorner.Parent = FreeScanButton

    local PrevButton = Instance.new("TextButton")
    PrevButton.Name = "PrevButton"
    PrevButton.Size = UDim2.new(0, 70, 0, 30)
    PrevButton.Position = UDim2.new(0.05, 0, 0, 265)
    PrevButton.BackgroundColor3 = COLOR_ACCENT
    PrevButton.BackgroundTransparency = 1
    PrevButton.Text = "< Previous"
    PrevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    PrevButton.TextSize = 14
    PrevButton.Font = Enum.Font.GothamBold
    PrevButton.TextTransparency = 1
    PrevButton.Visible = result.status == "leaks" and result.leaks and #result.leaks > 1
    PrevButton.Parent = ResultFrame

    local PrevCorner = Instance.new("UICorner")
    PrevCorner.CornerRadius = UDim.new(0, 8)
    PrevCorner.Parent = PrevButton

    local NextButton = Instance.new("TextButton")
    NextButton.Name = "NextButton"
    NextButton.Size = UDim2.new(0, 70, 0, 30)
    NextButton.Position = UDim2.new(0.75, 0, 0, 265)
    NextButton.BackgroundColor3 = COLOR_ACCENT
    NextButton.BackgroundTransparency = 1
    NextButton.Text = "Next >"
    NextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    NextButton.TextSize = 14
    NextButton.Font = Enum.Font.GothamBold
    NextButton.TextTransparency = 1
    NextButton.Visible = result.status == "leaks" and result.leaks and #result.leaks > 1
    NextButton.Parent = ResultFrame

    local NextCorner = Instance.new("UICorner")
    NextCorner.CornerRadius = UDim.new(0, 8)
    NextCorner.Parent = NextButton

    local PageLabel = Instance.new("TextLabel")
    PageLabel.Name = "PageLabel"
    PageLabel.Size = UDim2.new(0, 50, 0, 30)
    PageLabel.Position = UDim2.new(0.5, -25, 0, 265)
    PageLabel.BackgroundTransparency = 1
    PageLabel.Text = "1 / " .. tostring(result.leaks and #result.leaks or 1)
    PageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    PageLabel.TextSize = 14
    PageLabel.Font = Enum.Font.GothamBold
    PageLabel.TextTransparency = 1
    PageLabel.Visible = result.status == "leaks" and result.leaks and #result.leaks > 1
    PageLabel.Parent = ResultFrame

    playerResultWindows[player] = {
        frame = ResultFrame,
        connection = nil,
        freeScanConnection = nil,
        currentLeakIndex = 1,
        leaks = result.leaks or {}
    }

    if result.status == "leaks" and result.leaks and #result.leaks > 0 then
        local leak = result.leaks[1]
        local fieldsList = {
            { field = "Source", value = leak.source, emoji = EMOJI_GLOBE },
            { field = "Date", value = leak.date, emoji = EMOJI_CALENDAR }
        }
        if leak.origin and leak.origin ~= "Unknown" then
            table.insert(fieldsList, { field = "Origin", value = leak.origin, emoji = EMOJI_GLOBE })
        end
        for field, value in pairs(leak.fields) do
            table.insert(fieldsList, { field = field, value = tostring(value), emoji = nil })
        end

        ResultScroll.Size = UDim2.new(0.9, 0, #result.leaks > 1 and 0.7 or 0.8, 0)

        if #fieldsList == 0 then
            local noneLabel = Instance.new("TextButton")
            noneLabel.Size = UDim2.new(1, 0, 0, 20)
            noneLabel.BackgroundTransparency = 1
            noneLabel.Text = "None"
            noneLabel.TextColor3 = COLOR_TEXT
            noneLabel.TextSize = 14
            noneLabel.Font = Enum.Font.GothamBold
            noneLabel.TextXAlignment = Enum.TextXAlignment.Left
            noneLabel.TextTransparency = 1
            noneLabel.AutoButtonColor = false
            noneLabel.Parent = ResultList
            noneLabel.MouseButton1Click:Connect(function()
                setclipboard("None")
                TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
                task.delay(0.2, function()
                    TweenService:Create(noneLabel, TweenInfo.new(1.8), { TextColor3 = COLOR_TEXT }):Play()
                end)
            end)
            noneLabel.MouseEnter:Connect(function()
                TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
            end)
            noneLabel.MouseLeave:Connect(function()
                TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
            end)
        else
            for _, entry in ipairs(fieldsList) do
                local fieldLabel = Instance.new("TextButton")
                fieldLabel.Size = UDim2.new(1, 0, 0, 20)
                fieldLabel.BackgroundTransparency = 1
                fieldLabel.Text = (entry.emoji or "") .. " " .. capitalize(entry.field)
                fieldLabel.TextColor3 = COLOR_TEXT
                fieldLabel.TextSize = 14
                fieldLabel.Font = Enum.Font.GothamBold
                fieldLabel.TextXAlignment = Enum.TextXAlignment.Left
                fieldLabel.TextTransparency = 1
                fieldLabel.AutoButtonColor = false
                fieldLabel.Parent = ResultList
                fieldLabel.MouseEnter:Connect(function()
                    TweenService:Create(fieldLabel, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
                end)
                fieldLabel.MouseLeave:Connect(function()
                    TweenService:Create(fieldLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
                end)

                local valueButton = Instance.new("TextButton")
                valueButton.Size = UDim2.new(1, 0, 0, 20)
                valueButton.BackgroundTransparency = 1
                valueButton.Text = "  " .. entry.value
                valueButton.TextColor3 = COLOR_TEXT
                valueButton.TextSize = 14
                valueButton.Font = Enum.Font.Gotham
                valueButton.TextXAlignment = Enum.TextXAlignment.Left
                valueButton.TextTransparency = 1
                valueButton.AutoButtonColor = false
                valueButton.Parent = ResultList
                valueButton.MouseButton1Click:Connect(function()
                    setclipboard(entry.value)
                    TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
                    task.delay(0.2, function()
                        TweenService:Create(valueButton, TweenInfo.new(1.8), { TextColor3 = COLOR_TEXT }):Play()
                    end)
                end)
                valueButton.MouseEnter:Connect(function()
                    TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
                end)
                valueButton.MouseLeave:Connect(function()
                    TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
                end)
            end
        end

        PrevButton.BackgroundTransparency = 0.8
        PrevButton.TextTransparency = 0.8
        NextButton.BackgroundTransparency = #result.leaks == 1 and 0.8 or 0.2
        NextButton.TextTransparency = #result.leaks == 1 and 0.8 or 0
        PageLabel.Text = "1 / " .. tostring(#result.leaks)
        LeaksFoundLabel.Text = #result.leaks == 1 and "Leaks Found" or tostring(#result.leaks) .. " Leaks Found"
    else
        local textButton = Instance.new("TextButton")
        textButton.Size = UDim2.new(1, 0, 0, 20)
        textButton.Position = UDim2.new(0, 0, 0, 40)
        textButton.BackgroundTransparency = 1
        textButton.Text = result.text or "No leaks found"
        textButton.TextColor3 = result.color or COLOR_NO_LEAKS
        textButton.TextSize = 16
        textButton.Font = Enum.Font.GothamBold
        textButton.TextXAlignment = Enum.TextXAlignment.Center
        textButton.TextWrapped = true
        textButton.TextTransparency = 0
        textButton.AutoButtonColor = false
        textButton.Parent = ResultFrame
        textButton.Visible = true
        textButton.MouseButton1Click:Connect(function()
            setclipboard(result.text or "No leaks found")
            TweenService:Create(textButton, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
            task.delay(0.2, function()
                TweenService:Create(textButton, TweenInfo.new(1.8), { TextColor3 = result.color or COLOR_NO_LEAKS }):Play()
            end)
        end)
        textButton.MouseEnter:Connect(function()
            local r, g, b = (result.color or COLOR_NO_LEAKS).R * 255, (result.color or COLOR_NO_LEAKS).G * 255, (result.color or COLOR_NO_LEAKS).B * 255
            local brighter = Color3.fromRGB(math.min(r + 50, 255), math.min(g + 50, 255), math.min(b + 50, 255))
            TweenService:Create(textButton, TweenInfo.new(0.2), { TextColor3 = brighter }):Play()
        end)
        textButton.MouseLeave:Connect(function()
            TweenService:Create(textButton, TweenInfo.new(0.2), { TextColor3 = result.color or COLOR_NO_LEAKS }):Play()
        end)
        ResultScroll.Size = UDim2.new(0.9, 0, 0.8, 0)
    end

    PrevButton.MouseButton1Click:Connect(function()
        if not playerResultWindows[player] or playerResultWindows[player].currentLeakIndex <= 1 then return end
        playerResultWindows[player].currentLeakIndex = playerResultWindows[player].currentLeakIndex - 1
        for _, child in ipairs(ResultList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        local leak = playerResultWindows[player].leaks[playerResultWindows[player].currentLeakIndex]
        local fieldsList = {
            { field = "Source", value = leak.source, emoji = EMOJI_GLOBE },
            { field = "Date", value = leak.date, emoji = EMOJI_CALENDAR }
        }
        if leak.origin and leak.origin ~= "Unknown" then
            table.insert(fieldsList, { field = "Origin", value = leak.origin, emoji = EMOJI_GLOBE })
        end
        for field, value in pairs(leak.fields) do
            table.insert(fieldsList, { field = field, value = tostring(value), emoji = nil })
        end

        local resultScroll = ResultFrame:FindFirstChild("ResultScroll")
        if resultScroll then
            resultScroll.Size = UDim2.new(0.9, 0, #playerResultWindows[player].leaks > 1 and 0.7 or 0.8, 0)
        end

        if #fieldsList == 0 then
            local noneLabel = Instance.new("TextButton")
            noneLabel.Size = UDim2.new(1, 0, 0, 20)
            noneLabel.BackgroundTransparency = 1
            noneLabel.Text = "None"
            noneLabel.TextColor3 = COLOR_TEXT
            noneLabel.TextSize = 14
            noneLabel.Font = Enum.Font.GothamBold
            noneLabel.TextXAlignment = Enum.TextXAlignment.Left
            noneLabel.TextTransparency = 0
            noneLabel.AutoButtonColor = false
            noneLabel.Parent = ResultList
            noneLabel.MouseButton1Click:Connect(function()
                setclipboard("None")
                TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
                task.delay(0.2, function()
                    TweenService:Create(noneLabel, TweenInfo.new(1.8), { TextColor3 = COLOR_TEXT }):Play()
                end)
            end)
            noneLabel.MouseEnter:Connect(function()
                TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
            end)
            noneLabel.MouseLeave:Connect(function()
                TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
            end)
        else
            for _, entry in ipairs(fieldsList) do
                local fieldLabel = Instance.new("TextButton")
                fieldLabel.Size = UDim2.new(1, 0, 0, 20)
                fieldLabel.BackgroundTransparency = 1
                fieldLabel.Text = (entry.emoji or "") .. " " .. capitalize(entry.field)
                fieldLabel.TextColor3 = COLOR_TEXT
                fieldLabel.TextSize = 14
                fieldLabel.Font = Enum.Font.GothamBold
                fieldLabel.TextXAlignment = Enum.TextXAlignment.Left
                fieldLabel.TextTransparency = 0
                fieldLabel.AutoButtonColor = false
                fieldLabel.Parent = ResultList
                fieldLabel.MouseEnter:Connect(function()
                    TweenService:Create(fieldLabel, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
                end)
                fieldLabel.MouseLeave:Connect(function()
                    TweenService:Create(fieldLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
                end)

                local valueButton = Instance.new("TextButton")
                valueButton.Size = UDim2.new(1, 0, 0, 20)
                valueButton.BackgroundTransparency = 1
                valueButton.Text = "  " .. entry.value
                valueButton.TextColor3 = COLOR_TEXT
                valueButton.TextSize = 14
                valueButton.Font = Enum.Font.Gotham
                valueButton.TextXAlignment = Enum.TextXAlignment.Left
                valueButton.TextTransparency = 0
                valueButton.AutoButtonColor = false
                valueButton.Parent = ResultList
                valueButton.MouseButton1Click:Connect(function()
                    setclipboard(entry.value)
                    TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
                    task.delay(0.2, function()
                        TweenService:Create(valueButton, TweenInfo.new(1.8), { TextColor3 = COLOR_TEXT }):Play()
                    end)
                end)
                valueButton.MouseEnter:Connect(function()
                    TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
                end)
                valueButton.MouseLeave:Connect(function()
                    TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
                end)
            end
        end

        PageLabel.Text = tostring(playerResultWindows[player].currentLeakIndex) .. " / " .. tostring(#playerResultWindows[player].leaks)
        PrevButton.BackgroundTransparency = playerResultWindows[player].currentLeakIndex == 1 and 0.8 or 0.2
        PrevButton.TextTransparency = playerResultWindows[player].currentLeakIndex == 1 and 0.8 or 0
        NextButton.BackgroundTransparency = playerResultWindows[player].currentLeakIndex == #playerResultWindows[player].leaks and 0.8 or 0.2
        NextButton.TextTransparency = playerResultWindows[player].currentLeakIndex == #playerResultWindows[player].leaks and 0.8 or 0
    end)

    NextButton.MouseButton1Click:Connect(function()
        if not playerResultWindows[player] or playerResultWindows[player].currentLeakIndex >= #playerResultWindows[player].leaks then return end
        playerResultWindows[player].currentLeakIndex = playerResultWindows[player].currentLeakIndex + 1
        for _, child in ipairs(ResultList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        local leak = playerResultWindows[player].leaks[playerResultWindows[player].currentLeakIndex]
        local fieldsList = {
            { field = "Source", value = leak.source, emoji = EMOJI_GLOBE },
            { field = "Date", value = leak.date, emoji = EMOJI_CALENDAR }
        }
        if leak.origin and leak.origin ~= "Unknown" then
            table.insert(fieldsList, { field = "Origin", value = leak.origin, emoji = EMOJI_GLOBE })
        end
        for field, value in pairs(leak.fields) do
            table.insert(fieldsList, { field = field, value = tostring(value), emoji = nil })
        end

        local resultScroll = ResultFrame:FindFirstChild("ResultScroll")
        if resultScroll then
            resultScroll.Size = UDim2.new(0.9, 0, #playerResultWindows[player].leaks > 1 and 0.7 or 0.8, 0)
        end

        if #fieldsList == 0 then
            local noneLabel = Instance.new("TextButton")
            noneLabel.Size = UDim2.new(1, 0, 0, 20)
            noneLabel.BackgroundTransparency = 1
            noneLabel.Text = "None"
            noneLabel.TextColor3 = COLOR_TEXT
            noneLabel.TextSize = 14
            noneLabel.Font = Enum.Font.GothamBold
            noneLabel.TextXAlignment = Enum.TextXAlignment.Left
            noneLabel.TextTransparency = 0
            noneLabel.AutoButtonColor = false
            noneLabel.Parent = ResultList
            noneLabel.MouseButton1Click:Connect(function()
                setclipboard("None")
                TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
                task.delay(0.2, function()
                    TweenService:Create(noneLabel, TweenInfo.new(1.8), { TextColor3 = COLOR_TEXT }):Play()
                end)
            end)
            noneLabel.MouseEnter:Connect(function()
                TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
            end)
            noneLabel.MouseLeave:Connect(function()
                TweenService:Create(noneLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
            end)
        else
            for _, entry in ipairs(fieldsList) do
                local fieldLabel = Instance.new("TextButton")
                fieldLabel.Size = UDim2.new(1, 0, 0, 20)
                fieldLabel.BackgroundTransparency = 1
                fieldLabel.Text = (entry.emoji or "") .. " " .. capitalize(entry.field)
                fieldLabel.TextColor3 = COLOR_TEXT
                fieldLabel.TextSize = 14
                fieldLabel.Font = Enum.Font.GothamBold
                fieldLabel.TextXAlignment = Enum.TextXAlignment.Left
                fieldLabel.TextTransparency = 0
                fieldLabel.AutoButtonColor = false
                fieldLabel.Parent = ResultList
                fieldLabel.MouseEnter:Connect(function()
                    TweenService:Create(fieldLabel, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
                end)
                fieldLabel.MouseLeave:Connect(function()
                    TweenService:Create(fieldLabel, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
                end)

                local valueButton = Instance.new("TextButton")
                valueButton.Size = UDim2.new(1, 0, 0, 20)
                valueButton.BackgroundTransparency = 1
                valueButton.Text = "  " .. entry.value
                valueButton.TextColor3 = COLOR_TEXT
                valueButton.TextSize = 14
                valueButton.Font = Enum.Font.Gotham
                valueButton.TextXAlignment = Enum.TextXAlignment.Left
                valueButton.TextTransparency = 0
                valueButton.AutoButtonColor = false
                valueButton.Parent = ResultList
                valueButton.MouseButton1Click:Connect(function()
                    setclipboard(entry.value)
                    TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
                    task.delay(0.2, function()
                        TweenService:Create(valueButton, TweenInfo.new(1.8), { TextColor3 = COLOR_TEXT }):Play()
                    end)
                end)
                valueButton.MouseEnter:Connect(function()
                    TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(200, 200, 200) }):Play()
                end)
                valueButton.MouseLeave:Connect(function()
                    TweenService:Create(valueButton, TweenInfo.new(0.2), { TextColor3 = COLOR_TEXT }):Play()
                end)
            end
        end

        PageLabel.Text = tostring(playerResultWindows[player].currentLeakIndex) .. " / " .. tostring(#playerResultWindows[player].leaks)
        PrevButton.BackgroundTransparency = 0.2
        PrevButton.TextTransparency = 0
        NextButton.BackgroundTransparency = playerResultWindows[player].currentLeakIndex == #playerResultWindows[player].leaks and 0.8 or 0.2
        NextButton.TextTransparency = playerResultWindows[player].currentLeakIndex == #playerResultWindows[player].leaks and 0.8 or 0
    end)

    if FreeScanButton.Visible then
        playerResultWindows[player].freeScanConnection = FreeScanButton.MouseButton1Click:Connect(function()
            local freeResult = checkLeakCheckFree(player.Name)
            for _, child in ipairs(ResultList:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            for _, child in ipairs(ResultFrame:GetChildren()) do
                if child:IsA("TextButton") and child.Name ~= "FreeScanButton" and child.Name ~= "CloseButton" and child.Name ~= "PrevButton" and child.Name ~= "NextButton" then
                    child:Destroy()
                end
            end
            local textButton = Instance.new("TextButton")
            textButton.Size = UDim2.new(1, 0, 0, 20)
            textButton.Position = UDim2.new(0, 0, 0, 40)
            textButton.BackgroundTransparency = 1
            textButton.Text = freeResult.text or "No leaks found"
            textButton.TextColor3 = freeResult.color or COLOR_NO_LEAKS
            textButton.TextSize = 16
            textButton.Font = Enum.Font.GothamBold
            textButton.TextXAlignment = Enum.TextXAlignment.Center
            textButton.TextWrapped = true
            textButton.TextTransparency = 0
            textButton.AutoButtonColor = false
            textButton.Parent = ResultFrame
            textButton.Visible = true
            textButton.MouseButton1Click:Connect(function()
                setclipboard(freeResult.text or "No leaks found")
                TweenService:Create(textButton, TweenInfo.new(0.2), { TextColor3 = COLOR_COPIED }):Play()
                task.delay(0.2, function()
                    TweenService:Create(textButton, TweenInfo.new(1.8), { TextColor3 = freeResult.color or COLOR_NO_LEAKS }):Play()
                end)
            end)
            textButton.MouseEnter:Connect(function()
                local r, g, b = (freeResult.color or COLOR_NO_LEAKS).R * 255, (freeResult.color or COLOR_NO_LEAKS).G * 255, (freeResult.color or COLOR_NO_LEAKS).B * 255
                local brighter = Color3.fromRGB(math.min(r + 50, 255), math.min(g + 50, 255), math.min(b + 50, 255))
                TweenService:Create(textButton, TweenInfo.new(0.2), { TextColor3 = brighter }):Play()
            end)
            textButton.MouseLeave:Connect(function()
                TweenService:Create(textButton, TweenInfo.new(0.2), { TextColor3 = freeResult.color or COLOR_NO_LEAKS }):Play()
            end)

            FreeScanButton.Visible = freeResult.showFreeScan or false
            PrevButton.Visible = false
            NextButton.Visible = false
            PageLabel.Visible = false
            LeaksFoundLabel.Visible = false
            playerResultWindows[player].leaks = {}
            playerResultWindows[player].currentLeakIndex = 1
            local resultScroll = ResultFrame:FindFirstChild("ResultScroll")
            if resultScroll then
                resultScroll.Size = UDim2.new(0.9, 0, 0.8, 0)
            end
        end)
    end

    CloseButton.MouseButton1Click:Connect(function()
        local fadeOut = TweenService:Create(ResultFrame, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
        local titleFadeOut = TweenService:Create(ResultTitle, TweenInfo.new(0.2), { TextTransparency = 1 })
        local leaksFadeOut = TweenService:Create(LeaksFoundLabel, TweenInfo.new(0.2), { TextTransparency = 1 })
        local closeFadeOut = TweenService:Create(CloseButton, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 })
        local freeScanFadeOut = TweenService:Create(FreeScanButton, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 })
        local prevFadeOut = TweenService:Create(PrevButton, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 })
        local nextFadeOut = TweenService:Create(NextButton, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 })
        local pageFadeOut = TweenService:Create(PageLabel, TweenInfo.new(0.2), { TextTransparency = 1 })
        fadeOut:Play()
        titleFadeOut:Play()
        leaksFadeOut:Play()
        closeFadeOut:Play()
        freeScanFadeOut:Play()
        prevFadeOut:Play()
        nextFadeOut:Play()
        pageFadeOut:Play()
        for _, child in ipairs(ResultList:GetChildren()) do
            if child:IsA("TextButton") then
                TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
            end
        end
        for _, child in ipairs(ResultFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "FreeScanButton" and child.Name ~= "CloseButton" and child.Name ~= "PrevButton" and child.Name ~= "NextButton" then
                TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
            end
        end
        fadeOut.Completed:Connect(function()
            ResultFrame.Visible = false
            FreeScanButton.Visible = false
            if playerResultWindows[player] then
                if playerResultWindows[player].connection then
                    playerResultWindows[player].connection:Disconnect()
                end
                if playerResultWindows[player].freeScanConnection then
                    playerResultWindows[player].freeScanConnection:Disconnect()
                end
                ResultFrame:Destroy()
                playerResultWindows[player] = nil
            end
        end)
    end)

    local resultDragging, resultDragInput, resultDragStart, resultStartPos
    ResultFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resultDragging = true
            resultDragStart = input.Position
            resultStartPos = ResultFrame.Position
            if playerResultWindows[player] and playerResultWindows[player].connection then
                playerResultWindows[player].connection:Disconnect()
                playerResultWindows[player].connection = nil
            end
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resultDragging = false
                end
            end)
        end
    end)

    ResultFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            resultDragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == resultDragInput and resultDragging then
            local delta = input.Position - resultDragStart
            ResultFrame.Position = UDim2.new(resultStartPos.X.Scale, resultStartPos.X.Offset + delta.X, resultStartPos.Y.Scale, resultStartPos.Y.Offset + delta.Y)
        end
    end)

    ResultFrame.Visible = true
    TweenService:Create(ResultFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 }):Play()
    TweenService:Create(ResultTitle, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
    TweenService:Create(LeaksFoundLabel, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.2, TextTransparency = 0 }):Play()
    if FreeScanButton.Visible then
        TweenService:Create(FreeScanButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.2, TextTransparency = 0 }):Play()
    end
    if PrevButton.Visible then
        TweenService:Create(PrevButton, TweenInfo.new(0.2), { BackgroundTransparency = PrevButton.BackgroundTransparency, TextTransparency = PrevButton.TextTransparency }):Play()
    end
    if NextButton.Visible then
        TweenService:Create(NextButton, TweenInfo.new(0.2), { BackgroundTransparency = NextButton.BackgroundTransparency, TextTransparency = NextButton.TextTransparency }):Play()
    end
    if PageLabel.Visible then
        TweenService:Create(PageLabel, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
    end
    for _, child in ipairs(ResultList:GetChildren()) do
        if child:IsA("TextButton") then
            TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
        end
    end
    for _, child in ipairs(ResultFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name ~= "FreeScanButton" and child.Name ~= "CloseButton" and child.Name ~= "PrevButton" and child.Name ~= "NextButton" then
            TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
        end
    end

    local isFadingOut = false
    local lastDistance = math.huge
    playerResultWindows[player].connection = RunService.Heartbeat:Connect(function()
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local localPlayer = Players.LocalPlayer
            if localPlayer and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 3, 0))

                local viewportSize = workspace.CurrentCamera.ViewportSize
                local frameWidth = 350
                local frameHeight = 300
                local posX = math.clamp(screenPos.X - 175, 0, viewportSize.X - frameWidth)
                local posY = math.clamp(screenPos.Y - 200, 0, viewportSize.Y - frameHeight)
                ResultFrame.Position = UDim2.new(0, posX, 0, posY)

                if onScreen and distance <= SCAN_DISTANCE then
                    if isFadingOut or ResultFrame.BackgroundTransparency > 0.1 then
                        isFadingOut = false
                        TweenService:Create(ResultFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 }):Play()
                        TweenService:Create(ResultTitle, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
                        TweenService:Create(LeaksFoundLabel, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
                        TweenService:Create(CloseButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.2, TextTransparency = 0 }):Play()
                        if FreeScanButton.Visible then
                            TweenService:Create(FreeScanButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.2, TextTransparency = 0 }):Play()
                        end
                        if PrevButton.Visible then
                            TweenService:Create(PrevButton, TweenInfo.new(0.2), { BackgroundTransparency = PrevButton.BackgroundTransparency, TextTransparency = PrevButton.TextTransparency }):Play()
                        end
                        if NextButton.Visible then
                            TweenService:Create(NextButton, TweenInfo.new(0.2), { BackgroundTransparency = NextButton.BackgroundTransparency, TextTransparency = NextButton.TextTransparency }):Play()
                        end
                        if PageLabel.Visible then
                            TweenService:Create(PageLabel, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
                        end
                        for _, child in ipairs(ResultList:GetChildren()) do
                            if child:IsA("TextButton") then
                                TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
                            end
                        end
                        for _, child in ipairs(ResultFrame:GetChildren()) do
                            if child:IsA("TextButton") and child.Name ~= "FreeScanButton" and child.Name ~= "CloseButton" and child.Name ~= "PrevButton" and child.Name ~= "NextButton" then
                                TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
                            end
                        end
                    end
                    ResultFrame.Visible = true
                else
                    if not isFadingOut and ResultFrame.BackgroundTransparency < 1 then
                        isFadingOut = true
                        TweenService:Create(ResultFrame, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
                        TweenService:Create(ResultTitle, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
                        TweenService:Create(LeaksFoundLabel, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
                        TweenService:Create(CloseButton, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
                        if FreeScanButton.Visible then
                            TweenService:Create(FreeScanButton, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
                        end
                        if PrevButton.Visible then
                            TweenService:Create(PrevButton, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
                        end
                        if NextButton.Visible then
                            TweenService:Create(NextButton, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
                        end
                        if PageLabel.Visible then
                            TweenService:Create(PageLabel, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
                        end
                        for _, child in ipairs(ResultList:GetChildren()) do
                            if child:IsA("TextButton") then
                                TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
                            end
                        end
                        for _, child in ipairs(ResultFrame:GetChildren()) do
                            if child:IsA("TextButton") and child.Name ~= "FreeScanButton" and child.Name ~= "CloseButton" and child.Name ~= "PrevButton" and child.Name ~= "NextButton" then
                                TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
                            end
                        end
                    end
                    ResultFrame.Visible = ResultFrame.BackgroundTransparency < 1
                end
                lastDistance = distance
            end
        else
            ResultFrame.Visible = false
        end
    end)
end

-- Create scan button for a player
local function createScanButton(player)
    if playerScanButtons[player] then
        return
    end

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 80, 0, 30)
    button.BackgroundColor3 = COLOR_ACCENT
    button.BackgroundTransparency = 1
    button.Text = "Scan"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 16
    button.Font = Enum.Font.GothamBold
    button.TextTransparency = 1
    button.Visible = false
    button.Parent = ScreenGui

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    playerScanButtons[player] = {
        button = button,
        connection = nil
    }

    local function updateButton()
        if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Head") then
            button.Visible = false
            return
        end

        local head = player.Character.Head
        local localPlayer = Players.LocalPlayer
        if not localPlayer or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            button.Visible = false
            return
        end

        local distance = (player.Character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 3, 0))

        if onScreen and distance <= SCAN_DISTANCE and isScanningEnabled then
            button.Position = UDim2.new(0, screenPos.X - 40, 0, screenPos.Y)
            if button.BackgroundTransparency > 0 and not scanCooldown then
                TweenService:Create(button, TweenInfo.new(0.2), { BackgroundTransparency = 0.2, TextTransparency = 0 }):Play()
            end
            button.Visible = true
        else
            if button.BackgroundTransparency < 1 then
                local fadeOut = TweenService:Create(button, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextTransparency = 1 })
                fadeOut:Play()
                fadeOut.Completed:Connect(function()
                    button.Visible = false
                end)
            else
                button.Visible = false
            end
        end
    end

    playerScanButtons[player].connection = RunService.Heartbeat:Connect(updateButton)

    -- Scan button click with global cooldown
    button.MouseButton1Click:Connect(function()
        if not isScanningEnabled or scanCooldown then
            return
        end

        -- Start global cooldown
        scanCooldown = true
        cooldownEndTime = tick() + 3 -- 3 seconds from now

        -- Perform the scan
        local result = checkLeakCheck(player.Name)
        showResult(player, result)
    end)
end

-- Add cooldown update loop
RunService.Heartbeat:Connect(updateAllButtonsCooldown)

-- Initialize buttons for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Players.LocalPlayer then
        createScanButton(player)
    end
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
    if player ~= Players.LocalPlayer then
        createScanButton(player)
    end
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
    if playerScanButtons[player] then
        if playerScanButtons[player].connection then
            playerScanButtons[player].connection:Disconnect()
        end
        if playerScanButtons[player].button then
            playerScanButtons[player].button:Destroy()
        end
        playerScanButtons[player] = nil
    end
    if playerResultWindows[player] then
        if playerResultWindows[player].connection then
            playerResultWindows[player].connection:Disconnect()
        end
        if playerResultWindows[player].freeScanConnection then
            playerResultWindows[player].freeScanConnection:Disconnect()
        end
        if playerResultWindows[player].frame then
            playerResultWindows[player].frame:Destroy()
        end
        playerResultWindows[player] = nil
    end
end)
