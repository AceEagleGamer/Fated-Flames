--- References ---
local rep = game:GetService("ReplicatedStorage")
--local run = game:GetService("RunService")
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
Core.playerState = {
    endlag = false,
    stunned = false,
    blocking = false,
    statuses = {},

    originalWalkspeed = 16, -- just set it to this for now
    originalJumpPower = 50,

    remote = nil,
    Changed = nil
}
Core.queuedHits = {}

Core.debug = false

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

    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    local animator = hum:FindFirstChild("Animator")
    if not animator then return end

    for _, animFolder in rep.HitAnims:GetChildren() do
        animTracks[animFolder.Name] = {}
        for _, anim in animFolder:GetChildren() do
            if not anim:IsA("Animation") then continue end
            animTracks[animFolder.Name][anim.Name] = animator:LoadAnimation(anim)
        end


    end
    animTracks.currentlyPlaying = "nil"
    animTracks.currentFolder = "nil"
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
function Core:Endlag(duration)

    -- sanity check
    if self.context == nil then return end -- idk why this would happen but just making sure
    if self.playerState.endlag then return end -- this might be cause for concern later down the line. currently i dont care

    -- register endlag
    self.playerState.endlag = true
    task.delay(duration, function()
        self.playerState.endlag = false
        self.playerState.remote:Fire()
    end)

    -- fire changed event
    self.playerState.remote:Fire()

    -- TODO: register to the server
end

function Core:PlayHit(attacker, hitTable)
    local function vfx(char, animFolder, isBlocked)

        -- play sound
        if not isBlocked then
            local nSound: Sound = rep.MoveSFX.hitlanded:Clone()
            nSound.Parent = char.HumanoidRootPart
            nSound:Play()
            game:GetService("Debris"):AddItem(nSound, nSound.TimeLength)
        else
            local nSound: Sound = rep.MoveSFX.hitblocked:Clone()
            nSound.Parent = char.HumanoidRootPart
            nSound:Play()
            game:GetService("Debris"):AddItem(nSound, nSound.TimeLength)
        end
        
        -- get anim table
        local animTracks = self.characterAnims[char]
        if animTracks then
            -- stop previous anim
            if animTracks.currentlyPlaying ~= "nil" and animTracks.currentFolder ~= "nil" and animTracks[animTracks.currentFolder][animTracks.currentlyPlaying].IsPlaying then
                animTracks[animTracks.currentFolder][animTracks.currentlyPlaying]:Stop()
            end

            -- play new anim
            local chosenAnim = animTracks[animFolder][`hit{math.random(1, #game.ReplicatedStorage.HitAnims[animFolder]:GetChildren())}`]
            chosenAnim:Play()
            animTracks.currentlyPlaying = chosenAnim.Animation.Name
            animTracks.currentFolder = animFolder

            chosenAnim.Ended:Connect(function()
                animTracks.currentlyPlaying = "nil"
                animTracks.currentFolder = "nil"
            end)
        else
            warn("no anim tracks?")
        end
    end

    for _, char in hitTable do

        -- check if they're blocking
        if char:GetAttribute("Blocking") == true then
            local dot = attacker.HumanoidRootPart.CFrame.LookVector:Dot(char.HumanoidRootPart.CFrame.LookVector)
            print(dot)
            if dot > 0.1 then -- facing the back
                vfx(char, "Default", false)
            else
                vfx(char, "fistblock", true)
            end
        else
            vfx(char, "Default", false)
        end
    end
end

function Core:Init(context)
    self.context = context
    buildAnimationBlacklist()

    -- build player state table
    self.playerState.remote = Instance.new("BindableEvent")
    self.playerState.Changed = self.playerState.remote.Event

    -- for players that joined before us
    for _, player in playerService:GetPlayers() do
        if player == playerService.LocalPlayer then continue end

        onPlayerLoaded(player)
    end

    -- for npcs that existed before us
    for _, npc in workspace.NPCs:GetChildren() do
        loadHitAnims(npc)
    end

    -- LOcAL PLAYHER
    self.playerCons[localPlayer.UserId] = {}

    -- run stuff ourselves
    localPlayer.CharacterAdded:Connect(function(char)
        -- debug
        -- Core.playerCons[localPlayer.UserId].animationPlayed = char:WaitForChild("Humanoid").Animator.AnimationPlayed:Connect(PreventAnimationFromReplicating)

        -- disconnect previous connections
        if self.playerCons[localPlayer.UserId].ragdoll then self.playerCons[localPlayer.UserId].ragdoll:Disconnect() end
        if self.playerCons[localPlayer.UserId].isStunned then self.playerCons[localPlayer.UserId].isStunned:Disconnect() end

        -- stun tracking
        self.playerCons[localPlayer.UserId].isStunned = char:GetAttributeChangedSignal("Stunned"):Connect(function()
            self.playerState.stunned = char:GetAttribute("Stunned")
            self.playerState.remote:Fire()
        end)

        -- block tracking
        self.playerCons[localPlayer.UserId].isBlocking = char:GetAttributeChangedSignal("Blocking"):Connect(function()
            self.playerState.blocking = char:GetAttribute("Blocking")
            self.playerState.remote:Fire()
        end)

        -- ragdoll client side
        self.playerCons[localPlayer.UserId].ragdoll = events.RagdollClient.OnClientEvent:Connect(function(isRagdoll, kbDir)
            if not char:FindFirstChild("Humanoid") then return end
            if isRagdoll then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
                char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

                -- Apply any desired impulse when the character ragdolls
                char.HumanoidRootPart.AssemblyLinearVelocity = -kbDir
            else
                char.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)

        loadHitAnims(char)
    end)

    -- handle endlag/stunned
    self.playerCons[localPlayer.UserId].playerStateChanged = self.playerState.Changed:Connect(function()
        if not localPlayer.Character or not localPlayer.Character:FindFirstChild("Humanoid") or localPlayer.Character.Humanoid.Health <= 0 then return end

        if self.playerState.endlag or self.playerState.stunned then

            localPlayer.Character:FindFirstChild("Humanoid").WalkSpeed = 0
            localPlayer.Character:FindFirstChild("Humanoid").JumpPower = 0

            -- cancel all queued hits on stun
            if self.playerState.stunned then
                for _, hit in self.queuedHits do
                    task.cancel(hit)
                end
            end
        elseif self.playerState.blocking then
            localPlayer.Character:FindFirstChild("Humanoid").WalkSpeed = 5
            localPlayer.Character:FindFirstChild("Humanoid").JumpPower = 0
        else
            localPlayer.Character:FindFirstChild("Humanoid").WalkSpeed = self.playerState.originalWalkspeed
            localPlayer.Character:FindFirstChild("Humanoid").JumpPower = self.playerState.originalJumpPower
        end
    end)

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

    -- hit replication
    events.ReplicateHit.OnClientEvent:Connect(function(player, hitTable, hitProperties)
        if player == localPlayer.Name then return end
        print("test")
        self:PlayHit(workspace.PlayerCharacters:FindFirstChild(player), hitTable)

        -- do some stun stuff here
    end)

    -- client prediction
    --self.playerCons[localPlayer.UserId].serverPrediction = run.Heartbeat:Connect(predictServerCFrame) -- should this be here?
end

return Core