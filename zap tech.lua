-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZapGUI"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local ZapButton = Instance.new("TextButton")
ZapButton.Size = UDim2.new(0, 120, 0, 50)
ZapButton.Position = UDim2.new(0.05, 0, 0.5, 0)
ZapButton.BackgroundColor3 = Color3.fromRGB(128, 0, 255) -- Purple
ZapButton.Text = "Zap"
ZapButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ZapButton.Font = Enum.Font.GothamBold
ZapButton.TextScaled = true
ZapButton.Parent = ScreenGui

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

local BOOST = 10
local busy = false

-- Function: forces another jump + boost
local function ZapJump()
	if busy then return end
	if not humanoid then return end

	busy = true

	local original = humanoid.JumpPower
	humanoid.JumpPower = original + BOOST

	-- **Force an immediate extra jump**
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	-- Small delay then restore
	task.wait(0.15)
	humanoid.JumpPower = original
	busy = false
end

-- GUI press
ZapButton.MouseButton1Click:Connect(ZapJump)

-- Controller Y button
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.ButtonY then
		ZapJump()
	end
end)
