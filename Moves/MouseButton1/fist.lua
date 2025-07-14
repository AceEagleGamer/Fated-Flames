--- Public Variables ---
local MoveData = {}
MoveData.__index = MoveData

--- Private Variables ---
local shared = game:GetService("ReplicatedStorage").Shared
local maid = require(shared.maid)
local hitbox = require(shared.hitbox)
local moveSFX = game:GetService("ReplicatedStorage").MoveSFX

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = {workspace.PlayerCharacters, workspace.NPCs}

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
            endlag = 1.5,
            hitboxTiming = 0.2,

            cframe = CFrame.new(0,0,-3),
            size = Vector3.new(6,6,6),
            variants = {
                downslam = {
                    damage = 5,
                    postureDamage = 0,
                    stunDuration = 2,
                    interruptible = true,

                    endlag = 1.5,
                    endlagCondition = function()

                    end,

                    cframe = CFrame.new(0,-2,-3),
                    size = Vector3.new(3,5,3),
                },

                uppercut = {
                    damage = 5,
                    postureDamage = 15,
                    stunDuration = 2,
                    interruptible = true,

                    endlag = 1.5,
                    endlagCondition = function()

                    end,

                    cframe = CFrame.new(0,2,-3),
                    size = Vector3.new(3,4,3),
                }
            }
        }
    }

    -- move properties
    newMoveData.properties = {

        currentComboString = 1,
        maxComboString = 4,
        comboResetTimer = 4,
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

    if not player_info.playerStates.busy then
        player_info.playerStates.busy = true

        -- check if we've exceeded the combo reset timer, then reset
        if (time() - self.stateTable.lastMoveTick >= self.properties.comboResetTimer) then
            self.properties.currentComboString = 1
        end

        -- update info for player and move table
        self.stateTable.lastMoveTick = time()

        -- get current hit properties, and animation
        local hitProperty = self.hitProperties[`hit{self.properties.currentComboString}`]
        local moveAnim = player_info.animations[`hit{self.properties.currentComboString}`]

        repeat task.wait() until moveAnim.Length > 0

        -- play animation n things
        local moveThread = task.spawn(function()

            -- stop previous animations
            for i = 1,4 do
                player_info.animations[`hit{i}`]:Stop()
            end

            -- let the move run
            -- TODO: vfx link to the client
            moveAnim:Play()
            local sound = moveSFX.MouseButton1.fist:FindFirstChild(`hit{self.properties.currentComboString}`):Clone()
            sound.Parent = player_info.character_model.HumanoidRootPart
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 2)

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
                
            end)
            
        end)

        -- add to table for other scripts to interrupt
        if hitProperty.interruptible then
            table.insert(player_info.moveQueue, moveThread)
        end

        -- at the end, go to the next tick
        task.delay(hitProperty.endlag, function()
            player_info.playerStates.busy = false
        end)
        self:Tick()
    end

end

return MoveData