--- Private Variables ---
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events

--- Public Variables ---
local InputService = {}
InputService.context = nil

InputService.connections = {}
InputService.threads = {}

--- Private Functions ---
local function EvaluateRequest(player, moveFolder: string, moveName: string)

    -- sanity checks
    --[[if not moves:FindFirstChild(moveFolder) then return false end
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

    -- update lastmove and lastmovetick
    playerTable.lastMove = moveData
    playerTable.lastMoveTick = time()

    -- replication here
    events.ReplicateMove:FireAllClients(player, moveFolder, moveName, variant, moveTick)
    
    return true]]
end


--- Public Functions ---
function InputService:Init(context)
    self.context = context
    local PlayerService = context.services.playerservice

    self.connections.updateInput = events.UpdateInputToggle.OnServerEvent:Connect(function(player, inputTable)
        
        -- get player info
        local player_info = PlayerService.players[player.UserId]
        if player_info == nil then return end
        if player_info.initialized ~= true then return end

        -- update info
        player_info.inputStates = inputTable
    end)
end

function InputService:Start()

    local services = self.context.services
    local PlayerService = services.playerservice
    local TickService = services.tickservice

    self.connections.playerJoined = PlayerService.events.playerJoining:Connect(function(player)
        
        -- hook input loop to tickservice to handle m1 and blocking, probably some other stuff but later i guess
        local player_info = PlayerService.players[player.UserId]
        local m1 = player_info.moveModules.MouseButton1

        player_info.connections.updateLoop = TickService.Update:Connect(function(dt)

            -- sanity checks
            if player_info.character_model == nil then return end
            if not player_info.animationsLoaded then return end
            
            -- m1 loop
            if player_info.inputStates.m1 and (not player_info.playerStates.busy) and (not player_info.playerStates.endlag) then
                m1:Work()
            end

            -- blocking
            if player_info.inputStates.blocking and (not player_info.playerStates.busy) and (not player_info.animations.block.IsPlaying) and (time() - player_info.timestamps.lastBlockTick >= 0.5) then
                player_info.playerStates.busy = true
                player_info.animations.block:Play()
                player_info.character_model:SetAttribute("Blocking", true)

            elseif not player_info.inputStates.blocking and player_info.animations.block.IsPlaying then
                player_info.timestamps.lastBlockTick = time() -- record timestamp of new block
                player_info.playerStates.busy = false
                player_info.animations.block:Stop()
                player_info.character_model:SetAttribute("Blocking", false)
            end
        end)
    end)
end

return InputService