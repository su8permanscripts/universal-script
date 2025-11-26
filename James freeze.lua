----------------------------------------------------------------------
-- MATCHA SECURITY LOADER (KEY SYSTEM + DISCORD BUTTON — NO HWID)
----------------------------------------------------------------------

local KEY_URL = "https://pastebin.com/raw/adDXmSV1"
local ff2_script = "https://raw.githubusercontent.com/su8permanscripts/universal-script/main/ff2%20universal.lua"
local DISCORD_INVITE = "https://discord.gg/BydCNS9R9d"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

----------------------------------------------------------------------
-- GUI CREATION
----------------------------------------------------------------------

local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 220)
frame.Position = UDim2.new(0.5, -150, 0.4, -110)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
title.Text = "Matcha Security | Key System"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.SourceSansBold

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(0.8, 0, 0, 35)
box.Position = UDim2.new(0.1, 0, 0.33, 0)
box.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.PlaceholderText = "Enter Key"
box.Font = Enum.Font.SourceSans
box.TextSize = 17

local submit = Instance.new("TextButton", frame)
submit.Size = UDim2.new(0.8, 0, 0, 35)
submit.Position = UDim2.new(0.1, 0, 0.6, 0)
submit.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
submit.Text = "Submit"
submit.TextColor3 = Color3.fromRGB(255, 255, 255)
submit.Font = Enum.Font.SourceSansBold
submit.TextSize = 18

local discord = Instance.new("TextButton", frame)
discord.Size = UDim2.new(0.8, 0, 0, 35)
discord.Position = UDim2.new(0.1, 0, 0.78, 0)
discord.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
discord.Text = "Join Discord"
discord.TextColor3 = Color3.fromRGB(255, 255, 255)
discord.Font = Enum.Font.SourceSansBold
discord.TextSize = 18

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, 0, 0, 25)
status.Position = UDim2.new(0, 0, 1, -25)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(255, 80, 80)
status.Font = Enum.Font.SourceSansBold
status.TextSize = 16

----------------------------------------------------------------------
-- DISCORD BUTTON
----------------------------------------------------------------------

local function openDiscord(link)
    local req = syn and syn.request or request or http_request
    if req then
        req({
            Url = link,
            Method = "GET"
        })
    else
        setclipboard(link)
    end
end

discord.MouseButton1Click:Connect(function()
    status.Text = "Opening Discord..."
    status.TextColor3 = Color3.fromRGB(0, 255, 255)

    openDiscord(DISCORD_INVITE)
end)

----------------------------------------------------------------------
-- KEY VALIDATION
----------------------------------------------------------------------

submit.MouseButton1Click:Connect(function()
    status.Text = "Checking..."
    status.TextColor3 = Color3.fromRGB(255,255,0)

    local success, response = pcall(function()
        return game:HttpGet(KEY_URL)
    end)

    if not success then
        status.Text = "Failed to fetch key!"
        status.TextColor3 = Color3.fromRGB(255,0,0)
        return
    end

    local keyFile = string.gsub(response, "[\n\r]", "")
    local userKey = box.Text

    if userKey ~= keyFile then
        status.Text = "Invalid Key!"
        status.TextColor3 = Color3.fromRGB(255,0,0)
        return
    end

    status.Text = "Access Granted!"
    status.TextColor3 = Color3.fromRGB(0,255,0)
    wait(0.5)
    gui:Destroy()

    loadstring(game:HttpGet(ff2_script))()
end)
