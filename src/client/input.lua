--- References ---
local player = game.Players.LocalPlayer
local cas = game:GetService("ContextActionService")
local run = game:GetService("RunService")
local rep = game:GetService("ReplicatedStorage")
--local uis = game:GetService("UserInputService")
local moves = rep.Moves

--- Public Variables ---
local Input = {}
Input.context = nil

Input.LoadAfterCharacterLoads = true
Input.bindings = {}
Input.connections = {}
Input.moveModules = {}
Input.CDTable = {}

Input.M1Properties = {
    moveName = nil,
    moveMod = nil
}
Input.holdingM1 = false

--- Private Functions ---
local function EvaluateMoveInput(actionName, inputState, _inputObj)
    -- only handle if we're at the beginning of an input
    if inputState ~= Enum.UserInputState.Begin then return end

    -- check if our character is alive
    if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then return end
    local playerChar = player.Character

    -- dont go if we're stunned or endlagged (is that the corect term)
    local core = Input.context.services.core
    if playerChar:GetAttribute("Stunned") == true or core.playerState.endlag then return end

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
    moveMod:Work(actionName, inputState, _inputObj)
end

local function EvaluateM1(_, inputState, _inputObj)
    Input.holdingM1 = inputState == Enum.UserInputState.Begin
end

--- Public Functions ---
function Input:Init(context)
    self.context = context

    -- TODO: load actual bindings here
    Input.bindings.MouseButton1 = "fist"
    Input.bindings.F = "fistblock"
    Input.bindings.Q = "fistdash"
    
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
        
        -- bind it via context action service
        if self.connections[key] == nil then -- catch for nil. create the table ourselves
            self.connections[key] = {}
        end
        
        -- non m1 moves
        if moveMod.IsKey then
            self.connections[`{key}/{move}`] = cas:BindAction(`{key}/{move}`, EvaluateMoveInput, false, Enum.KeyCode[key])
        else -- assume this is an m1 move
            self.connections[`{key}/{move}`] = cas:BindAction(`{key}/{move}`, EvaluateM1, false, Enum.UserInputType.MouseButton1)
            self.M1Properties.moveMod = moveMod
            self.M1Properties.moveName = `{key}/{move}`
        end
     end

    -- reset move mods on death
     self.connections.characterLoaded = player.CharacterAdded:Connect(function(char)

        -- loop through movemods and call ResetDefaults and Init
        for _, moveMod in self.moveModules do

            moveMod:ResetDefaults()
            moveMod:Init(player, context)
        end
        
     end)
end

function Input:Start()

     -- m1 loop
     self.connections.m1Loop = run.RenderStepped:Connect(function(dt)
        if self.holdingM1 then
            
            -- check cd
            local moveMod = self.M1Properties.moveMod
            local cd = moveMod:GetCooldown()
            
            -- dont go if we're below cd
            if tick() - moveMod.lastSwing < cd then return end
           EvaluateMoveInput(self.M1Properties.moveName, Enum.UserInputState.Begin)
        end
     end)
end

return Input