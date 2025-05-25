--- References ---
local rep = game:GetService("ReplicatedStorage")

--- Public Variables ---
local Core = {}

Core.context = nil
Core.connections = {}
Core.animBlacklist = {}
Core.playerCons = {}

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

local function PreventAnimationFromReplicating(anim)
    if anim.Name == "Animation" and Core.animBlacklist[anim.Animation.AnimationId] then
        anim:Stop()
    end
end

local function onPlayerLoaded(player: Player)
    Core.playerCons[player.UserId] = {}

    Core.playerCons[player.UserId].characterAdded = player.CharacterAdded:Connect(function(char)
        
        Core.playerCons[player.UserId].animationPlayed = char:WaitForChild("Humanoid").Animator.AnimationPlayed:Connect(PreventAnimationFromReplicating)
    end)
end

--- Public Functions ---
function Core:Init(context)
    self.context = context
    buildAnimationBlacklist()

    -- for players that joined before us
    for _, player in game:GetService("Players"):GetPlayers() do
        --if player == game:GetService("Players").LocalPlayer then continue end

        onPlayerLoaded(player)
        if player.Character then
            self.playerCons[player.UserId].animationPlayed = player.Character:WaitForChild("Humanoid").Animator.AnimationPlayed:Connect(PreventAnimationFromReplicating)
        end
    end
    
    -- for players joining after us
    self.connections.playerLoaded = game:GetService("Players").PlayerAdded:Connect(onPlayerLoaded)

    self.connections.playerLeft = game:GetService("Players").PlayerRemoving:Connect(function(player: Player)

        for _, con in self.playerCons[player.UserId] do
            con:Disconnect()
        end

        self.playerCons[player.UserId] = nil
    end)
end

function Core:Start()

end

return Core