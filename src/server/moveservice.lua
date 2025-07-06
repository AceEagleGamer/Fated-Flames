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
MoveService.playerCDs = {}
MoveService.playerUpdateConnections = {}

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

local function EvaluateBlockingState(player, state: boolean)

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
end

local function EvaluateM1State(player, state: boolean)

end

-- non m1 moves
local function EvaluateRequest(player, moveFolder: string, moveName: string, variant, moveTick: string)

    -- sanity checks
    if not moves:FindFirstChild(moveFolder) then return false end
    if not moves[moveFolder]:FindFirstChild(moveName) then return false end

    -- check if we're alive
    local playerChar = player.Character
    if playerChar == nil or playerChar:FindFirstChild("Humanoid") == nil or playerChar.Humanoid.Health <= 0 then return false end

    -- check if we're endlagged, stunned, or ragdolled
    if playerChar:GetAttribute("Stunned") == true or playerChar:GetAttribute("IsRagdoll") == true then return false end

    -- check if we're blocking
    if playerChar:GetAttribute("Blocking") == true then return false end

    -- get player CDs
    local playerTable = MoveService.playerCDs[player.UserId]
    if not playerTable then warn(`[MoveService] {player.Name} does not have a CD table`); return false end

    -- get move module
    local moveData = require(moves[moveFolder]:FindFirstChild(moveName))

    -- check if we have a valid variant
    local variantChosen = nil
    if moveData.properties.variants and moveData.properties.variants[variant] then variantChosen = moveData.properties.variants[variant] end

    -- check if enough time has passed since the last move. Fun nesting
    if playerTable.lastMove and playerTable.lastMove.moveEndlag then
        if (time() - playerTable.lastMoveTick) < playerTable.lastMove.moveEndlag then return false end
    end

    -- check if we have a valid CD table. basically a more complicated check for nil :/.
    local CDName = nil
    if not variantChosen then
        if not playerTable[`{moveFolder}{moveName}`] then
            playerTable[`{moveFolder}{moveName}`] = 0
        end
        CDName = `{moveFolder}{moveName}`
    else
        if not playerTable[`{moveFolder}{moveName}{variantChosen.name}`] then
            playerTable[`{moveFolder}{moveName}{variantChosen.name}`] = 0
        end
        CDName = `{moveFolder}{moveName}{variantChosen.name}`
    end

    local moveCD = moveData:GetCooldown(variant) - 0.1 -- to make it more lenient i guess
    
    -- check CD timings
    if time() - playerTable[CDName] < moveCD then warn(`[MoveService] {player.Name} requesting a move under cooldown`); return false end
    playerTable[`{moveFolder}{moveName}{variant}`] = time()
    moveData:Tick()

    -- update lastmove and lastmovetick
    playerTable.lastMove = moveData
    playerTable.lastMoveTick = time()

    -- replication here
    events.ReplicateMove:FireAllClients(player, moveFolder, moveName, variant, moveTick)
    
    return true
end

local function Update(player, dt)
    --print("test")
end

--- Public Functions ---
function MoveService:Init(context)
    self.context = context
end

function MoveService:Start()

    local context = self.context
    local PlayerService = context.services.playerservice
    local TickService = context.services.tickservice

    -- not sure if i can store this callback in a table. wtv
    events.RequestMove.OnServerInvoke = EvaluateRequest
    events.UpdateBlockingState.OnServerInvoke = EvaluateBlockingState
    events.UpdateM1State.OnServerInvoke = EvaluateM1State

    self.connections.playerLoaded = PlayerService.events.playerJoining:Connect(function(player: Player)
        
        -- wait for the player to load on the client first
        player:GetAttributeChangedSignal("ClientLoaded"):Wait()

        local playerClass = PlayerService.players[player.UserId]
        if playerClass == nil then player:Kick("Something went wrong with initializing the player"); warn(`[MoveService] failed to initialize {player} - no player class obj`); return end

        -- setup connection inside the player obj
        playerClass.connections.updateConnection = TickService.Update:Connect(function(dt)
            Update(player, dt)
        end)
    end)
end

return MoveService