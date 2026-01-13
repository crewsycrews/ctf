local buffs = require("main.scripts.modules.buffs")
local defold_extend = require("main.scripts.common.defold_extend")
local followersManipulator = require('main.scripts.modules.followers')

local skills = {}

---Push unit forward in current direction
---@param performer Head
skills.dash = function(performer)
  if performer.dash_on_cooldown or performer.dashing then return end
  performer.dash_on_cooldown = true
  performer.dashing = true

  -- Store original speed and boost it for dash
  if not performer.original_speed then
    performer.original_speed = performer.speed
  end
  performer.speed = performer.original_speed * 4

  msg.post("/gui/gui", MESSAGES.SKILLS.COOLDOWN,
    { type = "head_" .. ELEMENTS[1] })
  timer.delay(SKILLS.COOLDOWNS.dash, false, function()
    performer.dash_on_cooldown = false
    msg.post("/gui/gui", MESSAGES.SKILLS.NORMAL,
      { type = "head_" .. ELEMENTS[1] })
  end)

  -- Reset speed and dashing state after dash duration
  timer.delay(SKILLS.SKILL_DURATIONS.dash, false, function()
    performer.speed = performer.original_speed
    performer.dashing = false
    buffs.remove_status(performer, STATUSES.invulnerability)
  end)

  buffs.add_status(performer, STATUSES.invulnerability)
end
--- Animate scale increse and decrease
---@param performer { followers: table }
skills.jump = function(performer)
  if performer.jump_on_cooldown or performer.jumping then return end

  performer.jumping = true
  performer.jump_on_cooldown = true
  msg.post("/gui/gui", MESSAGES.SKILLS.COOLDOWN,
    { type = "head_" .. ELEMENTS[3] })
  timer.delay(SKILLS.COOLDOWNS.jump, false, function(self, handle, time_elapsed)
    performer.jump_on_cooldown = false
    msg.post("/gui/gui", MESSAGES.SKILLS.NORMAL,
      { type = "head_" .. ELEMENTS[3] })
  end)
  go.animate(go.get_id(), 'scale', go.PLAYBACK_ONCE_PINGPONG,
    go.get_scale() * 2, go.EASING_LINEAR, SKILLS.SKILL_DURATIONS.jump, 0,
    function(self, url, property) self.jumping = false end)
  -- followersManipulator.animate_jump(performer)
end

---Push unit backward from current direction
---@param performer Head
skills.backward_dash = function(performer)
  if performer.backward_dash_on_cooldown or performer.dashing then return end
  performer.backward_dash_on_cooldown = true
  performer.dashing = true

  -- Store original speed and direction
  if not performer.original_speed then
    performer.original_speed = performer.speed
  end
  local original_dir = vmath.vector3(performer.dir)

  -- Boost speed and reverse direction for backward dash
  performer.speed = performer.original_speed * 8
  performer.dir = -performer.dir

  msg.post("/gui/gui", MESSAGES.SKILLS.COOLDOWN,
    { type = "head_" .. ELEMENTS[2] })
  timer.delay(SKILLS.COOLDOWNS.backward_dash, false, function()
    performer.backward_dash_on_cooldown = false
    msg.post("/gui/gui", MESSAGES.SKILLS.NORMAL,
      { type = "head_" .. ELEMENTS[2] })
  end)

  -- Reset speed, restore direction, and clear dashing state after dash duration
  timer.delay(SKILLS.SKILL_DURATIONS.backward_dash, false, function()
    performer.speed = performer.original_speed
    performer.dir = original_dir
    performer.dashing = false
  end)
end

---@param performer Head
skills.ice_barrage = function(performer)
  if performer.ice_barrage_on_cooldown or performer.ice_barrage_active then
    return
  end

  msg.post("/gui/gui", MESSAGES.SKILLS.COOLDOWN,
    { type = ELEMENTS[2] })

  local spellGO = factory.create("#ice-spell-factory")

  -- Calculate rotation towards mouse
  local player_pos = go.get_position()
  local dir_to_mouse = performer.mouse_world_pos - player_pos
  local rotation = vmath.quat()
  if vmath.length(dir_to_mouse) > 1 then
    local angle = math.atan2(player_pos.x - performer.mouse_world_pos.x, performer.mouse_world_pos.y - player_pos.y)
    rotation = vmath.quat_rotation_z(angle)
  end
  go.set_rotation(rotation, spellGO)

  -- Tell the spell to follow the player
  msg.post(spellGO, "follow_target", { target = go.get_id() })
  performer.ice_barrage_on_cooldown = true
  performer.ice_barrage_active = true
  timer.delay(SKILLS.COOLDOWNS.ice_barrage, false,
    function(self, handle, time_elapsed)
      performer.ice_barrage_on_cooldown = false
      msg.post("/gui/gui", MESSAGES.SKILLS.NORMAL,
        { type = ELEMENTS[2] })
    end)
  timer.delay(SKILLS.SKILL_DURATIONS.ice_barrage, false,
    function(self, handle, time_elapsed)
      performer.ice_barrage_active = false
      go.delete(spellGO)
    end)
end

---@param performer Head
skills.fireball = function(performer)
  if performer.fireball_on_cooldown then return end
  performer.fireball_on_cooldown = true
  msg.post("/gui/gui", MESSAGES.SKILLS.COOLDOWN,
    { type = ELEMENTS[1] })

  -- Calculate rotation towards mouse
  local player_pos = go.get_position()
  local dir_to_mouse = performer.mouse_world_pos - player_pos
  local rotation = vmath.quat()
  if vmath.length(dir_to_mouse) > 1 then
    local angle = math.atan2(player_pos.x - performer.mouse_world_pos.x, performer.mouse_world_pos.y - player_pos.y)
    rotation = vmath.quat_rotation_z(angle)
  end

  local spellGO = factory.create("#fireball-spell-factory")
  go.set_rotation(rotation, spellGO)
  timer.delay(SKILLS.COOLDOWNS.fireball, false,
    function(self, handle, time_elapsed)
      performer.fireball_on_cooldown = false
      msg.post("/gui/gui", MESSAGES.SKILLS.NORMAL,
        { type = ELEMENTS[1] })
    end)
end

---@param performer Head
skills.thunderclap = function(performer)
  if performer.thunderclap_on_cooldown or performer.thunderclap_active then
    return
  end
  performer.thunderclap_on_cooldown = true
  performer.thunderclap_active = true
  msg.post("/gui/gui", MESSAGES.SKILLS.COOLDOWN,
    { type = ELEMENTS[4] })

  local spellGO = factory.create("#thunderclap-spell-factory")
  msg.post(spellGO, "set_parent", { parent_id = go.get_id() })
  timer.delay(SKILLS.SKILL_DURATIONS.thunderclap, false,
    function(self, handle, time_elapsed)
      performer.thunderclap_active = false
      go.delete(spellGO)
    end)
  timer.delay(SKILLS.COOLDOWNS.thunderclap, false,
    function(self, handle, time_elapsed)
      performer.thunderclap_on_cooldown = false
      msg.post("/gui/gui", MESSAGES.SKILLS.NORMAL,
        { type = ELEMENTS[4] })
    end)
end

---@param performer Head
skills.windwalk = function(performer)
  if performer.windwalk_on_cooldown or performer.windwalk_active then return end
  performer.windwalk_on_cooldown = true
  msg.post("/gui/gui", MESSAGES.SKILLS.COOLDOWN,
    { type = ELEMENTS[3] })
  local spellGO = factory.create("#windwalk-spell-factory")

  go.set_rotation(go.get_rotation(), spellGO)
  go.set_scale(1.6, spellGO)
  timer.delay(SKILLS.SKILL_DURATIONS.windwalk, false,
    function(self, handle, time_elapsed)
      performer.windwalk_active = false
      go.set_scale(1)
      if (defold_extend.go_exists(spellGO)) then go.delete(spellGO) end
    end)
  timer.delay(SKILLS.COOLDOWNS.windwalk, false,
    function(self, handle, time_elapsed)
      performer.windwalk_on_cooldown = false
      msg.post("/gui/gui", MESSAGES.SKILLS.NORMAL,
        { type = ELEMENTS[3] })
    end)
  -- making the walker small, like he's disappeared
  go.set_scale(0.0000001)
end

return skills
