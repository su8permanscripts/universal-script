-- Create GUI
local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "FreezeToggleGUI"
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 150, 0, 50)
button.Position = UDim2.new(0.05, 0, 0.2, 0)
button.TextScaled = true
button.Parent = gui

-- Freeze state
local frozen = false

-- Update button appearance
local function updateButton()
    if frozen then
        button.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- green
        button.Text = "Freeze: ON"
    else
        button.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- red
        button.Text = "Freeze: OFF"
    end
end

updateButton()

-- Toggle freeze on click
button.MouseButton1Click:Connect(function()
    frozen = not frozen
    updateButton()

    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if hrp then
        hrp.Anchored = frozen
    end
end)
