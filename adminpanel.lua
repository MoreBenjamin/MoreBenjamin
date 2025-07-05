--[[
    🚀 Ultra Admin Panel v7.0 🚀
    Nejkomplexnější administrační systém pro Roblox
    Autor: [Váš název]
    Verze: 7.0 (Enterprise)
    Datum: 2025-07-06
    
    ⚠️ VŠECHNA PRÁVA VYHRAZENA ⚠️
]]

local plugin = script:FindFirstAncestorOfClass("Plugin")
local selection = game:GetService("Selection")
local httpService = game:GetService("HttpService")

-- ##Hlavní funkce pro vytvoření admin panelu
local function createAdminSystem()
    -- ##Základní struktura složek
    local adminFolder = Instance.new("Folder")
    adminFolder.Name = "UltraAdminSystem"
    adminFolder.Parent = game:GetService("ServerStorage")
    
    -- ##Hlavní komponenty systému
    local serverScriptService = game:GetService("ServerScriptService")
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local starterGui = game:GetService("StarterGui")
    local serverStorage = game:GetService("ServerStorage")
    
    -- ##Vytvoření základních složek
    local adminMainFolder = Instance.new("Folder")
    adminMainFolder.Name = "UltraAdmin"
    adminMainFolder.Parent = adminFolder
    
    local adminModules = Instance.new("Folder")
    adminModules.Name = "Modules"
    adminModules.Parent = adminMainFolder
    
    local adminEvents = Instance.new("Folder")
    adminEvents.Name = "Events"
    adminEvents.Parent = adminMainFolder
    
    local adminUI = Instance.new("Folder")
    adminUI.Name = "UI"
    adminUI.Parent = adminMainFolder
    
    -- ##Hlavní serverový skript
    local adminServer = Instance.new("Script")
    adminServer.Name = "AdminServer"
    adminServer.Source = [[
        -- ##Hlavní serverový skript
        
        local Players = game:GetService("Players")
        local ServerStorage = game:GetService("ServerStorage")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RunService = game:GetService("RunService")
        local Lighting = game:GetService("Lighting")
        local TeleportService = game:GetService("TeleportService")
        
        -- ##Načtení modulů
        local UltraAdmin = ServerStorage:WaitForChild("UltraAdminSystem"):WaitForChild("UltraAdmin")
        local Events = UltraAdmin:WaitForChild("Events")
        local Modules = UltraAdmin:WaitForChild("Modules")
        
        local Logger = require(Modules:WaitForChild("Logger"))
        local Permissions = require(Modules:WaitForChild("Permissions"))
        local AntiCheat = require(Modules:WaitForChild("AntiCheat"))
        local Config = require(Modules:WaitForChild("Config"))
        local Utils = require(Modules:WaitForChild("Utils"))
        
        -- Inicializace systémů
        Logger.init()
        Permissions.loadAdmins()
        AntiCheat.startMonitoring()
        Config.loadSettings()
        
        -- ##Zpracování příkazů od adminů
        local function processAdminCommand(player, command, args)
            if not Permissions.isAdmin(player) then
                Logger.logWarning(player.Name .. " se pokusil použít admin příkaz bez oprávnění: " .. command)
                return false
            end
            
            local playerLevel = Permissions.getAdminLevel(player)
            local commandData = Config.getCommandData(command)
            
            if not commandData then
                Logger.logWarning("Neplatný příkaz: " .. command)
                return false
            end
            
            -- Kontrola oprávnění
            if not Permissions.hasPermission(playerLevel, commandData.minLevel) then
                Logger.logWarning(player.Name .. " nemá oprávnění pro příkaz: " .. command)
                return false
            end
            
            -- Zpracování příkazu
            local success, result = pcall(function()
                -- ##Hráčské příkazy
                if command == "Kick" then
                    local target = Players:FindFirstChild(args[1])
                    if target then
                        target:Kick("Vyhozen adminem: " .. player.Name .. "\nDůvod: " .. (args[2] or "Neuvedeno"))
                        return true
                    end
                    
                elseif command == "Ban" then
                    local target = Players:FindFirstChild(args[1])
                    if target then
                        Permissions.addBan(target.UserId, "Permanentní ban", player.UserId)
                        target:Kick("Permabanován adminem: " .. player.Name .. "\nDůvod: " .. (args[2] or "Neuvedeno"))
                        return true
                    end
                    
                -- ##Nástroje světa
                elseif command == "SetWeather" then
                    local weatherType = args[1]
                    if weatherType == "Sunny" then
                        Lighting.Weather = "Clear"
                    elseif weatherType == "Rain" then
                        Lighting.Weather = "Rain"
                    elseif weatherType == "Storm" then
                        Lighting.Weather = "Thunderstorm"
                    end
                    
                elseif command == "ToggleDayNight" then
                    if Lighting.ClockTime > 18 or Lighting.ClockTime < 6 then
                        Lighting.ClockTime = 12
                    else
                        Lighting.ClockTime = 0
                    end
                    
                -- ##Ostatní příkazy
                elseif command == "TeleportToPlayer" then
                    local target = Players:FindFirstChild(args[1])
                    if target and target.Character then
                        player.Character:MoveTo(target.Character.HumanoidRootPart.Position)
                    end
                    
                elseif command == "FreezePlayer" then
                    local target = Players:FindFirstChild(args[1])
                    if target and target.Character then
                        local humanoid = target.Character:FindFirstChild("Humanoid")
                        if humanoid then
                            humanoid.WalkSpeed = 0
                        end
                    end
                    
                -- Přidat další příkazy podle potřeby...
                end
            end)
            
            if success then
                Logger.logAction(player.Name, command, args)
                return result
            else
                Logger.logError("Chyba při zpracování příkazu " .. command .. ": " .. result)
                return false
            end
        end
        
        -- Připojení RemoteEventů
        Events.AdminCommand.OnServerEvent:Connect(function(player, command, args)
            processAdminCommand(player, command, args)
        end)
        
        Events.PlayerLog.OnServerEvent:Connect(function(player, logType, data)
            if logType == "Join" then
                Logger.logPlayer(player.Name, "Připojil se do hry", {
                    AccountAge = player.AccountAge,
                    UserId = player.UserId
                })
            elseif logType == "Leave" then
                Logger.logPlayer(player.Name, "Opustil hru", {
                    PlayTime = os.time() - player.JoinTime
                })
            end
        end)
        
        -- ##Anti-Cheat reporty
        AntiCheat.onViolation:Connect(function(player, reason, data)
            Logger.logSuspicious(player.Name, reason, data)
            
            if Config.getSetting("AutoBanOnCheat") then
                player:Kick("Anti-Cheat: " .. reason)
                Permissions.addBan(player.UserId, "Auto-ban: " .. reason, 0)
            end
        end)
        
        -- ##Uložení stavu při vypnutí
        game:BindToClose(function()
            Permissions.saveAdmins()
            Config.saveSettings()
            Logger.exportLogs()
        end)
    ]]
    adminServer.Parent = serverScriptService
    
    -- ##Hlavní klientský skript
    local adminClient = Instance.new("LocalScript")
    adminClient.Name = "AdminClient"
    adminClient.Source = [[
        -- ##Hlavní klientský skript
        
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local UserInputService = game:GetService("UserInputService")
        local RunService = game:GetService("RunService")
        local GuiService = game:GetService("GuiService")
        local player = Players.LocalPlayer
        
        -- ##Načtení modulů
        local UltraAdmin = ReplicatedStorage:WaitForChild("UltraAdminSystem"):WaitForChild("UltraAdmin")
        local Events = UltraAdmin:WaitForChild("Events")
        local UI = UltraAdmin:WaitForChild("UI")
        local Modules = UltraAdmin:WaitForChild("Modules")
        
        local Config = require(Modules:WaitForChild("Config"))
        local Utils = require(Modules:WaitForChild("Utils"))
        local Permissions = require(Modules:WaitForChild("Permissions"))
        
        -- ##GUI komponenty
        local adminGUI = UI:WaitForChild("AdminGUI"):Clone()
        adminGUI.Parent = player:WaitForChild("PlayerGui")
        
        local mainFrame = adminGUI:WaitForChild("MainFrame")
        local tabButtons = mainFrame:WaitForChild("TabButtons")
        local tabContent = mainFrame:WaitForChild("TabContent")
        
        -- Proměnné
        local currentTab = "Players"
        local playerList = {}
        local isGuiVisible = false
        
        -- ##Funkce pro aktualizaci GUI
        local function updatePlayerList()
            local playersTab = tabContent:WaitForChild("PlayersTab")
            local playerListContainer = playersTab:WaitForChild("PlayerListContainer")
            
            -- Vymazání starého seznamu
            for _, child in ipairs(playerListContainer:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            -- Přidání hráčů
            for _, target in ipairs(Players:GetPlayers()) do
                if target ~= player then
                    local playerFrame = Instance.new("Frame")
                    playerFrame.Name = target.Name
                    playerFrame.Size = UDim2.new(1, -20, 0, 50)
                    playerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    playerFrame.BorderSizePixel = 0
                    
                    local playerName = Instance.new("TextLabel")
                    playerName.Name = "PlayerName"
                    playerName.Text = target.Name .. " (@" .. target.DisplayName .. ")"
                    playerName.Size = UDim2.new(0.3, 0, 1, 0)
                    playerName.Position = UDim2.new(0.01, 0, 0, 0)
                    playerName.TextColor3 = Color3.fromRGB(255, 255, 255)
                    playerName.Font = Enum.Font.GothamBold
                    playerName.TextSize = 14
                    playerName.TextXAlignment = Enum.TextXAlignment.Left
                    playerName.BackgroundTransparency = 1
                    playerName.Parent = playerFrame
                    
                    local playerInfo = Instance.new("TextLabel")
                    playerInfo.Name = "PlayerInfo"
                    playerInfo.Text = "ID: " .. target.UserId .. " | Ping: " .. target:GetNetworkPing()
                    playerInfo.Size = UDim2.new(0.3, 0, 1, 0)
                    playerInfo.Position = UDim2.new(0.32, 0, 0, 0)
                    playerInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
                    playerInfo.Font = Enum.Font.Gotham
                    playerInfo.TextSize = 12
                    playerInfo.TextXAlignment = Enum.TextXAlignment.Left
                    playerInfo.BackgroundTransparency = 1
                    playerInfo.Parent = playerFrame
                    
                    -- Tlačítka pro akce
                    local actionsFrame = Instance.new("Frame")
                    actionsFrame.Name = "Actions"
                    actionsFrame.Size = UDim2.new(0.35, 0, 1, 0)
                    actionsFrame.Position = UDim2.new(0.65, 0, 0, 0)
                    actionsFrame.BackgroundTransparency = 1
                    
                    -- Teleportovat
                    local teleportBtn = Instance.new("TextButton")
                    teleportBtn.Name = "Teleport"
                    teleportBtn.Text = "Teleport"
                    teleportBtn.Size = UDim2.new(0.3, 0, 0.8, 0)
                    teleportBtn.Position = UDim2.new(0, 0, 0.1, 0)
                    teleportBtn.Font = Enum.Font.Gotham
                    teleportBtn.TextSize = 12
                    teleportBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
                    teleportBtn.TextColor3 = Color3.white
                    teleportBtn.Parent = actionsFrame
                    
                    teleportBtn.MouseButton1Click:Connect(function()
                        Events.AdminCommand:FireServer("TeleportToPlayer", {target.Name})
                    end)
                    
                    -- Vyhodit
                    local kickBtn = Instance.new("TextButton")
                    kickBtn.Name = "Kick"
                    kickBtn.Text = "Vyhodit"
                    kickBtn.Size = UDim2.new(0.3, 0, 0.8, 0)
                    kickBtn.Position = UDim2.new(0.35, 0, 0.1, 0)
                    kickBtn.Font = Enum.Font.Gotham
                    kickBtn.TextSize = 12
                    kickBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 80)
                    kickBtn.TextColor3 = Color3.white
                    kickBtn.Parent = actionsFrame
                    
                    kickBtn.MouseButton1Click:Connect(function()
                        Events.AdminCommand:FireServer("Kick", {target.Name, "Porušení pravidel"})
                    end)
                    
                    -- Zmrazit
                    local freezeBtn = Instance.new("TextButton")
                    freezeBtn.Name = "Freeze"
                    freezeBtn.Text = "Zmrazit"
                    freezeBtn.Size = UDim2.new(0.3, 0, 0.8, 0)
                    freezeBtn.Position = UDim2.new(0.7, 0, 0.1, 0)
                    freezeBtn.Font = Enum.Font.Gotham
                    freezeBtn.TextSize = 12
                    freezeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 180)
                    freezeBtn.TextColor3 = Color3.white
                    freezeBtn.Parent = actionsFrame
                    
                    freezeBtn.MouseButton1Click:Connect(function()
                        Events.AdminCommand:FireServer("FreezePlayer", {target.Name})
                    end)
                    
                    actionsFrame.Parent = playerFrame
                    playerFrame.Parent = playerListContainer
                end
            end
        end
        
        -- ##Funkce pro aktualizaci logů
        local function updateLogs()
            local logsTab = tabContent:WaitForChild("LogsTab")
            local logsContainer = logsTab:WaitForChild("LogsContainer")
            
            -- Vymazání starých logů
            for _, child in ipairs(logsContainer:GetChildren()) do
                if child:IsA("TextLabel") then
                    child:Destroy()
                end
            end
            
            -- Požádat server o logy
            Events.GetLogs:FireServer()
        end
        
        -- ##Funkce pro přepínání GUI
        local function toggleGUI()
            isGuiVisible = not isGuiVisible
            mainFrame.Visible = isGuiVisible
            
            if isGuiVisible then
                updatePlayerList()
                updateLogs()
                GuiService:SetMenuIsOpen(true)
            else
                GuiService:SetMenuIsOpen(false)
            end
        end
        
        -- ##Klávesové zkratky
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            
            -- Přepínání GUI pomocí F5
            if input.KeyCode == Enum.KeyCode.F5 then
                toggleGUI()
            end
            
            -- Chat příkaz /admin
            if input.KeyCode == Enum.KeyCode.Slash then
                local chatBar = player.PlayerGui:FindFirstChild("Chat") and player.PlayerGui.Chat:FindFirstChild("ChatBar")
                if chatBar then
                    spawn(function()
                        wait(0.1)
                        if chatBar.Text == "/admin " then
                            toggleGUI()
                        end
                    end)
                end
            end
        end)
        
        -- ##Inicializace GUI
        for _, tabBtn in ipairs(tabButtons:GetChildren()) do
            if tabBtn:IsA("TextButton") then
                tabBtn.MouseButton1Click:Connect(function()
                    currentTab = tabBtn.Name:gsub("Tab", "")
                    for _, tab in ipairs(tabContent:GetChildren()) do
                        if tab:IsA("Frame") then
                            tab.Visible = tab.Name == currentTab .. "Tab"
                        end
                    end
                end)
            end
        end
        
        -- ##Tlačítko zavření
        local closeBtn = mainFrame:WaitForChild("CloseButton")
        closeBtn.MouseButton1Click:Connect(toggleGUI)
        
        -- ##Nastavení tématu
        local function updateTheme()
            local isDarkMode = Config.getSetting("Theme") == "Dark"
            local bgColor = isDarkMode and Color3.fromRGB(30, 30, 40) or Color3.fromRGB(240, 240, 245)
            local textColor = isDarkMode and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 20, 20)
            local btnColor = isDarkMode and Color3.fromRGB(50, 50, 70) or Color3.fromRGB(200, 200, 220)
            
            mainFrame.BackgroundColor3 = bgColor
            mainFrame.BackgroundTransparency = isDarkMode and 0.1 or 0.05
            
            for _, child in ipairs(mainFrame:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    child.TextColor3 = textColor
                end
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = btnColor
                end
            end
        end
        
        -- ##Připojení RemoteEventů
        Events.UpdateLogs.OnClientEvent:Connect(function(logs)
            local logsTab = tabContent:WaitForChild("LogsTab")
            local logsContainer = logsTab:WaitForChild("LogsContainer")
            
            for _, log in ipairs(logs) do
                local logLabel = Instance.new("TextLabel")
                logLabel.Text = "[" .. os.date("%H:%M:%S", log.time) .. "] " .. log.message
                logLabel.Size = UDim2.new(1, -10, 0, 30)
                logLabel.TextColor3 = log.type == "WARNING" and Color3.fromRGB(255, 200, 100) 
                                      or log.type == "ERROR" and Color3.fromRGB(255, 100, 100) 
                                      or Color3.fromRGB(180, 230, 255)
                logLabel.Font = Enum.Font.Gotham
                logLabel.TextSize = 12
                logLabel.TextXAlignment = Enum.TextXAlignment.Left
                logLabel.BackgroundTransparency = 1
                logLabel.Parent = logsContainer
            end
        end)
        
        -- ##Easter egg - Matrix Mode
        local matrixMode = false
        UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.M and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                matrixMode = not matrixMode
                for _, obj in ipairs(adminGUI:GetDescendants()) do
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                        obj.TextColor3 = matrixMode and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
                    end
                end
            end
        end)
        
        -- ##Skrytí GUI pro neoprávněné
        if not Permissions.isAdmin(player) then
            adminGUI:Destroy()
        end
        
        -- Inicializace
        updateTheme()
        toggleGUI()  -- GUI je zpočátku skryté
    ]]
    adminClient.Parent = starterGui
    
    -- ##GUI komponenty
    local adminGUI = Instance.new("ScreenGui")
    adminGUI.Name = "AdminGUI"
    adminGUI.ResetOnSpawn = false
    adminGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Hlavní okno
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.7, 0, 0.8, 0)
    mainFrame.Position = UDim2.new(0.15, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    
    -- ##Záhlaví
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0.08, 0)
    header.BackgroundTransparency = 1
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "ULTRA ADMIN PANEL"
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0.15, 0, 0, 0)
    title.TextColor3 = Color3.fromRGB(100, 180, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.BackgroundTransparency = 1
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Text = "✕"
    closeBtn.Size = UDim2.new(0.08, 0, 1, 0)
    closeBtn.Position = UDim2.new(0.92, 0, 0, 0)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Parent = header
    
    header.Parent = mainFrame
    
    -- ##Záložky panelu
    local tabButtons = Instance.new("Frame")
    tabButtons.Name = "TabButtons"
    tabButtons.Size = UDim2.new(1, 0, 0.08, 0)
    tabButtons.Position = UDim2.new(0, 0, 0.08, 0)
    tabButtons.BackgroundTransparency = 1
    
    local tabs = {
        "Players", "Tools", "Logs", "Settings"
    }
    
    for i, tabName in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(0.24, 0, 1, 0)
        tabButton.Position = UDim2.new(0.25 * (i-1), 0, 0, 0)
        tabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        tabButton.Text = tabName
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.Font = Enum.Font.GothamBold
        tabButton.TextSize = 14
        tabButton.Parent = tabButtons
    end
    
    tabButtons.Parent = mainFrame
    
    -- ##Obsah záložek
    local tabContent = Instance.new("Frame")
    tabContent.Name = "TabContent"
    tabContent.Size = UDim2.new(1, 0, 0.84, 0)
    tabContent.Position = UDim2.new(0, 0, 0.16, 0)
    tabContent.BackgroundTransparency = 1
    
    -- ##Záložka Hráči
    local playersTab = Instance.new("ScrollingFrame")
    playersTab.Name = "PlayersTab"
    playersTab.Size = UDim2.new(1, 0, 1, 0)
    playersTab.BackgroundTransparency = 1
    playersTab.ScrollBarThickness = 5
    playersTab.Visible = true
    playersTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local playerListLayout = Instance.new("UIListLayout")
    playerListLayout.Name = "PlayerListLayout"
    playerListLayout.Padding = UDim.new(0, 5)
    playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local playerListContainer = Instance.new("Frame")
    playerListContainer.Name = "PlayerListContainer"
    playerListContainer.Size = UDim2.new(1, -20, 1, -10)
    playerListContainer.Position = UDim2.new(0, 10, 0, 5)
    playerListContainer.BackgroundTransparency = 1
    playerListContainer.Parent = playersTab
    
    playerListLayout.Parent = playerListContainer
    playersTab.Parent = tabContent
    
    -- ##Záložka Nástroje
    local toolsTab = Instance.new("ScrollingFrame")
    toolsTab.Name = "ToolsTab"
    toolsTab.Size = UDim2.new(1, 0, 1, 0)
    toolsTab.BackgroundTransparency = 1
    toolsTab.ScrollBarThickness = 5
    toolsTab.Visible = false
    toolsTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local toolsContainer = Instance.new("Frame")
    toolsContainer.Name = "ToolsContainer"
    toolsContainer.Size = UDim2.new(1, -20, 1, -10)
    toolsContainer.Position = UDim2.new(0, 10, 0, 5)
    toolsContainer.BackgroundTransparency = 1
    toolsContainer.Parent = toolsTab
    
    local toolsListLayout = Instance.new("UIListLayout")
    toolsListLayout.Name = "ToolsListLayout"
    toolsListLayout.Padding = UDim.new(0, 15)
    toolsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    toolsListLayout.Parent = toolsContainer
    
    -- Kategorie nástrojů
    local toolCategories = {
        {
            name = "Počasí",
            tools = {
                {"Slunečno", "SetWeather", {"Sunny"}},
                {"Déšť", "SetWeather", {"Rain"}},
                {"Bouřka", "SetWeather", {"Storm"}}
            }
        },
        {
            name = "Čas",
            tools = {
                {"Den/Noc", "ToggleDayNight", {}},
                {"Rychlý čas", "SetTimeSpeed", {2}},
                {"Pomalý čas", "SetTimeSpeed", {0.5}}
            }
        },
        {
            name = "Server",
            tools = {
                {"Resetovat server", "ResetServer", {}},
                {"Uklidit mapu", "CleanupMap", {}}
            }
        }
    }
    
    for catIndex, category in ipairs(toolCategories) do
        local categoryLabel = Instance.new("TextLabel")
        categoryLabel.Text = category.name
        categoryLabel.Size = UDim2.new(1, 0, 0, 30)
        categoryLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        categoryLabel.Font = Enum.Font.GothamBold
        categoryLabel.TextSize = 16
        categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
        categoryLabel.BackgroundTransparency = 1
        categoryLabel.LayoutOrder = catIndex * 2 - 1
        categoryLabel.Parent = toolsContainer
        
        local toolsFrame = Instance.new("Frame")
        toolsFrame.Name = category.name .. "Tools"
        toolsFrame.Size = UDim2.new(1, 0, 0, 0)
        toolsFrame.BackgroundTransparency = 1
        toolsFrame.LayoutOrder = catIndex * 2
        toolsFrame.AutomaticSize = Enum.AutomaticSize.Y
        toolsFrame.Parent = toolsContainer
        
        local toolsGridLayout = Instance.new("UIGridLayout")
        toolsGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
        toolsGridLayout.CellSize = UDim2.new(0.3, 0, 0, 40)
        toolsGridLayout.FillDirection = Enum.FillDirection.Horizontal
        toolsGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        toolsGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        toolsGridLayout.Parent = toolsFrame
        
        for toolIndex, toolData in ipairs(category.tools) do
            local toolButton = Instance.new("TextButton")
            toolButton.Name = toolData[1]
            toolButton.Text = toolData[1]
            toolButton.Size = UDim2.new(1, 0, 0, 40)
            toolButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            toolButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            toolButton.Font = Enum.Font.Gotham
            toolButton.TextSize = 14
            toolButton.Parent = toolsFrame
            
            toolButton.MouseButton1Click:Connect(function()
                game:GetService("ReplicatedStorage").UltraAdminSystem.UltraAdmin.Events.AdminCommand:FireServer(
                    toolData[2], toolData[3]
                )
            end)
        end
    end
    
    toolsTab.Parent = tabContent
    
    -- ##Záložka Logy
    local logsTab = Instance.new("ScrollingFrame")
    logsTab.Name = "LogsTab"
    logsTab.Size = UDim2.new(1, 0, 1, 0)
    logsTab.BackgroundTransparency = 1
    logsTab.ScrollBarThickness = 5
    logsTab.Visible = false
    logsTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local logsContainer = Instance.new("Frame")
    logsContainer.Name = "LogsContainer"
    logsContainer.Size = UDim2.new(1, -20, 1, -10)
    logsContainer.Position = UDim2.new(0, 10, 0, 5)
    logsContainer.BackgroundTransparency = 1
    logsContainer.Parent = logsTab
    
    local logsListLayout = Instance.new("UIListLayout")
    logsListLayout.Name = "LogsListLayout"
    logsListLayout.Padding = UDim.new(0, 5)
    logsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logsListLayout.Parent = logsContainer
    
    logsTab.Parent = tabContent
    
    -- ##Záložka Nastavení
    local settingsTab = Instance.new("ScrollingFrame")
    settingsTab.Name = "SettingsTab"
    settingsTab.Size = UDim2.new(1, 0, 1, 0)
    settingsTab.BackgroundTransparency = 1
    settingsTab.ScrollBarThickness = 5
    settingsTab.Visible = false
    settingsTab.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local settingsContainer = Instance.new("Frame")
    settingsContainer.Name = "SettingsContainer"
    settingsContainer.Size = UDim2.new(1, -20, 1, -10)
    settingsContainer.Position = UDim2.new(0, 10, 0, 5)
    settingsContainer.BackgroundTransparency = 1
    settingsContainer.Parent = settingsTab
    
    local settingsListLayout = Instance.new("UIListLayout")
    settingsListLayout.Name = "SettingsListLayout"
    settingsListLayout.Padding = UDim.new(0, 15)
    settingsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    settingsListLayout.Parent = settingsContainer
    
    -- Nastavení
    local settingsData = {
        {
            name = "Theme",
            label = "Téma",
            type = "dropdown",
            options = {"Dark", "Light"}
        },
        {
            name = "ToggleKey",
            label = "Klávesa pro otevření",
            type = "keybind",
            default = "F5"
        },
        {
            name = "AntiCheatLevel",
            label = "Úroveň Anti-Cheatu",
            type = "slider",
            min = 1,
            max = 3,
            default = 2
        },
        {
            name = "AutoBanOnCheat",
            label = "Auto-ban při cheatování",
            type = "toggle",
            default = true
        },
        {
            name = "DiscordIntegration",
            label = "Propojení s Discordem",
            type = "button",
            action = function()
                -- Otevření odkazu na Discord
                if game:GetService("UserInputService"):GetPlatform() == Enum.Platform.Windows then
                    game:GetService("StarterGui"):SetCore("OpenBrowserWindow", {
                        URL = "https://discord.gg/bgEhJhVWBb"
                    })
                end
            end
        }
    }
    
    for i, setting in ipairs(settingsData) do
        local settingFrame = Instance.new("Frame")
        settingFrame.Name = setting.name
        settingFrame.Size = UDim2.new(1, 0, 0, 50)
        settingFrame.BackgroundTransparency = 1
        settingFrame.LayoutOrder = i
        settingFrame.Parent = settingsContainer
        
        local settingLabel = Instance.new("TextLabel")
        settingLabel.Name = "Label"
        settingLabel.Size = UDim2.new(0.5, 0, 1, 0)
        settingLabel.BackgroundTransparency = 1
        settingLabel.Text = setting.label .. ":"
        settingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        settingLabel.Font = Enum.Font.GothamBold
        settingLabel.TextSize = 14
        settingLabel.TextXAlignment = Enum.TextXAlignment.Left
        settingLabel.Parent = settingFrame
        
        if setting.type == "dropdown" then
            local dropdown = Instance.new("TextButton")
            dropdown.Name = "Dropdown"
            dropdown.Size = UDim2.new(0.4, 0, 0.7, 0)
            dropdown.Position = UDim2.new(0.55, 0, 0.15, 0)
            dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            dropdown.Text = setting.default or setting.options[1]
            dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
            dropdown.Font = Enum.Font.Gotham
            dropdown.TextSize = 14
            dropdown.Parent = settingFrame
            
            -- TODO: Implementovat dropdown menu
            
        elseif setting.type == "toggle" then
            local toggle = Instance.new("TextButton")
            toggle.Name = "Toggle"
            toggle.Size = UDim2.new(0.15, 0, 0.7, 0)
            toggle.Position = UDim2.new(0.55, 0, 0.15, 0)
            toggle.BackgroundColor3 = setting.default and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(180, 80, 80)
            toggle.Text = setting.default and "ZAP" or "VYP"
            toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggle.Font = Enum.Font.GothamBold
            toggle.TextSize = 14
            toggle.Parent = settingFrame
            
            toggle.MouseButton1Click:Connect(function()
                local newState = toggle.Text == "VYP"
                toggle.Text = newState and "ZAP" or "VYP"
                toggle.BackgroundColor3 = newState and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(180, 80, 80)
                
                -- Uložit nastavení
                game:GetService("ReplicatedStorage").UltraAdminSystem.UltraAdmin.Events.UpdateSetting:FireServer(
                    setting.name, newState
                )
            end)
            
        elseif setting.type == "slider" then
            local slider = Instance.new("Frame")
            slider.Name = "Slider"
            slider.Size = UDim2.new(0.4, 0, 0.4, 0)
            slider.Position = UDim2.new(0.55, 0, 0.3, 0)
            slider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            slider.BorderSizePixel = 0
            slider.Parent = settingFrame
            
            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.Size = UDim2.new(0.5, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
            fill.BorderSizePixel = 0
            fill.Parent = slider
            
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Name = "Value"
            valueLabel.Text = tostring(setting.default or setting.min)
            valueLabel.Size = UDim2.new(0.1, 0, 1, 0)
            valueLabel.Position = UDim2.new(1.05, 0, 0, 0)
            valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            valueLabel.Font = Enum.Font.Gotham
            valueLabel.TextSize = 14
            valueLabel.BackgroundTransparency = 1
            valueLabel.Parent = slider
            
            -- TODO: Implementovat funkčnost slideru
            
        elseif setting.type == "button" then
            local button = Instance.new("TextButton")
            button.Name = "ActionButton"
            button.Size = UDim2.new(0.4, 0, 0.7, 0)
            button.Position = UDim2.new(0.55, 0, 0.15, 0)
            button.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
            button.Text = "Otevřít"
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.Font = Enum.Font.GothamBold
            button.TextSize = 14
            button.Parent = settingFrame
            
            button.MouseButton1Click:Connect(setting.action)
        end
    end
    
    settingsTab.Parent = tabContent
    
    tabContent.Parent = mainFrame
    mainFrame.Parent = adminGUI
    adminGUI.Parent = adminUI
    
    -- ##RemoteEventy pro komunikaci
    local commandEvent = Instance.new("RemoteEvent")
    commandEvent.Name = "AdminCommand"
    commandEvent.Parent = adminEvents
    
    local playerLogEvent = Instance.new("RemoteEvent")
    playerLogEvent.Name = "PlayerLog"
    playerLogEvent.Parent = adminEvents
    
    local getLogsEvent = Instance.new("RemoteEvent")
    getLogsEvent.Name = "GetLogs"
    getLogsEvent.Parent = adminEvents
    
    local updateLogsEvent = Instance.new("RemoteEvent")
    updateLogsEvent.Name = "UpdateLogs"
    updateLogsEvent.Parent = adminEvents
    
    local updateSettingEvent = Instance.new("RemoteEvent")
    updateSettingEvent.Name = "UpdateSetting"
    updateSettingEvent.Parent = adminEvents
    
    -- ##Moduly pro správu systému
    -- Modul pro logování
    local loggerModule = Instance.new("ModuleScript")
    loggerModule.Name = "Logger"
    loggerModule.Source = [[
        -- ##Modul pro logování akcí
        
        local Logger = {}
        local logs = {}
        local maxLogs = 1000
        
        function Logger.init()
            -- Inicializace loggeru
            logs = {}
        end
        
        function Logger.logAction(playerName, action, details)
            -- Přidání záznamu do logu
            table.insert(logs, 1, {
                time = os.time(),
                type = "ACTION",
                message = playerName .. " použil: " .. action,
                details = details
            })
            
            -- Omezení velikosti logu
            while #logs > maxLogs do
                table.remove(logs)
            end
        end
        
        function Logger.logPlayer(playerName, event, details)
            table.insert(logs, 1, {
                time = os.time(),
                type = "PLAYER",
                message = playerName .. " " .. event,
                details = details
            })
            
            while #logs > maxLogs do
                table.remove(logs)
            end
        end
        
        function Logger.logSuspicious(playerName, reason, data)
            table.insert(logs, 1, {
                time = os.time(),
                type = "WARNING",
                message = "PODEZŘELÉ CHOVÁNÍ: " .. playerName .. " - " .. reason,
                details = data
            })
            
            while #logs > maxLogs do
                table.remove(logs)
            end
        end
        
        function Logger.logError(message)
            table.insert(logs, 1, {
                time = os.time(),
                type = "ERROR",
                message = "CHYBA: " .. message,
                details = {}
            })
            
            while #logs > maxLogs do
                table.remove(logs)
            end
        end
        
        function Logger.logWarning(message)
            table.insert(logs, 1, {
                time = os.time(),
                type = "WARNING",
                message = "VAROVÁNÍ: " .. message,
                details = {}
            })
            
            while #logs > maxLogs do
                table.remove(logs)
            end
        end
        
        function Logger.getLogs(count)
            -- Vrací posledních 'count' záznamů
            local result = {}
            for i = 1, math.min(count or 50, #logs) do
                table.insert(result, logs[i])
            end
            return result
        end
        
        function Logger.exportLogs()
            -- Export logů do formátu vhodného pro konzoli
            local export = {}
            for i, log in ipairs(logs) do
                table.insert(export, string.format("[%s] %s: %s", 
                    os.date("%Y-%m-%d %H:%M:%S", log.time), 
                    log.type, 
                    log.message))
            end
            return table.concat(export, "\n")
        end
        
        return Logger
    ]]
    loggerModule.Parent = adminModules
    
    -- Modul pro oprávnění
    local permissionsModule = Instance.new("ModuleScript")
    permissionsModule.Name = "Permissions"
    permissionsModule.Source = [[
        -- ##Modul pro správu oprávnění
        
        local Permissions = {}
        local admins = {}
        local bans = {}
        
        -- Jednoduchá "šifrace" pro UserId
        local function obfuscateId(id)
            return tostring(id * 2 + 12345)
        end
        
        local function deobfuscateId(obfId)
            return (tonumber(obfId) - 12345) / 2
        end
        
        function Permissions.loadAdmins()
            -- Načte seznam adminů (v produkci by se načítalo z databáze)
            -- Toto je ukázkový seznam - v reálném nasazení by byl šifrovaný
            
            -- Příklad adminů: [UserId] = "Role"
            local defaultAdmins = {
                [obfuscateId(123456)] = "Owner",  -- UserId admina
                [obfuscateId(654321)] = "Admin",
                [obfuscateId(789012)] = "Moderator"
            }
            
            -- TODO: Načíst z uložených dat
            admins = defaultAdmins
        end
        
        function Permissions.saveAdmins()
            -- Uloží seznam adminů
            -- TODO: Implementovat ukládání
        end
        
        function Permissions.isAdmin(player)
            -- Kontrola, zda je hráč admin
            return admins[obfuscateId(player.UserId)] ~= nil
        end
        
        function Permissions.getAdminLevel(player)
            -- Vrací úroveň admina
            return admins[obfuscateId(player.UserId)] or "None"
        end
        
        function Permissions.hasPermission(level, required)
            -- Kontrola oprávnění
            local levels = {Owner = 3, Admin = 2, Moderator = 1}
            return levels[level] >= levels[required]
        end
        
        function Permissions.addAdmin(userId, level)
            -- Přidá nového admina
            admins[obfuscateId(userId)] = level
        end
        
        function Permissions.removeAdmin(userId)
            -- Odebere admina
            admins[obfuscateId(userId)] = nil
        end
        
        function Permissions.addBan(userId, reason, adminId)
            -- Přidá ban
            bans[obfuscateId(userId)] = {
                time = os.time(),
                reason = reason,
                admin = adminId
            }
        end
        
        function Permissions.isBanned(userId)
            -- Kontrola, zda je hráč zabanován
            return bans[obfuscateId(userId)] ~= nil
        end
        
        return Permissions
    ]]
    permissionsModule.Parent = adminModules
    
    -- Modul pro anti-cheat
    local antiCheatModule = Instance.new("ModuleScript")
    antiCheatModule.Name = "AntiCheat"
    antiCheatModule.Source = [[
        -- ##Modul pro detekci podvodů
        
        local AntiCheat = {}
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Settings = require(script.Parent.Config)
        
        local detectionSettings = {
            speedHack = true,
            teleportHack = true,
            propertyTampering = true,
            flyHack = true
        }
        
        local violators = {}
        local event = Instance.new("BindableEvent")
        AntiCheat.onViolation = event.Event
        
        local function getSensitivity()
            local level = Settings.getSetting("AntiCheatLevel") or 2
            return {
                speedThreshold = 50 + (level-1)*30,  -- 50, 80, 110
                teleportThreshold = 100 + (level-1)*50  -- 100, 150, 200
            }
        end
        
        function AntiCheat.startMonitoring()
            -- Spustí monitorování hráčů
            Players.PlayerAdded:Connect(function(player)
                monitorPlayer(player)
            end)
            
            -- Monitorování již připojených hráčů
            for _, player in ipairs(Players:GetPlayers()) do
                monitorPlayer(player)
            end
        end
        
        function monitorPlayer(player)
            -- Sleduje jednoho hráče
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoid = character:WaitForChild("Humanoid")
            local rootPart = character:WaitForChild("HumanoidRootPart")
            
            -- ##Detekce speed hacku
            if detectionSettings.speedHack then
                local lastPosition = rootPart.Position
                local lastTime = os.clock()
                
                RunService.Heartbeat:Connect(function()
                    if not character or not rootPart then return end
                    
                    local currentPosition = rootPart.Position
                    local currentTime = os.clock()
                    
                    local distance = (currentPosition - lastPosition).Magnitude
                    local timeDiff = currentTime - lastTime
                    
                    local speed = distance / timeDiff
                    local maxSpeed = getSensitivity().speedThreshold
                    
                    -- Ignorovat padání
                    if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                        maxSpeed = maxSpeed * 2
                    end
                    
                    -- Maximální povolená rychlost
                    if speed > maxSpeed and humanoid.MoveDirection.Magnitude > 0 then
                        reportViolation(player, "Speed hack (" .. math.floor(speed) .. " studs/s)", {
                            speed = speed,
                            position = currentPosition
                        })
                    end
                    
                    lastPosition = currentPosition
                    lastTime = currentTime
                end)
            end
            
            -- ##Detekce teleport hacku
            if detectionSettings.teleportHack then
                local lastPosition = rootPart.Position
                
                RunService.Heartbeat:Connect(function()
                    if not character or not rootPart then return end
                    
                    local currentPosition = rootPart.Position
                    local distance = (currentPosition - lastPosition).Magnitude
                    local maxDistance = getSensitivity().teleportThreshold
                    
                    if distance > maxDistance then
                        reportViolation(player, "Teleport hack (" .. math.floor(distance) .. " studs)", {
                            distance = distance,
                            from = lastPosition,
                            to = currentPosition
                        })
                    end
                    
                    lastPosition = currentPosition
                end)
            end
            
            -- ##Detekce fly hacku
            if detectionSettings.flyHack then
                local lastY = rootPart.Position.Y
                local lastTime = os.clock()
                
                RunService.Heartbeat:Connect(function()
                    if not character or not rootPart then return end
                    
                    local currentY = rootPart.Position.Y
                    local currentTime = os.clock()
                    
                    local verticalSpeed = math.abs(currentY - lastY) / (currentTime - lastTime)
                    
                    -- Povolená vertikální rychlost (skoky/padání)
                    if verticalSpeed > 100 and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                        reportViolation(player, "Fly hack (" .. math.floor(verticalSpeed) .. " studs/s)", {
                            speed = verticalSpeed,
                            position = rootPart.Position
                        })
                    end
                    
                    lastY = currentY
                    lastTime = currentTime
                end)
            end
        end
        
        function reportViolation(player, reason, data)
            -- Nahlásí porušení pravidel
            if not violators[player.UserId] then
                violators[player.UserId] = {
                    count = 0,
                    lastReport = 0
                }
            end
            
            -- Omezit frekvenci reportů
            if os.time() - violators[player.UserId].lastReport < 10 then
                return
            end
            
            violators[player.UserId].count = violators[player.UserId].count + 1
            violators[player.UserId].lastReport = os.time()
            
            -- Vyvolat událost
            event:Fire(player, reason, data)
        end
        
        return AntiCheat
    ]]
    antiCheatModule.Parent = adminModules
    
    -- Modul pro konfiguraci
    local configModule = Instance.new("ModuleScript")
    configModule.Name = "Config"
    configModule.Source = [[
        -- ##Modul pro konfiguraci
        
        local Config = {}
        local settings = {
            Theme = "Dark",
            ToggleKey = "F5",
            AntiCheatLevel = 2,
            AutoBanOnCheat = true
        }
        
        local commandData = {
            Kick = {minLevel = "Moderator"},
            Ban = {minLevel = "Admin"},
            TeleportToPlayer = {minLevel = "Moderator"},
            FreezePlayer = {minLevel = "Moderator"},
            SetWeather = {minLevel = "Admin"},
            ToggleDayNight = {minLevel = "Admin"},
            ResetServer = {minLevel = "Admin"}
        }
        
        function Config.loadSettings()
            -- Načte uložená nastavení
            -- TODO: Načíst z uložených dat
        end
        
        function Config.saveSettings()
            -- Uloží nastavení
            -- TODO: Implementovat ukládání
        end
        
        function Config.getSetting(name)
            return settings[name]
        end
        
        function Config.updateSetting(name, value)
            settings[name] = value
        end
        
        function Config.getCommandData(command)
            return commandData[command]
        end
        
        return Config
    ]]
    configModule.Parent = adminModules
    
    -- Modul pro utility funkce
    local utilsModule = Instance.new("ModuleScript")
    utilsModule.Name = "Utils"
    utilsModule.Source = [[
        -- ##Modul s pomocnými funkcemi
        
        local Utils = {}
        
        function Utils.createTween(object, properties, duration, style)
            local tweenService = game:GetService("TweenService")
            local tweenInfo = TweenInfo.new(
                duration or 0.3,
                style or Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )
            local tween = tweenService:Create(object, tweenInfo, properties)
            tween:Play()
            return tween
        end
        
        function Utils.deepCopy(original)
            local copy = {}
            for k, v in pairs(original) do
                if type(v) == "table" then
                    v = Utils.deepCopy(v)
                end
                copy[k] = v
            end
            return copy
        end
        
        return Utils
    ]]
    utilsModule.Parent = adminModules
    
    -- ##Uspořádání hierarchie
    adminMainFolder.Parent = serverStorage.UltraAdminSystem
    adminUI.Parent = adminMainFolder
    
    -- Výběr nově vytvořených objektů ve Studiu
    selection:Set({adminFolder})
    
    return adminFolder
end

-- ##UI pro plugin v Roblox Studio
local toolbar = plugin:CreateToolbar("Ultra Admin")
local button = toolbar:CreateButton("Ultra Admin", "Vytvoří admin panel", "rbxassetid://4458901886")

button.Click:Connect(function()
    createAdminSystem()
    plugin:OpenScript(game:GetService("ServerScriptService").AdminServer)
end)

-- ##Kontextové menu
local menu = plugin:CreatePluginMenu("UltraAdminMenu", "Ultra Admin")
menu:AddNewAction("CreateSystem", "Vytvořit systém", "Vytvoří administrační systém").Triggered:Connect(createAdminSystem)
menu:AddNewAction("OpenDocs", "Otevřít dokumentaci", "Otevře dokumentaci systému").Triggered:Connect(function()
    plugin:OpenScript(script)
end)

-- ##Zpráva po instalaci
print([[
------------------------------------------------------
✅ Ultra Admin Panel v7.0 byl úspěšně nainstalován!
 
 • Systém byl vytvořen v ServerStorage
 • Hlavní serverový skript: ServerScriptService > AdminServer
 • GUI bylo přidáno do StarterGui
 
 Pro otevření panelu ve hře:
   • Stiskněte F5
   • Nebo napište "/admin" do chatu
 
 Dokumentace: 
   https://github.com/yourusername/ultra-admin
 
 Discord podpora:
   https://discord.gg/bgEhJhVWBb
------------------------------------------------------
]])

-- ##Automatické vytvoření systému při načtení
createAdminSystem()