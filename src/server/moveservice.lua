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
local function CheckCD(player: Player, moveFolder: string, moveName: string)

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
    print(`combo string: {moveData.comboString}, cooldown: {moveCD}`)
    
    return true
end

--- Public Functions ---
function MoveService:Init(context)
    self.context = context
end

function MoveService:Start()

    local context = self.context
    local PlayerService = context.services.playerservice

    -- not sure if i can store this callback in a table. wtv
    events.RequestMove.OnServerInvoke = CheckCD

    self.connections.playerLoaded = PlayerService.events.playerJoining:Connect(function(player: Player)
        
        -- wait for the player to load on the client first
        player:GetAttributeChangedSignal("ClientLoaded"):Wait()

        -- register records to player CDs
        self.playerCDs[player.UserId] = {}
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