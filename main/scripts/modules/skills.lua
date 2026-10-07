local C = require("main.scripts.modules.catalog")
local Combat = require("main.scripts.modules.combat")
local M = {}

-- The Defold player owns movement; combat owns the attached elemental effects.
function M.start_head(world, action, ready, direction)
  if not world.run.active or (ready[action] or 0) > world.time then return nil end
  ready[action] = world.time + C.balance.head_cooldown
  world.head.ready = ready
  local movement = { action = action, elapsed = 0,
    group = Combat.head_action(world, action, world.head.x, world.head.y),
    direction = { x = direction.x, y = direction.y },
    duration = action == "jump" and C.balance.jump_duration or C.balance.dash_duration }
  if action == "dash" or action == "jump" then
    world.head.invulnerable_until = world.time + movement.duration
  end
  return movement
end

M.cast_tail = Combat.cast
return M
