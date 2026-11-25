do
	local Players          = game:GetService("Players")
	local UIS              = game:GetService("UserInputService")
	local RunService       = game:GetService("RunService")
	local Lighting         = game:GetService("Lighting")
	local TeleportService  = game:GetService("TeleportService")
	local player           = Players.LocalPlayer

	local DISCORD_URL = "https://discord.gg/Qe9Z2zX2G"
	local GATE_SECONDS = 15

	local uc = {
		Panel     = Color3.fromRGB(10, 8, 8),
		Surface   = Color3.fromRGB(24, 10, 10),
		SurfaceHi = Color3.fromRGB(38, 14, 14),
		Border    = Color3.fromRGB(96, 28, 28),
		Text      = Color3.fromRGB(245, 235, 235),
		Muted     = Color3.fromRGB(170, 120, 120),
		On        = Color3.fromRGB(220, 55, 55),
		Discord   = Color3.fromRGB(200, 35, 35),
	}

	local function make(className, props, parent)
		local inst = Instance.new(className)
		for k, v in pairs(props) do inst[k] = v end
		inst.Parent = parent
		return inst
	end

	local function corner(parent, radius)
		make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
	end

	local function copyDiscord()
		local ok = pcall(function()
			if setclipboard then
				setclipboard(DISCORD_URL)
			elseif toclipboard then
				toclipboard(DISCORD_URL)
			end
		end)
		return ok
	end

	-- ---------- feature state ----------
	local infJumpConn, noclipConn, flyConn, flyBV
	local savedLighting
	local savedSpeed, savedJumpPower, savedUseJumpPower
	local speedBoostOn, jumpPowerOn = false, false

	local function setInfiniteJump(on)
		if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
		if not on then return end
		infJumpConn = UIS.JumpRequest:Connect(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end

	local function setNoclip(on)
		if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
		if not on then return end
		noclipConn = RunService.Stepped:Connect(function()
			local char = player.Character
			if not char then return end
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then
					p.CanCollide = false
				end
			end
		end)
	end

	local function setFullbright(on)
		if on then
			if not savedLighting then
				savedLighting = {
					Brightness     = Lighting.Brightness,
					ClockTime      = Lighting.ClockTime,
					Ambient        = Lighting.Ambient,
					OutdoorAmbient = Lighting.OutdoorAmbient,
					FogEnd         = Lighting.FogEnd,
					GlobalShadows  = Lighting.GlobalShadows,
				}
			end
			Lighting.Brightness     = 3
			Lighting.ClockTime      = 14
			Lighting.Ambient        = Color3.fromRGB(180, 180, 180)
			Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
			Lighting.FogEnd         = 1e6
			Lighting.GlobalShadows  = false
		elseif savedLighting then
			for k, v in pairs(savedLighting) do
				pcall(function() Lighting[k] = v end)
			end
			savedLighting = nil
		end
	end

	local function setFly(on)
		if flyConn then flyConn:Disconnect(); flyConn = nil end
		if flyBV   then flyBV:Destroy();      flyBV   = nil end
		if not on then return end
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		local root = hum and hum.RootPart
		if not root then return end
		local bv = Instance.new("BodyVelocity")
		bv.Name = "HackingBrosFly"
		bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bv.Velocity = Vector3.zero
		bv.Parent = root
		flyBV = bv
		local cam = workspace.CurrentCamera
		flyConn = RunService.RenderStepped:Connect(function()
			if not flyBV or not flyBV.Parent then return end
			local dir = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W)           then dir = dir + cam.CFrame.LookVector   end
			if UIS:IsKeyDown(Enum.KeyCode.S)           then dir = dir - cam.CFrame.LookVector   end
			if UIS:IsKeyDown(Enum.KeyCode.A)           then dir = dir - cam.CFrame.RightVector  end
			if UIS:IsKeyDown(Enum.KeyCode.D)           then dir = dir + cam.CFrame.RightVector  end
			if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir = dir + Vector3.new(0, 1, 0)    end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0)    end
			flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * 60 or Vector3.zero
		end)
	end

	local function setSpeedBoost(on)
		speedBoostOn = on
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		if on then
			if savedSpeed == nil then savedSpeed = hum.WalkSpeed end
			hum.WalkSpeed = 100
		elseif savedSpeed ~= nil then
			hum.WalkSpeed = savedSpeed
			savedSpeed = nil
		end
	end

	local function setJumpPower(on)
		jumpPowerOn = on
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		if on then
			if savedJumpPower == nil then
				savedJumpPower    = hum.JumpPower
				savedUseJumpPower = hum.UseJumpPower
			end
			hum.UseJumpPower = true
			hum.JumpPower    = 120
		elseif savedJumpPower ~= nil then
			hum.JumpPower     = savedJumpPower
			hum.UseJumpPower  = savedUseJumpPower
			savedJumpPower    = nil
			savedUseJumpPower = nil
		end
	end

	local function resetCharacter()
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = 0 end
	end

	local function rejoinServer()
		pcall(function()
			TeleportService:Teleport(game.PlaceId, player)
		end)
	end

	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum then return end
		if speedBoostOn then hum.WalkSpeed = 100 end
		if jumpPowerOn then
			hum.UseJumpPower = true
			hum.JumpPower    = 120
		end
	end)

	-- =========================================================
	-- SPLASH — 15 second Discord gate
	-- =========================================================
	local function showSplash(onDone)
		local splash = make("ScreenGui", {
			Name = "HackingBrosSplash",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = 200,
		}, player:WaitForChild("PlayerGui"))

		make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
		}, splash)

		local card = make("Frame", {
			Size = UDim2.fromOffset(460, 300),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = uc.Panel,
			BorderSizePixel = 0,
		}, splash)
		corner(card, 14)
		make("UIStroke", { Color = uc.Border, Thickness = 1 }, card)

		make("TextLabel", {
			Size = UDim2.new(1, -40, 0, 26),
			Position = UDim2.fromOffset(20, 22),
			BackgroundTransparency = 1,
			Text = "HACKING BROS",
			Font = Enum.Font.GothamBold,
			TextSize = 20,
			TextColor3 = uc.On,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, card)

		make("TextLabel", {
			Size = UDim2.new(1, -40, 0, 16),
			Position = UDim2.fromOffset(20, 50),
			BackgroundTransparency = 1,
			Text = "FULL SCRIPT · JOIN DISCORD",
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = uc.On,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, card)

		make("TextLabel", {
			Size = UDim2.new(1, -40, 0, 60),
			Position = UDim2.fromOffset(20, 76),
			BackgroundTransparency = 1,
			Text = "Copy the invite link and hop in for the full release. The free UI below unlocks once the timer runs out.",
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = uc.Muted,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, card)

		local linkBox = make("TextLabel", {
			Size = UDim2.new(1, -40, 0, 38),
			Position = UDim2.fromOffset(20, 148),
			BackgroundColor3 = uc.Surface,
			BorderSizePixel = 0,
			Text = "discord.gg/Qe9Z2zX2G",
			Font = Enum.Font.Code,
			TextSize = 14,
			TextColor3 = uc.Text,
		}, card)
		corner(linkBox, 8)
		make("UIStroke", { Color = uc.Border, Thickness = 1 }, linkBox)

		local copyBtn = make("TextButton", {
			Size = UDim2.new(1, -40, 0, 40),
			Position = UDim2.fromOffset(20, 198),
			BackgroundColor3 = uc.Discord,
			BorderSizePixel = 0,
			Text = "Copy Discord Invite",
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = uc.Text,
			AutoButtonColor = false,
		}, card)
		corner(copyBtn, 8)

		copyBtn.Activated:Connect(function()
			copyDiscord()
			copyBtn.Text = "Copied — see you inside ✓"
			copyBtn.BackgroundColor3 = uc.On
			copyBtn.TextColor3 = Color3.new(0, 0, 0)
		end)

		local countdown = make("TextLabel", {
			Size = UDim2.new(1, -40, 0, 20),
			Position = UDim2.new(0, 20, 1, -38),
			BackgroundTransparency = 1,
			Text = ("UI unlocks in %ds…"):format(GATE_SECONDS),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = uc.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, card)

		local start = os.clock()
		task.spawn(function()
			while true do
				local remaining = math.max(0, math.ceil(GATE_SECONDS - (os.clock() - start)))
				countdown.Text = ("UI unlocks in %ds…"):format(remaining)
				if remaining <= 0 then break end
				task.wait(0.1)
			end
			splash:Destroy()
			onDone()
		end)
	end

	-- =========================================================
	-- MAIN UI
	-- =========================================================
	local function buildUI()
		local screen2 = make("ScreenGui", {
			Name = "HackingBrosGui",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 101,
		}, player:WaitForChild("PlayerGui"))

		-- -- persistent Discord button (top-right of screen)
		local dcBar = make("Frame", {
			Name = "DiscordBar",
			Size = UDim2.fromOffset(240, 40),
			Position = UDim2.new(1, -20, 0, 20),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = uc.Panel,
			BorderSizePixel = 0,
		}, screen2)
		corner(dcBar, 8)
		make("UIStroke", { Color = uc.Discord, Thickness = 1 }, dcBar)

		local dcBtn = make("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
		}, dcBar)

		local dcLabel = make("TextLabel", {
			Size = UDim2.new(1, -28, 1, 0),
			Position = UDim2.fromOffset(12, 0),
			BackgroundTransparency = 1,
			Text = "Join DC for full script",
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = uc.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, dcBtn)

		make("TextLabel", {
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.new(1, -24, 0.5, -9),
			BackgroundTransparency = 1,
			Text = "›",
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = uc.On,
		}, dcBtn)

		dcBtn.Activated:Connect(function()
			copyDiscord()
			dcLabel.Text = "Link copied ✓"
			task.delay(1.4, function()
				if dcLabel.Parent then
					dcLabel.Text = "Join DC for full script"
				end
			end)
		end)

		-- -- main panel
		local PANEL_W, PANEL_H = 340, 360

		local panel2 = make("Frame", {
			Name = "Panel",
			Size = UDim2.fromOffset(PANEL_W, PANEL_H),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = uc.Panel,
			BorderSizePixel = 0,
			Active = true,
		}, screen2)
		corner(panel2, 10)
		make("UIStroke", { Color = uc.Border, Thickness = 1 }, panel2)

		local header2 = make("Frame", {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundTransparency = 1,
			Active = true,
		}, panel2)

		make("TextLabel", {
			Size = UDim2.new(1, -100, 1, 0),
			Position = UDim2.fromOffset(18, 0),
			BackgroundTransparency = 1,
			Text = "HACKING BROS",
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = uc.On,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, header2)

		local minBtn = make("TextButton", {
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.new(1, -72, 0, 12),
			BackgroundTransparency = 1,
			Text = "–",
			Font = Enum.Font.GothamBold,
			TextSize = 20,
			TextColor3 = uc.Muted,
			AutoButtonColor = false,
		}, header2)

		local close2 = make("TextButton", {
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.new(1, -42, 0, 12),
			BackgroundTransparency = 1,
			Text = "×",
			Font = Enum.Font.Gotham,
			TextSize = 22,
			TextColor3 = uc.Muted,
			AutoButtonColor = false,
		}, header2)

		make("Frame", {
			Size = UDim2.new(1, -36, 0, 1),
			Position = UDim2.fromOffset(18, 48),
			BackgroundColor3 = uc.Border,
			BorderSizePixel = 0,
		}, panel2)

		local content = make("Frame", {
			Name = "Content",
			Size = UDim2.new(1, -36, 1, -60),
			Position = UDim2.fromOffset(18, 56),
			BackgroundTransparency = 1,
		}, panel2)
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}, content)

		local function makeToggle(order, label, callback)
			local btn = make("TextButton", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = uc.Surface,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = order,
			}, content)
			corner(btn, 6)
			local stroke = make("UIStroke", { Color = uc.Border, Thickness = 1 }, btn)

			make("TextLabel", {
				Size = UDim2.new(0.7, 0, 1, 0),
				Position = UDim2.fromOffset(14, 0),
				BackgroundTransparency = 1,
				Text = label,
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
				TextColor3 = uc.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, btn)

			local status = make("TextLabel", {
				Size = UDim2.new(0.3, -14, 1, 0),
				Position = UDim2.new(0.7, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = "OFF",
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = uc.Muted,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, btn)

			local state = false
			local function render()
				status.Text = state and "ON" or "OFF"
				status.TextColor3 = state and uc.On or uc.Muted
				stroke.Color = state and uc.On or uc.Border
				btn.BackgroundColor3 = state and uc.SurfaceHi or uc.Surface
			end
			render()

			btn.Activated:Connect(function()
				state = not state
				render()
				local ok, err = pcall(callback, state)
				if not ok then
					warn("[HackingBros] " .. label .. ": " .. tostring(err))
					state = false
					render()
				end
			end)
			return btn
		end

		local function makeAction(order, label, callback)
			local btn = make("TextButton", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = uc.Surface,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = order,
			}, content)
			corner(btn, 6)
			make("UIStroke", { Color = uc.Border, Thickness = 1 }, btn)

			make("TextLabel", {
				Size = UDim2.new(1, -50, 1, 0),
				Position = UDim2.fromOffset(14, 0),
				BackgroundTransparency = 1,
				Text = label,
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
				TextColor3 = uc.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, btn)

			make("TextLabel", {
				Size = UDim2.fromOffset(20, 20),
				Position = UDim2.new(1, -32, 0.5, -10),
				BackgroundTransparency = 1,
				Text = "›",
				Font = Enum.Font.GothamBold,
				TextSize = 16,
				TextColor3 = uc.On,
			}, btn)

			btn.Activated:Connect(function()
				pcall(callback)
			end)
			return btn
		end

		makeToggle(1, "Infinite Jump",            setInfiniteJump)
		makeToggle(2, "Noclip",                   setNoclip)
		makeToggle(3, "Fullbright",               setFullbright)
		makeToggle(4, "Fly  (WASD/Space/Ctrl)",   setFly)
		makeToggle(5, "Speed Boost",              setSpeedBoost)
		makeToggle(6, "High Jump",                setJumpPower)
		makeAction(7, "Reset Character",          resetCharacter)
		makeAction(8, "Rejoin Server",            rejoinServer)

		local minimized = false
		minBtn.Activated:Connect(function()
			minimized = not minimized
			if minimized then
				content.Visible = false
				panel2.Size = UDim2.fromOffset(PANEL_W, 48)
				minBtn.Text = "+"
			else
				content.Visible = true
				panel2.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
				minBtn.Text = "–"
			end
		end)

		close2.Activated:Connect(function()
			if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
			if noclipConn  then noclipConn:Disconnect();  noclipConn  = nil end
			if flyConn     then flyConn:Disconnect();     flyConn     = nil end
			if flyBV       then flyBV:Destroy();          flyBV       = nil end
			setFullbright(false)
			screen2:Destroy()
		end)

		-- -- drag
		local dragging, dragInput, dragStart, startPos
		header2.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging  = true
				dragInput = input
				dragStart = input.Position
				startPos  = panel2.Position
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if dragging and (input == dragInput
				or (dragInput.UserInputType == Enum.UserInputType.MouseButton1
					and input.UserInputType == Enum.UserInputType.MouseMovement)) then
				local delta = input.Position - dragStart
				panel2.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
		UIS.InputEnded:Connect(function(input)
			if input == dragInput then
				dragging  = false
				dragInput = nil
			end
		end)

		return screen2
	end

	-- =========================================================
	-- RUN
	-- =========================================================
	showSplash(function()
		local ok, err = pcall(buildUI)
		if not ok then
			warn("[HackingBros] failed to build UI: " .. tostring(err))
		end
	end)
end