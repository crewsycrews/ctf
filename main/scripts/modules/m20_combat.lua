-- m20_combat.lua
-- Microlite20 Combat Resolution Module
-- Handles attack rolls, damage calculation, and combat resolution
--
-- Usage:
--   local combat = require("main.scripts.modules.m20_combat")
--   local result = combat.resolve_attack(attacker, target, "1d8+3", "melee")

---@class CombatResult
---@field attack_roll number The raw d20 roll
---@field attack_total number Roll + attack bonus
---@field hit boolean True if attack hits
---@field is_critical boolean True if natural 20
---@field is_fumble boolean True if natural 1
---@field damage_roll number Damage dice roll (before modifiers)
---@field damage_total number Total damage dealt
---@field target_alive boolean True if target survives
---@field attacker_name string Attacker class/name
---@field target_name string Target class/name
---@field target_ac number Target's AC
---@field target_hp_remaining? number Remaining HP after damage

---@class SpellSaveResult
---@field save_roll number The raw d20 roll
---@field save_total number Roll + modifiers
---@field save_success boolean True if save succeeded
---@field spell_dc number The DC for the save
---@field caster_name string Caster class/name
---@field target_name string Target class/name
---@field save_type string "fortitude", "reflex", or "will"
---@field effect_applied boolean True if effect was applied

local dice = require("main.scripts.modules.m20_dice")
local attrs = require("main.scripts.modules.m20_attributes")

local M = {}

--- Resolve a complete attack (roll to hit, then roll damage if hit)
---@param attacker table Attacking entity with m20_stats
---@param target table Target entity with m20_stats
---@param damage_dice string Damage dice notation (e.g., "1d8", "2d6+2")
---@param attack_type? string "melee", "ranged", or "magic" (default: "melee")
---@return CombatResult result Combat result with hit/miss, damage dealt, etc.
function M.resolve_attack(attacker, target, damage_dice, attack_type)
    attack_type = attack_type or "melee"

    assert(attacker and attacker.m20_stats, "Attacker must have m20_stats")
    assert(target and target.m20_stats, "Target must have m20_stats")

    -- Step 1: Roll to hit
    local attack_result = dice.attack_roll(attacker, target)

    local combat_result = {
        -- Attack roll info
        attack_roll = attack_result.roll,
        attack_total = attack_result.total,
        hit = attack_result.hit,
        is_critical = attack_result.is_critical,
        is_fumble = attack_result.is_fumble,

        -- Damage info (calculated if hit)
        damage_roll = 0,
        damage_total = 0,
        target_alive = true,

        -- Context
        attacker_name = attacker.m20_stats.class or "unknown",
        target_name = target.m20_stats.class or "unknown",
        target_ac = target.m20_stats.ac
    }

    -- Step 2: Roll damage if hit
    if attack_result.hit then
        -- Get stat bonus for damage based on attack type
        local stat_bonus = 0
        if attack_type == "melee" then
            stat_bonus = dice.stat_bonus(attacker.m20_stats.STR)
        elseif attack_type == "ranged" then
            -- Ranged weapons typically don't add STR (unless composite bow, etc.)
            stat_bonus = 0
        elseif attack_type == "magic" then
            -- Magic attacks may or may not add MIND bonus (spell-specific)
            stat_bonus = 0
        end

        -- Roll damage
        local damage = dice.damage_roll(damage_dice, stat_bonus, attack_result.is_critical)

        combat_result.damage_total = damage

        -- Apply damage to target
        combat_result.target_alive = attrs.take_damage(target, damage)
        combat_result.target_hp_remaining = target.m20_stats.hp_current
    end

    return combat_result
end

-- Resolve a melee attack with weapon
-- @param attacker (table) Attacking entity
-- @param target (table) Target entity
-- @param weapon_damage (string, optional) Weapon damage dice (default: "1d3" for unarmed)
-- @return (table) Combat result
function M.melee_attack(attacker, target, weapon_damage)
    weapon_damage = weapon_damage or "1d3"  -- Unarmed strike
    return M.resolve_attack(attacker, target, weapon_damage, "melee")
end

-- Resolve a ranged attack
-- @param attacker (table) Attacking entity
-- @param target (table) Target entity
-- @param weapon_damage (string) Weapon damage dice (e.g., "1d6" for shortbow)
-- @return (table) Combat result
function M.ranged_attack(attacker, target, weapon_damage)
    return M.resolve_attack(attacker, target, weapon_damage, "ranged")
end

-- Resolve a magic attack (spell that requires attack roll)
-- @param caster (table) Casting entity
-- @param target (table) Target entity
-- @param spell_damage (string) Spell damage dice (e.g., "1d4+1" for Magic Missile)
-- @return (table) Combat result
function M.magic_attack(caster, target, spell_damage)
    return M.resolve_attack(caster, target, spell_damage, "magic")
end

-- Resolve a spell with saving throw (no attack roll)
-- @param caster (table) Casting entity with m20_stats
-- @param target (table) Target entity with m20_stats
-- @param save_type (string) "fortitude", "reflex", or "will"
-- @param effect_fn (function) Function to call if save fails: effect_fn(target)
-- @return (table) Save result with success/failure
function M.spell_with_save(caster, target, save_type, effect_fn)
    assert(caster and caster.m20_stats, "Caster must have m20_stats")
    assert(target and target.m20_stats, "Target must have m20_stats")

    -- Calculate spell DC
    local dc = dice.spell_dc(caster)

    -- Target makes saving throw
    local save_result = dice.saving_throw(target, save_type, dc)

    local result = {
        -- Save roll info
        save_roll = save_result.roll,
        save_total = save_result.total,
        save_success = save_result.success,
        spell_dc = dc,

        -- Context
        caster_name = caster.m20_stats.class or "unknown",
        target_name = target.m20_stats.class or "unknown",
        save_type = save_type
    }

    -- Apply effect if save failed
    if not save_result.success and effect_fn then
        effect_fn(target)
        result.effect_applied = true
    else
        result.effect_applied = false
    end

    return result
end

-- Resolve area-of-effect spell (multiple targets)
-- @param caster (table) Casting entity
-- @param targets (table) Array of target entities
-- @param save_type (string) "fortitude", "reflex", or "will"
-- @param effect_fn (function) Function to call on each target that fails save
-- @return (table) Array of save results, one per target
function M.aoe_spell(caster, targets, save_type, effect_fn)
    local results = {}

    for i, target in ipairs(targets) do
        local result = M.spell_with_save(caster, target, save_type, effect_fn)
        result.target_index = i
        table.insert(results, result)
    end

    return results
end

-- Apply damage over time (DoT) effect
-- @param entity (table) Entity with m20_stats
-- @param damage_per_round (number) Damage to apply each round
-- @param duration_rounds (number) Number of rounds the DoT lasts
-- @return (table) DoT effect data (to be stored on entity)
function M.apply_dot(entity, damage_per_round, duration_rounds)
    return {
        damage = damage_per_round,
        rounds_remaining = duration_rounds,
        entity = entity
    }
end

-- Tick a DoT effect (call each round)
-- @param dot_effect (table) DoT effect data from apply_dot()
-- @return (bool) True if DoT is still active, false if expired
function M.tick_dot(dot_effect)
    if dot_effect.rounds_remaining <= 0 then
        return false
    end

    -- Apply damage
    attrs.take_damage(dot_effect.entity, dot_effect.damage)

    -- Decrement rounds
    dot_effect.rounds_remaining = dot_effect.rounds_remaining - 1

    return dot_effect.rounds_remaining > 0
end

-- Format combat result as human-readable string (for floating text)
-- @param result (table) Combat result from resolve_attack()
-- @return (string) Formatted combat text
function M.format_combat_text(result)
    if not result.hit then
        if result.is_fumble then
            return "FUMBLE! (1)"
        else
            return string.format("Miss (%d vs AC %d)", result.attack_total, result.target_ac)
        end
    end

    if result.is_critical then
        return string.format("CRITICAL! %d damage", result.damage_total)
    end

    return string.format("Hit! %d damage", result.damage_total)
end

-- Format saving throw result as human-readable string
-- @param result (table) Save result from spell_with_save()
-- @return (string) Formatted save text
function M.format_save_text(result)
    if result.save_success then
        return string.format("Resisted! (%d vs DC %d)", result.save_total, result.spell_dc)
    else
        return string.format("Failed save! (%d vs DC %d)", result.save_total, result.spell_dc)
    end
end

-- Calculate Two-Weapon Fighting penalty (M20 rules)
-- Fighters and Rogues can wield 2 light weapons with -2 penalty to all attacks
-- @param attacker (table) Entity with m20_stats
-- @return (number) Attack penalty (0 or -2)
function M.two_weapon_penalty(attacker)
    assert(attacker and attacker.m20_stats, "Attacker must have m20_stats")

    local class = attacker.m20_stats.class
    if class == "fighter" or class == "rogue" then
        return -2  -- Can dual-wield with -2 penalty
    end

    return -10  -- Other classes can't effectively dual-wield
end

-- Check if attack hits touch AC (for spells)
-- Touch AC = 10 + DEX bonus (ignores armor)
-- @param attacker (table) Attacking entity
-- @param target (table) Target entity
-- @return (bool) True if attack hits touch AC
function M.touch_attack(attacker, target)
    assert(attacker and attacker.m20_stats, "Attacker must have m20_stats")
    assert(target and target.m20_stats, "Target must have m20_stats")

    local roll = dice.roll(20)
    local attack_bonus = attacker.m20_stats.attack_bonus_magic or 0
    local total = roll + attack_bonus

    local touch_ac = 10 + dice.stat_bonus(target.m20_stats.DEX)

    return total >= touch_ac or roll == 20  -- Natural 20 always hits
end

return M
