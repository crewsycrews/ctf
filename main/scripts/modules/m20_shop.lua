--- M20 Shop System Module
--- Handles buying/selling spells, equipment, and consumables
--- @module m20_shop

local M = {}

local attrs = require("main.scripts.modules.m20_attributes")
local magic = require("main.scripts.modules.m20_magic")
local equipment = require("main.scripts.modules.m20_equipment")
local spells = require("main.scripts.modules.m20_spells")

---@class ShopItem
---@field id string Item identifier
---@field name string Display name
---@field type string "spell", "equipment", or "consumable"
---@field price number Gold cost
---@field description string Item description
---@field spell_level? number Spell level (for spells only)
---@field equipment_data? EquipmentItem Equipment data (for equipment only)

---@class ShopTransaction
---@field success boolean Whether transaction succeeded
---@field message string Result message
---@field gold_remaining number Player's gold after transaction
---@field item_id string Item identifier
---@field price number Transaction price

-- Spell prices by level
M.SPELL_PRICES = {
    [0] = 20,   -- Cantrips
    [1] = 50,   -- Level 1
    [2] = 100,  -- Level 2
    [3] = 200,  -- Level 3
    [4] = 350,  -- Level 4
    [5] = 500   -- Level 5
}

-- Sell price multiplier (sell for 50% of purchase price)
M.SELL_MULTIPLIER = 0.5

--- Get all spells available for purchase
---@return ShopItem[] items Array of spell shop items
function M.get_spell_inventory()
    local spell_inventory = {}

    -- Get all spells from m20_spells module
    local all_spells = spells.get_all_spells()

    for _, spell in ipairs(all_spells) do
        -- Only include spells that have CTF mappings for now
        local ctf_spell = spells.get_ctf_spell_id(spell.id)
        if ctf_spell then
            table.insert(spell_inventory, {
                id = spell.id,
                name = spell.name,
                type = "spell",
                price = M.SPELL_PRICES[spell.level] or 100,
                description = spell.description,
                spell_level = spell.level
            })
        end
    end

    -- Sort by level, then by name
    table.sort(spell_inventory, function(a, b)
        if a.spell_level == b.spell_level then
            return a.name < b.name
        end
        return a.spell_level < b.spell_level
    end)

    return spell_inventory
end

--- Get all equipment available for purchase
---@return ShopItem[] items Array of equipment shop items
function M.get_equipment_inventory()
    local equip_inventory = {}

    for item_id, item_data in pairs(equipment.ITEMS) do
        if item_data.type ~= "consumable" then
            table.insert(equip_inventory, {
                id = item_id,
                name = item_data.name,
                type = "equipment",
                price = item_data.price,
                description = item_data.description,
                equipment_data = item_data
            })
        end
    end

    -- Sort by type, then by price
    table.sort(equip_inventory, function(a, b)
        if a.equipment_data.type == b.equipment_data.type then
            return a.price < b.price
        end
        return a.equipment_data.type < b.equipment_data.type
    end)

    return equip_inventory
end

--- Get all consumables available for purchase
---@return ShopItem[] items Array of consumable shop items
function M.get_consumable_inventory()
    local consumable_inventory = {}

    for item_id, item_data in pairs(equipment.ITEMS) do
        if item_data.type == "consumable" then
            table.insert(consumable_inventory, {
                id = item_id,
                name = item_data.name,
                type = "consumable",
                price = item_data.price,
                description = item_data.description,
                equipment_data = item_data
            })
        end
    end

    -- Sort by price
    table.sort(consumable_inventory, function(a, b)
        return a.price < b.price
    end)

    return consumable_inventory
end

--- Get all shop items (spells + equipment + consumables)
---@return table shop_inventory Table with spell_items, equipment_items, consumable_items
function M.get_full_inventory()
    return {
        spells = M.get_spell_inventory(),
        equipment = M.get_equipment_inventory(),
        consumables = M.get_consumable_inventory()
    }
end

--- Buy a spell
---@param entity table Player entity with m20_stats and spellbook
---@param spell_id string Spell identifier
---@return ShopTransaction result Transaction result
function M.buy_spell(entity, spell_id)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    -- Get spell data
    local spell = spells.get_spell(spell_id)
    if not spell then
        return {
            success = false,
            message = "Spell not found",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = spell_id,
            price = 0
        }
    end

    -- Check if already learned
    if magic.knows_spell(entity, spell_id) then
        return {
            success = false,
            message = "Already learned " .. spell.name,
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = spell_id,
            price = 0
        }
    end

    -- Check price
    local price = M.SPELL_PRICES[spell.level] or 100

    if not attrs.has_gold(entity, price) then
        return {
            success = false,
            message = string.format("Not enough gold (need %d, have %d)", price, entity.m20_stats.gold or 0),
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = spell_id,
            price = price
        }
    end

    -- Deduct gold
    local gold_success, gold_remaining = attrs.remove_gold(entity, price)
    if not gold_success then
        return {
            success = false,
            message = "Failed to deduct gold",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = spell_id,
            price = price
        }
    end

    -- Learn spell
    local learn_success, learn_msg = magic.learn_spell(entity, spell_id)
    if not learn_success then
        -- Refund gold if learning failed
        attrs.add_gold(entity, price)
        return {
            success = false,
            message = learn_msg or "Failed to learn spell",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = spell_id,
            price = price
        }
    end

    return {
        success = true,
        message = string.format("Learned %s for %d gold", spell.name, price),
        gold_remaining = gold_remaining,
        item_id = spell_id,
        price = price
    }
end

--- Buy equipment
---@param entity table Player entity with m20_stats and equipped_items
---@param item_id string Equipment item identifier
---@return ShopTransaction result Transaction result
function M.buy_equipment(entity, item_id)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    -- Get equipment data
    local item = equipment.get_item(item_id)
    if not item then
        return {
            success = false,
            message = "Item not found",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = 0
        }
    end

    -- Check if can equip (class restrictions)
    local can_equip, equip_error = equipment.can_equip(entity, item)
    if not can_equip then
        return {
            success = false,
            message = equip_error or "Cannot equip this item",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = item.price
        }
    end

    -- Check price
    if not attrs.has_gold(entity, item.price) then
        return {
            success = false,
            message = string.format("Not enough gold (need %d, have %d)", item.price, entity.m20_stats.gold or 0),
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = item.price
        }
    end

    -- Deduct gold
    local gold_success, gold_remaining = attrs.remove_gold(entity, item.price)
    if not gold_success then
        return {
            success = false,
            message = "Failed to deduct gold",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = item.price
        }
    end

    -- Equip item automatically (will unequip previous item in slot)
    local equip_success, equip_msg = equipment.equip_item(entity, item)
    if not equip_success then
        -- Refund gold if equipping failed
        attrs.add_gold(entity, item.price)
        return {
            success = false,
            message = equip_msg or "Failed to equip item",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = item.price
        }
    end

    return {
        success = true,
        message = string.format("Bought and equipped %s for %d gold", item.name, item.price),
        gold_remaining = gold_remaining,
        item_id = item_id,
        price = item.price
    }
end

--- Buy consumable
---@param entity table Player entity with m20_stats and equipped_items
---@param item_id string Consumable item identifier
---@return ShopTransaction result Transaction result
function M.buy_consumable(entity, item_id)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    -- Get consumable data
    local item = equipment.get_item(item_id)
    if not item or item.type ~= "consumable" then
        return {
            success = false,
            message = "Consumable not found",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = 0
        }
    end

    -- Check price
    if not attrs.has_gold(entity, item.price) then
        return {
            success = false,
            message = string.format("Not enough gold (need %d, have %d)", item.price, entity.m20_stats.gold or 0),
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = item.price
        }
    end

    -- Check inventory space
    if not entity.equipped_items then
        equipment.initialize_equipment(entity)
    end

    if #entity.equipped_items.consumables >= 5 then
        return {
            success = false,
            message = "Consumable inventory full (max 5)",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = item.price
        }
    end

    -- Deduct gold
    local gold_success, gold_remaining = attrs.remove_gold(entity, item.price)
    if not gold_success then
        return {
            success = false,
            message = "Failed to deduct gold",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = item.price
        }
    end

    -- Add to inventory
    local add_success, add_msg = equipment.add_consumable(entity, item)
    if not add_success then
        -- Refund gold if adding failed
        attrs.add_gold(entity, item.price)
        return {
            success = false,
            message = add_msg or "Failed to add consumable",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = item.price
        }
    end

    return {
        success = true,
        message = string.format("Bought %s for %d gold", item.name, item.price),
        gold_remaining = gold_remaining,
        item_id = item_id,
        price = item.price
    }
end

--- Sell equipment (for 50% of purchase price)
---@param entity table Player entity with m20_stats and equipped_items
---@param slot string Equipment slot: "armor", "weapon", "shield"
---@return ShopTransaction result Transaction result
function M.sell_equipment(entity, slot)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    if not entity.equipped_items or not entity.equipped_items[slot] then
        return {
            success = false,
            message = "No item equipped in " .. slot,
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = "",
            price = 0
        }
    end

    local item = entity.equipped_items[slot]
    local sell_price = math.floor(item.price * M.SELL_MULTIPLIER)

    -- Unequip item
    local unequip_success, unequip_msg = equipment.unequip_item(entity, slot)
    if not unequip_success then
        return {
            success = false,
            message = unequip_msg or "Failed to unequip item",
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item.id,
            price = sell_price
        }
    end

    -- Add gold
    local new_gold = attrs.add_gold(entity, sell_price)

    return {
        success = true,
        message = string.format("Sold %s for %d gold", item.name, sell_price),
        gold_remaining = new_gold,
        item_id = item.id,
        price = sell_price
    }
end

--- Generic buy function that routes to appropriate handler
---@param entity table Player entity
---@param item_type string "spell", "equipment", or "consumable"
---@param item_id string Item identifier
---@return ShopTransaction result Transaction result
function M.buy_item(entity, item_type, item_id)
    if item_type == "spell" then
        return M.buy_spell(entity, item_id)
    elseif item_type == "equipment" then
        return M.buy_equipment(entity, item_id)
    elseif item_type == "consumable" then
        return M.buy_consumable(entity, item_id)
    else
        return {
            success = false,
            message = "Unknown item type: " .. tostring(item_type),
            gold_remaining = entity.m20_stats.gold or 0,
            item_id = item_id,
            price = 0
        }
    end
end

return M
