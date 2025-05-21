--- References ---
local Player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local cas = game:GetService("ContextActionService")

--- Public Variables ---
local Input = {}
Input.context = nil

Input.bindings = {}

--- Public Functions ---
function Input:Init(context)
    self.context = context

    -- TODO: load actual bindings here
    Input.bindings.MouseOne = "fist"
end

function Input:Start()

    -- test i guess
    
end

return Input