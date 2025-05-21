-- handle loading controllers

--- References ---
local Player = game.Players.LocalPlayer
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events
local packages = rep.Packages

--- Public Variables ---
local root = {}

root.debug = true
root.services = {}

root.playerValues = {}

-- wait for data to load
repeat task.wait() until Player:GetAttribute("DataLoaded") == true -- bad but wtv

-- TODO: Load data stuff here

do
    local initTick = tick()

    for _, service in script:GetChildren() do
        local serviceMod = require(service)
        if root.debug then
            serviceMod.debug = true
        end

        root.services[service.Name] = serviceMod
        serviceMod:Init(root)
    end

    if root.debug then
        print(`[CLIENT] Services loaded in {tick() - initTick}s`)
    end

    initTick = tick()
    for _, service in root.services do
        service:Start()
    end

    if root.debug then
        print(`[CLIENT] Services started in {tick() - initTick}s`)
    end
end

-- let the server know we've loaded
events.PlayerLoaded:FireServer()