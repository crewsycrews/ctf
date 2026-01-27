-- m20_attributes.lua
-- Microlite20 Attributes Module
-- Manages character stats (STR, DEX, MIND), HP, AC, and stat generation
--
-- Usage:
--   local attrs = require("main.scripts.modules.m20_attributes")
--   local stats = attrs.generate_stats()
--   attrs.initialize_entity(entity, "fighter", "human")

---@class M20Stats
---@field STR number Strength stat (8-20+)
---@field DEX number Dexterity stat (8-20+)
---@field MIND number Mind stat (8-20+)
---@field level number Character level (1+)
---@field xp? number Current experience points
---@field xp_to_next_level? number XP needed for next level
---@field hp_max number Maximum hit points
---@field hp_current number Current hit points
---@field ac number Armor Class
---@field attack_bonus number Default attack bonus
---@field attack_bonus_melee number Melee attack bonus (STR based)
---@field attack_bonus_ranged number Ranged attack bonus (DEX based)
---@field attack_bonus_magic number Magic attack bonus (MIND based)
---@field class string Character class or "monster"
---@field race string Character race
---@field gold? number Gold pieces
---@field hd? number Hit Dice (for monsters)
---@field intelligent? boolean Is intelligent monster
---@field gold_drop? number Gold dropped on death (monsters)

---@class RaceBonus
---@field STR number Strength bonus
---@field DEX number Dexterity bonus
---@field MIND number Mind bonus
---@field skill_bonus number Bonus to all skills

---@class BaseStats
---@field STR number Strength stat
---@field DEX number Dexterity stat
---@field MIND number Mind stat

local dice = require("main.scripts.modules.m20_dice")

local M = {}

-- Race bonuses (M20 core rules)
M.RACE_BONUSES = {
    human = {
        STR = 0,
        DEX = 0,
        MIND = 0,
        skill_bonus = 1  -- +1 to all skill rolls
    },
    elf = {
        STR = 0,
        DEX = 0,
        MIND = 2,
        skill_bonus = 0
    },
    dwarf = {
        STR = 2,
        DEX = 0,
        MIND = 0,
        skill_bonus = 0
    },
    halfling = {
        STR = 0,
        DEX = 2,
        MIND = 0,
        skill_bonus = 0
    }
}

-- Template stat arrays for quick character creation
-- Optimized for each class's primary stats
M.STAT_TEMPLATES = {
    fighter = { STR = 16, DEX = 12, MIND = 10 },
    rogue = { STR = 12, DEX = 16, MIND = 10 },
    mage = { STR = 10, DEX = 12, MIND = 16 },
    cleric = { STR = 12, DEX = 14, MIND = 14 }
}

--- Generate random stats using 4d6 drop lowest (M20 method)
---@return BaseStats stats Generated stats
function M.generate_random_stats()
    return {
        STR = dice.roll_4d6_drop_lowest(),
        DEX = dice.roll_4d6_drop_lowest(),
        MIND = dice.roll_4d6_drop_lowest()
    }
end

--- Get template stats for a class
---@param class_name string "fighter", "rogue", "mage", or "cleric"
---@return BaseStats|nil stats Template stats or nil if invalid class
function M.get_template_stats(class_name)
    local template = M.STAT_TEMPLATES[class_name]
    if not template then
        return nil
    end

    -- Return a copy to avoid mutation
    return {
        STR = template.STR,
        DEX = template.DEX,
        MIND = template.MIND
    }
end

--- Apply race bonuses to stats
---@param stats BaseStats Stats to modify
---@param race string "human", "elf", "dwarf", or "halfling"
---@return BaseStats stats Modified stats with race bonuses applied
function M.apply_race_bonuses(stats, race)
    local bonuses = M.RACE_BONUSES[race]
    if not bonuses then
        print("Unknown race: " .. tostring(race))
        return stats
    end

    stats.STR = stats.STR + bonuses.STR
    stats.DEX = stats.DEX + bonuses.DEX
    stats.MIND = stats.MIND + bonuses.MIND

    return stats
end

-- Calculate initial HP (STR + 1d6 for level 1)
-- @param str_stat (number) Strength stat value
-- @return (number) Initial HP
function M.calculate_initial_hp(str_stat)
    return str_stat + dice.roll(6)
end

-- Calculate base AC (10 + DEX bonus)
-- Equipment will add to this in m20_equipment module
-- @param dex_stat (number) Dexterity stat value
-- @return (number) Base AC
function M.calculate_base_ac(dex_stat)
    return 10 + dice.stat_bonus(dex_stat)
end

-- Calculate base attack bonus (level + stat bonus)
-- @param level (number) Character level
-- @param stat_value (number) Relevant stat (STR for melee, DEX for ranged, MIND for magic)
-- @return (number) Attack bonus
function M.calculate_attack_bonus(level, stat_value)
    return level + dice.stat_bonus(stat_value)
end

--- Initialize M20 stats for an entity (player or monster)
---@param entity table The entity to initialize
---@param class_name? string Class name for players (nil for monsters)
---@param race? string Race name (default: "human")
---@param use_template? boolean Use template stats vs random (default: true)
---@return table entity The entity with m20_stats initialized
function M.initialize_entity(entity, class_name, race, use_template)
    race = race or "human"
    use_template = (use_template == nil) and true or use_template

    -- Generate or get template stats
    local stats
    if class_name and use_template then
        stats = M.get_template_stats(class_name)
        if not stats then
            print("Invalid class, using random stats: " .. tostring(class_name))
            stats = M.generate_random_stats()
        end
    else
        stats = M.generate_random_stats()
    end

    -- Apply race bonuses
    stats = M.apply_race_bonuses(stats, race)

    -- Initialize m20_stats table
    entity.m20_stats = {
        -- Core stats
        STR = stats.STR,
        DEX = stats.DEX,
        MIND = stats.MIND,

        -- Level and XP
        level = 1,
        xp = 0,
        xp_to_next_level = 10,  -- Level up at XP = 10 * current level

        -- HP and AC
        hp_max = M.calculate_initial_hp(stats.STR),
        hp_current = 0,  -- Set to hp_max after this
        ac = M.calculate_base_ac(stats.DEX),

        -- Combat stats (calculated from level + stats)
        attack_bonus = M.calculate_attack_bonus(1, stats.STR),  -- Default to STR
        attack_bonus_melee = M.calculate_attack_bonus(1, stats.STR),
        attack_bonus_ranged = M.calculate_attack_bonus(1, stats.DEX),
        attack_bonus_magic = M.calculate_attack_bonus(1, stats.MIND),

        -- Class and race
        class = class_name or "monster",
        race = race,

        -- Gold (for shop system)
        -- Players start with 150 gold, monsters start with 0
        gold = class_name and 150 or 0
    }

    -- Set current HP to max
    entity.m20_stats.hp_current = entity.m20_stats.hp_max

    return entity
end

--- Initialize monster stats based on Hit Dice (HD)
---@param entity table The monster entity
---@param hd number Hit Dice (determines all stats)
---@param intelligent? boolean If true, gets +3 to one skill
---@return table entity The entity with m20_stats initialized
function M.initialize_monster(entity, hd, intelligent)
    intelligent = intelligent or false

    -- For monsters: stats are based on HD
    -- Default stats of 10 + HD
    local str = 10 + hd
    local dex = 10 + hd
    local mind = 10

    -- Calculate HP: HD × d8 (with 2x multiplier for action gameplay)
    local hp = dice.roll(8, hd) * 2

    -- Calculate AC based on HD (rough formula: 10 + HD + DEX bonus)
    local ac = 10 + hd + dice.stat_bonus(dex)

    entity.m20_stats = {
        -- Core stats
        STR = str,
        DEX = dex,
        MIND = mind,

        -- Level (for monsters, level = HD)
        level = hd,
        hd = hd,

        -- HP and AC
        hp_max = hp,
        hp_current = hp,
        ac = ac,

        -- Combat stats (attack bonus = HD)
        attack_bonus = hd,
        attack_bonus_melee = hd,
        attack_bonus_ranged = hd,
        attack_bonus_magic = hd,

        -- Class and race
        class = "monster",
        race = "monster",

        -- Monster-specific
        intelligent = intelligent,

        -- Gold drops (1d6 × HD gold pieces)
        gold_drop = dice.roll(6) * hd
    }

    return entity
end

-- Recalculate derived stats after stat changes (level-up, equipment, etc.)
-- @param entity (table) Entity with m20_stats
function M.recalculate_derived_stats(entity)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local stats = entity.m20_stats

    -- Recalculate AC (base + equipment will be added by equipment module)
    stats.ac = 10 + dice.stat_bonus(stats.DEX)

    -- Recalculate attack bonuses
    stats.attack_bonus_melee = M.calculate_attack_bonus(stats.level, stats.STR)
    stats.attack_bonus_ranged = M.calculate_attack_bonus(stats.level, stats.DEX)
    stats.attack_bonus_magic = M.calculate_attack_bonus(stats.level, stats.MIND)

    -- Default attack bonus (usually melee for fighters, ranged for rogues, etc.)
    -- This will be set by class module based on class type
    stats.attack_bonus = stats.attack_bonus_melee
end

-- Take damage and update HP
-- @param entity (table) Entity with m20_stats
-- @param damage (number) Amount of damage to take
-- @return (bool) True if entity is still alive, false if dead (HP <= 0)
function M.take_damage(entity, damage)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    entity.m20_stats.hp_current = entity.m20_stats.hp_current - damage

    -- Clamp to 0
    if entity.m20_stats.hp_current < 0 then
        entity.m20_stats.hp_current = 0
    end

    return entity.m20_stats.hp_current > 0
end

-- Heal HP (cannot exceed max)
-- @param entity (table) Entity with m20_stats
-- @param amount (number) Amount to heal
-- @return (number) Actual amount healed
function M.heal(entity, amount)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local old_hp = entity.m20_stats.hp_current
    entity.m20_stats.hp_current = math.min(
        entity.m20_stats.hp_current + amount,
        entity.m20_stats.hp_max
    )

    return entity.m20_stats.hp_current - old_hp
end

-- Check if entity can cast a spell (has enough HP)
-- @param entity (table) Entity with m20_stats
-- @param spell_level (number) Spell level (0-9)
-- @param is_signature (bool, optional) If true, costs -1 HP
-- @return (bool) True if entity has enough HP to cast
function M.can_cast_spell(entity, spell_level, is_signature)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local cost = 1 + (spell_level * 2)
    if is_signature then
        cost = cost - 1
    end

    return entity.m20_stats.hp_current >= cost
end

-- Pay HP cost for casting a spell
-- @param entity (table) Entity with m20_stats
-- @param spell_level (number) Spell level (0-9)
-- @param is_signature (bool, optional) If true, costs -1 HP
-- @return (bool) True if cost was paid, false if not enough HP
function M.pay_spell_cost(entity, spell_level, is_signature)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local cost = 1 + (spell_level * 2)
    if is_signature then
        cost = cost - 1
    end

    if entity.m20_stats.hp_current < cost then
        return false
    end

    entity.m20_stats.hp_current = entity.m20_stats.hp_current - cost
    return true
end

--- Add gold to entity
---@param entity table Entity with m20_stats
---@param amount number Gold to add
---@return number new_gold New gold total
function M.add_gold(entity, amount)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")
    assert(amount >= 0, "Gold amount must be non-negative")

    entity.m20_stats.gold = (entity.m20_stats.gold or 0) + amount
    return entity.m20_stats.gold
end

--- Remove gold from entity (with check)
---@param entity table Entity with m20_stats
---@param amount number Gold to remove
---@return boolean success Whether gold was removed (false if insufficient)
---@return number remaining Gold remaining after removal
function M.remove_gold(entity, amount)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")
    assert(amount >= 0, "Gold amount must be non-negative")

    local current_gold = entity.m20_stats.gold or 0

    if current_gold < amount then
        return false, current_gold
    end

    entity.m20_stats.gold = current_gold - amount
    return true, entity.m20_stats.gold
end

--- Check if entity has enough gold
---@param entity table Entity with m20_stats
---@param amount number Gold required
---@return boolean has_gold Whether entity has enough gold
function M.has_gold(entity, amount)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")
    return (entity.m20_stats.gold or 0) >= amount
end

--- Set starting gold for new player character
---@param entity table Entity with m20_stats
---@param amount? number Starting gold (default: 150)
function M.set_starting_gold(entity, amount)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")
    amount = amount or 150  -- Default starting gold
    entity.m20_stats.gold = amount
end

return M
