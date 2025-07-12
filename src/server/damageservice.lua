--- References ---
local rep = game:GetService("ReplicatedStorage")
local playerService = game:GetService("Players")
local events = rep.Events
local moves = rep.Moves

--- Public Variables ---
local DamageService = {}

DamageService.connections = {}
DamageService.context = nil

--- Private Functions ---
local function QueueStun(player, stunDuration)
    local PlayerService = DamageService.context.services.playerservice

    -- get player info
    local player_info = PlayerService.players[player.UserId]
    local char = player_info.character_model
    local threads = player_info.threads

    -- sanity check
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end 

    -- cancel previous stun thread
    if threads.stunThread then task.cancel(threads.stunThread) end

    char:SetAttribute("Stunned", true)
    threads.stunThread = task.delay(stunDuration, function()
        char:SetAttribute("Stunned", false)
    end)
end

--- Public Functions ---
function DamageService:Init(context)

    self.context = context

end

function DamageService:EvaluateHit(player, moveData, hitList)

    local services = DamageService.context.services

    -- player sanity check
    if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character:FindFirstChild("Humanoid").Health <= 0 then return end
    if not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = player.Character.HumanoidRootPart

    print('hitting')

end

function DamageService:Start()

end


return DamageService