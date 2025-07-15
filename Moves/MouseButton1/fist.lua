--- Public Variables ---
local MoveData = {}
MoveData.__index = MoveData

--- Private Variables ---
local shared = game:GetService("ReplicatedStorage").Shared
local maid = require(shared.maid)
local hitbox = require(shared.hitbox)
local moveSFX = game:GetService("ReplicatedStorage").MoveSFX

--- Constructor ---
function MoveData.new(playerData, context)
    local newMoveData = {}
    setmetatable(newMoveData, MoveData)

    -- hit properties
    newMoveData.hitProperties = {
        hit1 = {
            damage = 5,
            postureDamage = 10,
            stunDuration = 1.5,
            interruptible = true,
            endlag = 0.4,
            hitboxTiming = 0.2,

            cframe = CFrame.new(0,0,-3),
            size = Vector3.new(6,6,6),
        },

        hit2 = {
            damage = 5,
            postureDamage = 10,
            stunDuration = 1.5,
            interruptible = true,
            endlag = 0.4,
            hitboxTiming = 0.2,

            cframe = CFrame.new(0,0,-3),
            size = Vector3.new(6,6,6),
        },

        hit3 = {
            damage = 5,
            postureDamage = 10,
            stunDuration = 1.5,
            interruptible = true,
            endlag = 0.4,
            hitboxTiming = 0.2,

            cframe = CFrame.new(0,0,-3),
            size = Vector3.new(6,6,6),
        },

        hit4 = {
            damage = 5,
            postureDamage = 15,
            stunDuration = 1.5,
            interruptible = true,
            endlagFulfilled = 1,
            endlagOtherwise =  0.5,
            hitboxTiming = 0.2,

            endlagCondition = function(hitProperties, hitList)
                return #hitList == 0
            end,

            ragdolls = true,
            ragdollProperties = {
                knockbackStrength = 75,
                duration = 2.5
            },

            cframe = CFrame.new(0,0,-3),
            size = Vector3.new(6,6,6),
        },

        downslam = {
            damage = 5,
            postureDamage = 0,
            stunDuration = 2,
            hitboxTiming = 0.2,
            interruptible = true,
            bypassRagdoll = true,

            endlagFulfilled = 1,
            endlagOtherwise =  0.5,
            endlagCondition = function(hitProperties, hitList)
                return #hitList == 0
            end,

            ragdolls = true,
            ragdollProperties = {
                knockback = Vector3.new(0,1,0),
                knockbackStrength = 70,
                setCFrame = CFrame.new(0,0,0) * CFrame.Angles(math.rad(90),0,0),
                duration = 2
            },

            cframe = CFrame.new(0,-6,-4),
            size = Vector3.new(4,8,4),
        },

        uppercut = {
            damage = 5,
            postureDamage = 15,
            stunDuration = 2,
            hitboxTiming = 0.2,
            interruptible = true,
            bypassRagdoll = true,

            endlagFulfilled = 1,
            endlagOtherwise =  0.5,
            endlagCondition = function(hitProperties, hitList)
                return #hitList == 0
            end,

            ragdolls = true,
            ragdollProperties = {
                knockback = Vector3.new(0,-1,0),
                knockbackStrength = 120,
                setCFrame = CFrame.new(0,0,0) * CFrame.Angles(math.rad(90),0,0),
                duration = 2
            },

            cframe = CFrame.new(0,2,-3),
            size = Vector3.new(5,4,5),
        }
    }

    -- move properties
    newMoveData.properties = {

        currentComboString = 1,
        maxComboString = 4,
        comboResetTimer = 1,
    }

    newMoveData.stateTable = {
        lastMoveTick = 0,
    }

    -- references and other important stuff
    newMoveData.playerData = playerData
    newMoveData.context = context

    return newMoveData
end

--- Deconstructor ---
function MoveData:Destroy()
    table.clear(self.properties)
    table.clear(self.stateTable)
    self.playerData = nil

    maid:DeepClear(self.hitProperties)

    table.clear(self)
end

--- Class Functions ---
function MoveData:Tick()
    self.properties.currentComboString += 1

    if self.properties.currentComboString > 4 then -- reset back to one
        self.properties.currentComboString = 1
    end
end

function MoveData:Work()
    local player_info = self.playerData
    local services = self.context.services
    local DamageService = services.damageservice
    local TickService = services.tickservice

    if not player_info.playerStates.busy and player_info.playerStates.canM1 and player_info.character_model and player_info.character_model:FindFirstChild("HumanoidRootPart") then
        player_info.playerStates.busy = true
        player_info.character_model:SetAttribute("Busy", true) -- replicate to other clients

        -- check if we've exceeded the combo reset timer, then reset
        if (time() - self.stateTable.lastMoveTick >= self.properties.comboResetTimer) then
            self.properties.currentComboString = 1
        end

        -- check if we're on hit4 then determine if we're fulfilling the condition of a variant
        local variant = nil
        if self.properties.currentComboString == 4 then
            local isJumping = player_info.inputStates.jumping
            if isJumping then -- going up
                variant = "uppercut"
            elseif (time() - player_info.timestamps.lastJump < 0.5) and (time() - self.stateTable.lastMoveTick < 1) then -- going down
                variant = "downslam"
            end
        end

        -- update info for player and move table
        self.stateTable.lastMoveTick = time()

        -- get current hit properties, and animation
        local hitProperty = self.hitProperties[`hit{self.properties.currentComboString}`]
        local moveAnim = player_info.animations[`hit{self.properties.currentComboString}`]
        local moveSound = moveSFX.MouseButton1.fist:FindFirstChild(`hit{self.properties.currentComboString}`)

        if variant then
            hitProperty = self.hitProperties[variant]
            moveAnim = player_info.animations[variant]
            moveSound =  moveSFX.MouseButton1.fist:FindFirstChild(variant)
        end

        local moveEndlag = hitProperty.endlag

        -- play animation n things
        local hasEndlagCondition = hitProperty.endlagCondition ~= nil
        local endlagConditionEvaluated = Instance.new("BindableEvent")
        local moveThread = task.spawn(function()

            -- stop previous animations
            for i = 1,4 do
                player_info.animations[`hit{i}`]:Stop()
            end

            -- let the move run
            -- TODO: vfx link to the client
            moveAnim:Play()
            local sound = moveSound:Clone()
            sound.Parent = player_info.character_model.HumanoidRootPart
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 2)

            -- overlap
            local overlapParams = OverlapParams.new()
            overlapParams.FilterType = Enum.RaycastFilterType.Exclude
            overlapParams.FilterDescendantsInstances = {player_info.character_model}

            -- hitbox stuff
            local hits = {}
            local newHitbox = hitbox.CreateHitbox()
            newHitbox.Size = hitProperty.size
            newHitbox.CFrame = player_info.character_model.HumanoidRootPart
            newHitbox.Offset = hitProperty.cframe
            newHitbox.VelocityPrediction = true
            newHitbox.VelocityPredictionTime = player_info.player_object:GetNetworkPing()
            newHitbox.OverlapParams = overlapParams

            newHitbox.Touched:Connect(function(hit, humanoid)
                table.insert(hits, humanoid.Parent)
            end)
            
            task.delay(hitProperty.hitboxTiming, function()

                -- help
                TickService.Update:Wait()
                newHitbox:Start()
                TickService.Update:Wait()
                newHitbox:Stop()

                DamageService:EvaluateHit(player_info.player_object, hitProperty, hits)
                
                -- special endlag condition
                if hasEndlagCondition then
                    local fulfilled = hitProperty.endlagCondition(hitProperty, hits)
                    if fulfilled then
                        moveEndlag = hitProperty.endlagFulfilled - hitProperty.hitboxTiming -- account for calculation delay
                        player_info.playerStates.endlag = true
                        player_info.character_model:SetAttribute("Endlag", true)
                    else
                        moveEndlag = hitProperty.endlagOtherwise - hitProperty.hitboxTiming -- account for calculation delay
                    end
                    endlagConditionEvaluated:Fire()
                end
            end)
            
        end)

        -- add to table for other scripts to interrupt
        if hitProperty.interruptible then
            table.insert(player_info.moveQueue, moveThread)
        end

        -- at the end, go to the next tick
        if hasEndlagCondition then
            endlagConditionEvaluated.Event:Wait()
            endlagConditionEvaluated:Destroy()

            task.delay(0.2, function()
                player_info.playerStates.canM1 = false
                player_info.character_model:SetAttribute("CanM1", false) -- replicate to other clients
                local timer = if player_info.playerStates.endlag then 2 else 1

                player_info.threads.canM1Again = task.delay(timer, function()
                    player_info.character_model:SetAttribute("CanM1", true) -- replicate to other clients
                    player_info.playerStates.canM1 = true
                end)
            end)
        end

        player_info.threads.m1Endlag = task.delay(moveEndlag, function()
            player_info.playerStates.busy = false

            -- wHY
            if player_info.animations.hit4.IsPlaying or player_info.animations.downslam.IsPlaying or player_info.animations.uppercut.IsPlaying then
                player_info.animations.hit4:AdjustSpeed(12)
                player_info.animations.downslam:AdjustSpeed(12)
                player_info.animations.uppercut:AdjustSpeed(12)
            end

            player_info.character_model:SetAttribute("Busy", false) -- replicate to other clients
            player_info.character_model:SetAttribute("Endlag", false) -- replicate to other clients
            player_info.playerStates.endlag = false
        end)
        self:Tick()
    end

end

return MoveData