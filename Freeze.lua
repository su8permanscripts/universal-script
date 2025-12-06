-- Create GUI
local gui = Instance.new("ScreenGui")
gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 150, 0, 50)
button.Position = UDim2.new(0.05, 0, 0.2, 0)
button.TextScaled = true
button.Parent = gui

-- Initial state
local frozen = false

-- Update appearance
local function updateButton()
    if frozen then
        button.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- green
        button.Text = "Freeze ON"
    else
        button.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- red
        button.Text = "Freeze OFF"
    end
end

updateButton()

-- Toggle freeze
button.MouseButton1Click:Connect(function()
    frozen = not frozen
    updateButton()

    local character = game.Players.LocalPlayer.Character
    if character then
        local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
        if humanoidRoot then
            if frozen then
                humanoidRoot.Anchored = true
            else
                humanoidRoot.Anchored = false
            end
        end
    end
end)
