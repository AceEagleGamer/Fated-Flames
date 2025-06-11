--[[

    boiler plate code for future reference

]]
--- References ---
local rep = game:GetService("ReplicatedStorage")
local shared = rep.Shared

local localPlayer = game:GetService("Players").LocalPlayer

local moveAnims = rep.MoveAnims
local moveSFX = rep.MoveSFX
local events = rep.Events

--- Public Variables ---
local MoveData = {}

MoveData.properties = {
    cooldown = 0.5,
    damage = 5
}

MoveData.HitboxProperties = {
    hit = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(4,4,5),
        stunDuration = 0.5,
        interruptible = true
    }
}

MoveData.IsKey = false

MoveData.animations = {}
MoveData.sounds = {}

MoveData.player = nil
MoveData.free = true

function MoveData:ResetDefaults()
    -- reset move data basically
end

function MoveData:GetCooldown()

end

function MoveData:Tick()
    -- in case its a combo or something like that. or a successive move thing
end

function MoveData:Init(player, context)
    -- only to get context and maybe some extra setup stuff
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

function MoveData:Work(_, inputState, _inputObj, holdStatus)
    -- the move itself. visuals and hitbox
    if not self.free then return end

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


    end
end

return MoveData