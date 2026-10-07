local C = require("main.scripts.modules.catalog")
local Combat = require("main.scripts.modules.combat")
local Session = require("main.scripts.modules.session")
local Expedition = require("main.scripts.modules.expedition")
local M = {}
local world, visuals, run_ref

function M.constrain(entity, x, y)
  -- Bounds of the existing 64px tilemap at (106,106), scale 0.781.
  x, y = math.max(24, math.min(2280, x)), math.max(24, math.min(2180, y))
  local dx, dy = x - entity.x, y - entity.y
  local length = math.sqrt(dx * dx + dy * dy)
  if length < 0.001 then return x, y end
  local fraction = 1
  local radius = entity.cast and 5 or 12
  for _, offset in ipairs({ -radius, 0, radius }) do
    local ox, oy = -dy / length * offset, dx / length * offset
    local start = vmath.vector3(entity.x + ox, entity.y + oy, 0)
    local finish = vmath.vector3(x + ox + dx / length * radius, y + oy + dy / length * radius, 0)
    local hit = physics.raycast(start, finish, { hash("obstacles") })
    if hit then fraction = math.min(fraction, math.max(0, (hit.fraction * (length + radius) - radius) / length)) end
  end
  return entity.x + dx * fraction, entity.y + dy * fraction
end

function M.get()
  if not Session.run then return nil end
  if run_ref ~= Session.run then
    run_ref, visuals = Session.run, {}
    world = Combat.new(run_ref)
    world.move = M.constrain
  end
  return world
end

function M.finish(success)
  local w = M.get()
  if not w or not w.run.active then return end
  Session.finish(success)
  if not w.run.active then msg.post("main:/loader#script", "load_level", { level = "game_over" }) end
end

local function color(element, alpha)
  local c = C.colors[element] or { 1, 1, 1 }
  return vmath.vector4(c[1], c[2], c[3], alpha or 1)
end
M.color = color

local function show(item, element, radius, alpha, seen)
  local key = item.id
  local object = visuals[key]
  if not object then
    object = factory.create("/totem#visuals", vmath.vector3(item.x, item.y, 0.15))
    visuals[key] = object
  end
  seen[key] = true
  local x2, y2 = item.x2 or item.x, item.y2 or item.y
  local dx, dy = x2 - item.x, y2 - item.y
  local length = math.sqrt(dx * dx + dy * dy)
  go.set_position(vmath.vector3((item.x + x2) / 2, (item.y + y2) / 2, 0.15), object)
  if length > 0 then go.set_rotation(vmath.quat_rotation_z(math.atan2(dy, dx)), object) end
  go.set_scale(vmath.vector3((2 * radius + length) / 64, 2 * radius / 64, 1), object)
  go.set(msg.url(nil, object, "sprite"), "tint", color(element, alpha))
end

-- Original spell flipbooks are presentation only: no legacy scripts, collisions
-- or timers can move them or apply damage a second time.
local function show_spell(item, name, angle, scale, seen)
  local object = visuals[item.id]
  if not object then
    object = factory.create("/totem#" .. name .. "_visuals", vmath.vector3(item.x, item.y, 0.2))
    visuals[item.id] = object
  end
  seen[item.id] = true
  go.set_position(vmath.vector3(item.x, item.y, 0.2), object)
  go.set_rotation(vmath.quat_rotation_z(angle or 0), object)
  go.set_scale(scale or 1, object)
end

local function render(w)
  local seen = {}
  for _, f in ipairs(w.fields) do
    local element = f.cast and f.cast.element or f.kind:gsub("head_", "")
    if element == "mud" then element = "earth" end
    if element == "steam" then element = "water" end
    if element == "trail" then element = "fire" end
    if f.kind == "spell" and element == "water" then
      show_spell(f, "ice_barrage", math.atan2(f.dy, f.dx), f.length / 299, seen)
    elseif f.kind == "spell" and element == "earth" then
      show_spell(f, "thunderclap", 0, 2 * f.radius / 96, seen)
    else
      show(f, element, f.radius, 0.2, seen)
    end
  end
  for _, p in ipairs(w.projectiles) do
    if p.frost then show(p, "water", 10, 1, seen)
    elseif p.cast.element == "fire" then
      -- Fire art points left, wind art points up; align them with the model's velocity.
      show_spell(p, "fireball", math.atan2(p.dy, p.dx) + math.pi, 1, seen)
    elseif p.cast.element == "wind" then
      show_spell(p, "windwalker", math.atan2(p.dy, p.dx) - math.pi / 2, 1, seen)
    end
  end
  for _, f in ipairs(w.flashes) do show(f, f.element, f.radius, 0.7, seen) end
  for key, object in pairs(visuals) do
    if not seen[key] then go.delete(object); visuals[key] = nil end
  end
end

local function spawn(w)
  if w.time < (w.next_spawn or 0) then return end
  local kind = Expedition.next_spawn(w)
  if not kind then return end
  -- Place enemies along a clear line from the head, rather than behind map obstacles.
  local angle = math.random() * math.pi * 2
  for attempt = 1, 12 do
    local a = angle + attempt * math.pi / 6
    local x, y = M.constrain(w.head, w.head.x + math.cos(a) * 360, w.head.y + math.sin(a) * 360)
    if Combat.distance(w.head, { x = x, y = y }) > 160 then
      local boss, level = kind == "boss", w.run.level
      factory.create(boss and "/totem#boss" or "/totem#enemies", vmath.vector3(x, y, 0), nil,
        { health = level.health * (boss and C.expedition.boss_health_multiplier or 1),
          speed = boss and C.expedition.boss_speed or level.speed,
          damage = boss and C.expedition.boss_damage or 10, boss = boss })
      if boss then w.boss_spawned = true end
      w.next_spawn = w.time + C.expedition.spawn_interval
      return
    end
  end
  w.next_spawn = w.time + 0.5
end

function M.tick(dt)
  local w = M.get()
  if not w or not w.run.active then return end
  local remaining = dt
  while remaining > 0 and w.head.health > 0 and not Expedition.complete(w.run) do
    local step = math.min(remaining, 1 / 60)
    Combat.update(w, step)
    remaining = remaining - step
  end
  for key, enemy in pairs(w.enemies) do
    if enemy.dead then
      go.delete(enemy.object)
      w.enemies[key] = nil
    else
      go.set_position(vmath.vector3(enemy.x, enemy.y, 0), enemy.object)
      local tint = enemy.boss and "fire" or ""
      if Combat.has(w, enemy, "frozen") or Combat.has(w, enemy, "wet") then tint = "water"
      elseif Combat.has(w, enemy, "smolder") or Combat.has(w, enemy, "burn") then tint = "fire"
      elseif Combat.has(w, enemy, "slow") then tint = "earth" end
      go.set(msg.url(nil, enemy.object, "sprite"), "tint", color(tint))
      sprite.set_hflip(msg.url(nil, enemy.object, "sprite"), enemy.x < w.head.x)
    end
  end
  render(w)
  if w.head.health <= 0 then M.finish(false)
  elseif Expedition.complete(w.run) then M.finish(true)
  else spawn(w) end
end

return M
