local C = require("main.scripts.modules.catalog")
local M = { width = 1280, height = 1080, reach = 86, gate = { x = 640, y = 130 } }
local columns = { 320, 500, 780, 960 }
function M.plot(slot)
  return { x = columns[(slot - 1) % 4 + 1], y = 300 + math.floor((slot - 1) / 4) * 180 }
end
local function distance(a, b)
  return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end
function M.new()
  M.state = { x = 320, y = 214, notice = "", revision = 0, action = 0 }
  return M.state
end
function M.near(state)
  if distance(state, M.gate) <= M.reach then return { kind = "gate" } end
  local nearest, best = nil, M.reach
  for slot = 1, C.balance.plots do
    local d = distance(state, M.plot(slot))
    if d <= best then nearest, best = { kind = "plot", slot = slot }, d end
  end
  return nearest
end
function M.can_use(state, context)
  if not state or not context then return false end
  local pos = context.kind == "gate" and M.gate or M.plot(context.slot)
  return distance(state, pos) <= M.reach
end
function M.close(state)
  state.context, state.revision = nil, state.revision + 1
end
function M.interact(state)
  if state.context then M.close(state); return end
  state.context, state.revision = M.near(state), state.revision + 1
end
function M.move(state, dx, dy, dt, profile)
  if state.context then return end
  local length = math.sqrt(dx * dx + dy * dy)
  if length == 0 then return end
  local function open(x, y)
    for slot, tree in pairs(profile.trees) do
      if tree.stage == "adult" or tree.stage == "upgrading" then
        if distance({ x = x, y = y }, M.plot(slot)) < 24 then return false end
      end
    end
    return true
  end
  local x = math.max(100, math.min(M.width - 100, state.x + dx / length * 180 * dt))
  local y = math.max(90, math.min(M.height - 90, state.y + dy / length * 180 * dt))
  if open(x, state.y) then state.x = x end
  if open(state.x, y) then state.y = y end
end
return M
