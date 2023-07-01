require("main.scripts.common.functional")
local buffs = {}

---Check if the given status is in the buffs enum of a holder
---@param statusHolder {buffs: table}
---@param status statuses
---@return bool
buffs.check_status = function(statusHolder, status)
  return statusHolder.buffs[status] ~= nil or false
end

---@param statusHolder {buffs: table}
---@param status statuses
buffs.add_status = function(statusHolder, status)
  statusHolder.buffs[status] = status
end

---@param statusHolder {buffs: table}
---@param status statuses
buffs.remove_status = function(statusHolder, status)
  statusHolder.buffs[status] = nil
end

return buffs
