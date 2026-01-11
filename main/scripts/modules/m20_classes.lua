-- m20_classes.lua
-- Microlite20 Character Classes Module
-- Manages the 4 base classes: Fighter, Rogue, Mage, Cleric
--
-- Usage:
--   local classes = require("main.scripts.modules.m20_classes")
--   classes.apply_class_features(entity, "fighter")

---@class ClassInfo
---@field name string Class name
---@field description string Class description
---@field primary_stat string "STR", "DEX", or "MIND"
---@field armor_proficiency string Armor types allowed
---@field weapon_proficiency string Weapon types allowed
---@field special_ability string Special class feature
---@field hit_die number Hit die size (d6, d8, etc.)

local M = {}

-- M20 Class Definitions
M.CLASSES = {
    fighter = {
        name = "Fighter",
        description = "Master of weapons and armor, excelling in melee combat",
        primary_stat = "STR",
        armor_proficiency = "Any armor and shields",
        weapon_proficiency = "All weapons",
        special_ability = "+3 Physical skill, +1 attack/damage every 5 levels",
        hit_die = 6,
        can_cast_spells = false
    },
    rogue = {
        name = "Rogue",
        description = "Skilled in stealth and trickery, deadly with precision strikes",
        primary_stat = "DEX",
        armor_proficiency = "Light armor only",
        weapon_proficiency = "Light weapons and ranged weapons",
        special_ability = "+3 Subterfuge skill, sneak attack damage",
        hit_die = 6,
        can_cast_spells = false
    },
    mage = {
        name = "Mage",
        description = "Arcane spellcaster wielding destructive magical power",
        primary_stat = "MIND",
        armor_proficiency = "No armor",
        weapon_proficiency = "Simple weapons (staff, dagger)",
        special_ability = "+3 Knowledge skill, cast arcane spells",
        hit_die = 6,
        can_cast_spells = true,
        spell_type = "arcane"
    },
    cleric = {
        name = "Cleric",
        description = "Divine spellcaster channeling holy power to heal and protect",
        primary_stat = "MIND",
        armor_proficiency = "Light and medium armor",
        weapon_proficiency = "Simple weapons",
        special_ability = "+3 Communication skill, cast divine spells, Turn Undead",
        hit_die = 6,
        can_cast_spells = true,
        spell_type = "divine"
    }
}

--- Get class information
---@param class_name string Class name ("fighter", "rogue", "mage", "cleric")
---@return ClassInfo|nil info Class info or nil if invalid
function M.get_class_info(class_name)
    return M.CLASSES[class_name]
end

--- Check if a class can cast spells
---@param class_name string Class name
---@return boolean can_cast True if class can cast spells
function M.can_cast_spells(class_name)
    local class_info = M.CLASSES[class_name]
    return class_info and class_info.can_cast_spells or false
end

--- Get spell type for a class (arcane or divine)
---@param class_name string Class name
---@return string|nil spell_type "arcane", "divine", or nil if can't cast
function M.get_spell_type(class_name)
    local class_info = M.CLASSES[class_name]
    if class_info and class_info.can_cast_spells then
        return class_info.spell_type
    end
    return nil
end

--- Apply class-specific bonuses to an entity
--- This is called during character creation and level-up
---@param entity table Entity with m20_stats
---@param class_name string Class name
function M.apply_class_features(entity, class_name)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local class_info = M.CLASSES[class_name]
    if not class_info then
        print("Unknown class: " .. tostring(class_name))
        return
    end

    local stats = entity.m20_stats
    local level = stats.level

    -- Fighter: +1 attack and damage at levels 5, 10, 15, 20
    if class_name == "fighter" then
        if level >= 5 then
            local fighter_bonus = math.floor(level / 5)
            stats.fighter_attack_bonus = fighter_bonus
            stats.fighter_damage_bonus = fighter_bonus
        end
    end

    -- Rogue: Sneak attack damage scales with level
    if class_name == "rogue" then
        -- Sneak attack: +1d6 damage per 5 levels when attacking from advantage
        stats.sneak_attack_dice = math.max(1, math.floor(level / 5))
    end

    -- Mage: Maximum spell level based on character level
    if class_name == "mage" then
        stats.max_spell_level = math.ceil(level / 2)
        stats.spell_type = "arcane"
    end

    -- Cleric: Maximum spell level and Turn Undead
    if class_name == "cleric" then
        stats.max_spell_level = math.ceil(level / 2)
        stats.spell_type = "divine"

        -- Turn Undead DC = 10 + level + MIND bonus
        local dice = require("main.scripts.modules.m20_dice")
        stats.turn_undead_dc = 10 + level + dice.stat_bonus(stats.MIND)
    end
end

--- Get primary stat for a class
---@param class_name string Class name
---@return string stat "STR", "DEX", or "MIND"
function M.get_primary_stat(class_name)
    local class_info = M.CLASSES[class_name]
    return class_info and class_info.primary_stat or "STR"
end

--- Calculate sneak attack damage for rogues
---@param rogue_entity table Rogue entity with m20_stats
---@param base_damage number Base weapon damage
---@return number total_damage Base damage + sneak attack dice
function M.calculate_sneak_attack_damage(rogue_entity, base_damage)
    assert(rogue_entity and rogue_entity.m20_stats, "Entity must have m20_stats")

    local stats = rogue_entity.m20_stats
    local sneak_dice = stats.sneak_attack_dice or 1

    -- Roll sneak attack dice (d6 per 5 levels)
    local dice = require("main.scripts.modules.m20_dice")
    local sneak_damage = dice.roll(6, sneak_dice)

    return base_damage + sneak_damage
end

--- Check if entity meets armor proficiency requirements
---@param entity table Entity with m20_stats
---@param armor_type string "light", "medium", or "heavy"
---@return boolean proficient True if proficient with this armor type
function M.has_armor_proficiency(entity, armor_type)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local class_name = entity.m20_stats.class

    if class_name == "fighter" then
        return true -- All armor
    elseif class_name == "rogue" then
        return armor_type == "light"
    elseif class_name == "mage" then
        return false -- No armor
    elseif class_name == "cleric" then
        return armor_type == "light" or armor_type == "medium"
    end

    return false
end

--- Check if entity meets weapon proficiency requirements
---@param entity table Entity with m20_stats
---@param weapon_type string "light", "one-handed", "two-handed", "ranged"
---@return boolean proficient True if proficient with this weapon type
function M.has_weapon_proficiency(entity, weapon_type)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local class_name = entity.m20_stats.class

    if class_name == "fighter" then
        return true -- All weapons
    elseif class_name == "rogue" then
        return weapon_type == "light" or weapon_type == "ranged"
    elseif class_name == "mage" or class_name == "cleric" then
        return weapon_type == "light" -- Simple weapons only
    end

    return false
end

--- Get all available classes as a list for UI
---@return table classes Array of class names
function M.get_all_class_names()
    return {
        "fighter",
        "rogue",
        "mage",
        "cleric"
    }
end

--- Format class info as human-readable string
---@param class_name string Class name
---@return string text Formatted class description
function M.format_class_info(class_name)
    local class_info = M.CLASSES[class_name]
    if not class_info then
        return "Unknown class"
    end

    local text = string.format("%s\n", class_info.name)
    text = text .. string.format("%s\n\n", class_info.description)
    text = text .. string.format("Primary Stat: %s\n", class_info.primary_stat)
    text = text .. string.format("Armor: %s\n", class_info.armor_proficiency)
    text = text .. string.format("Weapons: %s\n", class_info.weapon_proficiency)
    text = text .. string.format("Special: %s", class_info.special_ability)

    return text
end

--- Validate class name
---@param class_name string Class name to validate
---@return boolean valid True if valid class name
function M.is_valid_class(class_name)
    return M.CLASSES[class_name] ~= nil
end

return M
