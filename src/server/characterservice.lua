-- handles whatever we'll do to each player character when they respawn n whatnot
-- tells the player to load things on the client side

--- References ---
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events
local packages = rep.Packages

--- Public Variables ---
local CharacterService = {}

CharacterService.debug = false
CharacterService.events = {}
CharacterService.connections = {}
CharacterService.context = nil

--- Private Functions ---

local function LoadCharacter(player: Player)

end

local function onCharacterAdded(player: Player, char: Model)

    -- get the player data table
    local context = CharacterService.context
    local PlayerService = context.services.playerservice
    local player_info = PlayerService.players[player.UserId]
    if not player_info then
        player:Kick("On Character Added: Something went wrong initializing your player. Please rejoin")
    end

    -- set up events
    local hum = char:WaitForChild("Humanoid")
    player_info.connections.playerDied = hum.Died:Connect(function()
        -- reset connections
        player_info.connections.playerDied:Disconnect()

        -- TODO: handle stuff related to death here. i'll just deleted the character model and erase the reference for now
        char:Destroy()
        player_info.player_object = nil

        -- initiate the respawn
        task.wait(context.respawnTimer)
        player:LoadCharacter()
    end)
end

local function InitialLoadCharacter(player: Player)

    -- get the player data table
    local context = CharacterService.context
    local PlayerService = context.services.playerservice
    local player_info = PlayerService.players[player.UserId]
    if not player_info then
        player:Kick("Initial Load Character: Something went wrong initializing your player. Please rejoin")
    end

    -- TODO: some more sanity checks i guess

    -- set up events for respawning n stuff
    player_info.connections.characterAdded = player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char) -- this will handle the rest
    end)

    -- load character
    player:LoadCharacter()
    player_info.character_model = player.Character
end

--- Public Functions ---
function CharacterService:Init(context)

    self.context = context
    local PlayerService = context.services.playerservice

    self.connections.playerLoaded = events.PlayerLoaded.OnServerEvent:Connect(function(player: Player)
        player:SetAttribute("ClientLoaded", true)
    end)

    self.connections.playerJoined = PlayerService.events.playerJoining:Connect(function(player: Player)
        
        -- wait for the player to load on the client first
        player:GetAttributeChangedSignal("ClientLoaded"):Wait()

        InitialLoadCharacter(player) -- this should hopefully yield

        -- fire some events for the player to know that we've loaded in
        
    end)
end

function CharacterService:Start()

end

return CharacterService