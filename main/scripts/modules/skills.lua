require("main.scripts.modules.messages")
local buffs = require("main.scripts.modules.buffs")
local followersManipulator = require('main.scripts.modules.followers')

local skills = {}

---Push unit forward in current direction
---@param performer Head
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
---@param performer Head
skills.backward_dash = function(performer)
  performer.dashing = true
  local target_position = go.get_position()
  target_position = target_position - performer.dir * performer.speed * 1.08
  go.animate(".", "position", go.PLAYBACK_ONCE_FORWARD, target_position,
             go.EASING_LINEAR, 0.4, 0,
             function(self, url, property) self.dashing = false end)
end

---@param performer Follower
skills.ice_barrage = function(performer)
  if performer.ice_barrage_on_cooldown or performer.ice_barrage_active then
    return
  end

  msg.post("/gui/gui", MESSAGES.SKILLS.ICE.COOLDOWN)
  local spellGO = factory.create("#ice-spell-factory")
  msg.post(spellGO, "set_parent", { parent_id = go.get_id() })
  performer.ice_barrage_on_cooldown = true
  performer.ice_barrage_active = true
  timer.delay(6, false, function(self, handle, time_elapsed)
    performer.ice_barrage_on_cooldown = false
    msg.post("/gui/gui", MESSAGES.SKILLS.ICE.NORMAL)
  end)
  timer.delay(3, false, function(self, handle, time_elapsed)
    performer.ice_barrage_active = false
    go.delete(spellGO)

  end)
end

---@param performer Follower
skills.fireball = function(performer)
  if performer.fireball_on_cooldown then return end
  performer.fireball_on_cooldown = true
  msg.post("/gui/gui", MESSAGES.SKILLS.FIREBALL.COOLDOWN)
  local spellGO = factory.create("#fireball-spell-factory")
  go.set_rotation(go.get_rotation(), spellGO)
  timer.delay(0.5, false, function(self, handle, time_elapsed)
    performer.fireball_on_cooldown = false
    msg.post("/gui/gui", MESSAGES.SKILLS.FIREBALL.NORMAL)
  end)
end

---@param performer Follower
skills.thunderclap = function(performer)
  if performer.thunderclap_on_cooldown or performer.thunderclap_active then
    return
  end
  performer.thunderclap_on_cooldown = true
  performer.thunderclap_active = true

  local spellGO = factory.create("#thunderclap-spell-factory")
  msg.post(spellGO, "set_parent", { parent_id = go.get_id() })
  timer.delay(0.5, false, function(self, handle, time_elapsed)
    performer.thunderclap_active = false
    go.delete(spellGO)
  end)
  timer.delay(5, false, function(self, handle, time_elapsed)
    performer.thunderclap_on_cooldown = false
  end)
end

---@param performer Follower
skills.windwalk = function(performer)
  if performer.windwalk_on_cooldown or performer.windwalk_active then return end
  performer.windwalk_on_cooldown = true
  local spellGO = factory.create("#windwalk-spell-factory")

  go.set_rotation(go.get_rotation(), spellGO)
  go.set_scale(1.6, spellGO)
  timer.delay(1, false, function(self, handle, time_elapsed)
    performer.windwalk_active = false
    go.set_scale(1)
    go.delete(spellGO)
  end)
  timer.delay(3, false, function(self, handle, time_elapsed)
    performer.windwalk_on_cooldown = false
  end)
  go.set_scale(0.0000001)
end

return skills
