-- main/scripts/modules/m20_weapons.lua
-- Microlite20 Weapons System for Cosmic Tree Fighters
-- Weapon equipment, damage calculation, and combat behaviors

local M = {}

---@class WeaponDefinition
---@field id string Weapon ID
---@field name string Display name
---@field attack_type string "melee" | "ranged" | "magic"
---@field attack_stat string "STR" | "DEX" | "MIND"
---@field damage string Damage dice notation (e.g., "1d8")
---@field cost number Gold piece cost
---@field range number Attack range multiplier
---@field speed number Attack speed multiplier (1.0 = normal)
---@field special string Special properties description

---@class EquippedWeapon
---@field weapon_id string ID of equipped weapon
---@field damage_bonus number Current damage bonus from stats/class
---@field attack_bonus number Current attack bonus from stats/class

-- Weapon definitions - 3 core weapons (one per primary stat)
M.WEAPONS = {
  {
    id = "longsword",
    name = "Longsword",
    attack_type = "melee",
    attack_stat = "STR",
    damage = "1d8",
    cost = 50,
    range = 1.0,
    speed = 1.0,
    special = "Melee weapon with\nshort-range hitbox."
  },
  {
    id = "longbow",
    name = "Longbow",
    attack_type = "ranged",
    attack_stat = "DEX",
    damage = "1d8",
    cost = 50,
    range = 3.0,
    speed = 1.0,
    special = "Ranged weapon with\nlong-range projectile"
  },
  {
    id = "staff",
    name = "Staff",
    attack_type = "magic",
    attack_stat = "MIND",
    damage = "1d8",
    cost = 50,
    range = 2.0,
    speed = 1.0,
    special = "Magic weapon with\nspell projectile"
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
    M.WEAPON_BY_ID.longsword,
    M.WEAPON_BY_ID.longbow,
    M.WEAPON_BY_ID.staff
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

  -- Add stat bonus based on weapon's attack_stat
  local stat_value = stats[weapon.attack_stat] or 10
  local stat_bonus = math.floor((stat_value - 10) / 2)
  bonus = bonus + stat_bonus

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

  -- All weapons add their corresponding stat bonus to damage
  local stat_value = stats[weapon.attack_stat] or 10
  local stat_bonus = math.floor((stat_value - 10) / 2)

  return stat_bonus
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

  print(string.format("[M20 Weapons] Equipped %s: +%d atk, +%d dmg (%s)",
    weapon.name,
    entity.equipped_weapon.attack_bonus,
    entity.equipped_weapon.damage_bonus,
    weapon.attack_type))

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
---@return table? attack_params {speed: number, range: number, type: string, stat: string, damage_dice: string}
function M.get_attack_params(entity)
  local weapon = M.get_equipped_weapon(entity)
  if not weapon then return nil end

  return {
    speed = weapon.speed,
    range = weapon.range,
    type = weapon.attack_type,
    stat = weapon.attack_stat,
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
