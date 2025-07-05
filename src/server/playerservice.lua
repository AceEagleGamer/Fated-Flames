-- will handle the registering of players and other stuff in the future probably

--- References ---
local players = game:GetService("Players")
local rep = game:GetService("ReplicatedStorage")
local ss = game:GetService("ServerStorage")

local events = rep.Events
local packages = rep.Packages
local classes = ss.Classes

-- classes
local PlayerClass = require(classes.player) -- ignore error idk why it thinks it doesnt exist
local ProfileStore = require(game:GetService("ReplicatedStorage").Packages.profilestore)

--- Public Variables ---
local PlayerService = {}

PlayerService.players = {}
PlayerService.connections = {}
PlayerService.events = {}
PlayerService.context = nil

--- Private Variables ---
local InternalEvents = {
    PlayerJoining = nil,
    PlayerLeaving = nil -- these are to shut up Luau errors lol
}

--- Private Functions ---
local function LoadPlayerData(player: Player)
    -- TODO: this please lol

    player:SetAttribute("DataLoaded", true)
end

local function PlayerJoining(player: Player)

    -- create a new player
    local newPlayerObj = PlayerClass.new(player)
    PlayerService.players[player.UserId] = newPlayerObj

    -- analytics
    print(`[PlayerService] Registering {player.Name}`)

    -- load data
    LoadPlayerData(player)

    -- fire remote
    InternalEvents.PlayerJoining:Fire(player)
end

local function PlayerLeaving(player: Player)

    -- analytics
    print(`[PlayerService] De-registering {player.Name}`)

    -- search for player obj and call its deconstructor
    local check_player = PlayerService.players[player.UserId]
    if check_player then
        check_player:Destroy()
    end

    -- after work is done, fire remote
    InternalEvents.PlayerLeaving:Fire(player)
end

--- Public Functions ---
function PlayerService:Init(context)

    -- these events will fire after playerservice does its work with their individual players
    InternalEvents.PlayerJoining = Instance.new("BindableEvent")
    InternalEvents.PlayerLeaving = Instance.new("BindableEvent")
    self.events.playerJoining = InternalEvents.PlayerJoining.Event
    self.events.playerLeaving = InternalEvents.PlayerLeaving.Event

    self.context = context

    -- register with roblox's events
    players.PlayerAdded:Connect(PlayerJoining)
    players.PlayerRemoving:Connect(PlayerLeaving)
end

function PlayerService:Start()
    
end

return PlayerService