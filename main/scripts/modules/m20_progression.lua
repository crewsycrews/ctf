-- m20_progression.lua
-- Microlite20 Experience and Leveling Module
-- Handles XP tracking, level-ups, and stat increases
--
-- Usage:
--   local progression = require("main.scripts.modules.m20_progression")
--   progression.award_xp(entity, 10)
--   if progression.check_level_up(entity) then
--       progression.level_up(entity, stat_choice)
--   end

---@class LevelUpResult
---@field new_level number The new level after leveling up
---@field old_level number The previous level
---@field hp_gained number HP gained from level up
---@field hp_max number New maximum HP
---@field stat_increased? string Which stat was increased ("STR", "DEX", or "MIND")

---@class XPInfo
---@field current_xp number Current XP
---@field xp_needed number XP needed for next level
---@field level number Current level
---@field progress_pct number Progress to next level (0.0 to 1.0)

local dice = require("main.scripts.modules.m20_dice")
local attrs = require("main.scripts.modules.m20_attributes")

local M = {}

-- Calculate XP award for defeating a single enemy
-- For action games: each kill awards XP individually based on HD
--
-- XP Progression Design:
-- - Level 1→2 requires 10 XP (kill ~3-5 enemies of HD 1-2)
-- - Level 2→3 requires 20 XP (kill ~6-10 enemies)
-- - Player should reach level 3-4 in typical game session
--
-- XP Formula: HD² + HD (scales quadratically for tougher enemies)
-- Examples: 1 HD = 2 XP, 2 HD = 6 XP, 3 HD = 12 XP, 4 HD = 20 XP
--
---@param enemy_hd number Enemy Hit Dice (1-10 typical range)
---@return number xp XP awarded for defeating this enemy
function M.calculate_enemy_xp(enemy_hd)
    -- Quadratic scaling rewards fighting tougher enemies
    -- HD² gives exponential risk/reward, +HD provides base minimum
    return (enemy_hd * enemy_hd) + enemy_hd
end

--- Award XP to an entity
---@param entity table Entity with m20_stats
---@param xp_amount number Amount of XP to award
function M.award_xp(entity, xp_amount)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    entity.m20_stats.xp = entity.m20_stats.xp + xp_amount
end

-- Check if entity has enough XP to level up
-- M20 rule: Level up when XP >= (10 × current level)
-- @param entity (table) Entity with m20_stats
-- @return (bool) True if entity can level up
function M.check_level_up(entity)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local stats = entity.m20_stats
    return stats.xp >= stats.xp_to_next_level
end

-- Perform level-up for an entity
-- M20 level-up bonuses:
-- - +1d6 HP
-- - +1 to all attack rolls
-- - +1 to all skills
-- - Every 3 levels: +1 to STR, DEX, or MIND (player choice)
-- - Class-specific bonuses (handled by class module)
--
-- @param entity (table) Entity with m20_stats and m20_skills
-- @param stat_choice (string, optional) "STR", "DEX", or "MIND" (for levels divisible by 3)
-- @return (table) Level-up results { new_level, hp_gained, stat_increased }
function M.level_up(entity, stat_choice)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local stats = entity.m20_stats
    local old_level = stats.level

    -- Reset XP counter (subtract the threshold, keep overflow)
    stats.xp = stats.xp - stats.xp_to_next_level

    -- Increment level
    stats.level = stats.level + 1

    -- Update XP threshold for next level
    stats.xp_to_next_level = 10 * stats.level

    -- Roll +1d6 HP
    local hp_gained = dice.roll(6)
    stats.hp_max = stats.hp_max + hp_gained
    stats.hp_current = stats.hp_current + hp_gained  -- Heal the gained HP

    -- +1 to all attack rolls (recalculate bonuses)
    attrs.recalculate_derived_stats(entity)

    -- +1 to all skills (handled by skills module)
    if entity.m20_skills then
        for skill_name, rank in pairs(entity.m20_skills) do
            entity.m20_skills[skill_name] = rank + 1
        end
    end

    local result = {
        new_level = stats.level,
        old_level = old_level,
        hp_gained = hp_gained,
        hp_max = stats.hp_max,
        stat_increased = nil
    }

    -- Every 3 levels: +1 to STR, DEX, or MIND
    if stats.level % 3 == 0 then
        if stat_choice == "STR" then
            stats.STR = stats.STR + 1
            result.stat_increased = "STR"
        elseif stat_choice == "DEX" then
            stats.DEX = stats.DEX + 1
            result.stat_increased = "DEX"
        elseif stat_choice == "MIND" then
            stats.MIND = stats.MIND + 1
            result.stat_increased = "MIND"
        else
            -- Default to primary stat if no choice provided
            -- (This should prompt player in UI, but we need a fallback)
            if stats.class == "fighter" then
                stats.STR = stats.STR + 1
                result.stat_increased = "STR"
            elseif stats.class == "rogue" then
                stats.DEX = stats.DEX + 1
                result.stat_increased = "DEX"
            elseif stats.class == "mage" or stats.class == "cleric" then
                stats.MIND = stats.MIND + 1
                result.stat_increased = "MIND"
            end
        end

        -- Recalculate derived stats after stat increase
        attrs.recalculate_derived_stats(entity)
    end

    return result
end

-- Apply class-specific level-up bonuses
-- Fighter: +1 attack/damage at levels 5, 10, 15, etc.
-- Mage/Cleric: Access to new spell levels at 3, 5, 7, 9, etc.
--
-- @param entity (table) Entity with m20_stats
function M.apply_class_bonuses(entity)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local stats = entity.m20_stats
    local class = stats.class
    local level = stats.level

    if class == "fighter" then
        -- Fighter gains +1 attack and damage at 5/10/15/20
        if level % 5 == 0 then
            stats.fighter_attack_bonus = (stats.fighter_attack_bonus or 0) + 1
            -- This bonus is added to attack rolls in combat module
        end
    elseif class == "mage" or class == "cleric" then
        -- Spellcasters gain access to new spell levels
        -- Spell level = Level / 2 (rounded up)
        stats.max_spell_level = math.ceil(level / 2)

        -- Spell levels unlock at: 1(0th), 3(1st), 5(2nd), 7(3rd), etc.
    end
end

-- Get maximum spell level a caster can use
-- M20 rule: Can cast spells with level ≤ (character level / 2, rounded up)
-- @param entity (table) Entity with m20_stats
-- @return (number) Maximum spell level (0-9)
function M.get_max_spell_level(entity)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local level = entity.m20_stats.level
    return math.ceil(level / 2)
end

-- Check if caster can cast a given spell level
-- @param entity (table) Entity with m20_stats
-- @param spell_level (number) Spell level to check (0-9)
-- @return (bool) True if caster can cast this level
function M.can_cast_spell_level(entity, spell_level)
    local max_level = M.get_max_spell_level(entity)
    return spell_level <= max_level
end

-- Format level-up message for display
-- @param result (table) Level-up result from level_up()
-- @return (string) Formatted message
function M.format_level_up_message(result)
    local msg = string.format("LEVEL UP! Now level %d", result.new_level)
    msg = msg .. string.format("\n+%d HP (max: %d)", result.hp_gained, result.hp_max)

    if result.stat_increased then
        msg = msg .. string.format("\n%s +1!", result.stat_increased)
    end

    return msg
end

-- Calculate total XP needed to reach a target level
-- @param target_level (number) Level to calculate for
-- @return (number) Total XP needed
function M.xp_for_level(target_level)
    -- Sum of XP thresholds: 10*1 + 10*2 + 10*3 + ... + 10*(n-1)
    -- = 10 * (1 + 2 + 3 + ... + (n-1))
    -- = 10 * ((n-1) * n / 2)
    return 10 * ((target_level - 1) * target_level / 2)
end

-- Get XP progress percentage toward next level
-- @param entity (table) Entity with m20_stats
-- @return (number) Percentage (0.0 to 1.0)
function M.xp_progress(entity)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local stats = entity.m20_stats
    return stats.xp / stats.xp_to_next_level
end

-- Get detailed XP info for UI display
-- @param entity (table) Entity with m20_stats
-- @return (table) { current_xp, xp_needed, level, progress_pct }
function M.get_xp_info(entity)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local stats = entity.m20_stats
    return {
        current_xp = stats.xp,
        xp_needed = stats.xp_to_next_level,
        level = stats.level,
        progress_pct = M.xp_progress(entity)
    }
end

return M
