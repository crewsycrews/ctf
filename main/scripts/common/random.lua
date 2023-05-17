local M = {}

-- Generate random number and put it in the first argument table. If the number is repeated in that table, then generate another
---@param table table store uniq values here
---@param from number
---@param to number
function M.uniq_random(table, from, to) -- second, exclude duplicates
  local num = math.random(from, to)
  if table[num] then num = M.uniq_random(table, from, to) end
  table[num] = num
  return num
end

return M