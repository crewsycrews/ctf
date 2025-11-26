require("main.scripts.common.functional")
local buffs = {}

local function ensure_status_tables(statusHolder)
  statusHolder.buffs = statusHolder.buffs or {}
end

local function set_effect_enabled(component, enabled)
  if not component then return end
  local msg_id = enabled and hash("enable") or hash("disable")
  pcall(msg.post, component, msg_id)
end

local function activate_effect(statusHolder, status)
  local component = statusHolder.buff_effect_components and
                        statusHolder.buff_effect_components[status]
  set_effect_enabled(component, true)
end

local function deactivate_effect(statusHolder, status)
  local component = statusHolder.buff_effect_components and
                        statusHolder.buff_effect_components[status]
  set_effect_enabled(component, false)
end

---Check if the given status is in the buffs enum of a holder
---@param statusHolder {buffs: table}
---@param status statuses
---@return bool
buffs.check_status = function(statusHolder, status)
  ensure_status_tables(statusHolder)
  return statusHolder.buffs[status] ~= nil
end

---@param statusHolder {buffs: table}
---@param status statuses
buffs.add_status = function(statusHolder, status)
  ensure_status_tables(statusHolder)
  statusHolder.buffs[status] = status
  activate_effect(statusHolder, status)
end

---@param statusHolder {buffs: table}
---@param status statuses
buffs.remove_status = function(statusHolder, status)
  ensure_status_tables(statusHolder)
  statusHolder.buffs[status] = nil
  deactivate_effect(statusHolder, status)
end

return buffs
