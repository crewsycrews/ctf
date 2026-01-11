-- m20_spells.lua
-- Microlite20 Spell Definitions
-- Comprehensive spell database from M20 rules
--
-- Usage:
--   local spells = require("main.scripts.modules.m20_spells")
--   local spell = spells.get_spell("magic_missile")
--   local mage_spells = spells.get_spells_for_class("mage", 3)

---@class SpellDefinition
---@field id string Unique spell identifier (snake_case)
---@field name string Display name
---@field level number Spell level (0-9)
---@field school string Magic school ("arcane" or "divine")
---@field range string Range description ("touch", "30 ft", "60 ft", etc.)
---@field duration string Duration ("instant", "1 round", "concentration", etc.)
---@field save_type? string Save type if applicable ("fortitude", "reflex", "will")
---@field damage_dice? string Damage dice notation (e.g., "1d4+1", "3d6")
---@field description string Full spell description
---@field effect string Mechanical effect summary
---@field ctf_spell? string Mapped to existing CTF spell name

local M = {}

-- Spell database organized by level
-- Based on Microlite20 core spell list
M.SPELLS = {
    -- LEVEL 0 (Cantrips)
    {
        id = "detect_magic",
        name = "Detect Magic",
        level = 0,
        school = "arcane",
        range = "60 ft",
        duration = "concentration",
        description = "Detect magical auras within range",
        effect = "Reveals magical items, spells, and enchantments"
    },
    {
        id = "light",
        name = "Light",
        level = 0,
        school = "arcane",
        range = "touch",
        duration = "1 hour",
        description = "Object sheds light as a torch",
        effect = "Illuminates 20 ft radius"
    },
    {
        id = "mage_hand",
        name = "Mage Hand",
        level = 0,
        school = "arcane",
        range = "30 ft",
        duration = "concentration",
        description = "Telekinetically manipulate a small object",
        effect = "Move 5 lb object at range"
    },
    {
        id = "cure_minor_wounds",
        name = "Cure Minor Wounds",
        level = 0,
        school = "divine",
        range = "touch",
        duration = "instant",
        description = "Heal minor injuries",
        effect = "Heal 1 HP",
        damage_dice = "1"
    },

    -- LEVEL 1 SPELLS
    {
        id = "magic_missile",
        name = "Magic Missile",
        level = 1,
        school = "arcane",
        range = "100 ft",
        duration = "instant",
        description = "Unerring missile of magical force",
        effect = "Auto-hit for 1d4+1 force damage per missile",
        damage_dice = "1d4+1",
        ctf_spell = "fireball" -- Maps to CTF fireball
    },
    {
        id = "shield",
        name = "Shield",
        level = 1,
        school = "arcane",
        range = "self",
        duration = "1 minute",
        description = "Invisible shield blocks attacks",
        effect = "+4 AC bonus"
    },
    {
        id = "sleep",
        name = "Sleep",
        level = 1,
        school = "arcane",
        range = "30 ft",
        duration = "1 minute",
        save_type = "will",
        description = "Put creatures to sleep",
        effect = "Affects 2d4 HD of creatures"
    },
    {
        id = "burning_hands",
        name = "Burning Hands",
        level = 1,
        school = "arcane",
        range = "15 ft cone",
        duration = "instant",
        save_type = "reflex",
        description = "Cone of fire from fingertips",
        effect = "1d4 fire damage per caster level",
        damage_dice = "1d4"
    },
    {
        id = "cure_light_wounds",
        name = "Cure Light Wounds",
        level = 1,
        school = "divine",
        range = "touch",
        duration = "instant",
        description = "Heal injuries with divine power",
        effect = "Heal 1d8+1 HP",
        damage_dice = "1d8+1"
    },
    {
        id = "bless",
        name = "Bless",
        level = 1,
        school = "divine",
        range = "50 ft",
        duration = "1 minute",
        description = "Allies gain +1 to attack rolls",
        effect = "+1 attack bonus to allies"
    },
    {
        id = "invisibility_1",
        name = "Invisibility",
        level = 1,
        school = "arcane",
        range = "touch",
        duration = "1 minute or until attack",
        description = "Subject becomes invisible",
        effect = "Cannot be seen, +20 to Subterfuge checks",
        ctf_spell = "windwalk" -- Maps to CTF windwalk
    },

    -- LEVEL 2 SPELLS
    {
        id = "hold_person",
        name = "Hold Person",
        level = 2,
        school = "arcane",
        range = "50 ft",
        duration = "1 minute",
        save_type = "will",
        description = "Paralyze a humanoid",
        effect = "Target cannot move or act",
        ctf_spell = "ice_barrage" -- Maps to CTF ice barrage (freeze effect)
    },
    {
        id = "web",
        name = "Web",
        level = 2,
        school = "arcane",
        range = "100 ft",
        duration = "10 minutes",
        save_type = "reflex",
        description = "Fill area with sticky webs",
        effect = "Creatures stuck, movement reduced"
    },
    {
        id = "scorching_ray",
        name = "Scorching Ray",
        level = 2,
        school = "arcane",
        range = "30 ft",
        duration = "instant",
        description = "Ray of fire",
        effect = "Ranged attack for 4d6 fire damage",
        damage_dice = "4d6"
    },
    {
        id = "gust_of_wind",
        name = "Gust of Wind",
        level = 2,
        school = "arcane",
        range = "60 ft line",
        duration = "1 round",
        save_type = "fortitude",
        description = "Powerful wind blast",
        effect = "Knockback, extinguish flames",
        ctf_spell = "thunderclap" -- Maps to CTF thunderclap (knockback/slow)
    },
    {
        id = "cure_moderate_wounds",
        name = "Cure Moderate Wounds",
        level = 2,
        school = "divine",
        range = "touch",
        duration = "instant",
        description = "Heal moderate injuries",
        effect = "Heal 2d8+3 HP",
        damage_dice = "2d8+3"
    },
    {
        id = "spiritual_weapon",
        name = "Spiritual Weapon",
        level = 2,
        school = "divine",
        range = "30 ft",
        duration = "1 minute",
        description = "Floating weapon attacks foes",
        effect = "1d8+MIND bonus force damage per round",
        damage_dice = "1d8"
    },

    -- LEVEL 3 SPELLS
    {
        id = "fireball",
        name = "Fireball",
        level = 3,
        school = "arcane",
        range = "100 ft",
        duration = "instant",
        save_type = "reflex",
        description = "Explosive ball of fire",
        effect = "1d6 fire damage per caster level (max 10d6)",
        damage_dice = "1d6"
    },
    {
        id = "lightning_bolt",
        name = "Lightning Bolt",
        level = 3,
        school = "arcane",
        range = "100 ft line",
        duration = "instant",
        save_type = "reflex",
        description = "Stroke of lightning",
        effect = "1d6 electricity damage per caster level (max 10d6)",
        damage_dice = "1d6"
    },
    {
        id = "fly",
        name = "Fly",
        level = 3,
        school = "arcane",
        range = "touch",
        duration = "1 minute per level",
        description = "Subject gains flight",
        effect = "Fly at 60 ft/round"
    },
    {
        id = "dispel_magic",
        name = "Dispel Magic",
        level = 3,
        school = "arcane",
        range = "100 ft",
        duration = "instant",
        description = "Cancel magical effects",
        effect = "Remove spells and enchantments"
    },
    {
        id = "cure_serious_wounds",
        name = "Cure Serious Wounds",
        level = 3,
        school = "divine",
        range = "touch",
        duration = "instant",
        description = "Heal serious injuries",
        effect = "Heal 3d8+5 HP",
        damage_dice = "3d8+5"
    },
    {
        id = "prayer",
        name = "Prayer",
        level = 3,
        school = "divine",
        range = "40 ft",
        duration = "1 round per level",
        description = "Bless allies and curse enemies",
        effect = "Allies +1 to rolls, enemies -1 to rolls"
    },

    -- LEVEL 4 SPELLS
    {
        id = "ice_storm",
        name = "Ice Storm",
        level = 4,
        school = "arcane",
        range = "100 ft",
        duration = "instant",
        save_type = "reflex",
        description = "Hail and ice pelt area",
        effect = "5d6 cold damage",
        damage_dice = "5d6"
    },
    {
        id = "polymorph",
        name = "Polymorph",
        level = 4,
        school = "arcane",
        range = "touch",
        duration = "1 minute per level",
        save_type = "fortitude",
        description = "Transform subject into another form",
        effect = "Change creature's shape"
    },
    {
        id = "dimension_door",
        name = "Dimension Door",
        level = 4,
        school = "arcane",
        range = "400 ft",
        duration = "instant",
        description = "Teleport short distance",
        effect = "Instant teleportation"
    },
    {
        id = "cure_critical_wounds",
        name = "Cure Critical Wounds",
        level = 4,
        school = "divine",
        range = "touch",
        duration = "instant",
        description = "Heal critical injuries",
        effect = "Heal 4d8+7 HP",
        damage_dice = "4d8+7"
    },
    {
        id = "divine_power",
        name = "Divine Power",
        level = 4,
        school = "divine",
        range = "self",
        duration = "1 round per level",
        description = "Gain combat prowess",
        effect = "+3 attack, +3 damage, bonus HP"
    },

    -- LEVEL 5 SPELLS
    {
        id = "cone_of_cold",
        name = "Cone of Cold",
        level = 5,
        school = "arcane",
        range = "60 ft cone",
        duration = "instant",
        save_type = "reflex",
        description = "Freezing cone of ice",
        effect = "1d6 cold damage per caster level (max 15d6)",
        damage_dice = "1d6"
    },
    {
        id = "teleport",
        name = "Teleport",
        level = 5,
        school = "arcane",
        range = "unlimited",
        duration = "instant",
        description = "Teleport to familiar location",
        effect = "Instant long-distance travel"
    },
    {
        id = "wall_of_force",
        name = "Wall of Force",
        level = 5,
        school = "arcane",
        range = "30 ft",
        duration = "1 round per level",
        description = "Invisible wall blocks everything",
        effect = "Impenetrable barrier"
    },
    {
        id = "flame_strike",
        name = "Flame Strike",
        level = 5,
        school = "divine",
        range = "100 ft",
        duration = "instant",
        save_type = "reflex",
        description = "Column of divine fire",
        effect = "1d6 damage per caster level (max 15d6)",
        damage_dice = "1d6"
    },
    {
        id = "raise_dead",
        name = "Raise Dead",
        level = 5,
        school = "divine",
        range = "touch",
        duration = "instant",
        description = "Restore life to the dead",
        effect = "Revive recently deceased creature"
    }
}

-- Build lookup tables for fast access
M.SPELLS_BY_ID = {}
M.SPELLS_BY_LEVEL = {}
M.SPELLS_BY_SCHOOL = { arcane = {}, divine = {} }
M.CTF_SPELL_MAP = {} -- Maps CTF spell names to M20 spells

-- Initialize lookup tables
for _, spell in ipairs(M.SPELLS) do
    -- By ID
    M.SPELLS_BY_ID[spell.id] = spell

    -- By level
    if not M.SPELLS_BY_LEVEL[spell.level] then
        M.SPELLS_BY_LEVEL[spell.level] = {}
    end
    table.insert(M.SPELLS_BY_LEVEL[spell.level], spell)

    -- By school
    table.insert(M.SPELLS_BY_SCHOOL[spell.school], spell)

    -- CTF spell mapping
    if spell.ctf_spell then
        M.CTF_SPELL_MAP[spell.ctf_spell] = spell
    end
end

--- Get spell definition by ID
---@param spell_id string Spell identifier
---@return SpellDefinition|nil spell Spell definition or nil
function M.get_spell(spell_id)
    return M.SPELLS_BY_ID[spell_id]
end

--- Get all spells of a specific level
---@param level number Spell level (0-9)
---@return SpellDefinition[] spells Array of spell definitions
function M.get_spells_by_level(level)
    return M.SPELLS_BY_LEVEL[level] or {}
end

--- Get all spells for a specific school
---@param school string "arcane" or "divine"
---@return SpellDefinition[] spells Array of spell definitions
function M.get_spells_by_school(school)
    return M.SPELLS_BY_SCHOOL[school] or {}
end

--- Get all spells a character can cast based on level and class
---@param class_name string Class name ("mage" or "cleric")
---@param character_level number Character level
---@return SpellDefinition[] spells Array of available spells
function M.get_spells_for_class(class_name, character_level)
    local max_spell_level = math.ceil(character_level / 2)
    local school = (class_name == "mage") and "arcane" or "divine"
    local available_spells = {}

    for level = 0, max_spell_level do
        local level_spells = M.get_spells_by_level(level)
        for _, spell in ipairs(level_spells) do
            if spell.school == school then
                table.insert(available_spells, spell)
            end
        end
    end

    return available_spells
end

--- Get M20 spell mapped to a CTF spell name
---@param ctf_spell_name string CTF spell name (e.g., "fireball", "ice_barrage")
---@return SpellDefinition|nil spell Mapped M20 spell or nil
function M.get_spell_from_ctf(ctf_spell_name)
    return M.CTF_SPELL_MAP[ctf_spell_name]
end

--- Calculate spell damage based on caster level
---@param spell SpellDefinition Spell definition
---@param caster_level number Caster level
---@return string damage_dice Damage dice notation (e.g., "5d6")
function M.calculate_spell_damage_dice(spell, caster_level)
    if not spell.damage_dice then
        return "0"
    end

    -- Spells that scale with level (e.g., "1d6" becomes "5d6" at level 5)
    local base_dice = spell.damage_dice:match("(%d+)d(%d+)")
    if base_dice == "1" and spell.level >= 3 then
        -- Scaling spells (fireball, lightning bolt, etc.)
        local dice_count = math.min(caster_level, 10 + spell.level)
        return dice_count .. spell.damage_dice:match("d(%d+.*)")
    end

    -- Fixed damage spells
    return spell.damage_dice
end

--- Format spell info for UI display
---@param spell SpellDefinition Spell definition
---@param caster_level? number Caster level (for damage calculation)
---@return string text Formatted spell info
function M.format_spell_info(spell, caster_level)
    local magic = require("main.scripts.modules.m20_magic")

    local text = string.format("%s (Level %d %s)\n",
        spell.name,
        spell.level,
        spell.school:sub(1,1):upper() .. spell.school:sub(2)
    )

    -- HP cost
    local cost = magic.calculate_spell_cost(spell.level, false)
    text = text .. string.format("HP Cost: %d\n", cost)

    -- Range and duration
    text = text .. string.format("Range: %s | Duration: %s\n",
        spell.range,
        spell.duration
    )

    -- Damage
    if spell.damage_dice and caster_level then
        local damage_dice = M.calculate_spell_damage_dice(spell, caster_level)
        text = text .. string.format("Damage: %s\n", damage_dice)
    end

    -- Save type
    if spell.save_type then
        text = text .. string.format("Save: %s\n", spell.save_type:sub(1,1):upper() .. spell.save_type:sub(2))
    end

    -- Description
    text = text .. string.format("\n%s", spell.description)

    return text
end

--- Get all spell IDs as array (for iteration)
---@return string[] spell_ids Array of spell IDs
function M.get_all_spell_ids()
    local ids = {}
    for id, _ in pairs(M.SPELLS_BY_ID) do
        table.insert(ids, id)
    end
    table.sort(ids)
    return ids
end

--- Get spell count by level
---@return table counts Table of {level = count}
function M.get_spell_counts_by_level()
    local counts = {}
    for level = 0, 9 do
        counts[level] = #(M.SPELLS_BY_LEVEL[level] or {})
    end
    return counts
end

return M
