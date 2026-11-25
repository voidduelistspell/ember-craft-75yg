-- STNRD HUB - Clean Everything ESP + Take All (Infinite Range)
-- Keyless

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Direct connection to the game's RemoteEvent
local GrabRequest = ReplicatedStorage:WaitForChild("StoreRemotes"):WaitForChild("GrabRequest")

-- List 1: Bakery Map (includes Cooking Whisk and Rolling Pin)
local BakeryItems = {
    "Apple Lollipop", "Apple Pie #1", "Apple Pie #2", "Bag of Flour", "Baguette", "Baguette#15",
    "Bloxy Cola Bottle", "Bloxy Cola Can", "Blueberry Pie", "Bread Loaf", "Bread Roll", "Butter",
    "Caramel Donut", "Caramel Lollipop", "Cherry Lollipop", "Cherry Pie", "Chocolat Eclair",
    "Chocolate Bar", "Chocolate Bear", "Chocolate Bell", "Chocolate Cookie", "Chocolate Cupcake",
    "Chocolate Donut", "Chocolate Macaron", "Coffee Cup", "Coffee Eclair", "Coffee Macaron",
    "Cola Lollipop", "Cooking Whisk", "Country Bread", "Croissant", "Dark Chocolate Bar", "Dark Chocolate Bear",
    "Dough", "Egg", "Flour Bag", "Flour Bag#23", "Glass Cola Bottle", "Goala Cola Bottle",
    "Goala Cola Can", "Grape Lollipop", "IceCream Pot", "IceCream Pot#26", "IceCream Scoop",
    "Jar Of Sugar", "Lemon Macaron", "Lemon Pie", "Lollipop", "MangoMacaron", "Minecraft Cake",
    "Orange Lollipop", "Paper Bag", "Pistachio Macaron", "Plate", "Plate#24", "Pumpkin Pie",
    "Raspberry Cake", "Raspberry Cake#14", "Raspberry Cookie", "Rolling Pin", "Small Baguette", "Split Bread",
    "Strawberry Cake", "Strawberry Cupcake", "Strawberry Donut", "Strawberry Macaron", "Strawberry Pie",
    "Tea Cup", "Vanilla Cookie", "Vanilla Cupcake", "Vanilla Cupcakes", "Vanilla Donut",
    "Vanilla Eclair", "Vanilla Macaron", "White Chocolate Bar", "White Chocolate Bear"
}

-- List 2: Restaurant Map (141 items)
local RestaurantItems = {
    "Apple", "Attic_Light_A", "Avocado", "Back", "Balloon", "Banana", "Bananna", "Birthday Cake",
    "Birthday Letter [B]", "Birthday Letter [H]", "Birthday Letter [a]", "Birthday Letter [a] #2",
    "Birthday Letter [d]", "Birthday Letter [h]", "Birthday Letter [i]", "Birthday Letter [p]",
    "Birthday Letter [p] #2", "Birthday Letter [r]", "Birthday Letter [t]", "Birthday Letter [y]",
    "Birthday Letter [y] #2", "Black Piano Piece", "Bowl", "Bracelet", "Burger", "Candle", "Carrot",
    "Chair", "Cheese", "Chicken Burger", "Chocolate Cake", "Chocolate Pie", "ClientArm",
    "ClientArmVM", "Coffee", "Cola", "Dark Bottle", "Disco Pad", "Earth", "ErgoMouse", "Fork",
    "Fried Chicken", "FrontLeft", "FrontRight", "GamepassAura", "Glass [TABLE]", "Grape",
    "Gum Ball", "HelperGhost", "Hot Sauce", "Hotdog Ketchup", "Hotdog Mustard", "Jelly",
    "Jimmy_MrBeast223", "Jupiter", "Ketchup", "Keyboard", "Keys", "Knife", "Large Tupperware",
    "Lasagna", "Lemon Cake", "Lemon Pie", "Lounge_Stool_Low", "Mango", "Marriage Chair", "Mars",
    "Meat Skewer", "Medium Tupperware", "Mercury", "MicrowaveOven", "Model", "Moon", "Mustard",
    "Napkin [TABLE #1]", "Napkin [TABLE #2]", "Neptune", "Nugget", "Orange", "Oreo Cake", "Part",
    "Pasta", "Pepper", "Piano", "PianoModel", "Pink Flower", "Pizza", "Planter_V2", "Plate",
    "PottedPlant_Bananna", "Purple Bottle", "QuickplaceGamepass", "RadioGamepass", "Ramen Bowl",
    "Red Bottle", "RobloxTower01", "Round Glass", "Salt", "Sandwich", "Saturn", "Sign",
    "Small Tupperware", "SmartHoldingGamepass", "Speaker", "Sponge", "Steak", "Strawberry Cake",
    "Sun", "Sushi #1", "Sushi #2", "Sushi #3", "Sushi #4", "Sushi Sauce", "Table #1", "Table #2",
    "Table #3", "Table #4", "Table #5", "Table #6", "Table Light", "Taco", "ThreeDTextObject",
    "Tuna Sandwich", "Uranus", "Venus", "ViewModel", "Vin Glass", "White Piano Piece",
    "Wine Bottle", "bench", "body", "control panel", "door glass", "extinguisher", "handle",
    "legs", "lid", "part", "piano body", "table number", "vents"
}

local enabledBakery = {}
local enabledRestaurant = {}
local highlights = {}

for _, name in ipairs(BakeryItems) do enabledBakery[name] = false end
for _, name in ipairs(RestaurantItems) do enabledRestaurant[name] = false end

local function destroyHL(obj)
    if highlights[obj] then
        pcall(function() highlights[obj]:Destroy() end)
        highlights[obj] = nil
    end
end

local function createHL(obj)
    if highlights[obj] then return end
    if not obj or not obj.Parent then return end
    if obj:IsDescendantOf(LocalPlayer.Character) then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor = Color3.fromRGB(0, 255, 100)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = CoreGui
    highlights[obj] = hl
end

-- Global Take All function (Infinite Range)
local function executeTakeAll()
    local count = 0
    for obj, _ in pairs(highlights) do
        if obj and obj.Parent then
            pcall(function()
                GrabRequest:FireServer(obj)
                count = count + 1
            end)
            task.wait(0.01)
        end
    end

    Rayfield:Notify({
        Title = "STNRD HUB",
        Content = "Picked up " .. count .. " items!",
        Duration = 2
    })
end

-- ==========================================
-- MOBILE FLOATING BUTTON (TAKE ALL)
-- ==========================================
if CoreGui:FindFirstChild("StnrdMobileHUD") then
    CoreGui.StnrdMobileHUD:Destroy()
end

local MobileGui = Instance.new("ScreenGui")
MobileGui.Name = "StnrdMobileHUD"
MobileGui.ResetOnSpawn = false
MobileGui.Enabled = false
MobileGui.Parent = CoreGui

local TakeAllBtn = Instance.new("TextButton")
TakeAllBtn.Name = "TakeAllButton"
TakeAllBtn.Size = UDim2.new(0, 110, 0, 45)
TakeAllBtn.Position = UDim2.new(0.8, -55, 0.4, 0)
TakeAllBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TakeAllBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
TakeAllBtn.Font = Enum.Font.GothamBold
TakeAllBtn.TextSize = 15
TakeAllBtn.Text = "TAKE ALL"
TakeAllBtn.Parent = MobileGui

local UICorner = Instance.new("UICorner", TakeAllBtn)
UICorner.CornerRadius = UDim.new(0, 10)
local UIStroke = Instance.new("UIStroke", TakeAllBtn)
UIStroke.Color = Color3.fromRGB(0, 255, 120)
UIStroke.Thickness = 2

local dragging, dragInput, dragStart, startPos
local isDraggingAction = false

TakeAllBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        isDraggingAction = false
        dragStart = input.Position
        startPos = TakeAllBtn.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TakeAllBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        if delta.Magnitude > 8 then
            isDraggingAction = true
            TakeAllBtn.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end
end)

TakeAllBtn.MouseButton1Click:Connect(function()
    if not isDraggingAction then
        TakeAllBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
        TakeAllBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
        task.spawn(executeTakeAll)
        task.wait(0.15)
        TakeAllBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        TakeAllBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
    end
end)
-- ==========================================

-- Render loop for infinite range and constant re-detection
RunService.RenderStepped:Connect(function()
    for obj, _ in pairs(highlights) do
        if not obj or not obj.Parent or (not enabledBakery[obj.Name] and not enabledRestaurant[obj.Name]) then
            destroyHL(obj)
        end
    end

    for name, isOn in pairs(enabledBakery) do
        if isOn then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name == name and obj:IsA("Model") then
                    createHL(obj)
                end
            end
        end
    end

    for name, isOn in pairs(enabledRestaurant) do
        if isOn then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name == name and obj:IsA("Model") then
                    createHL(obj)
                end
            end
        end
    end
end)

-- Rayfield interface
local Window = Rayfield:CreateWindow({
    Name = "STNRD HUB",
    LoadingTitle = "STNRD HUB",
    LoadingSubtitle = "Clean Everything ESP + Take All",
    Theme = "Default",
})

-- ==========================================
-- TAB: BAKERY MAP
-- ==========================================
local BakeryTab = Window:CreateTab("Bakery Map", 4483362458)

BakeryTab:CreateSection("Quick Controls")

BakeryTab:CreateToggle({
    Name = "Mobile Floating Button (Take All)",
    CurrentValue = false,
    Callback = function(Value)
        MobileGui.Enabled = Value
        if Value then
            Rayfield:Notify({Title = "STNRD HUB", Content = "Floating button enabled", Duration = 3})
        end
    end,
})

BakeryTab:CreateButton({
    Name = "Take All (Grab all at distance)",
    Callback = function() executeTakeAll() end,
})

BakeryTab:CreateButton({
    Name = "Turn Off All ESP",
    Callback = function()
        for name, _ in pairs(enabledBakery) do enabledBakery[name] = false end
        for name, _ in pairs(enabledRestaurant) do enabledRestaurant[name] = false end
        for obj, _ in pairs(highlights) do destroyHL(obj) end
        Rayfield:Notify({Title = "STNRD HUB", Content = "All ESP turned off", Duration = 3})
    end,
})

BakeryTab:CreateSection("Food and Utensils (Infinite Range)")

for _, name in ipairs(BakeryItems) do
    BakeryTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Callback = function(Value)
            enabledBakery[name] = Value
            if not Value then
                for obj, _ in pairs(highlights) do
                    if obj and obj.Name == name then destroyHL(obj) end
                end
            end
        end,
    })
end

-- ==========================================
-- TAB: RESTAURANT MAP
-- ==========================================
local RestaurantTab = Window:CreateTab("Restaurant Map", 4483362458)

RestaurantTab:CreateSection("Quick Controls")

RestaurantTab:CreateToggle({
    Name = "Mobile Floating Button (Take All)",
    CurrentValue = false,
    Callback = function(Value)
        MobileGui.Enabled = Value
        if Value then
            Rayfield:Notify({Title = "STNRD HUB", Content = "Floating button enabled", Duration = 3})
        end
    end,
})

RestaurantTab:CreateButton({
    Name = "Take All (Grab all at distance)",
    Callback = function() executeTakeAll() end,
})

RestaurantTab:CreateButton({
    Name = "Turn Off All ESP",
    Callback = function()
        for name, _ in pairs(enabledBakery) do enabledBakery[name] = false end
        for name, _ in pairs(enabledRestaurant) do enabledRestaurant[name] = false end
        for obj, _ in pairs(highlights) do destroyHL(obj) end
        Rayfield:Notify({Title = "STNRD HUB", Content = "All ESP turned off", Duration = 3})
    end,
})

RestaurantTab:CreateSection("Restaurant Items (Infinite Range)")

for _, name in ipairs(RestaurantItems) do
    RestaurantTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Callback = function(Value)
            enabledRestaurant[name] = Value
            if not Value then
                for obj, _ in pairs(highlights) do
                    if obj and obj.Name == name then destroyHL(obj) end
                end
            end
        end,
    })
end

Rayfield:Notify({
    Title = "STNRD HUB",
    Content = "STNRD HUB is ready!",
    Duration = 5
})
