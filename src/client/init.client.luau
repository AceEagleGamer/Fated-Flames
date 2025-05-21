-- handle loading controllers

--- References ---
local Player = game.Players.LocalPlayer
local rep = game:GetService("ReplicatedStorage")
local events = rep.Events
local packages = rep.Packages

--- Private Variables ---
local servicesToLoadAfterCharacter = {}

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
    for serviceName, service in root.services do
        if not service.LoadAfterCharacterLoads then
            service:Start()
        else
            table.insert(servicesToLoadAfterCharacter, serviceName)
        end
    end

    if root.debug then
        print(`[CLIENT] Services started in {tick() - initTick}s`)
    end
end

-- let the server know we've loaded
events.PlayerLoaded:FireServer()
Player:GetAttributeChangedSignal("CharacterLoaded"):Wait()

-- load the rest
do
    local initTick = tick()
    for _, serviceName in servicesToLoadAfterCharacter do

        -- find the service
        local service = root.services[serviceName]
        if not service then warn(`how did you index {service} when it doesnt exist`); continue end

        -- start it NOW
        service:Start()
    end

        if root.debug then
        print(`[CLIENT] Additional services started in {tick() - initTick}s`)
    end
end