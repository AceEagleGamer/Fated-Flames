-- handles whatever we'll do to each player character when they respawn n whatnot
local CharacterService = {}

--- Public Variables ---
CharacterService.events = {}
CharacterService.connections = {}
CharacterService.context = nil

--- Private Functions ---
local function LoadCharacter(player: Player)

    -- get the player data table
    local context = CharacterService.context
    local PlayerService = context.services.playerservice
    local player_info = PlayerService.players[player.UserId]
    if not player_info then
        player:Kick("Something went wrong initializing your player. Please rejoin")
    end

    -- TODO: some more sanity checks i guess

    -- load character
    player:LoadCharacter()
    player_info.character_model = player.Character

    
end

--- Public Functions ---
function CharacterService:Init(context)

    self.context = context
    local PlayerService = context.services.playerservice

    self.connections.playerJoined = PlayerService.events.playerJoining:Connect(function(player: Player)
        LoadCharacter(player)
    end)
end

function CharacterService:Start()

end

return CharacterService