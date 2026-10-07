local C = require("main.scripts.modules.catalog")
local B = C.balance
local M = {}

local function distance(a, b)
  local x, y = a.x - b.x, a.y - b.y
  return math.sqrt(x * x + y * y)
end

local function segment_distance(p, a, b)
  local x, y = b.x - a.x, b.y - a.y
  local length = x * x + y * y
  local t = length > 0 and math.max(0, math.min(1, ((p.x - a.x) * x + (p.y - a.y) * y) / length)) or 0
  return distance(p, { x = a.x + x * t, y = a.y + y * t })
end

M.distance, M.segment_distance = distance, segment_distance

local function crosses_field(a, b, f)
  local c, d = f, { x = f.x2 or f.x, y = f.y2 or f.y }
  local ux, uy, vx, vy = b.x - a.x, b.y - a.y, d.x - c.x, d.y - c.y
  local cross = ux * vy - uy * vx
  if math.abs(cross) > 0.00001 then
    local wx, wy = c.x - a.x, c.y - a.y
    local t, s = (wx * vy - wy * vx) / cross, (wx * uy - wy * ux) / cross
    if t >= 0 and t <= 1 and s >= 0 and s <= 1 then return true end
  end
  return math.min(segment_distance(a, c, d), segment_distance(b, c, d),
    segment_distance(c, a, b), segment_distance(d, a, b)) <= f.radius
end

function M.new(run, random)
  return { run = run, time = 0, enemies = {}, followers = {}, projectiles = {},
    fields = {}, drops = {}, flashes = {}, loot = {}, serial = 0, random = random or math.random,
    head = { x = 1133, y = 1080, health = B.max_health, shield = 0 },
    exit = { x = 1118, y = 1264 }, reaction = "", reaction_until = 0 }
end

local function id(w)
  w.serial = w.serial + 1
  return w.serial
end

function M.add_enemy(w, key, x, y, health, speed, damage)
  local enemy = { id = key, x = x, y = y, health = health, speed = speed,
    damage = damage, statuses = {}, dead = false }
  w.enemies[key] = enemy
  return enemy
end

function M.status(w, enemy, name, duration)
  enemy.statuses[name] = math.max(enemy.statuses[name] or 0, w.time + duration)
end

function M.has(w, enemy, name)
  return (enemy.statuses[name] or 0) > w.time
end

function M.speed(w, enemy)
  if M.has(w, enemy, "frozen") then return 0 end
  return enemy.speed * (M.has(w, enemy, "slow") and B.slow or 1)
end

function M.shield(w)
  w.head.shield, w.head.shield_until = B.shield, w.time + B.shield_duration
end

function M.hurt_head(w, damage)
  if not w.run.active or (w.head.invulnerable_until or 0) > w.time then return end
  if (w.head.shield_until or 0) <= w.time then w.head.shield = 0 end
  local absorbed = math.min(w.head.shield, damage)
  w.head.shield = w.head.shield - absorbed
  w.head.health = math.max(0, w.head.health - damage + absorbed)
end

local function next_loot(w)
  if #w.loot == 0 then
    for _, key in ipairs(C.resources) do w.loot[#w.loot + 1] = key end
    for i = #w.loot, 2, -1 do
      local j = w.random(i)
      w.loot[i], w.loot[j] = w.loot[j], w.loot[i]
    end
  end
  return table.remove(w.loot)
end

function M.kill(w, enemy, ability)
  if enemy.dead then return end
  enemy.dead = true
  if ability then
    w.run.kills = w.run.kills + 1
    w.drops[#w.drops + 1] = { id = id(w), x = enemy.x, y = enemy.y, resource = next_loot(w) }
  end
end

function M.damage(w, enemy, amount)
  if enemy.dead or not w.run.active then return end
  enemy.health = enemy.health - amount
  if enemy.health <= 0 then M.kill(w, enemy, true) end
end

local function flash(w, x, y, radius, element)
  w.flashes[#w.flashes + 1] = { id = id(w), x = x, y = y, radius = radius,
    element = element, expires = w.time + 0.3 }
end

local function burst(w, x, y, damage, slow)
  flash(w, x, y, B.burst_radius, slow and "water" or "earth")
  for _, enemy in pairs(w.enemies) do
    if not enemy.dead and distance(enemy, { x = x, y = y }) <= B.burst_radius then
      M.damage(w, enemy, damage)
      if slow then M.status(w, enemy, "slow", slow) end
    end
  end
end

local function field(w, kind, x, y, radius, duration, group)
  local f = { id = id(w), kind = kind, x = x, y = y, radius = radius,
    expires = w.time + duration, group = group }
  w.fields[#w.fields + 1] = f
  return f
end
M.field = field

function M.head_action(w, action, x, y)
  local element = w.run.head[action]
  if not element or not w.run.active then return nil end
  local group = { consumed = false, element = element, marked = {} }
  if element == "earth" then M.shield(w) end
  if action ~= "jump" then field(w, "head_" .. element, x, y, B.head_radius, B.head_duration, group) end
  return group
end

function M.head_trace(w, group, x, y, x2, y2)
  if not group or not w.run.active then return end
  local f = field(w, "head_" .. group.element, x, y, B.head_radius, B.head_duration, group)
  f.x2, f.y2 = x2, y2
end

function M.head_land(w, group, x, y)
  if group and w.run.active then
    field(w, "head_" .. group.element, x, y, B.head_radius, B.head_duration, group)
  end
end

local function reaction(w, cast, name)
  if cast.reacted then return false end
  cast.reacted, w.reaction, w.reaction_until = true, name, w.time + 2
  return true
end

local function move(w, entity, x, y)
  if w.move then x, y = w.move(entity, x, y) end
  entity.x, entity.y = x, y
end

local function displace(w, enemy, x, y, pull)
  local dx, dy = enemy.x - x, enemy.y - y
  local length = math.sqrt(dx * dx + dy * dy)
  if length == 0 then return end
  local amount = pull and -math.min(B.push, length) or B.push
  move(w, enemy, enemy.x + dx / length * amount, enemy.y + dy / length * amount)
end

local function hit(w, cast, enemy, damage, frost)
  if enemy.dead or cast.hits[enemy.id] then return false end
  cast.hits[enemy.id] = true
  -- Only a primary hit can consume a head mark. Bursts and fields call damage directly.
  if cast.element == "water" and M.has(w, enemy, "smolder") and reaction(w, cast, "STEAM BURST") then
    enemy.statuses.smolder = nil
    burst(w, enemy.x, enemy.y, B.burst_damage, B.steam_duration)
  elseif cast.element == "earth" and M.has(w, enemy, "wet") and reaction(w, cast, "MUD") then
    enemy.statuses.wet = nil
    field(w, "mud", enemy.x, enemy.y, B.mud_radius, B.mud_duration)
  end
  M.damage(w, enemy, damage)
  if frost or cast.element == "water" then
    M.status(w, enemy, "frozen", frost or C.spells.water.freeze)
    if cast.secondary == "fire" then enemy.thaw_burst = true end
  end
  if cast.element == "earth" then
    M.status(w, enemy, "slow", C.spells.earth.slow)
    if cast.secondary == "fire" then M.status(w, enemy, "burn", B.burn_duration)
    elseif cast.secondary == "water" then field(w, "mud", enemy.x, enemy.y, B.mud_radius, B.mud_duration)
    elseif cast.secondary == "wind" then displace(w, enemy, cast.x, cast.y, true) end
  elseif cast.element == "fire" then
    if cast.secondary == "water" then field(w, "steam", enemy.x, enemy.y, B.burst_radius, B.steam_duration)
    elseif cast.secondary == "earth" then displace(w, enemy, cast.x, cast.y, false) end
  elseif cast.element == "wind" and cast.secondary == "water" and not cast.healed then
    cast.healed = true
    w.head.health = math.min(B.max_health, w.head.health + B.heal)
  end
  return true
end

local function projectile(w, cast, x, y, dx, dy, frost)
  local length = math.sqrt(dx * dx + dy * dy)
  if length == 0 then dx, dy, length = 0, 1, 1 end
  local p = { id = id(w), cast = cast, x = x, y = y, dx = dx / length, dy = dy / length,
    expires = w.time + (frost and B.projectile_life or C.spells[cast.element].duration),
    remaining = cast.element == "fire" and cast.secondary == "wind" and B.fire_pierce or 1,
    frost = frost, trail_x = x, trail_y = y }
  w.projectiles[#w.projectiles + 1] = p
  return p
end

function M.cast(w, follower, dx, dy)
  if not w.run.active or (follower.ready or 0) > w.time then return false end
  local spec = C.spells[follower.element]
  follower.ready = w.time + spec.cooldown
  local cast = { id = id(w), element = follower.element, secondary = follower.secondary,
    x = follower.x, y = follower.y, hits = {}, reacted = false }
  if cast.element == "water" or cast.element == "earth" then
    local f = field(w, "spell", follower.x, follower.y, spec.radius, spec.duration)
    f.cast, f.follower = cast, follower
    if cast.element == "water" and cast.secondary == "earth" then M.shield(w) end
    if cast.element == "water" and cast.secondary == "wind" then
      -- Separate hit ledger: the extra bolt is a distinct primary projectile,
      -- but shares the same reaction budget as its parent cast.
      local p = projectile(w, cast, follower.x, follower.y, dx, dy, B.frost_duration)
      p.hits = {}
    end
  else
    projectile(w, cast, follower.x, follower.y, dx, dy)
    if cast.element == "wind" then follower.hidden_until = w.time + spec.duration end
  end
  return true
end

local function in_field(f, entity)
  return segment_distance(entity, f, { x = f.x2 or f.x, y = f.y2 or f.y }) <= f.radius
end

local function finish_projectile(w, p)
  if p.dead then return end
  p.dead = true
  if p.cast.element == "wind" and not p.cast.burst_done then
    local damage = 0
    if p.cast.secondary == "earth" then damage = damage + B.burst_damage end
    if p.cast.stone then damage = damage + B.burst_damage end
    p.cast.burst_done = true
    if damage > 0 then burst(w, p.x, p.y, damage) end
  end
end

local function update_projectile(w, p, dt)
  if p.dead then return end
  local old = { x = p.x, y = p.y }
  local step = math.max(0, math.min(dt, p.expires - w.time + dt))
  local nx, ny = p.x + p.dx * B.projectile_speed * step, p.y + p.dy * B.projectile_speed * step
  local blocked = false
  if w.move then
    local bx, by = w.move(p, nx, ny)
    blocked = math.abs(nx - bx) + math.abs(ny - by) > 0.01
    nx, ny = bx, by
  end
  p.x, p.y = nx, ny
  local cast = p.cast
  for _, f in ipairs(w.fields) do
    if f.expires > w.time and f.group and not f.group.consumed and not cast.reacted and
        crosses_field(old, p, f) then
      if f.kind == "head_earth" and cast.element == "wind" then
        f.group.consumed = true
        cast.stone = true
        reaction(w, cast, "STONE BURST READY")
      elseif f.kind == "head_wind" and cast.element == "fire" then
        f.group.consumed = true
        reaction(w, cast, "FIRE FAN")
        for _, angle in ipairs({ -B.fan_angle, B.fan_angle }) do
          local c, s = math.cos(angle), math.sin(angle)
          projectile(w, cast, p.x, p.y, p.dx * c - p.dy * s, p.dx * s + p.dy * c)
        end
      end
    end
  end
  if cast.element == "wind" and cast.secondary == "fire" then
    local d = distance(old, p)
    local count = math.max(1, math.ceil(d / B.trail_spacing))
    for n = 1, count do
      field(w, "trail", old.x + (p.x - old.x) * n / count,
        old.y + (p.y - old.y) * n / count, B.trail_spacing, B.trail_duration)
    end
  end
  local targets = {}
  for _, enemy in pairs(w.enemies) do
    if not enemy.dead and segment_distance(enemy, old, p) <= B.projectile_radius + B.enemy_radius then
      targets[#targets + 1] = enemy
    end
  end
  table.sort(targets, function(a, b) return distance(a, old) < distance(b, old) end)
  for _, enemy in ipairs(targets) do
    local ledger = cast.hits
    if p.hits then cast.hits = p.hits end
    local landed = hit(w, cast, enemy, p.frost and B.frost_damage or C.spells[cast.element].damage, p.frost)
    cast.hits = ledger
    if landed then
      p.remaining = p.remaining - 1
      if p.remaining <= 0 then
        p.x, p.y = enemy.x, enemy.y
        finish_projectile(w, p)
        break
      end
    end
  end
  if not p.dead and (w.time >= p.expires or blocked) then finish_projectile(w, p) end
end

function M.can_exit(w)
  return w.run.active and w.head.health > 0 and w.run.elapsed >= B.exit_time and
    distance(w.head, w.exit) <= B.exit_radius
end

function M.update(w, dt)
  if not w.run.active then return end
  -- The runtime advances in small steps; tests may advance by arbitrary intervals.
  w.time, w.run.elapsed = w.time + dt, w.run.elapsed + dt
  if (w.head.shield_until or 0) <= w.time then w.head.shield = 0 end
  for _, enemy in pairs(w.enemies) do
    if not enemy.dead then
      local burn = math.max(0, math.min(dt, (enemy.statuses.burn or 0) - (w.time - dt)))
      if burn > 0 then M.damage(w, enemy, B.burn_dps * burn) end
      if enemy.thaw_burst and not M.has(w, enemy, "frozen") then
        enemy.thaw_burst = nil
        burst(w, enemy.x, enemy.y, B.burst_damage)
      end
    end
  end
  local field_count = #w.fields
  for i = 1, field_count do
    local f = w.fields[i]
    if f.expires > w.time then
      if f.follower then f.x, f.y = f.follower.x, f.follower.y end
      for _, enemy in pairs(w.enemies) do
        if not enemy.dead and in_field(f, enemy) then
          if f.kind == "spell" then
            f.cast.x, f.cast.y = f.x, f.y
            hit(w, f.cast, enemy, C.spells[f.cast.element].damage)
          elseif f.kind == "head_fire" then
            if not f.group.marked[enemy.id] then
              M.status(w, enemy, "smolder", B.mark_duration)
              f.group.marked[enemy.id] = true
            end
            enemy.fire_tick = true
          elseif f.kind == "head_water" then
            if not f.group.marked[enemy.id] then
              M.status(w, enemy, "wet", B.mark_duration)
              f.group.marked[enemy.id] = true
            end
            M.status(w, enemy, "slow", B.mark_duration)
          elseif f.kind == "mud" or f.kind == "steam" then
            M.status(w, enemy, "slow", dt * 2)
          elseif f.kind == "trail" then enemy.fire_tick = true end
        end
      end
      if f.kind == "head_wind" then
        for _, follower in pairs(w.followers) do
          if in_field(f, follower) then follower.haste_until = w.time + B.haste_duration end
        end
      end
    end
  end
  local projectile_count = #w.projectiles
  for i = 1, projectile_count do update_projectile(w, w.projectiles[i], dt) end
  for _, enemy in pairs(w.enemies) do
    if not enemy.dead then
      if enemy.fire_tick then M.damage(w, enemy, B.fire_dps * dt) end
      enemy.fire_tick = nil
      if not enemy.dead then
        local d = distance(enemy, w.head)
        if d <= B.enemy_radius + 15 then
          M.hurt_head(w, enemy.damage)
          M.kill(w, enemy, false)
        elseif d > 0 then
          local amount = math.min(d, M.speed(w, enemy) * dt)
          move(w, enemy, enemy.x + (w.head.x - enemy.x) / d * amount,
            enemy.y + (w.head.y - enemy.y) / d * amount)
        end
      end
    end
  end
  for i = #w.drops, 1, -1 do
    local drop = w.drops[i]
    if distance(drop, w.head) <= B.pickup_radius then
      w.run.bag[drop.resource] = w.run.bag[drop.resource] + 1
      table.remove(w.drops, i)
    end
  end
  for i = #w.projectiles, 1, -1 do if w.projectiles[i].dead then table.remove(w.projectiles, i) end end
  for i = #w.fields, 1, -1 do if w.fields[i].expires <= w.time then table.remove(w.fields, i) end end
  for i = #w.flashes, 1, -1 do if w.flashes[i].expires <= w.time then table.remove(w.flashes, i) end end
end

return M
