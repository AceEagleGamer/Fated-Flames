--- References ---
local rep = game:GetService("ReplicatedStorage")
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local playerService = game:GetService("Players")
local localPlayer = playerService.LocalPlayer
local events = rep.Events

--- Public Variables ---
local Core = {}

Core.context = nil
Core.connections = {}
Core.animBlacklist = {}
Core.playerCons = {}
Core.playerThreads = {}

Core.animCons = {}
Core.characterAnims = {}
Core.playerState = {
    followingCamDir = false,
    statuses = {},

    originalWalkspeed = 16, -- just set it to this for now
    originalJumpPower = 50,

    remote = nil,
    Changed = nil
}
Core.queuedHits = {}

Core.debug = false

--- Private Functions ---

--- Public Functions ---

function Core:Init(context)
    self.context = context

    -- build player state table
    self.playerState.remote = Instance.new("BindableEvent")
    self.playerState.Changed = self.playerState.remote.Event

    -- LOcAL PLAYHER
    self.playerCons[localPlayer.UserId] = {}

    -- run stuff ourselves
    localPlayer.CharacterAdded:Connect(function(char)

        -- do cam stuff here
        local cam = workspace.CurrentCamera
        cam.CameraSubject = char:WaitForChild("Head")

        -- break previous thread then make a new one
        if self.playerThreads.shiftlockFix then
            self.playerThreads.shiftlockFix:Disconnect()
        end

        local hum = char:WaitForChild("Humanoid")
        self.playerThreads.shiftlockFix = run.RenderStepped:Connect(function()
            if not char or not hum then
                return
            end
            
            if uis.MouseBehavior == Enum.MouseBehavior.LockCenter or self.playerState.followingCamDir then
                hum.AutoRotate = false --We set the Humanoid's AutoRotate to true if we aren't in shift lock mode.
                local _X, Y, _Z = cam.CFrame:ToOrientation()
                char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position) * CFrame.fromOrientation(0, Y, 0)
            else
                hum.AutoRotate = true
            end

        end)
    end)
end

function Core:Start()

    -- hit replication
    --[[events.ReplicateHit.OnClientEvent:Connect(function(player, hitTable, hitProperties)
        if player == localPlayer.Name then return end
        self:PlayHit(workspace.PlayerCharacters:FindFirstChild(player), hitTable, hitProperties)

        -- do some stun stuff here
    end)]]

    -- client prediction
    --self.playerCons[localPlayer.UserId].serverPrediction = run.Heartbeat:Connect(predictServerCFrame) -- should this be here?
end

return Core