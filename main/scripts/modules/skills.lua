local buffs = require("main.scripts.modules.buffs")
local followersManipulator =
    require('main.scripts.modules.followersManipulator')

local skills = {}

---Push unit forward in current direction
---@param performer { buffs: table, dir: quaternion|vector3|vector4, dashing: number }
skills.dash = function(performer)
  performer.dashing = 1
  table.insert(performer.buffs, buffs.statuses.invulnerability)
end
--- Animate Z coordinate increse and decrease
---@param performer { followers: table }
skills.jump = function(performer)
  go.animate(go.get_id(), 'scale', go.PLAYBACK_ONCE_PINGPONG, go.get_scale() * 2, go.EASING_LINEAR, 0.8)
  followersManipulator.animate_jump(performer)
end

return skills
