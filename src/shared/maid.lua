local Maid = {}

function Maid:DeepClear(t)
	for i, v in pairs(t) do
		if type(i) == "table" then
			setmetatable(i, nil)
			self:DeepClear(i)
		end
		if type(v) == "table" then
			setmetatable(v, nil)
			self:DeepClear(v)
		end
	end
	setmetatable(t, nil)
	table.clear(t)
end

return Maid