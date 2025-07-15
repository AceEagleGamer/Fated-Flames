--- References ---
local cas = game:GetService("ContextActionService")
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events
local moves = rep.Moves
local client = game.Players.LocalPlayer

--- Public Variables ---
local Input = {}
Input.context = nil
Input.LoadAfterCharacterLoads = true

Input.bindings = {}
Input.moveModules = {}
Input.updateFrequency = 0.1 -- in seconds

Input.heldKeys = {
    m1 = false,
    blocking = false,
    jumping = false
}

--- Public Functions ---
function Input:Init(context)
     self.context = context

    local function EvaluateToggleableInput(actionName, inputState)
        self.heldKeys[actionName] = (inputState == Enum.UserInputState.Begin) -- true if active, false if not

        -- https://devforum.roblox.com/t/will-firing-server-many-times-a-second-exceed-the-bandwidth-limit/693011
        -- remotes will automatically drop requests if an exploiter sends too many requests at once. this will probably not affect the server too much like this
        events.UpdateInputToggle:FireServer(self.heldKeys)

        return Enum.ContextActionResult.Pass
    end

    local function EvaluateInput(action, inputState)
        
        local clientCharacter = client.Character
        if clientCharacter == nil or clientCharacter:FindFirstChild("Humanoid") == nil or clientCharacter:FindFirstChild("HumanoidRootPart") == nil then return end

        -- local check for busy and endlag
        if clientCharacter:GetAttribute("Endlag") == true or 
            clientCharacter:GetAttribute("Busy") == true or 
                (self.heldKeys.m1 and clientCharacter:GetAttribute("CanM1") == true) then 
                    return 
        end

        print("can dash")
    end

     -- hook some stuff for the input loop for now
     cas:BindAction(`m1`, EvaluateToggleableInput, false, Enum.UserInputType.MouseButton1)
     cas:BindAction('blocking', EvaluateToggleableInput, false, Enum.KeyCode.F)
     cas:BindAction('jumping', EvaluateToggleableInput, false, Enum.KeyCode.Space)

     -- set bindings temporarily for now
     self.bindings.Q = 'fist'

     -- load move modules on the client
     for key, moveName in self.bindings do
        local targetFolder = moves:FindFirstChild(key)
        if targetFolder == nil then continue end

        local targetModule = targetFolder:FindFirstChild(moveName)
        if targetModule == nil then continue end

        local newMoveData = require(targetModule).new(nil, context)
        self.moveModules[moveName] = newMoveData

        cas:BindAction(`{key}/{moveName}`, EvaluateInput, false, Enum.KeyCode[key])
     end

     -- let the server know we've set our bindings
     events.SetBindings:FireServer(self.bindings)

end

function Input:Start()

end

return Input