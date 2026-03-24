-- JW HUB - Recognition (Optimizado)
-- Sube este archivo a Polsec

repeat task.wait() until game:IsLoaded()
task.wait(2)
if game.PlaceId ~= 109983668079237 then return end
getgenv().JWUserRecognitionRunning = nil
getgenv().JWUserRecognitionRunning = true

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer
local CoreGui      = gethui and gethui() or game:GetService("CoreGui")

local SECRET_ANIM_ID = "rbxassetid://117620032862971"
local FREE_ANIM_ID   = "rbxassetid://284328730261847"

local GRADIENTS = {
    Default = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(220, 222, 240)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 240, 180)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(220, 222, 240))
    },
    Owner = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 215, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 255, 200)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 215, 0))
    },
    Free = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(160, 80, 255)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(220, 180, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(160, 80, 255))
    }
}

local SPECIAL_ROLES = {
    ["flecha7752"] = {
        Tag = "JW PRIORITY OWNER",
        Gradient = GRADIENTS.Owner,
        HighlightColor = Color3.fromRGB(255, 215, 0)
    }
}

local JWUsers = {}
-- Tabla global de gradientes a animar con un solo loop
local activeGradients = {}

-- UN SOLO RenderStepped para todos los gradientes
RunService.RenderStepped:Connect(function()
    local rot = (os.clock() * 120) % 360
    for i = #activeGradients, 1, -1 do
        local data = activeGradients[i]
        if data.sg and data.sg.Parent and data.tg and data.tg.Parent then
            data.sg.Rotation = rot
            data.tg.Rotation = rot
        else
            -- Limpiar gradientes de jugadores que salieron
            table.remove(activeGradients, i)
        end
    end
end)

-- INDICADOR VISUAL
local function mostrarIndicador()
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            local old = pg:FindFirstChild("JWRecognitionIndicator")
            if old then old:Destroy() end
        end
    end)
    pcall(function()
        if gethui then
            local old = gethui():FindFirstChild("JWRecognitionIndicator")
            if old then old:Destroy() end
        end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "JWRecognitionIndicator"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9999998
    pcall(function()
        if gethui then gui.Parent = gethui()
        else gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    end)

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 145, 0, 28)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(13, 15, 24)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(0, 200, 80)
    stroke.Thickness = 1.5

    local dot = Instance.new("Frame", frame)
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 8, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(0, 220, 80)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -26, 1, 0)
    label.Position = UDim2.new(0, 22, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "JW Recognition ON"
    label.TextColor3 = Color3.fromRGB(220, 222, 240)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    task.spawn(function()
        while gui and gui.Parent do
            TweenService:Create(dot, TweenInfo.new(0.8), {BackgroundColor3 = Color3.fromRGB(0, 100, 40)}):Play()
            task.wait(0.8)
            TweenService:Create(dot, TweenInfo.new(0.8), {BackgroundColor3 = Color3.fromRGB(0, 220, 80)}):Play()
            task.wait(0.8)
        end
    end)
end

-- AUTO RE-EXEC EN CADA SERVERHOP
local function setupQueue()
    local queueFunc = nil
    if queue_on_teleport then queueFunc = queue_on_teleport
    elseif syn and syn.queue_on_teleport then queueFunc = syn.queue_on_teleport
    elseif fluxus and fluxus.queue_on_teleport then queueFunc = fluxus.queue_on_teleport
    end
    if not queueFunc then
        warn("[JW Recognition] queue_on_teleport no disponible")
        return
    end
    local POLSEC_URL = "https://raw.githubusercontent.com/akycard/Reconocimiento-/refs/heads/main/processed.lua.txt"
    local wrapper = string.format([[
repeat task.wait() until game:IsLoaded()
task.wait(2)
if game.PlaceId ~= 109983668079237 then return end
loadstring(game:HttpGet(%q))()
]], POLSEC_URL)
    pcall(function()
        if writefile then
            writefile("jw_recognition.lua", wrapper)
        end
        queueFunc(wrapper)
    end)
    print("[JW Recognition] Queue registrado ✓")
end

-- ESP
local function GetSpecialRole(player)
    if not player then return nil end
    if SPECIAL_ROLES[string.lower(player.Name)] then return SPECIAL_ROLES[string.lower(player.Name)] end
    if SPECIAL_ROLES[string.lower(player.DisplayName)] then return SPECIAL_ROLES[string.lower(player.DisplayName)] end
    return nil
end

local function StartBroadcasting()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = SECRET_ANIM_ID
    local track = hum:LoadAnimation(anim)
    track.Looped = true
    track.Priority = Enum.AnimationPriority.Action
    track:Play(0.1, 0.01, 1)
end

local function CreateJWESP(player, isFree)
    if JWUsers[player] or player == LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    JWUsers[player] = true

    local roleData = GetSpecialRole(player)
    local tagText = isFree and "JW FREE User" or "JW PREMIUM User"
    local tagGradient = isFree and GRADIENTS.Free or GRADIENTS.Default
    local outlineColor = isFree and Color3.fromRGB(160, 80, 255) or Color3.fromRGB(255, 215, 0)

    if roleData then
        tagText = roleData.Tag
        tagGradient = roleData.Gradient
        outlineColor = roleData.HighlightColor
    end

    local bg = Instance.new("BillboardGui")
    bg.Name = "JWPriorityTag"
    bg.Adornee = player.Character.Head
    bg.Size = UDim2.new(0, 200, 0, 50)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = tagText
    textLabel.Font = Enum.Font.GothamBlack
    textLabel.TextSize = 13
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Parent = bg

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.Parent = textLabel

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = tagGradient
    strokeGradient.Parent = stroke

    local textGradient = Instance.new("UIGradient")
    textGradient.Color = tagGradient
    textGradient.Parent = textLabel

    -- Añadir al loop global en vez de crear un RenderStepped por jugador
    table.insert(activeGradients, {sg = strokeGradient, tg = textGradient})

    if syn and syn.protect_gui then syn.protect_gui(bg) end
    bg.Parent = CoreGui

    local highlight = Instance.new("Highlight")
    highlight.Name = "JWHighlight"
    highlight.Adornee = player.Character
    highlight.FillColor = outlineColor
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = 0
    highlight.Parent = bg

    player.CharacterRemoving:Connect(function()
        if bg then bg:Destroy() end
        JWUsers[player] = nil
    end)
end

local function ScanPlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local isSpecial = GetSpecialRole(plr) ~= nil
            local isUser, isFreeUser = false, false
            if not isSpecial then
                local hum = plr.Character:FindFirstChild("Humanoid")
                if hum then
                    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                        if track.Animation then
                            if track.Animation.AnimationId == SECRET_ANIM_ID then isUser = true; break end
                            if track.Animation.AnimationId == FREE_ANIM_ID then isFreeUser = true; break end
                        end
                    end
                end
            end
            if isSpecial or isUser then CreateJWESP(plr, false)
            elseif isFreeUser then CreateJWESP(plr, true) end
        end
    end
end

-- ARRANQUE
mostrarIndicador()
setupQueue()

LocalPlayer.CharacterAdded:Connect(function() task.wait(1); StartBroadcasting() end)
if LocalPlayer.Character then StartBroadcasting() end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function() task.wait(2); ScanPlayers() end)
end)

print("[JW Recognition] Activo ✓")

while true do
    ScanPlayers()
    task.wait(3)
end
