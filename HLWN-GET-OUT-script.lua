local Repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(Repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(Repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(Repo .. 'addons/SaveManager.lua'))()

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local ColorCorrection = Lighting:FindFirstChild("EnhancedColorCorrection") or Instance.new("ColorCorrectionEffect")
ColorCorrection.Name = "EnhancedColorCorrection"
ColorCorrection.Parent = Lighting

local activeESPs = {}
local fovCircle = nil
local targetLine = Drawing.new("Line")
targetLine.Visible = false
targetLine.Thickness = 1.5
targetLine.Color = Color3.fromRGB(255, 0, 0)

local resolutions = {
    ["Standard"] = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["1080x1080"] = CFrame.new(0, 0, 0, 1, 0, 0, 0, 0.35, 0, 0, 0, 1),
    ["1920x1080"] = CFrame.new(0, 0, 0, 1, 0, 0, 0, 0.65, 0, 0, 0, 1),
    ["2560x1440"] = CFrame.new(0, 0, 0, 1, 0, 0, 0, 0.8895, 0, 0, 0, 1)
}

local Toggles = {
    EspEnabled = false,
    ShowNames = false,
    ShowHealth = false,
    ShowDistance = false,
    ShowTracers = false,
    TeamCheck = false,
    AimbotEnabled = false,
    ShowFOV = false,
    VisibleCheck = false,
    TargetLines = false,
    SpeedEnabled = false,
    NoCamShake = false,
    NoFog = false
}

local Options = {
    AimbotFOV = 150,
    AimbotSmoothness = 0.15,
    AimbotPart = "Head",
    TargetMode = "Closest",
    MaxEspDistance = 2000,
    WalkSpeed = 16,
    TimeOfDay = 12,
    Saturation = 0,
    Contrast = 0,
    CurrentRes = "Standard"
}

local function getStretchedViewportPoint(worldPos)
    local stretchCFrame = resolutions[Options.CurrentRes] or resolutions["Standard"]
    local camCF = Camera.CFrame
    local objectSpace = camCF:PointToObjectSpace(worldPos)
    local yScale = stretchCFrame.YVector.Y
    local stretchedObjectSpace = Vector3.new(objectSpace.X, objectSpace.Y / yScale, objectSpace.Z)
    local correctedWorldPos = camCF:PointToWorldSpace(stretchedObjectSpace)
    return Camera:WorldToViewportPoint(correctedWorldPos)
end

local function isVisible(targetPart)
    if not Toggles.VisibleCheck then return true end
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = destination - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, direction, raycastParams)
    if result then return result.Instance:IsDescendantOf(targetPart.Parent) end
    return false
end

local function updateFOV()
    if not fovCircle then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.NumSides = 64
        fovCircle.Filled = false
    end
    fovCircle.Visible = Toggles.AimbotEnabled and Toggles.ShowFOV
    fovCircle.Radius = Options.AimbotFOV
    fovCircle.Position = Camera.ViewportSize / 2
end

local function createESP(model)
    if activeESPs[model] then return end
    local drawings = {
        Outline = Drawing.new("Square"),
        Box = Drawing.new("Square"),
        NameTag = Drawing.new("Text"),
        DistanceTag = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthOutline = Drawing.new("Square"),
        Tracer = Drawing.new("Line")
    }
    
    drawings.Box.Thickness = 1
    drawings.Box.Color = Color3.new(1, 1, 1)
    drawings.Box.Filled = false
    drawings.Box.ZIndex = 2
    
    drawings.Outline.Thickness = 3
    drawings.Outline.Color = Color3.new(0, 0, 0)
    drawings.Outline.Filled = false
    drawings.Outline.ZIndex = 1
    
    drawings.NameTag.Center, drawings.NameTag.Outline, drawings.NameTag.Size = true, true, 13
    drawings.NameTag.Color = Color3.new(1, 1, 1)
    
    drawings.DistanceTag.Center, drawings.DistanceTag.Outline, drawings.DistanceTag.Size = true, true, 12
    drawings.DistanceTag.Color = Color3.new(1, 1, 1)
    
    drawings.HealthBar.Filled = true
    drawings.HealthBar.ZIndex = 2
    
    drawings.HealthOutline.Filled = true
    drawings.HealthOutline.Color = Color3.new(0, 0, 0)
    drawings.HealthOutline.ZIndex = 1
    
    drawings.Tracer.Thickness = 1
    drawings.Tracer.Color = Color3.new(1, 1, 1)
    
    activeESPs[model] = drawings
end

local function removeESP(model)
    if activeESPs[model] then
        for _, obj in pairs(activeESPs[model]) do obj:Remove() end
        activeESPs[model] = nil
    end
end

local function getTargetPosition(model)
    local targetPart = model:FindFirstChild(Options.AimbotPart)
    return targetPart or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

local function getBestTarget()
    local bestTarget = nil
    local lastMetric = math.huge 
    local targets = {}
    for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(targets, p.Character) end end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
            table.insert(targets, obj)
        end
    end

    for _, char in ipairs(targets) do
        local hum = char:FindFirstChildOfClass("Humanoid")
        local player = Players:GetPlayerFromCharacter(char)
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and char ~= LocalPlayer.Character and root then
            if Toggles.TeamCheck and player and player.Team == LocalPlayer.Team then continue end
            local part = getTargetPosition(char)
            if not part then continue end
            local screenPos, onScreen = getStretchedViewportPoint(part.Position)
            if onScreen and isVisible(part) then
                local mouseDist = (Vector2.new(screenPos.X, screenPos.Y) - Camera.ViewportSize/2).Magnitude
                local charDist = (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if mouseDist <= Options.AimbotFOV then
                    local metric = (Options.TargetMode == "Closest") and charDist or hum.Health
                    if metric < lastMetric then lastMetric = metric; bestTarget = part end
                end
            end
        end
    end
    return bestTarget
end

RunService.RenderStepped:Connect(function()
    updateFOV()

    Camera.CFrame = Camera.CFrame * (resolutions[Options.CurrentRes] or resolutions["Standard"])

    ColorCorrection.Saturation = Options.Saturation
    ColorCorrection.Contrast = Options.Contrast
    if Toggles.NoFog then
        Lighting.FogEnd = 999999
        if Lighting:FindFirstChildOfClass("Atmosphere") then
            Lighting:FindFirstChildOfClass("Atmosphere").Density = 0
        end
    end

    if Toggles.SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Options.WalkSpeed
    end

    Lighting.ClockTime = Options.TimeOfDay

    local target = getBestTarget()
    if Toggles.AimbotEnabled and target then
        local screenPos, onScreen = getStretchedViewportPoint(target.Position)
        if onScreen and Toggles.TargetLines then
            targetLine.Visible = true
            targetLine.From = Camera.ViewportSize / 2
            targetLine.To = Vector2.new(screenPos.X, screenPos.Y)
        else targetLine.Visible = false end

        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local mousePos = UserInputService:GetMouseLocation()
            mousemoverel((screenPos.X - mousePos.X) * Options.AimbotSmoothness, (screenPos.Y - mousePos.Y) * Options.AimbotSmoothness)
        end
    else targetLine.Visible = false end

    for model, drawings in pairs(activeESPs) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        if not model.Parent or not hum or hum.Health <= 0 or not root then
            removeESP(model)
            continue
        end

        local distance = (root.Position - Camera.CFrame.Position).Magnitude
        local screenPos, onScreen = getStretchedViewportPoint(root.Position)

        if onScreen and Toggles.EspEnabled and distance <= Options.MaxEspDistance then
            local headPos = getStretchedViewportPoint(root.Position + Vector3.new(0, 3, 0))
            local legPos = getStretchedViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
            local height = math.abs(headPos.Y - legPos.Y)
            local width = height / 1.5
            local boxPos = Vector2.new(screenPos.X - width/2, screenPos.Y - height/2)

            drawings.Box.Visible = true
            drawings.Box.Size = Vector2.new(width, height)
            drawings.Box.Position = boxPos
            
            drawings.Outline.Visible = true
            drawings.Outline.Size = drawings.Box.Size
            drawings.Outline.Position = drawings.Box.Position

            if Toggles.ShowNames then 
                drawings.NameTag.Visible = true
                drawings.NameTag.Text = model.Name
                drawings.NameTag.Position = Vector2.new(screenPos.X, boxPos.Y - 15) 
            else drawings.NameTag.Visible = false end
            
            if Toggles.ShowDistance then 
                drawings.DistanceTag.Visible = true
                drawings.DistanceTag.Text = "[" .. math.floor(distance) .. "m]"
                drawings.DistanceTag.Position = Vector2.new(screenPos.X, boxPos.Y + height + 5) 
            else drawings.DistanceTag.Visible = false end

            if Toggles.ShowHealth then
                local healthScale = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local barHeight = height * healthScale
                drawings.HealthOutline.Visible = true
                drawings.HealthOutline.Size = Vector2.new(4, height + 2)
                drawings.HealthOutline.Position = Vector2.new(boxPos.X - 6, boxPos.Y - 1)
                
                drawings.HealthBar.Visible = true
                drawings.HealthBar.Size = Vector2.new(2, barHeight)
                drawings.HealthBar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + (height - barHeight))
                drawings.HealthBar.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthScale)
            else drawings.HealthOutline.Visible, drawings.HealthBar.Visible = false, false end

            if Toggles.ShowTracers then
                drawings.Tracer.Visible = true
                drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                drawings.Tracer.To = Vector2.new(screenPos.X, screenPos.Y + (height/2))
            else drawings.Tracer.Visible = false end
        else
            for _, d in pairs(drawings) do d.Visible = false end
        end
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= LocalPlayer.Character then
            if not activeESPs[obj] then createESP(obj) end
        end
    end
end)

local Window = Library:CreateWindow({ Title = 'GET OUT open source by koezy', Center = true, AutoShow = true })
local Tabs = { Main = Window:AddTab('Main'), Misc = Window:AddTab('Misc'), Settings = Window:AddTab('Settings') }

local EspGroup = Tabs.Main:AddLeftGroupbox('ESP Settings')
EspGroup:AddToggle('EspEnabled', { Text = 'Enable ESP', Default = false }):OnChanged(function(v) Toggles.EspEnabled = v end)
EspGroup:AddToggle('ShowNames', { Text = 'Show Names', Default = false }):OnChanged(function(v) Toggles.ShowNames = v end)
EspGroup:AddToggle('ShowHealth', { Text = 'Show Health', Default = false }):OnChanged(function(v) Toggles.ShowHealth = v end)
EspGroup:AddToggle('ShowDistance', { Text = 'Show Distance', Default = false }):OnChanged(function(v) Toggles.ShowDistance = v end)
EspGroup:AddToggle('ShowTracers', { Text = 'Show Tracers', Default = false }):OnChanged(function(v) Toggles.ShowTracers = v end)
EspGroup:AddSlider('MaxDist', { Text = 'Max Distance', Default = 2000, Min = 100, Max = 10000, Rounding = 0 }):OnChanged(function(v) Options.MaxEspDistance = v end)

local AimGroup = Tabs.Main:AddRightGroupbox('Aimbot Settings')
AimGroup:AddToggle('AimbotActive', { Text = 'Enable Aimbot', Default = false }):OnChanged(function(v) Toggles.AimbotEnabled = v end)
AimGroup:AddToggle('VisibleCheck', { Text = 'Wall Check', Default = false }):OnChanged(function(v) Toggles.VisibleCheck = v end)
AimGroup:AddToggle('TargetLines', { Text = 'Target Line', Default = false }):OnChanged(function(v) Toggles.TargetLines = v end)
AimGroup:AddToggle('ShowFOV', { Text = 'Show FOV Circle', Default = false }):OnChanged(function(v) Toggles.ShowFOV = v end)
AimGroup:AddDropdown('TargetMode', { Text = 'Target Priority', Default = 'Closest', Values = {'Closest', 'Lowest Health'} }):OnChanged(function(v) Options.TargetMode = v end)
AimGroup:AddSlider('AimFOV', { Text = 'FOV Size', Default = 150, Min = 10, Max = 800, Rounding = 0 }):OnChanged(function(v) Options.AimbotFOV = v end)
AimGroup:AddSlider('AimSmooth', { Text = 'Smoothness', Default = 0.15, Min = 0.01, Max = 1, Rounding = 2 }):OnChanged(function(v) Options.AimbotSmoothness = v end)
AimGroup:AddDropdown('AimPart', { Text = 'Target Part', Default = 'Head', Values = {'Head', 'HumanoidRootPart'} }):OnChanged(function(v) Options.AimbotPart = v end)

local MiscGroup = Tabs.Misc:AddLeftGroupbox('Character & World')
MiscGroup:AddToggle('SpeedToggle', { Text = 'Speed Hack', Default = false }):OnChanged(function(v) Toggles.SpeedEnabled = v end)
MiscGroup:AddSlider('SpeedSlider', { Text = 'Walk Speed', Default = 16, Min = 16, Max = 300, Rounding = 0 }):OnChanged(function(v) Options.WalkSpeed = v end)
MiscGroup:AddToggle('NoShake', { Text = 'No Camera Shake', Default = false }):OnChanged(function(v) Toggles.NoCamShake = v end)
MiscGroup:AddToggle('NoFog', { Text = 'No Fog', Default = false }):OnChanged(function(v) Toggles.NoFog = v end)
MiscGroup:AddSlider('TimeSlider', { Text = 'Time of Day', Default = 12, Min = 0, Max = 24, Rounding = 1 }):OnChanged(function(v) Options.TimeOfDay = v end)

local VisualGroup = Tabs.Misc:AddRightGroupbox('Visual Mods')
VisualGroup:AddDropdown('StretchedRes', { Text = 'Stretched Resolution', Default = 'Standard', Values = {'Standard', '1080x1080', '1920x1080', '2560x1440'} }):OnChanged(function(v) Options.CurrentRes = v end)
VisualGroup:AddSlider('Saturation', { Text = 'Saturation', Default = 0, Min = -1, Max = 3, Rounding = 2 }):OnChanged(function(v) Options.Saturation = v end)
VisualGroup:AddSlider('Contrast', { Text = 'Contrast', Default = 0, Min = -1, Max = 3, Rounding = 2 }):OnChanged(function(v) Options.Contrast = v end)

Library:Notify("discord.gg/skid-wtf - made by koezy")