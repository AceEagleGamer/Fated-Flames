--- References ---
local cas = game:GetService("ContextActionService")
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events

--- Public Variables ---
local Input = {}
Input.context = nil
Input.LoadAfterCharacterLoads = true

Input.bindings = {}
Input.connections = {}
Input.threads = {}
Input.updateFrequency = 0.1 -- in seconds

Input.heldKeys = {
    m1 = false,
    blocking = false,
    jumping = false
}

--- Private Functions
function EvaluateToggleableInput(actionName, inputState)
    Input.heldKeys[actionName] = (inputState == Enum.UserInputState.Begin) -- true if active, false if not

    -- https://devforum.roblox.com/t/will-firing-server-many-times-a-second-exceed-the-bandwidth-limit/693011
    -- remotes will automatically drop requests if an exploiter sends too many requests at once. this will probably not affect the server too much like this
    events.UpdateInputToggle:FireServer(Input.heldKeys)

    return Enum.ContextActionResult.Pass
end

--- Public Functions ---
function Input:Init(context)
    self.context = context

    -- hook some stuff for the input loop for now
    cas:BindAction(`m1`, EvaluateToggleableInput, false, Enum.UserInputType.MouseButton1)
    cas:BindAction('blocking', EvaluateToggleableInput, false, Enum.KeyCode.F)
    cas:BindAction('jumping', EvaluateToggleableInput, false, Enum.KeyCode.Space)

    -- set bindings temporarily for now
    self.bindings.Q = 'fist'

    events.SetBindings:FireServer(self.bindings)

    -- load move modules on the client


end

function Input:Start()

end

return Input