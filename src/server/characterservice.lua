-- handles whatever we'll do to each player character when they respawn n whatnot
-- tells the player to load things on the client side

--- References ---
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events
local _packages = rep.Packages

--- Public Variables ---
local CharacterService = {}

CharacterService.connections = {}
CharacterService.context = nil
CharacterService.charFolder = nil

--- Private Functions ---
local function onCharacterAdded(player: Player, char)

    -- wait for the character appearance to load
    player.CharacterAppearanceLoaded:Wait()
    player:SetAttribute("CharacterLoaded", true)

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
    local TickService = context.services.tickservice
    local player_info = PlayerService.players[player.UserId]
    if not player_info then
        player:Kick("[CharacterService] Something went wrong initializing your player. Please rejoin")
    end

    -- re-parent the character
    char.Parent = CharacterService.charFolder
    player_info.character_model = player.Character
    player_info:LoadAnimations()

    -- set up attributes
    char:SetAttribute("Blocking", false)
    char:SetAttribute("Stunned", false)
    char:SetAttribute("Endlag", false)
    char:SetAttribute("Staggered", false)
    char:SetAttribute("Hyperarmor", false)

    char:SetAttribute("Posture", 50)
    char:SetAttribute("RagdollCancelCooldownDuration", 15)

    -- create attachments n stuff for dashes and other stuff
    local velHolder = Instance.new("Attachment", char.HumanoidRootPart)
    local linearVel = Instance.new("LinearVelocity", velHolder)
    linearVel.Enabled = false
    linearVel.Attachment0 = velHolder
    linearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    linearVel.MaxAxesForce = Vector3.new(50000, 0, 50000)

    -- set up events
    local hum = char:WaitForChild("Humanoid")
    player_info.connections.playerDied = hum.Died:Connect(function()
        player:SetAttribute("CharacterLoaded", false)
        char:SetAttribute("Dead", true)

        -- reset connections and info
        player_info:Reset()

        -- ragdoll the player
        char:SetAttribute("IsRagdoll", true)

        -- play a funny sound
        local sound = rep.DeathSound:Clone()
        sound.Parent = char.HumanoidRootPart
        sound:Play()

        -- initiate the respawn
        task.wait(context.respawnTimer)
        char:Destroy()

        player:LoadCharacter()
    end)

    player_info.connections.adjustWalkspeed = TickService.Update:Connect(function(dt)
        if player_info.character_model == nil or player_info.character_model:FindFirstChild("Humanoid") == nil then return end -- catch for nil idk

        -- last jump timestamp help
        if player_info.character_model.Humanoid.Jump and player_info.character_model.Humanoid.FloorMaterial ~= Enum.Material.Air then
            player_info.timestamps.lastJump = time()
        end

        -- looks like bad
        if player_info.playerStates.endlag or player_info.character_model:GetAttribute("Stunned") then
            player_info.character_model.Humanoid.JumpPower = 0
            player_info.character_model.Humanoid.WalkSpeed = 0
        elseif (player_info.inputStates.m1 and player_info.playerStates.canM1) then
            player_info.character_model.Humanoid.JumpPower = 0
            --player_info.character_model.Humanoid.WalkSpeed = 7
        else
            player_info.character_model.Humanoid.JumpPower = 50
            player_info.character_model.Humanoid.WalkSpeed = 16
        end
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