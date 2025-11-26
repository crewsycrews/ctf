MESSAGES = {
  LOAD_LEVEL = "load_level",
  PLAYER = {
    TAKE_DAMAGE = 'player_take_damage',
    SET_HEALTH = 'player_set_health',
    COUNT_SCORE = 'player_count_score'
  },
  TOTEM = { TAKE_DAMAGE = 'totem_take_damage', SET_HEALTH = 'totem_set_health' },
  SKILLS = { COOLDOWN = 'cooldown', NORMAL = 'normal' }
}

---@enum statuses
STATUSES = {
  invulnerability = 'invulnerability',
  frozen = 'frozen',
  slow = 'slow'
}

BUFF_TO_SKILL = {
  [STATUSES.frozen] = "ice_barrage",
  [STATUSES.slow] = "thunderclap"
}

---@enum collision_groups
COLLISION_GROUPS = {
  projectiles = hash('projectiles'),
  ice_barrage = hash('ice_barrage'),
  totem = hash('totem'),
  head = hash('head'),
  enemies = hash('enemies'),
  thunderclap = hash('thunderclap'),
  obstacles = hash('obstacles')
}

-- cooldowns in seconds
---@enum cooldowns
SKILLS = {
  COOLDOWNS = {
    ice_barrage = 6,
    fireball = 0.3,
    windwalk = 5,
    thunderclap = 5,
    dash = 3,
    jump = 3,
    backward_dash = 3
  },
  SKILL_DURATIONS = {
    ice_barrage = 3,
    windwalk = 0.5,
    thunderclap = 0.5,
    dash = 0.4,
    jump = 0.8,
    backward_dash = 0.4
  }
}

BUFF_DURATIONS = {
  [STATUSES.frozen] = 1,
  [STATUSES.slow] = 5
}

ELEMENTS = { "fire", "water", "wind", "earth" }
