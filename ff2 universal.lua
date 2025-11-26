--// GUI CREATION
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "MobileFreezeResetGUI"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 220)
Main.Position = UDim2.new(0.05, 0, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Main.Active = true
Main.Draggable = true

local UIList = Instance.new("UIListLayout", Main)
UIList.Padding = UDim.new(0, 6)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.VerticalAlignment = Enum.VerticalAlignment.Top

-- BUTTON MAKER
local function CreateButton(text)
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(0, 180, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Text = text
    return btn
end

-- LABEL FOR FREEZE STATUS
local FreezeLabel = Instance.new("TextLabel", Main)
FreezeLabel.Size = UDim2.new(0, 180, 0, 25)
FreezeLabel.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
FreezeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FreezeLabel.Font = Enum.Font.SourceSansBold
FreezeLabel.TextSize = 18
FreezeLabel.Text = "WSH Freeze (OFF)"

-- BUTTONS
local FreezeButton = CreateButton("Mobile Freeze Button")
local ResetButton = CreateButton("Reset Mobile Button")
local FreezeBindButton = CreateButton("Set Freeze Keybind")
local ResetBindButton = CreateButton("Set Reset Keybind")
local ToggleGUIBindButton = CreateButton("Set Toggle GUI Keybind") -- NEW BUTTON

-- SCRIPT VARIABLES
local freezeEnabled = false
local freezeKey = nil
local resetKey = nil
local toggleGUIKey = nil -- NEW
local listeningForFreezeKey = false
local listeningForResetKey = false
local listeningForToggleGUIKey = false -- NEW

local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer

--// FREEZE FUNCTION
local function toggleFreeze()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    freezeEnabled = not freezeEnabled

    if freezeEnabled then
        root.Anchored = true
        FreezeLabel.Text = "WSH Freeze (ON)"
        FreezeLabel.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    else
        root.Anchored = false
        FreezeLabel.Text = "WSH Freeze (OFF)"
        FreezeLabel.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    end
end

--// RESET FUNCTION (SUPER RELIABLE)
local function doReset()
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.BreakJoints(hum)
        end
    end
end

--// GUI TOGGLE FUNCTION
local guiVisible = true
local function toggleGUI()
    guiVisible = not guiVisible
    Main.Visible = guiVisible
end

-- BUTTON CONNECTIONS
FreezeButton.MouseButton1Click:Connect(toggleFreeze)
ResetButton.MouseButton1Click:Connect(doReset)

FreezeBindButton.MouseButton1Click:Connect(function()
    listeningForFreezeKey = true
    FreezeBindButton.Text = "Press a key..."
end)

ResetBindButton.MouseButton1Click:Connect(function()
    listeningForResetKey = true
    ResetBindButton.Text = "Press a key..."
end)

ToggleGUIBindButton.MouseButton1Click:Connect(function()
    listeningForToggleGUIKey = true
    ToggleGUIBindButton.Text = "Press a key..."
end)

--// KEYBIND LISTENER
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local key = input.KeyCode

    -- Set Freeze Keybind
    if listeningForFreezeKey then
        freezeKey = key
        FreezeBindButton.Text = "Freeze Key: " .. key.Name
        listeningForFreezeKey = false
        return
    end

    -- Set Reset Keybind
    if listeningForResetKey then
        resetKey = key
        ResetBindButton.Text = "Reset Key: " .. key.Name
        listeningForResetKey = false
        return
    end

    -- Set GUI Toggle Keybind
    if listeningForToggleGUIKey then
        toggleGUIKey = key
        ToggleGUIBindButton.Text = "GUI Toggle Key: " .. key.Name
        listeningForToggleGUIKey = false
        return
    end

    -- Keybind Actions
    if freezeKey and key == freezeKey then
        toggleFreeze()
    end

    if resetKey and key == resetKey then
        doReset()
    end

    if toggleGUIKey and key == toggleGUIKey then
        toggleGUI()
    end
end)
