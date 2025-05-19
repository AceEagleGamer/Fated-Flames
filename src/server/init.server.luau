
-- handle loading each service/controller. assume each service/controller has a load function
local root = {}

root.services = {}
root.debug = true

do

    -- for debug purposes
    local initTick = tick()

    -- register services into the table. might be useful if other scripts want
    -- to interact with any services
    debug.profilebegin('Indexing Services')
    for _, service in script:GetChildren() do
        local serviceMod = require(service)
        if root.debug then
            serviceMod.debug = true
        end
        
        local ServiceDataType = {
            name = service.Name,
            payload = serviceMod
        }

        if serviceMod.loadPriority then
            root.services[serviceMod.loadPriority] = ServiceDataType
        else
            table.insert(root.services, ServiceDataType)
        end
    end
    debug.profileend()

    -- initialize then start the services based on priority. This sucks but i dont care
    for i = 1, #script:GetChildren() do
        local service = root.services[i]
        
        debug.profilebegin(service.name)
        service.payload:Init(root)
        service.payload:Start()
        debug.profileend()
    end
    
    if root.debug then
        print(`{#script:GetChildren()} services loaded in {tick() - initTick}s`)
    end
end