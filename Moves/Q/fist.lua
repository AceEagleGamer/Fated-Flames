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

MoveData.IsKey = false
MoveData.context = nil

MoveData.animations = {}
MoveData.sounds = {}
MoveData.hitboxQueue = {}

MoveData.player = nil
MoveData.free = true
MoveData.lastSwing = 0

return MoveData