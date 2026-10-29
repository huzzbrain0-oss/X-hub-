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
    godmodeEnabled = false,
    dodgeDistance = 12,
    perfectDodgeTiming = 0.035,
    perfectDodgeCooldown = 0.12,
    lastDodgeTime = 0,
    originalSizes = {}
}

local restoreHitboxes
local applyGodmode, disableGodmode

-- ==================== CREAR GUI: X HUB (TEMA NEGRO/ROJO) ====================

local RED = Color3.fromRGB(235, 25, 40)
local DARK_RED = Color3.fromRGB(95, 0, 10)
local BLACK = Color3.fromRGB(5, 5, 7)
local PANEL_BLACK = Color3.fromRGB(12, 12, 15)
local TEXT_WHITE = Color3.fromRGB(245, 245, 245)
local TEXT_RED = Color3.fromRGB(255, 105, 115)

local camera = workspace.CurrentCamera
local viewportWidth = camera and camera.ViewportSize.X or 800
-- El panel se adapta al ancho disponible para no quedar fuera de pantalla en móvil.
local panelWidth = math.clamp(viewportWidth - 24, 300, 480)
local sidebarWidth = math.clamp(panelWidth * 0.23, 70, 112)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XHubGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainPanel = Instance.new("Frame")
mainPanel.Name = "XHubPanel"
mainPanel.Size = UDim2.new(0, panelWidth, 0, 530)
mainPanel.Position = UDim2.new(0, 12, 0, 20)
mainPanel.BackgroundColor3 = BLACK
mainPanel.BorderSizePixel = 2
mainPanel.BorderColor3 = RED
mainPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 6)
panelCorner.Parent = mainPanel

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -42, 0, 40)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = BLACK
titleLabel.TextColor3 = RED
titleLabel.TextSize = 19
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "X Hub"
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Active = true
titleLabel.ZIndex = 2
titleLabel.Parent = mainPanel

local titleLine = Instance.new("Frame")
titleLine.Name = "TitleRedLine"
titleLine.Size = UDim2.new(1, 0, 0, 2)
titleLine.Position = UDim2.new(0, 0, 0, 39)
titleLine.BackgroundColor3 = RED
titleLine.BorderSizePixel = 0
titleLine.ZIndex = 3
titleLine.Parent = mainPanel

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
minimizeBtn.ZIndex = 4
minimizeBtn.Parent = mainPanel

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

-- Barra lateral izquierda: categoría Combat.
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Position = UDim2.new(0, 0, 0, 41)
sidebar.Size = UDim2.new(0, sidebarWidth, 1, -41)
sidebar.BackgroundColor3 = BLACK
sidebar.BorderSizePixel = 0
sidebar.Parent = mainPanel

local sidebarHeader = Instance.new("TextLabel")
sidebarHeader.Name = "SidebarHeader"
sidebarHeader.Size = UDim2.new(1, -12, 0, 28)
sidebarHeader.Position = UDim2.new(0, 8, 0, 10)
sidebarHeader.BackgroundTransparency = 1
sidebarHeader.TextColor3 = TEXT_RED
sidebarHeader.TextSize = 11
sidebarHeader.Font = Enum.Font.GothamBold
sidebarHeader.Text = "CATEGORÍAS"
sidebarHeader.TextXAlignment = Enum.TextXAlignment.Left
sidebarHeader.Parent = sidebar

local combatCategoryButton = Instance.new("TextButton")
combatCategoryButton.Name = "CombatCategory"
combatCategoryButton.Size = UDim2.new(1, -14, 0, 38)
combatCategoryButton.Position = UDim2.new(0, 7, 0, 42)
combatCategoryButton.BackgroundColor3 = DARK_RED
combatCategoryButton.TextColor3 = TEXT_WHITE
combatCategoryButton.TextSize = 13
combatCategoryButton.Font = Enum.Font.GothamBold
combatCategoryButton.Text = "⚔  COMBAT"
combatCategoryButton.TextXAlignment = Enum.TextXAlignment.Left
combatCategoryButton.BorderSizePixel = 1
combatCategoryButton.BorderColor3 = RED
combatCategoryButton.Parent = sidebar

local combatCategoryPadding = Instance.new("UIPadding")
combatCategoryPadding.PaddingLeft = UDim.new(0, 8)
combatCategoryPadding.Parent = combatCategoryButton

local sidebarDivider = Instance.new("Frame")
sidebarDivider.Name = "SidebarDivider"
sidebarDivider.Size = UDim2.new(0, 2, 1, -41)
sidebarDivider.Position = UDim2.new(0, sidebarWidth - 1, 0, 41)
sidebarDivider.BackgroundColor3 = RED
sidebarDivider.BorderSizePixel = 0
sidebarDivider.Parent = mainPanel

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "CombatContent"
contentFrame.Position = UDim2.new(0, sidebarWidth + 9, 0, 42)
contentFrame.Size = UDim2.new(1, -(sidebarWidth + 12), 1, -44)
contentFrame.BackgroundColor3 = PANEL_BLACK
contentFrame.BorderSizePixel = 0
contentFrame.Active = true
contentFrame.ScrollingEnabled = true
contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
contentFrame.ScrollBarThickness = 5
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

combatCategoryButton.MouseButton1Click:Connect(function()
    -- Por ahora, todas las opciones del mod pertenecen a Combat.
    contentFrame.Visible = true
    combatCategoryButton.BackgroundColor3 = DARK_RED
end)

-- ==================== ELEMENTOS DE UI ====================

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
    label.Parent = contentFrame
    return label
end

local function createToggle(text, defaultState, callback, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 35)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder
    container.Parent = contentFrame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundColor3 = defaultState and DARK_RED or Color3.fromRGB(22, 22, 25)
    button.TextColor3 = TEXT_WHITE
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Text = text .. " [" .. (defaultState and "ON" or "OFF") .. "]"
    button.BorderSizePixel = 1
    button.BorderColor3 = RED
    button.Parent = container

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = button

    local state = defaultState
    button.MouseButton1Click:Connect(function()
        state = not state
        button.BackgroundColor3 = state and DARK_RED or Color3.fromRGB(22, 22, 25)
        button.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"
        if callback then callback(state) end
    end)
    return container
end

local function createSlider(labelText, minVal, maxVal, defaultVal, callback, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder
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
    sliderBg.BackgroundColor3 = Color3.fromRGB(38, 15, 18)
    sliderBg.BorderSizePixel = 0
    sliderBg.Active = true
    sliderBg.Parent = container

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = RED
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg

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

-- ==================== SECCION HITBOX ====================

createLabel("HITBOX EXPANDER", 1)

createSlider("Tamaño del Hitbox:", 1, 5, 2, function(value)
    settings.hitboxSize = value
    if settings.hitboxEnabled then
        print("[Combat Tools] Tamaño del hitbox: " .. tostring(math.round(value * 10) / 10) .. "x")
    end
end, 2)

createToggle("Activar Hitbox", true, function(state)
    settings.hitboxEnabled = state
    if not state and restoreHitboxes then restoreHitboxes() end
    print("[X Hub] Hitbox: " .. (state and "ACTIVADO" or "DESACTIVADO"))
end, 3)

local sepHitbox = Instance.new("Frame")
sepHitbox.Size = UDim2.new(1, 0, 0, 2)
sepHitbox.BackgroundColor3 = RED
sepHitbox.BorderSizePixel = 0
sepHitbox.LayoutOrder = 4
sepHitbox.Parent = contentFrame

createLabel("GODMODE", 5)

createToggle("Activar Godmode (local)", false, function(state)
    settings.godmodeEnabled = state
    if state then
        if applyGodmode then applyGodmode() end
        print("[X Hub] Godmode local activado (mejor esfuerzo)")
    else
        if disableGodmode then disableGodmode() end
        print("[X Hub] Godmode desactivado")
    end
end, 6)

local sepGodmode = Instance.new("Frame")
sepGodmode.Size = UDim2.new(1, 0, 0, 2)
sepGodmode.BackgroundColor3 = RED
sepGodmode.BorderSizePixel = 0
sepGodmode.LayoutOrder = 7
sepGodmode.Parent = contentFrame

-- ==================== SECCION PERFECT AUTO DODGE / WAVE ====================

createLabel("PERFECT AUTO DODGE / WAVE", 8)

local perfectDodgeCount = 0
local lastStatus = "esperando"
local updateDodgeStatus

createToggle("Activar Perfect Dodge Automático", false, function(state)
    settings.perfectDodgeEnabled = state
    lastStatus = state and "detector automático activo" or "desactivado"
    print("[X Hub] Perfect Dodge automático: " .. (state and "ACTIVADO" or "DESACTIVADO"))
    if updateDodgeStatus then updateDodgeStatus() end
end, 9)

createSlider("Rango de detección (studs):", 5, 25, 12, function(value)
    settings.dodgeDistance = value
    print("[X Hub] Rango: " .. math.round(value) .. " studs")
end, 10)

createSlider("Timing de esquiva (ms):", 5, 150, 35, function(value)
    settings.perfectDodgeTiming = value / 1000
    print("[X Hub] Timing: " .. math.round(value) .. " ms")
end, 11)

createLabel("Se activa al detectar un ataque cercano; no hace falta mantener L2.", 12)

local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "DodgeStatus"
infoLabel.Size = UDim2.new(1, 0, 0, 48)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = TEXT_RED
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.Gotham
infoLabel.Text = "Modo: AUTOMÁTICO\nIntentos de esquiva: 0\nEstado: esperando ataque"
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.TextWrapped = true
infoLabel.LayoutOrder = 13
infoLabel.Parent = contentFrame

updateDodgeStatus = function()
    if not infoLabel or not infoLabel.Parent then return end
    infoLabel.Text = "Modo: " .. (settings.perfectDodgeEnabled and "AUTOMÁTICO ACTIVO" or "DESACTIVADO")
        .. "\nIntentos de esquiva: " .. tostring(perfectDodgeCount)
        .. "\nEstado: " .. lastStatus
end

local actionContainer = Instance.new("Frame")
actionContainer.Size = UDim2.new(1, 0, 0, 40)
actionContainer.BackgroundTransparency = 1
actionContainer.LayoutOrder = 14
actionContainer.Parent = contentFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, 0, 1, 0)
closeBtn.BackgroundColor3 = DARK_RED
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X  Cerrar X Hub"
closeBtn.BorderSizePixel = 1
closeBtn.BorderColor3 = RED
closeBtn.Parent = actionContainer

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

-- ==================== COPIAS VISUALES PARA EL HITBOX ====================

local function createVisualClone(part, originalSize, originalLocalTransparency)
    local visualPart
    local ok = pcall(function() visualPart = part:Clone() end)
    if not ok or not visualPart then return nil end

    for _, child in ipairs(visualPart:GetDescendants()) do
        if child:IsA("BasePart") or child:IsA("JointInstance") or child:IsA("Constraint")
            or child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
            child:Destroy()
        end
    end

    visualPart.Name = "CombatToolsVisual_" .. part.Name
    visualPart:SetAttribute("CombatToolsVisualClone", true)
    visualPart.Size = originalSize
    visualPart.CFrame = part.CFrame
    visualPart.Anchored = false
    visualPart.CanCollide = false
    visualPart.CanTouch = false
    pcall(function() visualPart.CanQuery = false end)
    visualPart.Massless = true
    visualPart.LocalTransparencyModifier = originalLocalTransparency or 0
    visualPart.Parent = part.Parent

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part
    weld.Part1 = visualPart
    weld.Parent = visualPart
    return visualPart
end

-- ==================== RESTAURAR HITBOXES ====================

restoreHitboxes = function()
    for part, data in pairs(settings.originalSizes) do
        pcall(function()
            if part and part.Parent then
                part.Size = data.Size
                part.CanCollide = data.CanCollide
                part.LocalTransparencyModifier = data.LocalTransparencyModifier or 0
            end
        end)
        if data.visualClone then
            pcall(function() data.visualClone:Destroy() end)
        end
    end
    settings.originalSizes = {}
end

-- ==================== GODMODE (MEJOR ESFUERZO LOCAL) ====================
-- El cliente intenta restaurar la vida y agrega un ForceField local. Los juegos
-- con validacion de vida/daño en el servidor pueden ignorar o revertir estos cambios.

local godmodeHumanoid = nil
local godmodeOriginalMaxHealth = nil
local godmodeHealthConnection = nil
local godmodeForceField = nil

applyGodmode = function()
    if not settings.godmodeEnabled then return end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if godmodeHumanoid ~= humanoid then
        if godmodeHealthConnection then
            pcall(function() godmodeHealthConnection:Disconnect() end)
            godmodeHealthConnection = nil
        end
        if godmodeForceField then
            pcall(function() godmodeForceField:Destroy() end)
            godmodeForceField = nil
        end

        godmodeHumanoid = humanoid
        godmodeOriginalMaxHealth = humanoid.MaxHealth

        local forceField = Instance.new("ForceField")
        forceField.Name = "XHubLocalGodmode"
        forceField.Visible = false
        forceField.Parent = character
        godmodeForceField = forceField

        godmodeHealthConnection = humanoid.HealthChanged:Connect(function(health)
            if not settings.godmodeEnabled or godmodeHumanoid ~= humanoid then return end
            if health < humanoid.MaxHealth then
                task.defer(function()
                    if settings.godmodeEnabled and godmodeHumanoid == humanoid
                        and humanoid.Parent and humanoid.Health < humanoid.MaxHealth then
                        pcall(function() humanoid.Health = humanoid.MaxHealth end)
                    end
                end)
            end
        end)
    end

    pcall(function()
        -- Aumenta MaxHealth en el cliente y recupera la vida cuando baja.
        if humanoid.MaxHealth < 10000 then
            humanoid.MaxHealth = 10000
        end
        if humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
end

disableGodmode = function()
    if godmodeHealthConnection then
        pcall(function() godmodeHealthConnection:Disconnect() end)
        godmodeHealthConnection = nil
    end
    if godmodeForceField then
        pcall(function() godmodeForceField:Destroy() end)
        godmodeForceField = nil
    end

    if godmodeHumanoid and godmodeHumanoid.Parent and godmodeOriginalMaxHealth then
        pcall(function()
            godmodeHumanoid.MaxHealth = godmodeOriginalMaxHealth
            if godmodeHumanoid.Health > godmodeOriginalMaxHealth then
                godmodeHumanoid.Health = godmodeOriginalMaxHealth
            end
        end)
    end

    godmodeHumanoid = nil
    godmodeOriginalMaxHealth = nil
end

-- ==================== FUNCION HITBOX EXPANDER ====================

local function expandHitboxes()
    if not settings.hitboxEnabled then return end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and not part:GetAttribute("CombatToolsVisualClone") then
                    if not settings.originalSizes[part] then
                        local data = {
                            Size = part.Size,
                            CanCollide = part.CanCollide,
                            LocalTransparencyModifier = part.LocalTransparencyModifier,
                            visualClone = nil
                        }
                        settings.originalSizes[part] = data
                        data.visualClone = createVisualClone(part, data.Size, data.LocalTransparencyModifier)
                        if data.visualClone then
                            part.LocalTransparencyModifier = 1
                        end
                    end

                    local data = settings.originalSizes[part]
                    if data then
                        part.Size = data.Size * settings.hitboxSize
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end

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
    settings.godmodeEnabled = false
    if disableGodmode then disableGodmode() end
    if restoreHitboxes then restoreHitboxes() end
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
    if not closed then expandHitboxes() end
end)

heartbeatConnection = RunService.Heartbeat:Connect(function()
    if not closed then
        if settings.godmodeEnabled and applyGodmode then applyGodmode() end
        detectAttacks()
    end
end)

player.CharacterAdded:Connect(function()
    if restoreHitboxes then restoreHitboxes() end
    if disableGodmode then disableGodmode() end
    task.wait(0.5)
    if settings.hitboxEnabled then expandHitboxes() end
    if settings.godmodeEnabled and applyGodmode then applyGodmode() end
end)

print("[X Hub] Cargado")
print("Hitbox Expander: listo")
print("Perfect Wave: auto-deteccion por animacion/proximidad (sin L2 manual)")
print("Godmode: modo local de mejor esfuerzo")
print("Nota: la deteccion es aproximada; la simulacion de L2 depende del executor y del juego")
