local C = require("main.scripts.modules.catalog")
local Session = require("main.scripts.modules.session")
local M = {}

function M.spawn_followers(holder)
  for i, tree in ipairs(Session.run.tail) do
    local type_index, secondary = 1, 0
    for n, element in ipairs(C.elements) do
      if tree.element == element then type_index = n end
      if tree.secondary == element then secondary = n end
    end
    local parent = i == 1 and go.get_id() or holder.followers[i - 1]
    local pos = go.get_position(parent)
    pos.x = pos.x - 40
    local follower = factory.create("tail#followers", pos, go.get_rotation(), {
      parent = msg.url(nil, parent, "main"), type = type_index, secondary = secondary
    })
    holder.followers[i] = follower
  end
end

function M.animate_jump(holder)
  for index, follower in ipairs(holder.followers) do
    go.animate(follower, "scale", go.PLAYBACK_ONCE_PINGPONG, vmath.vector3(1.5),
      go.EASING_LINEAR, C.balance.jump_duration, 0.1 * index)
  end
end
return M
