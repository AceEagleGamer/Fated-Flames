--- References ---
local player = game.Players.LocalPlayer
local cas = game:GetService("ContextActionService")
local run = game:GetService("RunService")
local rep = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
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

Input.heldKeys = {
    m1 = false,
    space = false
}

Input.moving = false

--- Private Functions ---
local function EvaluateMoveInput(actionName, inputState, _inputObj)
    -- only handle if we're at the beginning of an input
    if inputState ~= Enum.UserInputState.Begin then return end

    -- check if our character is alive
    if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then return end
    local playerChar = player.Character

    -- dont go if we're stunned or endlagged (is that the corect term)
    local core = Input.context.services.core
    if playerChar:GetAttribute("Stunned") == true or core.playerState.endlag or playerChar:GetAttribute("IsRagdoll") == true then return end

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

    -- check if we have a valid variant
    local variantChosen = nil
    if moveMod.properties.variants then
        for variantName, variantData in moveMod.properties.variants do
            if variantData.conditionFulfilled() then
                variantChosen = {name = variantName, data = variantData}
                break
            end
        end
    end

    -- check if we have a valid CD table
    local CDName = nil
    if not variantChosen then
        if not Input.CDTable[`{moveFolder}/{moveName}`] then
            Input.CDTable[`{moveFolder}/{moveName}`] = 0
        end
        CDName = `{moveFolder}/{moveName}`
    else
        if not Input.CDTable[`{moveFolder}/{moveName}/{variantChosen.name}`] then
            Input.CDTable[`{moveFolder}/{moveName}/{variantChosen.name}`] = 0
        end
        CDName = `{moveFolder}/{moveName}/{variantChosen.name}`
    end

    -- check if the move module is free
    if not moveMod.free then return end

    -- check if we're off cooldown
    local cd, extraData = moveMod:GetCooldown()
    if tick() - Input.CDTable[CDName] < cd then return end
    Input.CDTable[CDName] = tick()

    -- run the move module
    moveMod:Work(actionName, inputState, _inputObj, extraData)
end

local function EvaluateM1(_, inputState, _inputObj)
    Input.heldKeys.m1 = inputState == Enum.UserInputState.Begin
    return Enum.ContextActionResult.Pass
end

local function EvaluateSpace(_, inputState, _inputObj)
    Input.heldKeys.space = inputState == Enum.UserInputState.Begin
    return Enum.ContextActionResult.Pass
end

local function SetJumpPower(jp)

    local char = player.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    if Input.context.services.core.playerState.endlag then return end

    char.Humanoid.JumpPower = jp
end

--- Public Functions ---
function Input:Init(context)
    self.context = context

    -- TODO: load actual bindings here
    Input.bindings.MouseButton1 = "fist"
    Input.bindings.F = "fistblock"
    Input.bindings.Q = "fist"
    
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
            cas:BindAction(`{key}/{move}`, EvaluateMoveInput, false, Enum.KeyCode[key])
        else -- assume this is an m1 move
            cas:BindAction(`{key}/{move}`, EvaluateM1, false, Enum.UserInputType.MouseButton1)
            self.M1Properties.moveMod = moveMod
            self.M1Properties.moveName = `{key}/{move}`
        end
    end

    -- for spacebar
    cas:BindAction('EvaluateJump', EvaluateSpace, false, Enum.KeyCode.Space)

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
     -- input loop
     self.connections.inputLoop = run.Heartbeat:Connect(function(dt)

        if self.heldKeys.m1 then
            -- check cd
            local moveMod = self.M1Properties.moveMod
            local hitboxProperty = moveMod.HitboxProperties
            local cd = moveMod:GetCooldown()

            -- dont go if we're below cd
            if tick() - moveMod.lastSwing >= cd and not self.moving then
                EvaluateMoveInput(self.M1Properties.moveName, Enum.UserInputState.Begin)

                SetJumpPower(if hitboxProperty[`hit{moveMod.comboString}`].canJump then 50 else 0)
            end

        else
            if self.moving then SetJumpPower(0); return end
            SetJumpPower(50)
        end
     end)
end

return Input