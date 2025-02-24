
local NetworkVisualizer = {
    ActiveCalls = {},
    NetworkStats = {
        TotalBytes = 0,
        CallsPerSecond = 0,
        PeakCallRate = 0
    }
}

function NetworkVisualizer:Init()
    self.StartTime = os.time()
    self.CallHistory = {}
    self:StartMetricsCollection()
end

function NetworkVisualizer:TrackCall(remote, args, callTime)
    local callSize = self:EstimateCallSize(args)
    
    table.insert(self.CallHistory, {
        Time = callTime,
        Size = callSize,
        Remote = remote.Name
    })
    
    self.NetworkStats.TotalBytes = self.NetworkStats.TotalBytes + callSize
    self:UpdateMetrics()
end

function NetworkVisualizer:EstimateCallSize(args)
    local size = 0
    for _, arg in pairs(args) do
        local argType = typeof(arg)
        if argType == "string" then
            size = size + #arg
        elseif argType == "number" then
            size = size + 8
        elseif argType == "table" then
            size = size + self:EstimateCallSize(arg)
        end
    end
    return size
end

function NetworkVisualizer:UpdateMetrics()
    local currentTime = os.time()
    local recentCalls = 0
    
    for i = #self.CallHistory, 1, -1 do
        if currentTime - self.CallHistory[i].Time <= 1 then
            recentCalls = recentCalls + 1
        else
            break
        end
    end
    
    self.NetworkStats.CallsPerSecond = recentCalls
    self.NetworkStats.PeakCallRate = math.max(self.NetworkStats.PeakCallRate, recentCalls)
end

function NetworkVisualizer:StartMetricsCollection()
    task.spawn(function()
        while true do
            self:CleanupOldCalls()
            task.wait(1)
        end
    end)
end

function NetworkVisualizer:CleanupOldCalls()
    local currentTime = os.time()
    local cutoffTime = currentTime - 60
    
    while #self.CallHistory > 0 and self.CallHistory[1].Time < cutoffTime do
        table.remove(self.CallHistory, 1)
    end
end

function NetworkVisualizer:GetStats()
    return {
        TotalBytes = self.NetworkStats.TotalBytes,
        CallsPerSecond = self.NetworkStats.CallsPerSecond,
        PeakCallRate = self.NetworkStats.PeakCallRate,
        UptimeSeconds = os.time() - self.StartTime
    }
end

return NetworkVisualizer
