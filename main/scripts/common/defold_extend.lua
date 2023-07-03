local M = {}

function M.go_exists(id)
	if not id then return false end
	local exists,_ = pcall(function()
		go.get_position(id)
	end)
	return exists
end

return M