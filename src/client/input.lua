--- References ---
local player = game.Players.LocalPlayer
local cas = game:GetService("ContextActionService")

local rep = game:GetService("ReplicatedStorage")
local moves = rep.Moves

--- Public Variables ---
local Input = {}
Input.context = nil

Input.LoadAfterCharacterLoads = true
Input.bindings = {}
Input.connections = {}
Input.moveModules = {}
Input.CDTable = {}

--- Private Function ---
local function EvaluateMoveInput(actionName, inputState, _inputObj)

    if inputState ~= Enum.UserInputState.Begin then return end

    -- get move
    local parseMoveName = string.split(actionName, '/')
    local moveFolder = parseMoveName[1]
    local moveName = parseMoveName[2]

    -- check if it exists
    if not moves:FindFirstChild(moveFolder) then return end
    if not moves[moveFolder]:FindFirstChild(moveName) then return end

    -- check if we have a move module recorded
    local moveMod = Input.moveModules[`{moveFolder}/{moveName}`]
    if not moveMod then warn(`{moveFolder}/{moveName} does not have a valid move module`); return end

    -- check if we have a valid CD table
    if not Input.CDTable[`{moveFolder}/{moveName}`] then
        Input.CDTable[`{moveFolder}/{moveName}`] = 0
    end

    -- check if we're off cooldown
    local cd = moveMod:GetCooldown()
    if tick() - Input.CDTable[`{moveFolder}/{moveName}`] < cd then return end
    Input.CDTable[`{moveFolder}/{moveName}`] = tick()

    -- run the move module
    moveMod.Work(actionName, inputState, _inputObj)
end

--- Public Functions ---
function Input:Init(context)
    self.context = context

    -- TODO: load actual bindings here
    Input.bindings.MouseButton1 = "fist"
end

function Input:Start()

    -- test i guess
     for key, move in self.bindings do
        -- get the move module
        local moveBranch = moves:FindFirstChild(key)
        if not moveBranch then warn(`{key} move branch does not exist for {move}`); continue end

        local moveMod = moveBranch:FindFirstChild(move)
        if not moveMod then warn(`{move} does not exist in {key}`); continue end

        -- initialize the move module
        self.moveModules[`{key}/{move}`] = require(moveMod)
        moveMod = self.moveModules[`{key}/{move}`]
        
        moveMod:Init(player)
        moveMod:ResetDefaults()
        
        -- bind it via context action service
        if self.connections[key] == nil then -- catch for nil. create the table ourselves
            self.connections[key] = {}
        end
        
        -- why
        self.connections[`{key}/{move}`] = cas:BindAction(`{key}/{move}`, EvaluateMoveInput, false, if moveMod.IsKey then Enum.KeyCode[key] else Enum.UserInputType[key])
     end
end

return Input