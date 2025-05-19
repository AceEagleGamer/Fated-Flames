-- will handle the registering of players and other stuff in the future probably

--- References ---
local players = game:GetService("Players")

--- Public Variables ---
local PlayerService = {}

PlayerService.players = {}
PlayerService.events = {}
PlayerService.context = nil
PlayerService.debug = false

--- Private Variables ---
local InternalEvents = {}

--- Private Functions ---
local function PlayerJoining(player: Player)
    local self = PlayerService
    
    -- register player via their id
    self.players[player.UserId] = {
        playerObject = player,
        connections = {},
    }

    -- debug purposes
    if self.debug then
        print(`Registering {player.Name}`)
        print(self.players)
    end

    -- after work is done, fire emote
    self.events.playerJoining:Fire(player)
end

local function PlayerLeaving(player: Player)
    local self = PlayerService

    -- find the registered player
    local check_player = self.players[player.UserId]
    if check_player then
        self.players[player.UserId] = nil
    end

    -- debug purposes
    if self.debug then
        print(`De-registering {player.Name}`)
        print(self.players)
    end

    -- after work is done, fire emote
    self.events.playerLeaving:Fire(player)

end

--- Public Functions ---
function PlayerService:Init(context)

    -- these events will fire after playerservice does its work with their individual players
    self.events.playerJoining = Instance.new("BindableEvent")
    self.events.playerLeaving = Instance.new("BindableEvent")

    self.context = context

    print(self.context)
end

function PlayerService:Start()

    -- register with roblox's events
    InternalEvents.playerJoining = players.PlayerAdded:Connect(PlayerJoining)
    InternalEvents.playerLeaving = players.PlayerRemoving:Connect(PlayerLeaving)
end

return PlayerService