-- LocalScript (place in StarterPlayerScripts or StarterGui)
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuickResetGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Small black frame (center-top)
local frame = Instance.new("Frame")
frame.Name = "ResetFrame"
frame.Size = UDim2.new(0, 120, 0, 40)        -- width 120px, height 40px
frame.Position = UDim2.new(0.5, -60, 0.04, 0) -- centered horizontally, near top
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- black
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Optional subtle border/stroke so it reads on dark backgrounds
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Transparency = 0.6
stroke.Parent = frame

-- Reset button
local button = Instance.new("TextButton")
button.Name = "ResetButton"
button.Size = UDim2.new(1, -12, 1, -10) -- fill frame with padding
button.Position = UDim2.new(0, 6, 0, 5)
button.AnchorPoint = Vector2.new(0, 0)
button.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- slightly lighter black
button.BorderSizePixel = 0
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 18
button.Text = "Reset (Y)"
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = button

-- Debounce to avoid multiple resets at once
local canReset = true
local RESET_DEBOUNCE = 1 -- seconds

local function doReset()
    if not canReset then return end
    canReset = false
    -- Prefer LoadCharacter; wraps in pcall to avoid errors in odd states
    if player and player.Character then
        pcall(function()
            player:LoadCharacter()
        end)
    end
    task.delay(RESET_DEBOUNCE, function()
        canReset = true
    end)
end

-- Button click
button.MouseButton1Click:Connect(function()
    doReset()
end)

-- Bind Y (keyboard) and ButtonY (gamepad) via ContextActionService
local function resetAction(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        doReset()
    end
    -- Returning Enum.ContextActionResult.Sink prevents other bindings from also reacting.
    return Enum.ContextActionResult.Sink
end

-- Bind inputs (works for keyboard Y and controller Y button)
ContextActionService:BindAction("QuickResetAction", resetAction, false, Enum.KeyCode.Y, Enum.KeyCode.ButtonY)

-- Cleanup if the script ever gets removed (optional safety)
screenGui.Destroying:Connect(function()
    ContextActionService:UnbindAction("QuickResetAction")
end)
