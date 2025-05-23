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
    comboStringReset = 1.5
}

MoveData.HitboxProperties = {
    hit1 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(4,4,5)
    },
    hit2 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(4,4,5)
    },
    hit3 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(4,4,5)
    },
    hit4 = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(4,4,5)
    },
}

MoveData.IsKey = false
MoveData.animations = {}
MoveData.sounds = {}
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

function MoveData:Init(player: Player)
    if not player.Character then warn(`[MoveData] Waiting for character`); player.CharacterAdded:Wait(); return end

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
            task.delay(hitboxProperty.timing, function()
                local hits = hitbox:Evaluate(self.player.Character.HumanoidRootPart.CFrame * hitboxProperty.cframe, hitboxProperty.size, true)
                hits = hitbox:FilterSelf(self.player.Character, hits)

                -- clientside hits
                
                -- do serverside things
                events.Hit:FireServer(hits, `{script.Parent.Name}/{script.Name}`)
            end)
        end
    end
    self.free = true
end

return MoveData