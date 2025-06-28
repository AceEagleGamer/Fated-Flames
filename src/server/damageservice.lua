--- References ---
local rep = game:GetService("ReplicatedStorage")
local playerService = game:GetService("Players")
local events = rep.Events
local moves = rep.Moves

--- Public Variables ---
local DamageService = {}

DamageService.debug = false
DamageService.events = {}
DamageService.connections = {}
DamageService.context = nil
DamageService.charFolder = nil

--- Private Functions ---
local function QueueStun(char, stunDuration)

    local MoveService = DamageService.context.services.characterservice

    -- disconnect previous thread
    local threadHolder = MoveService.charThreads[(playerService:GetPlayerFromCharacter(char) and playerService:GetPlayerFromCharacter(char).UserId) or char]
    if not threadHolder then return end

    if threadHolder.stunThread then task.cancel(threadHolder.stunThread) end

    -- sanity check
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end 

    char:SetAttribute("Stunned", true)
    threadHolder.stunThread = task.delay(stunDuration, function()
        char:SetAttribute("Stunned", false)
    end)
end


local function EvaluateHit(player, hitProperties: {[any]: any?}, rawMoveName, hitboxVariant, hitDataName)

    local services = DamageService.context.services

    -- player sanity check
    if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character:FindFirstChild("Humanoid").Health <= 0 then return end
    if not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = player.Character.HumanoidRootPart

    -- prevent things from happening when stunned
    if player.Character:GetAttribute("Stunned") == true or player.Character:GetAttribute("IsRagdoll") == true then return end

    -- data sanity check
    if hitProperties.HitList == nil then return end
    local hitTable = hitProperties.HitList

    -- get move data
    local moveIdentifier = string.split(rawMoveName, '/')
    local moveFolder = moveIdentifier[1]
    local moveName = moveIdentifier[2]

    -- move sanity check
    if not moves:FindFirstChild(moveFolder) then return end
    if not moves[moveFolder]:FindFirstChild(moveName) then return end

    -- get move data
    local moveData = require(moves[moveFolder]:FindFirstChild(moveName))
    local hitboxProperties = moveData.HitboxProperties[hitDataName]

    -- check if theres a hitbox variant
    if hitboxVariant then
        hitboxProperties = hitboxProperties.variants[hitboxVariant]
    end

    -- TODO: security checks. just hit them here doesnt matter
    local playersHit = {}
    local function work(hit)
        hit:FindFirstChild("Humanoid"):TakeDamage(moveData.properties.damage)

        -- stun if theres a stun duration
        if hitboxProperties.stunDuration then
            QueueStun(hit, hitboxProperties.stunDuration)
        end

        -- ragdoll if applicable
        if hitboxProperties.ragdolls then
            -- calculate kb
            local ragdollProperties = hitboxProperties.ragdollProperties
            local kbDir = ragdollProperties.knockback or (hrp.Position - hit.HumanoidRootPart.Position).Unit
            services.ragdollservice:Work(hit, kbDir * (hitboxProperties.ragdollProperties.knockbackStrength or 1), hitboxProperties.ragdollProperties.duration, ragdollProperties.setCFrame)
        end
    end
    -- loop through hit table
    for _, hit in hitTable do
        -- dont register if the hit is hitting a ragdolled character and we cant bypass ragdolls
        if hit:GetAttribute("IsRagdoll") == true and hitboxProperties.bypassRagdoll ~= true then continue end

        if playerService:GetPlayerFromCharacter(hit) then
            table.insert(playersHit, hit)
        end

        -- check if we're blocking
        local blocking = hit:GetAttribute("Blocking")
        if blocking then
            local dot = player.Character.HumanoidRootPart.CFrame.LookVector:Dot(hit.HumanoidRootPart.CFrame.LookVector)
            if dot > 0.1 or hitboxProperties.bypassBlocks then -- facing the back
                work(hit)
                hit:SetAttribute("Blocking", false)
            end
        else
            work(hit)
        end
    end

    events.ReplicateHit:FireAllClients(player.Name, playersHit, moveData.HitboxProperties[`hit{moveData.comboString}`])
end

--- Public Functions ---
function DamageService:Init(context)

    self.context = context

    self.connections.hitRequest = events.Hit.OnServerEvent:Connect(EvaluateHit)
end

function DamageService:Start()

end


return DamageService