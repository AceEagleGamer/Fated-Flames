local NPC = {}
NPC.__index = NPC

function NPC.new(template)
    local newNPC = {}
    setmetatable(newNPC, NPC)

    return newNPC
end

return NPC