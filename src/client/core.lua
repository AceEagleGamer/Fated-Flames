--- References ---
local rep = game:GetService("ReplicatedStorage")
local run = game:GetService("RunService")
local playerService = game:GetService("Players")
local localPlayer = playerService.LocalPlayer
local events = rep.Events

--- Public Variables ---
local Core = {}

Core.context = nil
Core.connections = {}
Core.animBlacklist = {}
Core.playerCons = {}

Core.animCons = {}
Core.characterAnims = {}
Core.currentServerCFramePrediction = CFrame.new(0,0,0)

Core.debug = true

--- Private Functions ---
local function buildAnimationBlacklist()
    for _, anim: Animation in rep.HitAnims:GetDescendants() do
        if not anim:IsA("Animation") then continue end
        Core.animBlacklist[anim.AnimationId] = true
    end

    if Core.debug then
        print(Core.animBlacklist)
    end
end

local function loadHitAnims(char)
    local animTracks = {}
    Core.characterAnims[char] = animTracks

    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end

    local animator = hum:FindFirstChild("Animator")
    if not animator then return end

    for _, anim: Animation in rep.HitAnims:GetDescendants() do
        if not anim:IsA("Animation") then continue end
        animTracks[anim.Name] = animator:LoadAnimation(anim)
    end
    animTracks.currentlyPlaying = "nil"
end

local function PreventAnimationFromReplicating(anim)
    if anim.Name == "Animation" and Core.animBlacklist[anim.Animation.AnimationId] then
        anim:Stop()
    end
end

local function onPlayerLoaded(player)
    Core.playerCons[player.UserId] = {}

    Core.playerCons[player.UserId].characterAdded = player.CharacterAdded:Connect(function(char)
        Core.playerCons[player.UserId].animationPlayed = char:WaitForChild("Humanoid").Animator.AnimationPlayed:Connect(PreventAnimationFromReplicating)

        loadHitAnims(char)
        
    end)

    if player.Character then
        Core.playerCons[player.UserId].animationPlayed = player.Character:WaitForChild("Humanoid").Animator.AnimationPlayed:Connect(PreventAnimationFromReplicating)
        loadHitAnims(player.Character)
    end
end

--- Public Functions ---
function Core:PlayHit(hitTable)
    for _, char in hitTable do

        -- play sound
        local nSound: Sound = rep.MoveSFX.hitlanded:Clone()
        nSound.Parent = char.HumanoidRootPart
        nSound:Play()
        game:GetService("Debris"):AddItem(nSound, nSound.TimeLength)
        
        -- get anim table
        local animTracks = self.characterAnims[char]
        if not animTracks then warn(`{char.Name} does not have anim tracks?`); continue end

        -- stop previous anim
        if animTracks.currentlyPlaying ~= "nil" and animTracks[animTracks.currentlyPlaying].IsPlaying then
            animTracks[animTracks.currentlyPlaying]:Stop()
        end

        -- play new anim
        local chosenAnim = animTracks[`hit{math.random(1,4)}`]
        chosenAnim:Play()
        animTracks.currentlyPlaying = chosenAnim.Animation.Name

        chosenAnim.Ended:Connect(function()
            animTracks.currentlyPlaying = "nil"
        end)
    end
end

function Core:Init(context)
    self.context = context
    buildAnimationBlacklist()

    -- for players that joined before us
    for _, player in playerService:GetPlayers() do
        if player == playerService.LocalPlayer then continue end

        onPlayerLoaded(player)
    end

    -- for npcs that existed before us
    for _, npc in workspace.NPCs:GetChildren() do
        loadHitAnims(npc)
    end

     -- TODO: create for new NPCs
    
    -- for players joining after us
    self.connections.playerLoaded = playerService.PlayerAdded:Connect(onPlayerLoaded)

    self.connections.playerLeft = playerService.PlayerRemoving:Connect(function(player: Player)

        for _, con in self.playerCons[player.UserId] do
            con:Disconnect()
        end

        self.playerCons[player.UserId] = nil
    end)
end

function Core:Start()
    Core.playerCons[localPlayer.UserId] = {}

    -- run stuff ourselves
    localPlayer.CharacterAdded:Connect(function(char)
        Core.playerCons[localPlayer.UserId].animationPlayed = char:WaitForChild("Humanoid").Animator.AnimationPlayed:Connect(PreventAnimationFromReplicating)

        loadHitAnims(char)
    end)

    -- hit replication
    events.ReplicateHit.OnClientEvent:Connect(function(player, hitTable)
        if player.Name == localPlayer.Name then return end
        self:PlayHit(hitTable)
    end)

    -- client prediction
    --self.playerCons[localPlayer.UserId].serverPrediction = run.Heartbeat:Connect(predictServerCFrame) -- should this be here?
end

return Core