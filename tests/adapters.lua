-- Boundary checks only: native layout, physics and rendering still need Defold.
package.path = './?.lua;' .. package.path
-- Defold's LuaJIT provides atan2; desktop Lua 5.3+ folds it into atan(y, x).
math.atan2 = math.atan2 or math.atan
local C = require('main.scripts.modules.catalog')
local P = require('main.scripts.modules.profile')
local S = require('main.scripts.modules.session')
local Garden = require('main.scripts.modules.garden')
local posted, nodes, objects, next_object = {}, {}, {}, 0
hash = function(s) return s end
vmath = {
  vector3 = function(x, y, z) return { x = x or 0, y = y or 0, z = z or 0 } end,
  vector4 = function(x, y, z, w) return { x = x, y = y, z = z, w = w } end,
  quat_rotation_z = function(angle) return { angle = angle } end
}
local function node(pos, size, text)
  local n = { pos = pos, size = size, text = text, children = {} }
  nodes[#nodes + 1] = n
  return n
end
gui = { PIVOT_W = 1, PIVOT_CENTER = 2,
  new_box_node = function(pos, size) return node(pos, size) end,
  new_text_node = function(pos, text) return node(pos, {}, text) end,
  get_width = function() return 960 end, get_height = function() return 640 end,
  set_parent = function(n, p) n.parent = p; p.children[#p.children + 1] = n end,
  set_text = function(n, text) assert(not n.deleted); n.text = text end,
  pick_node = function() return false end
}
for _, property in ipairs({ 'scale', 'position', 'color', 'font', 'pivot', 'size', 'line_break' }) do
  gui['set_' .. property] = function(n, value) assert(not n.deleted); n[property] = value end
end
function gui.delete_node(n)
  n.deleted = true
  for _, child in ipairs(n.children) do gui.delete_node(child) end
end
msg = { post = function(url, message, data) posted[#posted + 1] = { url = url, message = message, data = data } end,
  url = function(socket, path, fragment) return { socket = socket, path = path, fragment = fragment } end }
package.preload['druid.druid'] = function()
  return { new = function()
    return { buttons = {}, new_button = function(self, n, callback)
      self.buttons[#self.buttons + 1] = { node = n, callback = callback }
    end, final = function() end, update = function() end,
      on_input = function() end, on_message = function() end }
  end }
end
local function script(path)
  local env = setmetatable({}, { __index = _G })
  if setfenv then local fn = assert(loadfile(path)); setfenv(fn, env); fn()
  else assert(loadfile(path, 't', env))() end
  return env
end
local function button(self, pattern)
  for _, b in ipairs(self.druid.buttons) do
    for _, child in ipairs(b.node.children) do
      if child.text and child.text:find(pattern, 1, true) then return b.callback end
    end
  end
  error('Missing enabled button: ' .. pattern)
end
local function click(env, self, pattern)
  button(self, pattern)()
  env.update(self, 0.016)
end
local count = 0
local function test(name, fn)
  local ok, err = pcall(fn); if not ok then error(name .. ': ' .. tostring(err), 0) end
  count = count + 1; print('ok ' .. count .. ' - ' .. name)
end

local function interact(env, self, slot)
  local state = Garden.state
  local pos = slot and Garden.plot(slot) or Garden.gate
  state.x, state.y = pos.x, pos.y - 60
  Garden.close(state); Garden.interact(state); env.update(self, 0.016)
end
local function complete()
  S.run.kills, S.run.boss_defeated = S.run.level.target, true
  return S.finish(true)
end

test('physical plots, gate preparation, expedition and result share the saved profile', function()
  local saved
  S.configure(P.new(), function(p) saved = C.copy(p); return true end)
  Garden.new()
  local garden, self = script('main/gui/garden.gui_script'), {}
  garden.init(self); interact(garden, self, 1)
  click(garden, self, 'Fire > Maple'); assert(S.get().trees[1].stage == 'seedling')
  assert(not Garden.state.context, 'Planting returns to the world')
  interact(garden, self, 1)
  click(garden, self, 'CARE:'); assert(S.get().tutorial == 'done')
  interact(garden, self)
  click(garden, self, 'SPACE / Dash'); assert(S.get().head.dash == nil)
  assert(Garden.state.notice:find('No free grown trees'))
  click(garden, self, 'START EXPEDITION'); assert(S.run.active)
  assert(posted[#posted].data.level == 1)
  S.run.reward_element = 'water'
  assert(complete()); garden.final(self)
  local result, screen = script('main/gui/game_over.gui_script'), {}
  result.init(screen); click(result, screen, 'RETURN TO GARDEN')
  assert(posted[#posted].data.level == 'garden'); result.final(screen)
  S.configure(saved, function(p) saved = C.copy(p); return true end)
  Garden.new(); self = {}; garden.init(self)
  interact(garden, self, 2); click(garden, self, 'Water > Willow')
  interact(garden, self, 2); click(garden, self, 'CARE:')
  assert(S.get().trees[2].stage == 'growing')
  interact(garden, self); click(garden, self, 'START EXPEDITION'); assert(complete()); garden.final(self)
  Garden.new(); self = {}; garden.init(self)
  interact(garden, self, 2); click(garden, self, 'USE IN TAIL')
  assert(#P.loadout(S.get()) == 2); assert(P.valid(saved)); garden.final(self)
end)

test('preparation counts head and tail together and skips exhausted elements when cycling', function()
  local p = P.new(); assert(P.plant(p, 1, 'fire')); assert(P.care(p, 1))
  p.trees[2] = { element = 'fire', stage = 'adult' }
  p.trees[3] = { element = 'water', stage = 'adult' }
  S.configure(p, function() return true end); Garden.new()
  local garden, self = script('main/gui/garden.gui_script'), {}
  garden.init(self); interact(garden, self)
  local shown = false
  for _, node in ipairs(self.root.children) do
    if node.text and node.text:find('Reward: 1 Fire + 1 Compost + 1 Minerals', 1, true) then shown = true end
  end
  assert(shown, 'Preparation must show the actual next reward')
  click(garden, self, 'SPACE / Dash'); assert(S.get().head.dash == 'fire')
  click(garden, self, 'Q / Jump'); assert(S.get().head.jump == 'water')
  click(garden, self, 'E / Backstep'); assert(S.get().head.backward_dash == nil)
  interact(garden, self, 3)
  assert(not pcall(button, self, 'USE IN TAIL'), 'Water tree is already assigned to the head')
  interact(garden, self); click(garden, self, 'Q / Jump'); assert(S.get().head.jump == nil)
  interact(garden, self, 3); click(garden, self, 'USE IN TAIL')
  assert(#P.loadout(S.get()) == 2)
  local total, used, free = P.allocation(S.get(), 'fire'); assert(total == 2 and used == 2 and free == 0)
  garden.final(self)
end)

test('garden and result expose save retry without spending twice or allowing a new run', function()
  local fail = true
  S.configure(P.new(), function() return not fail end)
  Garden.new()
  local garden, self = script('main/gui/garden.gui_script'), {}
  garden.init(self); interact(garden, self, 1); click(garden, self, 'Fire > Maple')
  assert(S.blocked()); assert(S.get().resources.fire == 1)
  fail = false; click(garden, self, 'RETRY SAVE'); assert(S.get().resources.fire == 0)
  click(garden, self, 'CARE:'); interact(garden, self); click(garden, self, 'START EXPEDITION')
  fail = true; assert(not complete()); garden.final(self)
  local result, screen = script('main/gui/game_over.gui_script'), {}
  result.init(screen); assert(S.blocked())
  fail = false; click(result, screen, 'RETRY SAVE'); assert(not S.blocked())
  click(result, screen, 'RETURN TO GARDEN'); assert(S.get().successful_runs == 1)
  assert(S.get().expedition_level == 2)
  result.final(screen)
end)

test('scene loader serializes unload/load and ignores repeated requests', function()
  local env, self = script('main/scripts/loader.script'), {}
  local seed_calls, original = 0, math.randomseed
  math.randomseed = function(seed) assert(type(seed) == 'number'); seed_calls = seed_calls + 1 end
  env.init(self)
  math.randomseed = original; assert(seed_calls == 1)
  env.on_message(self, 'load_level', { level = 'garden' })
  assert(posted[#posted].message == 'load')
  local n = #posted; env.on_message(self, 'load_level', { level = 'garden' }); assert(#posted == n)
  env.on_message(self, 'proxy_loaded', {}, '/loader#garden'); assert(self.current == 'garden')
  env.on_message(self, 'load_level', { level = 'menu' }); assert(posted[#posted].message == 'unload')
  env.on_message(self, 'proxy_unloaded', {}, '/loader#garden')
  assert(posted[#posted].url == '/loader#menu' and posted[#posted].message == 'load')
  env.on_message(self, 'proxy_loaded', {}, '/loader#menu'); assert(self.current == 'menu')
end)

-- Lightweight bridge stubs verify that native-only effects are created at the
-- controller factory, enemies are deleted once, and the HUD can consume models.
go = { property = function() end, get_id = function() return 'enemy' end,
  get_position = function() return vmath.vector3(250, 0, 0) end,
  set_position = function(pos, id) objects[id] = objects[id] or {}; objects[id].pos = pos end,
  set_scale = function(scale, id) assert(objects[id]); objects[id].scale = scale end,
  set_rotation = function(rotation, id) assert(objects[id]); objects[id].rotation = rotation end,
  set = function(url, key, value)
    assert(key == 'tint' and value.w ~= nil)
    if type(url) == 'table' then
      assert(url.fragment == 'sprite' and objects[url.path])
      objects[url.path].tint = value
    end
  end,
  delete = function(id) assert(objects[id]); objects[id] = nil end }
factory = { create = function(url, pos)
  assert(url == '/totem#visuals' or url == '/totem#fireball_visuals' or
    url == '/totem#ice_barrage_visuals' or url == '/totem#thunderclap_visuals' or url == '/totem#windwalker_visuals')
  next_object = next_object + 1; objects[next_object] = { pos = pos, factory = url }; return next_object
end }
-- Only APIs actually exported by Defold. In particular, there is no sprite.set_constant.
sprite = { set_hflip = function() end }
label = { set_text = function(url, text) assert(url.fragment == 'name') end }
physics = { raycast = function() return nil end }

test('combat bridge updates a compact HUD and freezes after automatic level completion', function()
  local p = P.new(); assert(P.plant(p, 1, 'fire')); assert(P.care(p, 1))
  S.configure(p, function() return true end); assert(S.begin())
  local Runtime = require('main.scripts.modules.runtime')
  local Combat = require('main.scripts.modules.combat')
  local w = Runtime.get(); w.head.x, w.head.y = 100, 100
  w.run.kills = w.run.level.target - 1
  local enemy = Combat.add_enemy(w, 'enemy', 250, 100, 20, 0, 10)
  enemy.object = 'enemy'; objects.enemy = {}
  local follower = { x = 210, y = 100, element = 'fire' }; w.followers.f = follower
  Combat.cast(w, follower, 1, 0); Runtime.tick(0.1)
  assert(not objects.enemy and w.run.kills == w.run.level.target)
  assert(not w.run.active and S.result.success and S.get().expedition_level == 2)
  local hud, self = script('main/gui/player_gui.gui_script'), {}
  hud.init(self); hud.update(self, 0.016); assert(self.health.text:find('HP 100')); assert(self.objective.text:find('12/12'))
  Runtime.finish(false); assert(posted[#posted].data.level == 'game_over')
  local elapsed = w.run.elapsed; Runtime.tick(1); assert(w.run.elapsed == elapsed)
end)

test('live enemies keep moving and shots render while the combat controller updates', function()
  local p = P.new(); assert(P.plant(p, 1, 'fire')); assert(P.care(p, 1))
  S.configure(p, function() return true end); assert(S.begin())
  local Runtime = require('main.scripts.modules.runtime')
  local Combat = require('main.scripts.modules.combat')
  local w = Runtime.get(); w.head.x, w.head.y = 500, 500; w.next_spawn = 100
  for i = 1, 3 do
    local key = 'moving_enemy_' .. i
    local enemy = Combat.add_enemy(w, key, 700, 650 + i * 80, 100, 40, 10)
    enemy.object = key; objects[key] = {}
  end
  local follower = { x = 500, y = 450, element = 'fire' }
  w.followers.f = follower
  package.preload['orthographic.camera'] = function()
    return { screen_to_world = function(_, pos) return pos end, follow = function() end }
  end
  local original_rotation = go.set_rotation
  local rotation = vmath.quat_rotation_z(0)
  go.get_world_position = function() return vmath.vector3(follower.x, follower.y, 0) end
  go.set_rotation = function(value, id)
    if id then original_rotation(value, id) else rotation = value end
  end
  go.get_rotation = function() return rotation end
  vmath.rotate = function(q, v)
    return vmath.vector3(v.x * math.cos(q.angle) - v.y * math.sin(q.angle),
      v.x * math.sin(q.angle) + v.y * math.cos(q.angle), v.z)
  end
  local env = script('main/scripts/follower.script')
  local self = { model = follower }
  env.on_input(self, hash('touch'), { pressed = true, screen_x = 700, screen_y = 450 })
  assert(#w.projectiles == 1, 'A left click must launch a fire projectile')
  env.on_input(self, hash('touch'), { released = true })
  env.on_input(self, hash('touch'), { pressed = true })
  assert(#w.projectiles == 1, 'Release and clicks during cooldown must not launch extra shots')
  local before = next_object
  Runtime.tick(1 / 60)
  assert(next_object > before, 'The live projectile must have a visual')
  local projectile_object = next_object
  local x = objects[projectile_object].pos.x
  assert(objects[projectile_object].factory == '/totem#fireball_visuals')
  assert(math.abs(objects[projectile_object].rotation.angle - math.pi) < 0.001)
  local positions = {}
  for key, enemy in pairs(w.enemies) do
    assert(objects[key].pos.x < 700 and objects[key].tint)
    positions[key] = objects[key].pos.x
  end
  for i = 1, 6 do Runtime.tick(1 / 60) end
  assert(objects[projectile_object].pos.x > x)
  for key in pairs(w.enemies) do assert(objects[key].pos.x < positions[key]) end
  go.set_rotation = original_rotation
end)
test('ice, earth and wind use their original spell visuals and expire with combat models', function()
  local Runtime = require('main.scripts.modules.runtime')
  local Combat = require('main.scripts.modules.combat')
  for _, element in ipairs({ 'water', 'earth', 'wind' }) do
    local p = P.new(); assert(P.plant(p, 1, 'fire')); assert(P.care(p, 1))
    S.configure(p, function() return true end); assert(S.begin())
    local w = Runtime.get(); w.head.x, w.head.y = 500, 500; w.next_spawn = 100
    local f = { x = 500, y = 450, element = element }; w.followers.f = f
    assert(Combat.cast(w, f, 1, 0)); Runtime.tick(0.01)
    local object, count = next_object, next_object
    local names = { water = 'ice_barrage', earth = 'thunderclap', wind = 'windwalker' }
    assert(objects[object].factory == '/totem#' .. names[element] .. '_visuals')
    if element == 'water' then
      f.x, f.y = 550, 480; Combat.aim(f, 0, 1)
      Runtime.tick(0.01)
      assert(objects[object].pos.x == 550 and objects[object].pos.y == 480)
      assert(math.abs(objects[object].rotation.angle - math.pi / 2) < 0.001)
      assert(math.abs(objects[object].scale - C.spells.water.length / 299) < 0.001)
    elseif element == 'earth' then
      assert(objects[object].scale == 2 * C.spells.earth.radius / 96)
    else
      assert(math.abs(objects[object].rotation.angle + math.pi / 2) < 0.001)
    end
    Runtime.tick(0.1); assert(next_object == count, 'Animation must not respawn every frame')
    Runtime.tick(C.spells[element].duration)
    assert(not objects[object], 'Expired model must remove its animation')
  end
end)

test('runtime spawns level enemies and a guardian, then settles exactly once', function()
  local p = P.new(); assert(P.plant(p, 1, 'fire')); assert(P.care(p, 1)); p.expedition_level = 5
  S.configure(p, function() return true end); assert(S.begin()); S.run.reward_element = 'water'
  local Runtime = require('main.scripts.modules.runtime')
  local Combat = require('main.scripts.modules.combat')
  local w = Runtime.get(); w.head.x, w.head.y = 500, 500
  local original = factory.create
  local last
  factory.create = function(url, pos, rotation, properties)
    if url == '/totem#enemies' or url == '/totem#boss' then
      assert(type(properties.boss) == 'boolean' and properties.health > 0 and properties.speed > 0)
      next_object = next_object + 1; objects[next_object] = { pos = pos }
      last = Combat.add_enemy(w, next_object, pos.x, pos.y, properties.health, properties.speed, properties.damage)
      last.object, last.boss = next_object, properties.boss
      return next_object
    end
    return original(url, pos)
  end
  Runtime.tick(0.01); assert(last and not last.boss)
  w.run.kills = w.run.level.target - 1; Combat.kill(w, last, true)
  Runtime.tick(2); assert(last.boss and w.run.active and w.boss_spawned)
  local guardian = last; Runtime.tick(2); assert(last == guardian)
  Combat.kill(w, guardian, true); Runtime.tick(0.01)
  assert(not S.run.active and S.result.success and S.get().resources.water == 1)
  assert(S.get().expedition_level == 6)
  Runtime.tick(10); Runtime.finish(true); assert(S.get().resources.water == 1)
  factory.create = original
end)

test('garden player lifecycle creates world plots, plants beside the druid and walks to the gate', function()
  S.configure(P.new(), function() return true end)
  local old_go, old_factory, old_sprite = go, factory, sprite
  local scene, serial = { druid = { pos = vmath.vector3(320, 214, 0) } }, 0
  go = {
    get_id = function() return 'druid' end,
    get_position = function() return scene.druid.pos end,
    set_position = function(value, id) scene[id or 'druid'].pos = value end,
    set_scale = function(value, id) assert(scene[id]); scene[id].scale = value end,
    set = function(url, key, value)
      assert(key == 'scale' or key == 'tint')
      local object = type(url) == 'table' and scene[url.path] or scene.druid
      assert(object); object[key] = value
    end
  }
  factory = { create = function(url, pos)
    assert(url == '#plots' or url == '#effects')
    serial = serial + 1; scene[serial] = { pos = pos }; return serial
  end }
  sprite = { set_hflip = function() end, play_flipbook = function(url, animation)
    local object = type(url) == 'table' and scene[url.path] or scene.druid
    assert(object); object.animation = animation
  end }
  local player, actor = script('main/scripts/garden_player.script'), {}
  player.init(actor); player.update(actor, 0.016)
  assert(#actor.plots == 16 and serial == 17)
  local gui_env, screen = script('main/gui/garden.gui_script'), {}
  gui_env.init(screen)
  player.on_input(actor, hash('extract'), { pressed = true }); gui_env.update(screen, 0.016)
  click(gui_env, screen, 'Fire > Maple'); player.update(actor, 0.016)
  assert(scene[actor.plots[1]].animation == 'tree_4' and actor.action == 1)
  player.on_input(actor, hash('extract'), { pressed = true }); gui_env.update(screen, 0.016)
  click(gui_env, screen, 'CARE:'); player.update(actor, 0.016)
  assert(S.get().trees[1].stage == 'adult' and actor.action == 2)
  player.on_input(actor, hash('right'), { pressed = true })
  for i = 1, 177 do player.update(actor, 0.01) end
  player.on_input(actor, hash('right'), { released = true })
  player.on_input(actor, hash('extract'), { pressed = true }); gui_env.update(screen, 0.016)
  assert(Garden.state.context.kind == 'gate')
  click(gui_env, screen, 'START EXPEDITION'); assert(S.run.active)
  gui_env.final(screen); player.final(actor); assert(Garden.state == nil)
  go, factory, sprite = old_go, old_factory, old_sprite
end)
print('PASS: ' .. count .. ' adapter checks (not an engine playtest)')
