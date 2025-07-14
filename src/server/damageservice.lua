--- References ---
local rep = game:GetService("ReplicatedStorage")
local playerService = game:GetService("Players")
local events = rep.Events
local moves = rep.Moves
local moveSFX = rep.MoveSFX

--- Public Variables ---
local DamageService = {}

DamageService.connections = {}
DamageService.context = nil

--- Private Functions ---
local function QueueStun(character, stunDuration)
    local PlayerService = DamageService.context.services.playerservice
    local NPCService = DamageService.context.services.npcservice

    -- get character info
    local character_info = nil
    if character:IsA("Player") then
        character_info = PlayerService.players[character.UserId]
    else
        character_info = NPCService.npcs[character:GetAttribute("NPCID")]
    end
    
    local char = character_info.character_model
    local threads = character_info.threads

    -- sanity check
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end 

    -- interrupt moves that should be interrupted on stun

    -- cancel previous stun thread
    if threads.stunThread then task.cancel(threads.stunThread) end

    char:SetAttribute("Stunned", true)
    threads.stunThread = task.delay(stunDuration, function()
        char:SetAttribute("Stunned", false)
    end)
end

local function CalculateDamage(hit, hitData)
    hit:FindFirstChild("Humanoid"):TakeDamage(hitData.damage)
    if hitData.stunDuration then
        --QueueStun(hit, hitData.stunDuration)
    end
end

local function PlaySound(soundName, origin)
    local sound = moveSFX:FindFirstChild(soundName, true)
    if sound == nil then return end

    sound = sound:Clone()
    sound.Parent = origin
    sound:Play()
    game:GetService("Debris"):AddItem(sound, sound.TimeLength * 3)
end

--- Public Functions ---
function DamageService:Init(context)

    self.context = context

end

function DamageService:EvaluateHit(player, hitData, hitList)

    for _, hit in hitList do
        if hit == player.Character then continue end -- catch so we dont hit ourselves

        -- dont register if the hit is hitting a ragdolled character and we cant bypass ragdolls
        if hit:GetAttribute("IsRagdoll") == true and hitData.bypassRagdoll ~= true then continue end

        -- check if we're blocking
        local blocking = hit:GetAttribute("Blocking")
        if blocking then
            local dot = player.Character.HumanoidRootPart.CFrame.LookVector:Dot(hit.HumanoidRootPart.CFrame.LookVector)
            if dot > 0.1 or hitData.bypassBlocks then -- facing the back
                CalculateDamage(hit, hitData)
                hit:SetAttribute("Blocking", false)

                -- play sound
                PlaySound("hitlanded", hit.HumanoidRootPart)
            else
                -- damage posture
                hit:SetAttribute("Posture", hit:GetAttribute("Posture") - hitData.postureDamage or 5)

                -- play sound
                PlaySound("hitblocked", hit.HumanoidRootPart)
            end
        else
            CalculateDamage(hit, hitData)

            -- play sound
            PlaySound("hitlanded", hit.HumanoidRootPart)
        end
    end

end

function DamageService:Start()

end


return DamageService