-- main/scripts/modules/weapon_attacks.lua
-- Weapon-based melee attack system
-- Different attack behaviors for spear (pierce), axe (wide sweep), sword (balanced)

local M = {}

local weapons = require("main.scripts.modules.m20_weapons")
local dice = require("main.scripts.modules.m20_dice")

---@class AttackResult
---@field hit boolean Whether attack hit
---@field damage number Damage dealt
---@field targets table[] List of entities hit
---@field attack_type string Attack type used ("melee", "ranged", "magic")

--- Find enemies in an arc from the player
---@param player_pos vector3 Player position
---@param mouse_pos vector3 Mouse/target position
---@param arc_degrees number Arc width in degrees
---@param range number Attack range multiplier
---@return table[] enemies List of enemy URLs in arc
local function find_enemies_in_arc(player_pos, mouse_pos, arc_degrees, range)
    local base_range = 50  -- Base melee range in pixels
    local actual_range = base_range * range

    -- Direction to mouse/target
    local dir_to_target = mouse_pos - player_pos
    local target_angle = math.atan2(dir_to_target.y, dir_to_target.x)

    -- Find all enemies in range
    local enemies_in_arc = {}
    local half_arc = math.rad(arc_degrees / 2)

    -- Query physics for enemies (would need collision detection here)
    -- For now, we'll use a simple approach with trigger groups
    -- This is a placeholder - actual implementation needs collision queries

    return enemies_in_arc
end

--- Create visual attack effect based on weapon type
---@param player_pos vector3 Player position
---@param mouse_pos vector3 Mouse/target position
---@param attack_type string Attack type ("melee", "ranged", "magic")
---@param range number Range multiplier
local function create_attack_visual(player_pos, mouse_pos, attack_type, range)
    local dir = mouse_pos - player_pos
    local angle = math.atan2(dir.y, dir.x)
    local rotation = vmath.quat_rotation_z(angle)

    -- Create different visual effects based on attack type
    if attack_type == "melee" then
        -- Short-range slash animation
        print(string.format("[Weapon Attack] Melee attack: angle=%.1f°, range=%.1fx",
            math.deg(angle), range))
    elseif attack_type == "ranged" then
        -- Long-range arrow/projectile
        print(string.format("[Weapon Attack] Ranged attack: angle=%.1f°, range=%.1fx",
            math.deg(angle), range))
    elseif attack_type == "magic" then
        -- Medium-range magic projectile
        print(string.format("[Weapon Attack] Magic attack: angle=%.1f°, range=%.1fx",
            math.deg(angle), range))
    end

    -- TODO: Spawn actual visual effect game object or projectile
    -- factory.create("#weapon_effect_factory", player_pos, rotation)
end

--- Perform weapon attack with M20 dice rolls
---@param performer table Player entity with equipped_weapon and m20_stats
---@param mouse_world_pos vector3 Target position for attack direction
---@return AttackResult? result Attack result or nil if no weapon equipped
function M.weapon_attack(performer, mouse_world_pos)
    local weapon = weapons.get_equipped_weapon(performer)
    if not weapon then
        print("[Weapon Attack] No weapon equipped")
        return nil
    end

    -- Get attack parameters
    local params = weapons.get_attack_params(performer)
    if not params then
        print("[Weapon Attack] Failed to get attack parameters")
        return nil
    end

    local player_pos = go.get_position()

    print(string.format("[Weapon Attack] %s attack - type:%s speed:%.1fx range:%.1fx",
        weapon.name, params.type, params.speed, params.range))

    -- Create visual effect
    create_attack_visual(player_pos, mouse_world_pos, params.type, params.range)

    -- Find enemies in attack arc (using fixed 60° arc for now)
    local enemies = find_enemies_in_arc(player_pos, mouse_world_pos, 60, params.range)

    -- Attack each enemy found
    local result = {
        hit = #enemies > 0,
        damage = 0,
        targets = {},
        attack_type = params.type
    }

    for _, enemy_url in ipairs(enemies) do
        -- Roll M20 attack roll: d20 + attack bonus vs enemy AC
        local attack_roll = dice.roll(20) + params.attack_bonus

        -- Get enemy AC (would need to query enemy script)
        local enemy_ac = 12  -- Default AC, should query enemy

        if attack_roll >= enemy_ac then
            -- Hit! Roll damage
            local damage_dice_result = dice.parse_notation(params.damage_dice)
            local damage_roll = dice.roll(damage_dice_result.sides, damage_dice_result.count)
            local total_damage = damage_roll + params.damage_bonus

            -- Send damage to enemy
            msg.post(enemy_url, hash(MESSAGES.PLAYER.TAKE_DAMAGE), {
                damage = total_damage
            })

            result.damage = result.damage + total_damage
            table.insert(result.targets, enemy_url)

            print(string.format("[Weapon Attack] HIT! Roll:%d vs AC:%d, Damage:%s=%d+%d=%d",
                attack_roll, enemy_ac, params.damage_dice, damage_roll,
                params.damage_bonus, total_damage))
        else
            print(string.format("[Weapon Attack] MISS! Roll:%d vs AC:%d",
                attack_roll, enemy_ac))
        end
    end

    return result
end

--- Generic melee attack - uses equipped weapon (melee, ranged, or magic)
---@param performer table Player entity
---@param mouse_world_pos vector3 Target position
---@return AttackResult? result
function M.melee_attack(performer, mouse_world_pos)
    return M.weapon_attack(performer, mouse_world_pos)
end

return M
