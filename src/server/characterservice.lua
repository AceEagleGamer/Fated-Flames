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
CharacterService.charThreads = {}

--- Private Functions ---
local function onCharacterAdded(player: Player, char)

    -- wait for the character appearance to load
    player.CharacterAppearanceLoaded:Wait()

    -- set player parts to not interact with physics queries
    for _, part in char:GetDescendants() do
        if part.Parent:IsA("Accessory") and part:IsA("BasePart") then
            part.CanQuery = false
            part.CanTouch = false
        end

        if part:IsA("BasePart") then
            part.CollisionGroup = "Players"
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
    char:SetAttribute("Staggered", false)
    char:SetAttribute("Hyperarmor", false)

    char:SetAttribute("Posture", 50)
    char:SetAttribute("RagdollCancelCooldownDuration", 15)

    -- set up events
    local hum = char:WaitForChild("Humanoid")
    player_info.connections.playerDied = hum.Died:Connect(function()
        player:SetAttribute("CharacterLoaded", false)
        char:SetAttribute("Dead", true)
        -- reset connections
        player_info.connections.playerDied:Disconnect()

        player_info.player_object = nil

        -- ragdoll the player
        char:SetAttribute("IsRagdoll", true)

        -- play a funny sound
        local sound = rep.DeathSound:Clone()
        sound.Parent = char.HumanoidRootPart
        sound:Play()

        -- initiate the respawn
        task.wait(context.respawnTimer)
        char:Destroy()

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

    -- temp for npcs for now
    for _, npc in workspace.NPCs:GetChildren() do
        self.charThreads[npc] = {}
    end

    self.connections.playerJoined = PlayerService.events.playerJoining:Connect(function(player: Player)

        -- register player threads table
        self.charThreads[player.UserId] = {}
        
        -- wait for the player to load on the client first
        player:GetAttributeChangedSignal("ClientLoaded"):Wait()

        InitialLoadCharacter(player) -- this should hopefully yield

        -- fire some events for the player to know that we've loaded in
        player:SetAttribute("CharacterLoaded", true)
    end)

    self.connections.playerLeft = PlayerService.events.playerLeaving:Connect(function(player: Player)
        
        local charThreads = self.charThreads[player.UserId]
        -- clear threads and remove records
        for _, thread in charThreads do
            task.cancel(thread) -- assume theyre all task threads
        end

        -- extra clear i guess idk
        table.clear(charThreads)
        self.charThreads[player.UserId] = nil
    end)
end

return CharacterService