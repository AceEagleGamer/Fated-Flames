
-- handle loading each service/controller. assume each service/controller has a load function
local root = {}

root.services = {}
root.debug = true

do

    -- for debug purposes
    local initTick = tick()

    -- register services into the table. might be useful if other scripts want
    -- to interact with any services
    for _, service in script:GetChildren() do
        local serviceMod = require(service)
        if root.debug then
            serviceMod.debug = true
        end

        root.services[service.Name] = serviceMod
        serviceMod:Init(root)

    end

    if root.debug then
        print(`{#script:GetChildren()} services initiated in {tick() - initTick}s`)
    end

    -- start the services
    initTick = tick()
    for _, service in root.services do
        service:Start()
    end

    if root.debug then
        print(`{#script:GetChildren()} services started in {tick() - initTick}s`)
    end
end