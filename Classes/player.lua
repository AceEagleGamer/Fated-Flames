--- Initializer
local Player = {}
Player.__index = Player

local analytics = true

--- Constructor ---
function Player.new(playerObj)
    local newPlayer = {}
    setmetatable(newPlayer, Player)

    -- physical objects
    newPlayer.player_object = playerObj
    newPlayer.character_model = nil

    -- tables
    newPlayer.connections = {} -- assume these are all disconnectable with :Disconnect()
    newPlayer.threads = {} -- assume these are all cancelable with task.cancel()
    newPlayer.moveModules = {} -- assume these are all classes that we can call :Destroy() on

    newPlayer.playerStates = {
        m1 = false,
        blocking = false,
    }
    newPlayer.playerCDs = {
        lastMove = "nil",
        lastBlockTick = 0,
        lastMoveTick = 0
    }

    return newPlayer
end

--- Deconstructor ---
function Player:Destroy()

    -- disconnect and cancel all connections/threads
    if analytics then
        print(`[Player] destroying {self.player_object.Name} player object`)
    end

    for moduleName, module in self.moveModules do
        print(`destroying {moduleName} module`)
        module:Destroy()
    end
    
    for conName, con in self.connections do
        print(`disconnecting {conName} connection`)
        con:Disconnect()
    end

    for threadName, thread in self.threads do
        print(`cancelling {threadName} thread`)
        task.cancel(thread)
    end

    table.clear(self.threads)
    table.clear(self.connections)
    table.clear(self.playerStates)
    table.clear(self.playerCDs)

    if analytics then
        print(`[Player] finished destroying {self.player_object.Name} player object`)
    end

    table.clear(self)
end

--- Class Functions ---

return Player