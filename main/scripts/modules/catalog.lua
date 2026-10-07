local M = {}

M.elements = { "fire", "water", "wind", "earth" }
M.resources = { "fire", "water", "wind", "earth", "compost", "minerals" }
M.actions = { "dash", "jump", "backward_dash" }
M.names = { fire = "Fire", water = "Water", wind = "Air", earth = "Earth",
  compost = "Compost", minerals = "Minerals" }
M.colors = { fire = { 1, 0.35, 0.2 }, water = { 0.3, 0.7, 1 },
  wind = { 0.5, 1, 0.6 }, earth = { 0.8, 0.6, 0.3 },
  compost = { 0.5, 0.35, 0.25 }, minerals = { 0.8, 0.7, 1 } }
M.base = { fire = "Maple", water = "Willow", earth = "Oak", wind = "Poplar" }
M.recipes = {
  water = { fire = "Flame willow", earth = "Wooly willow", wind = "Babylon willow" },
  fire = { water = "Amur maple", earth = "Black maple", wind = "Silver maple" },
  earth = { fire = "Red Oak", water = "Willow oak", wind = "Chinese cork oak" },
  wind = { fire = "Tsavo poplar", water = "Swamp poplar", earth = "Gray Poplar" }
}
M.descriptions = {
  fire = "Fireball: 20 damage. Left mouse.",
  water = "Ice stream toward cursor for 3s. 10 damage, freeze 2s. Wheel down.",
  earth = "Earth strike: 10 damage, slow 3s. Wheel up.",
  wind = "Wind projectile: 25 damage. Right mouse.",
  water_fire = "Thawing enemies explode for 10 damage.",
  water_earth = "Casting grants a 20-point shield for 3s.",
  water_wind = "Also fires a frost bolt: 10 damage, freeze 1s.",
  fire_water = "Hits leave slowing steam for 2s.",
  fire_earth = "Hits push enemies back by 60.",
  fire_wind = "Fireballs pierce up to 3 enemies.",
  earth_fire = "Hits burn for 4 damage/s for 3s.",
  earth_water = "Hits leave slowing mud for 3s.",
  earth_wind = "Hits pull enemies toward the strike.",
  wind_fire = "Projectile leaves a burning trail.",
  wind_water = "First hit heals the head by 10.",
  wind_earth = "Projectile ends with a 10-damage explosion."
}
M.combos = { fire = "Fire head + Water tail: steam burst",
  water = "Water head + Earth tail: mud",
  earth = "Earth head + Air tail: stone burst",
  wind = "Air head + Fire tail: fire fan" }
M.head_help = {
  fire = "Fire: burning ground + smolder mark. Water tail triggers a steam burst.",
  water = "Water: wet mark + slow. Earth tail creates mud.",
  earth = "Earth: 20-point shield + dust. Air tail picks up a stone burst.",
  wind = "Air: faster followers. A Fire shot through the flow becomes a fan."
}
M.finishers = { fire = "water", water = "earth", earth = "wind", wind = "fire" }
M.balance = {
  plots = 16,
  growth_cost = { compost = 1, minerals = 1 }, growth_runs = 1,
  max_health = 100, shield = 20, shield_duration = 3,
  head_radius = 60, head_duration = 3, mark_duration = 3,
  fire_dps = 5, burn_dps = 4, burn_duration = 3, slow = 0.5,
  haste = 1.25, haste_duration = 3, burst_damage = 10, burst_radius = 60,
  mud_radius = 80, mud_duration = 3, steam_duration = 2,
  push = 60, heal = 10, fan_angle = math.pi / 12,
  projectile_speed = 600, projectile_life = 2, projectile_radius = 16,
  fire_pierce = 3, frost_damage = 10, frost_duration = 1,
  trail_duration = 2, trail_spacing = 24, enemy_radius = 18,
  head_cooldown = 3, dash_duration = 0.4, jump_duration = 0.8,
  dash_distance = 216, move_speed = 200, spawn_interval = 5, enemy_limit = 120
}
M.expedition = { reward_rotation = { "fire", "water", "wind", "earth" },
  first_target = 12, target_step = 4, max_target = 60,
  boss_every = 5, reward_every = 5, max_reward = 5, max_alive = 6, spawn_interval = 1.5,
  enemy_health = 20, health_step = 2, enemy_speed = 75, speed_step = 2, max_speed = 115,
  boss_health_multiplier = 10, boss_damage = 20, boss_speed = 65 }
M.spells = {
  fire = { cooldown = 0.3, damage = 20, duration = 2 },
  water = { cooldown = 6, damage = 10, duration = 3, radius = 60, freeze = 2,
    length = 300, near_width = 18, far_width = 70 },
  earth = { cooldown = 5, damage = 10, duration = 0.5, radius = 80, slow = 3 },
  wind = { cooldown = 5, damage = 25, duration = 0.5 }
}

function M.tree_name(tree)
  return tree.secondary and M.recipes[tree.element][tree.secondary] or M.base[tree.element]
end

function M.resource_bag()
  local bag = {}
  for _, key in ipairs(M.resources) do bag[key] = 0 end
  return bag
end

function M.copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = M.copy(item) end
  return result
end

return M
