-- main/scripts/modules/m20_weapons.lua
-- Microlite20 Weapons System for Cosmic Tree Fighters
-- Weapon equipment, damage calculation, and combat behaviors

local M = {}

---@class WeaponDefinition
---@field id string Weapon ID
---@field name string Display name
---@field category string "light" | "one_handed" | "two_handed" | "ranged"
---@field damage string Damage dice notation (e.g., "1d8")
---@field cost number Gold piece cost
---@field range number? Range increment in feet (for ranged/thrown weapons)
---@field special string? Special properties description
---@field attack_behavior string "normal" | "pierce" | "wide_sweep" | "balanced"
---@field attack_speed number Attack speed multiplier (1.0 = normal)
---@field attack_range number Attack reach multiplier (1.0 = normal)
---@field attack_arc number Attack arc in degrees (for melee weapons)

---@class EquippedWeapon
---@field weapon_id string ID of equipped weapon
---@field damage_bonus number Current damage bonus from stats/class
---@field attack_bonus number Current attack bonus from stats/class

-- Weapon definitions from M20 rules (Page 5)
M.WEAPONS = {
  -- STARTER WEAPONS (Light/Simple)
  {
    id = "unarmed",
    name = "Unarmed Strike",
    category = "light",
    damage = "1d3",
    cost = 0,
    attack_behavior = "normal",
    attack_speed = 1.2,
    attack_range = 0.6,
    attack_arc = 60,
    special = "Natural weapon"
  },
  {
    id = "dagger",
    name = "Dagger",
    category = "light",
    damage = "1d4",
    cost = 2,
    range = 10,
    attack_behavior = "normal",
    attack_speed = 1.3,
    attack_range = 0.7,
    attack_arc = 45,
    special = "Can be thrown"
  },

  -- THREE SHOP WEAPONS (Main feature weapons)
  {
    id = "spear",
    name = "Spear",
    category = "one_handed",
    damage = "1d8",
    cost = 10,
    range = 20,
    attack_behavior = "pierce",
    attack_speed = 1.0,
    attack_range = 1.5,     -- Longer reach for piercing
    attack_arc = 30,        -- Narrow arc for thrust attacks
    special = "Reach weapon, can be thrown, piercing attacks hit single targets at long range"
  },
  {
    id = "battleaxe",
    name = "Battleaxe",
    category = "one_handed",
    damage = "1d8",
    cost = 10,
    attack_behavior = "wide_sweep",
    attack_speed = 0.7,     -- Slower attacks
    attack_range = 1.0,
    attack_arc = 120,       -- Wide sweeping arc
    special = "Slow, wide cleaving attacks that can hit multiple enemies"
  },
  {
    id = "longsword",
    name = "Longsword",
    category = "one_handed",
    damage = "1d8",
    cost = 10,
    attack_behavior = "balanced",
    attack_speed = 1.0,
    attack_range = 1.1,
    attack_arc = 75,
    special = "Balanced weapon, good for versatile combat"
  },

  -- ADDITIONAL WEAPONS (for variety)
  {
    id = "shortsword",
    name = "Shortsword",
    category = "light",
    damage = "1d6",
    cost = 10,
    attack_behavior = "normal",
    attack_speed = 1.2,
    attack_range = 0.9,
    attack_arc = 60,
    special = "Light weapon, faster attacks"
  },
  {
    id = "mace",
    name = "Mace",
    category = "one_handed",
    damage = "1d8",
    cost = 12,
    attack_behavior = "normal",
    attack_speed = 0.9,
    attack_range = 0.9,
    attack_arc = 70,
    special = "Bludgeoning damage"
  },
  {
    id = "greatsword",
    name = "Greatsword",
    category = "two_handed",
    damage = "2d6",
    cost = 50,
    attack_behavior = "wide_sweep",
    attack_speed = 0.6,
    attack_range = 1.2,
    attack_arc = 100,
    special = "Two-handed, slow but powerful"
  },
  {
    id = "greataxe",
    name = "Greataxe",
    category = "two_handed",
    damage = "1d10",
    cost = 20,
    attack_behavior = "wide_sweep",
    attack_speed = 0.65,
    attack_range = 1.1,
    attack_arc = 110,
    special = "Two-handed, devastating cleaves"
  }
}

-- Create lookup table by ID
M.WEAPON_BY_ID = {}
for _, weapon in ipairs(M.WEAPONS) do
  M.WEAPON_BY_ID[weapon.id] = weapon
end

--- Get weapon definition by ID
---@param weapon_id string
---@return WeaponDefinition?
function M.get_weapon(weapon_id)
  return M.WEAPON_BY_ID[weapon_id]
end

--- Get weapons available for purchase (shop weapons)
---@return WeaponDefinition[]
function M.get_shop_weapons()
  return {
    M.WEAPON_BY_ID.spear,
    M.WEAPON_BY_ID.battleaxe,
    M.WEAPON_BY_ID.longsword
  }
end

--- Calculate attack bonus for weapon based on entity stats
---@param entity table Entity with m20_stats
---@param weapon_id string Weapon ID
---@return number attack_bonus
function M.calculate_attack_bonus(entity, weapon_id)
  local weapon = M.get_weapon(weapon_id)
  if not weapon then return 0 end

  local stats = entity.m20_stats
  if not stats then return 0 end

  -- Base: Level
  local bonus = stats.level

  -- Melee weapons use STR, light weapons can use DEX
  if weapon.category == "ranged" then
    bonus = bonus + math.floor((stats.DEX - 10) / 2)
  elseif weapon.category == "light" then
    -- Fighters and Rogues can use DEX for light weapons (M20 rules page 2)
    local dex_bonus = math.floor((stats.DEX - 10) / 2)
    local str_bonus = math.floor((stats.STR - 10) / 2)
    bonus = bonus + math.max(dex_bonus, str_bonus)
  else
    bonus = bonus + math.floor((stats.STR - 10) / 2)
  end

  -- Class bonuses (Fighter gets +1 per 5 levels, already in level progression)
  -- This is handled in m20_classes.lua

  return bonus
end

--- Calculate damage bonus for weapon based on entity stats
---@param entity table Entity with m20_stats
---@param weapon_id string Weapon ID
---@return number damage_bonus
function M.calculate_damage_bonus(entity, weapon_id)
  local weapon = M.get_weapon(weapon_id)
  if not weapon then return 0 end

  local stats = entity.m20_stats
  if not stats then return 0 end

  -- Melee weapons add STR bonus (x2 for two-handed)
  local str_bonus = math.floor((stats.STR - 10) / 2)

  if weapon.category == "two_handed" then
    return str_bonus * 2
  elseif weapon.category == "ranged" then
    return 0     -- Ranged weapons don't add stat bonus
  else
    return str_bonus
  end
end

--- Equip weapon on entity
---@param entity table Entity with m20_stats
---@param weapon_id string Weapon to equip
---@return boolean success
function M.equip_weapon(entity, weapon_id)
  local weapon = M.get_weapon(weapon_id)
  if not weapon then
    print("[M20 Weapons] Unknown weapon:", weapon_id)
    return false
  end

  -- Create equipped weapon data
  entity.equipped_weapon = {
    weapon_id = weapon_id,
    attack_bonus = M.calculate_attack_bonus(entity, weapon_id),
    damage_bonus = M.calculate_damage_bonus(entity, weapon_id)
  }

  print(string.format("[M20 Weapons] Equipped %s: +%d atk, +%d dmg, %s behavior",
    weapon.name,
    entity.equipped_weapon.attack_bonus,
    entity.equipped_weapon.damage_bonus,
    weapon.attack_behavior))

  return true
end

--- Get currently equipped weapon definition
---@param entity table Entity with equipped_weapon
---@return WeaponDefinition?
function M.get_equipped_weapon(entity)
  if not entity.equipped_weapon then return nil end
  return M.get_weapon(entity.equipped_weapon.weapon_id)
end

--- Get attack parameters for equipped weapon (for animation/collision system)
---@param entity table Entity with equipped_weapon
---@return table? attack_params {speed: number, range: number, arc: number, behavior: string}
function M.get_attack_params(entity)
  local weapon = M.get_equipped_weapon(entity)
  if not weapon then return nil end

  return {
    speed = weapon.attack_speed,
    range = weapon.attack_range,
    arc = weapon.attack_arc,
    behavior = weapon.attack_behavior,
    damage_dice = weapon.damage,
    attack_bonus = entity.equipped_weapon.attack_bonus,
    damage_bonus = entity.equipped_weapon.damage_bonus
  }
end

--- Check if player can afford weapon
---@param player table Player entity with m20_stats.gold
---@param weapon_id string Weapon ID
---@return boolean can_afford
function M.can_afford(player, weapon_id)
  local weapon = M.get_weapon(weapon_id)
  if not weapon then return false end

  local gold = player.m20_stats.gold or 0
  return gold >= weapon.cost
end

--- Purchase weapon (deduct gold, add to inventory)
---@param player table Player entity
---@param weapon_id string Weapon to purchase
---@return boolean success
function M.purchase_weapon(player, weapon_id)
  local weapon = M.get_weapon(weapon_id)
  if not weapon then return false end

  if not M.can_afford(player, weapon_id) then
    print("[M20 Weapons] Cannot afford", weapon.name)
    return false
  end

  -- Deduct gold
  player.m20_stats.gold = player.m20_stats.gold - weapon.cost

  -- Equip weapon immediately (simple inventory system)
  M.equip_weapon(player, weapon_id)

  print(string.format("[M20 Weapons] Purchased %s for %d gp (remaining: %d gp)",
    weapon.name, weapon.cost, player.m20_stats.gold))

  return true
end

return M
