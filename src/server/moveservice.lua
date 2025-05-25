-- don't know yet. this will be used for tracking cooldowns for each player

--- References ---
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events
local moves = rep.Moves

--- Public Variables ---
local MoveService = {}

MoveService.context = nil
MoveService.debug = false
MoveService.events = {}
MoveService.connections = {}
MoveService.playerCDs = {}

--- Private Functions ---
local function EvaluateRequest(player: Player, moveFolder: string, moveName: string)

    -- sanity checks
    if not moves:FindFirstChild(moveFolder) then return false end
    if not moves[moveFolder]:FindFirstChild(moveName) then return false end

    -- get player CDs
    local playerTable = MoveService.playerCDs[player.UserId]
    if not playerTable then warn(`[MoveService] {player.Name} does not have a CD table`); return false end

    -- catch for nil
    if not playerTable[`{moveFolder}{moveName}`] then playerTable[`{moveFolder}{moveName}`] = 0 end
    local playerMoveCD = playerTable[`{moveFolder}{moveName}`]

    -- get move module
    local moveData = require(moves[moveFolder]:FindFirstChild(moveName))
    local moveCD = moveData:GetCooldown() - 0.1 -- to make it more lenient i guess

    -- check CD timings
    if tick() - playerMoveCD < moveCD then warn(`[MoveService] {player.Name} requesting a move under cooldown`); return false end
    playerTable[`{moveFolder}{moveName}`] = tick()
    moveData:Tick()

    -- update lastmove and lastmovetick
    playerTable.lastMove = `{moveFolder}{moveName}`
    playerTable.lastMoveTick = tick()

    -- replication here
    events.Replicate:FireAllClients(player, moveFolder, moveName)
    
    return true
end

local function EvaluateHit(player: Player, hitTable: {[any]: any?}, rawMoveName)

    -- get move data
    local moveIdentifier = string.split(rawMoveName, '/')
    local moveFolder = moveIdentifier[1]
    local moveName = moveIdentifier[2]

    -- sanity check
    if not moves:FindFirstChild(moveFolder) then return end
    if not moves[moveFolder]:FindFirstChild(moveName) then return end

    -- TODO: security checks. just hit them here doesnt matter
    for _, hit in hitTable do

        hit:FindFirstChild("Humanoid"):TakeDamage(5)

    end
end

--- Public Functions ---
function MoveService:Init(context)
    self.context = context

    self.connections.hitRequest = events.Hit.OnServerEvent:Connect(EvaluateHit)
end

function MoveService:Start()

    local context = self.context
    local PlayerService = context.services.playerservice

    -- not sure if i can store this callback in a table. wtv
    events.RequestMove.OnServerInvoke = EvaluateRequest

    self.connections.playerLoaded = PlayerService.events.playerJoining:Connect(function(player: Player)
        
        -- wait for the player to load on the client first
        player:GetAttributeChangedSignal("ClientLoaded"):Wait()

        -- register records to player CDs
        self.playerCDs[player.UserId] = {
            lastMove = "nil",
            lastMoveTick = 0
        }
    end)

    self.connections.playerLeft = PlayerService.events.playerLeaving:Connect(function(player: Player)
        
        -- remove records from, player CDs
        if self.playerCDs[player.UserId] then
            table.clear(self.playerCDs[player.UserId]) -- assuming this actually clears the table? setting the table to nil doesnt do that
            self.playerCDs[player.UserId] = nil
        end
    end)
end

return MoveService