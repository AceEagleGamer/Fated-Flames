-- handle loading controllers

--- References ---
local Player = game.Players.LocalPlayer
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events
local packages = rep.Packages

--- Public Variables ---
local root = {}

root.services = {}
root.controllers = {}

-- wait for data to load
repeat task.wait() until Player:GetAttribute("DataLoaded") == true

do

end

-- let the server know we've loaded
events.PlayerLoaded:FireServer()