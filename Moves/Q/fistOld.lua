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

--- Packages ---
local hitbox = require(shared.hitbox)

--- Public Variables ---
local MoveData = {}
MoveData.direction = 0

MoveData.properties = {
    cooldown = 2,

    damage = 5,
    postureDamage = 5,

    canMoveAgain = 0.5,
    moveEndlag = 0.5,

    variants = {
        front = {
            cooldown = 4,
            canMoveAgain = 0.75,
            conditionFulfilled = function()
                if not localPlayer.Character or not localPlayer.Character:FindFirstChild("Humanoid") or localPlayer.Character.Humanoid.Health <= 0 then return end
                local PlayerScripts = localPlayer:WaitForChild("PlayerScripts")
                local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule")) -- ignore error
                local ControlModule = PlayerModule:GetControls()

                local _hum = localPlayer.Character.Humanoid
                local MoveDirection = ControlModule:GetMoveVector() or Vector3.new()
                --local MoveDirection = camera.CFrame:VectorToObjectSpace(moveVector)

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
    if run:IsServer() then return end
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("Humanoid") or localPlayer.Character.Humanoid.Health <= 0 then return end
    local PlayerScripts = localPlayer:WaitForChild("PlayerScripts")
    local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule")) -- ignore error
    local ControlModule = PlayerModule:GetControls()

    local _hum = localPlayer.Character.Humanoid
    local MoveDirection = ControlModule:GetMoveVector() or Vector3.new()
    --local MoveDirection = camera.CFrame:VectorToObjectSpace(moveVector)

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

    local startingTick = time()

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local function checkInFront()
        if time() - startingTick < 0.5 then return end
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
    table.clear(self.animations)
    table.clear(self.sounds)
    self.player = nil
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
    linearVel.MaxAxesForce = Vector3.new(50000, 0, 50000)
    
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

function MoveData:Replicate(player, variant, moveTick)
    
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
            if char:GetAttribute("IsRagdoll") == true then self.free = true; return end
            local moveGranted = events.RequestMove:InvokeServer(script.Parent.Name, script.Name, dir) -- takes move folder and move name, returns true or false
            if moveGranted then
                self.free = false
                -- moving logic
                input.moving = true
                local frontProperties = self.properties.variants.front

                -- set char to follow cam direction
                core.playerState.followingCamDir = true

                -- prep linear velocity for dash
                local linearVel = char.HumanoidRootPart.Attachment.LinearVelocity
                linearVel.Enabled = true

                -- dash stuff
                local dashStrength = Instance.new("NumberValue")
                dashStrength.Value = 90

                local dashDecay = twn:Create(dashStrength, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = 0})
                dashDecay:Play()

                local dashUpdateLoop = QueueDash(dir, char, dashStrength, linearVel)

                -- play anim and rotate character accordingly
                self.animations["front_windup"]:Play()
                self.sounds.dash:Play()

                -- handles end of dash
                task.delay(frontProperties.canMoveAgain, function()
                    if dashUpdateLoop then
                        task.cancel(dashUpdateLoop)
                        self.OutOfDash:Fire()
                    end
                end)

                self.OutOfDash.Event:Wait() -- end of dash or ending early
                core.playerState.followingCamDir = false
                self.animations["front_windup"]:Stop()
                self.animations["front_hit"]:Play()

                linearVel.Enabled = false
                char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0) -- reset velocity
                
                -- you cant hit immediately after a dash hit!
                task.delay(0.35, function()
                    input.moving = false -- handle it here cuz we're handling everything else here anyway
                end)

                -- hitbox troll
                local hitboxProperty = self.HitboxProperties.front
                local hitProperties = {}
                local hits = hitbox:Evaluate(self.player.Character.HumanoidRootPart.CFrame * hitboxProperty.cframe, hitboxProperty.size, true)
                hits = hitbox:FilterSelf(self.player.Character, hits)

                -- clientside hits
                core:PlayHit(self.player.Character, hits, hitProperties)

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
                        self.animations["front_hit"]:AdjustSpeed(12)
                    end
                end
                self.free = true
            end
        else

            -- special condition for ragdoll cancel
            if char:GetAttribute("IsRagdoll") == true then
                local status = events.RequestRagdollCancel:InvokeServer()
                if status == false then
                    return
                end
            end
            self.free = false
            input.canJump = false

            -- prep linear velocity for dash
            local linearVel = char.HumanoidRootPart.Attachment.LinearVelocity
            linearVel.Enabled = true

            core.playerState.followingCamDir = true

            -- dash stuff
            local dashStrength = Instance.new("NumberValue")
            dashStrength.Value = 120

            local dashDecay = twn:Create(dashStrength, TweenInfo.new(self.properties.canMoveAgain, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = 10})
            dashDecay:Play()

            local dashUpdateLoop = QueueDash(dir, char, dashStrength, linearVel)

            -- play anim and rotate character accordingly
            self.animations[dir]:Play()
            self.sounds.dash:Play()

            task.delay(self.properties.canMoveAgain, function()
                task.cancel(dashUpdateLoop)
                core.playerState.followingCamDir = false
                linearVel.Enabled = false
                self.free = true
                input.canJump = true
            end)
        end
    end
    self.free = true
end

return MoveData