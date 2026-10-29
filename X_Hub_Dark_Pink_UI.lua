-- Combat Tools para Fist Fight Arena - Auto Dodge mejorado (mejor esfuerzo)
-- Conserva panel arrastrable, burbuja, Hitbox Expander y aspecto visual original.
-- IMPORTANTE: deteccion e input son aproximados; la validacion final depende del servidor.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local VirtualInputManager
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local virtualInput
pcall(function()
    virtualInput = UserInputService:CreateVirtualInput()
end)

print("[COMBAT TOOLS] Iniciando...")

-- ==================== CONFIGURACION ====================

local settings = {
    hitboxEnabled = true,
    hitboxSize = 2,

    -- Perfect Wave / Auto Dodge
    perfectDodgeEnabled = false,
    playerESPEnabled = false,
    espShowPosition = true,
    espShowDistance = true,
    espShowHealth = true,
    dodgeDistance = 12,
    perfectDodgeTiming = 0.035,
    perfectDodgeCooldown = 0.12,
    lastDodgeTime = 0,
    originalSizes = {}
}

local restoreHitboxes

-- ==================== CREAR GUI: X HUB (TEMA DARK HUB ROSA NEÓN) ====================

-- Paleta inspirada en Dark Hub: negro, borgoña y rosa/fucsia neón.
local RED = Color3.fromRGB(255, 48, 181)       -- rosa neón
local DARK_RED = Color3.fromRGB(89, 13, 57)    -- borgoña activo
local BLACK = Color3.fromRGB(8, 5, 11)         -- fondo casi negro
local PANEL_BLACK = Color3.fromRGB(22, 8, 21)  -- panel borgoña oscuro
local TEXT_WHITE = Color3.fromRGB(250, 244, 249)
local TEXT_RED = Color3.fromRGB(255, 137, 215)
local ROW_BLACK = Color3.fromRGB(28, 13, 28)

local camera = workspace.CurrentCamera
local viewportWidth = camera and camera.ViewportSize.X or 800
local viewportHeight = camera and camera.ViewportSize.Y or 700
-- Diseño adaptable: ancho grande en PC y compacto en móvil.
local panelWidth = math.clamp(viewportWidth - 24, 300, 720)
local panelHeight = math.clamp(viewportHeight - 36, 460, 620)
local sidebarWidth = math.clamp(panelWidth * 0.29, 88, 198)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XHubGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainPanel = Instance.new("Frame")
mainPanel.Name = "XHubPanel"
mainPanel.Size = UDim2.new(0, panelWidth, 0, panelHeight)
mainPanel.Position = UDim2.new(0, 18, 0, 18)
mainPanel.BackgroundColor3 = PANEL_BLACK
mainPanel.BorderSizePixel = 0
mainPanel.ClipsDescendants = false
mainPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 11)
panelCorner.Parent = mainPanel

-- Doble contorno para imitar el brillo neón de la referencia.
local glowStroke = Instance.new("UIStroke")
glowStroke.Color = RED
glowStroke.Thickness = 9
glowStroke.Transparency = 0.72
glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
glowStroke.Parent = mainPanel

local edgeStroke = Instance.new("UIStroke")
edgeStroke.Color = Color3.fromRGB(255, 106, 209)
edgeStroke.Thickness = 2
edgeStroke.Transparency = 0.04
edgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
edgeStroke.Parent = mainPanel

local panelGradient = Instance.new("UIGradient")
panelGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 7, 23)),
    ColorSequenceKeypoint.new(0.52, Color3.fromRGB(13, 7, 15)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(37, 8, 29))
})
panelGradient.Rotation = 15
panelGradient.Parent = mainPanel

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -94, 0, 22)
titleLabel.Position = UDim2.new(0, 16, 0, 3)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = TEXT_WHITE
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "Dark Hub"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Active = true
titleLabel.ZIndex = 2
titleLabel.Parent = mainPanel

local authorLabel = Instance.new("TextLabel")
authorLabel.Name = "AuthorLabel"
authorLabel.Size = UDim2.new(0, 145, 0, 14)
authorLabel.Position = UDim2.new(0, 17, 0, 23)
authorLabel.BackgroundTransparency = 1
authorLabel.TextColor3 = TEXT_RED
authorLabel.TextSize = 10
authorLabel.Font = Enum.Font.Gotham
authorLabel.Text = "by X Hub"
authorLabel.TextXAlignment = Enum.TextXAlignment.Left
authorLabel.Parent = mainPanel

local titleLine = Instance.new("Frame")
titleLine.Name = "TitlePinkLine"
titleLine.Size = UDim2.new(1, 0, 0, 2)
titleLine.Position = UDim2.new(0, 0, 0, 39)
titleLine.BackgroundColor3 = RED
titleLine.BorderSizePixel = 0
titleLine.ZIndex = 3
titleLine.Parent = mainPanel
local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new(RED, Color3.fromRGB(166, 67, 255))
titleGradient.Parent = titleLine

-- ==================== BOTON MINIMIZAR / BURBUJA ====================

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeButton"
minimizeBtn.Size = UDim2.new(0, 32, 0, 28)
minimizeBtn.Position = UDim2.new(1, -37, 0, 6)
minimizeBtn.BackgroundColor3 = PANEL_BLACK
minimizeBtn.TextColor3 = RED
minimizeBtn.TextSize = 22
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "—"
minimizeBtn.BorderSizePixel = 1
minimizeBtn.BorderColor3 = RED
local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 5)
minimizeCorner.Parent = minimizeBtn
minimizeBtn.ZIndex = 4
minimizeBtn.Parent = mainPanel

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 26, 0, 28)
closeBtn.Position = UDim2.new(1, -68, 0, 6)
closeBtn.BackgroundColor3 = PANEL_BLACK
closeBtn.TextColor3 = RED
closeBtn.TextSize = 22
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "×"
closeBtn.BorderSizePixel = 1
closeBtn.BorderColor3 = RED
closeBtn.ZIndex = 4
closeBtn.Parent = mainPanel
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeBtn

local bubble = Instance.new("TextButton")
bubble.Name = "XHubBubble"
bubble.Size = UDim2.new(0, 56, 0, 56)
bubble.Position = mainPanel.Position
bubble.BackgroundColor3 = BLACK
bubble.TextColor3 = RED
bubble.TextSize = 18
bubble.Font = Enum.Font.GothamBlack
bubble.Text = "XH"
bubble.BorderSizePixel = 2
bubble.BorderColor3 = RED
bubble.Visible = false
bubble.Active = true
bubble.ZIndex = 10
bubble.Parent = screenGui

local bubbleCorner = Instance.new("UICorner")
bubbleCorner.CornerRadius = UDim.new(1, 0)
bubbleCorner.Parent = bubble

-- Barra lateral estilo Dark Hub. Las pestañas saltan a las secciones reales del script.
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Position = UDim2.new(0, 0, 0, 41)
sidebar.Size = UDim2.new(0, sidebarWidth, 1, -41)
sidebar.BackgroundColor3 = BLACK
sidebar.BackgroundTransparency = 0.12
sidebar.BorderSizePixel = 0
sidebar.Parent = mainPanel

local sidebarHeader = Instance.new("TextLabel")
sidebarHeader.Name = "SidebarHeader"
sidebarHeader.Size = UDim2.new(1, -12, 0, 28)
sidebarHeader.Position = UDim2.new(0, 10, 0, 10)
sidebarHeader.BackgroundTransparency = 1
sidebarHeader.TextColor3 = TEXT_RED
sidebarHeader.TextSize = 11
sidebarHeader.Font = Enum.Font.GothamBold
sidebarHeader.Text = "CATEGORÍAS"
sidebarHeader.TextXAlignment = Enum.TextXAlignment.Left
sidebarHeader.Parent = sidebar

local contentFrame -- declaración anticipada para la navegación lateral
local navTargets = {}
local navButtons = {}
local navDefinitions = {
    { key = "Combat", text = "⚔  Combat" },
    { key = "Visual", text = "◎  Visual" },
    { key = "Settings", text = "⚙  Settings" },
}

local function selectNav(key)
    for navKey, navButton in pairs(navButtons) do
        local active = navKey == key
        navButton.BackgroundColor3 = active and DARK_RED or ROW_BLACK
        navButton.TextColor3 = active and TEXT_WHITE or Color3.fromRGB(218, 198, 215)
        navButton.BorderColor3 = active and RED or Color3.fromRGB(69, 30, 60)
        navButton.BorderSizePixel = active and 1 or 0
    end
    -- Cada categoría muestra solamente sus propios controles; Settings queda vacío.
    for _, child in ipairs(contentFrame:GetChildren()) do
        local categoryKey = child:GetAttribute("CategoryKey")
        if categoryKey then
            child.Visible = categoryKey == key
        end
    end
    contentFrame.CanvasPosition = Vector2.new(0, 0)
end

for index, definition in ipairs(navDefinitions) do
    local button = Instance.new("TextButton")
    button.Name = definition.key .. "Category"
    button.Size = UDim2.new(1, -14, 0, 36)
    button.Position = UDim2.new(0, 7, 0, 42 + (index - 1) * 44)
    button.BackgroundColor3 = index == 1 and DARK_RED or ROW_BLACK
    button.TextColor3 = index == 1 and TEXT_WHITE or Color3.fromRGB(218, 198, 215)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Text = definition.text
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.BorderSizePixel = index == 1 and 1 or 0
    button.BorderColor3 = index == 1 and RED or Color3.fromRGB(69, 30, 60)
    button.AutoButtonColor = true
    button.Parent = sidebar
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 9)
    padding.PaddingRight = UDim.new(0, 3)
    padding.Parent = button
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button
    navButtons[definition.key] = button
    button.MouseButton1Click:Connect(function()
        selectNav(definition.key)
    end)
end

local sidebarDivider = Instance.new("Frame")
sidebarDivider.Name = "SidebarDivider"
sidebarDivider.Size = UDim2.new(0, 1, 1, -41)
sidebarDivider.Position = UDim2.new(0, sidebarWidth - 1, 0, 41)
sidebarDivider.BackgroundColor3 = Color3.fromRGB(116, 34, 91)
sidebarDivider.BorderSizePixel = 0
sidebarDivider.Parent = mainPanel

contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "CombatContent"
contentFrame.Position = UDim2.new(0, sidebarWidth + 9, 0, 48)
contentFrame.Size = UDim2.new(1, -(sidebarWidth + 15), 1, -54)
contentFrame.BackgroundColor3 = PANEL_BLACK
contentFrame.BorderSizePixel = 0
contentFrame.Active = true
contentFrame.ScrollingEnabled = true
contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
contentFrame.ScrollBarThickness = 4
contentFrame.ScrollBarImageColor3 = RED
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = mainPanel

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 8)
contentLayout.Parent = contentFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 10)
contentPadding.PaddingBottom = UDim.new(0, 10)
contentPadding.PaddingLeft = UDim.new(0, 10)
contentPadding.PaddingRight = UDim.new(0, 10)
contentPadding.Parent = contentFrame

-- ==================== ELEMENTOS DE UI ====================

local currentCategory = "Combat"

local function createLabel(text, layoutOrder)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.TextColor3 = TEXT_RED
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = layoutOrder
    label:SetAttribute("CategoryKey", currentCategory)
    label.Parent = contentFrame
    return label
end

local function createToggle(text, defaultState, callback, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 38)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder
    container:SetAttribute("CategoryKey", currentCategory)
    container.Parent = contentFrame

    -- Fila oscura con texto a la izquierda y switch rosa a la derecha,
    -- similar a las opciones del panel de referencia.
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundColor3 = ROW_BLACK
    button.TextColor3 = TEXT_WHITE
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.BorderSizePixel = 1
    button.BorderColor3 = Color3.fromRGB(75, 31, 66)
    button.AutoButtonColor = false
    button.Parent = container

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = button

    local textPadding = Instance.new("UIPadding")
    textPadding.PaddingLeft = UDim.new(0, 10)
    textPadding.PaddingRight = UDim.new(0, 52)
    textPadding.Parent = button

    local track = Instance.new("Frame")
    track.Name = "ToggleTrack"
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, -9, 0.5, 0)
    track.Size = UDim2.new(0, 36, 0, 20)
    track.BackgroundColor3 = defaultState and RED or Color3.fromRGB(70, 45, 66)
    track.BorderSizePixel = 0
    track.ZIndex = 3
    track.Parent = button

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local knob = Instance.new("Frame")
    knob.Name = "ToggleKnob"
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = defaultState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 247, 253)
    knob.BorderSizePixel = 0
    knob.ZIndex = 4
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = defaultState
    local function refreshToggle()
        track.BackgroundColor3 = state and RED or Color3.fromRGB(70, 45, 66)
        knob.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        button.BorderColor3 = state and Color3.fromRGB(157, 43, 117) or Color3.fromRGB(75, 31, 66)
    end

    button.MouseButton1Click:Connect(function()
        state = not state
        refreshToggle()
        if callback then callback(state) end
    end)
    return container
end

local function createSlider(labelText, minVal, maxVal, defaultVal, callback, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder
    container:SetAttribute("CategoryKey", currentCategory)
    container.Parent = contentFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = TEXT_RED
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.Text = labelText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    sliderBg.Position = UDim2.new(0, 0, 0, 22)
    sliderBg.BackgroundColor3 = Color3.fromRGB(47, 19, 42)
    sliderBg.BorderSizePixel = 0
    sliderBg.Active = true
    sliderBg.Parent = container
    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(1, 0)
    sliderBgCorner.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = RED
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    sliderFillCorner.Parent = sliderFill

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 40, 0, 18)
    valueLabel.Position = UDim2.new(1, -40, 0, 20)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = TEXT_RED
    valueLabel.TextSize = 11
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(math.round(defaultVal * 10) / 10)
    valueLabel.Parent = container

    local isSliding = false
    local activeTouch = nil

    local function updateSlider(inputX)
        local bgPos = sliderBg.AbsolutePosition.X
        local bgSize = sliderBg.AbsoluteSize.X
        if bgSize <= 0 then return end

        local percentage = math.clamp((inputX - bgPos) / bgSize, 0, 1)
        local value = minVal + (maxVal - minVal) * percentage
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        valueLabel.Text = tostring(math.round(value * 10) / 10)
        if callback then callback(value) end
    end

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isSliding = true
            activeTouch = nil
            updateSlider(input.Position.X)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
            activeTouch = input
            updateSlider(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not isSliding then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input.Position.X)
        elseif input.UserInputType == Enum.UserInputType.Touch and activeTouch == input then
            updateSlider(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isSliding = false
        elseif input.UserInputType == Enum.UserInputType.Touch and activeTouch == input then
            isSliding = false
            activeTouch = nil
        end
    end)

    return container
end

-- ==================== COMBAT / VISUAL / SETTINGS ====================

createLabel("COMBAT", 1)

local perfectDodgeCount = 0
local lastStatus = "esperando"
local updateDodgeStatus -- se mantiene como callback opcional para el detector

createToggle("Auto Perfect Wave", false, function(state)
    settings.perfectDodgeEnabled = state
    lastStatus = state and "detector automático activo" or "desactivado"
    print("[X Hub] Auto Perfect Wave: " .. (state and "ACTIVADO" or "DESACTIVADO"))
    if updateDodgeStatus then updateDodgeStatus() end
end, 2)

createToggle("Hitbox Expander", true, function(state)
    settings.hitboxEnabled = state
    if not state and restoreHitboxes then restoreHitboxes() end
    print("[X Hub] Hitbox Expander: " .. (state and "ACTIVADO" or "DESACTIVADO"))
end, 3)

createSlider("Tamaño del hitbox", 1, 5, 2, function(value)
    settings.hitboxSize = value
end, 4)

currentCategory = "Visual"
createLabel("PLAYER ESP", 1)
createToggle("Activar ESP de jugadores", false, function(state)
    settings.playerESPEnabled = state
end, 2)
createToggle("Mostrar posición", true, function(state)
    settings.espShowPosition = state
end, 3)
createToggle("Mostrar distancia", true, function(state)
    settings.espShowDistance = state
end, 4)
createToggle("Mostrar vida (HP)", true, function(state)
    settings.espShowHealth = state
end, 5)

-- Settings queda intencionalmente vacío hasta que se agreguen opciones reales.
currentCategory = "Settings"

selectNav("Combat")

-- ==================== MINIMIZAR Y RESTAURAR ====================

minimizeBtn.MouseButton1Click:Connect(function()
    bubble.Position = mainPanel.Position
    mainPanel.Visible = false
    bubble.Visible = true
end)

bubble.MouseButton1Click:Connect(function()
    mainPanel.Position = bubble.Position
    bubble.Visible = false
    mainPanel.Visible = true
end)

-- ==================== ARRASTRE DEL PANEL ====================

local isDragging = false
local dragStart
local startPos
local dragInput

titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = mainPanel.Position
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not isDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput then
        local delta = input.Position - dragStart
        mainPanel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    elseif input.UserInputType == Enum.UserInputType.Touch and dragInput and input.UserInputType == dragInput.UserInputType then
        local delta = input.Position - dragStart
        mainPanel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or (dragInput and input == dragInput) then
        isDragging = false
        dragInput = nil
    elseif input.UserInputType == Enum.UserInputType.Touch and dragInput and input == dragInput then
        isDragging = false
        dragInput = nil
    end
end)

-- ==================== HITBOX EXPANDER SIN DISTORSIONAR EL AVATAR ====================
-- Solo se modifica el HumanoidRootPart del jugador objetivo; nunca se escalan las
-- extremidades ni se oculta la skin. SelectionBox dibuja el contorno blanco del área.

restoreHitboxes = function()
    for part, data in pairs(settings.originalSizes) do
        pcall(function()
            if part and part.Parent then
                part.Size = data.Size
            end
        end)
        if data.visualBox then
            pcall(function() data.visualBox:Destroy() end)
        end
    end
    settings.originalSizes = {}
end

local function expandHitboxes()
    if not settings.hitboxEnabled then return end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local character = otherPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
                local data = settings.originalSizes[root]
                if not data then
                    data = { Size = root.Size, visualBox = nil }
                    settings.originalSizes[root] = data

                    local box = Instance.new("SelectionBox")
                    box.Name = "XHubHitboxOutline"
                    box.Adornee = root
                    box.Color3 = Color3.fromRGB(255, 255, 255)
                    box.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
                    box.SurfaceTransparency = 1
                    box.LineThickness = 0.045
                    box.Visible = true
                    box.Parent = root
                    data.visualBox = box
                end

                -- Escalado relativo al tamaño original, no al tamaño del frame anterior.
                pcall(function()
                    root.Size = data.Size * settings.hitboxSize
                end)
            end
        end
    end
end

-- ==================== PLAYER ESP ====================

local espByPlayer = {}

local function removePlayerESP(otherPlayer)
    local data = espByPlayer[otherPlayer]
    if data then
        pcall(function() data.billboard:Destroy() end)
        espByPlayer[otherPlayer] = nil
    end
end

local function createPlayerESP(otherPlayer, root)
    removePlayerESP(otherPlayer)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "XHubPlayerESP"
    billboard.Adornee = root
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Size = UDim2.fromOffset(220, 74)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.Enabled = settings.playerESPEnabled
    billboard.Parent = playerGui

    local label = Instance.new("TextLabel")
    label.Name = "ESPText"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0.12
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = billboard

    espByPlayer[otherPlayer] = {
        billboard = billboard,
        label = label,
        root = root,
        character = root.Parent,
    }
end

local function updatePlayerESP()
    local localCharacter = player.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local character = otherPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local data = espByPlayer[otherPlayer]

            if root and humanoid then
                if not data or data.root ~= root or not data.billboard.Parent then
                    createPlayerESP(otherPlayer, root)
                    data = espByPlayer[otherPlayer]
                end

                data.billboard.Enabled = settings.playerESPEnabled
                if settings.playerESPEnabled then
                    local lines = { otherPlayer.Name }
                    if settings.espShowPosition then
                        local pos = root.Position
                        table.insert(lines, string.format("POS: %d, %d, %d", math.round(pos.X), math.round(pos.Y), math.round(pos.Z)))
                    end
                    if settings.espShowDistance and localRoot then
                        local distance = (root.Position - localRoot.Position).Magnitude
                        table.insert(lines, "DIST: " .. tostring(math.round(distance)) .. " studs")
                    end
                    if settings.espShowHealth then
                        table.insert(lines, "HP: " .. tostring(math.max(0, math.floor(humanoid.Health))) .. "/" .. tostring(math.floor(humanoid.MaxHealth)))
                    end
                    data.label.Text = table.concat(lines, "\n")
                end
            elseif data then
                removePlayerESP(otherPlayer)
            end
        end
    end

    for otherPlayer in pairs(espByPlayer) do
        if otherPlayer.Parent ~= Players then
            removePlayerESP(otherPlayer)
        end
    end
end

Players.PlayerRemoving:Connect(removePlayerESP)

-- ==================== PERFECT WAVE / DETECCION MEJORADA ====================

-- Mejoras principales:
-- 1) Animator.AnimationPlayed detecta el inicio de una animacion, sin esperar a que
--    el escaneo la encuentre varios frames despues.
-- 2) Los AnimationTrack reutilizados pueden volver a disparar la deteccion cuando
--    se reinician; no quedan bloqueados permanentemente despues del primer uso.
-- 3) La deteccion alternativa considera distancia, orientacion y velocidad relativa,
--    para cubrir ataques cuyas animaciones no se replican o tienen nombres genericos.
-- 4) El contador informa intentos, no confirma que el servidor haya aceptado la esquiva.

local trackStates = setmetatable({}, { __mode = "k" })
local lastFallbackByPlayer = {}
local lastDodgeByPlayer = {}
local detectionConnections = {}
local hookedPlayers = setmetatable({}, { __mode = "k" })
local warnedInput = false
local inputHoldTime = 0.09

local function addDetectionConnection(connection)
    table.insert(detectionConnections, connection)
    return connection
end

local function getTrackState(track)
    local state = trackStates[track]
    if not state then
        state = {
            triggered = false,
            lastTimePosition = 0,
            lastTriggeredAt = 0,
        }
        trackStates[track] = state

        -- Si el mismo AnimationTrack vuelve a reproducirse, permitir detectar el nuevo ciclo.
        pcall(function()
            state.stoppedConnection = track.Stopped:Connect(function()
                state.triggered = false
                state.lastTimePosition = 0
            end)
        end)
    end

    local currentPosition = 0
    pcall(function() currentPosition = track.TimePosition end)
    if currentPosition + 0.08 < (state.lastTimePosition or 0) then
        -- Algunas experiencias reinician el mismo track sin crear otro objeto.
        state.triggered = false
    end
    state.lastTimePosition = currentPosition
    return state
end

local function sendVirtualKey(keyCode, isPressed)
    -- VirtualInputManager es interno de Roblox y puede ser bloqueado por el executor.
    if VirtualInputManager then
        local ok = pcall(function()
            VirtualInputManager:SendKeyEvent(isPressed, keyCode, false, game)
        end)
        if ok then return true end
    end

    -- VirtualInput admite entradas tipo teclado en entornos que lo permiten.
    if virtualInput then
        local ok = pcall(function()
            virtualInput:SendKey(isPressed, keyCode, false)
        end)
        if ok then return true end
    end

    return false
end

local function activateScreenDodgeButton()
    -- Solo activa botones cuya etiqueta/nombre indique claramente esquiva.
    local terms = { "dodge", "weave", "evade", "esquivar", "esquiva", "wave" }
    for _, object in ipairs(playerGui:GetDescendants()) do
        if object:IsA("GuiButton") and object.Visible and object.Active then
            local label = string.lower(object.Name .. " " .. (object:IsA("TextButton") and object.Text or ""))
            for _, term in ipairs(terms) do
                if string.find(label, term, 1, true) then
                    local ok = pcall(function() object:Activate() end)
                    if ok then return true end
                end
            end
        end
    end
    return false
end

local function getFacingDot(attackerRoot, playerRoot)
    local toPlayer = playerRoot.Position - attackerRoot.Position
    if toPlayer.Magnitude < 0.01 then return 1 end
    return attackerRoot.CFrame.LookVector:Dot(toPlayer.Unit)
end

local function classifyAnimationTrack(track)
    if not track then return nil end

    local isPlaying = false
    local trackName = ""
    local animationName = ""
    local trackLength = 0
    local looped = false
    local priority
    local animationId = ""

    pcall(function()
        isPlaying = track.IsPlaying
        trackName = tostring(track.Name or "")
        trackLength = track.Length or 0
        looped = track.Looped
        priority = track.Priority
        local animation = track.Animation
        if animation then
            animationName = tostring(animation.Name or "")
            animationId = tostring(animation.AnimationId or "")
        end
    end)

    if not isPlaying then return nil end

    local name = string.lower(trackName .. " " .. animationName .. " " .. animationId)

    -- Evitar clasificar animaciones defensivas/recibidas como golpes entrantes.
    local excludedWords = {
        "hitreact", "hit_react", "gethit", "get_hit", "hurt", "stagger", "damage",
        "dodge", "evade", "weave", "roll", "block", "parry", "guard", "defend",
        "walk", "run", "idle", "jump", "fall", "land", "emote", "taunt", "equip"
    }
    for _, word in ipairs(excludedWords) do
        if string.find(name, word, 1, true) then
            return nil
        end
    end

    local attackWords = {
        "punch", "attack", "swing", "jab", "hook", "uppercut", "combo",
        "fist", "m1", "heavy", "light", "strike", "lunge", "melee"
    }
    for _, word in ipairs(attackWords) do
        if string.find(name, word, 1, true) then
            return "named"
        end
    end

    local actionPriority = priority == Enum.AnimationPriority.Action
        or priority == Enum.AnimationPriority.Action2
        or priority == Enum.AnimationPriority.Action3
        or priority == Enum.AnimationPriority.Action4

    -- Respaldo: muchas experiencias usan nombres como "Animation" para los golpes.
    -- Se filtra por prioridad y duracion corta, y luego por proximidad/orientacion.
    local plausibleLength = trackLength <= 0
        or (trackLength >= 0.06 and trackLength <= 2.7 and not looped)

    if actionPriority and plausibleLength then
        return "generic"
    end

    return nil
end

local executePerfectDodge

local function sendDodgePulse(attackerRoot, playerRoot)
    -- Moverse hacia el lado contrario al que se encuentra el atacante.
    local offset = attackerRoot.Position - playerRoot.Position
    local side = playerRoot.CFrame.RightVector:Dot(offset)
    local directionKey = side >= 0 and Enum.KeyCode.A or Enum.KeyCode.D

    local l2Down = sendVirtualKey(Enum.KeyCode.ButtonL2, true)
    local directionDown = sendVirtualKey(directionKey, true)
    local screenButtonActivated = false

    if not l2Down then
        screenButtonActivated = activateScreenDodgeButton()
    end

    task.delay(inputHoldTime, function()
        sendVirtualKey(Enum.KeyCode.ButtonL2, false)
        sendVirtualKey(directionKey, false)
    end)

    if not l2Down and not directionDown and not screenButtonActivated and not warnedInput then
        warnedInput = true
        lastStatus = "ataque detectado; el executor no pudo enviar L2/teclas"
        warn("[Combat Tools] Se detecta el posible golpe, pero no se pudo enviar la entrada de esquiva.")
    end

    return l2Down, directionDown, screenButtonActivated
end

executePerfectDodge = function(attackerRoot, playerRoot, track, attackerPlayer, source, timingOverride)
    local now = os.clock()
    local minimumGap = math.clamp(settings.perfectDodgeCooldown or 0.12, 0.08, 0.35)

    if now - (settings.lastDodgeTime or 0) < minimumGap then
        return false
    end

    if attackerPlayer and now - (lastDodgeByPlayer[attackerPlayer] or -math.huge) < 0.09 then
        return false
    end

    settings.lastDodgeTime = now
    if attackerPlayer then
        lastDodgeByPlayer[attackerPlayer] = now
    end

    lastStatus = "posible golpe detectado; preparando esquiva"
    if updateDodgeStatus then updateDodgeStatus() end

    local timing = timingOverride
    if timing == nil then
        timing = math.clamp(settings.perfectDodgeTiming or 0.035, 0, 0.15)
        -- No retrasar más de la cuenta si la animación ya está avanzada.
        if track then
            pcall(function()
                local length = track.Length
                local position = track.TimePosition
                if length and length > 0 then
                    local remaining = math.max(0, length - position)
                    if remaining < timing then
                        timing = math.max(0, remaining * 0.35)
                    end
                end
            end)
        end
    end
    timing = math.clamp(timing or 0, 0, 0.15)

    task.delay(timing, function()
        if not screenGui.Parent or not settings.perfectDodgeEnabled then return end
        if not attackerRoot or not attackerRoot.Parent or not playerRoot or not playerRoot.Parent then
            lastStatus = "el personaje cambió antes de ejecutar la esquiva"
            if updateDodgeStatus then updateDodgeStatus() end
            return
        end

        perfectDodgeCount += 1
        local l2Sent, directionSent, buttonActivated = sendDodgePulse(attackerRoot, playerRoot)

        if buttonActivated then
            lastStatus = "botón de esquiva de pantalla activado"
        elseif l2Sent and directionSent then
            lastStatus = "intento enviado: L2 + movimiento lateral"
        elseif l2Sent then
            lastStatus = "intento enviado: L2; dirección no confirmada"
        elseif directionSent then
            lastStatus = "movimiento lateral enviado; L2 no confirmado"
        else
            lastStatus = "golpe detectado, pero no se pudo enviar la entrada"
        end

        print("[Combat Tools] Intento automático #" .. perfectDodgeCount .. " | origen: " .. tostring(source or "detección"))
        if updateDodgeStatus then updateDodgeStatus() end
    end)

    return true
end

local function processAttackTrack(otherPlayer, attackerRoot, playerRoot, track, source)
    if not settings.perfectDodgeEnabled then return false end
    if not attackerRoot or not attackerRoot.Parent or not playerRoot or not playerRoot.Parent then
        return false
    end

    local classification = classifyAnimationTrack(track)
    if not classification then return false end

    local distance = (playerRoot.Position - attackerRoot.Position).Magnitude
    if distance > settings.dodgeDistance then return false end

    local facingDot = getFacingDot(attackerRoot, playerRoot)
    local toPlayer = playerRoot.Position - attackerRoot.Position
    local closingSpeed = 0
    if toPlayer.Magnitude > 0.01 then
        local direction = toPlayer.Unit
        local attackerVelocity = attackerRoot.AssemblyLinearVelocity
        local playerVelocity = playerRoot.AssemblyLinearVelocity
        closingSpeed = (attackerVelocity - playerVelocity):Dot(direction)
    end

    -- Un ataque con nombre reconocible se acepta incluso con orientacion imperfecta.
    -- Para animaciones genericas, exigir cierta proximidad, orientacion o acercamiento.
    if classification == "generic" then
        local plausibleThreat = facingDot > -0.35 or distance <= 5.5 or closingSpeed > 1.0
        if not plausibleThreat then return false end
    end

    local state = getTrackState(track)
    if state.triggered then return false end

    local queued = executePerfectDodge(
        attackerRoot,
        playerRoot,
        track,
        otherPlayer,
        source or classification,
        nil
    )

    if queued then
        state.triggered = true
        state.lastTriggeredAt = os.clock()
        lastStatus = "animacion de posible ataque detectada (" .. tostring(otherPlayer.Name) .. ")"
        if updateDodgeStatus then updateDodgeStatus() end
        return true
    end

    return false
end

local function getCharacterParts(otherPlayer)
    local character = otherPlayer and otherPlayer.Character
    if not character then return nil, nil, nil end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return nil, nil, nil end
    return character, root, humanoid
end

local function hookOpponentCharacter(otherPlayer, character)
    if otherPlayer == player or not character then return end

    task.spawn(function()
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
        if not humanoid or not character.Parent then return end

        local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5)
        if not animator or not character.Parent then return end

        addDetectionConnection(animator.AnimationPlayed:Connect(function(track)
            if not settings.perfectDodgeEnabled then return end
            -- AnimationPlayed captura el inicio del track; defer evita leerlo antes de actualizar su estado.
            task.defer(function()
                if not settings.perfectDodgeEnabled or not screenGui.Parent then return end
                if otherPlayer.Character ~= character then return end

                local _, attackerRoot, attackerHumanoid = getCharacterParts(otherPlayer)
                local localCharacter = player.Character
                local playerRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
                if not attackerRoot or not attackerHumanoid or not playerRoot then return end

                processAttackTrack(otherPlayer, attackerRoot, playerRoot, track, "inicio de animacion")
            end)
        end))
    end)
end

local function hookOpponent(otherPlayer)
    if otherPlayer == player or hookedPlayers[otherPlayer] then return end
    hookedPlayers[otherPlayer] = true

    addDetectionConnection(otherPlayer.CharacterAdded:Connect(function(character)
        hookOpponentCharacter(otherPlayer, character)
    end))

    if otherPlayer.Character then
        hookOpponentCharacter(otherPlayer, otherPlayer.Character)
    end
end

-- Conectar eventos de animacion para jugadores presentes y futuros.
for _, otherPlayer in ipairs(Players:GetPlayers()) do
    hookOpponent(otherPlayer)
end

addDetectionConnection(Players.PlayerAdded:Connect(function(otherPlayer)
    hookOpponent(otherPlayer)
end))

addDetectionConnection(Players.PlayerRemoving:Connect(function(otherPlayer)
    lastFallbackByPlayer[otherPlayer] = nil
    lastDodgeByPlayer[otherPlayer] = nil
    hookedPlayers[otherPlayer] = nil
end))

local function detectAttacks()
    if not settings.perfectDodgeEnabled then return end

    local localCharacter = player.Character
    local playerRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not playerRoot then return end

    local now = os.clock()

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local _, attackerRoot, attackerHumanoid = getCharacterParts(otherPlayer)
            if attackerRoot and attackerHumanoid then
                local offset = playerRoot.Position - attackerRoot.Position
                local distance = offset.Magnitude

                if distance <= settings.dodgeDistance then
                    local foundTrack = false
                    local animator = attackerHumanoid:FindFirstChildOfClass("Animator")

                    if animator then
                        local tracks = {}
                        pcall(function() tracks = animator:GetPlayingAnimationTracks() end)
                        for _, track in ipairs(tracks) do
                            if processAttackTrack(otherPlayer, attackerRoot, playerRoot, track, "escaneo de animacion") then
                                foundTrack = true
                                break
                            end
                        end
                    end

                    -- Fallback de amenaza: cubre animaciones no replicadas o sin nombre util.
                    -- Es mas agresivo a corta distancia para no depender solo de la velocidad.
                    if not foundTrack then
                        local directionToPlayer = distance > 0.01 and offset.Unit or Vector3.zero
                        local facingDot = getFacingDot(attackerRoot, playerRoot)
                        local attackerVelocity = attackerRoot.AssemblyLinearVelocity
                        local playerVelocity = playerRoot.AssemblyLinearVelocity
                        local closingSpeed = (attackerVelocity - playerVelocity):Dot(directionToPlayer)
                        local attackerSpeed = attackerVelocity.Magnitude

                        local closeThreatRange = math.min(settings.dodgeDistance, 5.8)
                        local closingThreatRange = math.min(settings.dodgeDistance, 9.0)
                        local veryCloseThreat = distance <= closeThreatRange and facingDot > -0.45
                        local movingThreat = distance <= closingThreatRange
                            and closingSpeed > 1.15
                            and facingDot > -0.65
                        local fastApproachThreat = distance <= closingThreatRange
                            and attackerSpeed > 7.0
                            and closingSpeed > 0.25

                        local lastFallback = lastFallbackByPlayer[otherPlayer] or 0
                        if (veryCloseThreat or movingThreat or fastApproachThreat)
                            and now - lastFallback >= 0.38 then

                            -- Sin retraso extra: la deteccion por proximidad ya suele llegar tarde.
                            local queued = executePerfectDodge(
                                attackerRoot,
                                playerRoot,
                                nil,
                                otherPlayer,
                                "proximidad/velocidad",
                                0
                            )
                            if queued then
                                lastFallbackByPlayer[otherPlayer] = now
                                lastStatus = "amenaza cercana detectada: " .. tostring(otherPlayer.Name)
                                if updateDodgeStatus then updateDodgeStatus() end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- La deteccion automatica funciona cuando el toggle esta activo; L2 manual no es requerido.

-- ==================== EVENTOS Y LOOPS ====================

local closed = false
local renderConnection
local heartbeatConnection

closeBtn.MouseButton1Click:Connect(function()
    if closed then return end
    closed = true
    settings.hitboxEnabled = false
    settings.perfectDodgeEnabled = false
    if restoreHitboxes then restoreHitboxes() end
    for otherPlayer in pairs(espByPlayer) do removePlayerESP(otherPlayer) end
    if renderConnection then renderConnection:Disconnect() end
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    for _, connection in ipairs(detectionConnections) do
        pcall(function() connection:Disconnect() end)
    end
    screenGui:Destroy()
    print("[Combat Tools] Script cerrado")
end)

Players.PlayerAdded:Connect(function()
    task.wait(0.3)
    if settings.hitboxEnabled then expandHitboxes() end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    lastFallbackByPlayer[leavingPlayer] = nil
end)

renderConnection = RunService.RenderStepped:Connect(function()
    if not closed then
        expandHitboxes()
        updatePlayerESP()
    end
end)

heartbeatConnection = RunService.Heartbeat:Connect(function()
    if not closed then
        detectAttacks()
    end
end)

player.CharacterAdded:Connect(function()
    if restoreHitboxes then restoreHitboxes() end
    task.wait(0.5)
    if settings.hitboxEnabled then expandHitboxes() end
    updatePlayerESP()
end)

print("[X Hub] Cargado")
print("Hitbox Expander: contorno blanco en HumanoidRootPart, sin redimensionar extremidades")
print("Auto Perfect Wave: detección por animación/proximidad")
print("Player ESP: posición, distancia y HP configurables")
print("Nota: los cambios de hitbox del cliente pueden no afectar la validación del servidor")
