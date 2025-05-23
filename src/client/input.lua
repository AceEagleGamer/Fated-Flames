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

--- Private Function ---


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
        if self.moveModules[key] == nil then -- catch for nil. create the table ourselves
            self.moveModules[key] = {}
        end
        self.moveModules[key][move] = require(moveMod)
        moveMod = self.moveModules[key][move]
        
        moveMod:Init(player)
        moveMod:ResetDefaults()
        
        -- bind it via context action service
        if self.connections[key] == nil then -- catch for nil. create the table ourselves
            self.connections[key] = {}
        end
        
        -- why
        self.connections[key][move] = cas:BindAction(`{key}/{move}`, moveMod.Work, false, if moveMod.IsKey then Enum.KeyCode[key] else Enum.UserInputType[key])
     end
end

return Input