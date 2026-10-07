package.path = './?.lua;' .. package.path
local C = require('main.scripts.modules.catalog')
local P = require('main.scripts.modules.profile')
local S = require('main.scripts.modules.session')
local Combat = require('main.scripts.modules.combat')
local count = 0
local function test(name, fn)
  local ok, err = pcall(fn)
  if not ok then error(name .. ': ' .. tostring(err), 0) end
  count = count + 1
  print('ok ' .. count .. ' - ' .. name)
end
local function eq(a, b) assert(a == b, tostring(a) .. ' ~= ' .. tostring(b)) end
local function near(a, b) assert(math.abs(a - b) < 0.001, a .. ' ~= ' .. b) end
local function grown_profile()
  local p = P.new()
  assert(P.plant(p, 1, 'fire')); assert(P.care(p, 1))
  return p
end
local function run(p)
  local ok, r = P.begin_run(p); assert(ok, r); return r
end
local function world(element, secondary)
  local r = { id = 1, active = true, elapsed = 0, kills = 0, bag = C.resource_bag(), head = {}, tail = {} }
  local w = Combat.new(r, function(n) return n end)
  w.head.x, w.head.y = 0, 0
  local f = { x = 200, y = 0, element = element, secondary = secondary }
  w.followers[1] = f
  return w, f
end
local function enemy(w, key, x, y, hp)
  return Combat.add_enemy(w, key, x or 230, y or 0, hp or 200, 0, 10)
end
local function advance(w, seconds)
  local remaining = seconds
  while remaining > 0.000001 do
    local dt = math.min(remaining, 1 / 60)
    Combat.update(w, dt); remaining = remaining - dt
  end
end

test('tutorial charges real resources, instant first growth and selected Maple', function()
  local p = P.new()
  assert(not P.begin_run(p)); assert(not P.plant(p, 1, 'water'))
  assert(P.plant(p, 1, 'fire')); eq(p.resources.fire, 0)
  assert(not P.upgrade(p, 1, 'water'))
  assert(P.care(p, 1)); eq(p.trees[1].stage, 'adult'); eq(p.selected.fire, 1)
  eq(p.resources.compost, 0); eq(p.tutorial, 'done'); assert(P.valid(p))
end)

test('growth requires care and a successful expedition, settlement is idempotent', function()
  local p = grown_profile(); p.resources.water = 2; p.resources.compost = 1; p.resources.minerals = 1
  assert(P.plant(p, 2, 'water')); assert(P.plant(p, 3, 'water'))
  assert(P.care(p, 2))
  local failed = run(p); failed.bag.earth = 4; assert(P.finish(p, failed, false))
  eq(p.resources.earth, 0); eq(p.trees[2].stage, 'growing')
  local success = run(p); success.bag.wind = 2; assert(P.finish(p, success, true))
  eq(p.resources.wind, 2); eq(p.trees[2].stage, 'adult'); eq(p.trees[3].stage, 'seedling')
  assert(not P.finish(p, success, true)); eq(p.resources.wind, 2); eq(p.successful_runs, 1)
end)

test('all 12 exact directed recipes charge once and keep base skills during growth', function()
  local expected = {
    water_fire = 'Flame willow', water_earth = 'Wooly willow', water_wind = 'Babylon willow',
    fire_water = 'Amur maple', fire_earth = 'Black maple', fire_wind = 'Silver maple',
    earth_fire = 'Red Oak', earth_water = 'Willow oak', earth_wind = 'Chinese cork oak',
    wind_fire = 'Tsavo poplar', wind_water = 'Swamp poplar', wind_earth = 'Gray Poplar'
  }
  for base, recipes in pairs(C.recipes) do
    for secondary, name in pairs(recipes) do
      eq(name, expected[base .. '_' .. secondary])
      local p = grown_profile()
      p.trees[2] = { element = base, stage = 'adult' }; assert(P.select(p, 2))
      p.resources[secondary], p.resources.compost, p.resources.minerals = 1, 1, 1
      assert(not P.upgrade(p, 2, base)); eq(p.resources[secondary], 1)
      assert(P.upgrade(p, 2, secondary)); eq(p.resources[secondary], 0)
      eq(p.trees[2].secondary, nil); assert(P.adult(p.trees[2]))
      assert(not P.upgrade(p, 2, secondary)); assert(P.finish(p, run(p), true))
      eq(C.tree_name(p.trees[2]), name); assert(not P.upgrade(p, 2, secondary))
      assert(P.valid(p))
    end
  end
end)

test('invalid or unaffordable operations do not partially spend resources', function()
  local p = grown_profile(); p.resources.water = 1
  assert(not P.plant(p, 17, 'water')); eq(p.resources.water, 1)
  assert(P.plant(p, 2, 'water')); p.resources.compost = 1
  assert(not P.care(p, 2)); eq(p.resources.compost, 1); eq(p.trees[2].stage, 'seedling')
  assert(not P.infuse(p, 'dash', 'water')); assert(not P.infuse(p, 'bogus', 'fire'))
end)

test('loadout has fixed order, one per element, and is a snapshot', function()
  local p = grown_profile()
  for n, e in ipairs(C.elements) do p.trees[n + 1] = { element = e, stage = 'adult' }; assert(P.select(p, n + 1)) end
  assert(P.infuse(p, 'jump', 'fire'))
  local r = run(p); eq(#r.tail, 4)
  for n, e in ipairs(C.elements) do eq(r.tail[n].element, e) end
  p.trees[2].secondary = 'water'; p.head.jump = 'earth'
  eq(r.tail[1].secondary, nil); eq(r.head.jump, 'fire')
  assert(P.select(p, 2)); eq(#P.loadout(p), 3)
  assert(P.infuse(p, 'dash', 'fire')) -- grown tree need not be selected
end)

test('save failure leaves profile unchanged and retry commits exactly once', function()
  local saved, fail = nil, true
  S.configure(P.new(), function(p) if fail then return false end; saved = C.copy(p); return true end)
  assert(not S.change('plant', 1, 'fire')); eq(S.get().resources.fire, 1); assert(S.blocked())
  assert(not S.change('plant', 2, 'fire'))
  fail = false; assert(S.retry()); eq(S.get().resources.fire, 0); assert(saved.trees[1])
  assert(S.change('care', 1)); assert(S.begin())
  S.run.bag.water = 3; fail = true; assert(not S.finish(true)); eq(S.get().resources.water, 0)
  assert(not S.finish(true)); fail = false; assert(S.retry()); eq(S.get().resources.water, 3)
  eq(S.get().successful_runs, 1)
  S.configure(saved, function() return true end); eq(S.run, nil) -- no resumable backpack
end)

test('enemy deaths produce a balanced loot bag exactly once; contact grants nothing', function()
  local w = world('fire')
  for i = 1, 6 do local e = enemy(w, i); Combat.kill(w, e, true); Combat.kill(w, e, true) end
  eq(#w.drops, 6); eq(w.run.kills, 6)
  local found = {}; for _, d in ipairs(w.drops) do found[d.resource] = (found[d.resource] or 0) + 1 end
  for _, resource in ipairs(C.resources) do eq(found[resource], 1) end
  Combat.kill(w, enemy(w, 7), false); eq(#w.drops, 6)
  w.head.x, w.head.y = 230, 0; advance(w, 0.02)
  for _, resource in ipairs(C.resources) do eq(w.run.bag[resource], 1) end
end)

test('exit requires time, distance, life and active run', function()
  local w = world('fire'); w.head.x, w.head.y = w.exit.x, w.exit.y
  assert(not Combat.can_exit(w)); w.run.elapsed = 90; assert(Combat.can_exit(w))
  w.head.x = w.head.x + 81; assert(not Combat.can_exit(w)); w.head.x = w.exit.x
  w.head.health = 0; assert(not Combat.can_exit(w))
end)

test('invulnerability, non-stacking shield, freeze and slow expire independently', function()
  local w = world('fire'); w.head.invulnerable_until = 1
  Combat.hurt_head(w, 50); eq(w.head.health, 100); w.time = 1
  Combat.shield(w); Combat.hurt_head(w, 15); eq(w.head.shield, 5); eq(w.head.health, 100)
  Combat.shield(w); eq(w.head.shield, 20); Combat.hurt_head(w, 30); eq(w.head.health, 90)
  local e = enemy(w, 1); e.speed = 20
  Combat.status(w, e, 'slow', 4); Combat.status(w, e, 'frozen', 2); eq(Combat.speed(w, e), 0)
  Combat.status(w, e, 'slow', 0.1); Combat.status(w, e, 'frozen', 0.1)
  w.time = 3.1; eq(Combat.speed(w, e), 10); w.time = 5.1; eq(Combat.speed(w, e), 20)
end)

test('water variants: thaw burst, shield and additional frost bolt', function()
  local w, f = world('water', 'fire'); local e = enemy(w, 1)
  assert(Combat.cast(w, f, 1, 0)); advance(w, 0.02); near(e.health, 190)
  advance(w, 2.1); near(e.health, 180)
  w, f = world('water', 'earth'); Combat.cast(w, f, 1, 0); eq(w.head.shield, 20)
  w, f = world('water', 'wind'); e = enemy(w, 1, 320)
  Combat.cast(w, f, 1, 0); advance(w, 0.25); near(e.health, 190); assert(Combat.has(w, e, 'frozen'))
end)

test('fire variants: steam, push and piercing with once-per-target hits', function()
  local w, f = world('fire', 'water'); local e = enemy(w, 1)
  Combat.cast(w, f, 1, 0); advance(w, 0.05); near(e.health, 180)
  assert(Combat.has(w, e, 'slow'))
  w, f = world('fire', 'earth'); e = enemy(w, 1)
  Combat.cast(w, f, 1, 0); advance(w, 0.02); eq(e.x, 290)
  w, f = world('fire', 'wind')
  local targets = {}; for i = 1, 4 do targets[i] = enemy(w, i, 230 + i * 65) end
  Combat.cast(w, f, 1, 0); advance(w, 0.7)
  for i = 1, 3 do near(targets[i].health, 180) end; near(targets[4].health, 200)
end)

test('earth variants: burning, mud and pull', function()
  local w, f = world('earth', 'fire'); local e = enemy(w, 1)
  Combat.cast(w, f, 1, 0); advance(w, 3.1); near(e.health, 178)
  w, f = world('earth', 'water'); e = enemy(w, 1)
  Combat.cast(w, f, 1, 0); advance(w, 0.6); assert(Combat.has(w, e, 'slow'))
  w, f = world('earth', 'wind'); e = enemy(w, 1, 270)
  Combat.cast(w, f, 1, 0); advance(w, 0.02); eq(e.x, 210)
end)

test('air variants: trail damage, heal once and one terminal explosion', function()
  local w, f = world('wind', 'fire'); local e = enemy(w, 1, 215, 20)
  Combat.cast(w, f, 1, 0); advance(w, 0.1); assert(e.health < 175)
  w, f = world('wind', 'water'); w.head.health = 95; e = enemy(w, 1)
  Combat.cast(w, f, 1, 0); advance(w, 0.1); eq(w.head.health, 100)
  w, f = world('wind', 'earth'); e = enemy(w, 1)
  Combat.cast(w, f, 1, 0); advance(w, 0.1); near(e.health, 165)
  advance(w, 1); near(e.health, 165)
end)

for _, action in ipairs(C.actions) do
  for _, element in ipairs(C.elements) do
    test(action .. ' + ' .. element .. ' prepares a field; matching base and upgraded tail react once', function()
      for _, upgraded in ipairs({ false, true }) do
        local finisher = C.finishers[element]
        local secondary = upgraded and (finisher == 'fire' and 'wind' or 'earth') or nil
        if secondary == finisher then secondary = 'fire' end
        local w, f = world(finisher, secondary)
        w.run.head[action] = element
        local group = Combat.head_action(w, action, 220, 0)
        if action == 'dash' then Combat.head_trace(w, group, 220, 0, 250, 0)
        elseif action == 'jump' then eq(#w.fields, 0); Combat.head_land(w, group, 220, 0) end
        local e = enemy(w, 1, 240)
        advance(w, 0.02); Combat.cast(w, f, 1, 0); advance(w, 0.1)
        assert(w.reaction_until > w.time, 'no reaction')
        if element == 'fire' then assert(not Combat.has(w, e, 'smolder')) end
        if element == 'water' then assert(not Combat.has(w, e, 'wet')) end
        local reaction_until = w.reaction_until
        advance(w, 0.1); eq(w.reaction_until, reaction_until)
      end
    end)
  end
end

test('air fan and piercing share a hit ledger, and only consume one field', function()
  local w, f = world('fire', 'wind'); w.run.head.dash = 'wind'
  Combat.head_action(w, 'dash', 210, 0)
  local second = Combat.head_action(w, 'dash', 210, 0)
  local e = enemy(w, 1, 280)
  Combat.cast(w, f, 1, 0); advance(w, 0.3)
  near(e.health, 180); eq(second.consumed, false)
end)

test('secondary explosions do not consume another head mark or trigger cascades', function()
  local w, f = world('water', 'fire')
  local e = enemy(w, 1, 210); local other = enemy(w, 2, 280)
  Combat.status(w, e, 'smolder', 3); Combat.status(w, other, 'smolder', 3)
  Combat.cast(w, f, 1, 0); advance(w, 0.02)
  assert(not Combat.has(w, e, 'smolder')); assert(Combat.has(w, other, 'smolder'))
end)

test('projectiles expire, wind bursts on timeout and inactive worlds stop', function()
  local w, f = world('wind', 'earth'); local e = enemy(w, 1, 520, 40)
  Combat.cast(w, f, 1, 0); advance(w, 0.6); eq(#w.projectiles, 0); near(e.health, 190)
  w.run.active = false; local time = w.time; advance(w, 1); eq(w.time, time)
end)

print('PASS: ' .. count .. ' tests')
