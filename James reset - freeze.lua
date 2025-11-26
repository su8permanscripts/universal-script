----------------------------------------------------------------------
-- RAYFIELD HUB | FREEZE + RESET + KEYBINDS
----------------------------------------------------------------------

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Matcha Universal Hub",
    LoadingTitle = "Matcha Hub",
    LoadingSubtitle = "by James",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MatchaHub",
        FileName = "UniversalConfig"
    }
})

----------------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------------

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

local freezeEnabled = false
local uiOpen = true

----------------------------------------------------------------------
-- UNIVERSAL TAB
----------------------------------------------------------------------

local UniversalTab = Window:CreateTab("Universal", 4483362458)

-- Freeze Toggle
local FreezeToggle = UniversalTab:CreateToggle({
    Name = "Anchor Freeze",
    CurrentValue  false,
    Flag = "FreezeToggle",
    Callback = function(Value)
        freezeEnabled = Value
        if Value then
            hrp.Anchored = true
        else
            hrp.Anchored = false
        end
    end,
})

-- Reset Button
UniversalTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        local c = player.Character
        if c:FindFirstChild("Humanoid") then
            c:FindFirstChild("Humanoid").Health = 0
        end
    end,
})

----------------------------------------------------------------------
-- KEYBINDS TAB
----------------------------------------------------------------------

local KeybindsTab = Window:CreateTab("Keybinds", 4483362458)

-- Freeze Keybind
KeybindsTab:CreateKeybind({
    Name = "Freeze Toggle Keybind",
    CurrentKeybind = "G",
    HoldToInteract = false,
    Flag = "FreezeKey",
    Callback = function()
        freezeEnabled = not freezeEnabled
        FreezeToggle:Set(freezeEnabled)
        hrp.Anchored = freezeEnabled
    end,
})

-- Reset Keybind
KeybindsTab:CreateKeybind({
    Name = "Reset Keybind",
    CurrentKeybind = "R",
    HoldToInteract = false,
    Flag = "ResetKey",
    Callback = function()
        local c = player.Character
        if c:FindFirstChild("Humanoid") then
            c:FindFirstChild("Humanoid").Health = 0
        end
    end,
})

-- Toggle GUI Keybind
KeybindsTab:CreateKeybind({
    Name = "Toggle UI Keybind",
    CurrentKeybind = "RightControl",
    HoldToInteract = false,
    Flag = "ToggleUIKey",
    Callback = function()
        uiOpen = not uiOpen
        if uiOpen then
            Rayfield:ToggleUI(true)
        else
            Rayfield:ToggleUI(false)
        end
    end,
})

----------------------------------------------------------------------
-- DONE
----------------------------------------------------------------------

Rayfield:Notify({
    Title = "Matcha Hub Loaded",
    Content = "Freeze, Reset, and Keybinds are ready.",
    Duration = 5
})
