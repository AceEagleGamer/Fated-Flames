-- boilerplate for future moves probably
-- i'd like to make every move modular. i think it will be easier

--- Public Variables ---
local MoveData = {}
MoveData.comboString = 0

MoveData.properties = {
    cooldown = 0.5
}

MoveData.IsKey = false
MoveData.animations = {}
MoveData.player = nil

--- Public Functions
function MoveData:ResetDefaults()
    self.comboString = 0
    self.properties.cooldown = 0.5

    table.clear(self.animations)
    self.player = nil
end

function MoveData:GetCooldown() -- just in case there are "complex" behaviors to the move i guess
    return self.properties.cooldown
end

function MoveData:Tick()
    if self.comboString == 4 then self.comboString = 0 end -- reset
    self.comboString += 1
end

function MoveData:Init(player: Player)
    if not player.Character then warn(`[MoveData] Waiting for character`); player.CharacterAdded:Wait(); return end

    self.player = player
    -- index some important stuff
    local char = player.Character
    local hum = char:WaitForChild("Humanoid")
    local animator = hum:FindFirstChild("Animator")

    -- load anims i guess lol
    print(animator)
end

MoveData.Work = function(_, inputState, _inputObj)
    print(inputState, _inputObj)
end

return MoveData