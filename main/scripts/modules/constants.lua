MESSAGES = {
  LOAD_LEVEL = "load_level",
  PLAYER = {
    TAKE_DAMAGE = 'player_take_damage',
    SET_HEALTH = 'player_set_health'
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
