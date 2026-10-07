local C = require("main.scripts.modules.catalog")
local Profile = require("main.scripts.modules.profile")
local M = { error = nil }
local profile, writer, pending

-- Injectable persistence keeps transactions testable without the Defold runtime.
function M.configure(initial, save)
  profile, writer, pending = initial, save, nil
  M.run, M.error, M.result = nil, nil, initial.result
end

function M.load()
  if profile then return end
  local path = sys.get_save_file("cosmic_tree_fighters", "garden_v1")
  local ok, data = pcall(sys.load, path)
  if not ok or (next(data or {}) and not Profile.valid(data)) then
    M.error = "Cannot read garden save. Your file has not been replaced."
    return false
  end
  M.configure(next(data or {}) and data or Profile.new(), function(value)
    return sys.save(path, value)
  end)
  return true
end

function M.get()
  if not profile then M.load() end
  return profile
end

local function commit(candidate, after)
  pending = { profile = candidate, after = after }
  local ok, saved = pcall(writer, candidate)
  if not ok or not saved then
    M.error = "Save failed. Retry before continuing."
    return false, M.error
  end
  profile, pending, M.error = candidate, nil, nil
  if after then after() end
  return true
end

function M.retry()
  if pending then return commit(pending.profile, pending.after) end
  return M.load()
end

function M.change(operation, ...)
  if pending then return false, M.error end
  local p = M.get()
  if not p then return false, M.error end
  local candidate = C.copy(p)
  local ok, err = Profile[operation](candidate, ...)
  if not ok then return false, err end
  return commit(candidate)
end

function M.begin()
  if pending then return false, M.error end
  local candidate = C.copy(M.get())
  if not candidate then return false, M.error end
  local ok, run = Profile.begin_run(candidate)
  if not ok then return false, run end
  return commit(candidate, function() M.run, M.result = run, nil end)
end

function M.finish(success)
  if not M.run or not M.run.active then return false end
  M.run.active = false
  local candidate = C.copy(profile)
  local ok, result = Profile.finish(candidate, M.run, success)
  if not ok then return false, result end
  M.result = result
  return commit(candidate)
end

function M.blocked() return pending ~= nil or not profile end
return M
