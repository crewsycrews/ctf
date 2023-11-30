local followers = {}
local random = require("main.scripts.common.random")
math.randomseed(os.time())

followers.TYPES = { "fire", "water", "wind", "earth" }

---Deploy followers that will go behind each others back
---@param holder {followers_amount: number, followers: table, dir: quaternion|vector3|vector4 }
followers.spawn_followers = function(holder)
  holder.followers_amount = 4
  holder.followers_types = {}
  if #holder.followers == holder.followers_amount then return end
  for i = 1, holder.followers_amount do
    local typeIndex = random.uniq_random(holder.followers_types, 1,
      #followers.TYPES)
    local follower

    follower = factory.create("/player#followers", go.get_world_position(),
      nil, {
        parent = msg.url(nil, go.get_id(), 'main'),
        type = typeIndex
      })
    go.set_parent(follower, go.get_id())
    table.insert(holder.followers, i, follower)
    msg.post(follower, "look_at", { dir = holder.dir })
  end
end

followers.send_message_to_all = function(holder, message, data)
  for index, follower in ipairs(holder.followers) do
    msg.post(follower, message, data)
  end
end

---@param holder { followers: table }
followers.animate_jump = function(holder)
  for index, follower in ipairs(holder.followers) do
    go.animate(msg.url(nil, follower, nil), 'scale', go.PLAYBACK_ONCE_PINGPONG,
      go.get_scale() * 2, go.EASING_LINEAR, 0.8, 0.2 * index)
  end
end

return followers
