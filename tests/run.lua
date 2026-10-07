package.path = './?.lua;' .. package.path
local C = require('main.scripts.modules.catalog')
local P = require('main.scripts.modules.profile')
local S = require('main.scripts.modules.session')
local Combat = require('main.scripts.modules.combat')
local Expedition = require('main.scripts.modules.expedition')
local Garden = require('main.scripts.modules.garden')
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
local function victory(p, r)
  r.kills, r.boss_defeated = r.level.target, true
  return P.finish(p, r, true)
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
  local success = run(p); success.reward_element = "wind"; success.bag.wind = 200; assert(victory(p, success))
  eq(p.resources.wind, 1); eq(p.trees[2].stage, 'adult'); eq(p.trees[3].stage, 'seedling')
  assert(not P.finish(p, success, true)); eq(p.resources.wind, 1); eq(p.successful_runs, 1)
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
      assert(not P.upgrade(p, 2, secondary)); assert(victory(p, run(p)))
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

test('each grown tree supports exactly one head or tail assignment of its base element', function()
  local p = grown_profile()
  assert(not P.infuse(p, 'dash', 'fire')) -- tutorial tree is already in the tail
  eq(p.head.dash, nil)
  p.trees[2] = { element = 'fire', stage = 'seedling' }
  p.trees[3] = { element = 'fire', stage = 'growing', remaining = 1 }
  eq(P.tree_count(p, 'fire'), 1)
  assert(not P.infuse(p, 'dash', 'fire'))
  p.trees[2] = { element = 'fire', stage = 'upgrading', pending = 'water', remaining = 1 }
  assert(P.infuse(p, 'dash', 'fire')); eq(P.tree_count(p, 'water'), 0)
  assert(P.infuse(p, 'dash', 'fire')) -- retaining an assignment is free
  assert(not P.infuse(p, 'jump', 'fire')); eq(p.head.jump, nil)
  assert(P.select(p, 2)) -- replace the fire follower without spending another tree
  eq(p.selected.fire, 2)
  assert(P.select(p, 2)); assert(P.infuse(p, 'jump', 'fire'))
  assert(not P.select(p, 1)); eq(p.selected.fire, nil)
  assert(P.infuse(p, 'jump', nil)); assert(P.select(p, 1))
  local total, used, free = P.allocation(p, 'fire'); eq(total, 2); eq(used, 2); eq(free, 0)
  p.trees[3] = { element = 'water', stage = 'adult', secondary = 'fire' }
  assert(P.infuse(p, 'dash', 'water')) -- replacing frees fire and uses water
  assert(P.infuse(p, 'jump', 'fire')); assert(P.valid(p))
  assert(not P.infuse(p, 'backward_dash', 'fire')) -- improved water tree grants no extra fire capacity
end)

test('over-allocated preparation is rejected before starting or advancing the run id', function()
  local p = grown_profile(); p.head.dash = 'fire'
  local next_run = p.next_run
  assert(not P.valid(p)); assert(not P.begin_run(p)); eq(p.next_run, next_run)
end)

test('old assignments migrate deterministically without losing trees, resources or tail', function()
  local p = grown_profile(); p.version = 1
  p.trees[2] = { element = 'fire', stage = 'adult' }
  p.head = { dash = 'fire', jump = 'fire', backward_dash = 'fire' }
  p.resources.water = 17
  assert(P.valid(p))
  local migrated, removed = P.migrate(p)
  eq(migrated.version, 2); eq(#removed, 2); assert(P.valid(migrated))
  eq(migrated.head.dash, 'fire'); eq(migrated.head.jump, nil); eq(migrated.head.backward_dash, nil)
  eq(migrated.selected.fire, 1); eq(migrated.resources.water, 17)
  eq(migrated.trees[2].stage, 'adult'); eq(p.head.jump, 'fire')
  local again, cleared = P.migrate(migrated); eq(#cleared, 0); assert(P.valid(again))
end)

test('loading an old save retries allocation migration without accepting an over-budget run', function()
  local p = grown_profile(); p.version = 1; p.head = { dash = 'fire' }
  local old_sys, fail, saved = sys, true, nil
  sys = { get_save_file = function() return 'test-profile' end,
    load = function() return C.copy(p) end,
    save = function(_, value) if fail then return false end; saved = C.copy(value); return true end }
  local session = assert(loadfile('main/scripts/modules/session.lua'))()
  assert(not session.load()); assert(session.blocked()); eq(session.get().version, 1)
  assert(not session.begin()); assert(session.notice)
  fail = false; assert(session.retry()); assert(not session.blocked())
  eq(session.get().head.dash, nil); eq(saved.version, 2); eq(saved.selected.fire, 1)
  assert(session.begin()); eq(session.run.head.dash, nil)
  -- Lazy loading must not overwrite a pending migration with a run transaction.
  p.head, fail = {}, true
  local lazy = assert(loadfile('main/scripts/modules/session.lua'))()
  assert(not lazy.begin()); assert(lazy.blocked()); eq(lazy.run, nil)
  fail = false; assert(lazy.retry()); eq(lazy.get().version, 2); eq(lazy.run, nil)
  sys = old_sys
end)

test('save failure leaves profile unchanged and retry commits exactly once', function()
  local saved, fail = nil, true
  S.configure(P.new(), function(p) if fail then return false end; saved = C.copy(p); return true end)
  assert(not S.change('plant', 1, 'fire')); eq(S.get().resources.fire, 1); assert(S.blocked())
  assert(not S.change('plant', 2, 'fire'))
  fail = false; assert(S.retry()); eq(S.get().resources.fire, 0); assert(saved.trees[1])
  assert(S.change('care', 1)); assert(S.begin())
  S.run.reward_element = "water"; S.run.kills = S.run.level.target; fail = true; assert(not S.finish(true)); eq(S.get().resources.water, 0)
  assert(not S.finish(true)); fail = false; assert(S.retry()); eq(S.get().resources.water, 1)
  eq(S.get().successful_runs, 1)
  S.configure(saved, function() return true end); eq(S.run, nil) -- no resumable backpack
end)

test('kills count once, award no loot and contact grants no objective progress', function()
  local w = world('fire')
  for i = 1, 6 do local e = enemy(w, i); Combat.kill(w, e, true); Combat.kill(w, e, true) end
  eq(w.run.kills, 6); eq(w.drops, nil)
  Combat.kill(w, enemy(w, 7), false); eq(w.run.kills, 6)
  for _, resource in ipairs(C.resources) do eq(w.run.bag[resource], 0) end
end)

test('quota and boss gate settlement; rewards scale by level, never by surplus kills', function()
  local p = grown_profile(); local r = run(p)
  assert(not P.finish(p, r, true)); eq(p.successful_runs, 0)
  r.reward_element = 'water'; r.kills = r.level.target + 1000
  assert(P.finish(p, r, true)); eq(p.resources.water, 1)
  eq(p.resources.compost, 1); eq(p.resources.minerals, 1); eq(p.expedition_level, 2)
  assert(not P.finish(p, r, true)); eq(p.resources.water, 1)
  p.expedition_level = 5; r = run(p); r.kills = r.level.target
  assert(r.level.boss); assert(not P.finish(p, r, true))
  r.boss_defeated = true; assert(P.finish(p, r, true)); eq(p.expedition_level, 6)
  r = run(p); r.reward_element = 'earth'; eq(r.level.reward_count, 2)
  assert(victory(p, r)); eq(p.resources.earth, 2)
  local level = p.expedition_level; r = run(p)
  assert(P.finish(p, r, false)); eq(p.expedition_level, level)
  for _, amount in pairs(p.result.bag) do eq(amount, 0) end
end)

test('reward rotation follows levels across wins, deaths, abandoned runs and restarts', function()
  local p = grown_profile()
  local expected = { 'fire', 'water', 'wind', 'earth', 'fire', 'water', 'wind', 'earth' }
  local old_random = math.random
  math.random = function() error('Level rewards must not use random') end
  for level, element in ipairs(expected) do
    eq(Expedition.reward_element(p.expedition_level), element)
    local abandoned = run(p); eq(abandoned.reward_element, element)
    p = C.copy(p) -- restart after quitting: no result or reward
    local failed = run(p); eq(failed.reward_element, element)
    assert(P.finish(p, failed, false)); eq(p.expedition_level, level)
    local r = run(p); eq(r.reward_element, element)
    local before = C.copy(p.resources)
    assert(victory(p, r)); eq(p.expedition_level, level + 1)
    for _, key in ipairs(C.elements) do
      eq(p.resources[key] - before[key], key == element and r.level.reward_count or 0)
    end
    assert(not P.finish(p, r, true)); eq(p.expedition_level, level + 1)
    p = C.copy(p); assert(P.valid(p))
  end
  math.random = old_random
end)

test('reward rotation is committed once with the result and resumes from existing level progress', function()
  local p = grown_profile(); p.expedition_level = 4
  local fail, saved = false, nil
  S.configure(p, function(value) if fail then return false end; saved = C.copy(value); return true end)
  assert(S.begin()); eq(S.run.reward_element, 'earth')
  S.run.kills = S.run.level.target; fail = true
  assert(not S.finish(true)); eq(S.get().expedition_level, 4); eq(S.get().resources.earth, 0)
  assert(not S.begin()); assert(not S.finish(true))
  fail = false; assert(S.retry()); eq(S.get().resources.earth, 1); eq(saved.expedition_level, 5)
  S.configure(saved, function() return true end)
  assert(S.begin()); eq(S.run.reward_element, 'fire'); assert(S.run.level.boss)
  local legacy = grown_profile(); legacy.expedition_level = nil
  eq(run(legacy).reward_element, 'fire')
end)

test('legacy saves keep all inventory and trees and start new level progression at 1', function()
  local p = grown_profile(); p.expedition_level = nil; p.resources.water = 80
  p.successful_runs = 27
  assert(P.valid(p)); eq(run(p).level.number, 1); eq(p.resources.water, 80)
  local r = run(p); assert(victory(p, r)); eq(p.expedition_level, 2); eq(p.trees[1].stage, 'adult')
end)

test('director replaces contact deaths and spawns only one guardian after the quota', function()
  local w = Combat.new(run(grown_profile()))
  eq(Expedition.next_spawn(w), 'enemy')
  for i = 1, C.expedition.max_alive do enemy(w, i) end
  eq(Expedition.next_spawn(w), nil)
  Combat.kill(w, w.enemies[1], false); eq(Expedition.next_spawn(w), 'enemy')
  w.run.kills = w.run.level.target; eq(Expedition.next_spawn(w), nil)
  w.run.level = Expedition.level(5); w.run.kills = w.run.level.target
  eq(Expedition.next_spawn(w), 'boss'); w.boss_spawned = true; eq(Expedition.next_spawn(w), nil)
  local boss = enemy(w, 'boss', w.head.x, w.head.y, 200); boss.boss = true
  Combat.update(w, 0.01); assert(not boss.dead); eq(w.head.health, 90)
  Combat.update(w, 0.01); eq(w.head.health, 90)
  Combat.kill(w, boss, true); assert(Expedition.complete(w.run))
end)

test('garden interactions require walking into reach; panels freeze movement and trunks block it', function()
  local state, p = Garden.new(), grown_profile()
  local nearby = Garden.near(state); eq(nearby.slot, 1)
  assert(not Garden.can_use(state, { kind = 'plot', slot = 16 }))
  Garden.interact(state); eq(state.context.slot, 1)
  local y = state.y; Garden.move(state, 0, 1, 1, p); eq(state.y, y)
  Garden.close(state)
  for i = 1, 30 do Garden.move(state, 0, 1, 0.02, p) end
  assert(state.y <= Garden.plot(1).y - 24)
  state.x, state.y = Garden.gate.x, Garden.gate.y
  Garden.interact(state); eq(state.context.kind, 'gate')
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

test('ice stream hits forward, follows movement and aim, and ends after its duration', function()
  local w, f = world('water')
  local front = enemy(w, 'front', 300, 0)
  local behind = enemy(w, 'behind', 150, 0)
  local side = enemy(w, 'side', 300, 90)
  local far = enemy(w, 'far', 501, 0)
  assert(Combat.cast(w, f, 1, 0)); advance(w, 0.02)
  near(front.health, 190); assert(Combat.has(w, front, 'frozen'))
  near(behind.health, 200); near(side.health, 200); near(far.health, 200)
  advance(w, 0.2); near(front.health, 190) -- one direct hit per cast
  f.x, f.y = 400, 100
  Combat.aim(f, 0, 1)
  local above = enemy(w, 'above', 400, 250)
  local old_direction = enemy(w, 'right', 550, 100)
  advance(w, 0.02); near(above.health, 190); near(old_direction.health, 200)
  near(w.fields[1].x, 400); near(w.fields[1].y, 100); near(w.fields[1].dy, 1)
  advance(w, 3); eq(#w.fields, 0)
  local late = enemy(w, 'late', 400, 200); advance(w, 0.02); near(late.health, 200)
end)

test('water variants: thaw burst, shield and additional frost bolt', function()
  local w, f = world('water', 'fire'); local e = enemy(w, 1)
  assert(Combat.cast(w, f, 1, 0)); advance(w, 0.02); near(e.health, 190)
  advance(w, 2.1); near(e.health, 180)
  w, f = world('water', 'earth'); Combat.cast(w, f, 1, 0); eq(w.head.shield, 20)
  w, f = world('water', 'wind'); e = enemy(w, 1, 550)
  Combat.cast(w, f, 1, 0); advance(w, 0.65); near(e.health, 190); assert(Combat.has(w, e, 'frozen'))
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
