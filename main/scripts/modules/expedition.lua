-- Level objectives and rewards are shared by preparation, combat and settlement.
local C = require("main.scripts.modules.catalog")
local M = {}

-- Level progress is saved and only advances on victory. Retries, deaths and
-- restarts therefore keep the same reward without a separate mutable cursor.
function M.reward_element(level)
  local rotation = C.expedition.reward_rotation
  return rotation[((level or 1) - 1) % #rotation + 1]
end

function M.level(number)
  number = math.max(1, number or 1)
  local b = C.expedition
  return { number = number, target = math.min(b.max_target, b.first_target + (number - 1) * b.target_step),
    boss = number % b.boss_every == 0,
    reward_count = math.min(b.max_reward, 1 + math.floor((number - 1) / b.reward_every)),
    health = b.enemy_health + math.min(number - 1, 20) * b.health_step,
    speed = math.min(b.max_speed, b.enemy_speed + (number - 1) * b.speed_step) }
end

function M.complete(run)
  return run.level and run.kills >= run.level.target and (not run.level.boss or run.boss_defeated == true)
end

function M.reward(run)
  local bag = C.resource_bag()
  bag[run.reward_element] = run.level.reward_count
  bag.compost, bag.minerals = run.level.reward_count, run.level.reward_count
  return bag
end

-- Contact deaths do not count, so the director replaces them until the quota is met.
function M.next_spawn(w)
  if not w.run.active or not w.run.level or M.complete(w.run) then return nil end
  local alive = 0
  for _, enemy in pairs(w.enemies) do if not enemy.dead then alive = alive + 1 end end
  local remaining = w.run.level.target - w.run.kills
  if remaining > 0 and alive < math.min(remaining, C.expedition.max_alive) then return "enemy" end
  if remaining <= 0 and w.run.level.boss and not w.boss_spawned then return "boss" end
end

return M
