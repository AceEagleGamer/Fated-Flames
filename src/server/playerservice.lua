-- will handle the registering of players and other stuff in the future probably

--- References ---
local players = game:GetService("Players")
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events
local packages = rep.Packages
--local ProfileStore = require(game:GetService("ReplicatedStorage").Packages.profilestore)

--- Public Variables ---
local PlayerService = {}

PlayerService.players = {}
PlayerService.connections = {}
PlayerService.events = {}
PlayerService.context = nil
PlayerService.debug = false

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
    local self = PlayerService
    
    -- register player via their id
    self.players[player.UserId] = {
        player_object = player,
        character_model = nil,
        connections = {},
    }

    -- debug purposes
    if self.debug then
        print(`[PlayerService] Registering {player.Name}`)
        --print(self.players)
    end

    -- load data
    LoadPlayerData(player)

    -- after work is done, fire emote
    InternalEvents.PlayerJoining:Fire(player)
end

local function PlayerLeaving(player: Player)
    local self = PlayerService

    -- debug purposes
    if self.debug then
        --print(self.players)
        print(`[PlayerService] De-registering {player.Name}`)
    end

    -- find the registered player
    local check_player = self.players[player.UserId]
    if check_player then
        self.players[player.UserId] = nil
    end

    -- after work is done, fire emote
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