--- Public Variables ---
local MoveData = {}
MoveData.comboString = 0

MoveData.properties = {
    cooldown = 2,
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

--- Public Functions ---
function MoveData:ResetDefaults()
    -- reset move data basically
end

function MoveData:GetCooldown()
    return 0
end

function MoveData:Tick()
    -- in case its a combo or something like that. or a successive move thing
end

function MoveData:Init(context)
    -- only to get context and maybe some extra setup stuff
    self.context = context
end

function MoveData:Work(_, inputState, _inputObj)
    -- the move itself. visuals and hitbox
    print("test")
end

return MoveData