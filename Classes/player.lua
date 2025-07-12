--- Private Variables ---
local rep = game:GetService("ReplicatedStorage")
local moves = rep.Moves

--- Initializer ---
local Player = {}
Player.__index = Player

local analytics = true -- debug purposes

--- Constructor ---
function Player.new(playerObj, context)
    local newPlayer = {}
    setmetatable(newPlayer, Player)

    -- references
    newPlayer.context = nil
    newPlayer.initialized = false
    newPlayer.animationsLoaded = false
    newPlayer.context = context

    -- physical objects
    newPlayer.player_object = playerObj
    newPlayer.character_model = nil

    -- tables
    newPlayer.connections = {} -- assume these are all disconnectable with :Disconnect()
    newPlayer.threads = {} -- assume these are all cancelable with task.cancel()
    newPlayer.moveModules = {} -- assume these are all classes that we can call :Destroy() on
    newPlayer.moveQueue = {} -- for interruptible moves
    newPlayer.animations = {}
    newPlayer.bindings = {} -- bind skills to keys

    newPlayer.inputStates = {
        m1 = false,
        blocking = false,
    }

    newPlayer.playerStates = {
        busy = false
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
    table.clear(self.inputStates)
    table.clear(self.playerCDs)

    if analytics then
        print(`[Player] finished destroying {self.player_object.Name} player object`)
    end

    table.clear(self)
end

--- Class Functions ---
function Player:Init(context)
    self.context = context
    self.initialized = true

    -- TODO: load bindings from data. right now its all placeholder stuff
    self.bindings.MouseButton1 = "fist"
    self.bindings.F = "fist"
    --self.bindings.Q = "fist"

    -- load move modules based on bindings
    for key, modName in self.bindings do

        -- catch for blocking
        if key == "F" then continue end

        local moveFolder = moves:FindFirstChild(key)
        if moveFolder == nil then warn(`{key} is not a valid move folder`); continue end

        local moveMod = moveFolder:FindFirstChild(modName)
        if moveMod == nil then warn(`{modName} is not a valid move module of {key}`); continue end

        -- require and store object in player move table
        local newMoveMod = require(moveMod).new(self, self.context)
        self.moveModules[key] = newMoveMod
    end

    -- do other stuff i guess idk
end

function Player:LoadAnimations()

    if self.character_model == nil then warn(`[Player] attempted to load animations when character model was nil`); return end
    local animator = self.character_model:WaitForChild("Humanoid").Animator

    -- load block anim
    local targetAnim = rep.BlockAnims:FindFirstChild(self.bindings.F)
    if targetAnim then
        self.animations.block = animator:LoadAnimation(targetAnim)
    end

    -- load m1 animations
    local targetAnimFolder = rep.MoveAnims.MouseButton1:FindFirstChild(self.bindings.MouseButton1)
    if targetAnimFolder then
        for _, anim in targetAnimFolder:GetChildren() do
            self.animations[anim.Name] = animator:LoadAnimation(anim)
        end
    end

    self.animationsLoaded = true
end

function Player:Reset()
    self.playerStates.busy = false
    self.animationsLoaded = false
    self.character_model = nil
    self.connections.playerDied:Disconnect()
end
return Player