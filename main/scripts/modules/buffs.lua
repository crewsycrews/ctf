require("main.scripts.common.functional")
local buffs = {}

---@enum statuses
local STATUSES = { invulnerability = 'invulnerability' }
buffs.statuses = STATUSES

---Check if the given status is in the buffs enum of a holder
---@param statusHolder {buffs: table}
---@param status statuses
---@return bool
buffs.check_status = function(statusHolder, status)
  return foldr(function(buff, is_presented)
    return status == buff or is_presented
  end, false, statusHolder.buffs)
end

return buffs
