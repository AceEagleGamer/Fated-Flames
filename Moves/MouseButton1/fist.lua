-- boilerplate for future moves probably
-- i'd like to make every move modular. i think it will be easier

--- References ---
local rep = game:GetService("ReplicatedStorage")
local shared = rep.Shared

local moveAnims = rep.MoveAnims
local moveSFX = rep.MoveSFX
local events = rep.Events

--- Packages ---
local hitbox = require(shared.hitbox)

--- Public Variables ---
local MoveData = {}
MoveData.comboString = 0

MoveData.properties = {
    cooldown = 0.5,
    endCD = 1.5,
    comboStringReset = 1,
    damage = 5
}

MoveData.HitboxProperties = {
    hit0 = { --[[ catch for nil. dont ask ]]},
    hit1 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(4,4,5),
        stunDuration = 0.5,
        interruptible = true,
    },
    hit2 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(4,4,5),
        stunDuration = 0.5,
        interruptible = true
    },
    hit3 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(4,4,5),
        stunDuration = 0.5,
        interruptible = true
    },
    hit4 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(4,4,5),
        interruptible = true,
        canJump = true,

        endlag = 1.5,
        endlagConditions = function(hitProperties)
            return #hitProperties.HitList == 0
        end,

        ragdolls = true,
        ragdollProperties = {
            knockbackStrength = 75,
            duration = 1
        }
    },
}

MoveData.IsKey = false

MoveData.animations = {}
MoveData.sounds = {}
MoveData.hitboxQueue = {}

MoveData.player = nil
MoveData.free = true
MoveData.lastSwing = 0

--- Public Functions ---
function MoveData:ResetDefaults()
    self.comboString = 0
    self.properties.cooldown = 0.5

    table.clear(self.animations)
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

function MoveData:Init(player: Player, context)
    if not player.Character then warn(`[MoveData] Waiting for character`); player.CharacterAdded:Wait(); return end

    self.context = context
    self.player = player

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

function MoveData:Work(_, inputState, _inputObj)
    if not self.free then return end
    self.free = false

    local core = self.context.services.core
    local playerState = core.playerState
    if playerState.endlag then self.free = true; return end

    if inputState == Enum.UserInputState.Begin then
         
        -- request the server for a move
        local moveGranted = events.RequestMove:InvokeServer(script.Parent.Name, script.Name) -- takes move folder and move name, returns true or false
        if moveGranted then
            self:Tick()

            -- stop previous anim (idk if this does anything)
            if self.animations[`hit{self.comboString - 1}`] then self.animations[`hit{self.comboString - 1}`]:Stop() end
            
            -- play vfx stuff
            self.animations[`hit{self.comboString}`]:Play()
            self.sounds[`hit{self.comboString}`]:Play()
            
            -- hitbox stuff
            local hitboxProperty = self.HitboxProperties[`hit{self.comboString}`]
            local queueHit = task.delay(hitboxProperty.timing, function()
                local hitProperties = {}
                local hits = hitbox:Evaluate(self.player.Character.HumanoidRootPart.CFrame * hitboxProperty.cframe, hitboxProperty.size, true)
                hits = hitbox:FilterSelf(self.player.Character, hits)

                -- clientside hits
                core:PlayHit(hits)

                -- fill in hit properties
                -- evaluate conditions
                hitProperties.HitList = hits

                -- handle endlag if there is one
                if hitboxProperty.endlag then
                    local conditionFulfilled = hitboxProperty.endlagConditions(hitProperties)
                    if conditionFulfilled then
                        core:Endlag(hitboxProperty.endlag)
                    end

                end

                -- serverside stuff
                events.Hit:FireServer(hitProperties, `{script.Parent.Name}/{script.Name}`)
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