--[[
    AdvancedSpy
    A mobile-friendly enhanced remote spy for Roblox games.
    Author: Assistant
    Version: 1.0.0
]]
local AdvancedSpy = {
    Version = "1.0.0",
    Enabled = false,
    Connections = {},
    RemoteLog = {},
    BlockedRemotes = {},
    ExcludedRemotes = {},
    Settings = {
        Theme = "dark",
        MaxLogs = 1000,
        AutoBlock = false,
        LogReturnValues = true,
        Debug = true
    }
}

-- Debug logging function
local function debugLog(module, message)
    if AdvancedSpy.Settings.Debug then
        print(string.format("[AdvancedSpy Debug] [%s] %s", module, message))
    end
end

-- Define the base URL for the raw GitHub files
local baseUrl = "https://raw.githubusercontent.com/EvyOksi/AdvancedSpyV3/main/modules/"

-- Define the raw URLs for each module
local urlNetworkVisualizer = baseUrl .. "NetworkVisualizer.lua"
local urlRemoteInterceptor = baseUrl .. "RemoteInterceptor.lua"
local urlScriptGenerator = baseUrl .. "ScriptGenerator.lua"
local urlTheme = baseUrl .. "Theme.lua"
local urlTouchControls = baseUrl .. "TouchControls.lua"
local urlUIComponents = baseUrl .. "UIComponents.lua"

-- Fetch the raw content for each module
local networkVisualizerContent = game:HttpGet(urlNetworkVisualizer)
local remoteInterceptorContent = game:HttpGet(urlRemoteInterceptor)
local scriptGeneratorContent = game:HttpGet(urlScriptGenerator)
local themeContent = game:HttpGet(urlTheme)
local touchControlsContent = game:HttpGet(urlTouchControls)
local uiComponentsContent = game:HttpGet(urlUIComponents)

-- Load and execute the content using loadstring (with pcall for error handling)
local success1, errorMessage1 = pcall(loadstring(networkVisualizerContent))
local success2, errorMessage2 = pcall(loadstring(remoteInterceptorContent))
local success3, errorMessage3 = pcall(loadstring(scriptGeneratorContent))
local success4, errorMessage4 = pcall(loadstring(themeContent))
local success5, errorMessage5 = pcall(loadstring(touchControlsContent))
local success6, errorMessage6 = pcall(loadstring(uiComponentsContent))

-- Check for any errors and handle them
if not success1 then
    warn("Error executing NetworkVisualizer.lua: " .. errorMessage1)
end
if not success2 then
    warn("Error executing RemoteInterceptor.lua: " .. errorMessage2)
end
if not success3 then
    warn("Error executing ScriptGenerator.lua: " .. errorMessage3)
end
if not success4 then
    warn("Error executing Theme.lua: " .. errorMessage4)
end
if not success5 then
    warn("Error executing TouchControls.lua: " .. errorMessage5)
end
if not success6 then
    warn("Error executing UIComponents.lua: " .. errorMessage6)
end

-- Core UI Elements
local GUI = {
    Main = nil,
    LogList = nil,
    SearchBar = nil,
    SettingsPanel = nil,
    RemotePanel = nil  -- Remote management panel
}

function AdvancedSpy:Init()
    if not game then
        warn("AdvancedSpy must be run within Roblox!")
        return
    end
    
    -- Advanced initialization with performance monitoring
    self.Performance = {
        StartTime = tick(),
        CallCount = 0,
        MemoryUsage = 0,
        NetworkStats = {}
    }
    
    -- Setup crash recovery
    self:SetupErrorHandler()
    
    -- Initialize network monitoring
    self:InitNetworkMonitor()
    
    -- Setup advanced remote filtering
    self.FilterEngine = {
        Patterns = {},
        Blacklist = {},
        CustomRules = {}
    }
    
    -- Mobile optimization settings
    self.MobileConfig = {
        LowPowerMode = false,
        GestureThreshold = 20,
        RenderDistance = 1000,
        MaxCallsPerFrame = 60
    }

    debugLog("Init", "Initializing AdvancedSpy v" .. self.Version)

    -- Create main UI components
    GUI.Main = UIComponents.CreateMainWindow()
    GUI.LogList = UIComponents.CreateLogList()
    GUI.SearchBar = UIComponents.CreateSearchBar()
    GUI.SettingsPanel = UIComponents.CreateSettingsPanel()
    GUI.RemotePanel = UIComponents.CreateRemoteManagementPanel()
    GUI.RemotePanel.Parent = GUI.Main.MainFrame.ContentFrame

    -- Initialize touch controls for mobile
    debugLog("TouchControls", "Initializing touch controls...")
    TouchControls:Init(GUI.Main)

    -- Setup remote interceptors
    debugLog("RemoteInterceptor", "Setting up remote interceptors...")
    RemoteInterceptor:Init(function(remote, args, returnValue, stats)
        self:HandleRemoteCall(remote, args, returnValue, stats)
    end)

    -- Apply initial theme
    debugLog("Theme", "Applying initial theme: " .. self.Settings.Theme)
    Theme:Apply(self.Settings.Theme)

    -- Setup search functionality
    GUI.SearchBar.Changed:Connect(function(text)
        self:FilterLogs(text)
    end)

    -- Setup periodic remote list updates
    self:UpdateRemoteList()
    task.spawn(function()
        while self.Enabled do
            task.wait(5)  -- Update every 5 seconds
            if self.Enabled then  -- Check again to prevent update after destruction
                self:UpdateRemoteList()
            end
        end
    end)

    self.Enabled = true
    debugLog("Init", "AdvancedSpy initialized successfully")
end

function AdvancedSpy:HandleRemoteCall(remote, args, returnValue, stats)
    if not self.Enabled then return end
    debugLog("RemoteCall", string.format("Handling remote call: %s", remote.Name))

    if self:IsExcluded(remote) then 
        debugLog("RemoteCall", "Remote is excluded, ignoring...")
        return 
    end

    if self:IsBlocked(remote) then 
        debugLog("RemoteCall", "Remote is blocked, ignoring...")
        return 
    end

    local logEntry = {
        Remote = remote,
        Args = args,
        ReturnValue = returnValue,
        Timestamp = os.time(),
        Stack = debug.traceback(),
        Id = #self.RemoteLog + 1,
        NetworkStats = stats  -- Detailed network statistics from interception
    }

    table.insert(self.RemoteLog, 1, logEntry)
    debugLog("RemoteCall", string.format("Added log entry #%d", logEntry.Id))
    self:TrimLogs()
    self:UpdateLogDisplay(logEntry)
end

function AdvancedSpy:FilterLogs(searchText)
    if not searchText then return end
    searchText = searchText:lower()
    for _, entry in ipairs(self.RemoteLog) do
        local visible = entry.Remote.Name:lower():find(searchText) ~= nil
        local logElement = GUI.LogList:FindFirstChild("Log_" .. entry.Id)
        if logElement then
            logElement.Visible = visible
        end
    end
end

function AdvancedSpy:UpdateLogDisplay(logEntry)
    if not self.Enabled or not logEntry then return end
    debugLog("UI", string.format("Updating display for log entry #%d", logEntry.Id))
    UIComponents.AddLogEntry(GUI.LogList, logEntry)
end

function AdvancedSpy:TrimLogs()
    while #self.RemoteLog > self.Settings.MaxLogs do
        table.remove(self.RemoteLog)
    end
    debugLog("Logs", string.format("Trimmed logs to %d entries", #self.RemoteLog))
end

-- API Functions
function AdvancedSpy:BlockRemote(remote)
    if not remote then return end
    debugLog("API", string.format("Blocking remote: %s", remote.Name))
    self.BlockedRemotes[remote] = true
    RemoteInterceptor:BlockRemote(remote)
end

function AdvancedSpy:UnblockRemote(remote)
    if not remote then return end
    debugLog("API", string.format("Unblocking remote: %s", remote.Name))
    self.BlockedRemotes[remote] = nil
    RemoteInterceptor:UnblockRemote(remote)
end

function AdvancedSpy:ExcludeRemote(remote)
    if not remote then return end
    debugLog("API", string.format("Excluding remote: %s", remote.Name))
    self.ExcludedRemotes[remote] = true
end

function AdvancedSpy:IncludeRemote(remote)
    if not remote then return end
    debugLog("API", string.format("Including remote: %s", remote.Name))
    self.ExcludedRemotes[remote] = nil
end

function AdvancedSpy:GetRemoteFiredSignal(remote)
    if not remote then return end
    debugLog("API", string.format("Creating signal for remote: %s", remote.Name))
    return RemoteInterceptor:CreateSignal(remote)
end

function AdvancedSpy:UpdateRemoteList()
    if not self.Enabled then return end
    local remotes = RemoteInterceptor:GetAllRemotes()
    GUI.RemotePanel:UpdateRemotes(remotes)
    debugLog("RemoteList", string.format("Updated remote list (%d remotes)", #remotes))
end

function AdvancedSpy:IsBlocked(remote)
    return remote and self.BlockedRemotes[remote] ~= nil
end

function AdvancedSpy:IsExcluded(remote)
    return remote and self.ExcludedRemotes[remote] ~= nil
end

function AdvancedSpy:Destroy()
    debugLog("Cleanup", "Destroying AdvancedSpy...")
    self.Enabled = false
    for _, connection in pairs(self.Connections) do
        if typeof(connection) == "RBXScriptConnection" and connection.Connected then
            connection:Disconnect()
        end
    end
    if GUI.Main and typeof(GUI.Main) == "Instance" then
        GUI.Main:Destroy()
    end
    table.clear(self.RemoteLog)
    table.clear(self.BlockedRemotes)
    table.clear(self.ExcludedRemotes)
    debugLog("Cleanup", "AdvancedSpy destroyed successfully")
end

-- Return the module initialization function
return function()
    AdvancedSpy:Init()
    return AdvancedSpy
end
