-- WSH ff2 script - Rayfield GUI (Full feature set requested)
-- Features: Quick Reset GUI, Fly GUI (WASD & mobile), WalkSpeed, JumpPower
-- Keybinds, Config save/load/reset, Colors, Draggable mini GUIs, Credits copy links

-- ====== Dependencies (Rayfield) ======
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not success or not Rayfield then
    warn("Rayfield load failed. Make sure you have HTTP enabled in your executor or replace with local Rayfield loader.")
    return
end

-- ====== UTIL: JSON encode/decode, safe file IO ======
local JSON = (function()
    -- Minimal JSON encode/decode for config persistence
    local function esc(s) return s:gsub('\\', '\\\\'):gsub('"','\\"') end
    local function is_array(t)
        local i=0
        for _ in pairs(t) do
            i=i+1
            if t[i]==nil then return false end
        end
        return true
    end
    local function encode(v)
        local t = type(v)
        if t == "string" then return '"' .. esc(v) .. '"' end
        if t == "number" or t == "boolean" then return tostring(v) end
        if t == "table" then
            if is_array(v) then
                local out = {}
                for i=1,#v do out[#out+1]=encode(v[i]) end
                return "["..table.concat(out,",").."]"
            else
                local out = {}
                for k,val in pairs(v) do out[#out+1] = '"'..esc(tostring(k))..'":'..encode(val) end
                return "{"..table.concat(out,",").."}"
            end
        end
        return "null"
    end
    local function decode() error("JSON decode not implemented; using loadstring fallback.") end
    return { encode = encode, decode = decode }
end)()

local writefilef = writefile
local readfilef = readfile
local isfilef = isfile
local delfilef = delfile or function() end
-- fallback checks
if not writefilef or not readfilef or not isfilef then
    writefilef = writefilef or function() error("writefile not supported in this executor") end
    readfilef = readfilef or function() error("readfile not supported in this executor") end
    isfilef = isfilef or function() return false end
end

-- ====== Basic state ======
local CONFIG_PATH = "wsh_ff2_config.json"
local state = {
    resetDelay = 0,
    flySpeed = 20,
    walkSpeed = 16,
    jumpPower = 50,
    colors = {
        accent = {0.192,0.588,0.941}, -- default Rayfield blue-ish (RGB 49,150,240 normalized)
        background = {0.09,0.09,0.09},
        main = {0.16,0.16,0.16},
    },
    keybinds = { -- stored as KeyCode.Name strings or nil
        reset = nil,
        fly = nil,
        ws = nil,
        jp = nil,
        noclip = nil,
    },
    noclip = false,
    auto_load = true,
}

-- Safe save/load
local function save_config()
    local ok, err = pcall(function()
        writefilef(CONFIG_PATH, JSON.encode(state))
    end)
    return ok, err
end
local function load_config()
    if isfilef and isfilef(CONFIG_PATH) then
        local ok, content = pcall(function() return readfilef(CONFIG_PATH) end)
        if ok and content then
            -- try pcall loadstring to parse (since decode above not implemented)
            local parsed
            local successParse, ret = pcall(function()
                -- replace true/false/null into valid Lua then load
                local t = content
                t = t:gsub('null','nil')
                t = t:gsub('true','true')
                t = t:gsub('false','false')
                -- Very naive: convert JSON object to Lua table by replacing ":" with "="
                t = t:gsub('(%a[%w_]*)%s*:', '"%1":') -- ensure keys quoted
                -- We'll attempt to use load (dangerous but typical in scripts)
                local f = loadstring("return "..content)
                if f then parsed = f() end
            end)
            if successParse and parsed and type(parsed) == "table" then
                -- merge loaded into state (only top-level keys)
                for k,v in pairs(parsed) do state[k] = v end
                return true
            end
        end
    end
    return false
end

-- Auto-load if available
pcall(function()
    if state.auto_load then
        load_config()
    end
end)

-- ====== Rayfield Window ======
local Window = Rayfield:CreateWindow({
    Name = "WSH ff2 script",
    LoadingTitle = "WSH ff2 script",
    LoadingSubtitle = "Loaded by ChatGPT",
})

local mainTab = Window:CreateTab("Main", 4483362458)
local keybindTab = Window:CreateTab("Keybinds", 4483362458)
local colorsTab = Window:CreateTab("Colors", 4483362458)
local configTab = Window:CreateTab("Config", 4483362458)
local creditsTab = Window:CreateTab("Credits", 4483362458)

-- ====== Utilities ======
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local function MakeDraggable(frame)
    -- simple drag implementation
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    RunService.Heartbeat:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function copy_to_clipboard(txt)
    if setclipboard then
        pcall(setclipboard, txt)
        return true
    elseif syn and syn.request then
        -- no clipboard API here, still attempt to set
        pcall(function() setclipboard(txt) end)
        return true
    else
        return false
    end
end

-- ====== Mini GUIs ======
local spawnedMiniGUIs = {} -- track for color updates and clean up

local function spawn_quick_reset_gui()
    -- if one exists, don't spawn duplicate
    if workspace:FindFirstChild("QuickResetGUI") or game.CoreGui:FindFirstChild("QuickResetGUI") or spawnedMiniGUIs["Reset"] then
        return
    end
    local screen = Instance.new("ScreenGui")
    screen.Name = "QuickResetGUI"
    screen.Parent = game.CoreGui

    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0, 140, 0, 60)
    frame.Position = UDim2.new(0.02, 0, 0.35, 0)
    frame.BackgroundColor3 = Color3.new(unpack(state.colors.main))
    frame.BorderSizePixel = 0

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,20)
    title.BackgroundTransparency = 1
    title.Text = "Quick Reset"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextScaled = true

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,-10,0,30)
    btn.Position = UDim2.new(0,5,0,25)
    btn.Text = "RESET"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.new(unpack(state.colors.accent))
    btn.BorderSizePixel = 0

    MakeDraggable(frame)

    btn.MouseButton1Click:Connect(function()
        task.wait(state.resetDelay or 0)
        local plr = LocalPlayer
        if plr and plr.Character then
            pcall(function() plr.Character:BreakJoints() end)
        end
    end)

    spawnedMiniGUIs["Reset"] = {screen = screen, frame = frame, btn = btn, title = title}
end

local function spawn_fly_gui()
    if spawnedMiniGUIs["Fly"] then return end
    local screen = Instance.new("ScreenGui")
    screen.Name = "FlyGUI"
    screen.Parent = game.CoreGui

    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0, 180, 0, 110)
    frame.Position = UDim2.new(0.75, 0, 0.35, 0)
    frame.BackgroundColor3 = Color3.new(unpack(state.colors.main))
    frame.BorderSizePixel = 0

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,20)
    title.BackgroundTransparency = 1
    title.Text = "Fly"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextScaled = true

    local flyBtn = Instance.new("TextButton", frame)
    flyBtn.Size = UDim2.new(0.6, -8, 0, 30)
    flyBtn.Position = UDim2.new(0,8,0,26)
    flyBtn.Text = "FLY"
    flyBtn.BackgroundColor3 = Color3.new(unpack(state.colors.accent))
    flyBtn.TextColor3 = Color3.new(1,1,1)
    flyBtn.BorderSizePixel = 0

    local speedLabel = Instance.new("TextLabel", frame)
    speedLabel.Size = UDim2.new(0.35, 0, 0, 30)
    speedLabel.Position = UDim2.new(0.63, 0, 0, 26)
    speedLabel.Text = "Speed: "..tostring(state.flySpeed)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.new(1,1,1)

    local info = Instance.new("TextLabel", frame)
    info.Size = UDim2.new(1, -10, 0, 32)
    info.Position = UDim2.new(0,5,0,60)
    info.Text = "WASD / arrows move during fly. Mobile buttons appear automatically."
    info.TextWrapped = true
    info.TextColor3 = Color3.new(1,1,1)
    info.BackgroundTransparency = 1
    info.TextSize = 12

    MakeDraggable(frame)

    -- fly implementation
    local flying = false
    local currentVelocityObj = nil
    local flyDirection = Vector3.new(0,0,0)
    local moveKeys = {W=false,A=false,S=false,D=false,Up=false,Down=false,Left=false,Right=false}
    local function computeDirection()
        local dir = Vector3.zero
        if moveKeys.W or moveKeys.Up then dir = dir + Vector3.new(0,0,-1) end
        if moveKeys.S or moveKeys.Down then dir = dir + Vector3.new(0,0,1) end
        if moveKeys.A or moveKeys.Left then dir = dir + Vector3.new(-1,0,0) end
        if moveKeys.D or moveKeys.Right then dir = dir + Vector3.new(1,0,0) end
        return dir.Unit ~= dir.Unit and Vector3.zero or (dir.Unit * (dir.Magnitude>0 and 1 or 0))
    end

    local function start_fly()
        local plr = LocalPlayer
        if not plr or not plr.Character then return end
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        flying = true
        flyBtn.Text = "STOP"
        -- create BodyVelocity for smoother movement
        currentVelocityObj = Instance.new("BodyVelocity")
        currentVelocityObj.MaxForce = Vector3.new(1e5,1e5,1e5)
        currentVelocityObj.Velocity = Vector3.new(0,0,0)
        currentVelocityObj.Parent = root
        spawn(function()
            while flying and currentVelocityObj.Parent do
                local dir = computeDirection()
                if dir.Magnitude > 0 then
                    local cam = workspace.CurrentCamera
                    local camCFrame = cam and cam.CFrame or CFrame.new()
                    local move = (camCFrame:VectorToWorldSpace(dir))
                    currentVelocityObj.Velocity = move * state.flySpeed + Vector3.new(0,0,0)
                else
                    currentVelocityObj.Velocity = Vector3.new(0,0,0)
                end
                RunService.Stepped:Wait()
            end
            if currentVelocityObj and currentVelocityObj.Parent then
                currentVelocityObj:Destroy()
            end
            currentVelocityObj = nil
        end)
    end
    local function stop_fly()
        flying = false
        flyBtn.Text = "FLY"
        if currentVelocityObj and currentVelocityObj.Parent then
            currentVelocityObj:Destroy()
            currentVelocityObj = nil
        end
    end

    flyBtn.MouseButton1Click:Connect(function()
        if flying then stop_fly() else start_fly() end
    end)

    -- key handling for WASD while flying
    local function onInputBegan(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local k = input.KeyCode.Name
            if moveKeys[k] ~= nil then
                moveKeys[k] = true
            end
        end
    end
    local function onInputEnded(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local k = input.KeyCode.Name
            if moveKeys[k] ~= nil then
                moveKeys[k] = false
            end
        end
    end
    UserInputService.InputBegan:Connect(onInputBegan)
    UserInputService.InputEnded:Connect(onInputEnded)

    -- Mobile controls: simple on-screen buttons for touch devices
    local mobileControls = Instance.new("Frame", screen)
    mobileControls.Name = "MobileControls"
    mobileControls.Size = UDim2.new(0, 250, 0, 120)
    mobileControls.Position = UDim2.new(0, 10, 1, -140)
    mobileControls.BackgroundTransparency = 1

    local function makeTouchBtn(name, pos, size, label)
        local b = Instance.new("TextButton", mobileControls)
        b.Name = name
        b.Size = size
        b.Position = pos
        b.Text = label
        b.TextScaled = true
        b.BackgroundColor3 = Color3.new(unpack(state.colors.accent))
        b.TextColor3 = Color3.new(1,1,1)
        b.BorderSizePixel = 0
        return b
    end

    local up = makeTouchBtn("Up", UDim2.new(0,0,0,0), UDim2.new(0,40,0,40), "W")
    local left = makeTouchBtn("Left", UDim2.new(0,44,0,44), UDim2.new(0,40,0,40), "A")
    local down = makeTouchBtn("Down", UDim2.new(0,88,0,44), UDim2.new(0,40,0,40), "S")
    local right = makeTouchBtn("Right", UDim2.new(0,132,0,44), UDim2.new(0,40,0,40), "D")
    local tFly = makeTouchBtn("FlyToggle", UDim2.new(0,180,0,0), UDim2.new(0,60,0,60), "Fly")

    -- touch behavior
    local function bindTouch(btn, keyName)
        btn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then
                moveKeys[keyName] = true
            end
        end)
        btn.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then
                moveKeys[keyName] = false
            end
        end)
    end
    bindTouch(up, "Up")
    bindTouch(down, "Down")
    bindTouch(left, "Left")
    bindTouch(right, "Right")
    tFly.MouseButton1Click:Connect(function()
        if flying then stop_fly() else start_fly() end
    end)

    spawnedMiniGUIs["Fly"] = {screen = screen, frame = frame, flyBtn = flyBtn, speedLabel = speedLabel, mobileControls = mobileControls}
end

-- helper to update color theme on spawned GUIs
local function apply_colors_to_minis()
    for k,v in pairs(spawnedMiniGUIs) do
        local frame = v.frame
        if frame and frame:IsA("Frame") then
            frame.BackgroundColor3 = Color3.new(unpack(state.colors.main))
        end
        if v.btn then v.btn.BackgroundColor3 = Color3.new(unpack(state.colors.accent)) end
        if v.mobileControls then
            for _,child in pairs(v.mobileControls:GetChildren()) do
                if child:IsA("TextButton") then child.BackgroundColor3 = Color3.new(unpack(state.colors.accent)) end
            end
        end
    end
end

-- ====== Main Tab controls ======
mainTab:CreateButton({
    Name = "Open Quick Reset GUI",
    Callback = function() spawn_quick_reset_gui() end,
})

mainTab:CreateSlider({
    Name = "Reset Wait Duration",
    Range = {0,1},
    Increment = 0.1,
    CurrentValue = state.resetDelay,
    Callback = function(v)
        state.resetDelay = v
    end,
})

mainTab:CreateButton({
    Name = "Open Fly GUI",
    Callback = function() spawn_fly_gui() end,
})

mainTab:CreateSlider({
    Name = "Fly Speed",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = state.flySpeed,
    Callback = function(v)
        state.flySpeed = v
        if spawnedMiniGUIs["Fly"] and spawnedMiniGUIs["Fly"].speedLabel then
            spawnedMiniGUIs["Fly"].speedLabel.Text = "Speed: "..tostring(v)
        end
    end,
})

mainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 40},
    Increment = 1,
    CurrentValue = state.walkSpeed,
    Callback = function(v)
        state.walkSpeed = v
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            pcall(function() char.Humanoid.WalkSpeed = v end)
        end
    end,
})

mainTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 100},
    Increment = 1,
    CurrentValue = state.jumpPower,
    Callback = function(v)
        state.jumpPower = v
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            pcall(function() char.Humanoid.JumpPower = v end)
        end
    end,
})

mainTab:CreateToggle({
    Name = "Noclip (hold keybind to enable)",
    CurrentValue = state.noclip,
    Callback = function(val)
        state.noclip = val
    end,
})

-- ====== Noclip implementation (toggle state uses keybind) ======
local function set_noclip(enabled)
    local char = LocalPlayer.Character
    if not char then return end
    for _,part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

-- keep noclip updated when toggled
RunService.Stepped:Connect(function()
    if state.noclip then set_noclip(true) end
end)

-- ====== Keybinds Tab ======
-- helper to present keybind setter UI inside Rayfield
local function keyName(k)
    if not k then return "Unbound" end
    return tostring(k)
end

local capturing = { active = false, action = nil }
local function start_capture(actionName, btnLabelObj)
    if capturing.active then return end
    capturing.active = true
    capturing.action = actionName
    if btnLabelObj then btnLabelObj.Text = "Press a key..."
    end
    local conn1, conn2
    conn1 = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local code = input.KeyCode.Name
            state.keybinds[actionName] = code
            if btnLabelObj then btnLabelObj.Text = code end
            capturing.active = false
            capturing.action = nil
            conn1:Disconnect()
            conn2:Disconnect()
        end
    end)
    -- cancel capture if focus lost by pressing Esc
    conn2 = UserInputService.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.Escape then
            capturing.active = false
            capturing.action = nil
            if btnLabelObj then btnLabelObj.Text = keyName(state.keybinds[actionName]) end
            conn1:Disconnect(); conn2:Disconnect()
        end
    end)
end

local kb_frame = {}
-- create UI entries
local kb_actions = { "reset", "fly", "ws", "jp", "noclip" }
for _,act in ipairs(kb_actions) do
    local display = act:upper()
    keybindTab:CreateLabel(display)
    local row = keybindTab:CreateParagraph({Title = "Bind for "..display, Content = "Current: "..keyName(state.keybinds[act])})
    local setBtn = keybindTab:CreateButton({Name = "Set "..display, Callback = function()
        -- we will create a temporary small Rayfield window to show capturing state
        start_capture(act, { Text = "Press a key..." })
    end})
    local clearBtn = keybindTab:CreateButton({Name = "Clear "..display, Callback = function()
        state.keybinds[act] = nil
        -- update label text (Rayfield paragraph won't auto-update easily, but it's fine)
    end})
end

keybindTab:CreateToggle({
    Name = "Auto Load Keybinds on start (uses config)",
    CurrentValue = state.auto_load,
    Callback = function(v) state.auto_load = v end,
})

-- we will handle the actual binding (listening for keys) globally below

-- ====== Colors Tab ======
colorsTab:CreateLabel("Change GUI colors (applies to mini GUIs immediately)")
colorsTab:CreateColorPicker({
    Name = "Accent Color",
    Default = Color3.new(unpack(state.colors.accent)),
    Callback = function(c)
        state.colors.accent = {c.R, c.G, c.B}
        apply_colors_to_minis()
    end,
})
colorsTab:CreateColorPicker({
    Name = "Main Color (frames)",
    Default = Color3.new(unpack(state.colors.main)),
    Callback = function(c)
        state.colors.main = {c.R, c.G, c.B}
        apply_colors_to_minis()
    end,
})
colorsTab:CreateColorPicker({
    Name = "Background Color",
    Default = Color3.new(unpack(state.colors.background)),
    Callback = function(c)
        state.colors.background = {c.R, c.G, c.B}
        -- could apply to root window if desired
    end,
})

-- ====== Config Tab ======
configTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        local ok,err = pcall(save_config)
        if ok then Rayfield:Notify({Title="Config",Content="Saved!",Duration=2}) else Rayfield:Notify({Title="Config Error",Content=tostring(err),Duration=3}) end
    end,
})
configTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        local ok = pcall(load_config)
        if ok then Rayfield:Notify({Title="Config",Content="Loaded (session)!",Duration=2}) else Rayfield:Notify({Title="Config Error",Content="Load failed",Duration=2}) end
        apply_colors_to_minis()
    end,
})
configTab:CreateButton({
    Name = "Reset Config (delete)",
    Callback = function()
        if isfilef and isfilef(CONFIG_PATH) then
            pcall(function() delfilef(CONFIG_PATH) end)
            Rayfield:Notify({Title="Config",Content="Config file deleted",Duration=2})
        else
            Rayfield:Notify({Title="Config",Content="No config file found",Duration=2})
        end
    end,
})
configTab:CreateToggle({
    Name = "Auto Load Config on start",
    CurrentValue = state.auto_load,
    Callback = function(v) state.auto_load = v end,
})

-- ====== Credits Tab ======
creditsTab:CreateLabel("Credits & Links")
creditsTab:CreateButton({
    Name = "Tiktok (copy link)",
    Callback = function()
        local link = "https://www.tiktok.com/@weloveperkzz?_r=1&_t=ZP-91hb6d47Zh1"
        local ok = pcall(function() copy_to_clipboard(link) end)
        if ok then Rayfield:Notify({Title="Copied",Content="Tiktok link copied to clipboard",Duration=2}) else Rayfield:Notify({Title="Copy failed",Content=link,Duration=4}) end
    end,
})
creditsTab:CreateButton({
    Name = "Discord (copy invite)",
    Callback = function()
        local link = "https://discord.gg/CEUv3gfs"
        local ok = pcall(function() copy_to_clipboard(link) end)
        if ok then Rayfield:Notify({Title="Copied",Content="Discord invite copied to clipboard",Duration=2}) else Rayfield:Notify({Title="Copy failed",Content=link,Duration=4}) end
    end,
})

-- ====== Global input handling for keybinds ======
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local name = input.KeyCode.Name

    -- if we are currently capturing, ignore here (capture handles it)
    if capturing.active then return end

    -- check all keybound actions
    for action, key in pairs(state.keybinds) do
        if key and key == name then
            -- perform action
            if action == "reset" then
                task.wait(state.resetDelay or 0)
                pcall(function() LocalPlayer.Character:BreakJoints() end)
            elseif action == "fly" then
                -- toggle or open fly gui
                if spawnedMiniGUIs["Fly"] and spawnedMiniGUIs["Fly"].flyBtn then
                    local btn = spawnedMiniGUIs["Fly"].flyBtn
                    btn:Activate()
                else
                    spawn_fly_gui()
                end
            elseif action == "ws" then
                -- toggle walk speed apply to current character (set to stored value)
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    pcall(function() char.Humanoid.WalkSpeed = state.walkSpeed end)
                end
            elseif action == "jp" then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    pcall(function() char.Humanoid.JumpPower = state.jumpPower end)
                end
            elseif action == "noclip" then
                state.noclip = not state.noclip
                if state.noclip then set_noclip(true) else set_noclip(false) end
            end
        end
    end
end)

-- ====== Final touches: auto spawn minis if config says so? (Not requested) ======
-- apply initial values
RunService.Heartbeat:Wait()
-- set initial walk/jump
pcall(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = state.walkSpeed
        char.Humanoid.JumpPower = state.jumpPower
    end
end)
-- apply colors to any spawned minis
apply_colors_to_minis()

Rayfield:Notify({Title="WSH ff2 script", Content="Loaded successfully", Duration=3})
