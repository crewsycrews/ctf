local C = require("main.scripts.modules.catalog")
local Combat = require("main.scripts.modules.combat")
local Session = require("main.scripts.modules.session")
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
  msg.post("main:/loader#script", "load_level", { level = "game_over" })
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
    object = factory.create(item.resource and "/totem#loot_visuals" or "/totem#visuals", vmath.vector3(item.x, item.y, 0.15))
    visuals[key] = object
    if item.resource then label.set_text(msg.url(nil, object, "name"), C.names[item.resource]) end
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

local function render(w)
  local seen = {}
  for _, f in ipairs(w.fields) do
    local element = f.cast and f.cast.element or f.kind:gsub("head_", "")
    if element == "mud" then element = "earth" end
    if element == "steam" then element = "water" end
    if element == "trail" then element = "fire" end
    show(f, element, f.radius, 0.2, seen)
  end
  for _, p in ipairs(w.projectiles) do show(p, p.frost and "water" or p.cast.element, 10, 1, seen) end
  for _, drop in ipairs(w.drops) do show(drop, drop.resource, 12, 1, seen) end
  for _, f in ipairs(w.flashes) do show(f, f.element, f.radius, 0.7, seen) end
  for key, object in pairs(visuals) do
    if not seen[key] then go.delete(object); visuals[key] = nil end
  end
end

function M.tick(dt)
  local w = M.get()
  if not w or not w.run.active then return end
  local remaining = dt
  while remaining > 0 and w.head.health > 0 do
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
      local tint = ""
      if Combat.has(w, enemy, "frozen") or Combat.has(w, enemy, "wet") then tint = "water"
      elseif Combat.has(w, enemy, "smolder") or Combat.has(w, enemy, "burn") then tint = "fire"
      elseif Combat.has(w, enemy, "slow") then tint = "earth" end
      go.set(msg.url(nil, enemy.object, "sprite"), "tint", color(tint))
      sprite.set_hflip(msg.url(nil, enemy.object, "sprite"), enemy.x < w.head.x)
    end
  end
  render(w)
  if w.head.health <= 0 then M.finish(false) end
end

return M
