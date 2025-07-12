-- don't know yet. this will be used for tracking cooldowns for each player

--- References ---
local rep = game:GetService("ReplicatedStorage")
local playerService = game:GetService("Players")
local events = rep.Events
local moves = rep.Moves

--- Packages ---
--local hitbox = require(rep.Shared.hitbox)

--- Public Variables ---
local MoveService = {}

MoveService.context = nil
MoveService.debug = false

MoveService.events = {}
MoveService.connections = {}

--- Private Functions ---

-- idk if i'll use this
--[[local function _preventJumping(char, duration)

        -- disconnect previous thread
    local threadHolder = MoveService.charThreads[(playerService:GetPlayerFromCharacter(char) and playerService:GetPlayerFromCharacter(char).UserId) or char]
    if not threadHolder then return end

    if threadHolder.stopJumping then task.cancel(threadHolder.stopJumping) end

        -- sanity check
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end 

    char:SetAttribute("StopJumping", true)
    char.Humanoid.JumpPower = 0
    threadHolder.stopJumping = task.delay(duration, function()
        char:SetAttribute("StopJumping", false)
        char.Humanoid.JumpPower = 50
    end)
end]]

--local function EvaluateBlockingState(player, state: boolean)

    --[[-- sanity checks
    local playerState = MoveService.playerStates[player.UserId]
    local playerCDs = MoveService.playerCDs[player.UserId]

    if not playerState or not playerCDs then return false end
    if (state == true and tick() - playerCDs.lastBlockTick < 0.2) then return false end
    if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then return false end

    -- check if enough time has passed since the last move. Fun nesting
    if playerCDs.lastMove ~= "nil" and playerCDs.lastMove.properties.moveEndlag then
        if (tick() - playerCDs.lastMoveTick) < playerCDs.lastMove.properties.moveEndlag then return false end
    end

    -- prevent things from happening when stunned
    if player.Character:GetAttribute("Stunned") == true or player.Character:GetAttribute("IsRagdoll") == true then return end
    
    -- set blocking to true on the server side and update last block tick
    player.Character:SetAttribute("Blocking", state)
    playerCDs.lastBlockTick = tick()

    -- accept the block
    return true]]
--end

--- Public Functions ---
function MoveService:Init(context)
    self.context = context
end

function MoveService:Start()

end

return MoveService