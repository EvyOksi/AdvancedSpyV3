
local CONFIG = {
    DEBUG = true,
    MAX_ARGS_LENGTH = 1000,
    BLACKLIST_PATTERNS = {
        "^_",
        "Internal",
        "System"
    }
}

local RemoteInterceptor = {
    HookedRemotes = {},
    BlacklistedRemotes = {},
    Stats = {
        TotalCalls = 0,
        FailedCalls = 0,
        LastCall = 0
    }
}

function RemoteInterceptor:Init(callback)
    if not game then return end

    self.Callback = callback
    self:SetupErrorHandling()

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()

        if (method == "FireServer" or method == "InvokeServer") and 
           (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            
            local startTime = os.clock()
            local result = oldNamecall(self, unpack(args))
            local endTime = os.clock()

            if not RemoteInterceptor:IsBlacklisted(self) then
                task.spawn(function()
                    pcall(callback, self, args, result, {
                        ExecutionTime = endTime - startTime,
                        Timestamp = os.time(),
                        Type = self.ClassName,
                        Path = self:GetFullName()
                    })
                end)
            end

            return result
        end

        return oldNamecall(self, ...)
    end)

    self:MonitorGame()
    task.spawn(function()
        while true do
            self:CleanupStaleRemotes()
            task.wait(30)
        end
    end)
end

function RemoteInterceptor:SetupErrorHandling()
    self.ErrorHandler = function(err)
        warn("[RemoteInterceptor] Error:", err)
        self.Stats.FailedCalls = self.Stats.FailedCalls + 1
    end
end

function RemoteInterceptor:MonitorGame()
    game.DescendantAdded:Connect(function(desc)
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            self.HookedRemotes[desc] = true
        end
    end)
    
    game.DescendantRemoving:Connect(function(desc)
        self.HookedRemotes[desc] = nil
    end)
end

function RemoteInterceptor:CleanupStaleRemotes()
    for remote in pairs(self.HookedRemotes) do
        if not remote.Parent then
            self.HookedRemotes[remote] = nil
        end
    end
end

function RemoteInterceptor:BlockRemote(remote)
    if typeof(remote) == "Instance" then
        self.BlacklistedRemotes[remote] = true
        return true
    end
    return false
end

function RemoteInterceptor:UnblockRemote(remote)
    if typeof(remote) == "Instance" then
        self.BlacklistedRemotes[remote] = nil
        return true
    end
    return false
end

function RemoteInterceptor:IsBlacklisted(remote)
    return self.BlacklistedRemotes[remote] == true
end

function RemoteInterceptor:GetAllRemotes()
    local remotes = {}
    for remote in pairs(self.HookedRemotes) do
        if remote.Parent then
            table.insert(remotes, remote)
        end
    end
    return remotes
end

function RemoteInterceptor:GetStatistics()
    return {
        TotalCalls = self.Stats.TotalCalls,
        FailedCalls = self.Stats.FailedCalls,
        SuccessRate = self.Stats.TotalCalls > 0 
            and ((self.Stats.TotalCalls - self.Stats.FailedCalls) / self.Stats.TotalCalls * 100)
            or 100,
        LastCallTime = self.Stats.LastCall,
        ActiveRemotes = #self:GetAllRemotes()
    }
end

return RemoteInterceptor
