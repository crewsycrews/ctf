-- m20_dice.lua
-- Microlite20 Dice Rolling Module
-- Implements all dice mechanics for M20 rules
--
-- Usage:
--   local dice = require("main.scripts.modules.m20_dice")
--   local result = dice.roll(20)  -- Roll 1d20
--   local damage = dice.roll(6, 2)  -- Roll 2d6

---@class DiceNotation
---@field dice_count number Number of dice to roll
---@field dice_sides number Number of sides on each die
---@field modifier number Modifier to add/subtract

---@class AttackRollResult
---@field roll number The raw d20 roll (1-20)
---@field total number Roll + attack bonus
---@field hit boolean True if attack hits target AC
---@field is_critical boolean True if natural 20
---@field is_fumble boolean True if natural 1

---@class SkillCheckResult
---@field roll number The raw d20 roll
---@field total number Roll + skill rank + stat bonus
---@field success boolean True if total >= DC

---@class SavingThrowResult
---@field roll number The raw d20 roll
---@field total number Roll + level + stat bonus
---@field success boolean True if total >= DC

local M = {}

-- Random number generator (seeded on module load)
math.randomseed(os.time())

--- Roll a die with specified number of sides
---@param sides number Number of sides on the die (e.g., 6 for d6, 20 for d20)
---@param count? number Number of dice to roll (default: 1)
---@return number total Sum of all dice rolled
function M.roll(sides, count)
    count = count or 1
    assert(sides > 0, "Dice must have at least 1 side")
    assert(count > 0, "Must roll at least 1 die")

    local total = 0
    for i = 1, count do
        total = total + math.random(1, sides)
    end

    return total
end

--- Roll a die and return individual results
---@param sides number Number of sides on the die
---@param count number Number of dice to roll
---@return number[] rolls Array of individual die results
function M.roll_separate(sides, count)
    assert(sides > 0, "Dice must have at least 1 side")
    assert(count > 0, "Must roll at least 1 die")

    local results = {}
    for i = 1, count do
        table.insert(results, math.random(1, sides))
    end

    return results
end

--- Calculate stat bonus from stat value (M20 rule: (stat - 10) / 2, rounded down)
---@param stat_value number The stat value (e.g., STR = 16)
---@return number bonus The stat bonus (e.g., +3 for STR 16)
function M.stat_bonus(stat_value)
    return math.floor((stat_value - 10) / 2)
end

--- Roll 4d6, drop lowest die (for character stat generation)
---@return number total Sum of highest 3 dice
function M.roll_4d6_drop_lowest()
    local rolls = M.roll_separate(6, 4)

    -- Sort to find lowest
    table.sort(rolls)

    -- Sum the highest 3 (drop index 1, which is lowest)
    local total = 0
    for i = 2, 4 do
        total = total + rolls[i]
    end

    return total
end

--- Parse dice notation string (e.g., "1d8+3", "2d6", "1d4-1")
---@param notation string Dice notation (e.g., "2d6+4")
---@return DiceNotation|nil parsed Parsed dice data or nil if invalid
function M.parse_notation(notation)
    -- Pattern: XdY+Z or XdY-Z or XdY
    local count, sides, modifier = notation:match("(%d+)d(%d+)([%+%-]?%d*)")

    if not count or not sides then
        return nil
    end

    count = tonumber(count)
    sides = tonumber(sides)

    -- Parse modifier (default to 0)
    if modifier == "" then
        modifier = 0
    else
        modifier = tonumber(modifier)
    end

    return {
        dice_count = count,
        dice_sides = sides,
        modifier = modifier
    }
end

--- Roll dice from notation string (e.g., "1d8+3" returns total with modifier)
---@param notation string Dice notation (e.g., "2d6+4")
---@return number|nil total Total result with modifier, or nil if invalid notation
function M.roll_notation(notation)
    local parsed = M.parse_notation(notation)

    if not parsed then
        print("Invalid dice notation: " .. notation)
        return nil
    end

    local roll_total = M.roll(parsed.dice_sides, parsed.dice_count)
    return roll_total + parsed.modifier
end

--- Make an attack roll (d20 + attack bonus vs target AC)
---@param attacker table Entity with m20_stats (must have attack_bonus)
---@param target table Entity with m20_stats (must have ac)
---@return AttackRollResult result Attack roll result
function M.attack_roll(attacker, target)
    assert(attacker and attacker.m20_stats, "Attacker must have m20_stats")
    assert(target and target.m20_stats, "Target must have m20_stats")

    local roll = M.roll(20)
    local attack_bonus = attacker.m20_stats.attack_bonus or 0
    local total = roll + attack_bonus
    local target_ac = target.m20_stats.ac or 10

    local result = {
        roll = roll,
        total = total,
        hit = total >= target_ac,
        is_critical = (roll == 20),  -- Natural 20 is always a crit
        is_fumble = (roll == 1)      -- Natural 1 is always a miss
    }

    -- Natural 1 always misses, natural 20 always hits
    if roll == 1 then
        result.hit = false
    elseif roll == 20 then
        result.hit = true
    end

    return result
end

--- Roll damage from dice notation with stat bonus
---@param damage_dice string Dice notation (e.g., "1d8")
---@param stat_bonus? number Additional bonus from stats
---@param is_critical? boolean If true, double the dice (not the bonus)
---@return number damage Total damage
function M.damage_roll(damage_dice, stat_bonus, is_critical)
    stat_bonus = stat_bonus or 0
    is_critical = is_critical or false

    local damage = M.roll_notation(damage_dice) or 0

    -- Critical hits double the dice damage (not the bonus)
    if is_critical then
        damage = damage * 2
    end

    return damage + stat_bonus
end

--- Make a skill check (d20 + skill rank + stat bonus vs DC)
---@param entity table Entity with m20_stats and m20_skills
---@param skill_name string One of: "physical", "subterfuge", "knowledge", "communication"
---@param stat_bonus number Relevant stat bonus for this check
---@param dc number Difficulty Class to beat
---@return SkillCheckResult result Skill check result
function M.skill_check(entity, skill_name, stat_bonus, dc)
    assert(entity and entity.m20_skills, "Entity must have m20_skills")

    local skill_rank = entity.m20_skills[skill_name] or 0
    local roll = M.roll(20)
    local total = roll + skill_rank + stat_bonus

    return {
        roll = roll,
        total = total,
        success = total >= dc
    }
end

--- Make a saving throw (d20 + level + stat bonus vs DC)
---@param entity table Entity with m20_stats
---@param save_type string "fortitude" (STR), "reflex" (DEX), or "will" (MIND)
---@param dc number Difficulty Class to beat
---@return SavingThrowResult result Saving throw result
function M.saving_throw(entity, save_type, dc)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local stats = entity.m20_stats
    local level = stats.level or 1
    local roll = M.roll(20)

    -- Determine stat bonus based on save type
    local stat_bonus = 0
    if save_type == "fortitude" then
        stat_bonus = M.stat_bonus(stats.STR)
    elseif save_type == "reflex" then
        stat_bonus = M.stat_bonus(stats.DEX)
    elseif save_type == "will" then
        stat_bonus = M.stat_bonus(stats.MIND)
    else
        print("Unknown save type: " .. save_type)
    end

    local total = roll + level + stat_bonus

    return {
        roll = roll,
        total = total,
        success = total >= dc
    }
end

--- Calculate spell DC (10 + caster level + MIND bonus)
---@param caster table Entity with m20_stats
---@return number dc Spell DC
function M.spell_dc(caster)
    assert(caster and caster.m20_stats, "Caster must have m20_stats")

    local stats = caster.m20_stats
    local level = stats.level or 1
    local mind_bonus = M.stat_bonus(stats.MIND)

    return 10 + level + mind_bonus
end

return M
