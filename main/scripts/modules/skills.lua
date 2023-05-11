local buffs = require("main.scripts.modules.buffs")

local skills = {}

---Push unit forward in current direction
---@param performer { buffs: table, dir: quaternion|vector3|vector4, dashing: number }
skills.dash = function(performer)
  performer.dashing = 1
  table.insert(performer.buffs, buffs.statuses.invulnerability)
end

return skills
