MESSAGES = {
  LOAD_LEVEL = "load_level",
  PLAYER = {
    TAKE_DAMAGE = 'player_take_damage',
    SET_HEALTH = 'player_set_health',
    COUNT_SCORE = 'player_count_score'
  },
  TOTEM = { TAKE_DAMAGE = 'totem_take_damage', SET_HEALTH = 'totem_set_health' },
  SKILLS = { COOLDOWN = 'cooldown', NORMAL = 'normal' },
  -- M20 System Messages
  M20 = {
    AWARD_XP = 'm20_award_xp',
    LEVEL_UP = 'm20_level_up',
    STAT_CHOICE = 'm20_stat_choice',
    ROLL_ATTACK = 'm20_roll_attack',
    ROLL_DAMAGE = 'm20_roll_damage',
    SAVING_THROW = 'm20_saving_throw',
    COMBAT_RESULT = 'm20_combat_result',
    UPDATE_STATS = 'm20_update_stats',
    GOLD_PICKUP = 'm20_gold_pickup',
    SHOP_OPEN = 'm20_shop_open',
    SHOP_CLOSE = 'm20_shop_close',
    SHOP_BUY_SPELL = 'm20_shop_buy_spell',
    SHOP_PURCHASE_RESULT = 'm20_shop_purchase_result',
    BUY_ITEM = 'm20_buy_item',
    SELL_ITEM = 'm20_sell_item',
    EQUIP_ITEM = 'm20_equip_item',
    UNEQUIP_ITEM = 'm20_unequip_item',
    USE_CONSUMABLE = 'm20_use_consumable',
    SPELL_CAST = 'm20_spell_cast',
    SPELL_COST = 'm20_spell_cost'
  }
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
    ice_barrage = 1,
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
