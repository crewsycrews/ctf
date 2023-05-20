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
             go.get_scale() * 2, go.EASING_LINEAR, 0.8, 0,
             function(self, url, property) self.jumping = false end)
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

skills.ice_barrage = function(performer)
  if performer.ice_barrage_on_cooldown or performer.ice_barrage_active then
    return
  end
  local spellGO = factory.create("#ice-spell-factory")
  msg.post(spellGO, "set_parent", { parent_id = go.get_id() })
  performer.ice_barrage_on_cooldown = true
  performer.ice_barrage_active = true
  timer.delay(6, false, function(self, handle, time_elapsed)
    performer.ice_barrage_on_cooldown = false
  end)
  timer.delay(0.3, false, function(self, handle, time_elapsed)
    performer.ice_barrage_active = false
    go.delete(spellGO)
  end)
end

skills.fireball = function(performer)
  if performer.fireball_on_cooldown then
    return
  end
  performer.fireball_on_cooldown = true
  local spellGO = factory.create("#fireball-spell-factory")
  go.set_rotation(go.get_rotation(), spellGO)
  timer.delay(0.5, false, function(self, handle, time_elapsed)
    performer.fireball_on_cooldown = false
  end)
end

return skills
