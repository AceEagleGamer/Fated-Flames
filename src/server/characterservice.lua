-- handles whatever we'll do to each player character when they respawn n whatnot
-- tells the player to load things on the client side

--- References ---
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events
local _packages = rep.Packages

--- Public Variables ---
local CharacterService = {}

CharacterService.debug = false
CharacterService.events = {}
CharacterService.connections = {}
CharacterService.context = nil
CharacterService.charFolder = nil

--- Private Functions ---
local function onCharacterAdded(player: Player, char: Model)

    -- wait for the character appearance to load
    player.CharacterAppearanceLoaded:Wait()

    -- set player parts to not interact with physics queries
    for _, part in char:GetDescendants() do
        if part:IsA("BasePart") then
            part.CanQuery = false
            part.CanTouch = false
        end
    end

    -- get the player data table
    local context = CharacterService.context
    local PlayerService = context.services.playerservice
    local player_info = PlayerService.players[player.UserId]
    if not player_info then
        player:Kick("On Character Added: Something went wrong initializing your player. Please rejoin")
    end

    -- re-parent the character
    char.Parent = CharacterService.charFolder

    -- set up attributes
    char:SetAttribute("Blocking", false)
    char:SetAttribute("Stunned", false)
    char:SetAttribute("StunImmunity", false)

    char:SetAttribute("Posture", 50)

    -- set up events
    local hum = char:WaitForChild("Humanoid")
    player_info.connections.playerDied = hum.Died:Connect(function()
        player:SetAttribute("CharacterLoaded", false)
        -- reset connections
        player_info.connections.playerDied:Disconnect()

        -- TODO: handle stuff related to death here. i'll just deleted the character model and erase the reference for now
        char:Destroy()
        player_info.player_object = nil

        -- initiate the respawn
        task.wait(context.respawnTimer)

        player:SetAttribute("CharacterLoaded", true)
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

    -- create the playercharacters folder
    local cFolder = Instance.new("Folder", workspace)
    cFolder.Name = "PlayerCharacters"
    self.charFolder = cFolder

    self.connections.playerLoaded = events.PlayerLoaded.OnServerEvent:Connect(function(player: Player)
        player:SetAttribute("ClientLoaded", true)
    end)
end

function CharacterService:Start()

    local context = self.context
    local PlayerService = context.services.playerservice

    self.connections.playerJoined = PlayerService.events.playerJoining:Connect(function(player: Player)
        
        -- wait for the player to load on the client first
        player:GetAttributeChangedSignal("ClientLoaded"):Wait()

        InitialLoadCharacter(player) -- this should hopefully yield

        -- fire some events for the player to know that we've loaded in
        player:SetAttribute("CharacterLoaded", true)
    end)
end

return CharacterService