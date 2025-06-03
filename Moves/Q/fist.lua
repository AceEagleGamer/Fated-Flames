--- References ---
local rep = game:GetService("ReplicatedStorage")
local run = game:GetService("RunService")
local shared = rep.Shared

local localPlayer = game:GetService("Players").LocalPlayer

local moveAnims = rep.MoveAnims
local moveSFX = rep.MoveSFX
local events = rep.Events
local camera = workspace.CurrentCamera

local gameSettings = UserSettings().GameSettings

--- Packages ---
local hitbox = require(shared.hitbox)

--- Public Variables ---
local MoveData = {}
MoveData.direction = 0

MoveData.properties = {
    cooldown = 2,
    forwardCD = 4,
    damage = 5
}

MoveData.HitboxProperties = {
    forwardHit = {
        timing = 0.25,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(4,4,5),
        stunDuration = 0.5,
        interruptible = true
    },
}

MoveData.IsKey = true
MoveData.context = nil

MoveData.animations = {}
MoveData.sounds = {}
MoveData.hitboxQueue = {}

MoveData.player = nil
MoveData.free = true
MoveData.lastSwing = 0

--- Private Functions ---
local function EvaluateDir()
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("Humanoid") or localPlayer.Character.Humanoid.Health <= 0 then return end
    local hum = localPlayer.Character.Humanoid
    local MoveDirection = camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
        
    -- evaluate direction
    local dir = nil
    if math.round(MoveDirection.X) == -1 then dir = "left" end
    if math.round(MoveDirection.X) == 1 then dir = "right" end
    if math.round(MoveDirection.Z) == -1 then dir = "front" end
    if math.round(MoveDirection.Z) == 1 then dir = "back"end
    if dir == nil then dir = "front" end

    return dir
end

--- Public Functions ---
function MoveData:ResetDefaults()
    -- reset move data basically
end

function MoveData:GetCooldown()
    return if run:IsServer() then self.properties.forwardCD else 
        (if EvaluateDir() == "front" then self.properties.forwardCD else self.properties.cooldown) -- really odd. but a workaround is a workaround
end

function MoveData:Tick()
    -- in case its a combo or something like that. or a successive move thing
end

function MoveData:Init(player: Player, context)
    -- only to get context and maybe some extra setup stuff
    if not localPlayer.Character then warn(`[MoveData] Waiting for character`); localPlayer.CharacterAdded:Wait(); return end
    gameSettings.RotationType = Enum.RotationType.MovementRelative

    self.context = context
    self.player = localPlayer
    self.endlagging = false

    -- index some important stuff
    local char = localPlayer.Character
    local hum = char:WaitForChild("Humanoid")
    local animator: Animator = hum:FindFirstChild("Animator")

    -- create attachment for linear velocity
    local velHolder = Instance.new("Attachment", char.HumanoidRootPart)
    local linearVel = Instance.new("LinearVelocity", velHolder)
    linearVel.Enabled = false
    
    -- load anims i guess lol
    local anims = moveAnims.Q.fist:GetChildren()
    for _, anim in anims do
        self.animations[anim.Name] = animator:LoadAnimation(anim)
    end

    -- index sounds
    local sounds = moveSFX.Q.fist:GetChildren()
    for _, sound in sounds do
        self.sounds[sound.Name] = sound
    end

end

function MoveData:Work(_, inputState, _inputObj)
    -- the move itself. visuals and hitbox
    if not self.free then return end
    --self.free = false

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

        -- evaluate dir
        local dir = EvaluateDir()
        
        if dir == "front" then
            -- TODO: this

        else
            gameSettings.RotationType = Enum.RotationType.CameraRelative
        end
    end
end

return MoveData