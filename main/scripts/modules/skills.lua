local buffs = require("main.scripts.modules.buffs")
local defold_extend = require("main.scripts.common.defold_extend")
local followersManipulator = require('main.scripts.modules.followers')

-- M20 modules for HP-based spell casting
local spells = require("main.scripts.modules.m20_spells")
local magic = require("main.scripts.modules.m20_magic")
local attrs = require("main.scripts.modules.m20_attributes")
local weapon_attacks = require("main.scripts.modules.weapon_attacks")

local skills = {}

---Push unit forward in current direction
---@param performer Hero
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
---@param performer Hero
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

---@param performer Hero
skills.ice_barrage = function(performer)
  -- Prevent recasting while spell is active
  if performer.ice_barrage_active then
    return
  end

  -- M20: Hold Person (Level 2) costs 5 HP
  local spell = spells.get_spell_from_ctf("ice_barrage")
  if not spell then return end

  -- Check if player has learned this spell
  if not magic.knows_spell(performer, spell.id) then
    print("[M20] Cannot cast ice_barrage: Spell not learned (purchase from shop)")
    return
  end

  -- Check if player has enough HP to cast
  local can_cast, error_msg = magic.can_cast_spell(performer, spell.level, false)
  if not can_cast then
    print("[M20] Cannot cast ice_barrage: " .. error_msg)
    return
  end

  -- Deduct HP cost
  local result = magic.cast_spell(performer, spell.level, false)
  if not result.success then
    print("[M20] Failed to cast ice_barrage")
    return
  end

  print(string.format("[M20] Cast ice_barrage, paid %d HP (remaining: %d)", result.hp_cost, result.caster_hp_remaining))

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
  performer.ice_barrage_active = true

  -- Clean up after spell duration
  timer.delay(SKILLS.SKILL_DURATIONS.ice_barrage, false,
    function(self, handle, time_elapsed)
      performer.ice_barrage_active = false
      go.delete(spellGO)
    end)

  -- Update GUI to show new HP
  msg.post("/gui/gui", hash(MESSAGES.M20.UPDATE_STATS), {
    stats = {
      hp_current = performer.m20_stats.hp_current,
      hp_max = performer.m20_stats.hp_max,
      xp = performer.m20_stats.xp,
      xp_to_next_level = performer.m20_stats.xp_to_next_level,
      level = performer.m20_stats.level,
      ac = performer.m20_stats.ac
    }
  })
end

---@param performer Hero
skills.fireball = function(performer)
  -- M20: Magic Missile (Level 1) costs 3 HP
  local spell = spells.get_spell_from_ctf("fireball")
  if not spell then return end

  -- Check if player has learned this spell
  if not magic.knows_spell(performer, spell.id) then
    print("[M20] Cannot cast fireball: Spell not learned (purchase from shop)")
    return
  end

  -- Check if player has enough HP to cast
  local can_cast, error_msg = magic.can_cast_spell(performer, spell.level, false)
  if not can_cast then
    print("[M20] Cannot cast fireball: " .. error_msg)
    return
  end

  -- Deduct HP cost
  local result = magic.cast_spell(performer, spell.level, false)
  if not result.success then
    print("[M20] Failed to cast fireball")
    return
  end

  print(string.format("[M20] Cast fireball, paid %d HP (remaining: %d)", result.hp_cost, result.caster_hp_remaining))

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

  -- Update GUI to show new HP
  msg.post("/gui/gui", hash(MESSAGES.M20.UPDATE_STATS), {
    stats = {
      hp_current = performer.m20_stats.hp_current,
      hp_max = performer.m20_stats.hp_max,
      xp = performer.m20_stats.xp,
      xp_to_next_level = performer.m20_stats.xp_to_next_level,
      level = performer.m20_stats.level,
      ac = performer.m20_stats.ac
    }
  })
end

---@param performer Hero
skills.thunderclap = function(performer)
  -- Prevent recasting while spell is active
  if performer.thunderclap_active then
    return
  end

  -- M20: Gust of Wind (Level 2) costs 5 HP
  local spell = spells.get_spell_from_ctf("thunderclap")
  if not spell then return end

  -- Check if player has learned this spell
  if not magic.knows_spell(performer, spell.id) then
    print("[M20] Cannot cast thunderclap: Spell not learned (purchase from shop)")
    return
  end

  -- Check if player has enough HP to cast
  local can_cast, error_msg = magic.can_cast_spell(performer, spell.level, false)
  if not can_cast then
    print("[M20] Cannot cast thunderclap: " .. error_msg)
    return
  end

  -- Deduct HP cost
  local result = magic.cast_spell(performer, spell.level, false)
  if not result.success then
    print("[M20] Failed to cast thunderclap")
    return
  end

  print(string.format("[M20] Cast thunderclap, paid %d HP (remaining: %d)", result.hp_cost, result.caster_hp_remaining))

  performer.thunderclap_active = true

  local spellGO = factory.create("#thunderclap-spell-factory")
  msg.post(spellGO, "set_parent", { parent_id = go.get_id() })

  -- Clean up after spell duration
  timer.delay(SKILLS.SKILL_DURATIONS.thunderclap, false,
    function(self, handle, time_elapsed)
      performer.thunderclap_active = false
      go.delete(spellGO)
    end)

  -- Update GUI to show new HP
  msg.post("/gui/gui", hash(MESSAGES.M20.UPDATE_STATS), {
    stats = {
      hp_current = performer.m20_stats.hp_current,
      hp_max = performer.m20_stats.hp_max,
      xp = performer.m20_stats.xp,
      xp_to_next_level = performer.m20_stats.xp_to_next_level,
      level = performer.m20_stats.level,
      ac = performer.m20_stats.ac
    }
  })
end

---@param performer Hero
skills.windwalk = function(performer)
  -- Prevent recasting while spell is active
  if performer.windwalk_active then return end

  -- M20: Invisibility (Level 1) costs 3 HP
  local spell = spells.get_spell_from_ctf("windwalk")
  if not spell then return end

  -- Check if player has learned this spell
  if not magic.knows_spell(performer, spell.id) then
    print("[M20] Cannot cast windwalk: Spell not learned (purchase from shop)")
    return
  end

  -- Check if player has enough HP to cast
  local can_cast, error_msg = magic.can_cast_spell(performer, spell.level, false)
  if not can_cast then
    print("[M20] Cannot cast windwalk: " .. error_msg)
    return
  end

  -- Deduct HP cost
  local result = magic.cast_spell(performer, spell.level, false)
  if not result.success then
    print("[M20] Failed to cast windwalk")
    return
  end

  print(string.format("[M20] Cast windwalk, paid %d HP (remaining: %d)", result.hp_cost, result.caster_hp_remaining))

  local spellGO = factory.create("#windwalk-spell-factory")

  go.set_rotation(go.get_rotation(), spellGO)
  go.set_scale(1.6, spellGO)

  performer.windwalk_active = true

  -- Clean up after spell duration
  timer.delay(SKILLS.SKILL_DURATIONS.windwalk, false,
    function(self, handle, time_elapsed)
      performer.windwalk_active = false
      go.set_scale(1)
      if (defold_extend.go_exists(spellGO)) then go.delete(spellGO) end
    end)

  -- making the walker small, like he's disappeared
  go.set_scale(0.0000001)

  -- Update GUI to show new HP
  msg.post("/gui/gui", hash(MESSAGES.M20.UPDATE_STATS), {
    stats = {
      hp_current = performer.m20_stats.hp_current,
      hp_max = performer.m20_stats.hp_max,
      xp = performer.m20_stats.xp,
      xp_to_next_level = performer.m20_stats.xp_to_next_level,
      level = performer.m20_stats.level,
      ac = performer.m20_stats.ac
    }
  })
end

---Melee weapon attack
---@param performer Hero
skills.melee_attack = function(performer)
  -- Perform weapon attack using equipped weapon
  local result = weapon_attacks.melee_attack(performer, performer.mouse_world_pos)

  if result then
    print(string.format("[Melee Attack] %s: hit=%s, targets=%d, damage=%d",
      result.behavior, tostring(result.hit), #result.targets, result.damage))
  end
end

return skills
