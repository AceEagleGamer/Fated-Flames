-- idk
local Hitbox = {}
local rep = game:GetService("ReplicatedStorage")
local debugHitbox = rep.DebugHitbox

function Hitbox:Evaluate(cframe: CFrame, size: Vector3, isDebug: boolean)

    if not workspace:FindFirstChild("PlayerCharacters") then warn("How"); return end
    
    local overLap = OverlapParams.new()
    overLap.FilterType = Enum.RaycastFilterType.Include
    overLap.FilterDescendantsInstances = {workspace.PlayerCharacters, workspace.NPCs}

    if isDebug then
        local new = debugHitbox:Clone()
        new.CFrame = cframe
        new.Size = size
        new.Parent = workspace.DebugFolder

        game:GetService("Debris"):AddItem(new, 1)
    end

    local hits = workspace:GetPartBoundsInBox(cframe, size, overLap)

    return hits
end

function Hitbox:FilterSelf(excludeCharacter: Model, hitTable)
    local hits = {}
    local exclusionTable = {}
    for _, part in hitTable do
        if part:FindFirstAncestor(excludeCharacter.Name) then continue end
        if table.find(exclusionTable, part.Parent) then continue end
        table.insert(exclusionTable, part.Parent)
        table.insert(hits, part.Parent)
    end

    return hits
end

return Hitbox