--- Public Variables ---
local MoveData = {}
MoveData.__index = MoveData

--- Private Variables ---

--- Constructor ---
function MoveData.new(context)
    local newMoveData = {}
    setmetatable(newMoveData, MoveData)

    -- hit properties
    newMoveData.hitProperties = {
        hit1 = {
            damage = 5,
            postureDamage = 10,
            stunDuration = 1.5,
            interruptible = true,
            endlag = 0.4,

            cframe = CFrame.new(0,0,-2.5),
            size = Vector3.new(3,3,3),
        },

        hit2 = {
            damage = 5,
            postureDamage = 10,
            stunDuration = 1.5,
            interruptible = true,
            endlag = 0.4,

            cframe = CFrame.new(0,0,-2.5),
            size = Vector3.new(3,3,3),
        },

        hit3 = {
            damage = 5,
            postureDamage = 10,
            stunDuration = 1.5,
            interruptible = true,
            endlag = 0.4,

            cframe = CFrame.new(0,0,-2.5),
            size = Vector3.new(3,3,3),
        },

        hit4 = {
            damage = 5,
            postureDamage = 15,
            stunDuration = 1.5,
            interruptible = true,
            endlag = 1.5,

            cframe = CFrame.new(0,0,-2.5),
            size = Vector3.new(3,3,3),
            variants = {
                downslam = {
                    damage = 5,
                    postureDamage = 0,
                    stunDuration = 2,
                    interruptible = true,

                    endlag = 1.5,
                    endlagCondition = function()

                    end,

                    cframe = CFrame.new(0,-2,-3),
                    size = Vector3.new(3,5,3),
                },

                uppercut = {
                    damage = 5,
                    postureDamage = 15,
                    stunDuration = 2,
                    interruptible = true,

                    endlag = 1.5,
                    endlagCondition = function()

                    end,

                    cframe = CFrame.new(0,2,-3),
                    size = Vector3.new(3,4,3),
                }
            }
        }
    }

    -- move properties
    newMoveData.properties = {

        currentComboString = 1,
        maxComboString = 4,
        comboResetTimer = 4,
    }

    newMoveData.stateTable = {
        lastMoveTick = 0,

    }

    -- references and other important stuff
    newMoveData.context = context

    return newMoveData
end

--- Deconstructor ---

--- Class Functions ---
function MoveData:Work()

end

return MoveData