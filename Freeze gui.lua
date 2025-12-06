--// Create ScreenGui + Button
local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 150, 0, 50)
button.Position = UDim2.new(0.5, -75, 0.8, 0)
button.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red (OFF)
button.Text = "FREEZE: OFF"
button.Parent = gui
button.AutoButtonColor = true

--// Freeze state
local frozen = false

local function setFrozen(state)
	frozen = state
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")

	if frozen then
		-- Freeze in place
		root.Anchored = true
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		button.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
		button.Text = "FREEZE: ON"
	else
		-- Unfreeze
		root.Anchored = false
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		button.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
		button.Text = "FREEZE: OFF"
	end
end

--// Button toggle
button.MouseButton1Click:Connect(function()
	setFrozen(not frozen)
end)
