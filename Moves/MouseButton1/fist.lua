-- boilerplate for future moves probably
-- i'd like to make every move modular. i think it will be easier

--- References ---
local rep = game:GetService("ReplicatedStorage")
local moveAnims = rep.MoveAnims
local events = rep.Events

--- Public Variables ---
local MoveData = {}
MoveData.comboString = 0

MoveData.properties = {
    cooldown = 0.5,
    endCD = 1
}

MoveData.IsKey = false
MoveData.animations = {}
MoveData.player = nil
MoveData.free = true

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
end

MoveData.Work = function(_, inputState, _inputObj)
    if not MoveData.free then return end
    MoveData.free = false
    if inputState == Enum.UserInputState.Begin then
         
        -- request the server for a move
        local moveGranted = events.RequestMove:InvokeServer(script.Parent.Name, script.Name) -- takes move folder and move name, returns true or false
        if moveGranted then
            MoveData:Tick()
            
        end
    end
    MoveData.free = true
end

return MoveData