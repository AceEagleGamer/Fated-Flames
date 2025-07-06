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

Input.inputToggleQueue = {}
Input.heldKeys = {
    m1 = false,
    blocking = false,
}

--- Private Functions
function EvaluateToggleableInput(actionName, inputState)
    Input.heldKeys[actionName] = (inputState == Enum.UserInputState.Begin) -- true if active, false if not

    -- https://devforum.roblox.com/t/will-firing-server-many-times-a-second-exceed-the-bandwidth-limit/693011
    -- remotes will automatically drop requests if an exploiter sends too many requests at once. this will probably not affect the server too much like this
    events.UpdateInputToggle:FireServer(Input.heldKeys)
end

--- Public Functions ---
function Input:Init(context)
    self.context = context

    -- hook some stuff for the input loop for now
    cas:BindAction(`m1`, EvaluateToggleableInput, false, Enum.UserInputType.MouseButton1)
    cas:BindAction('blocking', EvaluateToggleableInput, false, Enum.KeyCode.F)

end

function Input:Start()

end

return Input