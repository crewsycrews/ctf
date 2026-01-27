--- M20 Equipment System Module
--- Handles armor, weapons, shields, consumables, and equipment management
--- @module m20_equipment

local M = {}

local attrs = require("main.scripts.modules.m20_attributes")
local dice = require("main.scripts.modules.m20_dice")

---@class EquipmentItem
---@field id string Unique item identifier
---@field name string Display name
---@field type string Item type: "armor", "weapon", "shield", "consumable"
---@field subtype? string Subtype: "light", "medium", "heavy" for armor; "simple", "martial" for weapons
---@field price number Gold cost
---@field ac_bonus? number Armor Class bonus
---@field damage_dice? string Damage dice notation (e.g., "1d6", "1d8+2")
---@field effect? string Description of consumable effect
---@field required_class? string[] Classes that can use this item
---@field description string Item description

---@class EquippedItems
---@field armor? EquipmentItem Currently equipped armor
---@field weapon? EquipmentItem Currently equipped weapon
---@field shield? EquipmentItem Currently equipped shield
---@field consumables EquipmentItem[] Consumable items in inventory (max 5)

--- Item database with all available equipment
---@type table<string, EquipmentItem>
M.ITEMS = {
  -- ARMOR (Light)
  leather_armor = {
    id = "leather_armor",
    name = "Leather Armor",
    type = "armor",
    subtype = "light",
    price = 30,
    ac_bonus = 2,
    description = "+2 AC, no movement penalty"
  },

  -- ARMOR (Medium)
  chainmail = {
    id = "chainmail",
    name = "Chainmail",
    type = "armor",
    subtype = "medium",
    price = 70,
    ac_bonus = 4,
    required_class = {"fighter", "cleric"},
    description = "+4 AC, requires Fighter/Cleric"
  },

  -- ARMOR (Heavy)
  plate_armor = {
    id = "plate_armor",
    name = "Plate Armor",
    type = "armor",
    subtype = "heavy",
    price = 150,
    ac_bonus = 6,
    required_class = {"fighter"},
    description = "+6 AC, requires Fighter"
  },

  -- WEAPONS (Simple)
  dagger = {
    id = "dagger",
    name = "Dagger",
    type = "weapon",
    subtype = "simple",
    price = 20,
    damage_dice = "1d4",
    description = "1d4 damage, usable by all classes"
  },

  club = {
    id = "club",
    name = "Club",
    type = "weapon",
    subtype = "simple",
    price = 25,
    damage_dice = "1d6",
    description = "1d6 damage, usable by all classes"
  },

  shortbow = {
    id = "shortbow",
    name = "Shortbow",
    type = "weapon",
    subtype = "simple",
    price = 40,
    damage_dice = "1d6",
    description = "1d6 ranged damage, usable by all classes"
  },

  -- WEAPONS (Martial)
  longsword = {
    id = "longsword",
    name = "Longsword",
    type = "weapon",
    subtype = "martial",
    price = 60,
    damage_dice = "1d8",
    required_class = {"fighter"},
    description = "1d8 damage, requires Fighter"
  },

  battleaxe = {
    id = "battleaxe",
    name = "Battleaxe",
    type = "weapon",
    subtype = "martial",
    price = 70,
    damage_dice = "1d8",
    required_class = {"fighter"},
    description = "1d8 damage, requires Fighter"
  },

  greatsword = {
    id = "greatsword",
    name = "Greatsword",
    type = "weapon",
    subtype = "martial",
    price = 100,
    damage_dice = "2d6",
    required_class = {"fighter"},
    description = "2d6 damage, requires Fighter (two-handed)"
  },

  -- SHIELDS
  wooden_shield = {
    id = "wooden_shield",
    name = "Wooden Shield",
    type = "shield",
    price = 30,
    ac_bonus = 1,
    description = "+1 AC, usable by all classes"
  },

  steel_shield = {
    id = "steel_shield",
    name = "Steel Shield",
    type = "shield",
    price = 50,
    ac_bonus = 2,
    required_class = {"fighter", "cleric"},
    description = "+2 AC, requires Fighter/Cleric"
  },

  -- CONSUMABLES
  minor_hp_potion = {
    id = "minor_hp_potion",
    name = "Minor HP Potion",
    type = "consumable",
    price = 30,
    effect = "2d6",
    description = "Heals 2d6 HP"
  },

  major_hp_potion = {
    id = "major_hp_potion",
    name = "Major HP Potion",
    type = "consumable",
    price = 80,
    effect = "4d6",
    description = "Heals 4d6 HP"
  },

  antidote = {
    id = "antidote",
    name = "Antidote",
    type = "consumable",
    price = 40,
    effect = "remove_poison",
    description = "Removes poison and disease effects"
  },
}

--- Get item by ID
---@param item_id string Item identifier
---@return EquipmentItem? item Item data or nil if not found
function M.get_item(item_id)
  return M.ITEMS[item_id]
end

--- Get all items of a specific type
---@param item_type string Item type: "armor", "weapon", "shield", "consumable"
---@return EquipmentItem[] items Array of items matching type
function M.get_items_by_type(item_type)
  local result = {}
  for id, item in pairs(M.ITEMS) do
    if item.type == item_type then
      table.insert(result, item)
    end
  end

  -- Sort by price
  table.sort(result, function(a, b) return a.price < b.price end)
  return result
end

--- Check if entity can equip item (class restrictions)
---@param entity table Entity with m20_stats
---@param item EquipmentItem Item to check
---@return boolean can_equip Whether entity can equip item
---@return string? error_msg Error message if can't equip
function M.can_equip(entity, item)
  if not entity.m20_stats then
    return false, "Entity has no M20 stats"
  end

  -- Check class restrictions
  if item.required_class then
    local has_class = false
    for _, class in ipairs(item.required_class) do
      if entity.m20_stats.class == class then
        has_class = true
        break
      end
    end

    if not has_class then
      local classes_str = table.concat(item.required_class, "/")
      return false, "Requires " .. classes_str .. " class"
    end
  end

  return true, nil
end

--- Equip an item to entity
---@param entity table Entity with m20_stats and equipped_items
---@param item EquipmentItem Item to equip
---@return boolean success Whether item was equipped
---@return string? message Success or error message
function M.equip_item(entity, item)
  if not entity.m20_stats then
    return false, "Entity has no M20 stats"
  end

  -- Initialize equipped_items if not present
  if not entity.equipped_items then
    entity.equipped_items = {
      armor = nil,
      weapon = nil,
      shield = nil,
      consumables = {}
    }
  end

  -- Check if entity can equip this item
  local can_equip, error_msg = M.can_equip(entity, item)
  if not can_equip then
    return false, error_msg
  end

  -- Unequip previous item of same type (if any)
  if item.type == "armor" and entity.equipped_items.armor then
    M.unequip_item(entity, "armor")
  elseif item.type == "weapon" and entity.equipped_items.weapon then
    M.unequip_item(entity, "weapon")
  elseif item.type == "shield" and entity.equipped_items.shield then
    M.unequip_item(entity, "shield")
  end

  -- Equip the item
  if item.type == "armor" then
    entity.equipped_items.armor = item
  elseif item.type == "weapon" then
    entity.equipped_items.weapon = item
  elseif item.type == "shield" then
    entity.equipped_items.shield = item
  elseif item.type == "consumable" then
    return false, "Use use_consumable() for consumables"
  end

  -- Recalculate AC with new equipment
  M.recalculate_ac(entity)

  return true, "Equipped " .. item.name
end

--- Unequip an item from entity
---@param entity table Entity with equipped_items
---@param slot string Slot to unequip: "armor", "weapon", "shield"
---@return boolean success Whether item was unequipped
---@return string? message Success or error message
function M.unequip_item(entity, slot)
  if not entity.equipped_items then
    return false, "No items equipped"
  end

  local item = entity.equipped_items[slot]
  if not item then
    return false, "No item in " .. slot .. " slot"
  end

  entity.equipped_items[slot] = nil

  -- Recalculate AC after unequipping
  M.recalculate_ac(entity)

  return true, "Unequipped " .. item.name
end

--- Recalculate AC based on equipped items
---@param entity table Entity with m20_stats and equipped_items
function M.recalculate_ac(entity)
  if not entity.m20_stats then return end

  -- Base AC = 10 + DEX bonus
  local base_ac = 10 + dice.stat_bonus(entity.m20_stats.DEX)

  -- Add armor bonus
  if entity.equipped_items and entity.equipped_items.armor then
    base_ac = base_ac + (entity.equipped_items.armor.ac_bonus or 0)
  end

  -- Add shield bonus
  if entity.equipped_items and entity.equipped_items.shield then
    base_ac = base_ac + (entity.equipped_items.shield.ac_bonus or 0)
  end

  entity.m20_stats.ac = base_ac
end

--- Get weapon damage dice for entity
---@param entity table Entity with equipped_items
---@return string damage_dice Damage dice notation (e.g., "1d6")
function M.get_weapon_damage(entity)
  if entity.equipped_items and entity.equipped_items.weapon then
    return entity.equipped_items.weapon.damage_dice or "1d4"
  end

  -- Unarmed strike
  return "1d3"
end

--- Add consumable to inventory
---@param entity table Entity with equipped_items
---@param item EquipmentItem Consumable item to add
---@return boolean success Whether item was added
---@return string? message Success or error message
function M.add_consumable(entity, item)
  if item.type ~= "consumable" then
    return false, "Item is not a consumable"
  end

  -- Initialize equipped_items if not present
  if not entity.equipped_items then
    entity.equipped_items = {
      armor = nil,
      weapon = nil,
      shield = nil,
      consumables = {}
    }
  end

  -- Check inventory limit
  if #entity.equipped_items.consumables >= 5 then
    return false, "Consumable inventory full (max 5)"
  end

  table.insert(entity.equipped_items.consumables, item)
  return true, "Added " .. item.name .. " to inventory"
end

--- Use a consumable item
---@param entity table Entity with m20_stats and equipped_items
---@param item_id string Consumable item ID
---@return boolean success Whether item was used
---@return string? message Result message
function M.use_consumable(entity, item_id)
  if not entity.equipped_items or not entity.equipped_items.consumables then
    return false, "No consumables in inventory"
  end

  -- Find consumable in inventory
  local item_index = nil
  local item = nil
  for i, consumable in ipairs(entity.equipped_items.consumables) do
    if consumable.id == item_id then
      item_index = i
      item = consumable
      break
    end
  end

  if not item then
    return false, "Consumable not found in inventory"
  end

  -- Apply consumable effect
  local result_msg = ""

  if item.effect:match("^%d+d%d+$") then
    -- Healing potion (dice notation)
    local heal_amount = dice.damage_roll(item.effect, 0)
    attrs.heal(entity, heal_amount)
    result_msg = string.format("Healed %d HP with %s", heal_amount, item.name)
  elseif item.effect == "remove_poison" then
    -- Antidote
    -- TODO: Implement poison/disease removal when status system expanded
    result_msg = "Used " .. item.name .. " (poison removed)"
  else
    result_msg = "Used " .. item.name
  end

  -- Remove consumable from inventory
  table.remove(entity.equipped_items.consumables, item_index)

  return true, result_msg
end

--- Get total equipment AC bonus
---@param entity table Entity with equipped_items
---@return number ac_bonus Total AC bonus from equipment
function M.get_equipment_ac_bonus(entity)
  local bonus = 0

  if entity.equipped_items then
    if entity.equipped_items.armor then
      bonus = bonus + (entity.equipped_items.armor.ac_bonus or 0)
    end
    if entity.equipped_items.shield then
      bonus = bonus + (entity.equipped_items.shield.ac_bonus or 0)
    end
  end

  return bonus
end

--- Initialize equipment for new entity
---@param entity table Entity to initialize
function M.initialize_equipment(entity)
  entity.equipped_items = {
    armor = nil,
    weapon = nil,
    shield = nil,
    consumables = {}
  }
end

return M
