--- References ---
local rep = game:GetService("ReplicatedStorage")
local run = game:GetService("RunService")
local twn = game:GetService("TweenService")
local shared = rep.Shared

local localPlayer = game:GetService("Players").LocalPlayer

local moveAnims = rep.MoveAnims
local moveSFX = rep.MoveSFX
local events = rep.Events
local camera = workspace.CurrentCamera

local gameSettings = UserSettings().GameSettings

--- Packages ---
local hitbox = require(shared.hitbox)

--- Public Variables ---
local MoveData = {}
MoveData.direction = 0

MoveData.properties = {
    cooldown = 2,
    canMoveAgain = 0.5,
    damage = 5,
    variants = {
        front = {
            cooldown = 4,
            canMoveAgain = 1.15,
            conditionFulfilled = function()
                -- an exact copy paste of the function below but i wasnt moving the entire script so i can call the function
                if not localPlayer.Character or not localPlayer.Character:FindFirstChild("Humanoid") or localPlayer.Character.Humanoid.Health <= 0 then return end
                local hum = localPlayer.Character.Humanoid
                local MoveDirection = camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
                    
                -- evaluate direction
                local dir = nil
                if math.round(MoveDirection.X) == -1 then dir = "left" end
                if math.round(MoveDirection.X) == 1 then dir = "right" end
                if math.round(MoveDirection.Z) == -1 then dir = "front" end
                if math.round(MoveDirection.Z) == 1 then dir = "back"end
                if dir == nil then dir = "front" end

                return dir == "front"
            end,
        }
    }
}

MoveData.HitboxProperties = {
    front = {
        timing = 0.8,
        cframe = CFrame.new(0,0,-2.5),
        size = Vector3.new(3,3,3),
        stunDuration = 0.5,
        interruptible = false,

        endlag = 1.5,
        endlagConditions = function(hitProperties)
            return #hitProperties.HitList == 0
        end,
    },
}

MoveData.IsKey = true
MoveData.context = nil

MoveData.animations = {}
MoveData.sounds = {}
MoveData.hitboxQueue = {}

MoveData.player = nil
MoveData.free = true
MoveData.lastSwing = 0
MoveData.OutOfDash = Instance.new("BindableEvent")

--- Private Functions ---
local function EvaluateDir()
    if run:IsServer() then return end -- sigh
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("Humanoid") or localPlayer.Character.Humanoid.Health <= 0 then return end
    local hum = localPlayer.Character.Humanoid
    local MoveDirection = camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
        
    -- evaluate direction
    local dir = nil
    if math.round(MoveDirection.X) == -1 then dir = "left" end
    if math.round(MoveDirection.X) == 1 then dir = "right" end
    if math.round(MoveDirection.Z) == -1 then dir = "front" end
    if math.round(MoveDirection.Z) == 1 then dir = "back"end
    if dir == nil then dir = "front" end

    return dir
end

local function QueueDash(dir, char, dashStrength, linearVel)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local function checkInFront()
        local hrp = char.HumanoidRootPart
        local ray = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 3, raycastParams)

        if ray then
            if ray.Instance:FindFirstAncestor("NPCs") or ray.Instance:FindFirstAncestor("PlayerCharacters") then return true end
        end
        return false
    end

    return task.spawn(function()
        local hrp = char.HumanoidRootPart
        if dir == "left" then
            while run.RenderStepped:Wait() do
                linearVel.VectorVelocity = Vector3.new(-hrp.CFrame.RightVector.X * dashStrength.Value, 0, -hrp.CFrame.RightVector.Z * dashStrength.Value)
            end
        elseif dir == "right" then
            while run.RenderStepped:Wait() do
                linearVel.VectorVelocity = Vector3.new(hrp.CFrame.RightVector.X * dashStrength.Value, 0, hrp.CFrame.RightVector.Z * dashStrength.Value)
            end
        elseif dir == "back" then
            while run.RenderStepped:Wait() do
                linearVel.VectorVelocity = Vector3.new(-hrp.CFrame.LookVector.X * dashStrength.Value, 0, -hrp.CFrame.LookVector.Z * dashStrength.Value)
            end
        elseif dir == "front" then
            while run.RenderStepped:Wait() do
                linearVel.VectorVelocity = Vector3.new(hrp.CFrame.LookVector.X * dashStrength.Value, 0, hrp.CFrame.LookVector.Z * dashStrength.Value)
                if checkInFront() then print("braking"); break end
            end
        end
        MoveData.OutOfDash:Fire()
    end)
end

--- Public Functions ---
function MoveData:ResetDefaults()
    -- reset move data basically
end

function MoveData:GetCooldown(variant)
    return if variant == "front" then self.properties.variants.front.cooldown else 
        (if run:IsServer() then self.properties.forwardCD else 
            (if EvaluateDir() == "front" then self.properties.variants.front.cooldown else self.properties.cooldown)), EvaluateDir() -- really odd. but a workaround is a workaround
end

function MoveData:Tick()
    -- in case its a combo or something like that. or a successive move thing
end

function MoveData:Init(player: Player, context)
    -- only to get context and maybe some extra setup stuff
    if not localPlayer.Character then warn(`[MoveData] Waiting for character`); localPlayer.CharacterAdded:Wait(); return end
    gameSettings.RotationType = Enum.RotationType.MovementRelative

    self.context = context
    self.player = localPlayer
    self.endlagging = false

    -- index some important stuff
    local char = localPlayer.Character
    local hum = char:WaitForChild("Humanoid")
    local animator: Animator = hum:FindFirstChild("Animator")

    -- create attachment for linear velocity
    local velHolder = Instance.new("Attachment", char.HumanoidRootPart)
    local linearVel = Instance.new("LinearVelocity", velHolder)
    linearVel.Enabled = false
    linearVel.Attachment0 = velHolder
    linearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    linearVel.MaxAxesForce = Vector3.new(math.huge, 0, math.huge)
    
    -- load anims i guess lol
    local anims = moveAnims.Q.fist:GetChildren()
    for _, anim in anims do
        self.animations[anim.Name] = animator:LoadAnimation(anim)
    end

    -- index sounds
    local sounds = moveSFX.Q.fist:GetChildren()
    for _, sound in sounds do
        self.sounds[sound.Name] = sound
    end

end

function MoveData:Work(_, inputState, _inputObj, extraData)
    -- the move itself. visuals and hitbox
    if not self.free then return end
    --self.free = false

    local core = self.context.services.core
    local input = self.context.services.input
    local playerState = core.playerState
    if playerState.endlag then self.free = true; return end

    -- if we're already moving dont go
    if input.moving then return end

    -- check if we're alive and existing
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then self.free = true; return end

    if inputState == Enum.UserInputState.Begin then

        local dir = extraData -- supplied by getting the cd. odd but whatever
        
        if dir == "front" then
            local moveGranted = events.RequestMove:InvokeServer(script.Parent.Name, script.Name, dir) -- takes move folder and move name, returns true or false
            if moveGranted then
                -- moving logic
                input.moving = true
                local frontProperties = self.properties.variants.front

                -- prep linear velocity for dash
                local linearVel = char.HumanoidRootPart.Attachment.LinearVelocity
                linearVel.Enabled = true

                -- dash stuff
                local dashStrength = Instance.new("NumberValue")
                dashStrength.Value = 60

                local dashDecay = twn:Create(dashStrength, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {Value = 0})
                dashDecay:Play()

                local dashUpdateLoop = QueueDash(dir, char, dashStrength, linearVel)

                -- play anim and rotate character accordingly
                self.animations["front_windup"]:Play()
                self.sounds.dash:Play()
                gameSettings.RotationType = Enum.RotationType.CameraRelative

                -- handles end of dash
                local endofDash = false
                task.delay(frontProperties.canMoveAgain, function()
                    if dashUpdateLoop then
                        task.cancel(dashUpdateLoop)
                        self.OutOfDash:Fire()
                    end
                    endofDash = true
                    linearVel.Enabled = false
                    gameSettings.RotationType = Enum.RotationType.MovementRelative
                    input.moving = false -- handle it here cuz we're handling everything else here anyway
                end)

                self.OutOfDash.Event:Wait() -- end of dash or ending early
                self.animations["front_windup"]:Stop()
                self.animations["front_hit"]:Play()

                if not endofDash then
                    linearVel.Enabled = false
                    char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0) -- reset velocity
                    gameSettings.RotationType = Enum.RotationType.MovementRelative
                    input.moving = false -- handle it here cuz we're handling everything else here anyway
                end

                -- hitbox troll
                local hitboxProperty = self.HitboxProperties.front
                local hitProperties = {}
                local hits = hitbox:Evaluate(self.player.Character.HumanoidRootPart.CFrame * hitboxProperty.cframe, hitboxProperty.size, true)
                hits = hitbox:FilterSelf(self.player.Character, hits)

                -- clientside hits
                core:PlayHit(hits)

                -- evaluate conditions
                hitProperties.HitList = hits

                -- serverside stuff
                events.Hit:FireServer(hitProperties, `{script.Parent.Name}/{script.Name}`, nil, dir)

                -- handle endlag if there is one
                if hitboxProperty.endlag then
                    local conditionFulfilled = hitboxProperty.endlagConditions(hitProperties)
                    if conditionFulfilled then
                        core:Endlag(hitboxProperty.endlag)
                        
                    else
                        task.wait(0.3)
                        self.animations[dir]:AdjustSpeed(12)
                    end
                end
            end
        else

            -- moving logic
            input.moving = true

            -- prep linear velocity for dash
            local linearVel = char.HumanoidRootPart.Attachment.LinearVelocity
            linearVel.Enabled = true

            -- dash stuff
            local dashStrength = Instance.new("NumberValue")
            dashStrength.Value = 75

            local dashDecay = twn:Create(dashStrength, TweenInfo.new(self.properties.canMoveAgain, Enum.EasingStyle.Linear), {Value = 0})
            dashDecay:Play()

            local dashUpdateLoop = QueueDash(dir, char, dashStrength, linearVel)

            -- play anim and rotate character accordingly
            self.animations[dir]:Play()
            self.sounds.dash:Play()
            gameSettings.RotationType = Enum.RotationType.CameraRelative

            task.delay(self.properties.canMoveAgain, function()
                task.cancel(dashUpdateLoop)
                linearVel.Enabled = false
                gameSettings.RotationType = Enum.RotationType.MovementRelative
                input.moving = false -- handle it here cuz we're handling everything else here anyway
            end)
        end
    end
end

return MoveData