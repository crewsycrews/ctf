local C = require("main.scripts.modules.catalog")
local M = {}

function M.new()
  local p = { version = 1, resources = C.resource_bag(), trees = {}, selected = {},
    head = {}, tutorial = "plant", successful_runs = 0, next_run = 1, last_result = 0 }
  p.resources.fire, p.resources.compost, p.resources.minerals = 1, 1, 1
  return p
end

function M.adult(tree)
  return tree and (tree.stage == "adult" or tree.stage == "upgrading")
end

function M.available(p, element)
  for _, tree in pairs(p.trees) do
    if M.adult(tree) and tree.element == element then return true end
  end
  return false
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
  local tree = p.trees[slot]
  if not M.adult(tree) then return false, "Only grown trees can join the tail" end
  if p.selected[tree.element] == slot then p.selected[tree.element] = nil
  else p.selected[tree.element] = slot end
  return true
end

function M.infuse(p, action, element)
  local valid = false
  for _, name in ipairs(C.actions) do if name == action then valid = true end end
  if not valid then return false, "Unknown movement" end
  if element and not M.available(p, element) then return false, "Grow this element first" end
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
  local tail = M.loadout(p)
  if #tail == 0 then return false, "Select at least one grown tree" end
  local run = { id = p.next_run, tail = tail, head = C.copy(p.head),
    bag = C.resource_bag(), elapsed = 0, kills = 0, active = true }
  p.next_run = p.next_run + 1
  return true, run
end

function M.finish(p, run, success)
  if run.id <= p.last_result then return false, "This expedition is already settled" end
  local result = { id = run.id, success = success, bag = C.copy(run.bag),
    kills = run.kills, elapsed = run.elapsed, grown = {} }
  if success then
    for key, amount in pairs(run.bag) do p.resources[key] = p.resources[key] + amount end
    p.successful_runs = p.successful_runs + 1
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
  if type(p) ~= "table" or p.version ~= 1 then return false end
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
  return true
end

return M
