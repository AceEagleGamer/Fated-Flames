--- Public Variables ---
local MoveData = {}
MoveData.__index = MoveData

--- Private Functions
local function WorkClient(self)

end

--- Constructor ---
function MoveData.new(playerData, context)
    local newMoveData = {}
    setmetatable(newMoveData, MoveData)

    newMoveData.stateTable = {
        lastDashTick = 0,
        lastForwardDashTick = 0,
    }

    -- references and other important stuff
    newMoveData.playerData = playerData
    newMoveData.context = context
    newMoveData.IsClient = game:GetService("RunService"):IsClient()

    return MoveData
end

--- Public Functions ---
function MoveData:Work()

    if self.IsClient then
        WorkClient(self)

    else

        local player_info = self.playerData
        local services = self.context.services
        local DamageService = services.damageservice
        local TickService = services.tickservice
    end
    
            --[[-- prep linear velocity for dash
            local linearVel = char.HumanoidRootPart.Attachment.LinearVelocity
            linearVel.Enabled = true

            core.playerState.followingCamDir = true

            -- dash stuff
            local dashStrength = Instance.new("NumberValue")
            dashStrength.Value = 120

            local dashDecay = twn:Create(dashStrength, TweenInfo.new(self.properties.canMoveAgain, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = 10})
            dashDecay:Play()

            local dashUpdateLoop = QueueDash(dir, char, dashStrength, linearVel)

            -- play anim and rotate character accordingly
            self.animations[dir]:Play()
            self.sounds.dash:Play()

            task.delay(self.properties.canMoveAgain, function()
                task.cancel(dashUpdateLoop)
                core.playerState.followingCamDir = false
                linearVel.Enabled = false
                self.free = true
                input.canJump = true
            end)]]
end
return MoveData