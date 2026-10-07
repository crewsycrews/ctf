local C = require("main.scripts.modules.catalog")
local Expedition = require("main.scripts.modules.expedition")
local M = {}

function M.new()
  local p = { version = 2, resources = C.resource_bag(), trees = {}, selected = {},
    head = {}, tutorial = "plant", successful_runs = 0, expedition_level = 1, next_run = 1, last_result = 0 }
  p.resources.fire, p.resources.compost, p.resources.minerals = 1, 1, 1
  return p
end

function M.adult(tree)
  return tree and (tree.stage == "adult" or tree.stage == "upgrading")
end

function M.tree_count(p, element)
  local count = 0
  for _, tree in pairs(p.trees) do
    if M.adult(tree) and tree.element == element then count = count + 1 end
  end
  return count
end

function M.available(p, element)
  return M.tree_count(p, element) > 0
end

function M.allocation(p, element, excluding_action)
  local total, used = M.tree_count(p, element), p.selected[element] and 1 or 0
  for action, assigned in pairs(p.head) do
    if action ~= excluding_action and assigned == element then used = used + 1 end
  end
  return total, used, total - used
end

function M.allocation_valid(p)
  for _, element in ipairs(C.elements) do
    local _, _, free = M.allocation(p, element)
    if free < 0 then return false, "Too many " .. C.names[element] .. " assignments. Grow another tree or release an assignment." end
  end
  return true
end

function M.can_infuse(p, action, element)
  local valid = false
  for _, name in ipairs(C.actions) do if name == action then valid = true end end
  if not valid then return false, "Unknown movement" end
  if not element then return true end
  if not C.base[element] then return false, "Unknown element" end
  local total, _, free = M.allocation(p, element, action)
  if total == 0 then return false, "Grow this element first" end
  if free < 1 then return false, "No free " .. C.names[element] .. " tree. Release a head or tail assignment." end
  return true
end

function M.can_select(p, slot)
  local tree = p.trees[slot]
  if not M.adult(tree) then return false, "Only grown trees can join the tail" end
  -- Removing or replacing a follower of the same family costs no extra tree.
  if p.selected[tree.element] then return true end
  local _, _, free = M.allocation(p, tree.element)
  if free < 1 then return false, "No free " .. C.names[tree.element] .. " tree. Release a head assignment." end
  return true
end

-- Keep the old tail and the earliest head assignments that fit the new budget.
function M.migrate(p)
  local result, removed = C.copy(p), {}
  if result.version == 1 then
    result.head = {}
    for _, action in ipairs(C.actions) do
      local element = p.head[action]
      if element then
        if M.can_infuse(result, action, element) then result.head[action] = element
        else removed[#removed + 1] = action end
      end
    end
    result.version = 2
  end
  return result, removed
end

local function pay(p, cost)
  for key, amount in pairs(cost) do
    if (p.resources[key] or 0) < amount then return false, "Not enough " .. C.names[key] end
  end
  for key, amount in pairs(cost) do p.resources[key] = p.resources[key] - amount end
  return true
end

function M.plant(p, slot, element)
  if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > C.balance.plots then
    return false, "Invalid plot"
  end
  if not C.base[element] or p.trees[slot] then return false, "Choose an empty plot" end
  if p.tutorial ~= "done" and (p.tutorial ~= "plant" or element ~= "fire") then
    return false, "Tutorial: plant Fire to grow your first Maple"
  end
  local ok, err = pay(p, { [element] = 1 })
  if not ok then return false, err end
  p.trees[slot] = { element = element, stage = "seedling" }
  if p.tutorial == "plant" then p.tutorial, p.tutorial_slot = "care", slot end
  return true
end

function M.care(p, slot)
  local tree = p.trees[slot]
  if not tree or tree.stage ~= "seedling" then return false, "Choose a seedling" end
  local ok, err = pay(p, C.balance.growth_cost)
  if not ok then return false, err end
  if p.tutorial == "care" and p.tutorial_slot == slot then
    tree.stage, p.tutorial, p.tutorial_slot = "adult", "done", nil
    p.selected.fire = slot
  else
    tree.stage, tree.remaining = "growing", C.balance.growth_runs
  end
  return true
end

function M.upgrade(p, slot, element)
  local tree = p.trees[slot]
  if not tree or tree.stage ~= "adult" or tree.secondary then
    return false, "Only an adult base tree can be upgraded"
  end
  if not C.recipes[tree.element][element] then return false, "Choose a different element" end
  local cost = C.copy(C.balance.growth_cost)
  cost[element] = 1
  local ok, err = pay(p, cost)
  if not ok then return false, err end
  tree.stage, tree.pending, tree.remaining = "upgrading", element, C.balance.growth_runs
  return true
end

function M.select(p, slot)
  local ok, err = M.can_select(p, slot)
  if not ok then return false, err end
  local tree = p.trees[slot]
  if p.selected[tree.element] == slot then p.selected[tree.element] = nil
  else p.selected[tree.element] = slot end
  return true
end

function M.infuse(p, action, element)
  local ok, err = M.can_infuse(p, action, element)
  if not ok then return false, err end
  p.head[action] = element
  return true
end

function M.loadout(p)
  local result = {}
  for _, element in ipairs(C.elements) do
    local tree = p.trees[p.selected[element]]
    if M.adult(tree) and tree.element == element then result[#result + 1] = C.copy(tree) end
  end
  return result
end

function M.begin_run(p)
  if p.tutorial ~= "done" then return false, "Finish planting your first Maple" end
  local ok, err = M.allocation_valid(p)
  if not ok then return false, err end
  local tail = M.loadout(p)
  if #tail == 0 then return false, "Select at least one grown tree" end
  local run = { id = p.next_run, tail = tail, head = C.copy(p.head),
    bag = C.resource_bag(), elapsed = 0, kills = 0, active = true,
    level = Expedition.level(p.expedition_level or 1),
    reward_element = Expedition.reward_element(p.expedition_level) }
  p.next_run = p.next_run + 1
  return true, run
end

function M.finish(p, run, success)
  if run.id <= p.last_result then return false, "This expedition is already settled" end
  if success and not Expedition.complete(run) then return false, "Finish the level objective first" end
  local reward = success and Expedition.reward(run) or C.resource_bag()
  local result = { id = run.id, success = success, bag = reward, level = run.level.number,
    kills = run.kills, elapsed = run.elapsed, grown = {} }
  if success then
    for key, amount in pairs(reward) do p.resources[key] = p.resources[key] + amount end
    p.successful_runs = p.successful_runs + 1
    p.expedition_level = run.level.number + 1
    for slot = 1, C.balance.plots do
      local tree = p.trees[slot]
      if tree and (tree.stage == "growing" or tree.stage == "upgrading") then
        tree.remaining = tree.remaining - 1
        if tree.remaining <= 0 then
          if tree.pending then tree.secondary, tree.pending = tree.pending, nil end
          tree.stage, tree.remaining = "adult", nil
          result.grown[#result.grown + 1] = C.tree_name(tree)
        end
      end
    end
  end
  p.last_result, p.result = run.id, result
  return true, result
end

function M.valid(p)
  if type(p) ~= "table" or (p.version ~= 1 and p.version ~= 2) then return false end
  if type(p.resources) ~= "table" or type(p.trees) ~= "table" or
      type(p.selected) ~= "table" or type(p.head) ~= "table" then return false end
  for _, key in ipairs(C.resources) do
    local n = p.resources[key]
    if type(n) ~= "number" or n < 0 or n % 1 ~= 0 then return false end
  end
  for slot, tree in pairs(p.trees) do
    if type(slot) ~= "number" or slot < 1 or slot > C.balance.plots or slot % 1 ~= 0 or
        type(tree) ~= "table" or not C.base[tree.element] then return false end
    if tree.stage ~= "seedling" and tree.stage ~= "growing" and tree.stage ~= "adult" and
        tree.stage ~= "upgrading" then return false end
    if tree.secondary and not C.recipes[tree.element][tree.secondary] then return false end
    if tree.stage == "growing" or tree.stage == "upgrading" then
      if tree.remaining ~= C.balance.growth_runs then return false end
    end
    if tree.stage == "upgrading" and not C.recipes[tree.element][tree.pending] then return false end
  end
  for _, key in ipairs({ "next_run", "last_result", "successful_runs" }) do
    if type(p[key]) ~= "number" or p[key] < 0 or p[key] % 1 ~= 0 then return false end
  end
  if p.expedition_level ~= nil and (type(p.expedition_level) ~= "number" or
      p.expedition_level < 1 or p.expedition_level % 1 ~= 0) then return false end
  if p.next_run <= p.last_result then return false end
  if p.tutorial ~= "plant" and p.tutorial ~= "care" and p.tutorial ~= "done" then return false end
  if p.tutorial == "care" and (not p.trees[p.tutorial_slot] or
      p.trees[p.tutorial_slot].stage ~= "seedling") then return false end
  for element, slot in pairs(p.selected) do
    local tree = p.trees[slot]
    if not C.base[element] or not M.adult(tree) or tree.element ~= element then return false end
  end
  for action, element in pairs(p.head) do
    if action ~= "dash" and action ~= "jump" and action ~= "backward_dash" then return false end
    if not M.available(p, element) then return false end
  end
  if p.version == 2 then return M.allocation_valid(p) end
  return true
end

return M
