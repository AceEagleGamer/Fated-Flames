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
Core.threads = {}
Core.playerState = {
    followingCamDir = false,
    statuses = {},
}

--- Private Functions ---

--- Public Functions ---

function Core:Init(context)
    self.context = context

    -- run stuff ourselves
    self.connections.characterAdded = localPlayer.CharacterAdded:Connect(function(char)

        -- do cam stuff here
        local cam = workspace.CurrentCamera
        cam.CameraSubject = char:WaitForChild("Head")

        -- break previous thread then make a new one
        if self.threads.shiftlockFix then
            self.threads.shiftlockFix:Disconnect()
        end

        local hum = char:WaitForChild("Humanoid")
        self.threads.shiftlockFix = run.RenderStepped:Connect(function()
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
    
end

return Core