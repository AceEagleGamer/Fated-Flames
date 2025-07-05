--- Public Variables ---
local Ragdoll = {}

Ragdoll.cons = {}
Ragdoll.context = nil
Ragdoll.ragdollThreads = {
	players = {},
	npcs = {}
}
Ragdoll.ragdollCancelCDs = {}

--- Private Variables ---
local events = game:GetService("ReplicatedStorage").Events
local Players = game:GetService("Players")
local ragParts = game:GetService("ReplicatedStorage").RagdollParts:GetChildren()

--- Private Functions ---
function Work(char)
	char.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	char.Humanoid.AutoRotate = false
	for _, v in ipairs(char.RagdollConstraints.Motors:GetChildren()) do
		v.Value.Enabled = false
	end

	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("BasePart") then
			v:SetAttribute("OriginalCollisionGroup", v.CollisionGroup)
			v.CollisionGroup = "Ragdoll"
		end
	end
end

function Revert(char)
	char.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	for _, v in ipairs(char.RagdollConstraints.Motors:GetChildren()) do
		v.Value.Enabled = true
	end

	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = v:GetAttribute("OriginalCollisionGroup")
		end
	end
	char.Humanoid.AutoRotate = true
end

function Setup(char)

	local humanoid = char:FindFirstChild("Humanoid")
	assert(humanoid, "Can only set-up ragdoll on R6 humanoid rigs")
	assert(humanoid.RigType == Enum.HumanoidRigType.R6, "Can only set-up ragdoll on R6 humanoid rigs")
	assert(humanoid.RootPart ~= nil, "No RootPart was found in the provided rig")
	assert(char:FindFirstChild("HumanoidRootPart"), "No HumanoidRootPart was found in the provided rig")

	for _, v in ipairs(char:GetDescendants()) do
		if Players:GetPlayerFromCharacter(char) then continue end
		if v:IsA("BasePart") then
			v:SetNetworkOwner(nil)
		end
	end

	-- Setup ragdoll
	char.Head.Size = Vector3.new(1, 1, 1)
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false

	local clones = {}
	for _, v in ipairs(ragParts) do
		clones[v.Name] = v:Clone()
	end

	local folder1 = Instance.new("Folder")
	folder1.Name = "RagdollConstraints"
	for _, v in pairs(clones) do
		if v:IsA("Attachment") then
			v.Parent = char[v:GetAttribute("Parent")]
		elseif v:IsA("BallSocketConstraint") then
			v.Attachment0 = clones[v:GetAttribute("0")]
			v.Attachment1 = clones[v:GetAttribute("1")]
			v.Parent = folder1
		end
	end
	folder1.Parent = char

	local folder2 = Instance.new("Folder")
	folder2.Name = "Motors"
	local value
	for _, v in ipairs(char.Torso:GetChildren()) do
		if v:IsA("Motor6D") then
			value = Instance.new("ObjectValue")
			value.Value = v
			value.Parent = folder2
		end
	end
	folder2.Parent = folder1

	-- Ragdoll trigger
	char:SetAttribute("IsRagdoll", false)
end

function EvaluateRagdollCancel(player)

	-- check if we exist
    local playerChar = player.Character
    if playerChar == nil or playerChar:FindFirstChild("Humanoid") == nil or playerChar.Humanoid.Health <= 0 then return false end

	-- catch for nil
	if Ragdoll.ragdollCancelCDs[player] == nil then
		Ragdoll.ragdollCancelCDs[player] = 0
	end

	-- check if we're ragdolled in the first place
	if playerChar:GetAttribute("IsRagdoll") == false then return false end

	-- check if we're above ragdoll cancel cd
	if time() - Ragdoll.ragdollCancelCDs[player] >= playerChar:GetAttribute("RagdollCancelCooldownDuration") then
		if Ragdoll.ragdollThreads.players[player.Name] then
			task.cancel(Ragdoll.ragdollThreads.players[player.Name])
		end

		events.RagdollClient:FireClient(player, nil)
		playerChar:SetAttribute("IsRagdoll", false)
		Ragdoll.ragdollCancelCDs[player] = time()

		return true
	end
	return false
end

--- Public Functions ---
function Ragdoll:Init(context)
    self.context = context
end

-- heeeeeelp
function Ragdoll:Work(Character, knockbackDirection, ragdollDuration, setCFrame)
	local player = game:GetService("Players"):GetPlayerFromCharacter(Character)
	if player then -- if ragdolling player
		if Character:GetAttribute("IsRagdoll") == true then return end

		if setCFrame then
			Character:PivotTo(Character:GetPivot() * setCFrame)
		end

		Character:SetAttribute("IsRagdoll", true)
		events.RagdollClient:FireClient(player, true, knockbackDirection)

		self.ragdollThreads.players[Character.Name] = task.delay(ragdollDuration, function()
			events.RagdollClient:FireClient(player, nil)
			Character:SetAttribute("IsRagdoll", false)
		end)
	else -- if ragdolling npc
		if Character:GetAttribute("IsRagdoll") == true then return end
		if setCFrame then
			Character:PivotTo(Character:GetPivot() * setCFrame)
		end

		Character:SetAttribute("IsRagdoll", true)

		Character.HumanoidRootPart.AssemblyLinearVelocity = -knockbackDirection

		self.ragdollThreads.npcs[Character] = task.delay(ragdollDuration, function()
			if Character == nil or (Character:FindFirstChild("Humanoid") and Character:FindFirstChild("Humanoid").Health <= 0) then return end
			Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			Character:SetAttribute("IsRagdoll", false)
		end)
	end
end

function Ragdoll:Start()
	local context = self.context
	local services = context.services

	--- NPCs ---
	for _, npc in workspace.NPCs:GetChildren() do -- TODO: replace this when we do actual npcs\
		self.cons[npc] = {}
		npc.HumanoidRootPart:SetNetworkOwner(nil)

		Setup(npc)

		self.cons[npc].ragdollEvent = npc:GetAttributeChangedSignal("IsRagdoll"):Connect(function()
			local isRagdoll = npc:GetAttribute("IsRagdoll")
			if isRagdoll then
				Work(npc)
			else
				Revert(npc)
			end
		end)
	end

	--- Players ---
	self.cons.playerAdded = services.playerservice.events.playerJoining:Connect(function(player: Player)
		self.cons[player.UserId] = {}

		self.cons[player.UserId].characterLoaded = player.CharacterAdded:Connect(function(char)
			player.CharacterAppearanceLoaded:Wait()

			-- setup char
			Setup(char)

			-- disconnect previous ragdoll event
			if self.cons[player.UserId].ragdollEvent then
				self.cons[player.UserId].ragdollEvent:Disconnect()
			end
			-- Connect the event
			self.cons[player.UserId].ragdollEvent = char:GetAttributeChangedSignal("IsRagdoll"):Connect(function()
				local isRagdoll = char:GetAttribute("IsRagdoll")
				if isRagdoll then
					Work(char)
				else
					Revert(char)
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

	-- setup ragdoll cancel listener
	events.RequestRagdollCancel.OnServerInvoke = EvaluateRagdollCancel
end

return Ragdoll