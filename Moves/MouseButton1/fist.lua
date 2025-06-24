-- boilerplate for future moves probably
-- i'd like to make every move modular. i think it will be easier

--- References ---
local rep = game:GetService("ReplicatedStorage")
local shared = rep.Shared

local localPlayer = game:GetService("Players").LocalPlayer

local moveAnims = rep.MoveAnims
local moveSFX = rep.MoveSFX
local events = rep.Events

--- Packages ---
local hitbox = require(shared.hitbox)

--- Public Variables ---
local MoveData = {}
MoveData.comboString = 0
MoveData.context = nil

MoveData.IsKey = false

MoveData.animations = {}
MoveData.sounds = {}
MoveData.hitboxQueue = {}

MoveData.player = nil
MoveData.free = true
MoveData.lastSwing = 0
MoveData.lastlastSwing = 0 -- why

MoveData.properties = {
    cooldown = 0,
    endCD = 1.5,
    comboStringReset = 1,
    damage = 5,
    canMoveAgain = 0.45
}

MoveData.HitboxProperties = {
    hit0 = { --[[ catch for nil. dont ask ]]},
    hit1 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(3,3,3),
        stunDuration = 1.5,
        interruptible = true,
    },
    hit2 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(3,3,3),
        stunDuration = 1.5,
        interruptible = true
    },
    hit3 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(3,3,3),
        stunDuration = 1.5,
        interruptible = true
    },
    hit4 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(3,3,3),
        interruptible = true,

        endlag = 1.5,
        endlagConditions = function(hitProperties)
            return #hitProperties.HitList == 0
        end,

        ragdolls = true,
        ragdollProperties = {
            knockbackStrength = 75,
            duration = 2.5
        },

        variants = {
            uppercut = {
                conditionFulfilled = function()
                    local timeActivated = tick() - MoveData.lastlastSwing
                    return timeActivated < 0.7 and MoveData.context.services.input.heldKeys.space
                end,
                timing = 0.25,
                cframe = CFrame.new(0,2,-3),
                size = Vector3.new(3,4,3),
                interruptible = true,
                knockback = Vector3.new(0,30,0),

                ragdolls = true,
                ragdollProperties = {
                    knockback = Vector3.new(0,-1,0),
                    knockbackStrength = 120,
                    setCFrame = CFrame.new(0,0,0) * CFrame.Angles(math.rad(90),0,0),
                    duration = 2.5
                },

                endlag = 1.5,
                endlagConditions = function(hitProperties)
                    return #hitProperties.HitList == 0
                end,
            },
            downslam = {
                conditionFulfilled = function()
                    local timeActivated = tick() - MoveData.lastlastSwing
                    return (timeActivated > 0.7 and timeActivated < 1) and localPlayer.Character.Humanoid.FloorMaterial == Enum.Material.Air
                end,
                timing = 0.25,
                cframe = CFrame.new(0,-2,-3),
                size = Vector3.new(3,5,3),
                interruptible = true,
                bypassRagdoll = true,
                bypassBlocks = true,

                ragdolls = true,
                ragdollProperties = {
                    knockback = Vector3.new(0,1,0),
                    knockbackStrength = 70,
                    setCFrame = CFrame.new(0,0,0) * CFrame.Angles(math.rad(90),0,0),
                    duration = 2.5
                },

                endlag = 1.5,
                endlagConditions = function(hitProperties)
                    return #hitProperties.HitList == 0
                end,
            }
        }
    },
}

--- Public Functions ---
function MoveData:ResetDefaults()
    self.comboString = 0
    self.properties.cooldown = 0.45

    table.clear(self.animations)
    table.clear(self.sounds)
    self.player = nil
end

function MoveData:GetCooldown() -- just in case there are "complex" behaviors to the move i guess
    return if self.comboString == 4 then self.properties.endCD else self.properties.cooldown
end

function MoveData:Tick()
    -- reset combo string if we're over the timing window
    if tick() - self.lastSwing >= self.properties.comboStringReset then
        self.comboString = 0
    end
    
    self.lastSwing = tick()

    if self.comboString == 4 then self.comboString = 0 end -- reset
    self.comboString += 1
end

function MoveData:TempTick()
    local temp = self.comboString
    if tick() - self.lastSwing >= self.properties.comboStringReset then
        temp = 0
    end

    if self.comboString == 4 then self.comboString = 0 end -- reset
    temp = self.comboString + 1
    
    return temp
end

function MoveData:Init(player: Player, context)
    if not player.Character then warn(`[MoveData] Waiting for character`); player.CharacterAdded:Wait(); return end

    self.context = context
    self.player = player
    self.endlagging = false

    -- index some important stuff
    local char = player.Character
    local hum = char:WaitForChild("Humanoid")
    local animator: Animator = hum:FindFirstChild("Animator")

    -- load anims i guess lol
    local anims = moveAnims.MouseButton1.fist:GetChildren()
    for _, anim in anims do
        self.animations[anim.Name] = animator:LoadAnimation(anim)
    end

    -- index sounds
    local sounds = moveSFX.MouseButton1.fist:GetChildren()
    for _, sound in sounds do
        self.sounds[sound.Name] = sound
    end
end

function MoveData:Replicate()

end

function MoveData:Work(_, inputState, _inputObj)
    if not self.free then return end
    self.free = false

    local core = self.context.services.core
    local input = self.context.services.input
    local playerState = core.playerState
    if playerState.endlag then self.free = true; return end

    -- if we're already moving dont go
    if input.moving then return end

    -- check if we're alive and existing
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then self.free = true; return end

    if inputState == Enum.UserInputState.Begin then

        -- get potential variant
        -- check if we're at hit4, then check if any conditions can be fulfilled
        local hitboxProperty = self.HitboxProperties[`hit{self:TempTick()}`]
        local moveAnim = self.animations[`hit{self:TempTick()}`]
        local moveSound = self.sounds[`hit{self:TempTick()}`]
        local chosenVariant = nil
        if hitboxProperty.variants then

            for variantName, variantData in hitboxProperty.variants do
                if variantData.conditionFulfilled() then
                    moveAnim = self.animations[variantName]
                    moveSound = self.sounds[variantName]

                    chosenVariant = variantName
                    hitboxProperty = variantData
                    break
                end
            end
        end
         
        -- request the server for a move
        local moveGranted = events.RequestMove:InvokeServer(script.Parent.Name, script.Name, chosenVariant, self:TempTick()) -- takes move folder and move name, returns true or false
        if moveGranted then

            -- moving logic
            input.moving = true
            task.delay(self.properties.canMoveAgain, function()
                input.moving = false
            end)

            self:Tick()

            -- stop previous anim (idk if this does anything)
            if self.animations[`hit{self.comboString - 1}`] then self.animations[`hit{self.comboString - 1}`]:Stop() end

            MoveData.lastlastSwing = tick() -- die
            
            -- play vfx stuff
            moveAnim:Play()
            moveSound:Play()
            
            -- hitbox stuff
            local queueHit = task.delay(hitboxProperty.timing, function()
                local hitProperties = {}
                local hits = hitbox:Evaluate(self.player.Character.HumanoidRootPart.CFrame * hitboxProperty.cframe, hitboxProperty.size, true)
                hits = hitbox:FilterSelf(self.player.Character, hits)

                -- clientside hits
                core:PlayHit(self.player.Character, hits)

                -- evaluate conditions
                hitProperties.HitList = hits

                -- serverside stuff
                events.Hit:FireServer(hitProperties, `{script.Parent.Name}/{script.Name}`, chosenVariant, `hit{self.comboString}`)

                -- handle endlag if there is one
                if hitboxProperty.endlag then
                    local conditionFulfilled = hitboxProperty.endlagConditions(hitProperties)
                    if conditionFulfilled then
                        core:Endlag(hitboxProperty.endlag)
                        
                    else
                        task.wait(0.3)
                        moveAnim:AdjustSpeed(12)
                    end
                end
            end)

            -- store thread to a table if we can interrupt this move. core will cancel all threads in this table if stunned
            if hitboxProperty.interruptible then
                table.insert(core.queuedHits, queueHit)
            end
        end
    end
    self.free = true
end

return MoveData