
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
        root.services[service.Name] = require(service)
         if root.debug then
            root.services[service.Name].debug = true
         end
        root.services[service.Name]:Init(root) -- assume every service has an Init
    end
    
    if root.debug then
        print(`{#script:GetChildren()} services loaded in {tick() - initTick}s`)
    end

    -- start each service
    initTick = tick()
    for _, service in root.services do
        service:Start() -- assume every service has a Start
    end

    if root.debug then
        print(`{#script:GetChildren()} services started in {tick() - initTick}s`)
    end
end