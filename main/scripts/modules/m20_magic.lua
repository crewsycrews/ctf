-- m20_magic.lua
-- Microlite20 Magic System Module
-- Handles spell casting with HP costs, spell DCs, and signature spells
--
-- Usage:
--   local magic = require("main.scripts.modules.m20_magic")
--   if magic.can_cast_spell(entity, 1) then
--       magic.cast_spell(entity, 1, false)
--   end

---@class SpellCastResult
---@field success boolean True if spell was successfully cast
---@field hp_cost number HP cost paid for the spell
---@field spell_level number Level of the spell cast
---@field caster_hp_remaining number Caster's HP after paying cost
---@field spell_dc number Difficulty Class for spell saves
---@field is_signature boolean True if this was a signature spell

---@class SignatureSpells
---@field level_0? string Signature cantrip name
---@field level_1? string Signature 1st level spell
---@field level_2? string Signature 2nd level spell
---@field level_3? string Signature 3rd level spell
---@field level_4? string Signature 4th level spell
---@field level_5? string Signature 5th level spell

local dice = require("main.scripts.modules.m20_dice")
local attrs = require("main.scripts.modules.m20_attributes")

local M = {}

-- M20 Spell Casting Rules:
-- - HP cost = 1 + (2 × spell level)
-- - Signature spells cost -1 HP (minimum 0)
-- - Maximum spell level = character level / 2 (rounded up)
-- - Spell DC = 10 + caster level + MIND bonus

--- Calculate HP cost for casting a spell
---@param spell_level number Spell level (0-9)
---@param is_signature? boolean If true, reduces cost by 1
---@return number cost HP cost for casting the spell
function M.calculate_spell_cost(spell_level, is_signature)
    is_signature = is_signature or false

    -- Base cost: 1 + (2 × spell level)
    local cost = 1 + (spell_level * 2)

    -- Signature spells cost -1 HP
    if is_signature then
        cost = math.max(0, cost - 1)
    end

    return cost
end

--- Check if entity can cast a spell (has enough HP and meets level requirement)
---@param entity table Entity with m20_stats
---@param spell_level number Spell level (0-9)
---@param is_signature? boolean If true, reduces cost by 1
---@return boolean can_cast True if entity can cast this spell
---@return string? reason Reason why casting failed (if can_cast is false)
function M.can_cast_spell(entity, spell_level, is_signature)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local stats = entity.m20_stats
    is_signature = is_signature or false

    -- Check if character level allows this spell level
    local max_spell_level = math.ceil(stats.level / 2)
    if spell_level > max_spell_level then
        return false, string.format("Requires level %d to cast level %d spells", spell_level * 2, spell_level)
    end

    -- Check if entity has enough HP to pay the cost
    local cost = M.calculate_spell_cost(spell_level, is_signature)
    if stats.hp_current < cost then
        return false, string.format("Not enough HP (need %d, have %d)", cost, stats.hp_current)
    end

    return true, nil
end

--- Cast a spell (deduct HP cost)
---@param entity table Entity with m20_stats
---@param spell_level number Spell level (0-9)
---@param is_signature? boolean If true, reduces cost by 1
---@return SpellCastResult result Spell cast result
function M.cast_spell(entity, spell_level, is_signature)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    is_signature = is_signature or false

    -- Check if spell can be cast
    local can_cast, reason = M.can_cast_spell(entity, spell_level, is_signature)
    if not can_cast then
        return {
            success = false,
            hp_cost = 0,
            spell_level = spell_level,
            caster_hp_remaining = entity.m20_stats.hp_current,
            spell_dc = 0,
            is_signature = is_signature,
            failure_reason = reason
        }
    end

    -- Deduct HP cost
    local cost = M.calculate_spell_cost(spell_level, is_signature)
    entity.m20_stats.hp_current = entity.m20_stats.hp_current - cost

    -- Calculate spell DC for saving throws
    local spell_dc = dice.spell_dc(entity)

    return {
        success = true,
        hp_cost = cost,
        spell_level = spell_level,
        caster_hp_remaining = entity.m20_stats.hp_current,
        spell_dc = spell_dc,
        is_signature = is_signature
    }
end

--- Initialize signature spells for an entity
---@param entity table Entity with m20_stats
function M.initialize_signature_spells(entity)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    entity.signature_spells = {}
end

--- Set a signature spell for a specific spell level
---@param entity table Entity with m20_stats and signature_spells
---@param spell_level number Spell level (0-9)
---@param spell_name string Name of the signature spell
function M.set_signature_spell(entity, spell_level, spell_name)
    assert(entity, "Entity must exist")

    if not entity.signature_spells then
        M.initialize_signature_spells(entity)
    end

    entity.signature_spells["level_" .. spell_level] = spell_name
end

--- Check if a spell is a signature spell for this entity
---@param entity table Entity with signature_spells
---@param spell_level number Spell level (0-9)
---@param spell_name string Name of the spell to check
---@return boolean is_signature True if this spell is the signature for this level
function M.is_signature_spell(entity, spell_level, spell_name)
    if not entity or not entity.signature_spells then
        return false
    end

    local signature_name = entity.signature_spells["level_" .. spell_level]
    return signature_name == spell_name
end

--- Get signature spell for a specific level
---@param entity table Entity with signature_spells
---@param spell_level number Spell level (0-9)
---@return string|nil spell_name Name of signature spell, or nil if none set
function M.get_signature_spell(entity, spell_level)
    if not entity or not entity.signature_spells then
        return nil
    end

    return entity.signature_spells["level_" .. spell_level]
end

--- Get maximum spell level entity can cast
---@param entity table Entity with m20_stats
---@return number max_level Maximum spell level (0-9)
function M.get_max_spell_level(entity)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local level = entity.m20_stats.level or 1
    return math.ceil(level / 2)
end

--- Restore HP after rest (8 hours)
--- M20 rule: Spell HP costs are recovered after 8 hours of rest
---@param entity table Entity with m20_stats
---@return number restored Amount of HP restored
function M.rest(entity)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    return attrs.heal(entity, entity.m20_stats.hp_max)
end

--- Format spell cost as human-readable string
---@param spell_level number Spell level (0-9)
---@param is_signature? boolean If true, shows reduced cost
---@return string text Formatted spell cost text
function M.format_spell_cost(spell_level, is_signature)
    is_signature = is_signature or false

    local cost = M.calculate_spell_cost(spell_level, is_signature)
    local text = string.format("%d HP", cost)

    if is_signature then
        local normal_cost = M.calculate_spell_cost(spell_level, false)
        text = text .. string.format(" (Signature: %d → %d)", normal_cost, cost)
    end

    return text
end

--- Format spell cast result as human-readable string
---@param result SpellCastResult Spell cast result
---@return string text Formatted result text
function M.format_cast_result(result)
    if not result.success then
        return string.format("Cast failed: %s", result.failure_reason or "Unknown reason")
    end

    local signature_text = result.is_signature and " (Signature)" or ""
    return string.format("Cast level %d spell%s for %d HP (DC %d). HP: %d remaining",
        result.spell_level,
        signature_text,
        result.hp_cost,
        result.spell_dc,
        result.caster_hp_remaining
    )
end

--- Get spell level unlocked at character level
--- M20 progression: Level 1-2 = 0th, 3-4 = 1st, 5-6 = 2nd, etc.
---@param character_level number Character level (1-20)
---@return number spell_level Highest spell level available
function M.spell_level_at_character_level(character_level)
    return math.ceil(character_level / 2)
end

--- Calculate how many spells of each level can be cast with current HP
---@param entity table Entity with m20_stats
---@return table spell_counts Table of {spell_level = count}
function M.calculate_remaining_spell_slots(entity)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local hp = entity.m20_stats.hp_current
    local max_spell_level = M.get_max_spell_level(entity)
    local spell_counts = {}

    -- Calculate how many of each spell level can be cast
    for spell_level = 0, max_spell_level do
        local cost = M.calculate_spell_cost(spell_level, false)
        local count = math.floor(hp / cost)
        spell_counts[spell_level] = count
    end

    return spell_counts
end

--- Get all signature spells as a table for UI display
---@param entity table Entity with signature_spells
---@return table signatures Table of {spell_level = spell_name}
function M.get_all_signature_spells(entity)
    if not entity or not entity.signature_spells then
        return {}
    end

    local signatures = {}
    for key, spell_name in pairs(entity.signature_spells) do
        local spell_level = tonumber(key:match("level_(%d+)"))
        if spell_level then
            signatures[spell_level] = spell_name
        end
    end

    return signatures
end

-- ============================================================================
-- SPELLBOOK SYSTEM (for purchasable spells)
-- ============================================================================

--- Initialize spellbook for an entity
--- Players start with NO spells learned - must purchase them
---@param entity table Entity with m20_stats
function M.initialize_spellbook(entity)
    assert(entity, "Entity must exist")

    -- Spellbook is a set of spell IDs (from m20_spells.lua)
    -- e.g., { fireball = true, ice_barrage = true }
    entity.spellbook = {}
end

--- Learn a new spell (add to spellbook)
---@param entity table Entity with spellbook
---@param spell_id string Spell identifier (e.g., "fireball", "ice_barrage")
---@return boolean success True if spell was learned
---@return string? message Error message if failed
function M.learn_spell(entity, spell_id)
    assert(entity, "Entity must exist")

    if not entity.spellbook then
        M.initialize_spellbook(entity)
    end

    -- Check if spell is already learned
    if entity.spellbook[spell_id] then
        return false, "Spell already learned"
    end

    -- Add spell to spellbook
    entity.spellbook[spell_id] = true

    return true, "Learned " .. spell_id
end

--- Forget a spell (remove from spellbook)
---@param entity table Entity with spellbook
---@param spell_id string Spell identifier
---@return boolean success True if spell was forgotten
---@return string? message Error message if failed
function M.forget_spell(entity, spell_id)
    assert(entity, "Entity must exist")

    if not entity.spellbook or not entity.spellbook[spell_id] then
        return false, "Spell not in spellbook"
    end

    entity.spellbook[spell_id] = nil

    return true, "Forgot " .. spell_id
end

--- Check if entity knows a spell
---@param entity table Entity with spellbook
---@param spell_id string Spell identifier
---@return boolean knows True if spell is in spellbook
function M.knows_spell(entity, spell_id)
    if not entity or not entity.spellbook then
        return false
    end

    return entity.spellbook[spell_id] == true
end

--- Get all learned spells
---@param entity table Entity with spellbook
---@return string[] spell_ids Array of learned spell IDs
function M.get_learned_spells(entity)
    if not entity or not entity.spellbook then
        return {}
    end

    local spells = {}
    for spell_id, _ in pairs(entity.spellbook) do
        table.insert(spells, spell_id)
    end

    -- Sort alphabetically for consistent ordering
    table.sort(spells)

    return spells
end

--- Get count of learned spells
---@param entity table Entity with spellbook
---@return number count Number of spells in spellbook
function M.get_spell_count(entity)
    if not entity or not entity.spellbook then
        return 0
    end

    local count = 0
    for _, _ in pairs(entity.spellbook) do
        count = count + 1
    end

    return count
end

return M
