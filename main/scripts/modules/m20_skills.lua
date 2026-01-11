-- m20_skills.lua
-- Microlite20 Skills Module
-- Manages the 4-skill system: Physical, Subterfuge, Knowledge, Communication
--
-- Usage:
--   local skills = require("main.scripts.modules.m20_skills")
--   skills.initialize_skills(entity, "fighter")
--   local result = skills.make_check(entity, "physical", 15)

---@class M20Skills
---@field physical number Physical skill rank (STR/DEX based)
---@field subterfuge number Subterfuge skill rank (DEX/MIND based)
---@field knowledge number Knowledge skill rank (MIND based)
---@field communication number Communication skill rank (MIND based)

---@class SkillCheckDetailedResult
---@field roll number The raw d20 roll
---@field skill_rank number The skill rank bonus
---@field stat_bonus number The relevant stat bonus
---@field total number Total: roll + skill_rank + stat_bonus
---@field success boolean True if total >= DC
---@field skill_name string Name of skill checked

local dice = require("main.scripts.modules.m20_dice")

local M = {}

-- M20 Skill Definitions
-- Each class gets +3 to one skill at level 1
M.SKILL_NAMES = {
    "physical",      -- Athletics, climbing, jumping, swimming (STR/DEX)
    "subterfuge",    -- Stealth, traps, pickpocketing (DEX/MIND)
    "knowledge",     -- Lore, magic, history, nature (MIND)
    "communication"  -- Persuasion, intimidation, performance (MIND)
}

-- Class skill bonuses (M20 rules)
M.CLASS_SKILL_BONUSES = {
    fighter = {
        physical = 3,
        subterfuge = 0,
        knowledge = 0,
        communication = 0
    },
    rogue = {
        physical = 0,
        subterfuge = 3,
        knowledge = 0,
        communication = 0
    },
    mage = {
        physical = 0,
        subterfuge = 0,
        knowledge = 3,
        communication = 0
    },
    cleric = {
        physical = 0,
        subterfuge = 0,
        knowledge = 0,
        communication = 3
    }
}

-- Race skill bonuses (M20 rules: humans get +1 to all skills)
M.RACE_SKILL_BONUSES = {
    human = 1,
    elf = 0,
    dwarf = 0,
    halfling = 0
}

--- Initialize skills for an entity based on class and race
---@param entity table Entity with m20_stats
---@param class_name? string Class name ("fighter", "rogue", "mage", "cleric")
---@param race? string Race name (default: "human")
---@return table entity Entity with m20_skills initialized
function M.initialize_skills(entity, class_name, race)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    class_name = class_name or "fighter"
    race = race or "human"

    local level = entity.m20_stats.level or 1
    local class_bonuses = M.CLASS_SKILL_BONUSES[class_name] or M.CLASS_SKILL_BONUSES.fighter
    local race_bonus = M.RACE_SKILL_BONUSES[race] or 0

    -- M20 rule: Skill rank = level + class bonus + race bonus
    entity.m20_skills = {
        physical = level + class_bonuses.physical + race_bonus,
        subterfuge = level + class_bonuses.subterfuge + race_bonus,
        knowledge = level + class_bonuses.knowledge + race_bonus,
        communication = level + class_bonuses.communication + race_bonus
    }

    return entity
end

--- Initialize monster skills based on Hit Dice
---@param entity table Monster entity with m20_stats
---@param hd number Hit Dice
---@param intelligent? boolean If true, gets +3 to one skill
---@return table entity Entity with m20_skills initialized
function M.initialize_monster_skills(entity, hd, intelligent)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    intelligent = intelligent or false

    -- M20 rule: Monster skill rank = HD
    entity.m20_skills = {
        physical = hd,
        subterfuge = hd,
        knowledge = hd,
        communication = hd
    }

    -- Intelligent monsters get +3 to one skill (typically knowledge)
    if intelligent then
        entity.m20_skills.knowledge = entity.m20_skills.knowledge + 3
    end

    return entity
end

--- Determine the relevant stat for a skill check
---@param entity table Entity with m20_stats
---@param skill_name string Skill name
---@param preferred_stat? string "STR", "DEX", or "MIND" (optional override)
---@return number stat_bonus The relevant stat bonus
function M.get_skill_stat_bonus(entity, skill_name, preferred_stat)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")

    local stats = entity.m20_stats

    -- If preferred stat specified, use it
    if preferred_stat then
        if preferred_stat == "STR" then
            return dice.stat_bonus(stats.STR)
        elseif preferred_stat == "DEX" then
            return dice.stat_bonus(stats.DEX)
        elseif preferred_stat == "MIND" then
            return dice.stat_bonus(stats.MIND)
        end
    end

    -- Default stat mapping based on skill
    if skill_name == "physical" then
        -- Use higher of STR or DEX for physical checks
        return math.max(dice.stat_bonus(stats.STR), dice.stat_bonus(stats.DEX))
    elseif skill_name == "subterfuge" then
        -- Use higher of DEX or MIND for subterfuge
        return math.max(dice.stat_bonus(stats.DEX), dice.stat_bonus(stats.MIND))
    elseif skill_name == "knowledge" then
        return dice.stat_bonus(stats.MIND)
    elseif skill_name == "communication" then
        return dice.stat_bonus(stats.MIND)
    end

    return 0
end

--- Make a skill check (d20 + skill rank + stat bonus vs DC)
---@param entity table Entity with m20_stats and m20_skills
---@param skill_name string Skill to check ("physical", "subterfuge", "knowledge", "communication")
---@param dc number Difficulty Class to beat
---@param preferred_stat? string "STR", "DEX", or "MIND" (optional override)
---@return SkillCheckDetailedResult result Skill check result
function M.make_check(entity, skill_name, dc, preferred_stat)
    assert(entity and entity.m20_stats, "Entity must have m20_stats")
    assert(entity and entity.m20_skills, "Entity must have m20_skills")

    local skill_rank = entity.m20_skills[skill_name] or 0
    local stat_bonus = M.get_skill_stat_bonus(entity, skill_name, preferred_stat)
    local roll = dice.roll(20)
    local total = roll + skill_rank + stat_bonus

    return {
        roll = roll,
        skill_rank = skill_rank,
        stat_bonus = stat_bonus,
        total = total,
        success = total >= dc,
        skill_name = skill_name
    }
end

--- Increase all skill ranks by a fixed amount (used on level-up)
---@param entity table Entity with m20_skills
---@param amount? number Amount to increase (default: 1)
function M.increase_all_skills(entity, amount)
    assert(entity and entity.m20_skills, "Entity must have m20_skills")

    amount = amount or 1

    for skill_name, rank in pairs(entity.m20_skills) do
        entity.m20_skills[skill_name] = rank + amount
    end
end

--- Format skill check result as human-readable string
---@param result SkillCheckDetailedResult Skill check result
---@return string text Formatted skill check text
function M.format_check_text(result)
    local success_text = result.success and "Success!" or "Failed"
    return string.format("%s check: %d (d20: %d + skill: %d + stat: %d) %s",
        result.skill_name:gsub("^%l", string.upper), -- Capitalize first letter
        result.total,
        result.roll,
        result.skill_rank,
        result.stat_bonus,
        success_text
    )
end

--- Get skill rank for a specific skill
---@param entity table Entity with m20_skills
---@param skill_name string Skill name
---@return number rank Skill rank (0 if skill doesn't exist)
function M.get_skill_rank(entity, skill_name)
    if not entity or not entity.m20_skills then
        return 0
    end

    return entity.m20_skills[skill_name] or 0
end

--- Set skill rank for a specific skill
---@param entity table Entity with m20_skills
---@param skill_name string Skill name
---@param rank number New rank value
function M.set_skill_rank(entity, skill_name, rank)
    assert(entity and entity.m20_skills, "Entity must have m20_skills")

    entity.m20_skills[skill_name] = rank
end

--- Get all skills as a table for UI display
---@param entity table Entity with m20_skills
---@return table skills Table of {skill_name = rank}
function M.get_all_skills(entity)
    if not entity or not entity.m20_skills then
        return {}
    end

    -- Return a copy to avoid mutation
    local skills_copy = {}
    for skill_name, rank in pairs(entity.m20_skills) do
        skills_copy[skill_name] = rank
    end

    return skills_copy
end

return M
