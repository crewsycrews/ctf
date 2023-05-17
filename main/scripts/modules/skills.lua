local buffs = require("main.scripts.modules.buffs")
local followersManipulator =
    require('main.scripts.modules.followers')

local skills = {}

---Push unit forward in current direction
---@param performer { buffs: table, dir: quaternion|vector3|vector4, dashing: bool, speed: number }
skills.dash = function(performer)
  performer.dashing = true
  local target_position = go.get_position()
  target_position = target_position + performer.dir * performer.speed * 1.08
  go.animate(".", "position", go.PLAYBACK_ONCE_FORWARD, target_position,
             go.EASING_LINEAR, 0.4, 0, function(self, url, property)
    self.dashing = false
    buffs.remove_status(performer, buffs.statuses.invulnerability)
  end)
  buffs.add_status(performer, buffs.statuses.invulnerability)
end
--- Animate scale increse and decrease
---@param performer { followers: table }
skills.jump = function(performer)
  performer.jumping = true
  go.animate(go.get_id(), 'scale', go.PLAYBACK_ONCE_PINGPONG,
             go.get_scale() * 2, go.EASING_LINEAR, 0.8, 0, function (self, url, property) self.jumping = false end)
  followersManipulator.animate_jump(performer)
end

---Push unit backward from current direction
---@param performer { buffs: table, dir: quaternion|vector3|vector4, dashing: bool, speed: number }
skills.backward_dash = function(performer)
  performer.dashing = true
  local target_position = go.get_position()
  target_position = target_position - performer.dir * performer.speed * 1.08
  go.animate(".", "position", go.PLAYBACK_ONCE_FORWARD, target_position,
             go.EASING_LINEAR, 0.4, 0,
             function(self, url, property) self.dashing = false end)
end

return skills
