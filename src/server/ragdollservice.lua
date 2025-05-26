--- Public Variables ---
local Ragdoll = {}

Ragdoll.cons = {}
Ragdoll.context = nil

--- Private Variables ---
local events = game:GetService("ReplicatedStorage").Events
--> Specific CFrame's I made for the best looking Ragdoll
local attachmentCFrames = {
	["Neck"] = {CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1)},
	["Left Shoulder"] = {CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1), CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1)},
	["Right Shoulder"] = {CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	["Left Hip"] = {CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
	["Right Hip"] = {CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
}

local ragdollInstanceNames = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}
--- Private Functions ---
local function createColliderPart(part: BasePart)
	if not part then return end
	local rp = Instance.new("Part")
	rp.Name = "ColliderPart"
	rp.Size = part.Size/1.7
	rp.Massless = true			
	rp.CFrame = part.CFrame
	rp.Transparency = 1
	
	local wc = Instance.new("WeldConstraint")
	wc.Part0 = rp
	wc.Part1 = part
	
	wc.Parent = rp
	rp.Parent = part
end

function replaceJoints(Character)

	local Humanoid = Character:FindFirstChild("Humanoid")
	Humanoid.AutoRotate = false 
	Character:WaitForChild("HumanoidRootPart").Massless = true
	for _, motor in pairs(Character:GetDescendants()) do
		if motor:IsA("Motor6D") then
			if not attachmentCFrames[motor.Name] then return end
			motor.Enabled = false;
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.CFrame = attachmentCFrames[motor.Name][1]
			a1.CFrame = attachmentCFrames[motor.Name][2]

			a0.Name = "RagdollAttachment"
			a1.Name = "RagdollAttachment"

			createColliderPart(motor.Part1)

			local b = Instance.new("BallSocketConstraint")
			b.Attachment0 = a0
			b.Attachment1 = a1
			b.Name = "RagdollConstraint"

			b.Radius = 0.15
			b.LimitsEnabled = true
			b.TwistLimitsEnabled = false
			b.MaxFrictionTorque = 0
			b.Restitution = 0
			b.UpperAngle = 90
			b.TwistLowerAngle = -45
			b.TwistUpperAngle = 45

			if motor.Name == "Neck" then
				b.TwistLimitsEnabled = true
				b.UpperAngle = 45
				b.TwistLowerAngle = -70
				b.TwistUpperAngle = 70
			end
			
			a0.Parent = motor.Part0
			a1.Parent = motor.Part1
			b.Parent = motor.Parent
		end
	end
end

function resetJoints(Character)
	Character:WaitForChild("HumanoidRootPart").Massless = false
	Character:SetAttribute("IsRagdoll", false)

	local Humanoid = Character:FindFirstChild("Humanoid")
	Humanoid.AutoRotate = true
	
	if Humanoid.Health < 1 then return end
	for _, instance in pairs(Character:GetDescendants()) do
		if ragdollInstanceNames[instance.Name] then
			instance:Destroy()
		end

		if instance:IsA("Motor6D") then
			instance.Enabled = true;
		end
	end
	
end

local function _push(T, Kb)
	T:ApplyImpulse(T.CFrame.LookVector * Kb)
end

--- Public Functions ---
function Ragdoll:Init(context)
    self.context = context
end

function Ragdoll:Work(Character, knockbackDirection, ragdollDuration)
	if Character:GetAttribute("IsRagdoll") == true then return end
	Character:SetAttribute("IsRagdoll", true)
	events.RagdollClient:FireClient(game:GetService("Players"):GetPlayerFromCharacter(Character), true, knockbackDirection)

	task.delay(ragdollDuration, function()
		events.RagdollClient:FireClient(game:GetService("Players"):GetPlayerFromCharacter(Character), nil)
		Character:SetAttribute("IsRagdoll", false)
	end)
end

function Ragdoll:Start()
	local context = self.context
	local services = context.services
	self.cons.playerAdded = services.playerservice.events.playerJoining:Connect(function(player: Player)
		self.cons[player.UserId] = {}

		self.cons[player.UserId].characterLoaded = player.CharacterAdded:Connect(function(char)

			-- disconnect previous ragdoll event
			if self.cons[player.UserId].ragdollEvent then
				self.cons[player.UserId].ragdollEvent:Disconnect()
			end
			-- Connect the event
			self.cons[player.UserId].ragdollEvent = char:GetAttributeChangedSignal("IsRagdoll"):Connect(function()
				local isRagdoll = char:GetAttribute("IsRagdoll")
				if isRagdoll then
					replaceJoints(char)
				else
					resetJoints(char)
				end
			end)
    	end)
	end)

	self.cons.playerAdded = services.playerservice.events.playerLeaving:Connect(function(player: Player)
		for _, con in self.cons[player.UserId] do
			con:Disconnect()
		end

		table.clear(self.cons[player.UserId])
	end)

end

return Ragdoll